# Este script constituye un paso para copiar los archivos guardados en uno
# o varios clientes de captura a la estructura de carpetas del SNMB:

#estructura:
# nombre_estructura
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
# ...
# ├───aaaa_mm_dd_no_reg
# |   ├───fotos_videos
# |   ├───audio
# |   ├───archivos_pdf

# En este script, como su nombre lo indica, se accede a la base de datos, y por
# medio de los datos apropiados, se genera una ruta destino para cada archivo
# registrado en ella. Cabe destacar que para generar este path, se necesita
# especificar el path de la carpeta donde se aloja la estructura de archivos,
# así como el nombre de la misma.

library("plyr")
library("dplyr")
library("tidyr")
library("readr")
library("stringr")
library("stringi")
library("RSQLite")

args <- commandArgs(trailingOnly = TRUE)

# Nombre de la carpeta donde se encuentran los archivos (éste se pide únicamente
# para colocar el csv con los nuevos paths de los archivos en el lugar adecuado).
dir_entrega <- args[1]
#dir_entrega <- "/Volumes/sacmod"

# Nombre de la carpeta donde se guardarán los datos:
nombre_estructura <- args[2]
#nombre_estructura <- "archivos_snmb_2"

# Directorio de la estructura
dir_estructura <- args[3]
#dir_estructura <- "/Volumes/sacmod"

# Ruta hacia la estructura:
ruta_estructura <- paste0(dir_estructura, "/", nombre_estructura)

# Ruta de la base de datos a utilizar:

nombre_base <- args[4]
#nombre_base <- "2015_12_14_6.sqlite"

ruta_base <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/base",
  "/", nombre_base)

# Conexión a la base de datos:
base_input <- src_sqlite(ruta_base)

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

# Supuestos:
# 1. La base de datos contiene al menos un conglomerado.
# 2. La información y fotografías de sitio se entregaron correctamente en dicha base
# (ésto porque se procesan las imágenes de sitio de manera ligeramente distinta
# a las demás)

###
Conglomerado_muestra_sub <- Conglomerado_muestra %>%
  select(
    id,
    nombre,
    fecha_visita,
    # para los reportes de archivos registrados en la base de datos pero no vistos
    institucion
    #####
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
    archivo,
    archivo_nombre_original
    )

###
Camara_sub <- Camara %>%
  select(
    id,
    sitio_muestra_id)

Imagen_referencia_camara_sub <- Imagen_referencia_camara %>%
  select(
    camara_id,
    archivo,
    archivo_nombre_original
    )

Archivo_camara_sub <- Archivo_camara %>%
  select(
    camara_id,
    archivo,
    archivo_nombre_original,
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
    archivo,
    archivo_nombre_original
    )

Archivo_referencia_grabadora_sub <- Archivo_referencia_grabadora %>%
  select(
    grabadora_id,
    archivo,
    archivo_nombre_original
    )

Imagen_referencia_microfonos_sub <- Imagen_referencia_microfonos %>%
  select(
    grabadora_id,
    archivo,
    archivo_nombre_original
    )

Archivo_grabadora_sub <- Archivo_grabadora %>%
  select(
    grabadora_id,
    archivo,
    archivo_nombre_original,
    es_audible
    )
########

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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
    )

Huella_excreta_extra_sub <- Huella_excreta_extra %>%
  select(
    id,
    conglomerado_muestra_id
    )

Archivo_huella_excreta_extra_sub <- Archivo_huella_excreta_extra %>%
  select(
    huella_excreta_extra_id,
    archivo,
    archivo_nombre_original
    )
  
Especimen_restos_extra_sub <- Especimen_restos_extra %>%
  select(
    id,
    conglomerado_muestra_id
    )

Archivo_especimen_restos_extra_sub <- Archivo_especimen_restos_extra %>%
  select(
    especimen_restos_extra_id,
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
    )

# Creando las tablas de información de conglomerado y conglomerado/sitio.
# Éstas son las principales para generar los joins.

