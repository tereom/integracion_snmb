library(dplyr)
library(DBI)
library(RSQLite)
library(RPostgreSQL)

### Observaciones
# 1. Por ahora eliminaRegistros sólo acepta variables de tipo caracter, 
#   extender a todos los tipos es inmediato (incluir if en construcción de 
#   vector_comillas después de reconocer el tipo)
# 2. Esta versión de eliminaMedia solo considera eliminar conglomerados 
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
  
  print("Número de registros en la tabla original:")
  print(num_registros)
  print("Número de registros a eliminar:")
  print(registros_eliminar)
    print("Número de registros en la tabla final:")
  print(num_registros_f)
  
  ids_eliminar
}

### Log
### base Nash
nombre_borrar <- read.csv("pruebas_nash/nombre_borrar.csv", sep="")
valores <- as.character(nombre_borrar$nombre)

ids <- eliminaRegistros(driver = "SQLite", 
  path_base = "datos/2015_10_21_conafor20150904.sqlite",
  tabla = "conglomerado_muestra", 
  variable = "nombre", valores = valores)


