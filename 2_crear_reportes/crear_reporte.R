# Versión de R: 3.2.1 ó superior.
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

Sys.setenv(RSTUDIO_PANDOC = '/Applications/RStudio.app/Contents/MacOS/pandoc')
args <- commandArgs(trailingOnly = TRUE)

nombre_entrega <- args[1]
dir_j <- args[2]
# si se requiere pattern_db se puede enviar como argumento desde la terminal
# pattern_db <- args[3]
pattern_db <- "\\.sqlite$"

# creamos el nombre del reporte, carpetas y dbs como la fecha + nombre_entrega
fecha_reporte <- format(Sys.time(), "%Y_%m_%d")
entrega <- paste(fecha_reporte, "_", nombre_entrega, sep = "")

output_dir = paste("reportes/", entrega, sep = "")
output_file = paste(entrega, ".pdf", sep = "")
render('revision_gral.Rmd', output_file = output_file, output_dir = output_dir)

output_file = paste(entrega, ".docx", sep = "")
  render('revision_gral_word.Rmd', output_file = output_file, 
  output_dir = output_dir)

# revisamos su hay repetidos, y si hace falta creamos reporte y txt
conglomerado_reps <- collect(tbl(base_input, "Conglomerado_muestra"))
cgl_reps <- conglomerado_reps %>%
  select(nombre, fecha_visita, id) 
ids_reps <- cgl_reps$id[duplicated(select(cgl_reps, nombre, fecha_visita))]

if(length(ids_reps) > 0){
  output_file = paste(output_dir, "/", entrega, "_rep.txt", sep = "")
  write.table(ids_reps, file = output_file, quote = FALSE, row.names = FALSE, 
    col.names = FALSE)
  output_file = paste(entrega, "_rep.pdf", sep = "")
  render('revision_repetidos.Rmd', output_file = output_file, 
  output_dir = output_dir)
}
