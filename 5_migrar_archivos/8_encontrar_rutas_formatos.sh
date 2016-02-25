#!/bin/bash 

# Input:
# dir_entrega: ruta de la carpeta donde están los clientes de captura. Ésta se
# utiliza para encontrar el archivo:
# "temp_basename(dir_entrega)_1_lista.csv"
# del que se seleccionarán, mediante palabras clave, las rutas que corresponden a
# formatos de campo.

# Output:
# lista de rutas hacia los formatos de campo:
# ${base_dir%%/}/reportes/temp_basename(dir_entrega)/productos
# /temp_basename(dir_entrega)_8_lista_formatos.csv 


base_dir=$( cd "$( dirname "$0" )" && pwd )
#echo "$base_dir"

# misma carpeta creada en "0_crear_carpetas_reportes"
nombre_carpeta=temp_"$(basename "$1")"

# la carpeta de productos especificada en "0_crear_carpetas_reportes.sh"
dir_archivos="${base_dir%%/}"/reportes/"$nombre_carpeta"/productos

# path a la lista de archivos en dir_entrega:
nombre_archivo_lista=temp_"$(basename "$1")"_1_lista.csv
ruta_archivo_lista="$dir_archivos"/"$nombre_archivo_lista"
#echo "$ruta_archivo_lista"

# path al archivo donde se guardarán las rutas a los formatos de campo
# localizados en dir_entrega:
nombre_archivo_lista_formatos=temp_"$(basename "$1")"_8_lista_formatos.csv
ruta_archivo_lista_formatos="$dir_archivos"/"$nombre_archivo_lista_formatos"
#echo "$ruta_archivo_lista_formatos"

# grepeando formularios de la lista:
if [ -f "$ruta_archivo_lista_formatos" ]; then
	echo "el archivo con la lista de formatos de campo ya fue creado"
else
	# se supone que las rutas hacia archivos que contienen formatos de campo
	# tienen la palabra "formato" en su ruta.
	grep formato "$ruta_archivo_lista" > "$ruta_archivo_lista_formatos"
fi
