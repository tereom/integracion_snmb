library("plyr")
library("dplyr")
library("stringi")
library("readr")

### Observaciones
# 1. Esta versión sólo considera eliminar carpetas completas asociadas a
#   conglomerados porque se construyó para arreglar CONAFOR, se debe generalizar
#   para aceptar conglomerado Y año.
# 2. En realidad, las carpetas no se eliminan, sino que se mueven a una carpeta de
#   "aaaa_mm_dd_eliminadas

# ruta_carpeta es la ruta a la carpeta raíz de la estructura de archivos. Es en
# esta estructura donde se encuentran las carpetas a cambiar de lugar. Ejemplo:
# ruta_carpeta <- "/Volumes/sacmod/archivos_snmb"
# Cabe destacar que la estructura de carpetas se supone como:
# nombre_entrega
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
#
# Las carpetas se mueven a una carpeta con nombre: aaaa_mm_dd_eliminados.

eliminaArchivos <- function(ruta_carpeta, valores){
  
  # Obteniendo fecha actual para nombre de la carpeta a donde se moverán las otras.
  fecha_actual <- Sys.Date() %>%
    stri_replace_all_fixed(., "-", "_")
  
  # Creando dicha carpeta.
  dir.create(paste0(ruta_carpeta, "/", fecha_actual, "_eliminados"))
  
  # Creando las rutas origen destino de las carpetas
  rutas_origen <- paste0(ruta_carpeta, "/", valores)
  rutas_destino <- paste0(ruta_carpeta, "/", fecha_actual, "_eliminados/", valores)
  
  # Moviendo las carpetas
  resultados <- file.rename(rutas_origen, rutas_destino)
  
  # Obteniendo qué carpetas se eliminaron:
  carpetas_eliminadas <- valores[resultados] %>%
    as.data.frame()
  
  # Creando los diagnósticos:
  resumen <- data.frame(resumen = c(
    paste0("Número de carpetas de conglomerado en la lista original: ", length(valores)),
    paste0("Número de carpetas de conglomerado movidas: ", sum(resultados))
    ))
  
  print("Número de carpetas de conglomerado en la lista original:")
  print(length(valores))
  
  print("Número de carpetas de conglomerado movidas:")
  print(sum(resultados))
  
  # Creando rutas para los reportes de eliminación
  dir.create("reportes")

  ruta_carpeta_reportes <- paste0("reportes/", fecha_actual)
  dir.create(ruta_carpeta_reportes)

  ruta_archivo_carpetas_eliminadas <- paste0(ruta_carpeta_reportes, "/", fecha_actual, 
    "_carpetas_eliminadas.csv")
  ruta_archivo_resumen <- paste0(ruta_carpeta_reportes, "/", fecha_actual, 
    "_resumen.csv")

  # Guardando reportes
  write_csv(carpetas_eliminadas, ruta_archivo_carpetas_eliminadas)
  write_csv(resumen, ruta_archivo_resumen)
}

## Ejemplo:
ruta_carpeta <- "/Volumes/sacmod/archivos_snmb"

nombre_borrar <- read_csv("../pruebas_nash/nombre_borrar.csv")
valores <- as.character(nombre_borrar$cgl) %>%
  unique()

eliminaArchivos(ruta_carpeta, valores)

#list.dirs("/Volumes/sacmod/archivos_snmb/2015_12_11_eliminados", recursive = FALSE)
