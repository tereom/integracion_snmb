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
# "temp_basename(ruta_entrega)_3_ruta_estructura.rds"
# "temp_basename(ruta_entrega)_3_conglomerado_carpetas.rds"
# creados en el paso 3.

# Además de crearse la estructura de carpetas, al correr este script, se genera el
# archivo:
# reportes/temp_basename(ruta_entrega)/productos_intermedios/
# temp_basename(dir_entrega)_5_cgl_muestra_carpetas.csv
# que sirve para verificar que se pudieron crear las carpetas correspondientes
# a cada muestra de cada conglomerado. Si ésto no fue así, y se descartaron
# problemas de conexión, lo más probable es que las carpetas se hayan creado con
# anterioridad, lo que puede significar que existe algún problema con los datos.
# Por ello, si se encuentra un problema, el script avisará inmediatamente.

# Se genera también el archivo:
# reportes/temp_basename(ruta_entrega)/productos_intermedios/
# temp_basename(dir_entrega)_5_cgl_muestra_subcarpetas.csv
# que contiene la información acerca de si se pudieron generar las subcarpetas
# correspondientes a cada muestra del conglomerado (o no).


library("plyr")
library("dplyr")
library("tidyr")
library("readr")

# Nombre de la carpeta donde se encuentran los archivos (éste se pide para formar
# las rutas hacia los objetos calculados con anterioridad).
dir_entrega <- args[1]
#dir_entrega <- "/Volumes/sacmod"

dir_archivos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos_intermedios"
  )

ruta_objeto_ruta_estructura <- paste0(
  dir_archivos,
  "/", "temp_", basename(dir_entrega), "_3_ruta_estructura.rds"
  )

ruta_objeto_conglomerado_carpetas <- paste0(
  dir_archivos,
  "/", "temp_", basename(dir_entrega), "_3_conglomerado_carpetas.rds"
  )

# Leyendo ambos objetos:
ruta_estructura <- readRDS(ruta_objeto_ruta_estructura)
Conglomerado_carpetas <- readRDS(ruta_objeto_conglomerado_carpetas)

## Creando la estructura de carpetas:
resultado_crear_carpeta_estructura <- dir.create(ruta_estructura)

## Creando las carpetas con el número de conglomerado:
rutas_cgl <- paste0(
  ruta_estructura,
  "/", Conglomerado_carpetas$cgl
  ) %>%
  unique()

resultados_crear_carpetas_cgl <- ldply(rutas_cgl, dir.create)

## Creando las carpetas con la fecha de muestreo dentro de su conglomerado
# correspondiente
rutas_cgl_fecha <- paste0(
  ruta_estructura,
  "/", Conglomerado_carpetas$cgl,
  "/", Conglomerado_carpetas$fecha
  ) 

resultados_crear_carpetas_cgl_fecha <- laply(rutas_cgl_fecha, dir.create)
#resultados_crear_carpetas_cgl_fecha <- sample(c(TRUE, FALSE), length(rutas_cgl_fecha),
#replace = TRUE)

# Un aviso final para no crear caos (aunque se supone que ésto ya se revisó en
# etapas anteriores): sabemos que "rutas_cgl_fecha" siempre se deben poder crear,
# puesto a que corresponden a muestreos distintos. Si ésto no sucede, quiere decir
# que alguna muestra de conglomerado que estamos tratando de guardar en la estructura,
# ya se encuentra registrada, por lo que se debe revisar el archivo generado:
# temp_basename(dir_entrega)_cgl_muestra_carpetas.csv

# Creando el informe acerca de si se pudieron crear las carpetas correspondientes
# a cada muestra del conglomerado:
Cgl_muestra_carpetas <- data_frame(
  carpeta = rutas_cgl_fecha,
  creada = resultados_crear_carpetas_cgl_fecha)

# Creando la ruta donde se guardará dicho informe
ruta_archivo_cgl_muestra_carpetas <- paste0(
  dir_archivos,
  "/", "temp_", basename(dir_entrega), "_5_cgl_muestra_carpetas.csv"
  )

# Guardando el informe:
write_csv(Cgl_muestra_carpetas, ruta_archivo_cgl_muestra_carpetas)

## Creando las subcarpetas con el número (éstas se crearán por completez en caso
# de que haya surgido algún problema en el paso anterior.)

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

rutas_subcarpetas <- expand.grid(x = rutas_cgl_fecha, y = subcarpetas,
  stringsAsFactors = FALSE) %>%
  mutate(
    rutas = paste0(x, "/", y)
    ) %>%
  .$rutas

resultados_crear_subcarpetas <- ldply(rutas_subcarpetas, dir.create)
#resultados_crear_subcarpetas <- sample(c(TRUE, FALSE), length(rutas_subcarpetas),
#replace = TRUE)

# Creando el informe acerca de si se pudieron crear las subcarpetas
Cgl_muestra_subcarpetas <- data_frame(
  subcarpeta = rutas_subcarpetas,
  creada = resultados_crear_subcarpetas)

# Creando la ruta donde se guardará dicho informe
ruta_archivo_cgl_muestra_subcarpetas <- paste0(
  dir_archivos,
  "/", "temp_", basename(dir_entrega), "_5_cgl_muestra_subcarpetas.csv"
  )

# Guardando el informe:
write_csv(Cgl_muestra_subcarpetas, ruta_archivo_cgl_muestra_subcarpetas)

## Finalmente, enviando un aviso en caso de que no se pudieran crear las carpetas
## de muestreos de conglomerado:

if(sum(!resultados_crear_carpetas_cgl_fecha) > 0)
  paste0("No se pudieron crear todas las carpetas asociadas a una muestra de ",
    "conglomerado, por lo que es posible que se esté introduciendo información ",
    "duplicada, o que ya ha sido introducida anteriormente. Favor de revisar el ",
    "archivo ..._5_cgl_muestra_carpetas.csv y tomar medidas apropiadas antes de ",
    "continuar. Todas las carpetas YA fueron creadas si el problema no es de conexión. ",
    "(ver ..._5_cgl_muestra_subcarpetas.csv).") %>%
  cat()

