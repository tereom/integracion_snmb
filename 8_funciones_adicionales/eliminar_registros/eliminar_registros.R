library(dplyr)
library(DBI)
library(RSQLite)
library(RPostgreSQL)
library(readr)
library(stringi)

### Observaciones
# 1. Por ahora eliminaRegistros sólo acepta variables de tipo caracter, 
#   extender a todos los tipos es inmediato (incluir if en construcción de 
#   vector_comillas después de reconocer el tipo)
# 2. Esta versión de elimina solo considera eliminar conglomerados 
#   completos porque se construyó para arreglar CONAFOR, se debe generalizar
#   para aceptar conglomerado Y año.

eliminaRegistros <- function(driver = "SQLite", path_base = ".", tabla, 
  variable, valores){
  # elimina los registros con valor valores en variable
  # driver: driver de la base de datos "SQLite" ó "PostgreSQL"
  # path: en caso de seleccionar SQLite, el nombre inclyendo ruta de la base
  #   de datos sqlite
  # tabla: tabla en que se eliminarán los registros
  # variable: variable por la que se va a eliminar
  # valores: valores de la variable var a eliminar 
  
  drv <- dbDriver(driver)

  if(driver == "SQLite"){
    con <- dbConnect(drv, path_base) 
    # activar funcionalidad de llaves foráneas
    dbSendQuery(con, "PRAGMA foreign_keys = ON")
  }else{
    PASS_SNMB = Sys.getenv("PASS_SNMB")
    con <- dbConnect(drv, dbname = "snmb", host = "dbms", user = "snmb", 
      password = PASS_SNMB)
  }
  
  valores_comillas <- Reduce("c",lapply(valores, function(i){
    paste("'", i, "'", sep = "")
    }))
  vector_comillas <- paste("(", paste(valores_comillas, collapse = ","), ")", 
    sep = "")
  
  num_registros <- dbGetQuery(con, paste("select count(*) from ", tabla, 
    sep = ""))
  
  registros_eliminar <- dbGetQuery(con, paste("select count(*) from ", 
    tabla, " where ", tabla, ".", variable, " in ", vector_comillas, sep = ""))
  
  ids_eliminar <- dbGetQuery(con, paste("select ", variable, ", id from ", 
    tabla, " where ", tabla, ".", variable, " in ", vector_comillas, sep = ""))
    
  eliminar <- dbSendQuery(con, paste("delete from ", 
    tabla, " where ", tabla, ".", variable, " in ", vector_comillas, sep = ""))

  num_registros_f <- dbGetQuery(con, paste("select count(*) from ", tabla, 
    sep = ""))
  
  dbDisconnect(con)
  
  resumen <- data.frame(resumen = c(
    paste0("Número de registros en la tabla original: ", num_registros),
    paste0("Número de registros a eliminar: ", registros_eliminar),
    paste0("Número de registros en la tabla final: ", num_registros_f)
    ))
  
  print("Número de registros en la tabla original:")
  print(num_registros)
  print("Número de registros a eliminar:")
  print(registros_eliminar)
  print("Número de registros en la tabla final:")
  print(num_registros_f)
  
  # Creando rutas para los reportes de eliminación
  dir.create("reportes")

  fecha_actual <- Sys.Date() %>%
    stri_replace_all_fixed("-", "_")

  ruta_carpeta_reportes <- paste0("reportes/", fecha_actual)
  dir.create(ruta_carpeta_reportes)

  ruta_archivo_ids_cgls <- paste0(ruta_carpeta_reportes, "/", fecha_actual, 
    "_ids_cgls_eliminados.csv")
  ruta_archivo_resumen <- paste0(ruta_carpeta_reportes, "/", fecha_actual, 
    "_resumen.csv")

  # Guardando reportes
  write_csv(ids_eliminar, ruta_archivo_ids_cgls)
  write_csv(resumen, ruta_archivo_resumen)
  
  ids_eliminar
}

### Ejemplo
### base Nash
# nombre_borrar <- read.csv("pruebas_nash/nombre_borrar.csv", sep="")
# valores <- as.character(nombre_borrar$nombre)
# 
# resultados <- eliminaRegistros(driver = "SQLite", 
#   path_base = "datos/2015_10_21_conafor20150904.sqlite",
#   tabla = "conglomerado_muestra", 
#   variable = "nombre", valores = valores)

# resultados <- eliminaRegistros(driver = "PostgreSQL", 
#  tabla = "conglomerado_muestra", 
#  variable = "nombre", valores = valores)



