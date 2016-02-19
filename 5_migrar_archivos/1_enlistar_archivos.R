library("plyr")
library("dplyr")
library("tidyr")
library("stringi")
library("readr")

# Creando la estructura de carpetas:

dir.create(ruta_estructura)

ruta_cgl_anio_mes <- paste(ruta_estructura, "/", Conglomerado_carpetas$cgl_anio_mes,
  sep = "")
resultados_crear_carpetas <- lapply(ruta_cgl_anio_mes, dir.create, recursive = TRUE)

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

producto_cartesiano <- expand.grid(x = ruta_cgl_anio_mes, y = subcarpetas)
ruta_subcarpetas <- paste(producto_cartesiano$x, producto_cartesiano$y, sep = "/")
lapply(ruta_subcarpetas, dir.create)

######

# Haciendo el join con "rutas", para encontrar las rutas de entrada/salida de los archivos:
Rutas_origen_destino <- Archivo_ruta %>%
  inner_join(Archivo_origen, by = c("entrada" = "nombre")) %>%
  select(
    cgl_anio_mes,
    ruta_origen = ruta,
    ruta_destino = ruta_salida,
    institucion
  )

# Tabla de archivos que se encuentran registrados en la base de datos (Archivo_ruta),
# pero que no se encontraron en la carpeta de archivos que se entregó.
# En esta tabla se incluye archivo_nombre_original, porque las causas por las que
# no se encuentran los archivos son ajenas a CONABIO.
Archivos_no_encontrados <- anti_join(Archivo_ruta, Archivo_origen,
  by = c("entrada" = "nombre"))

if(nrow(Archivos_no_encontrados) > 0){
  Archivos_no_encontrados <- Archivos_no_encontrados %>%
    separate(cgl_anio_mes, c("conglomerado", "anio", "mes")) %>%
    select(
      institucion,
      conglomerado,
      anio,
      mes,
      nombre_nuevo = entrada,
      nombre_original = archivo_nombre_original
    ) %>%
    arrange(conglomerado)
} else {
  Archivos_no_encontrados <- data.frame()
}

if(nrow(Rutas_origen_destino) > 0){
  
  # Copiando los archivos:
  resultados <- apply(Rutas_origen_destino, 1, function(x) file.copy(x['ruta_origen'],
    x['ruta_destino'], overwrite = FALSE))

  # ¿Qué archivos no se lograron copiar y cuáles sí?
  table(resultados)
  
  if(sum(resultados) > 0){
    Rutas_origen_destino_success <- Rutas_origen_destino %>%
      filter(resultados) %>%
      separate(cgl_anio_mes, c("conglomerado", "anio", "mes")) %>%
      select(
        conglomerado,
        anio,
        mes,
        institucion,
        archivo_ruta = ruta_origen
        )
  } else {
   Rutas_origen_destino_success <- data.frame()
  }
  
  if(sum(!resultados) > 0){
    
    # Archivos faaail, una razón puede ser que guardaron el mismo archivo en dos
    # lugares distintos usando el cliente viejo, entonces al hacer join de los
    # archivos en j con los registrados en la base usando el nombre como llave,
    # se duplican los registros y no los puede guardar 2 veces.

    Rutas_origen_destino_fail <- Rutas_origen_destino %>%
      filter(!resultados) %>%
      separate(cgl_anio_mes, c("conglomerado", "anio", "mes")) %>%
      select(
        conglomerado,
        anio,
        mes,
        institucion,
        archivo_ruta = ruta_origen
        )
  } else {
  Rutas_origen_destino_fail <- data.frame()
  }
  
} else {
  resultados <- c()
  Rutas_origen_destino_success <- data.frame()
  Rutas_origen_destino_fail <- data.frame()
}

################################################################################
############################# FALTA REVISAR ESTA SECCIÓN
# ACTUALIZAR ESTA SECCIÓN PARA EL 2016 EN ADELANTE...

# Extracción de formatos de campo:
# Se presupone que los formatos tienen un nombre de la forma:
# "0*num_conglomerado[_fecha]?[otra_cosa]?.pdf"

