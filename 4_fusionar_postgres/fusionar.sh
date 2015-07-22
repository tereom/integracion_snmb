#!/bin/bash 

# Argumentos:
# csv_ruta: ruta al archivo csv a fusionar en la base de datos final.
# Ejemplo: bash fusionar.sh ../1_exportar_sqlite/bases/storage.csv

# Por seguridad de los datos, se deberá encender el servidor de la base postgresql
# antes de correr este script.

# Adicionalmente a fusionar los datos de un csv en postgres, este script exporta
# la base postgres a sqlite, y la guarda en una carpeta llamada "imagen".

csv_ruta=$1

base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

base_fusionador_postgres=$(cd "../web2py/applications/fusionador_postgres_v12/databases" && pwd)
base_fusionador_sqlite=$(cd "../web2py/applications/fusionador_sqlite_v12/databases" && pwd)

mkdir ${base_dir%%/}/imagen

echo "fusionar en postgres"

python ../web2py/web2py.py -S fusionador_postgres_v12 -M -R ${base_dir%%/}/scripts_py/fusionar_postgres.py -A ${base_dir%%/}/${csv_ruta}

echo "crear csv de la postgres"

python ../web2py/web2py.py -S fusionador_postgres_v12 -M -R ${base_dir%%/}/scripts_py/crear_csv.py -A applications/fusionador_postgres_v12/databases/storage.csv

echo "exportar csv en sqlite"

#limpiar carpeta databases de fusionador_sqlite_v12
rm -f ${base_fusionador_sqlite%%/}/*

# Crear nuevas tablas de fusionador_sqlite_v12
python ../web2py/web2py.py -S fusionador_sqlite_v12 -M -R ${base_dir%%/}/scripts_py/crear_tablas.py

# Fusionar csv en sqlite
python ../web2py/web2py.py -S fusionador_sqlite_v12 -M -R ${base_dir%%/}/scripts_py/fusionar_sqlite.py -A applications/fusionador_postgres_v12/databases/storage.csv

# Mover base de datos a carpeta "imagen", borrando todo lo que contiene
rm -f ${base_dir%%/}/imagen/*
mv ${base_fusionador_sqlite%%/}/storage.sqlite ${base_dir%%/}/imagen/$(date +"%Y_%m_%d").sqlite

# Limpiar carpetas "databases"
rm -f ${base_fusionador_sqlite%%/}/*
rm -f ${base_fusionador_postgres%%/}/storage.csv
