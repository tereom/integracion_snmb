# Este script constituye un paso para copiar los archivos guardados en uno
# o varios clientes de captura a la estructura de carpetas del SNMB:

#estructura:
# nombre_estructura
# ├───conglomerado
# |   ├───anio_mes
# |   |   ├───formato_campo
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

# En este script, como su nombre lo indica, se mapean a la estructura de carpetas
# los formatos de campo cuyas rutas fueron encontradas en "dir_entrega",
# utilizando el script "8_encontrar_rutas_formatos.sh".

# Cabe destacar que éste paso no se separa en dos partes (crear nuevas rutas, y
# mapearlas después), a diferencia de lo que sucede con los otros
# archivos. Ésto debido a que los formatos no están registrados en la base de
# datos, por lo que se requiere crear las nuevas rutas únicamente a partir de sus
# rutas actuales (eliminando la necesidad de separar los pasos).

# Este script requiere "dir_entrega" como input, para localizar el archivo con
# las rutas a los formatos de campo:
# "temp_basename(dir_entrega)_8_lista_formatos.csv"

# También requiere el objeto que contiene la información de las carpetas de muestreo
# de conglomerado correspondientes a dir_entrega, creadas en la estructura de archivos,
# para poder asociar cada formato encontrado en dir_entrega, a un cgl/fecha
# registrado en la misma, sin tomar en cuenta otras entregas. Esto es especialmente
# útil si los formatos de campo no tienen información de la fecha de muestreo en
# ninguna parte de su ruta.
# "temp_basename(dir_entrega)_3_conglomerado_carpetas.rds

# Finalmente, requiere el objeto con la ruta a la estructura de carpetas, con el
# fin de crear la ruta absoluta hasta esta última, y poder crear de manera adecuada
# las rutas destino de los formatos de campo.
# "temp_basename(dir_entrega)_3_ruta_estructura.rds

# El output de este script es el archivo:
# reportes/temp_basename(ruta_entrega)/productos/
# temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv
# que contiene las rutas origen y destino de los formatos de campo.

library("plyr")
library("dplyr")
library("tidyr")
library("readr")
library("stringi")

# Nombre de la carpeta donde se encuentran los archivos (éste se pide para formar
# las rutas hacia los archivos y objetos calculados con anterioridad).
dir_entrega <- args[1]
#dir_entrega <- "/Volumes/sacmod"

dir_archivos <- paste0(
  "reportes",
  "/temp_", basename(dir_entrega),
  "/productos"
  )

# Archivo con las rutas actuales de los formatos de campo a migrar:
ruta_archivo_lista_formatos <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_8_lista_formatos_nueva.csv"
  )

# Objeto con la ruta hacia la estructura de carpetas:
ruta_objeto_ruta_estructura <- paste0(
  dir_archivos,
  "/", "temp_", basename(dir_entrega), "_3_ruta_estructura.rds"
  )

# Objeto con la información de las muestras de conglomerado que se encuentran
# en dir_entrega:
ruta_objeto_conglomerado_carpetas <- paste0(
  dir_archivos,
  "/", "temp_", basename(dir_entrega), "_3_conglomerado_carpetas.rds"
  )

##################

# Formando el data frame de Formatos_campo_info, con la lista de rutas a archivos con
# formatos de campo en "dir_entrega", más el nombre base de cada archivo enlistado.

# Leyendo las funciones para obtener el nombre base de archivos:
source("aux/obtener_nombre_base.R")

