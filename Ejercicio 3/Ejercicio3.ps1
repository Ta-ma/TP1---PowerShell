<#
.SYNOPSIS
     El Script creara un Job que al cerrarse el proceso indicado corrige el archivo indicado. 
     Ejercicio [-DireccionArchivo] <String> [-Log] <String> [-Proceso] <String>
.DESCRIPTION
    El Script creara un Job que quedara pendiente de creacion del proceso indicado [-Proceso] y aguardara su detencion para asi leer y corregir el archivo indicado [-DireccionArchivo], dicha correcion se escribira en el arhivo de nombre similar pero cuya terminacion sera "_modif". 
    Luego guardada un archivo de Log que contendra la fecha y hora en que se corrigio el archivo, el nombre del archivo y la cantidad de caracteres modificados

.EXAMPLE
    Ejercicio3 -DireccionArchivo C:\Archivo.txt -Log C:\Log.txt -Proceso "Notepad.exe"
.EXAMPLE
    Ejercicio3 -DireccionArchivo C:\Archivo.txt -Log .\Log.txt -Proceso "Notepad"
.EXAMPLE
    Ejercicio3 -DireccionArchivo .\Archivo.txt -Log C:\Log.txt -Proceso "Notepad"
.EXAMPLE
    Ejercicio3 -DireccionArchivo .\Archivo.txt -Log .\Log.txt -Proceso "Notepad.exe"

#>
Param([Parameter(Mandatory=$true)][string]$DireccionArchivo
     ,[Parameter(Mandatory=$true)][string]$Log
     ,[Parameter(Mandatory=$true)][string]$proceso)

if(([System.IO.Path]::IsPathRooted($DireccionArchivo)) -eq $false){$DireccionArchivo = (Get-ChildItem).DirectoryName+'\'+$DireccionArchivo.Substring(1)}
if(([System.IO.Path]::IsPathRooted($Log)) -eq $false){$Log = (Get-ChildItem).DirectoryName+'\'+$Log.Substring(0)}
 

$comando = { 
Param([string]$DireccionArchivo
     ,[string]$Log
     ,[string]$proceso)
    if($proceso.Contains(".")){$process = $proceso.Remove($proceso.LastIndexOf("."))} else {$process = $proceso}
    
    while($true)
    {
        if((Get-Process).Name.ToUpper().Contains($process.ToUpper()))
        {
            Wait-Process -Name $process
            $cant=0
            $line=""
    
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
            $line | Out-File $DireccionArchivo.replace('.','_modif.') -NoNewline
            (Get-Date -Format "yyyy/mm/dd - hh:mm:ss  " )+ $DireccionArchivo.subString($DireccionArchivo.lastindexof('\')+1) + "  $cant"  >> $Log  
        }
    }   
} 
Start-Job -ScriptBlock $comando -ArgumentList $DireccionArchivo, $Log, $proceso -Name "Espero a $Proceso"

