### Observaciones
# 1. En conglomerado incluir filtro de CONANP, CONAFOR, FMCN,...
# 2. No estamos llenando la variable monitoreo_tipo, por lo tanto para detectar
#     el tipo de monitoreo usamos el argumento nombre y comparamos con 
#     el string CONAFOR (sensible a mayúsculas)


### Shapefiles
# paquetes
library("rgdal")
library("sp")
library("raster")

library("RSQLite")
library("RPostgreSQL")
library("dplyr")

### Argumentos
# dir_base: directorio de la base de datos sqlite
# nombre: institución que muestreó
# dir_base <- "../2_crear_reportes/reportes/2015_06_22_CONAFOR/2015_06_22_CONAFOR.db"
# nombre <- "CONAFOR"
# anio_shape <- "2015"

args <- commandArgs(trailingOnly = TRUE)

dir_base <- args[1]
nombre <- args[2]
anio_shape <- args[3]


#### dir_base <- "base_output.db"

# Carpeta y nombre de salidas
dir.create("shapes")
nombre_shape <- paste(anio_shape, nombre, sep = "_")
dir <- paste("shapes/", nombre_shape, sep = "")
dir.create(dir)

base_input <- src_sqlite(dir_base)

# información para el shape
conglomerado <- collect(tbl(base_input, "Conglomerado_muestra")) %>%
  mutate(
    anio = substr(fecha_visita, 1, 4)
  ) %>%
  filter(anio == anio_shape) %>% # este filtro debe incluir FMCN, CONANP, ...
  select(id, cgl = nombre, fecha_visita)

# número de sitios
sitio <- collect(tbl(base_input, "Sitio_muestra")) %>%
  select(id, conglomerado_muestra_id, sitio_numero)

tab_sitio <- sitio %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  filter(sitio_numero != "Punto de control") %>%
  group_by(cgl) %>%
  summarise(
    n_sitios = n()
  )

# en caso de que queramos obtener las coordenadas del sitio
sitio_coords <- collect(tbl(base_input, "Sitio_muestra")) %>%
  filter(sitio_numero == "Centro") %>%
  mutate(
    lat = lat_grado + lat_min/60 + lat_seg/3600, 
    lon = lon_grado + lon_min/60 + lon_seg/3600, 
    lat = abs(lat),
    lon = abs(lon)
    ) %>%
  select(conglomerado_muestra_id, lat, lon) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  select(cgl, lat, lon)

