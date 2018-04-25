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

Param([Parameter(Mandatory=$true)][string]$DireccionArchivo
     ,[Parameter(Mandatory=$true)][string]$Log
     ,[Parameter(Mandatory=$true)][string]$proceso)

$DireccionArchivo = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($DireccionArchivo)
$Log = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Log)

if (-not (Test-Path $pathDir)) {
    Write-Error 'El archivo a modificar no existe.'
    return
}

$comando = { 
Param([string]$DireccionArchivo
     ,[string]$Log
     ,[string]$proceso)

    $directorio = Split-Path -parent $DireccionArchivo

    if($proceso.Contains(".")){$process = $proceso.Remove($proceso.LastIndexOf("."))} else {$process = $proceso}
    
    if((Get-Process).Name.ToUpper().Contains($process.ToUpper()))
    {
        Wait-Process -Name $process
        $cant=0
        $line=""
        #$archivo = Get-Content $DireccionArchivo

        (Get-Content $DireccionArchivo).Split("`n") | ForEach{
            if($line.Length -ne 0){$line += "`r`n"}
            $_.Split('.') | ForEach{
                [string]$aux=$_
                while($aux[0] -eq ' ')
                {
                    $line += ' '
                    $aux=$aux.Substring(1)
                }
                if($aux[0] -ge 97 -and $aux[0] -le 126)
                { 
                    $cant++
                    $line += ([string]$aux[0]).ToUpper()
                    if($aux.Length -ge 2)
                    {
                        $line+=$aux.Substring(1)
                    }
                }
                else
                {
                    $line += $aux
                }
                if(-not $line.EndsWith('.'))
                {
                    $line+='.'
                }
            } 
        }

        $nombreArchivo = (Split-Path $DireccionArchivo -leaf).Replace('.','_modif.')
        $dirNuevoArchivo = ($directorio + "\" + $nombreArchivo)
        Set-Content $dirNuevoArchivo -value $line
        #$line | Out-File $dirNuevoArchivo -NoNewline
        (Get-Date -Format "yyyy/mm/dd - hh:mm:ss  " )+ $DireccionArchivo.subString($DireccionArchivo.lastindexof('\')+1) + "  $cant"  >> $Log  
    }
} 
Start-Job -ScriptBlock $comando -ArgumentList $DireccionArchivo, $Log, $proceso -Name "Espero a $Proceso"

<# Fin de archivo #>