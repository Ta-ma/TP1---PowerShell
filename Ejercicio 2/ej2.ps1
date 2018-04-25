<#
    .Synopsis
    Muestra las 5 palabras más utilizadas en los títulos de las páginas web de un directorio.
    .Description
    Busca en todos los archivos de extensión .html en el directorio especificado
    las 5 palabras más utilizadas entre los tags <title> y </title>
    .Parameter path
    Directorio donde se encuentran los archivos .html
    .Example
    .\ej2.ps1 -path ".\Lote de Prueba"

    .Notes
    Sistemas Operativos
    --------------------
    Trabajo Práctico N°1
    Ejercicio 2
    Script: ej2.ps1
    --------------------
    Integrantes:
        .Kuczerawy, Damián - 37.807.869
        .Gómez Markowicz, Federico - 38.858.109
        .Siculin, Luciano - 39.213.320
        .Mediotte, Facundo - 39.436.162
        .Tamashiro, Santiago - 39.749.147
#>

Param(
    [Parameter(Mandatory=$true)]
    [ValidateLength(1, 255)]
    [String] $path
)

# validación del path
if (-not (Test-Path $path)) {
    Write-Error 'Path inexistente'
    return
}

# creo la hashtable que contendrá las palabras
$h = @{}

# obtengo todos los archivos de extensión .html que se encuentran dentro de #path e itero
Get-ChildItem -path $path -recurse -file | Where-Object {$_.Extension -eq '.html'} | ForEach-Object {
    # guardo su contenido
    $contenido = Get-Content $_.FullName -Raw
    # extraigo la frase que se encuentra entre '<title>' y '</title>'
    $titulo = [regex]::match($contenido, '(?<=<title>).*?(?=</title>)').Groups[0].value
    # uso trim para sacarle espacios de más si es que los hay
    $titulo = $titulo.Trim()
    # obtengo las palabras que componen la frase
    $palabras = $titulo -split ' '
    # array con palabras que deben ignorarse
    $palabrasProhibidas = 'a', 'ante', 'bajo', 'con', 'contra', 'de', 'desde',
     'durante', 'en', 'entre', 'hacia', 'hasta', 'para', 'por', 'según', 'sin', 'sobre', 'tras'
    # itero sobre las palabras
    foreach($p in $palabras) {
        # si está en las palabras prohibidas no la incluyo
        if(-not $palabrasProhibidas.Contains($p)) {
            if($h.ContainsKey($p)) {
                # si ya existe, le sumo 1 a la entrada correspondiente en la hashtable
                $h[$p]++
            } else {
                # si no existe, la agrego
                $h.Add($p, 1)
            }
        }
    }
}

# finalmente, ordeno la hashtable por valor en sentido descendente y selecciono las primeras 5 entradas
$h.GetEnumerator() | Sort-Object value -Descending | Select-Object -First 5 | ForEach-Object {
    Write-Output $_
}
<#  Fin de Archivo  #>