# número de registros de especies invasoras
transecto_especie <- collect(tbl(base_input, 
    "Transecto_especies_invasoras_muestra")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  select(cgl, id)

tab_ei <- collect(tbl(base_input, "Especie_invasora")) %>%
  right_join(transecto_especie,
    by = c("transecto_especies_invasoras_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    n_registros_ei = sum(!is.na(id))
  )

# número de registros de huella/excreta
transecto_huella <- collect(tbl(base_input, 
  "Transecto_huellas_excretas_muestra")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  mutate(
    n_transectos = n(), 
    # primera fecha
    fecha = first(fecha)
  ) %>%
  select(cgl, id, fecha, n_transectos)

tab_he <- collect(tbl(base_input, "Huella_excreta")) %>%
  right_join(transecto_huella, 
    by = c("transecto_huellas_excretas_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    n_registros_he = sum(!is.na(id))
  )

# número de fotos con fauna
camara <- collect(tbl(base_input, "Camara")) %>%
  left_join(sitio, by = c("sitio_muestra_id" = "id")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  select(camara = nombre, cgl, id)

archivo_camara <- collect(tbl(base_input, "Archivo_camara"))

archivos <- archivo_camara %>%
  right_join(camara, by = c("camara_id" = "id")) 

tab_camara <- archivos %>%
  group_by(cgl) %>%
  summarise(
    fauna = sum(presencia == "T", na.rm = TRUE)
  )

# número de archivos grabadora
grabadora <- collect(tbl(base_input, "Grabadora")) %>%
  left_join(sitio, by = c("sitio_muestra_id" = "id")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id"))
  
archivo_grabadora <- collect(tbl(base_input, "Archivo_grabadora"))

archivos <- archivo_grabadora %>%
  right_join(select(grabadora, cgl, id, fecha_inicio, 
    hora_inicio, fecha_termino, hora_termino), 
    by = c("grabadora_id" = "id")) 

tab_grabadora <- archivos %>%
  group_by(cgl) %>%
  summarise(
    n_archivos_g = sum(!is.na(id))
    ) 

# número de registros extra
tab_er_extra <- collect(tbl(base_input, "Especimen_restos_extra")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    n_registros_er_extra = n()
  ) 
tab_ei_extra <- collect(tbl(base_input, "Especie_invasora_extra")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    n_registros_ei_extra = n()
  )
tab_he_extra <- collect(tbl(base_input, "Huella_excreta_extra")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    n_registros_he_extra = n()
  )
tab_extra <- tab_er_extra %>%
  left_join(tab_ei_extra, by = "cgl") %>%
  left_join(tab_he_extra, by = "cgl") %>%
  group_by(cgl) %>%
  mutate(
    n_registros_extra = sum(c(n_registros_er_extra, n_registros_ei_extra, 
      n_registros_he_extra), na.rm= T)
  ) %>%
  select(cgl, n_registros_extra)

# hay conteo de aves
tab_ave <- collect(tbl(base_input, "Punto_conteo_aves")) %>%
  mutate(ave_b = TRUE) %>%
  left_join(sitio, by = c("sitio_muestra_id" = "id")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  select(cgl, ave_b)

# Ramas (material leñoso)
tab_lenoso <- collect(tbl(base_input, "Transecto_ramas")) %>%
  left_join(sitio, by = c("sitio_muestra_id" = "id")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    lenoso_b = TRUE
    )

# hay punto carbono (carbono en el mantillo)
tab_carbono <- collect(tbl(base_input, "Punto_carbono")) %>%
  left_join(sitio, by = c("sitio_muestra_id" = "id")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    carbono_b = TRUE
    )

# número de árboles pequeños
tab_trans <- collect(tbl(base_input, "Arbol_transecto")) %>%
  left_join(sitio, by = c("sitio_muestra_id" = "id")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    n_arboles_p = n()
    )

# número de árboles grandes
tab_cuad <- collect(tbl(base_input, "Arbol_cuadrante")) %>%
  left_join(sitio, by = c("sitio_muestra_id" = "id")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(n_arboles_g = sum(existe == "T"))

# número de epífitas distintas (cambiará con el nuevo modelo!)
tab_epifitas <- collect(tbl(base_input, "Informacion_epifitas")) %>%
  mutate_each(
    funs(. == "T"), matches("observa")
    ) %>%
  left_join(sitio, by = c("sitio_muestra_id" = "id")) %>%
  right_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
    summarise_each(
      funs(sum(.) > 0), matches("observa")
      ) %>%
    mutate(
    n_epifitas = helechos_observados + orquideas_observadas + musgos_observados +
      liquenes_observados + cactaceas_observadas + bromeliaceas_observadas +
      otras_observadas
      ) %>%
  select(cgl, n_epifitas)

# hay info. de incendios
tab_incendio <- collect(tbl(base_input, "Incendio")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    incendio_b = TRUE) %>%
  select(cgl, incendio_b)

# número de plagas
tab_plagas <- collect(tbl(base_input, "Plaga")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    num_plagas = n()
    )

# Impactos actuales
tab_impactos <- collect(tbl(base_input, "Impacto_actual")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  group_by(cgl) %>%
  summarise(
    num_impactos = sum(hay_evidencia == "T")
  )

if(nombre == "CONAFOR"){
  tab_shape <- conglomerado %>%
    left_join(tab_sitio, by = "cgl") %>%
    left_join(tab_ei, by = "cgl") %>%
    left_join(tab_he, by = "cgl") %>%
    left_join(tab_camara, by = "cgl") %>%
    left_join(tab_grabadora, by = "cgl") %>%
    left_join(tab_extra, by = "cgl")  
  
  # NA->'No disp.'
  codeNA <- function(x) ifelse(is.na(x), "No disp.", x)
  tab_shape_f <- tab_shape %>%
    mutate_each(funs(codeNA)) %>%
    select(-id)
  colnames(tab_shape_f) <- c("Cgl", "Visita", "Sitios", "Invasoras", 
    "Huella/ex", "Fauna", "Grab", "Extra")
}else{
  codeTrue <- function(x) ifelse(x, "Si", NA)
  tab_shape <- conglomerado %>%
    left_join(tab_sitio, by = "cgl") %>%
    left_join(tab_ei, by = "cgl") %>%
    left_join(tab_he, by = "cgl") %>%
    left_join(tab_camara, by = "cgl") %>%
    left_join(tab_grabadora, by = "cgl") %>%
    left_join(tab_extra, by = "cgl") %>% 
    left_join(tab_ave, by = "cgl") %>%
    left_join(tab_lenoso, by = "cgl") %>%
    left_join(tab_carbono, by = "cgl") %>%
    left_join(tab_trans, by = "cgl") %>%
    left_join(tab_cuad, by = "cgl") %>%
    left_join(tab_epifitas, by = "cgl") %>%  
    left_join(tab_incendio, by = "cgl") %>%
    left_join(tab_plagas, by = "cgl") %>%
    left_join(tab_impactos, by = "cgl") %>%
    mutate_each(funs(codeTrue), contains("_b"))   
  
  # NA->'No disp.'
  codeNA <- function(x) ifelse(is.na(x), "No disp.", x)
  tab_shape_f <- tab_shape %>%
    mutate_each(funs(codeNA)) %>%
    select(-id)
  colnames(tab_shape_f) <- c("Cgl", "Visita", "Sitios", "Invasoras", 
    "Huella/ex", "Fauna", "Grab", "Extra", "Ave", "Leñoso", "Carbono", 
    "Arb_ch", "Arb_gd", "Epifitas", "Incendio", "Plagas", "Impactos")
}

# guardar Rdata para pruebas ggvis
save(tab_shape, sitio_coords, 
  file = paste("salidas/", nombre_shape, ".Rdata", sep = ""))


### hacer shapes
# cargar coordenadas (shapes 22025)
# coords <- readOGR("shapes_22025/Cong22025_lamb.shp", "Cong22025_lamb")
# coords_df <- coords %>%
#   data.frame() %>%
#   mutate(
#     Cgl = as.character(IdConglome)
#     ) %>%
#   select(-IdConglome, -Latitud, -Longitud)
# 

# cargar coordenadas (shapes SINaMBioD)
coords <- readOGR("mallaSiNaMBioD/mallaSiNaMBioD.shp", "mallaSiNaMBioD")

OGRinfo(coords)
coords_df <- coords %>%
  data.frame() %>%
  mutate(
    Cgl = as.character(id_snmb)
    ) %>%
  select(Cgl, coords.x1, coords.x2)

# Unir con tablas de sarmod/sacmod
tab_coords <- tab_shape_f %>%
  inner_join(coords_df, by = c("Cgl")) %>%
  as.data.frame()
coordinates(tab_coords) = ~coords.x1 + coords.x2
projection(tab_coords) <- projection(coords)

# Escribir shapes
writeOGR(tab_coords, dir, nombre_shape, driver = "ESRI Shapefile", 
  verbose = FALSE, 
  overwrite_layer = TRUE)


EPSG <- make_EPSG()
sum(EPSG$prj4 %in% pp)
pp <- coords@proj4string@projargs

tmp <- EPSG[(stri_detect(regex="longlat", str=EPSG$prj4) & 
    stri_detect(regex="longlat", str=EPSG$prj4) &
    stri_detect(regex = "ellps=WGS84", str=EPSG$prj4)) , ][1:25, ]
dim(EPSG)
dim(tmp)
tmp <- tmp[(grep("WGS84", EPSG$prj4)),]
