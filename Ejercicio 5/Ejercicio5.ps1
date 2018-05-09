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
Param([Parameter(Mandatory=$true, position=1)][string]$path,
      [Parameter()]#ParameterSetName="Set1")]
      [switch]$U,
      [Parameter()]#ParameterSetName="Set2")]
      [switch]$C,
      [Parameter()]#ParameterSetName="Set3")]
      [switch]$K,
      [Parameter()]
      [switch]$F
)

$path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
$directorio = Split-Path -parent $path

if (-not (Test-Path $path)) {
    Write-Error "El archivo $path no existe."
    return
}

$extension = [IO.Path]::GetExtension($path)
if ($extension -ne '.txt') {
    $mensaje = ("$(Get-Date -Format g)" + " | La extensión $extension no es correcta (solo se permiten archivos .txt)")
    Add-Content $($directorio + "\" + "Log.txt") $mensaje
    Write-Error "La extensión del archivo $extension no es correcta (solo se permiten archivos .txt)."
    return
}

$var = 0
if($U) {$var++}
if($C) {$var++}
if($K) {$var++}

if($var -ne 1) { 
    $mensaje = ("$(Get-Date -Format g)" + " | No se enviaron correctamente los parámetros.")
    Add-Content $($directorio + "\" + "Log.txt") $mensaje
    Write-Error 'No se enviaron correctamente los parámetros. Puede visualizar la ayuda y ejemplos del Script utilizando Get-Help'
    return;
}

if($F -and -not $K) {
    $mensaje = ("$(Get-Date -Format g)" + " | El parámetro -F solo puede ser utilizado para forzar la detención de procesos... por lo tanto solo es posible la combinación -K -F")
    Add-Content $($directorio + "\" + "Log.txt") $mensaje
    Write-Error "El parámetro -F solo puede ser utilizado para forzar la detención de procesos... por lo tanto solo es posible la combinación -K -F"
    return;
}

$comando = { 
    Param([string]$path,
    [Parameter()]
    [bool]$U,
    [Parameter()]
    [bool]$C,
    [Parameter()]
    [bool]$K,
    [Parameter()]
    [bool]$F)
    $directorio = Split-Path -parent $path
    #inicio las variables para tenerlas globalmente
    $mipid=$micpu=$miram=$miramM=$nombre=$mensaje=""
    $tabla=@()
    $content = Get-Content $path
    $mensajes=@()
    
    if ($content -eq $null) {
        $mensaje = ("$(Get-Date -Format g)" + " | El archivo de procesos está vacío.")
        Add-Content $($directorio + "\" + "Log.txt") $mensaje
        return $mensaje
    }

    $content.Replace('.exe','') | foreach { 
        try {
            $nombre = $_
            $hora = (Get-Date -Format g)
            if($K) {
                if($F) {
                    Stop-Process -Name $_ -Force -ErrorAction Stop
                } else {
                    Stop-Process -Name $_ -ErrorAction Stop
                }
                $mensajes += "Proceso $nombre eliminado."
            } else {
                #se opto por usar el caracter comodin * para en caso de tener mas de un proceso con el mismo nombre tambien se incluya en la tabla
                $mipid = (Get-Counter "\Proceso($_*)\Id. de proceso" -ErrorAction Stop).CounterSamples.CookedValue
                $micpu = (Get-Counter "\Proceso($_*)\% de tiempo de procesador" -ErrorAction Stop).CounterSamples.CookedValue
                if($U) {
                    $miram = (Get-Counter "\Proceso($_*)\espacio de trabajo" -ErrorAction Stop).CounterSamples.CookedValue 
                    $miramM= (Get-Counter "\Proceso($_*)\Uso máximo del espacio de trabajo" -ErrorAction Stop).CounterSamples.CookedValue
                }
            }

            $i = 0   
            if($C) { 
                $mipid | foreach { 
                    $tabla += New-Object PSObject -Property @{
                        Nombre=(Get-Process -Id $_).Name.ToString() ;ID=$_ ;Uso_CPU=$micpu[$i++]
                    }
                }
            }
            if($U) { 
                $mipid | foreach {  
                    $tabla += New-Object PSObject -Property @{
                        Nombre=(Get-Process -Id $_).Name.ToString() ;ID=$_ ;Uso_CPU=$micpu[$i] ;Uso_De_Memoria=$miram[$i]/1024000 ;Uso_Maximo_De_Memoria=$miramM[$i++]/1024000
                    }
                }
            }
        } catch { 
            $mensaje = "$hora | El proceso indicado ($nombre) no es válido o no se encuentra ejecutando."
            Add-Content $($directorio + "\" + "Log.txt") $mensaje
            $mensajes += $mensaje
        }
    }
    #formateo la salida, este paso se puede omitir... es simplemente por estética... 
    #una salida más simple seria "return $tabla" o simplemente "$tabla" para únicamente mostrarla por pantalla
    if ($C) {
        $mensajes += $($tabla | Format-Table -Property ID, Nombre, Uso_CPU)
    }
    elseIf ($U) {
        $mensajes += $($tabla | Format-Table -Property ID, Nombre, Uso_CPU, Uso_De_Memoria, Uso_Maximo_De_Memoria)
    }
    return $mensajes;
}

# llamada al job para que analice los procesos.
Write-Output "Analizando procesos..."
$id = Start-Job -ScriptBlock $comando -ArgumentList $path, $U, $C, $K, $F -Name "ObtenerProceso"
$null = Wait-Job $id
$salida = Receive-Job $id
Write-Output $salida