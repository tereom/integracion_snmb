### Shapefiles
# paquetes
library("rgdal")
library("sp")
library("raster")

library("RSQLite")
library("RPostgreSQL")
library("dplyr")

# cargar coordenadas (shapes de Pedro)
coords <- readOGR("shapes_22025/Cong22025_lamb.shp", "Cong22025_lamb")

coords_df <- data.frame(coords)
names(coords_df) <- c("IdConglomerado", "Latitud", "Longitud", "coords.x1", 
  "coords.x2")
coords_df$IdConglomerado <- as.character(coords_df$IdConglomerado)
head(coords_df)

# base de datos para unir
base_input <- src_sqlite("../bases_prueba/storage.sqlite")

cgl <- collect(tbl(base_input, "Conglomerado_muestra")) %>%
  select(id, IdConglomerado = nombre, perturbado)

cgl_coords <- inner_join(conglomerado, coords_df, by = "IdConglomerado") %>%
  select(IdConglomerado, perturbado, coords.x1, coords.x2) %>%
  as.data.frame()

coordinates(ei_merged) = ~coords.x1 + coords.x2
projection(ei_merged) <- projection(coords)

writeOGR(ei_merged, "shapes", "prueba", driver = "ESRI Shapefile")

# información para el shape
cgl <- collect(tbl(base_input, "Conglomerado_muestra")) %>%
  select(id, cgl = nombre, fecha_visita)

# número de sitios
sitio <- collect(tbl(base_input, "Sitio_muestra")) %>%
  select(id, conglomerado_muestra_id, sitio_numero)

tab_sitio <- sitio %>%
  left_join(cgl, by = c("conglomerado_muestra_id" = "id")) %>%
  filter(sitio_numero != "Punto de control") %>%
  group_by(cgl) %>%
  summarise(
    n_sitios = n()
  )

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
  left_join(cgl, by = c("conglomerado_muestra_id" = "id")) %>%
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
tab_ei_extra <- collect(tbl(base_input, "Especimen_restos_extra")) %>%
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
  mutate(ave = "Sí") %>%
  left_join(sitio, by = c("sitio_muestra_id" = "id")) %>%
  left_join(conglomerado, by = c("conglomerado_muestra_id" = "id")) %>%
  select(cgl, ave)

tab_cgl <- cgl %>%
  left_join(tab_sitio, by = "cgl") %>%
  left_join(tab_ei, by = "cgl") %>%
  left_join(tab_he, by = "cgl") %>%
  left_join(tab_camara, by = "cgl") %>%
  left_join(tab_grabadora, by = "cgl") %>%
  left_join(tab_extra, by = "cgl") %>%
  left_join(tab_ave, by = "cgl") %>%
  

  left_join(select(tab_ei_extra, cgl, ei_extra_b = n_registros)) %>%
  left_join(select(tab_he_extra, cgl, he_extra_b = n_registros)) %>%
  left_join(select(tab_er_extra, cgl, er_extra_b = n_registros)) %>%
  mutate_each(funs(not.na), contains("_b")) 
