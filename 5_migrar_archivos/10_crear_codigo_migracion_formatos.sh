#!/bin/bash

# Input:
# dir_entrega: ruta de la carpeta donde están los clientes de captura, ésta se
# utilizará para obtener el archivo:
# "temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv",
# así como para guardar el archivo output en la carpeta adecuada.
# Ejemplo: bash 10_crear_codigo_migracion_formatos.sh /Volumes/sacmod/FMCN

# Output:
# Script con el código de bash para hacer la migración de archivos, utilizando la
# información de "temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv":
# ${base_dir%%/}/reportes/temp_basename(dir_entrega)/productos
# /temp_basename(dir_entrega)_10_codigo_migracion_formatos.sh

## Todo lo siguiente es para crear la ruta al archivo con el mapeo de rutas,
## así como la ruta donde se guardará el archivo de salida.

base_dir=$( cd "$( dirname "$0" )" && pwd )

# misma carpeta creada en "0_crear_carpetas_reportes"
nombre_carpeta=temp_"$(basename "$1")"

# la carpeta de productos especificada en "0_crear_carpetas_reportes.sh"
dir_archivos="${base_dir%%/}"/reportes/"$nombre_carpeta"/productos

# ruta del archivo con el mapeo de las rutas actuales de los archivos a las nuevas
# rutas que tendrán:
nombre_archivo_mapeo_rutas=temp_"$(basename "$1")"_9_mapeo_rutas_formatos.csv
ruta_archivo_mapeo_rutas="$dir_archivos"/"$nombre_archivo_mapeo_rutas"
#echo "$ruta_archivo_mapeo_rutas"

# creando la ruta del archivo que contendrá el código en bash para hacer la
# migración
nombre_archivo_codigo_migracion=temp_"$(basename "$1")"_10_codigo_migracion_formatos.sh
ruta_archivo_codigo_migracion="$dir_archivos"/"$nombre_archivo_codigo_migracion"
#echo "$ruta_archivo_codigo_migracion"

# creando la ruta del archivo que contendrá los errores de migración (a este archivo
# se le hará referencia en el código de la migración, por eso es importante tenerlo).
# cabe destacar que a este archivo no se le pone el directorio: "dir_archivos", 
# por portabilidad de "temp_basename(dir_entrega)_10_codigo_migracion_formatos.sh".
# La idea es que este último se corra desde la carpeta que lo contiene, para que
# el archivo de errores quede guardado ahí mismo.
nombre_archivo_errores_migracion=temp_"$(basename "$1")"_10_errores_migracion_formatos.txt
#echo "$nombre_archivo_errores_migracion"

## Creando el código de migración si es que no existe:

# Ejemplo de código creado:
## if [ -f "temp_sacmod_10_errores_migracion_formatos.txt" ]; then
## 	 echo "la migración ya fue realizada, ver archivo temp_sacmod_10_errores_migracion_formatos.txt"
## else
## 	 rsync --progress "/Volumes/sacmod/data_26_01_2015_tres/Entrega de Productos/AGOSTO/DIAAPROY/CS/E_20140829/BIODIVERSIDAD/CLIENTE DE CAPTURA/64199/resources/archives/imagenes/64199_S3_CVTC_20140808_3.JPG" "/Volumes/sacmod/archivos_snmb_2/64199/2014_08/fotos_videos/64199_S3_CVTC_20140808_3.JPG" 2>> "temp_sacmod_7_errores_migracion.txt"
## 	 rsync --progress "/Volumes/sacmod/data_26_01_2015_tres/Entrega de Productos/AGOSTO/DIAAPROY/CS/E_20140829/BIODIVERSIDAD/CLIENTE DE CAPTURA/68898/resources/archives/imagenes/68898_S3_CVTC_20140818_3.JPG" "/Volumes/sacmod/archivos_snmb_2/68898/2014_08/fotos_videos/68898_S3_CVTC_20140818_3.JPG" 2>> "temp_sacmod_7_errores_migracion.txt"
## 	 rsync --progress "/Volumes/sacmod/data_26_01_2015_tres/Entrega de Productos/AGOSTO/DIAAPROY/CS/E_20140829/BIODIVERSIDAD/CLIENTE DE CAPTURA/65027/resources/archives/imagenes/65027_S3_CVTC_20140804_3.JPG" "/Volumes/sacmod/archivos_snmb_2/65027/2014_08/fotos_videos/65027_S3_CVTC_20140804_3.JPG" 2>> "temp_sacmod_7_errores_migracion.txt"
## 	 rsync --progress "/Volumes/sacmod/data_26_01_2015_tres/Entrega de Productos/AGOSTO/DIAAPROY/CS/E_20140829/BIODIVERSIDAD/CLIENTE DE CAPTURA/69841/resources/archives/imagenes/69841_S3_FCT_20140824_3.JPG" "/Volumes/sacmod/archivos_snmb_2/69841/2014_08/fotos_videos/69841_S3_FCT_20140824_3.JPG" 2>> "temp_sacmod_7_errores_migracion.txt"
## 	 rsync --progress "/Volumes/sacmod/data_26_01_2015_tres/Entrega de Productos/AGOSTO/DIAAPROY/CS/E_20140829/BIODIVERSIDAD/CLIENTE DE CAPTURA/69841/resources/archives/imagenes/69841_T2_EXC_20140823_2.JPG" "/Volumes/sacmod/archivos_snmb_2/69841/2014_08/huellas_excretas/69841_T2_EXC_20140823_2.JPG" 2>> "temp_sacmod_7_errores_migracion.txt"
## fi


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

	codigo_migracion="$(awk -F, -v archivo_errores="$nombre_archivo_errores_migracion" '
		BEGIN {
			print "if [ -f \"" archivo_errores "\" ]; then"
			print "\t echo \"la migración ya fue realizada, ver archivo " archivo_errores \
			"\""
			print "else"
		}
		(NR > 1) {
			ruta_entrada = $4;
			ruta_salida = $5;
			print "\t rsync --progress " ruta_entrada " " ruta_salida " 2>> \"" archivo_errores "\"";
		}
		END {
			print "fi"
		}' "$1")"

	echo "$codigo_migracion" > "$2"
}


if [ -f "$ruta_archivo_codigo_migracion" ]; then
	echo el archivo con el código de migración ya fue creado
else
	crearCodigo "$ruta_archivo_mapeo_rutas" "$ruta_archivo_codigo_migracion"
fi