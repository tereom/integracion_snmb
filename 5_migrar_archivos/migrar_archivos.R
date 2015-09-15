# Copiar archivos del cliente a carpetas:

#estructura:
# nombre_entrega
# ├───conglomerado_anio 
# |   |   formato_campo.pdf
# |   ├───fotos_videos
# |   ├───grabaciones_audibles
# |   ├───grabaciones_ultrasonicas
# |   ├───especies_invasoras
# |   ├───huellas_excretas
# |   ├───registros_extra
# |   ├───referencias
# |   ├───otros
# ...
# ├───otros_archivos
# |   ├───fotos_videos
# |   ├───audio
# |   ├───archivos_pdf

library("plyr")
library("dplyr")
library("tidyr")
library("stringr")
library("stringi")
library("RSQLite")

args <- commandArgs(trailingOnly = TRUE)

# Nombre de la carpeta donde se guardarán los datos:
nombre_entrega <- args[1]

# Directorio donde se quiere colocar la carpeta con los datos:
ruta_entrega <- args[2]

# Ruta hacia la carpeta final:
entrega <- paste(ruta_entrega, "/", nombre_entrega, sep = "")

# Ruta de la base de datos a utilizar:
base <- args[3]

# Ruta de la carpeta donde están los clientes de captura:
dir_j <- args[4]

# Conexión a la base de datos:
base_input <- src_sqlite(base)

# Leyendo tablas necesarias:
Conglomerado_muestra <- collect(tbl(base_input, "Conglomerado_muestra"))
Sitio_muestra <- collect(tbl(base_input, "Sitio_muestra"))
Imagen_referencia_sitio <- collect(tbl(base_input, "Imagen_referencia_sitio"))

Camara <- collect(tbl(base_input, "Camara"))
Archivo_camara <- collect(tbl(base_input, "Archivo_camara"))
Imagen_referencia_camara <- collect(tbl(base_input, "Imagen_referencia_camara"))

Grabadora <- collect(tbl(base_input, "Grabadora"))
Imagen_referencia_grabadora <- collect(tbl(base_input, "Imagen_referencia_grabadora"))
Archivo_referencia_grabadora <- collect(tbl(base_input, "Archivo_referencia_grabadora"))
Imagen_referencia_microfonos <- collect(tbl(base_input, "Imagen_referencia_microfonos"))
Archivo_grabadora <- collect(tbl(base_input, "Archivo_grabadora"))

Transecto_especies_invasoras_muestra <- collect(tbl(base_input, "Transecto_especies_invasoras_muestra"))
Especie_invasora <- collect(tbl(base_input, "Especie_invasora"))
Archivo_especie_invasora <- collect(tbl(base_input, "Archivo_especie_invasora"))

Transecto_huellas_excretas_muestra <- collect(tbl(base_input, "Transecto_huellas_excretas_muestra"))
Huella_excreta <- collect(tbl(base_input, "Huella_excreta"))
Archivo_huella_excreta <- collect(tbl(base_input, "Archivo_huella_excreta"))

Especie_invasora_extra <- collect(tbl(base_input, "Especie_invasora_extra"))
Archivo_especie_invasora_extra <- collect(tbl(base_input, "Archivo_especie_invasora_extra"))

Huella_excreta_extra <- collect(tbl(base_input, "Huella_excreta_extra"))
Archivo_huella_excreta_extra <- collect(tbl(base_input, "Archivo_huella_excreta_extra"))

Especimen_restos_extra <- collect(tbl(base_input, "Especimen_restos_extra"))
Archivo_especimen_restos_extra <- collect(tbl(base_input, "Archivo_especimen_restos_extra"))

Punto_conteo_aves <- collect(tbl(base_input, "Punto_conteo_aves"))
Conteo_ave <- collect(tbl(base_input, "Conteo_ave"))
Archivo_conteo_ave <- collect(tbl(base_input, "Archivo_conteo_ave"))

