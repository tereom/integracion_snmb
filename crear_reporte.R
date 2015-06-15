# corre el rmd que genera reportes de entrega
# Ejemplo: 
# > Rscript crear_reporte.R 'FMCN' 'bases_prueba' '\.sqlite'
# Argumentos:
# entrega: nombre del directorio donde se guardará el análisis
# dir_j: ruta de la carpeta donde se buscará la base de datos a revisar
# pattern_db: regex que identifica las bases de datos a considerar
# El ejemplo crea:
# 1 copia de datos: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.db
# 2 reporte pdf: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.pdf
# 3 copia en word: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.docx

library(rmarkdown)

Sys.setenv(RSTUDIO_PANDOC='/Applications/RStudio.app/Contents/MacOS/pandoc')
args <- commandArgs(trailingOnly = TRUE)

nombre_entrega <- args[1]
dir_j <- args[2]
pattern_db <- args[3]

# creamos el nombre del reporte, carpetas y dbs como la fecha + nombre_entrega
fecha_reporte <- format(Sys.time(), "%Y_%m_%d")
entrega <- paste(fecha_reporte, "_", nombre_entrega, sep = "")

output_dir = paste("reportes/", entrega, sep = "")
output_file = paste(entrega, ".pdf", sep = "")

render('revision_gral.Rmd', output_file = output_file, output_dir = output_dir)

output_file = paste(entrega, ".docx", sep = "")
render('revision_gral_word.Rmd', output_file = output_file, 
  output_dir = output_dir)