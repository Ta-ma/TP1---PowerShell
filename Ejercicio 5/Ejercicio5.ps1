<#
.SYNOPSIS
     El Script mostrara por pantalla los procesos enviados a travez del parametro -Path (posicion 1)
     Ejercicio5 [-Path] <script> [[-K [-F]][-U][-C]]
.DESCRIPTION
    El Script creara una tabla con los datos solicitados por el usuario a travez de -K/-U/-C (exclusivamente una) 

.EXAMPLE
    Ejercicio5 -path C:\Archivo.txt -K [-F]
    esta opcion detendra la ejecucion de los procesos que esten dentro del archivo enviado atravez de -Path. El modificador -F fuerza la detencion
.EXAMPLE
    Ejercicio5 -path Archivo.txt -U
    El script mostrara el PID, el nombre, el porcentaje de uso de CPU, el consumo de memoria y el consumo maximo de memoria.
.EXAMPLE
    Ejercicio5 -.\Archivo.txt  -C
    El script mostrara el PID, el nombre, el porcentaje de uso de CPU.
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
if(-not($C -xor ($U -xor $K))){ (Get-Date -Format "yyyy/mm/dd - HH:mm:ss") + " | No se enviaron correctamente los parametros."  >> "Log.txt"
                                throw [System.ArgumentException]::New('No se enviaron correctamente los parametros. Puede visualizar la ayuda y ejemplos del Script utilizando get-help')}
if($F -and -not $K){
throw [System.ArgumentException]::New('El paramero -F solo puede ser utilizado para forzar la detencion de procesos... por lo tanto solo es posible la combinacion -K -F')}
#inicio las variables para tenerlas globalmente
$mipid=$micpu=$miram=$miramM=$nombre=$mensaje=""
$tabla=@()
(Get-Content $path).Replace('.exe','') | foreach{try{
    $nombre=$_
    $hora=(Get-Date -Format "yyyy/mm/dd - HH:mm:ss")
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