Formatos_campo_info <- read_csv(ruta_archivo_lista_formatos, col_names = FALSE) %>%
  transmute(
    ruta_entrada = X1,
    nombre_entrada = splitPathFile(ruta_entrada)[[3]]
  ) %>%
  
  # Obteniendo de "nombre_entrada" el conglomerado al cuál corresponde un formato
  # de campo, y, si es posible, la fecha de muestreo. Esta información servirá
  # para localizar la muestra de conglomerado a la cuál asociarle el formato, además
  # de para renombrarlo.
  mutate(
    # se sabe que los números de conglomerado forman la primera parte del nombre
    # del archivo.
    cgl = stri_match_first_regex(nombre_entrada, "^([0-9]+)_?")[,2] %>%
      as.numeric(),
    
    # se sabe que, en caso de existir, la fecha va después del "conglomerado_"
    fecha_cruda = stri_match_first_regex(nombre_entrada, "[0-9]+_([0-9]+)")[,2],
    
    # sabemos que es muy difícil encontrarse en una fecha un patrón como 2014, que
    # no sea el año, puesto que tendría que ser un día pegado a un año los meses
    # no llegan a valores tan altos como 20 o 14).
    anio = stri_extract_first_regex(fecha_cruda, "201[456]"),
    
    # el mes son los dos números anteriores/posteriores al año, dependiendo del
    # formato de la fecha.
    mes = ifelse(stri_detect_regex(fecha_cruda, "201[456][0-9]+"),
      stri_match_first_regex(fecha_cruda, "201[456]([0-9]{2})")[,2],
      stri_match_first_regex(fecha_cruda, "([0-9]{2})201[456]")[,2]
    ),
    
    # el día son los dos números anteriores/posteriores al mes, dependiendo del
    # formato de la fecha.
    dia = ifelse(stri_detect_regex(fecha_cruda, "201[456][0-9]+"),
      stri_match_first_regex(fecha_cruda, "201[456][0-9]{2}([0-9]{2})")[,2],
      stri_match_first_regex(fecha_cruda, "([0-9]{2})[0-9]{2}201[456]")[,2]
    ),
    
    # la fecha, en formato anio_mes, es para poder hacer el join con
    # "Conglomerado_carpetas"
    fecha = ifelse(is.na(anio) | is.na(mes), NA, paste0(anio, "_", mes))
  ) %>%
  # Esta tabla no se va a exportrar a csv, ya que como referencia de las rutas a 
  # los formatos tenemos a "temp_basename(dir_entrega)_8_lista_formatos.csv", por
  # ello, podemos filtrar sin riesgo a perder información útil en caso de error.
  
  # Para generar el reporte de "formatos que no se asociaron a ningún muestreo",
  # se utilizará la lista antes mencionada (por completez y simplicidad)
  filter(!is.na(cgl))
View(Formatos_campo_info)

##################

# Leyendo la ruta hacia la estructura de carpetas, así como la información de
# las muestras de conglomerado en "dir_entrega":

ruta_estructura <- readRDS(ruta_objeto_ruta_estructura)
Conglomerado_carpetas <- readRDS(ruta_objeto_conglomerado_carpetas) %>%
  mutate(
    cgl = as.numeric(cgl)
  )

##################

# Ahora sí comenzaremos a hacer los joins de las rutas de los formatos de campo en
# dir_entrega, con los muestreos registrados en la base de datos (Conglomerado_carpetas).
# Los pasos para esto son:

# 1. Separar la tabla de "Formato_campo_info" en dos tablas, una referente a los
# archivos que sólo tienen información del conglomerado en su nombre, y otra
# que corresponde a los que tienen información del nombre y la fecha. Se usará
# la "fecha" (no cruda) para este aspecto, ya que es la que corresponde a la llave
# que se usará, y no queremos que un formato de campo quede filtrado de la
# tabla sin fecha porque tiene "fecha_cruda", pero, al no tener "fecha", no sirva
# para hacer los joins.
# Ya filtramos con anterioridad los archivos sin datos del conglomerado.

Formatos_campo_info_llave_cgl <- Formatos_campo_info %>%
  filter(is.na(fecha))

Formatos_campo_info_llave_cgl_fecha <- Formatos_campo_info %>%
  filter(!is.na(fecha))

# 2. Hacer los joins de cada una de las tablas anteriores con "Conglomerado_carpetas",
# usando como llave ya sea el cgl o el cgl y la fecha. Notar que aquí estamos suponiendo
# que los nombres de los formatos tienen todos el mismo formato: si en dir_entrega
# hay un conglomerado muestreado dos veces, pero en un formato sólo viene el nombre
# del conglomerado, y en otro, además, la fecha de muestreo, el primer formato
# quedará asociado a ambos muestreos. 

# Más general, suponemos que el nombre del archivo con el formato de campo
# identifica de manera única a un muestreo de conglomerado contenido en dicha
# entrega. Si no es así, el problema quedará detectado en los reportes de muestreo.
# Ésto es porque no queremos complicar de más el código.

