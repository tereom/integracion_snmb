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

# Dada una entrega, en este script se crea un reporte de imágenes, videos y
# archivos de sonido registrados en la base de datos de la entrega, que se migraron
# a la estructura de archivos (por lo tanto, que se encontraron físicamente),
# pero que, sin embargo, su peso es menor o igual a cierto umbral (que depende
# del tipo de archivo y que tunearemos posteriormente), por lo que posiblemente
# estén incompletos:
# 14_posiblemente_incompletos.csv

# Para hacer este reporte, se requiere del archivo:
# temp_basename(dir_entrega)_4_mapeo_rutas.csv
# que contiene la información de cada archivo, por ejemplo, institución o
# nombre original.

# También se requiere de la lista con el peso de los archivos en
# "temp_basename(dir_entrega)_4_mapeo_rutas.csv", a saber:
# temp_basename(dir_entrega)_13_peso_archivos_mapeados.csv

# Se puede hacer el join de las tablas contenidas en ambos archivos por medio del
# campo: "ruta_entrada".

# Para validar que todos los archivos enlistados en la columna "ruta_entrada"
# tienen peso calculado, se verificará, antes que nada, que el siguiente archivo
# esté vacío:
# temp_basename(dir_entrega)_13_no_accedidos.txt

# Nota:
# Se prefirió migrar primero los archivos y, en caso de ser necesario, después
# reemplazar los archivos incompletos, para no quedarnos sin información en caso
# de que las instituciones se tarden en hacernos llegar las versiones completas
# de los archivos entregados. No obstante, como "13_obtener_peso_archivos_mapeados.sh"
# utiliza en nombre de entrada de cada archivo en "temp_basename(dir_entrega)_4_mapeo_rutas.csv"
# para calcular los pesos, en realidad, se puede correr este reporte antes de
# migrar los archivos.

# Adicionalmente al reporte mencionado anteriormente, y debido a su inminente
# utilidad, se guarda una tabla auxiliar que básicamente es la contenida en
# "temp_basename(dir_entrega)_4_mapeo_rutas.csv" con 2 campos extra: peso y tipo
# de archivo. Ésta se guarda como un objeto de R en:
# temp_basename(dir_entrega)_14_mapeo_rutas_info_adicional.rds

library("plyr")
library("dplyr")
library("tidyr")
library("readr")
library("stringi")

args <- commandArgs(trailingOnly = TRUE)

# Leyendo el directorio de la entrega, con el fin de crear las rutas para los
# archivos de input/output.
dir_entrega <- args[1]
#dir_entrega <- "/Volumes/sacmod"

# Creando el directorio hacia los archivos:
# temp_basename(dir_entrega)_4_mapeo_rutas.csv
# temp_basename(dir_entrega)_13_peso_archivos_mapeados.csv

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

# Archivo con el peso de cada uno de los archivos enlistados en la columna de
# "ruta_entrada", de "temp_basename(dir_entrega)_4_mapeo_rutas.csv":
ruta_archivo_peso_archivos_mapeados <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_13_peso_archivos_mapeados.csv"
  )

# Archivo con la información de los archivos cuyo peso no pudo ser calculado en:
# "13_obtener_peso_archivos_mapeados.sh".

ruta_archivo_no_accedidos <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_13_no_accedidos.txt"
  )

##################
# Primero se validará que no hayan archivos que se encontraron físicamente en
# dir_entrega (cuando se creó "temp_basename(dir_entrega)_4_mapeo_rutas.csv"),
# cuyo peso no pudo ser calculado:


if(file.info(ruta_archivo_no_accedidos)$size > 0){
  stop(paste0("Existen algunos archivos enlistados a los que no se les pudo ",
    "calcular el peso, favor de revisar el archivo: ",
    "temp_", basename(dir_entrega), "_13_no_accedidos.txt"))
}

##################

Rutas_entrada_salida <- read_csv(ruta_archivo_mapeo_rutas)
#glimpse(Rutas_entrada_salida)

Peso_archivos_info <- read_csv(ruta_archivo_peso_archivos_mapeados)
#glimpse(Peso_archivos_info)

# Obteniendo la tabla auxiliar de información acerca de los archivos mapeados,
# ésta es simplemente "Rutas_entrada_salida" con dos campos extra: el peso del
# archivo y el tipo de archivo.

