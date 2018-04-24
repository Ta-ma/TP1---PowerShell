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

$palabras = 'banana', 'manzana', 'pera', 'naranja', 'tomate', 'mandarina', 'khaki', 'ciruela', 'cereza', 'kiwi'

for ($i = 1; $i -le 100; $i++) {
    $frase = ''
    for ($j = 1; $j -le 10; $j++) {
        $ran = Get-Random -Maximum 10
        $frase = ($frase + $palabras[$ran] + " ")
    }
    #$frase = $frase.Trim()

    Set-Content -Path ($path + "\$i.html") -Value "
    <!DOCTYPE html>
    <html>
        <head>
            <title>$frase</title>
        </head>
        <body>
            Contenido...
        </body>
     </html>";
    #Write-Output ($path + "\$i.html")
}