library("plyr")
library("dplyr")
library("tidyr")
library("stringi")
library("readr")

args <- commandArgs(trailingOnly = TRUE)

# Ruta absoluta de la carpeta donde están los clientes de captura, que se enlistará:
dir_j <- args[1]
#dir_j <- "/Volumes/sacmod"

# Nombre de la carpeta con el que se guardarán los reportes:
# reportes/aaaa_mm_dd_basename_dir_j/productos_intermedios

nombre_carpeta <- Sys.Date() %>%
  stri_replace_all_fixed("-", "_") %>%
  paste0(., "_", basename(dir_j))

# Creando el nombre del archivo con la lista de todos los archivos en dir_j,
# éste nombre es la fecha precedida del nombre base de dir_j _lista.
nombre_archivo <- paste0(nombre_carpeta, "_lista")

# Creando la ruta del archivo a migrar:
ruta_archivo <- paste0("reportes/", nombre_carpeta,
  "/productos_intermedios/", nombre_archivo, ".csv")

# Enlistando todos los archivos en el directorio origen y guardándolos en un archivo csv:
# Cabe destacar que el archivo por donde empieza el path relativo es el working
# directory.
paste0("find ", dir_j, " -type f > ", ruta_archivo) #%>%
  #system()

# Comprobando que puedan encontrar todos los archivos (con la finalidad de saber
# si bash puede utilizar las rutas que escupió:

#Ruta para guardar archivo de existencia de archivos
nombre_archivo_existencia <- paste0(nombre_carpeta, "_existencia")
ruta_archivo_existencia <- paste0("reportes/", nombre_carpeta,
  "/productos_intermedios/", nombre_archivo_existencia, ".csv")

#script:
#while read -r p; do
#   echo "$([ -f "$p" ] && echo TRUE || echo FALSE)" >> ruta_archivo_existencia
# done < ruta_archivo

paste0(
  "while read -r p; do",
  " echo \"$([ -f \"$p\" ] && echo TRUE || echo FALSE)\" >> ", ruta_archivo_existencia, ";",
  " done < ", ruta_archivo) %>%
  system()

################################################################################
### funciones para generar nombres de archivos incluso para los muy largos ###
standardPathFile <- function(x){
  fsep <- .Platform$file.sep
  netshare <- substr(x, 1, 2) == "\\\\"
  if (any(netshare)){
    x[!netshare] <- gsub("\\\\", fsep, x[!netshare])
    y <- x[netshare]
    x[netshare] <- paste(substr(y, 1, 2), gsub("\\\\", fsep, substring(y, 3)), sep="")
  }else{
    x <- gsub("\\\\", fsep, x)
  }
  x
}

splitPathFile <- function(x){
  fsep <- .Platform$file.sep
  x <- standardPathFile(x)
  n <- nchar(x)
  pos <- regexpr(paste(fsep, "[^", fsep, "]*$", sep=""), x)
  pos[pos<0] <- 0L
  path <- substr(x, 1, pos-1L)
  file <- substr(x, pos+1L, n)
  ratherpath <- !pos & !is.na(match(file, c(".", "..", "~")))
  if (any(ratherpath)){
    path[ratherpath] <- file[ratherpath]
    file[ratherpath] <- ""
  }
  fsep <- rep(fsep, length(pos))
  fsep[!pos] <- ""
  list(path=path, fsep=fsep, file=file)
}
################################################################################

# nombres de archivos
nombres_archivos_j <- splitPathFile(lista_archivos_j)[[3]]

# de donde copiar
Archivo_origen <- data.frame(nombre = nombres_archivos_j, ruta = lista_archivos_j,
  stringsAsFactors = FALSE)
