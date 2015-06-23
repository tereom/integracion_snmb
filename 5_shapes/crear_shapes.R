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
base_input <- src_sqlite("datos/storage.sqlite")

cgl <- collect(tbl(base_input, "Conglomerado_muestra")) %>%
  select(id, IdConglomerado = nombre, perturbado)

cgl_coords <- inner_join(conglomerado, coords_df, by = "IdConglomerado") %>%
  select(IdConglomerado, perturbado, coords.x1, coords.x2) %>%
  as.data.frame()

coordinates(ei_merged) = ~coords.x1 + coords.x2
projection(ei_merged) <- projection(coords)

writeOGR(ei_merged, "shapes", "prueba", driver = "ESRI Shapefile")


# información para el shape