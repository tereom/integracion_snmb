# Versión de R: 3.2.1 ó superior.
# corre el rmd que genera reportes de entrega
# Ejemplo: 
# > Rscript crear_reporte.R 'entrega' 'bases_prueba' '\.sqlite'
# Argumentos:
# entrega: nombre del directorio donde se guardará el análisis
# instituciones: opcional, indica si el reporte se generará únicamente con info.
#   de alguna de las instituciones (FMCN, CONAFOR, CONANP), se deben enviar como
#   un vector, se escribe como vector de caracteres, ej. c("CONAFOR", "CONANP")
# anios: años para los que se generará el reporte, el default es 2012:2020
# Ejemplo
# Rscript crear_reporte.R reporte_prueba 'c("CONAFOR", "CONANP")' 'c(2010, 2014)' 
# El ejemplo crea:
# 1 reporte pdf: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.pdf
# 2 copia en word: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.docx

library(rmarkdown)

# apuntamos al pandoc de RStudio
Sys.setenv(RSTUDIO_PANDOC = '/Applications/RStudio.app/Contents/MacOS/pandoc')

# leemos los argumentos de la linea de comandos
args <- commandArgs(trailingOnly = TRUE)
nombre_entrega <- args[1]
inst_arg <- eval(parse(text = args[2]))
instituciones <- ifelse(is.na(inst_arg), c("CONAFOR", "FMCN", "CONANP"), 
  inst_arg)
anios_arg <- eval(parse(text = args[3]))
anios <- ifelse(is.na(anios_arg), 2012:2020, anios_arg)

print(paste("Generando reportes que incluyen", 
  paste(instituciones, collapse = ", "), 
  "en los años", paste(anios, collapse = ", ")))

# creamos el nombre del reporte, carpetas y dbs como la fecha + nombre_entrega
fecha_reporte <- format(Sys.time(), "%Y_%m_%d")
entrega <- paste(fecha_reporte, "_", nombre_entrega, sep = "")

# crear estructura de carpetas
# directorio padre dentro de carpeta reportes
dir.create("reportes")
dir_padre <- paste("reportes/", entrega, sep = "")
dir.create(dir_padre)

output_dir = paste("reportes/", entrega, sep = "")
output_pdf = paste(entrega, ".pdf", sep = "")
render('revision_gral.Rmd', output_file = output_pdf, output_dir = output_dir)

output_doc = paste(entrega, ".docx", sep = "")
  render('revision_gral_word.Rmd', output_file = output_doc, 
  output_dir = output_dir)