Plaga <- collect(tbl(base_input, "Plaga"))
Archivo_plaga <- collect(tbl(base_input, "Archivo_plaga"))
Incendio <- collect(tbl(base_input, "Incendio"))
Archivo_incendio <- collect(tbl(base_input, "Archivo_incendio"))

# obteniendo los datos que necesitamos de las tablas. Para las tablas que no 
# corresponden a ningún archivo, sólo se extrae lo mínimo necesario para ligar
# a los archivos con conglomerado (a excepción de "Sitio_muestra", cuyo campo
# "sitio_numero" se utilizará para renombrar algunos archivos)

###
Conglomerado_muestra_sub <- Conglomerado_muestra %>%
  select(
    id,
    nombre,
    fecha_visita
    )

Sitio_muestra_sub <- Sitio_muestra %>%
  select(
    id,
    conglomerado_muestra_id,
    sitio_numero
    )

Imagen_referencia_sitio_sub <- Imagen_referencia_sitio %>%
  select(
    sitio_muestra_id,
    archivo
    )

###
Camara_sub <- Camara %>%
  select(
    id,
    sitio_muestra_id)

Imagen_referencia_camara_sub <- Imagen_referencia_camara %>%
  select(
    camara_id,
    archivo
    )

Archivo_camara_sub <- Archivo_camara %>%
  select(
    camara_id,
    archivo,
    presencia
    )

###
Grabadora_sub <- Grabadora %>%
  select(
    id,
    sitio_muestra_id
    )

Imagen_referencia_grabadora_sub <- Imagen_referencia_grabadora %>%
  select(
    grabadora_id,
    archivo)

Archivo_referencia_grabadora_sub <- Archivo_referencia_grabadora %>%
  select(
    grabadora_id,
    archivo)

Imagen_referencia_microfonos_sub <- Imagen_referencia_microfonos %>%
  select(
    grabadora_id,
    archivo)

Archivo_grabadora_sub <- Archivo_grabadora %>%
  select(
    grabadora_id,
    archivo,
    es_audible
    )

###
Transecto_especies_invasoras_muestra_sub <- Transecto_especies_invasoras_muestra %>%
  select(
    id,
    conglomerado_muestra_id
    )

Especie_invasora_sub <- Especie_invasora %>%
  select(
    id,
    transecto_especies_invasoras_id
    )

Archivo_especie_invasora_sub <- Archivo_especie_invasora %>%
  select(
    especie_invasora_id,
    archivo
    )

###
Transecto_huellas_excretas_muestra_sub <- Transecto_huellas_excretas_muestra %>%
  select(
    id,
    conglomerado_muestra_id
    )

Huella_excreta_sub <- Huella_excreta %>%
  select(
    id,
    transecto_huellas_excretas_id
    )

Archivo_huella_excreta_sub <- Archivo_huella_excreta %>%
  select(
    huella_excreta_id,
    archivo
    )

###
Especie_invasora_extra_sub <- Especie_invasora_extra %>%
  select(
    id,
    conglomerado_muestra_id
    )

Archivo_especie_invasora_extra_sub <- Archivo_especie_invasora_extra %>%
  select(
    especie_invasora_extra_id,
    archivo
    )

Huella_excreta_extra_sub <- Huella_excreta_extra %>%
  select(
    id,
    conglomerado_muestra_id
    )

Archivo_huella_excreta_extra_sub <- Archivo_huella_excreta_extra %>%
  select(
    huella_excreta_extra_id,
    archivo
    )
  
Especimen_restos_extra_sub <- Especimen_restos_extra %>%
  select(
    id,
    conglomerado_muestra_id
    )

Archivo_especimen_restos_extra_sub <- Archivo_especimen_restos_extra %>%
  select(
    especimen_restos_extra_id,
    archivo
    )

###
Punto_conteo_aves_sub <- Punto_conteo_aves %>%
  select(
    id,
    sitio_muestra_id
    )

Conteo_ave_sub <- Conteo_ave %>%
  select(
    id,
    punto_conteo_aves_id
    )

Archivo_conteo_ave_sub <- Archivo_conteo_ave %>%
  select(
    conteo_ave_id,
    archivo
    )

