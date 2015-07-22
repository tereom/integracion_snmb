#!/bin/bash 

# Argumentos
# dir: ruta a la carpeta que contiene los archivos .sqlite
# Ejemplo: bash exportar.sh /Volumes/sacmod/FMCN

# El && sirve para ejecutar una acción si y sólo si la anterior fue exitosa.
base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# ${BASH_SOURCE[0]}: nombre del script
# echo $base_dir

# Directorio dentro de web2py (variable global)
base_web2py=$(cd "../web2py/applications/cliente_v10/databases" && pwd)
#echo $base_web2py
# Creamos la carpeta bases (en caso de que no exista)
mkdir ${base_dir%%/}/bases

# Comenzamos borrando las bases/csv en la carpeta bases para tener una sesión nueva
rm -f ${base_dir%%/}/bases/*.{sqlite,csv}

# # Exportar la base de datos
exporta_csv () {
	echo "limpiar carpeta databases"
	# Borrar los contenidos del directorio databases
	rm -f ${base_web2py%%/}/*

	# Crear nuevas tablas
	# -M es para cargar los modelos de la aplicación utilizada.
	python ../web2py/web2py.py -S cliente_v10 -M -R ${base_dir%%/}/scripts_py/crear_tablas.py

	# Copiar base de datos sqlite que nos entregaron y pegarla en el cliente
	echo "reemplazar"
	cp $1 ${base_web2py%%/}/storage.sqlite

	echo "exportar"
	# Exportar la base de datos
	# -M importar modelos, -R correr script de python
	python ../web2py/web2py.py -S cliente_v10 -M -R ${base_dir%%/}/scripts_py/exportar.py

	# Renombro archivo
	nuevo_nom=bases/snmb_$2.csv
	mv ${base_web2py%%/}/snmb.csv $nuevo_nom
}

# Buscando todos los archivos "storage.sqlite" en el directorio de entrada:

DIR="$1"
 
# failsafe - regresar al directorio actual si no se especifica nada
[ "$DIR" == "" ] && DIR="."
 
# guardar IFS anteriores y cambiarlos. IFS es el separador que utiliza bash para
# crear un arreglo (el default es espacios)
OLDIFS=$IFS
IFS=$'\n'
 
# crear el arreglo con los paths a los archivos "storage.sqlite"
fileArray=($(find $DIR -name 'storage.sqlite'))
  
# obtener longitud del arreglo
tLen=${#fileArray[@]}
 
# leyendo los elementos del arreglo
for (( i=0; i<${tLen}; i++ ));
do
  echo "${fileArray[$i]}"
  exporta_csv "${fileArray[$i]}" $i

done

# restaurar IFS
IFS=$OLDIFS


# Antes de fusionar borrar todo lo del folder databases del fusionador
base_fusionador=$(cd "../web2py/applications/fusionador_sqlite_v10/databases" && pwd)

rm -f ${base_fusionador%%/}/*

python ../web2py/web2py.py -S fusionador_sqlite_v10 -M -R ${base_dir%%/}/scripts_py/fusionar_sqlite.py -A ${base_dir%%/}/bases

mv ${base_fusionador%%/}/storage.sqlite ${base_dir%%/}/bases/storage.sqlite

mv ${base_fusionador%%/}/storage.csv ${base_dir%%/}/bases/storage.csv

rm -f ${base_web2py%%/}/*