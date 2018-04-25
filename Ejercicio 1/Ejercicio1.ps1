<#
.SYNOPSIS
Este Script hace una busqueda recursiva de todos los archivos dentro de esa carpeta y cuenta
la cantidad de archivos que tienen en el path completo un número.

.DESCRIPTION
El Script recibira como parametro el path a una carpeta.

+Si no se ingresa ningun parametro:
    -Se toma como parametro al path en ejecución.

+Si se ingresa el parametro:
    -Se toma como path al parametro ingresado.


.EXAMPLE
+./Ejercicio1.ps1 
.EXAMPLE
+./Ejercicio4.ps1 C:/Program Files

#>

<#     
.NOTES
Nombre del script: Ejercicio1.ps1
Trabajo Practico 1 - Ejercicio 1
Grupo:

Gómez Markowicz, Federico - 38858109
Kuczerawy, Damián - 37807869
Mediotte, Facundo - 39436162
Siculin, Luciano - 39213320
Tamashiro, Santiago - 39749147
#>

#a- Esta funcion recibe una direccion y te dice la cantidad de archivos que en su path contenga un número.

#b-

Param(
    [Parameter(Mandatory = $False)][ValidateNotNullOrEmpty()]$path 
)
if($path -eq $null){
    $path = [String](Get-Location)
}
if(Test-Path $path) {  #verifica si el path es correcto
    $a = Get-ChildItem $path -File -Recurse #obtiene el path de todas las subcarpetas y archivos
    $contador = 0 
    foreach ($item in $a) {
       if ($item.FullName -match ‘[0-9]’) { #verifica si en el path del archivo tiene un numero, si es verdadero lo cuenta
            $contador++
        } 
    } 
    Write-Output $contador
}
else {
    Write-Output 'El path es incorrecto'
}

#c- El opreador match compara dos string y devuelve TRUE si los dos string son iguales o si uno está incluido dentro del otro.

#d-
<#Param(
    [Parameter(Mandatory = $False)][ValidateNotNullOrEmpty()]$path 
)
if($path -eq $null){
    $path = [String](Get-Location)
}
if(Test-Path $path) { 
    $a = Get-ChildItem $path -File -Recurse
    $contador = 0
    $a | ForEach-Object {if($_.FullName -match ‘[0-9]’ ){ $contador++}}
    Write-Output $contador
}
else {
    Write-Output 'El path es incorrecto'
}#>

<# Fin de Archivo #>