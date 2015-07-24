#!/bin/bash 

# Argumentos:

# 1. base_ruta: ruta de la base de datos (esquema v12) cuyos duplicados se eliminarán
# ejemplo: base_ruta <- '../1_exportar_sqlite/bases/storage.sqlite'

# 2. archivo_ruta: ruta del archivo que contiene sólo una columna con los id's de los
# conglomerados a eliminar. Ejemplo de formato del archivo:
# 6
# 22
# 1

# el resultado será una nueva base, con el mismo nombre de la original, pero 
# eliminando los registros especificados

base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# directorio dentro de web2py (variable global)
base_fusionador=$(cd "../web2py/applications/fusionador_sqlite_v10/databases" && pwd)

# directorio donde se guardarán las bases de datos:

mkdir ${base_dir%%/}/bases

# nombre de la subcarpeta donde se guardarán las bases de datos deduplicadas,
# así como los informes:
nombre_salida=$(basename $1)
nombre_salida=${nombre_salida%.*}

mkdir ${base_dir%%/}/bases/$nombre_salida

# Antes de deduplicar borrar todo lo del folder databases del fusionador:
echo "limpiar carpeta databases"
rm -f ${base_fusionador%%/}/*

# Crear nuevas tablas:
python ../web2py/web2py.py -S fusionador_sqlite_v10 -M -R ${base_dir%%/}/scripts_py/crear_tablas.py

echo "reemplazar"
cp $1 ${base_fusionador%%/}/storage.sqlite

echo "deduplicar"
python ../web2py/web2py.py -S fusionador_sqlite_v10 -M -R ${base_dir%%/}/scripts_py/eliminar_registros.py -A $2 ${base_dir%%/}/bases/$nombre_salida/${nombre_salida}_eliminados.csv

echo "exportar"
python ../web2py/web2py.py -S fusionador_sqlite_v10 -M -R ${base_dir%%/}/scripts_py/crear_csv.py -A applications/fusionador_sqlite_v10/databases/storage.csv

echo "copiar a carpeta de salida"
cp ${base_fusionador%%/}/storage.sqlite ${base_dir%%/}/bases/$nombre_salida/$nombre_salida.sqlite
cp ${base_fusionador%%/}/storage.csv ${base_dir%%/}/bases/$nombre_salida/$nombre_salida.csv


#Limpiar fusionador:
rm -f ${base_fusionador%%/}/*