# Idea general: para cada formato encontrado en "lista_archivos_j", extraer su
# conglomerado y año (este último en caso de que sea válido), así como su
# ruta. Por medio del número de conglomerado (y del año), se hace el join con
# el nombre de la carpeta a la que pertenece un formulario y se crea la nueva
# ruta.

lista_formatos <- lista_archivos_j[grep("formatos", lista_archivos_j, ignore.case = TRUE)]
Formato_origen <- data.frame(ruta = lista_formatos, nombre = splitPathFile(lista_formatos)[[3]],
  stringsAsFactors = FALSE)

Formatos_origen_nombre_nuevo <- Formato_origen %>%
  mutate(
    conglomerado = as.numeric(sub("([[:digit:]]*).*", "\\1", nombre)),
    anio_aux = (sub(".*(201[45]).*", "\\1", nombre)),
    anio = as.numeric(ifelse(anio_aux %in% c("2014", "2015"), anio_aux, NA))
    ) %>%
  filter(!is.na(conglomerado)) %>%
  mutate(
    nombre_nuevo = ifelse(is.na(anio),
      paste(as.character(conglomerado), ".pdf", sep = ""),
      paste(conglomerado, "_", anio, ".pdf", sep = ""))
  ) %>%
  # uniendo con las rutas de conglomerado, 
  select(
    conglomerado,
    anio,
    ruta_origen = ruta,
    nombre_nuevo
  )

#Notar que Conglomerado_carpetas se obtiene de la base de datos, por lo que
#se insertarán los formatos bajo el supuesto de que en la misma base de datos,
#no hay registros del mismo conglomerado, en el mismo año, pero en dos temporadas
#distintas.
Formatos_destino <- Conglomerado_carpetas %>%
  separate(cgl_anio_mes, c("conglomerado", "anio", "mes"),
    remove = FALSE, convert = TRUE) %>%
  mutate(
    #anio_aux nunca es NA
    # Se presupone que los años que no son 2014 ni 2015 están mal.
    anio_aux = ifelse(anio %in% c(2014, 2015), 1, 0)
  )

Formatos_origen_destino <- Formatos_origen_nombre_nuevo %>%
  inner_join(Formatos_destino, by = "conglomerado") %>%
  mutate(
    ruta_destino = paste(ruta_estructura, "/", cgl_anio_mes, "/", nombre_nuevo, sep = ""),
    #bandera para filtrar: si el formato no tiene año, somos conservadores y
    #permitimos copiarlo en todas las carpetas donde se hizo el join:
    flag_1 = ifelse(anio.x == anio.y | is.na(anio.x), 1, 0),
    
    # Si los años no coinciden (y no hay NA's), entonces puede ser por dos 
    # razones: 1. el año de la carpeta está mal 2. el registro es un artefacto del join
    # por conglomerado, para eso, tenemos que revisar más:
    
    # esta bandera aprueba los casos en que los años fueron distintos pero el
    # año en la carpeta está mal
    flag_2 = ifelse(flag_1 == 0 & anio_aux == 0, 1, 0),
    
    # aprobando algunos casos que habíamos perdido:
    flag_3 = flag_1 + flag_2
    ) %>%
  filter(flag_3 == 1) %>%
  select(
    ruta_origen,
    ruta_destino
  )
  
#Copiando los archivos:
resultados_formatos <- apply(Formatos_origen_destino, 1,
  function(x) file.copy(x['ruta_origen'], x['ruta_destino'], overwrite = FALSE))

#Creando tabla de cuántos formatos tiene asociado cada conglomerado (para el reporte).
#Notar que los conglomerados se sacan de la base de datos especificada en "base",
#por lo que el reporte sólo es para los archivos que se están migrando en este
#momento (no para todos los archivos en la carpeta "estructura")
Conglomerados_formulario <- ldply(Conglomerado_carpetas$cgl_anio_mes,
  function(x){
    ruta_carpeta <- paste(ruta_estructura, x, sep = "/")
    formularios <- data.frame(
      cgl_anio_mes = x,
      numero_formularios = length(list.files(ruta_carpeta, pattern = "pdf"))) %>%
      separate(cgl_anio_mes, c("conglomerado", "anio", "mes"))
    return(formularios)
  }) %>%
  arrange(numero_formularios)

################################################################################

