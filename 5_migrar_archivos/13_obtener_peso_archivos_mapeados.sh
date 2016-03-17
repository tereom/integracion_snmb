#!/bin/bash

# Dada una entrega, en este script se enlistan los pesos de los archivos
# de entrada en "temp_basename(dir_entrega)_4_mapeo_rutas.csv".

# Por lo tanto, los archivos cuyo peso se enlista cumplen con lo siguiente:
# 1. Se encuentran registrados en la base de datos (ya que se pudo construir su
# ruta de salida).
# 2. Se encontraron físicamente en "dir_entrega" (puesto que cuentan con una
# ruta de entrada).

# Esta lista se utilizará para generar un reporte de archivos registrados en la
# base de datos fusionada en la entrega, que se encontraron físicamente, pero que
# posiblemente estén mal copiados o incompletos.

# Cabe destacar que los archivos registrados en la base de datos fusionada de la
# entrega, pero que no se encontraron físicamente en la misma, se enlistaron con
# anterioridad en: "7_crear_reporte_no_encontrados.R".

# Se prefirió migrar primero los archivos y, en caso de ser necesario, después
# reemplazar los archivos incompletos, para no quedarnos sin información en caso
# de que las instituciones se tarden en hacernos llegar las versiones completas
# de los archivos entregados.

# Input:
# dir_entrega: ruta de la carpeta donde están los clientes de captura, ésta se
# utilizará para obtener el archivo: "temp_basename(dir_entrega)_4_mapeo_rutas.csv",
# así como para guardar la lista de salida en la carpeta adecuada.
# Ejemplo: bash 13_obtener_peso_archivos_mapeados.sh /Volumes/sacmod/FMCN

# Output:
# Lista de la "ruta_entrada" de cada archivo en
# "temp_basename(dir_entrega)_4_mapeo_rutas.csv", junto con su peso en bytes:
# ${base_dir%%/}/reportes/temp_basename(dir_entrega)/productos/
# temp_basename(dir_entrega)_13_peso_archivos_mapeados.csv

# Además, se crea un reporte de archivos que se encontraron en
# "temp_basename(dir_entrega)_4_mapeo_rutas.csv", pero que por alguna razón no se
# les pudo calcular el peso:
# ${base_dir%%/}/reportes/temp_basename(dir_entrega)/productos/
# temp_basename(dir_entrega)_13_no_accedidos.txt

# Cabe destacar que el peso de los archivos se obtendrá de la fuente original
# (ruta_entrada), por flexibilidad de uso (que no sea necesario migrar los archivos
# para hacer este reporte). No obstante, el órden de los scripts enfatiza que éste
# debese hacer hasta después de migrados los archivos, por las razones antes
# mencionadas.

## Todo lo siguiente es para crear la ruta al archivo con el mapeo de rutas,
## así como la ruta donde se guardará el archivo de salida.

base_dir=$( cd "$( dirname "$0" )" && pwd )

# misma carpeta creada en "0_crear_carpetas_reportes"
nombre_carpeta=temp_"$(basename "$1")"

# la carpeta de productos especificada en "0_crear_carpetas_reportes.sh"
dir_archivos="${base_dir%%/}"/reportes/"$nombre_carpeta"/productos

# ruta del archivo con el mapeo de las rutas de los archivos en la entrega a las
# rutas en la estructura interna:
nombre_archivo_mapeo_rutas=temp_"$(basename "$1")"_4_mapeo_rutas_prueba_2.csv
ruta_archivo_mapeo_rutas="$dir_archivos"/"$nombre_archivo_mapeo_rutas"
#echo "$ruta_archivo_mapeo_rutas"

# creando la ruta del archivo que contendrá la lista de pesos de los archivos en
# "temp_basename(dir_entrega)_4_mapeo_rutas.csv"
nombre_archivo_pesos=temp_"$(basename "$1")"_13_peso_archivos_mapeados.csv
ruta_archivo_pesos="$dir_archivos"/"$nombre_archivo_pesos"
#echo "$ruta_archivo_pesos"

# creando la ruta del archivo que contendrá el reporte de archivos no accedidos,
# es decir, archivos cuyo peso no se pudo calcular por alguna razón:
nombre_archivo_no_accedidos=temp_"$(basename "$1")"_13_no_accedidos.txt
ruta_archivo_no_accedidos="$dir_archivos"/"$nombre_archivo_no_accedidos"

function crearListaPesos()
#$1: $ruta_archivo_mapeo_rutas
#$2: $ruta_archivo_pesos
#$3: $ruta_archivo_no_accedidos
#
{
	# obteniendo las rutas de entrada (primera columna del archivo:
	# "temp_basename(dir_entrega)_4_mapeo_rutas.csv")
	rutas_entrada="$(awk -F, '
	(NR > 1) {
			ruta_entrada = substr($1, 2, length($1) - 2);
			print ruta_entrada;
		}' "$1")"

	# como el output de awk viene separado por saltos de línea (no por espacios
	# no escapados), para bash, $rutas_entrada es simplemente un string muy largo:
	#echo "$rutas_entrada"

	# obteniendo un string separado por saltos de línea, con los pesos de los
	# archivos en "rutas_entrada", enviando los errores a "ruta_archivo_no_accedidos".

	lista_pesos_cruda="$(echo "$rutas_entrada" | xargs du 2>> "$3")"
	#echo "$lista_pesos_cruda"

	# la lista de pesos de cruda tiene el siguiente formato:
	# 32	/Users/fpardo/Desktop/.DS_Store
	# 0		/Users/fpardo/Desktop/.localized
	# 32	/Users/fpardo/Desktop/.Rhistory
	# 65376	/Users/fpardo/Desktop/base_conjunta.db
	# 8		/Users/fpardo/Desktop/convenciones_notacion

	# Donde el primer número corresponde al peso de cada archivo en bloques de
	# 512B, y el segundo corresponde a la "ruta_entrada" del mismo. Cabe destacar
	# que si no se pudo acceder a un archivo, éste no aparece en la lista, sino
	# que se encuentra en "temp_basename(dir_entrega)"_13_no_accedidos.txt

	# Formateando la lista de pesos cruda:
	# 1. se agregan nombres de campos.
	# 2. Se cambian las tabulaciones por comas.
	# 3. Se permutan los dos campos, y se calcula el peso en MB.
	lista_pesos="$(echo "$lista_pesos_cruda" | awk -F $'\t' '
		BEGIN {
			# código para poner encabezado a la tabla
			OFS=",";
			print "\"ruta_entrada\"" OFS "\"peso_mb\"";
		}
		1 {
			# código para cambiar la presentación de los datos.
			OFS=",";
			peso_mb = $1 * 512 / 1000000;
			print "\"" $2 "\"" OFS peso_mb;
		}')"
	# OFS: output field separator

	echo "$lista_pesos" > "$2"
}

if [ -f "$ruta_archivo_pesos" ]; then
	echo el archivo con la lista de pesos de los archivos mapeados ya fue creado
else
	crearListaPesos "$ruta_archivo_mapeo_rutas" "$ruta_archivo_pesos" \
	"$ruta_archivo_no_accedidos"

	# Si el archivo de no accedidos tiene un peso mayor a 0, enviar una advertencia.
	if [ -s "$ruta_archivo_no_accedidos" ]; then
		echo Advertencia: algunos archivos no pudieron ser accedidos, favor de \
		revisar el archivo \""${nombre_archivo_no_accedidos}"\", y solucionar el \
		problema antes de continuar
	fi
fi