###
Plaga_sub <- Plaga %>%
  select(
    id,
    conglomerado_muestra_id
    )

Archivo_plaga_sub <- Archivo_plaga %>%
  select(
    plaga_id,
    archivo
    )

###
Incendio_sub <- Incendio %>%
  select(
    id,
    conglomerado_muestra_id
    )

Archivo_incendio_sub <- Archivo_incendio %>%
  select(
    incendio_id,
    archivo
    )

# Creando las tablas de información de conglomerado y conglomerado/sitio.
# Éstas son las principales para generar los joins.

# Información de conglomerado:
Conglomerado_info <- Conglomerado_muestra_sub %>%
  select(
    conglomerado_muestra_id = id,
    nombre,
    fecha_visita
    )

# Información de conglomerado y sitio
Conglomerado_sitio_info <- Conglomerado_muestra_sub %>%
  inner_join(Sitio_muestra_sub, by = c("id" = "conglomerado_muestra_id")) %>%
  mutate(
    sitio_numero = sub("\\s", "_", sitio_numero)
    ) %>%
  select(
    conglomerado_muestra_id = id,
    nombre,
    fecha_visita,
    sitio_muestra_id = id.y,
    sitio_numero
    )

# Creando las demás tablas con ayuda de las anteriores

###
#
Imagen_sitio_info <- Conglomerado_sitio_info %>%
  inner_join(Imagen_referencia_sitio_sub, by = "sitio_muestra_id") %>%
  select(
    conglomerado_muestra_id,
    sitio_numero,
    archivo
    )

