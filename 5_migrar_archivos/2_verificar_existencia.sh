#!/bin/bash 

# Input:
# dir_entrega: ruta de la carpeta donde están los clientes de captura, de la cuál
# se enlistaron todos los archivos y, ahora, se validará la ruta mediante chequeos
# de existencia
# Ejemplo: bash 2_verificar_existencia.sh /Volumes/sacmod/FMCN

# Output:
# Archivo que verifica la existencia de los archivos en la lista creada en
# "1_enlistar_archivos.sh". Ésto con el fin de verificar que bash puede acceder
# a la ruta que acaba de escribir. Ruta del archivo output:
# ${base_dir%%/}/reportes/temp_basename(dir_entrega)/productos_intermedios
# /temp_basename(dir_entrega)_existencia.csv

base_dir=$( cd "$( dirname "$0" )" && pwd )
#echo "$base_dir"

# misma carpeta creada en "0_crear_carpetas_reportes"
nombre_carpeta=temp_"$(basename "$1")"

# la carpeta de productos intermedios especificada en "0_crear_carpetas_reportes.sh"
dir_archivos="${base_dir%%/}"/reportes/"$nombre_carpeta"/productos_intermedios
#echo "$dir_archivos"

#nombres de archivos para formar el path completo hacia ellos
nombre_archivo_lista=temp_"$(basename "$1")"_lista.csv
nombre_archivo_existencia=temp_"$(basename "$1")"_existencia.csv

ruta_archivo_lista="$dir_archivos"/"$nombre_archivo_lista"
ruta_archivo_existencia="$dir_archivos"/"$nombre_archivo_existencia"
#echo "$ruta_archivo_existencia"

#creando la función para verificar la existencia de los archivos:
function verificarExistencia()
#$1: $ruta_archivo_lista
#$2: "$ruta_archivo_existencia"
{
	while read -r linea; do
		echo "$([ -f "$linea" ] && echo TRUE || echo FALSE)" >> "$2"
	done < "$1"
}

#Corriendo la función en el caso en que no se haya creado el archivo de existencias.

if [ -f "$ruta_archivo_existencia" ]; then
	echo "el archivo de existencias ya fue creado"
	exit 1
else
	verificarExistencia "$ruta_archivo_lista" "$ruta_archivo_existencia"
fi
