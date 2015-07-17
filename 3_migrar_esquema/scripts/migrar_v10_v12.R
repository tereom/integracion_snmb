# corre el rmd que migra bases sqlite del esquema v10 al esquema v12.
# Ejemplo: 
# > Rscript migrar_v10_v12.R 'aaaa_mm_dd_FMCN_v10_v12' '../1_exportar_sqlite/bases/storage.sqlite' 'FMCN'

# Argumentos:
# entrega: nombre del directorio donde se guardará la base de datos.
# entrega <- "prueba_fer"
# base_ruta: ruta de la base de datos a migrar de esquema
# base_ruta <- '../1_exportar_sqlite/bases/storage.sqlite'
# institucion_input: nombre de la institución
# institucion_input <- "CONANP"

# El ejemplo crea:
# Base de datos v12: migraciones/entrega/entrega.sqlite

Sys.setenv(RSTUDIO_PANDOC = '/Applications/RStudio.app/Contents/MacOS/pandoc')
args <- commandArgs(trailingOnly = TRUE)

entrega <- args[1]
base_ruta <- args[2]
institucion_input <- args[3]

source("scripts/etl_v10_v12.R")