#Creación de reportes:

nombre_base <- sub("^(.*)\\..*", "\\1", basename(base))
dir_padre <- paste("reportes", nombre_base, sep = "/")

dir.create("reportes")
dir.create(dir_padre)

# Reporte de archivos que se encuentran registrados en la base de datos, pero
# que no se encontraron en la carpeta de archivos.

if(nrow(Archivos_no_encontrados) > 0)
  write.csv(Archivos_no_encontrados, file = paste0(
    dir_padre, "/", nombre_base, "_no_encontrados.csv"), row.names = FALSE)

# Reporte de archivos que se encuentran registrados en la base de datos, y que
# se encuentran en la carpeta de archivos, pero que no se pudieron migrar por
# alguna otra razón, por ejemplo, artefactos del join (ver arriba para mayor
# información).

if(nrow(Rutas_origen_destino_fail) > 0)
  write.csv(Rutas_origen_destino_fail, file = paste0(
    dir_padre, "/", nombre_base, "_fallidos_otros.csv"), row.names = FALSE)

# Reporte de número de formatos por conglomerado
write.csv(Conglomerados_formulario, file = paste0(
  dir_padre, "/", nombre_base, "_numero_formatos.csv"), row.names = FALSE)

################################################################################

# Ahora, se copiarán todos los archivos de lista_archivos_j con las terminaciones
# adecuadas, que no estén en Rutas_origen_destino$ruta_origen a una estructura
# especial de carpetas.

# Recordando tipos de archivos encontrados en la base de datos:
# tipos_archivo

# Creando estructura de carpetas

fecha_actual <- format(Sys.time(), "%Y_%m_%d")
entrega_no_registrados <- paste(ruta_estructura, "/", fecha_actual, "_", "no_reg",
  sep = "")
dir.create(entrega_no_registrados)

entrega_no_registrados_subcarpetas <- paste(entrega_no_registrados, c(
  "fotos_videos",
  "audio",
  "archivos_pdf"), sep = "/")

lapply(entrega_no_registrados_subcarpetas, dir.create)

# Seleccionando archivos tipo: "jpg", "mov", "wav", "avi".
# de "lista_archivos_j", que no se encuentren en Rutas_origen_destino$ruta_origen,
# y escribiendo su nueva ubicación.

# Recordar Archivo_origen es un df con ruta = lista_archivos_j y nombre =
# nombres_archivos_j
Archivos_no_registrados_origen_destino <- Archivo_origen %>%
  filter(
    !(ruta %in% Rutas_origen_destino$ruta_origen),
    grepl("(jpg|mov|wav|avi|pdf)$", lista_archivos_j, ignore.case = TRUE)
  ) %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", nombre)
  ) %>%
  mutate(
    ruta_destino = ifelse(grepl("jpg|mov|avi", nuevo_nombre, ignore.case = TRUE),
      paste(entrega_no_registrados, "fotos_videos", nuevo_nombre, sep = "/"),
      ifelse(grepl("wav", nuevo_nombre, ignore.case = TRUE),
        paste(entrega_no_registrados, "audio", nuevo_nombre, sep = "/"),
        paste(entrega_no_registrados, "archivos_pdf", sep = "/")
      )
    )
  ) %>%
  select(
    ruta_origen = ruta,
    ruta_destino
  )

# Copiando los archivos (no creo necesario hacer chequeos con resultados_nr,
# puesto que son archivos no registrados en la base de datos.)
resultados_nr <- apply(Archivos_no_registrados_origen_destino, 1,
  function(x) file.copy(x['ruta_origen'], x['ruta_destino'], overwrite = FALSE))

#Calculando el tamaño de los archivos migrados (en bytes):
files_media <- Rutas_origen_destino %>%
  filter(resultados) %>%
  .$ruta_destino
size_media <- file.size(files_media)

#Creando data frame con los tamaños de los archivos
tamano_archivos <- data.frame(
  nombre = splitPathFile(files_media)[[3]],
  ruta = files_media,
  tamano = size_media)

write.csv(tamano_archivos, file = paste0(
  dir_padre, "/", nombre_base, "_archivados_migrados_registrados_bd.csv"),
  row.names = FALSE)

##################
#################
##################


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