
# Migración de esquema de bases de datos v10 a v12.

# Supuestos:
# 
# 1. A la hora de correr este script, ya se ha resuelto el problema de
# conglomerados repetidos.
# 2. De entrada, este script acepta una base sqlite fusionada en el formato antiguo,
# y regresa una base sqlite fusionada el nuevo formato.

# Cargamos los paquetes, RSQLite nos sirve para escribir las tablas en una base
# de datos Sqlite.

library(plyr)
library(dplyr)
library(tidyr)
library(stringi)
library(gdata)
library(RSQLite)

#### Inputs
# entrega: nombre del directorio donde se guardará el análisis
# entrega <- "prueba_fer"
# base_ruta: ruta de la base de datos a migrar de esquema
# base_ruta <- '../1_exportar_sqlite/bases/storage.sqlite'
# institucion_input: nombre de la institución
# institucion_input <- "CONANP"

# crear estructura de carpetas
# directorio padre dentro de carpeta migraciones
dir.create("migraciones")
dir_padre <- paste("migraciones/", entrega, sep = "")
dir.create(dir_padre)

# el archivo output_vacio.sqlite se debe guardar en una carpeta llamada: aux,
# localizada al nivel de este script. Ejemplo: aux/output_vacio.sqlite

copiaRenombra <- function(dir_j_archivo, dir_local, nombre){
  # dir_j_archivo: directorio (con nombre archivo) donde se ubica el archivo a copiar
  # dir_local: directorio (sin nombre de archivo) donde se copiará la base 
  # nombre: nombre nuevo del archivo (sin terminación)
  copia <- file.copy(dir_j_archivo, dir_local, overwrite = FALSE)
  terminacion <- stri_extract_first(dir_j_archivo, regex = "\\.[a-z]+")
  renombra <- file.rename(from = paste(dir_local, basename(dir_j_archivo), 
    sep = "/"), 
    to = paste(dir_local, "/", nombre, terminacion, sep = ""))
}

#Copiando el archivo con el esquema de la base de datos a su lugar designado.
copiaRenombra("aux/output_vacio.sqlite", dir_padre, entrega)

#Conexión a la base de datos de entrada:
base_input <- src_sqlite(base_ruta)

#Leyendo todas las tablas
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

Arbol_transecto <- collect(tbl(base_input, "Arbol_transecto"))
Arbol_cuadrante <- collect(tbl(base_input, "Arbol_cuadrante"))
Transecto_ramas <- collect(tbl(base_input, "Transecto_ramas"))
Rama_1000h <- collect(tbl(base_input, "Rama_1000h"))
Punto_carbono <- collect(tbl(base_input, "Punto_carbono"))

Informacion_epifitas <- collect(tbl(base_input, "Informacion_epifitas"))

Impacto_actual <- collect(tbl(base_input, "Impacto_actual"))
Plaga <- collect(tbl(base_input, "Plaga"))
Archivo_plaga <- collect(tbl(base_input, "Archivo_plaga"))
Incendio <- collect(tbl(base_input, "Incendio"))
Archivo_incendio <- collect(tbl(base_input, "Archivo_incendio"))

# Transformando de v10 a v12

Conglomerado_muestra_n <- Conglomerado_muestra %>%
  mutate(
    institucion = institucion_input
    ) %>%
  select(
    id,
    nombre,
    fecha_visita,
    predio,
    compania,
    tipo,
    estado,
    municipio,
    tenencia,
    uso_suelo_tipo,
    monitoreo_tipo,
    institucion,
    vegetacion_tipo,
    perturbado,
    comentario
    )



Informacion_epifitas_n <- Informacion_epifitas %>%
  inner_join(Sitio_muestra, by = c("sitio_muestra_id" = "id")) %>%
  mutate(
    helechos_observados = ifelse(helechos_observados == "T", 1, 0),
    orquideas_observadas = ifelse(orquideas_observadas == "T", 1, 0),
    musgos_observados = ifelse(musgos_observados == "T", 1, 0),
    liquenes_observados = ifelse(liquenes_observados == "T", 1, 0),
    cactaceas_observadas = ifelse(cactaceas_observadas == "T", 1, 0),
    bromeliaceas_observadas = ifelse(bromeliaceas_observadas == "T", 1, 0),
    otras_observadas = ifelse(otras_observadas == "T", 1, 0)
    ) %>%
  group_by(conglomerado_muestra_id) %>%
    summarise(
      id = first(id),
      helechos_observados = ifelse(sum(helechos_observados) > 0, "T", "F"),
      orquideas_observadas = ifelse(sum(orquideas_observadas) > 0, "T", "F"),
      musgos_observados = ifelse(sum(musgos_observados) > 0, "T", "F"),
      liquenes_observados = ifelse(sum(liquenes_observados) > 0, "T", "F"),
      cactaceas_observadas = ifelse(sum(cactaceas_observadas) > 0, "T", "F"),
      bromeliaceas_observadas = ifelse(sum(bromeliaceas_observadas) > 0, "T", "F"),
      otras_observadas = ifelse(sum(otras_observadas) > 0, "T", "F"),
      nombre_otras = ifelse(otras_observadas > 0, trim(gsub('NA[:space]?', '',
        paste(nombre_otras, collapse = " "))), NA)
      ) %>%
  select(
    id,
    conglomerado_muestra_id,
    helechos_observados,
    orquideas_observadas,
    musgos_observados,
    liquenes_observados,
    cactaceas_observadas,
    bromeliaceas_observadas,
    otras_observadas,
    nombre_otras)

