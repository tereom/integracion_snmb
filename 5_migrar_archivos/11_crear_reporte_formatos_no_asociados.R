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

# En este script, como su nombre lo indica, se enlistan los archivos en

# temp_basename(dir_entrega)_8_lista_formatos.csv

# que no se pudieron asociar a ningún muestreo de conglomerado en dir_entrega, al
# correr el script: "9_mapear_rutas_formatos.R". Para ello, simplemente se toma
# el archivo anterior, y se hace el anti_join con

# temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv
# por ruta de entrada de este último.

# El reporte salida se guarda en:
# temp_basename(dir_entrega)_11_formatos_no_asociados.csv

library("plyr")
library("dplyr")
library("tidyr")
library("readr")

args <- commandArgs(trailingOnly = TRUE)

# Leyendo el directorio de la entrega, con el fin de crear las rutas para los
# archivos de input/output.
dir_entrega <- args[1]
#dir_entrega <- "/Volumes/sacmod"

# Creando el directorio hacia los archivos:
# "temp_basename(dir_entrega)_8_lista_formatos.csv" y
# "temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv"
directorio_archivos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos")

# Archivo con la lista de (posibles) formatos en dir_entrega:
ruta_archivo_lista_formatos <- paste0(
  directorio_archivos,
  "/temp_", basename(dir_entrega), "_8_lista_formatos_nueva.csv"
  )

# Archivo con la relación de las rutas de los formatos en dir_entrega, y la
# ruta que tendrán en la estructura de carpetas interna a CONABIO.
ruta_archivo_mapeo_rutas_formatos <- paste0(
  directorio_archivos,
  "/temp_", basename(dir_entrega), "_9_mapeo_rutas_formatos.csv"
  )

##################

# Formando el data frame de Rutas_entrada, con la lista de rutas a archivos con
# formatos de campo en "dir_entrega", más el nombre base de cada archivo enlistado.

# Leyendo las funciones para obtener el nombre base de archivos:
source("aux/4_funciones.R")

Rutas_entrada <- read_csv(ruta_archivo_lista_formatos, col_names = FALSE) %>%
  transmute(
    ruta_entrada = X1,
    nombre_entrada = splitPathFile(ruta_entrada)[[3]]
  )

##################

# Leyendo el data frame con el mapeo de rutas
Mapeo_rutas <- read_csv(ruta_archivo_mapeo_rutas_formatos)
#glimpse(Mapeo_rutas)

##################

# Creando la tabla de formatos no asociados a ningún conglomerado, para ello, se
# hace el anti_join de "Rutas_entrada" con "Mapeo_rutas", utilizando "ruta_entrada"
# como llave.

Formatos_no_asociados <- Rutas_entrada %>%
  anti_join(Mapeo_rutas, by = "ruta_entrada")
#glimpse(Formatos_no_asociados)

#Guardando "Formatos_no_asociados" en un archivo csv:
ruta_archivo_formatos_no_asociados <- paste0(
  directorio_archivos,
  "/temp_", basename(dir_entrega), "_11_formatos_no_asociados.csv"
  )

write_csv(Formatos_no_asociados, ruta_archivo_formatos_no_asociados)