# Información de conglomerado:
Conglomerado_info <- Conglomerado_muestra_sub %>%
  select(
    conglomerado_muestra_id = id,
    nombre,
    fecha_visita,
    institucion
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo_nombre_original,
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo_nombre_original,
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
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
    archivo,
    archivo_nombre_original
    )

# Creando los nombres de las carpetas conglomerado_anio:
Conglomerado_carpetas <- Conglomerado_info %>%
  separate(fecha_visita, c("anio", "mes", "dia")) %>%
  mutate(
    cgl_anio_mes = paste0(nombre, "/", anio, "_", mes)
  ) %>%
  select(
    conglomerado_muestra_id,
    cgl_anio_mes,
    institucion
    )

# Creando las rutas asociadas a cada tipo de archivo:

Imagen_sitio_ruta <- Imagen_sitio_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/referencias/",
      nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Imagen_camara_ruta <- Imagen_camara_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    #sustituyendo lo matcheado con la regex por uno de sus substrings.
    #si no se matchea nada, todo se queda igual.
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/referencias/", nuevo_nombre,
      sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Imagen_grabadora_ruta <- Imagen_grabadora_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/referencias/", nuevo_nombre,
      sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Imagen_microfonos_ruta <- Imagen_microfonos_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/referencias/", nuevo_nombre,
      sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_metadatos_ruta <- Archivo_metadatos_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/referencias/", nuevo_nombre,
      sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_camara_ruta <- Archivo_camara_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(
      ruta_estructura, "/", cgl_anio_mes, "/fotos_videos/", nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
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
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/", carpeta, "/", nuevo_nombre,
      sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_especie_invasora_ruta <- Archivo_especie_invasora_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/especies_invasoras/",
      nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_huella_excreta_ruta <- Archivo_huella_excreta_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/huellas_excretas/",
      nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_especie_invasora_extra_ruta <- Archivo_especie_invasora_extra_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/registros_extra/",
      nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_huella_excreta_extra_ruta <- Archivo_huella_excreta_extra_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/registros_extra/",
      nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_especimen_restos_extra_ruta <- Archivo_especimen_restos_extra_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/registros_extra/",
      nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_conteo_ave_ruta <- Archivo_conteo_ave_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/otros/", nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_plaga_ruta <- Archivo_plaga_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/otros/", nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

Archivo_incendio_ruta <- Archivo_incendio_info %>%
  inner_join(Conglomerado_carpetas, by = "conglomerado_muestra_id") %>%
  mutate(
    nuevo_nombre = gsub("(.*\\.).*\\.(.*\\.).*\\.", "\\1\\2", archivo),
    ruta_salida = paste(ruta_estructura, "/", cgl_anio_mes, "/otros/", nuevo_nombre, sep = "")
  ) %>%
  select(
    cgl_anio_mes,
    nombre_original = archivo_nombre_original,
    nombre_web2py = archivo,
    nombre_cluster = nuevo_nombre,
    ruta_salida,
    institucion
  )

# Uniendo las tablas anteriores:

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

# Escribiendo csv con las rutas que va a tener cada archivo en la estructura de
# archivos del cliente de captura:
dir_archivos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos_intermedios")

ruta_archivo_nuevas_rutas <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_nuevas_rutas.csv"
  )

write_csv(Archivo_ruta, ruta_archivo_nuevas_rutas)

# También se guardarán como objetos de R, "ruta_estructura" y "Conglomerado_carpetas".
# La razón de que no se guarden en csv, es que estos objetos no los consideramos
# valiosos por sí mismos, sino son insumos para "5_crear_estructura_carpetas.R".

ruta_objeto_ruta_estructura <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_ruta_estructura.rds"
  )

saveRDS(ruta_estructura, ruta_objeto_ruta_estructura)

ruta_objeto_conglomerado_carpetas <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_conglomerado_carpetas.rds"
  )

saveRDS(Conglomerado_carpetas, ruta_objeto_conglomerado_carpetas)
#readRDS(ruta_objeto_conglomerado_carpetas)
