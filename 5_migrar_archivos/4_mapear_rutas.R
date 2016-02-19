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

# En este script, como su nombre lo indica, se hace el join de la lista de rutas
# originales de cada archivo, con las rutas nuevas creadas a partir de la base de
# datos, por medio del nombre de archivo.

library("plyr")
library("dplyr")
library("tidyr")
library("readr")

args <- commandArgs(trailingOnly = TRUE)

# Leyendo el directorio de la entrega, con el fin de localizar los archivos que
# contienen la información de las rutas origen y destino
dir_entrega <- args[1]
#dir_entrega <- "/Volumes/sacmod"

# Creando el directorio hacia los archivos:
# "temp_sacmod_lista.csv" y "temp_sacmod_existencia.csv"
directorio_archivos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos_intermedios")

# Archivo con las rutas actuales de los archivos a migrar:
# temp_basename(dir_entrega)_lista.csv
ruta_archivo_origen <- paste0(
  directorio_archivos,
  "/temp_", basename(dir_entrega), "_lista.csv"
  )

# Archivo con la validación de la existencia de los archivos a migrar:
ruta_archivo_existencia <- paste0(
  directorio_archivos,
  "/temp_", basename(dir_entrega), "_existencia.csv"
)

# Archivo con las rutas nuevas que tendrán los archivos:
# temp_basename(dir_entrega)_nuevas_rutas.csv
ruta_archivo_destino <- paste0(
  directorio_archivos,
  "/temp_", basename(dir_entrega), "_nuevas_rutas.csv"
  )

Rutas_origen <- read_csv(ruta_archivo_origen, col_names = FALSE)
#glimpse(Rutas_origen)

existencia <- read_csv(ruta_archivo_existencia, col_names = FALSE)
#table(existencia)

Rutas_destino <- read_csv(ruta_archivo_destino) %>%
  filter(!duplicated(.$ruta_salida))
#glimpse(Rutas_destino)



