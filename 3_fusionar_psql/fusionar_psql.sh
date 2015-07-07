#!/bin/bash 

# Argumentos:
# csv_ruta: ruta al archivo csv a fusionar en la base de datos final

# Por seguridad de los datos, se deberá encender el servidor de la base postgresql
# antes de correr este script.

csv_ruta=$1

base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

../web2py/web2py.app/Contents/MacOS/web2py -S fusionador_postgres -M -R ${base_dir%%/}/scripts_py/fusionar_psql.py -A ${base_dir%%/}/${csv_ruta}