Archivos_mapeados_info <- Rutas_entrada_salida %>%
  # haciendo el join de ambas tablas por "ruta_entrada", para asociar a cada archivo
  # en esa tabla, su peso en MB. Cabe destacar que se hace "left_join" para no
  # perder del reporte los archivos que, en un principio, fueron encontrados
  # tanto en la base de datos como físicamente, pero después no se pudo leer su
  # peso por algún motivo.
  left_join(Peso_archivos_info, by = "ruta_entrada") %>%
  
  # eliminando duplicados que pudieran surgir por artefacto el join, por ejemplo,
  # si en un caso muy raro hay duplicados en "ruta_entrada", entonces el join
  # duplicaría artificialmente esos registros.
  filter(!duplicated(.)) %>%
  
  # obteniendo el tipo de archivo de acuerdo a la terminación, y, en algunos casos,
  # de acuerdo a la carpeta en la que se guardó el mismo:
  mutate(
    # se usa la ruta de salida para obtener el tipo de archivo, puesto que es
    # mucho más simple (y por lo tanto, más fácil de prevenir errores) que la
    # ruta de entrada.
    tipo_archivo = ifelse(
      stri_detect_regex(ruta_salida, "\\.wav", case_insensitive = TRUE),
      "grabación",
      ifelse(
        stri_detect_regex(ruta_salida, "\\.(jpg|jpeg)", case_insensitive = TRUE),
        "imagen",
        ifelse(
          stri_detect_regex(ruta_salida, "\\.(avi|mov)", case_insensitive = TRUE),
          "video",
          "otro"
          )
        )
      )
  ) %>%
  mutate(
    # ahora se verá si cada grabación es audible o ultrasónica, viendo la carpeta
    # de salida correspondiente.
    tipo_archivo = ifelse(
      tipo_archivo != "grabación",
      tipo_archivo,
      ifelse(
        stri_detect_coll(ruta_salida, "grabaciones_audibles"),
        "grabación audible",
        ifelse(
          stri_detect_coll(ruta_salida, "grabaciones_ultrasonicas"),
          "grabación ultrasónica",
          "grabación mal ubicada"
          )
        )
      )
  )

# Guardando "Archivos_mapeados_info" en un objeto RDS:

ruta_objeto_mapeo_rutas_info_adicional <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_14_mapeo_rutas_info_adicional.rds"
  )

saveRDS(Archivos_mapeados_info, ruta_objeto_mapeo_rutas_info_adicional)
#readRDS(ruta_objeto_mapeo_rutas_info_adicional)

# Ahora sí, utilizando "Archivos_mapeados_info" para generar el reporte de archivos
# posiblemente incompletos:

# Definiendo umbrales para las imágenes, videos, grabaciones audibles y grabaciones
# ultrasónicas. Cualquier archivo en "Archivos_mapeados_info" cuyo peso es menor
# o igual a dicho umbral, quedará reportado como posiblemente incompleto

umbral_grabacion_audible <- 0
umbral_grabacion_ultrasonica <- 0
umbral_imagen <- 0
umbral_video <- 0

Archivos_posiblemente_incompletos <- Archivos_mapeados_info %>%
  # definiendo el filtro con el que se van a obtener los archivos posiblemente
  # incompletos, por medio de los campos "tipo_archivo" y "peso_mb"
  mutate(
    posiblemente_incompleto = ifelse(
      tipo_archivo == "imagen",
      ifelse(peso_mb <= umbral_imagen, TRUE, FALSE),
        # si peso_mb es NA (que puede pasar si, por ejemplo, por falta de permisos
        # no se puede leer el peso de un archivo, y no se corrige ésto), entonces
        # posiblemente incompleto va a valer NA.
      ifelse(
        tipo_archivo == "video",
        ifelse(peso_mb <= umbral_video, TRUE, FALSE),
        ifelse(
          tipo_archivo == "grabación audible",
          ifelse(peso_mb <= umbral_grabacion_audible, TRUE, FALSE),
          ifelse(
            tipo_archivo == "grabación ultrasónica",
            ifelse(peso_mb <= umbral_grabacion_ultrasonica, TRUE, FALSE),
            NA
          )
        )
      )
    )
  ) %>%
  
  # Este filtro deja fuera los FALSE y NA's.
  filter(posiblemente_incompleto)
  
#Guardando "Archivos_posiblemente_incompletos" en un archivo csv:
ruta_posiblemente_incompletos <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_14_posiblemente_incompletos.csv"
  )

write_csv(Archivos_posiblemente_incompletos, ruta_posiblemente_incompletos)





