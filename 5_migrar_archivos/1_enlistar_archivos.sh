#!/bin/bash 

# Input:
# dir_entrega: ruta de la carpeta donde están los clientes de captura, de la cuál se
# enlistarán todos los archivos.
# Ejemplo: bash 1_enlistar_archivos.sh /Volumes/sacmod/FMCN

# Output:
# lista de archivos en dir_entrega: 
# ${base_dir%%/}/reportes/temp_basename(dir_entrega)/productos_intermedios
# /temp_basename(dir_entrega)_1_lista.csv 

base_dir=$( cd "$( dirname "$0" )" && pwd )
#echo "$base_dir"

# misma carpeta creada en "0_crear_carpetas_reportes"
nombre_carpeta=temp_"$(basename "$1")"

# la carpeta de productos intermedios especificada en "0_crear_carpetas_reportes.sh"
dir_archivo="${base_dir%%/}"/reportes/"$nombre_carpeta"/productos_intermedios
nombre_archivo=temp_"$(basename "$1")"_1_lista.csv

# path al archivo donde se guardará la lista:
ruta_archivo="$dir_archivo"/"$nombre_archivo"
#echo "$ruta_archivo"
#echo "${#ruta_archivo}"

#corriendo el código para enlistar archivos:
if [ -f "$ruta_archivo" ]; then
	echo "el archivo con la lista ya fue creado"
	exit 1
else
	find "$1" -type f > "$ruta_archivo"
fi




