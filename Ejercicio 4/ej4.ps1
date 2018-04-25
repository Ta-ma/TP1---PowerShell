<#
    .Synopsis
    Actualiza el archivo de inventario XML especificado con los archivos del proveedor.
    
    .Description
    Busca en el directorio todos los archivos XML con información de entregas de los proveedores
    y utiliza la información de estos para actualizar el precio y stock del archivo XML especificado.
    Los archivos del proveedor deben tener el siguiente formato:
        <codProveedor>_precio_<fecha>.xml o <codProveedor>_stock_<fecha>.xml

    .Example
    .\ej4.ps1 ".\Lote de Prueba\inventario.xml" ".\Lote de Prueba\Proveedores"

    .Notes
    Sistemas Operativos
    --------------------
    Trabajo Práctico N°1
    Ejercicio 4
    Script: ej4.ps1
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
    [String] $pathInv,
    [Parameter(Mandatory=$true)]
    [ValidateLength(1, 255)]
    [String] $pathDir,
    [Switch] $backup
)

function actualizarPrecioProducto {
    Param(
        [Parameter(Mandatory=$true)]$h,
        [Parameter(Mandatory=$true)]$codProv,
        [Parameter(Mandatory=$true)]$productoProv
    )
    $claveCompuesta = ($codProv + '_' + $productoProv.codigo)

    if($h.ContainsKey($claveCompuesta)) {
        # si el producto ya existe en el inventario, lo actualizo
        $productoInv = $h[$claveCompuesta]
        $precioViejo = $productoInv.precio

        if($productoProv.precio.porcentaje) {
            # si el precio es un porcentaje, aplico una multiplicación
            [float]$precioNuevo = $productoInv.precio
            $precioNuevo *= (1 + $productoProv.precio.InnerText / 100)
            $productoInv.precio = $precioNuevo.ToString('#.##').Replace(',', '.')
        } else {
            # si no es un porcentaje, reemplazo el precio viejo por el nuevo
            $productoInv.precio = $productoProv.precio
        }
        Write-Host "Actualizado el producto" $productoInv.codigo "(" $productoInv.descripcion ")" "del proveedor $codProveedor" "- Precio" $precioViejo -> $productoInv.precio
    } else {
        # si el producto no existe, lo agrego
        # acá aparece un problema, si el producto nuevo figura con un precio como "porcentaje"
        # lo pongo con 0 porque en realidad no tiene sentido que el proveedor traiga un producto
        # que no existe en el inventario con un cambio de precio porcentual
        if($productoProv.precio.porcentaje) {
            $precio = 0
        } else {
            $precio = $productoProv.precio
        }
        
        $nuevoProducto = [PSCustomObject]@{
            codigo = $productoProv.codigo
            descripcion = $productoProv.descripcion
            precio = $precio
            stock = 0
            codigoProveedor = $codProv
        }
        $h.Add($claveCompuesta, $nuevoProducto)
        Write-Host "Agregado el producto" $nuevoProducto.codigo  "(" $nuevoProducto.descripcion ")" "del proveedor $codProveedor"
    }
}

function actualizarStockProducto {
    Param(
        [Parameter(Mandatory=$true)]$h,
        [Parameter(Mandatory=$true)]$codProv,
        [Parameter(Mandatory=$true)]$productoProv
    )
    $claveCompuesta = ($codProv + '_' + $productoProv.codigo)

    if($h.ContainsKey($claveCompuesta)) {
        # si el producto ya existe en el inventario, lo actualizo
        $productoInv = $h[$claveCompuesta]
        $stockViejo = $productoInv.stock

        # le agrego la cantidad al stock del producto en inventario
        [int]$stockNuevo = $productoInv.stock
        $stockNuevo += $productoProv.stock
        $productoInv.stock = $stockNuevo.ToString()
        Write-Host "Actualizado el producto" $productoInv.codigo "(" $productoInv.descripcion ")" "del proveedor $codProveedor" "- Stock" $stockViejo -> $productoInv.stock
    } else {
        # si el producto no existe, lo agrego
        $nuevoProducto = [PSCustomObject]@{
            codigo = $productoProv.codigo
            descripcion = $productoProv.descripcion
            precio = 0
            stock = $productoProv.stock
            codigoProveedor = $codProv
        }
        $h.Add($claveCompuesta, $nuevoProducto)
        Write-Host "Agregado el producto" $nuevoProducto.codigo  "(" $nuevoProducto.descripcion ")" "del proveedor $codProveedor"
    }
}