Conteo_ave_n <- Conteo_ave %>%
  mutate(
      nombre_comun_en_lista = ifelse(nombre_comun == "", NA, nombre_en_lista),
      nombre_cientifico_en_lista = ifelse(nombre_cientifico == "", NA, nombre_en_lista)
    ) %>%
  select(
    id,
    punto_conteo_aves_id,
    nombre_comun_en_lista,
    nombre_comun,
    nombre_cientifico_en_lista,
    nombre_cientifico,
    es_visual,
    es_sonora,
    numero_individuos,
    distancia_aproximada
    )

# Escribiendo tablas en la base de salida:

base_output <- dbConnect(RSQLite::SQLite(), paste(dir_padre, "/", entrega, ".sqlite", sep = ""))

# "Conglomerado_muestra" modificada
dbWriteTable(base_output, "Conglomerado_muestra", as.data.frame(Conglomerado_muestra_n), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Sitio_muestra", as.data.frame(Sitio_muestra), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Imagen_referencia_sitio", as.data.frame(Imagen_referencia_sitio), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Camara", as.data.frame(Camara), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_camara", as.data.frame(Archivo_camara), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Imagen_referencia_camara", as.data.frame(Imagen_referencia_camara), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Grabadora", as.data.frame(Grabadora), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Imagen_referencia_grabadora", as.data.frame(Imagen_referencia_grabadora), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_referencia_grabadora", as.data.frame(Archivo_referencia_grabadora), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Imagen_referencia_microfonos", as.data.frame(Imagen_referencia_microfonos), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_grabadora", as.data.frame(Archivo_grabadora), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Transecto_especies_invasoras_muestra", as.data.frame(Transecto_especies_invasoras_muestra), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Especie_invasora", as.data.frame(Especie_invasora), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_especie_invasora", as.data.frame(Archivo_especie_invasora), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Transecto_huellas_excretas_muestra", as.data.frame(Transecto_huellas_excretas_muestra), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Huella_excreta", as.data.frame(Huella_excreta), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_huella_excreta", as.data.frame(Archivo_huella_excreta), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Especie_invasora_extra", as.data.frame(Especie_invasora_extra), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_especie_invasora_extra", as.data.frame(Archivo_especie_invasora_extra), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Huella_excreta_extra", as.data.frame(Huella_excreta_extra), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_huella_excreta_extra", as.data.frame(Archivo_huella_excreta_extra), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Especimen_restos_extra", as.data.frame(Especimen_restos_extra), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_especimen_restos_extra", as.data.frame(Archivo_especimen_restos_extra), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Punto_conteo_aves", as.data.frame(Punto_conteo_aves), overwrite = FALSE, append = TRUE)
# "Conteo_ave modificada"
dbWriteTable(base_output, "Conteo_ave", as.data.frame(Conteo_ave_n), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_conteo_ave", as.data.frame(Archivo_conteo_ave), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Arbol_transecto", as.data.frame(Arbol_transecto), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Arbol_cuadrante", as.data.frame(Arbol_cuadrante), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Transecto_ramas", as.data.frame(Transecto_ramas), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Rama_1000h", as.data.frame(Rama_1000h), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Punto_carbono", as.data.frame(Punto_carbono), overwrite = FALSE, append = TRUE)

# "Informacion_epifitas" modificada
dbWriteTable(base_output, "Informacion_epifitas", as.data.frame(Informacion_epifitas_n), overwrite = FALSE, append = TRUE)

dbWriteTable(base_output, "Impacto_actual", as.data.frame(Impacto_actual), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Plaga", as.data.frame(Plaga), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_plaga", as.data.frame(Archivo_plaga), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Incendio", as.data.frame(Incendio), overwrite = FALSE, append = TRUE)
dbWriteTable(base_output, "Archivo_incendio", as.data.frame(Archivo_incendio), overwrite = FALSE, append = TRUE)

dbDisconnect(base_output)



