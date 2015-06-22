#!/bin/bash 

# Argumentos
# dir: ruta a la carpeta que contiene el archivo .sqlite
# Ejemplo: bash exportar.sh /Volumes/sacmod/FMCN

# Directorio dentro de web2py (variable global)
base_web2py=web2py/web2py.app/Contents/Resources/applications/cliente_web2py/databases
base_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
# ${BASH_SOURCE[0]}: nombre del script

# Creamos la carpeta bases (en caso de que no exista)
# Comenzamos borrando las bases en la carpeta bases para tener una sesión nueva
rm -rfv ${base_dir%%/}/bases/*

# # Exportar la base de datos
exporta_csv () {
	echo "Limpiar carpeta databases"
	# Borrar los contenidos del directorio databases
	rm -rfv ${base_web2py%%/}/*

	# Crear nuevas tablas 
	web2py/web2py.app/Contents/MacOS/web2py -S cliente_web2py -M -R ${base_dir%%/}/scripts_py/borrar_tabla.py

	# Copiar base de datos sqlite que nos entregaron y pegarla en el cliente
	echo "reemplazar"
	cp $1 ${base_web2py%%/}/storage.sqlite

	# Exportar la base de datos
	# # -M importar modelos, -R correr script de python
	web2py/web2py.app/Contents/MacOS/web2py -S cliente_web2py -M -R ${base_dir%%/}/scripts_py/exportar.py

	# # Renombro archivo
	nuevo_nom=bases/snmb_$2.csv
	mv ${base_web2py%%/}/snmb.csv $nuevo_nom
}


fileArray=($(find $1 -name 'storage.sqlite'))
# get length of an array
tLen=${#fileArray[@]}

# use for loop read all filenames
for (( i=0; i<${tLen}; i++ ));
do
  #echo "${fileArray[$i]}"
  exporta_csv "${fileArray[$i]}" $i
done

# Antes de fusionar borrar todo lo del folder databases del fusionador
base_fusionador=web2py/web2py.app/Contents/Resources/applications/fusionador_hf/databases

rm -rfv ${base_fusionador%%/}/*

web2py/web2py.app/Contents/MacOS/web2py -S fusionador_hf -M -R ${base_dir%%/}/scripts_py/fusionar.py -A ${base_dir%%/}/bases

mv ${base_fusionador%%/}/storage.sqlite ${base_dir%%/}/bases/storage.sqlite

rm -rfv ${base_web2py%%/}/*