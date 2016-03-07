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

# En este script, como su nombre lo indica, se crea un reporte de archivos que
# se registraron en la base de datos, pero que no se encontraron en "dir_entrega",
# es decir, archivos que no se entregaron a Conabio.
# Este reporte se guarda en:
# reportes/temp_basename(dir_entrega)/productos/
# temp_basename(dir_entrega)_7_no_encontrados.csv

# Para este reporte se utilizan los archivos:
# temp_basename(dir_entrega)_1_lista.csv (lista de archivos en dir_entrega)
# temp_basename(dir_entrega)_3_nuevas_rutas.csv (tabla con nuevas rutas para los
# archivos, basadas en la información de la base de datos).

# Además de lo anterior, se guarda un reporte simplificado en:
# temp_basename(dir_entrega)_7_no_encontrados_simplificado.csv

# Y un archivo resumen de archivos faltantes por conglomerado y fecha en:
# temp_basename(dir_entrega)_7_resumen_no_encontrados.csv


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
# "temp_basename(dir_entrega)_1_lista.csv" y
# "temp_basename(dir_entrega)_3_nuevas_rutas.csv"
dir_archivos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos")

# Archivo con las rutas actuales de los archivos a migrar:
ruta_archivo_lista <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_1_lista.csv"
  )

# Archivo con las rutas nuevas generadas a partir de la base de datos:
ruta_archivo_nuevas_rutas <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_3_nuevas_rutas.csv"
  )

##################

# Formando el data frame de Rutas_entrada, con la lista de archivos en "dir_entrega",
# más el nombre base de cada archivo enlistado.

# Leyendo las funciones para obtener el nombre base de archivos:
source("aux/obtener_nombre_base.R")

Rutas_entrada <- read_csv(ruta_archivo_lista, col_names = FALSE) %>%
  mutate(
    ruta_entrada = X1,
    nombre_entrada = splitPathFile(ruta_entrada)[[3]]
  ) %>%
  select(-X1)
#glimpse(Rutas_entrada)

##################

# Leyendo el data frame con las nuevas rutas (rutas de salida)
Rutas_salida <- read_csv(ruta_archivo_nuevas_rutas)
#glimpse(Rutas_salida)

##################

# Formando la tabla de archivos no encontrados Para ello, se encuentran los archivos
# en "Rutas_salida", que no tienen correspondiente en "Rutas_entrada", es decir,
# archivos registrados en la base de datos, que no se encuentran en "dir_entrega":

Archivos_no_encontrados <- Rutas_salida %>%
  anti_join(Rutas_entrada, by = c("nombre_web2py" = "nombre_entrada"))
#glimpse(Archivos_no_encontrados)

#Archivos_encontrados <- Rutas_salida %>%
  #semi_join(Rutas_entrada, by = c("nombre_web2py" = "nombre_entrada"))
#glimpse(Archivos_encontrados)

# Comprobando:
#nrow(Rutas_salida) == nrow(Archivos_no_encontrados) + nrow(Archivos_encontrados)

#Guardando "Archivos_no_encontrados" en un archivo csv:
ruta_archivo_no_encontrados <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_7_no_encontrados.csv"
  )

write_csv(Archivos_no_encontrados, ruta_archivo_no_encontrados)

##################

# Creando reporte para CONAFOR, CONANP y FMCN:

Archivos_no_encontrados_simple <- Archivos_no_encontrados %>%
  select(
    cgl,
    fecha,
    nombre_original,
    nombre_web2py,
    institucion
  )

#Guardando "Archivos_no_encontrados_simple" en un archivo csv:
ruta_archivo_no_encontrados_simple <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_7_no_encontrados_simple.csv"
  )

write_csv(Archivos_no_encontrados_simple, ruta_archivo_no_encontrados_simple)

##################

# Creando el resumen de archivos no encontrados: número de archivos no encontrados
# por institucion, conglomerado y fecha

Resumen_no_encontrados <- Archivos_no_encontrados %>%
  group_by(fecha, cgl, institucion) %>%
  tally() %>%
  ungroup() %>%
  arrange(institucion, fecha, cgl)

#Guardando "Resumen_no_encontrados" en un archivo csv:
ruta_archivo_resumen_no_encontrados <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_7_resumen_no_encontrados.csv"
  )

write_csv(Resumen_no_encontrados, ruta_archivo_resumen_no_encontrados)