# Encontrando el muestreo de conglomerado al que corresponde cada formato. Sabemos
# que la fecha de muestreo es la fecha en el nombre del archivo (si es que la tiene).
# Lo ideal sería que cada renglón de "Conglomerado_carpetas" tuviera asociado al
# menos un formato de campo (posiblemente ésto no pase, si no tenemos los formatos
# completos)

# El primer caso es asociar a cada muestreo de conglomerado su formato de campo,
# en el caso que el nombre del formato tenga el conglomerado únicamente:

Rutas_entrada_salida_llave_cgl <- Conglomerado_carpetas %>%
  inner_join(Formatos_campo_info_llave_cgl, by = "cgl") %>%
  mutate(
    nuevo_nombre = paste0(cgl, "_", fecha.x, ".pdf"),
    # Sabemos que la carpeta "cgl/fecha.x" existe pues con "Conglomerado_carpetas"
    # creamos precísamente la estructura de carpetas.
    ruta_salida = paste0(ruta_estructura, "/", cgl, "/", fecha.x, "/formato_campo/", nuevo_nombre)
  ) %>%
  select(
    cgl,
    fecha = fecha.x,
    institucion,
    ruta_entrada,
    ruta_salida
  )
#glimpse(Rutas_entrada_salida_llave_cgl)
#Rutas_entrada_salida_llave_cgl$ruta_salida

Rutas_entrada_salida_llave_cgl_fecha <- Conglomerado_carpetas %>%
  inner_join(Formatos_campo_info_llave_cgl_fecha, by = c("cgl", "fecha")) %>%
  mutate(
    nuevo_nombre = paste0(cgl, "_", fecha, ".pdf"),
    # Sabemos que la carpeta "cgl/fecha" existe pues con "Conglomerado_carpetas"
    # creamos precísamente la estructura de carpetas.
    ruta_salida = paste0(ruta_estructura, "/", cgl, "/", fecha, "/formato_campo/", nuevo_nombre)
  ) %>%
  select(
    cgl,
    fecha,
    institucion,
    ruta_entrada,
    ruta_salida
  )
#glimpse(Rutas_entrada_salida_llave_cgl_fecha)
#Rutas_entrada_salida_llave_cgl_fecha$ruta_salida

Rutas_entrada_salida <- Rutas_entrada_salida_llave_cgl %>%
  rbind(Rutas_entrada_salida_llave_cgl_fecha)

#Guardando "Rutas_entrada_salida" en un archivo csv:
ruta_archivo_mapeo_rutas_formatos <- paste0(
  dir_archivos,
  "/temp_", basename(dir_entrega), "_9_mapeo_rutas_formatos.csv"
  )

write_csv(Rutas_entrada_salida, ruta_archivo_mapeo_rutas_formatos)

# Finalmente, cabe destacar que al hacer el join anterior, debido a que renombramos
# los formatos utilizando el nombre del conglomerado y la fecha, obtenidos de
# la tabla " Conglomerado_carpetas", entonces puede ser que formatos distintos
# tengan la misma ruta de salida. Por ello, hay que lidiar con este problema en
# la migración de archivos (renombrando apropiadamente para evitar sobreescribir)

#El problema anterior puede surgir si hay distintos formatos que se asocian a un
# único muestreo (por ejemplo, porque no tienen información de fecha los nombres
# de los formatos, y en la entrega se muestreó más de una vez el mismo conglomerado),

#Formatos que no se asociaron a ningún conglomerado:
Formatos_no_asociados <- Formatos_campo_info_restantes %>%
  anti_join(Formatos_por_muestreo_join_cgl_fecha, by = "ruta_entrada")

#Viendo si coinciden en conglomerado los formatos no asociados, con algún muestreo

sum(Formatos_no_asociados$cgl %in% Conglomerado_carpetas$cgl)
# Posiblemente estos formatos está con 2 nombres: el nombre del conglomerado
# y el nombre del conglomerado_fecha. Como ya fueron incluídos los primeros,
# éstos ya no fueron incluidos. Creo que es mejor ser conservadores e incluir todos...