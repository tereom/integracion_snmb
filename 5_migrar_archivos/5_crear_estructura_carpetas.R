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

# En este script, como su nombre lo indica, se crean en la estructura las carpetas
# donde se guardarán los archivos, ésto de acuerdo a su nueva ruta, creada en:
# "3_crear_nuevas_rutas.R". Por ello, se utilizan los objetos:
# "temp_sacmod_ruta_estructura.rds"
# "temp_sacmod_conglomerado_carpetas.rds"
# creados en dicho archivo.

library("plyr")
library("dplyr")
library("tidyr")
library("readr")

# Nombre de la carpeta donde se encuentran los archivos (éste se pide para formar
# las rutas hacia los objetos calculados con anterioridad).
dir_entrega <- args[1]
#dir_entrega <- "/Volumes/sacmod"

dir_objetos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos_intermedios"
  )

ruta_objeto_ruta_estructura <- paste0(
  dir_objetos,
  "/", "temp_sacmod_ruta_estructura.rds"
  )

ruta_objeto_conglomerado_carpetas <- paste0(
  dir_objetos,
  "/", "temp_sacmod_conglomerado_carpetas.rds"
  )

#Leyendo ambos objetos:
ruta_estructura <- readRDS(ruta_objeto_ruta_estructura)
Conglomerado_carpetas <- readRDS(ruta_objeto_conglomerado_carpetas)

# Creando la estructura de carpetas:
dir.create(ruta_estructura)

rutas_cgl_anio_mes <- paste0(ruta_estructura, "/", Conglomerado_carpetas$cgl_anio_mes)
resultados_crear_carpetas <- ldply(ruta_cgl_anio_mes, dir.create, recursive = TRUE)

subcarpetas <- c(
  "fotos_videos",
  "grabaciones_audibles",
  "grabaciones_ultrasonicas",
  "especies_invasoras",
  "huellas_excretas",
  "registros_extra",
  "referencias",
  "otros"
  )

rutas_subcarpetas <- expand.grid(x = rutas_cgl_anio_mes, y = subcarpetas,
  stringsAsFactors = FALSE) %>%
  mutate(
    rutas = paste0(x, "/", y)
    ) %>%
  .$rutas

resultados_crear_subcarpetas <- ldply(rutas_subcarpetas, dir.create)

# resultados_crear_subcarpetas se puede utilizar a modo de validación de que no
# hay problemas con los datos, ya que cada subcarpeta corresponde a un determinado
# muestreo del conglomerado (definido en el espacio y el tiempo). Éstas siempre se
# deberían poder crear. No así con las anteriores, puesto que se crean de manera
# recursiva. Hay que guardarlo como objeto, tanto "rutas_subcarpetas" como
# "resultados_crear_subcarpetas"