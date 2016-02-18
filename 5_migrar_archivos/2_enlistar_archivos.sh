#!/bin/bash 

# Input:
# dir_j: ruta de la carpeta donde están los clientes de captura, de la cuál se
# enlistarán todos los archivos.
# Ejemplo: bash 2_enlistar_archivos.sh /Volumes/sacmod/FMCN

# Output:
# lista de archivos en dir_j: 
# ${base_dir%%/}/reportes/temp_basename(dir_j)/productos_intermedios
# /temp_basename(dir_j)_lista.csv 

base_dir=$( cd "$( dirname "$0" )" && pwd )
#echo "$base_dir"

# misma carpeta creada en "0_crear_carpetas_reportes"
nombre_carpeta=temp_"$(basename "$1")"

# la carpeta de productos intermedios especificada en "0_crear_carpetas_reportes.sh"
ruta_archivos="${base_dir%%/}"/reportes/"$nombre_carpeta"/productos_intermedios
#echo "$ruta_archivos"

nombre_archivo_lista=temp_"$(basename "$1")"_lista.csv
path_archivo_lista="$ruta_archivos"/"$nombre_archivo_lista"
#echo "${#path_archivo_lista}"

nombre_archivo_existencia=temp_"$(basename "$1")"_existencia.csv
path_archivo_existencia="$ruta_archivos"/"$nombre_archivo_existencia"
#echo "$path_archivo_existencia"





