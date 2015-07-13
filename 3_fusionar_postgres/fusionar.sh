#!/bin/bash 

# Argumentos:
# csv_ruta: ruta al archivo csv a fusionar en la base de datos final.
# Ejemplo: bash fusionar.sh ../1_exportar_sqlite/bases/storage.csv

# Por seguridad de los datos, se deberá encender el servidor de la base postgresql
# antes de correr este script.

csv_ruta=$1

base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

python ../web2py/web2py.py -S fusionador_postgres -M -R ${base_dir%%/}/scripts_py/fusionar_postgres.py -A ${base_dir%%/}/${csv_ruta}