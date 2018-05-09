<#
    .Synopsis
        El Script creara un Job que al cerrarse el proceso indicado corrige el archivo indicado. 
        Ejercicio [-DireccionArchivo] <String> [-Log] <String> [-Proceso] <String>
    .Description
        El Script creará un Job que quedará pendiente de creación del proceso indicado [-Proceso] y 
        aguardará su detención para asi leer y corregir el archivo indicado [-DireccionArchivo].
        Dicha correción se escribirá en el arhivo de nombre similar pero cuya terminación será "_modif". 
        Luego, se guardará un archivo de Log que contendrá la fecha y hora en que se corrigió el archivo, 
        el nombre del archivo y la cantidad de caracteres modificados.
    .Example
        Ejercicio3 -DireccionArchivo C:\Archivo.txt -Log C:\Log.txt -Proceso "Notepad.exe"
    .Example
        Ejercicio3 -DireccionArchivo C:\Archivo.txt -Log .\Log.txt -Proceso "Notepad"
    .Example
        Ejercicio3 -DireccionArchivo .\Archivo.txt -Log C:\Log.txt -Proceso "Notepad"
    .Example
        Ejercicio3 -DireccionArchivo .\Archivo.txt -Log .\Log.txt -Proceso "Notepad.exe"
    .Example
        .\Ejercicio3.ps1 -DireccionArchivo .\Textos\Archivo.txt -Log .\Textos\Log.txt -Proceso "Notepad"
    .Notes
        Sistemas Operativos
        --------------------
        Trabajo Práctico N°1
        Ejercicio 3
        Script: Ejercicio3.ps1
        --------------------
        Integrantes:
            .Kuczerawy, Damián - 37.807.869
            .Gómez Markowicz, Federico - 38.858.109
            .Siculin, Luciano - 39.213.320
            .Mediotte, Facundo - 39.436.162
            .Tamashiro, Santiago - 39.749.147
#>

Param([Parameter(Mandatory=$true)][string]$direccionArchivo
     ,[Parameter(Mandatory=$true)][string]$log
     ,[Parameter(Mandatory=$true)][string]$proceso)

$direccionArchivo = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($direccionArchivo)
$log = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($log)

if (-not (Test-Path $direccionArchivo)) {
    Write-Error 'El archivo a modificar no existe.'
    return
}

$extension = [IO.Path]::GetExtension($direccionArchivo)
if ($extension -ne '.txt') {
    Write-Error 'La extensión del archivo a modificar no es válida (solo se permiten archivos .txt).'
    return
}

$extension = [IO.Path]::GetExtension($log)
if ($extension -ne '.txt') {
    Write-Error 'La extensión del archivo de log no es válida (solo se permiten archivos .txt).'
    return
}

$comando = { 
Param([string]$direccionArchivo
     ,[string]$log
     ,[string]$proceso)

    $directorio = Split-Path -parent $direccionArchivo

    if($proceso.Contains(".")){$process = $proceso.Remove($proceso.LastIndexOf("."))} else {$process = $proceso}
    
    if((Get-Process).Name.ToUpper().Contains($process.ToUpper())) {
        try {
            Wait-Process -Name $process
            $cant=0
            $line=""
            #$archivo = Get-Content $direccionArchivo

            (Get-Content $direccionArchivo).Split("`n") | ForEach {
                if($line.Length -ne 0) { $line += "`r`n" }
                $_.Split('.') | ForEach {
                    [string]$aux=$_
                    while($aux[0] -eq ' ') {
                        $line += ' '
                        $aux=$aux.Substring(1)
                    }
                    if($aux[0] -ge 97 -and $aux[0] -le 126) { 
                        $cant++
                        $line += ([string]$aux[0]).ToUpper()
                        if($aux.Length -ge 2) {
                            $line+=$aux.Substring(1)
                        }
                    } else {
                        $line += $aux
                    } if(-not $line.EndsWith('.')) {
                        $line+='.'
                    }
                } 
            }

            $nombreArchivo = (Split-Path $direccionArchivo -leaf)
            $nombreArchivoNuevo = (Split-Path $direccionArchivo -leaf).Replace('.','_modif.')
            $dirNuevoArchivo = ($directorio + "\" + $nombreArchivoNuevo)
            Set-Content $dirNuevoArchivo -value $line
            Add-Content $log ((Get-Date -Format g ) + " | " + $nombreArchivo + " Se realizaron $cant modificaciones.")
            return "El archivo modificado se generó correctamente."
        } catch {
            Add-Content $log ((Get-Date -Format g ) + " | " + ($_.exception.message))
            return "Ocurrió un error. Vea el archivo de log para ver más detalles."
        }
    } else {
        Add-Content $log ((Get-Date -Format g ) + " | El proceso $process no existe o no se encuentra ejecutando.")
        return "Ocurrió un error. Vea el archivo de log para ver más detalles."
    }
} 

$job = Start-Job -ScriptBlock $comando -ArgumentList $direccionArchivo, $log, $proceso -Name "Espero a $Proceso"
Write-Output "Esperando al proceso $Proceso"
$null = Wait-Job $job
$salida = Receive-Job $job
Write-Output $salida

<# Fin de archivo #>