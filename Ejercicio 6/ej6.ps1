<#
.Synopsis
Juego de memoria donde se debe recordar la secuencia mostrada en pantalla.
.Description
El juego consiste en recordar una secuencia de palabras que se muestran por pantalla.
El objetivo es obtener la mayor cantidad de puntos posibles.
.Parameter path
Se ingresa el archivo que contiene las palabras para el juego
.Parameter nombreJugador
Se ingresa el nombre del jugador
.Example
(Respuesta correcta)
barco celular computadora

Ingrese la secuencia:
barco
celular
computadora
.Example
(Respuesta incorrecta)
barco celular computadora

Ingrese la secuencia:
barco
jarron
computadora

TOPSCORES
1-Franco - 10
2-Joaco - 9
3-Luciano - 8
#>

<#     
.NOTES
Nombre del script: ej6.ps1
Trabajo Practico 1 - Ejercicio 6
Grupo:

Gómez Markowicz, Federico - 38858109
Kuczerawy, Damián - 37807869
Mediotte, Facundo - 39436162
Siculin, Luciano - 39213320
Tamashiro, Santiago - 39749147

#>
Param(
    [Parameter(Mandatory=$true)]
    [string]$path,
    [Parameter(Mandatory=$false)]
    [string]$pathPuntajes,
    [Parameter(Mandatory=$true)]
    [string]$nombreJugador
)

function Get-Answer {
    $key = '';
    $first = $true;
    $end = (Get-Date).AddSeconds(5);
    $fullString='';
    while ((Get-Date) -lt $end)
    {
        if ($host.ui.RawUI.KeyAvailable)
        {
            $key = $host.UI.RawUI.ReadKey("NoEcho, IncludeKeyUp").Character;
            
            if ($first -eq $false) 
            {
                Write-Host $key -NoNewline
                if ([System.Text.Encoding]::ASCII.GetBytes($key.ToString())[0] -eq 13 -and $first -eq $false)
                {
                    #Write-Host 'fue enter'
                    break;
                }
                if ([System.Text.Encoding]::ASCII.GetBytes($key.ToString())[0] -ne 13){
                    $fullString += $key;
                }
                
            }
            else 
            {
                if ([System.Text.Encoding]::ASCII.GetBytes($key.ToString())[0] -ne 13){
                    Write-Host $key -NoNewline
                    $fullString += $key;
                }
                $first = $false;                
            }
        }

        Start-Sleep -Milliseconds 50;        
    }
    if(!$fullString -or ((Get-Date) -ge $end)){
        $fullString = $false;
    }
    return $fullString;
}


#$path = 'palabras.txt';
$pathPuntajes = 'puntajes.csv'
$palabras = Get-Content $path;    #Obtiene el contenido del archivo


#Verifica si el archivo esta vacio
if($palabras.Length -eq 0){
    echo "Archivo Vacio";
    return;
}

$secuencia = @();                    #Crea un array vacio
$puntaje = 0;                    #inicializa un contador en 0
$perdio = $false;                 #booleano para determinar si perdio o no
$timeout = $false;

while($perdio -eq $false){

    $random = Get-Random -Maximum $palabras.Count;     #Random entre x cantidad de palabras
    $secuencia += $palabras[$random];                  #concatena las palabras en la secuencia
    echo "Secuencia de palabras: $secuencia";          #muestra la secuencia que se debe escribir
    Start-Sleep -Seconds 3;                            #espero 3 segundos para que el usuario pueda recordar la secuencia
    clear;                                             #y limpio la pantalla
    echo "Ingrese la secuencia:";
    for($i=0; $i -lt $secuencia.Length; $i++){

        $respuesta = Get-Answer;                       #obtengo la respuesta escribida por el usuario
        #echo ($respuesta);
        echo "";                                       #agrego un enter para que se vea bien la secuencia escrita

        if($respuesta -eq $false){                     #si la respuesta es false es porque se acabo el timeOut
            echo " ";
            echo "Se acabo el tiempo";
            $perdio = $true;
            break;
            
        }elseif($respuesta -ne $secuencia[$i]){        #si la respuesta no es igual a la secuencia pierdes el juego
            $perdio = $true;
        }
    }

    if($perdio -eq $false){                            #si no perdio incremento el puntaje
        $puntaje++;
        clear;
    }else {
        echo " ";
        echo "Secuencia erronea";
        echo "La secuencia era: $secuencia";
    }

}

$details = @{            
                Nombre    = $nombreJugador            
                Puntaje   = $puntaje                
            }   
                                    
$jugador = @();
$jugador += New-Object PSObject -Property $details;      #creo un objeto jugador con las propiedades nombre y puntaje

$jugador|Export-Csv $pathPuntajes -Delimiter ";" -Append -NoTypeInformation;

$arch = @();
$arch += Import-Csv $pathPuntajes -Delimiter ";"|Sort-Object "puntaje" -Descending;

#$arch|Select-Object Nombre,{[int]::Parse($_.Puntaje)}|Sort Puntaje|Format-Table 

echo " ";
echo "TOPSCORES"                       #muestro los 3 mejores jugadores
for($i=0;$i -lt 3; $i++){
    echo $arch[$i];
}

$arch|Export-Csv $pathPuntajes -Delimiter ";" -NoTypeInformation;   #export-csv