# validación del path
if (-not (Test-Path $pathInv)) {
    Write-Error 'El path del archivo de inventario no existe o no es accesible.'
    return
}

if (-not (Test-Path $pathDir)) {
    Write-Error 'El path del directorio con los archivos de los proveedores no existe o no es accesible.'
    return
}

$archInv = Get-Item $pathInv

# obtengo el xml del inventario
[xml]$xmlInv = Get-Content $archInv

# hago backup del archivo inventario si así fue solicitado
if ($backup) {
    Write-Host 'Se ha realizado un backup en: '
    Write-Host (($archInv).DirectoryName + '\' + ($archInv).BaseName + '_backup.xml')
    Copy-Item $pathInv -Destination (($archInv).DirectoryName + '\' + ($archInv).BaseName + '_backup.xml')
}

# paso los productos a una hashtable para que sea más cómodo manejarlos
$h = @{}

foreach ($productoProv in $xmlInv.inventario.producto) {
    # el hashtable tiene una clave compuesta "x_y" donde x es el código del proveedor
    # e y es el código de producto
    # Write-Output ($productoProv.codigoProveedor + '_' + $productoProv.codigo)
    $h.Add(($productoProv.codigoProveedor + '_' + $productoProv.codigo), $productoProv)
}

# obtengo todos los xml del directorio de proveedores
Get-ChildItem -path $pathDir -recurse -file | Where-Object {$_.Extension -eq '.xml'} | ForEach-Object {
    $partesNombre = $_.BaseName -split '_'

    if ($partesNombre.length -ne 3) {
        # se supone que esto no debería pasar igual ya que según la consigna los archivos tienen nombre válido
        Write-Error "Error en archivos xml del proveedor: El archivo de nombre $_.BaseName no es válido."
    } else {
        # cargo el xml
        [xml]$xmlProveedor = Get-Content $_.FullName
        # la primer parte del nombre es el cod de proveedor
        $codProveedor = $partesNombre[0]
        # la segunda parte del nombre es el tipo de actualización que se debe realizar
        $tipoArch = $partesNombre[1]
        
        if ($tipoArch -eq 'precio') {
            # primer caso: el xml tiene varios productos
            if ($xmlProveedor.precios.producto.length) {
                # recorro producto por producto
                foreach ($producto in $xmlProveedor.precios.producto) {
                    actualizarPrecioProducto $h $codProveedor $producto
                }
            # segundo caso: el xml tiene un único producto
            } elseIf ($xmlProveedor.precios.producto) {
                actualizarPrecioProducto $h $codProveedor $xmlProveedor.precios.producto
            }
            # el tercer caso sería que el xml esté vacío o no tenga productos (no se hace nada)
        } elseIf ($tipoArch -eq 'stock') {
            if ($xmlProveedor.stock.producto.length) {
                foreach ($producto in $xmlProveedor.stock.producto) {
                    actualizarStockProducto $h $codProveedor $producto
                }
            } elseIf ($xmlProveedor.stock.producto) {
                actualizarStockProducto $h $codProveedor $xmlProveedor.stock.producto
            }
        } else {
            Write-Error "Error en archivos xml del proveedor: El archivo de nombre $_.BaseName no es válido."
        }
    }
}

# guardo la hashtable en el xml
[xml]$doc = New-Object System.Xml.XmlDocument
$raiz = $doc.CreateNode("element", "inventario", $null)
$doc.AppendChild($raiz) | Out-Null

# por cada producto, creo un nodo xml y le agrego los elementos del producto
foreach($key in $h.Keys) {
    $producto = $h[$key]
    $nodoProducto = $doc.CreateNode("element", "producto", $null)
    
    "codigo","descripcion","codigoProveedor","precio","stock" | ForEach-Object {
        $e = $doc.CreateElement($_)
        $e.InnerText = $producto.$_
        $nodoProducto.AppendChild($e) | Out-Null
    }

    $raiz.AppendChild($nodoProducto) | Out-Null
}

# guardo el archivo
$doc.Save($archInv.FullName)
<#  Fin de Archivo  #>
