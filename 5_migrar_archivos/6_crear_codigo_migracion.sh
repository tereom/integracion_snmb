#!/bin/bash

# Input:
# dir_entrega: ruta de la carpeta donde están los clientes de captura, ésta se
# utilizará para obtener el archivo: "temp_basename(dir_entrega)_4_mapeo_rutas.csv",
# así como para guardar el archivo output en la carpeta adecuada.
# Ejemplo: bash 6_copiar_archivos.sh /Volumes/sacmod/FMCN

# Output:
# Script con el código de bash para hacer la migración de archivos, utilizando la
# información de "temp_basename(dir_entrega)_4_mapeo_rutas.csv":
# ${base_dir%%/}/reportes/temp_basename(dir_entrega)/productos
# /temp_basename(dir_entrega)_6_codigo_migracion.sh

## Todo lo siguiente es para crear la ruta al archivo con el mapeo de rutas,
## así como la ruta donde se guardará el archivo de salida.

base_dir=$( cd "$( dirname "$0" )" && pwd )

# misma carpeta creada en "0_crear_carpetas_reportes"
nombre_carpeta=temp_"$(basename "$1")"

# la carpeta de productos especificada en "0_crear_carpetas_reportes.sh"
dir_archivos="${base_dir%%/}"/reportes/"$nombre_carpeta"/productos

# ruta del archivo con el mapeo de las rutas actuales de los archivos a las nuevas
# rutas que tendrán:
nombre_archivo_mapeo_rutas=temp_"$(basename "$1")"_4_mapeo_rutas_prueba.csv
ruta_archivo_mapeo_rutas="$dir_archivos"/"$nombre_archivo_mapeo_rutas"

# creando la ruta del archivo que contendrá el código en bash para hacer la
# migración
nombre_archivo_codigo_migracion=temp_"$(basename "$1")"_6_codigo_migracion_prueba.sh
ruta_archivo_codigo_migracion="$dir_archivos"/"$nombre_archivo_codigo_migracion"

# creando la ruta del archivo que contendrá los errores de migración (a este archivo
# se le hará referencia en el código de la migración, por eso es importante tenerlo).
# cabe destacar que a este archivo no se le pone el directorio: "dir_archivos", porque
# la idea es que cuando se corra "temp_basename(dir_entrega)_6_codigo_migracion.sh",
# esto se haga desde la carpeta que lo contiene, para que el archivo de errores quede
# guardado ahí mismo.
nombre_archivo_errores_migracion=temp_"$(basename "$1")"_6_errores_migracion.txt

## Creando el código de migración si es que no existe:

function crearCodigo()
#$1: $ruta_archivo_mapeo_rutas
#$2: $ruta_archivo_codigo_migracion
{
	# -F,: el separador es una coma.
	# NR > 1 es empezar a partir del segundo renglón
	# $1 es la primera columna del csv, $2 es la segunda, etc...
	# la variable "codigo_migracion" contiene un script separado por saltos de línea
	# "/n", por lo que su contenido se debe procesar de la misma manera que un archivo
	# de texto leído con bash (while read -r linea...)
	# 2>> escribe los errores en el archivo indicado (sin borrar los anteriores).
	# la diagonal al final de la primera línea es para escapar el salto "\n"

	codigo_migracion="$(awk -F, -v archivo_errores="$nombre_archivo_errores_migracion" \
		'BEGIN {
			print "if [ -f \"" archivo_errores "\" ]; then"
			print "\t echo \"la migración ya fue realizada, ver archivo " archivo_errores \
			"\""
			print "else"
		}
		(NR > 1) {
			ruta_entrada = $1;
			ruta_salida = $6;
			print "\t cp " ruta_entrada " " ruta_salida " 2>> \"" archivo_errores "\"";
		}
		END {
			print "fi"
		}' "$1")"

	echo "$codigo_migracion" > "$2"
}


if [ -f "$ruta_archivo_codigo_migracion" ]; then
	echo "el archivo con el código de migración ya fue creado"
else
	crearCodigo "$ruta_archivo_mapeo_rutas" "$ruta_archivo_codigo_migracion"
fi