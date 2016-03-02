#!/bin/bash

# Este script sirve para agrupar todos los archivos correspondientes a formatos
# de campo en "dir_entrega", que no pudieron ser asociados a ninguna entrega, en
# una misma carpeta, para su fácil revisión.

# Inputs:
# 1. dir_entrega: ruta de la carpeta donde están los clientes de captura. Ésta se
# utiliza para encontrar el archivo:
# "temp_basename(dir_entrega)_11_formatos_no_asociados.csv"
# del que se extraerán las rutas de los formatos de campo en dir_entrega, que no
# pudieron ser asociados a ninuna entrega en la misma carpeta.

# 2. ruta_carpeta_formatos_no_asociados: ruta de la carpeta donde se copiarán los
# formatos no asociados

# Output:
# Carpeta que contiene los archivos enlistados en
# temp_basename(dir_entrega)_11_formatos_no_asociados.csv""

base_dir=$( cd "$( dirname "$0" )" && pwd )
#echo "$base_dir"

# misma carpeta creada en "0_crear_carpetas_reportes"
nombre_carpeta=temp_"$(basename "$1")"

# la carpeta de productos especificada en "0_crear_carpetas_reportes.sh"
dir_archivos="${base_dir%%/}"/reportes/"$nombre_carpeta"/productos

# path a la lista de formatos de campo que no pudieron ser asociados a ninguna
# muestra en dir_entrega.
nombre_archivo_formatos_no_asociados=temp_"$(basename "$1")"_11_formatos_no_asociados.csv
ruta_archivo_formatos_no_asociados="$dir_archivos"/"$nombre_archivo_formatos_no_asociados"
echo "$ruta_archivo_formatos_no_asociados"

# obteniendo ruta absoluta de la carpeta donde se van a agrupar los archivos
# anteriores.
ruta_carpeta_formatos_no_asociados="$2"
echo "$ruta_carpeta_formatos_no_asociados"

##############
#Creando la función para leer las rutas de los formatos del archivo apropiado
#y copiarlos a la nueva carpeta:

function copiarFormatosNoAsociados()
#$1: $ruta_archivo_formatos_no_asociados
#$2: $ruta_carpeta_formatos_no_asociados
{
	rutas_formatos="$(awk -F, '
	(NR > 1){
		# quitando las comillas (como se escapan, crean conflictos)
		ruta_formato_campo = substr($1, 2, length($1)-2);
		print ruta_formato_campo;
	}' "$1")"

	while read -r linea; do
		cp "$linea" "$2"/"$(basename "$linea")" #__"$RANDOM".pdf
	# <<<: leer de una variable
	done <<< "$rutas_formatos"
}

# Copiando los archivos si existe el directorio donde se quiere colocar la nueva
# carpeta, pero ésta no existe

if [ -d "$ruta_carpeta_formatos_no_asociados" ]; then
	echo "la carpeta destino ya existe, favor de especificar otra."
elif [ ! -d "$(dirname "$ruta_carpeta_formatos_no_asociados")" ]; then
	echo "no existe el directorio donde se quiere colocar la carpeta destino"
else
	mkdir "$ruta_carpeta_formatos_no_asociados"
	copiarFormatosNoAsociados "$ruta_archivo_formatos_no_asociados"\
	 "$ruta_carpeta_formatos_no_asociados"
fi
