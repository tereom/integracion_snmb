#!/bin/bash 

# Argumentos
# 1. dir_j: ruta de la carpeta donde están los clientes de captura, de la cuál se
# migrarán los archivos
# Ejemplo: bash 0_crear_carpetas_reportes.sh /Volumes/sacmod/FMCN

base_dir=$( cd "$( dirname "$0" )" && pwd )
#echo "$base_dir"
# ${BASH_SOURCE[0]} ó $0: nombre del script

# Los reportes de la migración de archivos se guardarán en una estructura como sigue:
#integracion_snmb/5_migrar_archivos
#---reportes
#------nombre_carpeta (temp_basename(dir_j))
#---------base
#------------base de datos con la información de los archivos
#				(introducirla manualmente por seguridad)	
#---------productos_intermedios
#------------aaaa_mm_dd_basename(dir_j)_lista.csv lista de archivos en dir_j
#------------aaaa_mm_dd_basename(dir_j)_existencia.csv prueba de que bash
#			 puede acceder a dichos archivos.
#---------reportes_migracion

#Creando dicha estructura:

#%%/ quita la última diagonal si es que ésta se introdujo
mkdir "${base_dir%%/}"/reportes

#nombre_carpeta="$(date +'%Y_%m_%d')"_"$(basename "$1")"
nombre_carpeta=temp_"$(basename "$1")"

mkdir "${base_dir%%/}"/reportes/"$nombre_carpeta"

mkdir "${base_dir%%/}"/reportes/"$nombre_carpeta"/base

mkdir "${base_dir%%/}"/reportes/"$nombre_carpeta"/productos_intermedios

mkdir "${base_dir%%/}"/reportes/"$nombre_carpeta"/reportes_migracion

#El nombre de la carpeta se cambiará de temp_basename(dir_j) a
#aaaa_mm_dd_basename(dir_j) cuando se termine el proceso de migración.