###
#
Imagen_camara_info <- Conglomerado_sitio_info %>%
  inner_join(Camara_sub, by = "sitio_muestra_id") %>%
  mutate(
    camara_id = id
    ) %>%
  select(-id) %>%
  inner_join(Imagen_referencia_camara_sub, by = "camara_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )
#
Archivo_camara_info <- Conglomerado_sitio_info %>%
  inner_join(Camara_sub, by = "sitio_muestra_id") %>%
  mutate(
    camara_id = id
    ) %>%
  select(-id) %>%
  inner_join(Archivo_camara_sub, by = "camara_id") %>%
  select(
    conglomerado_muestra_id,
    archivo,
    presencia
    )

##
#
Imagen_grabadora_info <- Conglomerado_sitio_info %>%
  inner_join(Grabadora_sub, by = "sitio_muestra_id") %>%
  mutate(
    grabadora_id = id
    ) %>%
  select(-id) %>%
  inner_join(Imagen_referencia_grabadora_sub, by = "grabadora_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )
#
Imagen_microfonos_info <- Conglomerado_sitio_info %>%
  inner_join(Grabadora_sub, by = "sitio_muestra_id") %>%
  mutate(
    grabadora_id = id
    ) %>%
  select(-id) %>%
  inner_join(Imagen_referencia_microfonos_sub, by = "grabadora_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )

#
Archivo_metadatos_info <- Conglomerado_sitio_info %>%
  inner_join(Grabadora_sub, by = "sitio_muestra_id") %>%
  mutate(
    grabadora_id = id
    ) %>%
  select(-id) %>%
  inner_join(Archivo_referencia_grabadora_sub, by = "grabadora_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )

#
Archivo_grabadora_info <- Conglomerado_sitio_info %>%
  inner_join(Grabadora_sub, by = "sitio_muestra_id") %>%
  mutate(
    grabadora_id = id
    ) %>%
  select(-id) %>%
  inner_join(Archivo_grabadora_sub, by = "grabadora_id") %>%
  select(
    conglomerado_muestra_id,
    archivo,
    es_audible
    ) #%>%
  # obteniendo únicamente los archivos audibles
  #filter(es_audible == "T")

###
#
Archivo_especie_invasora_info <- Conglomerado_info %>%
  inner_join(Transecto_especies_invasoras_muestra_sub, by = "conglomerado_muestra_id") %>%
  mutate(
    transecto_especies_invasoras_id = id
    ) %>%
  select(-id) %>%
  inner_join(Especie_invasora_sub, by = "transecto_especies_invasoras_id") %>%
  mutate(
    especie_invasora_id = id
    ) %>%
  select(-id) %>%
  inner_join(Archivo_especie_invasora_sub, by = "especie_invasora_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )
  
###
#
Archivo_huella_excreta_info <- Conglomerado_info %>%
  inner_join(Transecto_huellas_excretas_muestra_sub, by = "conglomerado_muestra_id") %>%
  mutate(
    transecto_huellas_excretas_id = id
    ) %>%
  select(-id) %>%
  inner_join(Huella_excreta_sub, by = "transecto_huellas_excretas_id") %>%
  mutate(
    huella_excreta_id = id
    ) %>%
  select(-id) %>%
  inner_join(Archivo_huella_excreta_sub, by = "huella_excreta_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )

###
#
Archivo_especie_invasora_extra_info <- Conglomerado_info %>%
  inner_join(Especie_invasora_extra_sub, by = "conglomerado_muestra_id") %>%
  mutate(
    especie_invasora_extra_id = id
    ) %>%
  select(-id) %>%
  inner_join(Archivo_especie_invasora_extra_sub, by = "especie_invasora_extra_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )
#
Archivo_huella_excreta_extra_info <- Conglomerado_info %>%
  inner_join(Huella_excreta_extra_sub, by = "conglomerado_muestra_id") %>%
  mutate(
    huella_excreta_extra_id = id
    ) %>%
  select(-id) %>%
  inner_join(Archivo_huella_excreta_extra_sub, by = "huella_excreta_extra_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )
#
Archivo_especimen_restos_extra_info <- Conglomerado_info %>%
  inner_join(Especimen_restos_extra_sub, by = "conglomerado_muestra_id") %>%
  mutate(
    especimen_restos_extra_id = id
    ) %>%
  select(-id) %>%
  inner_join(Archivo_especimen_restos_extra_sub, by = "especimen_restos_extra_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )

###
#
Archivo_conteo_ave_info <- Conglomerado_sitio_info %>%
  inner_join(Punto_conteo_aves_sub, by = "sitio_muestra_id") %>%
  mutate(
    punto_conteo_aves_id = id
    ) %>%
  select(-id) %>%
  inner_join(Conteo_ave_sub, by = "punto_conteo_aves_id") %>%
  mutate(
    conteo_ave_id = id
  ) %>%
  select(-id) %>%
  inner_join(Archivo_conteo_ave_sub, by = "conteo_ave_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )

###
#
Archivo_plaga_info <- Conglomerado_info %>%
  inner_join(Plaga_sub, by = "conglomerado_muestra_id") %>%
  mutate(
    plaga_id = id
  ) %>%
  select(-id) %>%
  inner_join(Archivo_plaga_sub, by = "plaga_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )
#
Archivo_incendio_info <- Conglomerado_info %>%
  inner_join(Incendio_sub, by = "conglomerado_muestra_id") %>%
  mutate(
    incendio_id = id  
  ) %>%
  select(-id) %>%
  inner_join(Archivo_incendio_sub, by = "incendio_id") %>%
  select(
    conglomerado_muestra_id,
    archivo
    )

# Creando los nombres de las carpetas conglomerado_anio:
Conglomerado_carpetas <- Conglomerado_info %>%
  mutate(
    anio = substr(fecha_visita, 1, 4),
    nombre_anio = paste(nombre, anio, sep = "-")
  ) %>%
  select(
    conglomerado_muestra_id,
    nombre_anio
    )

# Creando los paths asociados a cada tipo de archivo:

Imagen_sitio_ruta <- Imagen_sitio_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    id = 1:length(Imagen_sitio_info$conglomerado_muestra_id),
    tipo = substring(archivo, nchar(archivo) - 2, nchar(archivo)),
    salida = paste(entrega, "/", nombre_anio, "/referencias/", id, "__", sitio_numero, ".", tipo, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Imagen_camara_ruta <- Imagen_camara_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    #sustituyendo lo matcheado con la regex por uno de sus substrings.
    #si no se matchea nada, todo se queda igual.
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/referencias/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Imagen_grabadora_ruta <- Imagen_grabadora_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/referencias/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Imagen_microfonos_ruta <- Imagen_microfonos_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/referencias/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_metadatos_ruta <- Archivo_metadatos_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/referencias/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_camara_ruta <- Archivo_camara_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    indicador = ifelse(is.na(presencia), "ns",
      ifelse(presencia == "T", "cf", "sf"))
  ) %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(
      entrega, "/", nombre_anio, "/fotos_videos/", indicador, "_", nuevo_nombre, sep = ""
      )
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_grabadora_ruta <- Archivo_grabadora_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo)
    # el campo "es_audible" nunca está vacío
  ) %>%
  mutate(
    carpeta = ifelse(
      es_audible == "T",
      "grabaciones_audibles",
      "grabaciones_ultrasonicas")
  ) %>%
  mutate(
    salida = paste(entrega, "/", nombre_anio, "/", carpeta, "/", nuevo_nombre,
      sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_especie_invasora_ruta <- Archivo_especie_invasora_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/especies_invasoras/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_huella_excreta_ruta <- Archivo_huella_excreta_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/huellas_excretas/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_especie_invasora_extra_ruta <- Archivo_especie_invasora_extra_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/registros_extra/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_huella_excreta_extra_ruta <- Archivo_huella_excreta_extra_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/registros_extra/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_especimen_restos_extra_ruta <- Archivo_especimen_restos_extra_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/registros_extra/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_conteo_ave_ruta <- Archivo_conteo_ave_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/otros/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_plaga_ruta <- Archivo_plaga_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/otros/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

Archivo_incendio_ruta <- Archivo_incendio_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    salida = paste(entrega, "/", nombre_anio, "/otros/", nuevo_nombre, sep = "")
  ) %>%
  select(
    nombre_anio,
    entrada = archivo,
    salida
  )

# Creando la estructura de carpetas:

dir.create(entrega)

entrega_nombre_anio <- paste(entrega, "/", Conglomerado_carpetas$nombre_anio, sep = "")
lapply(entrega_nombre_anio, dir.create)

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

producto_cartesiano <- expand.grid(x = entrega_nombre_anio, y = subcarpetas)
entrega_nombre_anio_subcarpetas <- paste(producto_cartesiano$x, producto_cartesiano$y, sep = "/")
lapply(entrega_nombre_anio_subcarpetas, dir.create)

# Revisando los tipos de archivos posibles:

Archivo_ruta <- rbind(
  Imagen_sitio_ruta,
  Imagen_camara_ruta,
  Imagen_grabadora_ruta,
  Imagen_microfonos_ruta,
  Archivo_metadatos_ruta,
  Archivo_camara_ruta,
  Archivo_grabadora_ruta,
  Archivo_especie_invasora_ruta,
  Archivo_huella_excreta_ruta,
  Archivo_especie_invasora_extra_ruta,
  Archivo_huella_excreta_extra_ruta,
  Archivo_especimen_restos_extra_ruta,
  Archivo_conteo_ave_ruta,
  Archivo_plaga_ruta,
  Archivo_incendio_ruta
  )

terminaciones <- Archivo_ruta %>%
  mutate(
    terminacion = substring(entrada, nchar(entrada)-2, nchar(entrada))
  ) %>%
  select(terminacion)
tipos_archivo <- unique(terminaciones$terminacion)

# Enlistando todos los archivos en el directorio origen y guardándlos en un df:
# lista_archivos_j <- list.files(path = dir_j, recursive = TRUE, full.names = TRUE)

# Escribiendo archivo
# write.table(lista_archivos_j, file = "2015_08_11_archivos_snmb_cluster.csv",
#    sep=",", row.names = FALSE)

# Leer archivo
lista_archivos_j <- read.csv("../2015_08_11_archivos_snmb_cluster.csv", stringsAsFactors = FALSE)$x

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

# Haciendo el join con "rutas", para encontrar los paths de entrada/salida de los archivos:
Rutas_origen_destino <- Archivo_ruta %>%
  inner_join(Archivo_origen, by = c("entrada" = "nombre")) %>%
  select(
    nombre_anio,
    ruta_origen = ruta,
    ruta_destino = salida
  )

# Tabla de archivos que se encuentran registrados en la base de datos (Archivo_ruta),
# pero que no se encontraron en la carpeta de archivos que se entregó.
Archivos_no_encontrados <- anti_join(Archivo_ruta, Archivo_origen,
  by = c("entrada" = "nombre")) %>%
  select(
    nombre_anio,
    entrada
  )

# Copiando los archivos:
resultados <- apply(Rutas_origen_destino, 1, function(x) file.copy(x['ruta_origen'],
  x['ruta_destino'], overwrite = FALSE))

# ¿Qué archivos no se lograron copiar y cuáles sí?
table(resultados)
Rutas_origen_destino_success <- Rutas_origen_destino[resultados,
  c('nombre_anio', 'ruta_origen')]
Rutas_origen_destino_fail <- Rutas_origen_destino[!resultados,
  c('nombre_anio', 'ruta_origen')]

# Archivos faaail, una razón puede ser que guardaron el mismo archivo en dos
# lugares distintos usando el cliente viejo, entonces al hacer join de los
# archivos en j con los registrados en la base usando el nombre como llave,
# se duplican los registros y no los puede guardar 2 veces.

################################################################################

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

Formatos_destino <- Conglomerado_carpetas %>%
  mutate(
    conglomerado = as.numeric(sub("([[:digit:]]*).*", "\\1", nombre_anio)),
    anio = as.numeric(sub(".*-([[:digit:]]*)", "\\1", nombre_anio)),
    #anio_aux nunca es NA
    # Se presupone que los años que no son 2014 ni 2015 están mal.
    anio_aux = ifelse(anio %in% c(2014, 2015), 1, 0)
  )

Formatos_origen_destino <- Formatos_origen_nombre_nuevo %>%
  inner_join(Formatos_destino, by = "conglomerado") %>%
  mutate(
    ruta_destino = paste(entrega, "/", nombre_anio, "/", nombre_nuevo, sep = ""),
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
#momento (no para todos los archivos en la carpeta "entrega")
Conglomerados_formulario <- ldply(Conglomerado_carpetas$nombre_anio,
  function(x){
    ruta_carpeta <- paste(entrega, x, sep = "/")
    formularios <- data.frame(
      nombre_anio = x,
      numero_formularios = length(list.files(ruta_carpeta, pattern = "pdf")))
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
  write.table(Archivos_no_encontrados, file = paste0(
    dir_padre, "/", nombre_base, "_no_encontrados.csv"), row.names = FALSE)

# Reporte de archivos que se encuentran registrados en la base de datos, y que
# se encuentran en la carpeta de archivos, pero que no se pudieron migrar por
# alguna otra razón, por ejemplo, artefactos del join (ver arriba para mayor
# información).

if(nrow(Rutas_origen_destino_fail) > 0)
  write.table(Rutas_origen_destino_fail, file = paste0(
    dir_padre, "/", nombre_base, "_fallidos_otros.csv"), row.names = FALSE)

# Reporte de número de formatos por conglomerado
write.table(Conglomerados_formulario, file = paste0(
  dir_padre, "/", nombre_base, "_numero_formatos.csv"), row.names = FALSE)

################################################################################

# Ahora, se copiarán todos los archivos de lista_archivos_j con las terminaciones
# adecuadas, que no estén en Rutas_origen_destino$ruta_origen a una estructura
# especial de carpetas.

# Recordando tipos de archivos encontrados en la base de datos:
# tipos_archivo

# Creando estructura de carpetas

fecha_actual <- format(Sys.time(), "%Y_%m_%d")
entrega_no_registrados <- paste(entrega, "/", fecha_actual, "_", "no_reg",
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
