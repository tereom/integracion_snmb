# cambiar proyeccion por la proyección que usa OpenLayers
# cambiar malla por la malla.Rmd que se creó para 2_crear_reportes


### Shapefiles resumen de datos en base de datos
### Argumentos
# dir: directorio donde se encuentra la base de datos sqlite (.sqlite)
# dir <- "."
args <- commandArgs(trailingOnly = TRUE)
dir <- args[1]

# paquetes
library("rgdal")
library("sp")
library("raster")

library("RSQLite")
library("RPostgreSQL")
library("plyr")
library("dplyr")


### Leer shapes
# cargar coordenadas malla que se creó para 2_crear_reportes
load("../2_crear_reportes/malla.RData")
coords_df <- malla %>%
  mutate(
    Cgl = as.character(cgl)
  ) %>%
  select(-cgl)


# Crear carpeta de salidas
dir.create("shapes")

crearShape <- function(nombre_inst = c("CONAFOR", "CONANP", "FMCN"), 
  anio_shape = c("2013", "2014", "2015"), base_input = base_input){
  # nombre_inst (string): "CONAFOR", "CONANP" ó "FMCN", c("CONAFOR", "CONANP")
  # anio_shape (string): "2014", "2015", c("2014", "2015")
  # mult_insts (logical): si se va hacer un mismo shape para varias insts.
  
  nombre_shape <- paste(paste(anio_shape, collapse = "_"), 
    paste(nombre_inst, collapse = "_"), sep = "_")
  dir_shapes <- paste("shapes/", nombre_shape, sep = "")
  dir.create(dir_shapes)

  # identificamos si el shape corresponderá a más de una institución
  mult_insts <- ifelse(length(nombre_inst) > 1, TRUE, FALSE)
  # información para el shape
  conglomerado <- collect(tbl(base_input, "Conglomerado_muestra")) %>%
    mutate(
      anio = substr(fecha_visita, 1, 4)
    ) %>%
    filter(anio %in% anio_shape, institucion %in% nombre_inst)
  if(mult_insts){
    conglomerado <- select(conglomerado, inst = institucion, 
      conglomerado_muestra_id = id, cgl = nombre, fecha_visita)
  }else{
    conglomerado <- select(conglomerado, conglomerado_muestra_id = id, 
      cgl = nombre, fecha_visita)
  }
  
  # número de sitios
  sitio <- collect(tbl(base_input, "Sitio_muestra")) %>%
    select(sitio_muestra_id = id, conglomerado_muestra_id, sitio_numero) %>%
    right_join(conglomerado, by = "conglomerado_muestra_id")
  
  tab_sitio <- sitio %>%
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
      lon = ifelse(lon_grado > 0,  lon_grado + lon_min/60 + lon_seg/3600,
        -(lon_grado - lon_min/60 - lon_seg/3600)),
      lon = -lon
    ) %>%
    select(conglomerado_muestra_id, lat, lon) %>%
    right_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
    select(cgl, lat, lon)
  
  # número de registros de especies invasoras
  transecto_especie <- collect(tbl(base_input, 
    "Transecto_especies_invasoras_muestra")) %>%
    right_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
    select(cgl, transecto_especies_invasoras_id = id)
  
  tab_ei <- collect(tbl(base_input, "Especie_invasora")) %>%
    right_join(transecto_especie,
      by = c("transecto_especies_invasoras_id")) %>%
    group_by(cgl) %>%
    summarise(
      n_registros_ei = sum(!is.na(id))
    )
  
  # número de registros de huella/excreta
  transecto_huella <- collect(tbl(base_input, 
    "Transecto_huellas_excretas_muestra")) %>%
    right_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
    select(cgl, transecto_huellas_excretas_id = id)
  
  tab_he <- collect(tbl(base_input, "Huella_excreta")) %>%
    right_join(transecto_huella, 
      by = c("transecto_huellas_excretas_id")) %>%
    group_by(cgl) %>%
    summarise(
      n_registros_he = sum(!is.na(id))
    )
  
  # número de fotos con fauna
  camara <- collect(tbl(base_input, "Camara")) %>%
    right_join(sitio, by = c("sitio_muestra_id")) %>%
    select(camara = nombre, cgl, camara_id = id)
  
  archivos <- collect(tbl(base_input, "Archivo_camara")) %>%
    right_join(camara, by = c("camara_id")) 
  
  tab_camara <- archivos %>%
    group_by(cgl) %>%
    summarise(
      fauna = sum(presencia == "T", na.rm = TRUE)
    )
  
  # número de archivos grabadora
  grabadora <- collect(tbl(base_input, "Grabadora")) %>%
    right_join(sitio, by = c("sitio_muestra_id")) %>%
    select(grabadora = nombre, cgl, grabadora_id = id)
  
  archivos <- collect(tbl(base_input, "Archivo_grabadora")) %>%
    right_join(grabadora, by = c("grabadora_id")) 
  
  tab_grabadora <- archivos %>%
    group_by(cgl) %>%
    summarise(
      n_archivos_g = sum(!is.na(id))
    ) 
  
  # número de registros extra
  tab_er_extra <- collect(tbl(base_input, "Especimen_restos_extra")) %>%
    right_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(
      n_registros_er_extra = sum(!is.na(id))
    ) 
  tab_ei_extra <- collect(tbl(base_input, "Especie_invasora_extra")) %>%
    right_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(
      n_registros_ei_extra = sum(!is.na(id))
    )
  tab_he_extra <- collect(tbl(base_input, "Huella_excreta_extra")) %>%
    right_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(
      n_registros_he_extra = sum(!is.na(id))
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
    inner_join(sitio, by = c("sitio_muestra_id")) %>%
    select(cgl, ave_b) %>%
    group_by(cgl) %>%
    summarise(
      ave_b = TRUE
    )
  
  # Ramas (material leñoso)
  tab_lenoso <- collect(tbl(base_input, "Transecto_ramas")) %>%
    inner_join(sitio, by = c("sitio_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(
      lenoso_b = TRUE
    )
  
  # hay punto carbono (carbono en el mantillo)
  tab_carbono <- collect(tbl(base_input, "Punto_carbono")) %>%
    inner_join(sitio, by = c("sitio_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(
      carbono_b = TRUE
    )
  
  # número de árboles pequeños
  tab_trans <- collect(tbl(base_input, "Arbol_transecto")) %>%
    right_join(sitio, by = c("sitio_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(
      n_arboles_p = sum(!is.na(id))
    )
  
  # número de árboles grandes
  tab_cuad <- collect(tbl(base_input, "Arbol_cuadrante")) %>%
    right_join(sitio, by = c("sitio_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(n_arboles_g = sum(existe == "T", na.rm = TRUE))
  
  # número de epífitas distintas
  tab_epifitas <- collect(tbl(base_input, "Informacion_epifitas")) %>%
    mutate_each(
      funs(. == "T"), matches("observa")
    ) %>%
    right_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
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
    inner_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(
      incendio_b = TRUE) %>%
    select(cgl, incendio_b)
  
  # número de plagas
  tab_plagas <- collect(tbl(base_input, "Plaga")) %>%
    inner_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(
      num_plagas = sum(!is.na(id))
    )
  
  # Impactos actuales
  tab_impactos <- collect(tbl(base_input, "Impacto_actual")) %>%
    inner_join(conglomerado, by = c("conglomerado_muestra_id")) %>%
    group_by(cgl) %>%
    summarise(
      num_impactos = sum(hay_evidencia == "T")
    )
  
  if(!mult_insts & nombre_inst == "CONAFOR"){
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
      select(-conglomerado_muestra_id)
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
      select(-conglomerado_muestra_id)
    if(mult_insts){
      colnames(tab_shape_f) <- c("Inst", "Cgl", "Visita", "Sitios", "Invasoras", 
        "Huella/ex", "Fauna", "Grab", "Extra", "Ave", "Leñoso", "Carbono", 
        "Arb_ch", "Arb_gd", "Epifitas", "Incendio", "Plagas", "Impactos")
    }else{
      colnames(tab_shape_f) <- c("Cgl", "Visita", "Sitios", "Invasoras", 
        "Huella/ex", "Fauna", "Grab", "Extra", "Ave", "Leñoso", "Carbono", 
        "Arb_ch", "Arb_gd", "Epifitas", "Incendio", "Plagas", "Impactos")
    }

  }
  # Unir con tablas de sarmod/sacmod
  tab_coords <- tab_shape_f %>%
    inner_join(coords_df, by = c("Cgl")) %>%
    as.data.frame()
  coordinates(tab_coords) = ~lon+lat
  projection(tab_coords) <- "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"
  
  # Escribir shapes
  writeOGR(tab_coords, dir_shapes, nombre_shape, driver = "ESRI Shapefile", 
    verbose = FALSE, 
    overwrite_layer = TRUE)
  
  # guardar Rdata para pruebas ggvis
  save(tab_shape, sitio_coords, 
    file = paste("salidas/", nombre_shape, ".Rdata", sep = ""))
  
  tab_shape_f
}

### Leer base
dir_base <- list.files(path = dir, recursive = TRUE, full.names = TRUE, 
  pattern = "\\.sqlite$")
base_input <- src_sqlite(dir_base)

# fmcn_2015 <- crearShape(nombre_inst = "FMCN", anio_shape = "2015", 
#   base_input = base_input)
# fmcn_2014 <- crearShape(nombre_inst = "FMCN", anio_shape = "2014", 
#   base_input = base_input)
# conafor_2015 <- crearShape(nombre_inst = "CONAFOR", anio_shape = "2015", 
#   base_input = base_input)
# conafor_2014 <- crearShape(nombre_inst = "CONAFOR", anio_shape = "2014", 
#   base_input = base_input)

conglomerado_m <- collect(tbl(base_input, "Conglomerado_muestra")) %>%
  mutate(
    anio = substr(fecha_visita, 1, 4)
  )
anios <- sort(unique(conglomerado_m$anio))
insts <- unique(conglomerado_m$institucion)
if("2013" %in% anios) anios <- anios[-1]

comb <- expand.grid(insts, anios)
tabs <- lapply(1:nrow(comb), function(i) crearShape(nombre_inst = comb[i, 1], 
  anio_shape = comb[i, 2], 
  base_input))

# shape con todos los conglomerados
# shapes_todos <- crearShape(nombre_inst = c("CONAFOR", "CONANP", "FMCN"), 
#   anio_shape = c("2014", "2015"))
