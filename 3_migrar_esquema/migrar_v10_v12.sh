#!/bin/bash 

# Argumentos
# nombre_entrega: parte nombre del directorio donde se guardará la base de datos.
# A este nombre se le agregará la fecha actual, y las versiones involucradas para
# conformar el nombre real de la carpeta.
# nombre_entrega <- "prueba_fer"
# base_ruta: ruta de la base de datos a migrar de esquema
# base_ruta <- '../1_exportar_sqlite/bases/storage.sqlite'
# institucion_input: nombre de la institución
# institucion_input <- "CONANP"

base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Creando el nombre de la entrega usando fecha_actual_nombre_entrega_v10_v12.
entrega=$(date +"%Y_%m_%d")_$1_v10_v12

# Creando la base de datos y guardándola en una carpeta de la forma:
# 3_migrar_esquema/migraciones/aaaa_mm_dd_NOMBRE_ENTREGA_v10_v12/
# aaaa_mm_dd_NOMBRE_ENTREGA_v10_v12.sqlite

Rscript scripts/migrar_v10_v12.R $entrega $2 $3

base_fusionador=$(cd "../web2py/applications/fusionador_sqlite_v12/databases" && pwd)

# Antes de fusionar borrar todo lo del folder databases del fusionador
echo "limpiar carpeta databases"
rm -f ${base_fusionador%%/}/*

# Crear nuevas tablas
python ../web2py/web2py.py -S fusionador_sqlite_v12 -M -R ${base_dir%%/}/scripts/crear_tablas.py

echo "reemplazar"
cp ${base_dir%%/}/migraciones/$entrega/$entrega.sqlite ${base_fusionador%%/}/storage.sqlite

echo "exportar"
python ../web2py/web2py.py -S fusionador_sqlite_v12 -M -R ${base_dir%%/}/scripts/crear_csv.py -A applications/fusionador_sqlite_v12/databases/storage.csv

mv ${base_fusionador%%/}/storage.csv ${base_dir%%/}/migraciones/$entrega/$entrega.csv

rm -f ${base_fusionador%%/}/*