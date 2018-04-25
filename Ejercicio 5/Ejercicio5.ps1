<#
.SYNOPSIS
     El Script mostrará por pantalla los procesos enviados a través del parámetro -Path (posicion 1)
     Ejercicio5 [-Path] <script> [[-K [-F]][-U][-C]]
.DESCRIPTION
    El Script creara una tabla con los datos solicitados por el usuario a través de -K/-U/-C (exclusivamente una) 

.EXAMPLE
    Ejercicio5 -path C:\Archivo.txt -K [-F]
    esta opcion detendra la ejecucion de los procesos que esten dentro del archivo enviado a través de -Path. El modificador -F fuerza la detencion
.EXAMPLE
    Ejercicio5 -path Archivo.txt -U
    El script mostrará el PID, el nombre, el porcentaje de uso de CPU, el consumo de memoria y el consumo maximo de memoria.

.EXAMPLE
    Ejercicio5 -.\Archivo.txt  -C
    El script mostrará el PID, el nombre, el porcentaje de uso de CPU.
.NOTES
    Sistemas Operativos
    --------------------
    Trabajo Práctico N°1
    Ejercicio 5
    Script: Ejercicio5.ps1
    --------------------
    Integrantes:
        .Kuczerawy, Damián - 37.807.869
        .Gómez Markowicz, Federico - 38.858.109
        .Siculin, Luciano - 39.213.320
        .Mediotte, Facundo - 39.436.162
        .Tamashiro, Santiago - 39.749.147
#>
Param([Parameter(Mandatory=$true, position=1)][ValidateScript({Test-Path $_ })][string]$path,
      [Parameter()]#ParameterSetName="Set1")]
      [switch]$U,
      [Parameter()]#ParameterSetName="Set2")]
      [switch]$C,
      [Parameter()]#ParameterSetName="Set3")]
      [switch]$K,
      [Parameter()]
      [switch]$F
)

$var = 0
if($U) {$var++}
if($C) {$var++}
if($K) {$var++}

if($var -ne 1) { 
    (Get-Date -Format g) + " | No se enviaron correctamente los parametros."  >> "Log.txt"
    Write-Error 'No se enviaron correctamente los parametros. Puede visualizar la ayuda y ejemplos del Script utilizando get-help'
    return;
}

if($F -and -not $K) {
    Write-Error 'El paramero -F solo puede ser utilizado para forzar la detencion de procesos... por lo tanto solo es posible la combinacion -K -F'
    return;
}

#inicio las variables para tenerlas globalmente
$mipid=$micpu=$miram=$miramM=$nombre=$mensaje=""
$tabla=@()
(Get-Content $path).Replace('.exe','') | foreach{try{
    $nombre=$_
    $hora=(Get-Date -Format g)
    if($K){    if($F) {Stop-Process -Name $_ -Force -ErrorAction Stop} 
               else   {Stop-Process -Name $_ -ErrorAction Stop}} 
    #se opto por usar el caracter comodin * para en caso de tener mas de un proceso con el mismo nombre tambien se incluya en la tabla
    else      {$mipid = (Get-Counter "\Proceso($_*)\Id. de proceso" -ErrorAction Stop).CounterSamples.CookedValue
               $micpu = (Get-Counter "\Proceso($_*)\% de tiempo de procesador" -ErrorAction Stop).CounterSamples.CookedValue
        if($U){$miram = (Get-Counter "\Proceso($_*)\espacio de trabajo" -ErrorAction Stop).CounterSamples.CookedValue 
               $miramM= (Get-Counter "\Proceso($_*)\Uso máximo del espacio de trabajo" -ErrorAction Stop).CounterSamples.CookedValue}}
        $i=0   
                            
        if($C){ $mipid | foreach{ $tabla += New-Object PSObject -Property @{Nombre=(Get-Process -Id $_).Name.ToString() ;ID=$_ ;Uso_CPU=$micpu[$i++]}}}
        if($U){ $mipid | foreach{ $tabla += New-Object PSObject -Property @{Nombre=(Get-Process -Id $_).Name.ToString() ;ID=$_ ;Uso_CPU=$micpu[$i] ;Uso_De_Memoria=$miram[$i]/1024000 ;Uso_Maximo_De_Memoria=$miramM[$i++]/1024000}}}
    }catch{ $error=$_  #atrapo la exepcion para poder cargarlo al archivo log.txt que se encuentra en la ruta de ejecucion
            $mipid|foreach{if($error.exception.message -eq "No se puede enlazar el argumento al parámetro 'Id' porque es nulo.")
                                {$mensaje+="$hora | El proceso indicado ($nombre) no es valido o no se encuentra ejecutando`r`n"}
                           else{                 
                                if($_ -ne $null){$mensaje+="$hora | "+$error.exception.message+"`r`n"}
                                else            {$mensaje+="$hora | "+$error.exception.message+"`r`n"}}}}
}

if($mensaje.length -ne 0){ 
    $mensaje | Out-File "log.txt" -Append -NoNewline
    $mensaje
}

#formateo la salida, este paso se puede omitir... es simplemente por estetica... una salida mas simple seria "return $tabla" o simplemente "$tabla" para unicamente mostrarla por pantalla
if($C) {return $tabla | Format-Table -Property ID, Nombre, Uso_CPU}
if($U) {return $tabla | Format-Table -Property ID, Nombre, Uso_CPU, Uso_De_Memoria, Uso_Maximo_De_Memoria}
