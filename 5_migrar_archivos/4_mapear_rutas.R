# Este script constituye un paso para copiar los archivos guardados en uno
# o varios clientes de captura a la estructura de carpetas del SNMB:

#estructura:
# nombre_estructura
# ├───conglomerado
# |   ├───anio_mes
# |   |   ├───formato_campo
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
# datos, usando el nombre de archivo como llave. Éste join se guarda en el archivo:
# reportes/temp_basename(ruta_entrega)/productos/
# temp_basename(dir_entrega)_4_mapeo_rutas.csv


library("plyr")
library("dplyr")
library("tidyr")
library("readr")

args <- commandArgs(trailingOnly = TRUE)

# Leyendo el directorio de la entrega, con el fin de localizar los archivos que
# contienen la información de las rutas de entrada y salida.
dir_entrega <- args[1]
#dir_entrega <- "/Volumes/sacmod"

# Creando el directorio hacia los archivos:
# "temp_basename(dir_entrega)_1_lista.csv" y "temp_basename(dir_entrega)_2_existencia.csv"
dir_archivos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos")

# Archivo con las rutas actuales de los archivos a migrar:
ruta_archivo_lista <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_1_lista.csv"
  )

# Archivo con la validación de la existencia de los archivos a migrar:
ruta_archivo_existencia <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_2_existencia.csv"
)

# Archivo con las rutas nuevas que tendrán los archivos:
# temp_basename(dir_entrega)_nuevas_rutas.csv
ruta_archivo_nuevas_rutas <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_3_nuevas_rutas.csv"
  )

##################
# Primero se validará que se pueda acceder a todos los archivos enlistados:
existencia <- read_csv(ruta_archivo_existencia, col_names = FALSE)

tabla_existencia <- table(existencia)

if("FALSE" %in% names(tabla_existencia)){
  stop(paste0("Existen algunos archivos enlistados a los que no se puede acceder, ",
    "favor de revisar el archivo: ",
    "temp_", basename(dir_entrega), "_2_existencia.csv"))
}
##################

# Formando el data frame de Rutas_entrada, con la lista de archivos en "dir_entrega",
# más el nombre base de cada archivo enlistado.

# Leyendo las funciones para obtener el nombre base de archivos:
source("aux/obtener_nombre_base.R")

Rutas_entrada <- read_csv(ruta_archivo_lista, col_names = FALSE) %>%
  transmute(
    ruta_entrada = X1,
    nombre_entrada = splitPathFile(ruta_entrada)[[3]]
  )
#glimpse(Rutas_entrada)

##################

#Leyendo el data frame con las nuevas rutas (rutas de salida)
Rutas_salida <- read_csv(ruta_archivo_nuevas_rutas)
#glimpse(Rutas_salida)

##################

#Formando la tabla que mapea las rutas. Cabe destacar que si un archivo está
#repetido en dir_entrega (con dos rutas distintas), entonces, a la hora de hacer
#el join por el nombre del archivo, aparecerán registros con distinta ruta de entrada
#pero misma ruta de salida. Para optimizar rendimiento, conviene quitar archivos con
#la misma ruta de salida.

#Obviamente, archivos que no están registrados en la base de datos no tienen una
#ruta de salida, y son omitidos en la tabla de "Rutas_entrada_salida".

Rutas_entrada_salida <- Rutas_entrada %>%
  inner_join(Rutas_salida, by = c("nombre_entrada" = "nombre_web2py")) %>%
  mutate(
    nombre_web2py = nombre_entrada
  ) %>%
  select(-nombre_entrada) %>%
  filter(!duplicated(.$ruta_salida))
#glimpse(Rutas_entrada_salida)

#Obteniendo tipos de archivo:
# tipos_archivo <- Rutas_entrada_salida %>%
#   mutate(
#     terminacion = substring(nombre_web2py, nchar(nombre_web2py)-2, nchar(nombre_web2py))
#   ) %>%
#   group_by(terminacion) %>%
#   tally()

#Guardando "Rutas_entrada_salida" en un archivo csv:
ruta_archivo_mapeo_rutas <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_4_mapeo_rutas.csv"
  )

write_csv(Rutas_entrada_salida, ruta_archivo_mapeo_rutas)





