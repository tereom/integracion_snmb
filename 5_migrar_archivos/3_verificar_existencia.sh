#!/bin/bash 

# Input:
# dir_j: ruta de la carpeta donde están los clientes de captura, de la cuál se
# enlistaron todos los archivos y, ahora, se validará la ruta mediante chequeos
# de existencia
# Ejemplo: bash 3_verificar_existencia.sh /Volumes/sacmod/FMCN

# Output:
# Archivo que verifica la existencia de los archivos en la lista creada en
# "2_enlistar_archivos.sh". Ésto con el fin de verificar que bash puede acceder
# a la ruta que acaba de escribir. Ruta del archivo output:
# ${base_dir%%/}/reportes/temp_basename(dir_j)/productos_intermedios
# /temp_basename(dir_j)_existencia.csv

base_dir=$( cd "$( dirname "$0" )" && pwd )
#echo "$base_dir"

# misma carpeta creada en "0_crear_carpetas_reportes"
nombre_carpeta=temp_"$(basename "$1")"

