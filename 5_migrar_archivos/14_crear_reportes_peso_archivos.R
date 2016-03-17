# Este script constituye un paso para copiar los archivos guardados en uno
# o varios clientes de captura a la estructura de carpetas del SNMB:

#estructura:
# nombre_estructura
# ├───conglomerado
# |   ├───anio_mes
# |   |   |   formato_campo.pdf
# |   |   ├───fotos_videos
# |   |   ├───grabaciones_audibles
# |   |   ├───grabaciones_ultrasonicas
# |   |   ├───especies_invasoras
# |   |   ├───huellas_excretas
# |   |   ├───registros_extra
# |   |   ├───referencias
# |   |   ├───otros
# ...
# ├───aaaa_mm_dd_no_reg
# |   ├───fotos_videos
# |   ├───audio
# |   ├───archivos_pdf

# Dada una entrega, en este script se crean un reporte de imágenes, videos y
# archivos de sonido registrados en la base de datos de la entrega, que se migraron
# a la estructura de archivos (por lo tanto, que se encontraron físicamente),
# pero que, sin embargo, su peso es menor o igual a cierto umbral (que depende
# del tipo de archivo y que tunearemos posteriormente), por lo que posiblemente
# estén incompletos.

# Para hacer este reporte, se requiere el archivo:
# temp_basename(dir_entrega)_4_mapeo_rutas.csv
# para obtener los nombres original y web2py de cada archivo guardado en la estructura
# de datos.

# Se prefirió migrar primero los archivos y, en caso de ser necesario, después
# reemplazar los archivos incompletos, para no quedarnos sin información en caso
# de que las instituciones se tarden en hacernos llegar las versiones completas
# de los archivos entregados.

library("plyr")
library("dplyr")
library("tidyr")
library("readr")

args <- commandArgs(trailingOnly = TRUE)

# Leyendo el directorio de la entrega, con el fin de crear las rutas para los
# archivos de input/output.
dir_entrega <- args[1]
#dir_entrega <- "/Volumes/sacmod"

# Creando el directorio hacia el archivo:
# temp_basename(dir_entrega)_4_mapeo_rutas.csv

dir_archivos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos")

# Archivo con el mapeo de las rutas origen/destino de cada uno de los archivos en
# la entrega:
ruta_archivo_mapeo_rutas <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_4_mapeo_rutas.csv"
  )

Rutas_entrada_salida <- read_csv(ruta_archivo_mapeo_rutas)
glimpse(Rutas_entrada_salida)

# pasarlo a Bash...

# Dada una entrega, en este script se crean un reporte de imágenes, videos y
# archivos de sonido registrados en la base de datos de la entrega, que se migraron
# a la estructura de archivos (por lo tanto, que se encontraron físicamente),
# pero que, sin embargo, su peso es menor o igual a cierto umbral (que depende
# del tipo de archivo y que tunearemos posteriormente), por lo que posiblemente
# estén incompletos.

# Se prefirió migrar primero los archivos y, en caso de ser necesario, después
# reemplazar los archivos incompletos, para no quedarnos sin información en caso
# de que las instituciones se tarden en hacernos llegar las versiones completas
# de los archivos entregados.

# Input:
# dir_entrega: ruta de la carpeta donde están los clientes de captura, ésta se
# utilizará para obtener el archivo: "temp_basename(dir_entrega)_4_mapeo_rutas.csv",
# así como para guardar el reporte de salida en la carpeta adecuada.
# Ejemplo: bash 13_crear_reportes_peso_archivos.sh /Volumes/sacmod/FMCN

# Output:
# Reporte con la misma información que "temp_basename(dir_entrega)_4_mapeo_rutas.csv",
# además del peso de imágenes/videos/sonidos, para archivos con dicho valor por
# debajo de ciertos umbrales:
# ${base_dir%%/}/reportes/temp_basename(dir_entrega)/productos/
# temp_basename(dir_entrega)_13_archivos_incompletos.csv

# Además, se crea un reporte de archivos que por alguna razón no se les pudo
# calcular el peso:
# ${base_dir%%/}/reportes/temp_basename(dir_entrega)/productos/
# temp_basename(dir_entrega)_13_archivos_no_accedidos.csv

# Cabe destacar que el peso de los archivos se obtendrá de la fuente original
# (ruta_entrada), por flexibilidad de uso (que no sea necesario migrar los archivos
# para hacer este reporte). No obstante, el órden de los scripts enfatiza que éste
# debese hacer hasta después de migrados los archivos, por las razones antes
# mencionadas.

## Todo lo siguiente es para crear la ruta al archivo con el mapeo de rutas,
## así como la ruta donde se guardará el archivo de salida.

