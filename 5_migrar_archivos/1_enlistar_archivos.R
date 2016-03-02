
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