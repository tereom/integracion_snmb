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

# En este script, se crean dos reportes utilizando los archivos:
# temp_basename(dir_entrega)_8_lista_formatos.csv
# temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv

# El primero de ellos:
# temp_basename(dir_entrega)_11_formatos_no_asociados.csv

# Corresponde a los archivos en
# temp_basename(dir_entrega)_8_lista_formatos.csv
# que no se pudieron asociar a ninguna muestra en dir_entrega, al correr el script: 
# "9_mapear_rutas_formatos.R"

# Para ello, simplemente se hace anti_join de los contenidos de:
# temp_basename(dir_entrega)_8_lista_formatos.csv
# temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv
# (en orden), usando como llave "ruta_entrada" en este último.

# El segundo:
# temp_basename(dir_entrega)_11_formatos_por_cgl.csv

# Utiliza la información en:
# "temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv"
# "temp_basename(dir_entrega)_3_conglomerado_carpetas.rds"
# para hacer un resumen de cuántos formatos se tienen por muestreo de conglomerado.
# Cabe destacar que para que en realidad se encuentre en la estructura de carpetas
# el número de formatos que tiene cada muestra según esta relación, se tuvieron
# que haber podido migrar todos los archivos en el paso de migración, sin ningún
# error.

# Es importante destacar que este archivo únciamente habla de los formatos de campo
# asociados automáticamente a una muestra en "dir_entrega", por lo que no contempla
# los formatos mencionados en el primer reporte.

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
# "temp_basename(dir_entrega)_8_lista_formatos.csv"
# "temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv"
# "temp_basename(dir_entrega)_3_conglomerado_carpetas.rds"

dir_archivos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos")

# Archivo con la lista de (posibles) formatos en dir_entrega:
ruta_archivo_lista_formatos <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_8_lista_formatos_nueva.csv"
  )

# Archivo con la relación de las rutas de los formatos en dir_entrega, y la
# ruta que tendrán en la estructura de carpetas interna a CONABIO.
ruta_archivo_mapeo_rutas_formatos <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_9_mapeo_rutas_formatos.csv"
  )

# Objeto con la información de las muestras de conglomerado que se encuentran
# en dir_entrega:
ruta_objeto_conglomerado_carpetas <- paste0(
  dir_archivos,
  "/", "temp_", basename(dir_entrega), "_3_conglomerado_carpetas.rds"
  )

##################

# Formando el data frame de Rutas_entrada, con la lista de rutas a archivos con
# formatos de campo en "dir_entrega", más el nombre base de cada archivo enlistado.

# Leyendo las funciones para obtener el nombre base de archivos:
source("aux/obtener_nombre_base.R")

Rutas_entrada <- read_csv(ruta_archivo_lista_formatos, col_names = FALSE) %>%
  transmute(
    ruta_entrada = X1,
    nombre_entrada = splitPathFile(ruta_entrada)[[3]]
  )

# Leyendo el data frame con el mapeo de rutas
Mapeo_rutas <- read_csv(ruta_archivo_mapeo_rutas_formatos)
#glimpse(Mapeo_rutas)

# Leyendo el objeto con la información de muestreos del conglomerado:
Conglomerado_carpetas <- readRDS(ruta_objeto_conglomerado_carpetas) %>%
  mutate(
    cgl = as.integer(cgl)
  )
#glimpse(Conglomerado_carpetas)

##################

# Creando la tabla de formatos no asociados a ningún conglomerado, para ello, se
# hace el anti_join de "Rutas_entrada" con "Mapeo_rutas", utilizando "ruta_entrada"
# como llave.

Formatos_no_asociados <- Rutas_entrada %>%
  anti_join(Mapeo_rutas, by = "ruta_entrada")
#glimpse(Formatos_no_asociados)

#Guardando "Formatos_no_asociados" en un archivo csv:
ruta_archivo_formatos_no_asociados <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_11_formatos_no_asociados.csv"
  )

write_csv(Formatos_no_asociados, ruta_archivo_formatos_no_asociados)

##################

# Creando la tabla de Formatos_por_cgl, que contiene un resumen de cuántos formatos
# de campo fueron asociados automáticamente a cada muestra en "dir_entrega", al
# correr el script: "9_mapear_rutas_formatos.R". Para ello, se hará un left_join
# de "Conglomerado_carpetas", con "Mapeo_rutas", seguido de un summarise:

Formatos_por_cgl <- Conglomerado_carpetas %>%
  left_join(Mapeo_rutas, by = c("cgl", "fecha")) %>%
  mutate(
    cuenta = !is.na(ruta_entrada)
  ) %>%
  group_by(cgl, fecha, institucion.x) %>%
  summarise(
    num_formatos = sum(cuenta)
  ) %>%
  select(
    cgl,
    fecha,
    institucion = institucion.x,
    num_formatos
  ) %>%
  ungroup() %>%
  arrange(institucion, cgl, fecha)
View(Formatos_por_cgl)

#Resumen_formatos_por_cgl <- table(Formatos_por_cgl$num_formatos)

#Guardando "Formatos_por_cgl" en un archivo csv:
ruta_archivo_formatos_por_cgl <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_11_formatos_por_cgl.csv"
  )

write_csv(Formatos_por_cgl, ruta_archivo_formatos_por_cgl)



