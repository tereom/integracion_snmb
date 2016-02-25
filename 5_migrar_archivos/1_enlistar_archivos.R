
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