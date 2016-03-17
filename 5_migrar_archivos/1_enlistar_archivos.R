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