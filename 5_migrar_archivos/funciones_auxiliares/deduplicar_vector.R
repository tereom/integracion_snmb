library("plyr")
library("dplyr")

# función para deduplicar registros de un vector cualquiera, agregando un
# string "_i" hasta el final, con i un número natural > 2.

# Ésta es útil para el script "9_mapear_rutas_formatos.R", donde los nombres nuevos
# de los archivos que contienen los formatos de campo de determinada entrega, vienen
# dados por el nombre del conglomerado / fecha de muestreo, obtenidas de la base
# (tabla "Conglomerado_carpetas"). Ésto es un problema si más de un formato se
# asocia a un único muestreo, pues los dos formatos distintos tendrán la misma
# ruta destino, causando problemas de sobreescritura de dichos archivos a la hora
# de migrarlos a la estructura de carpetas

#parámetros:
# vec = vector a deduplicar

deduplicarVector <- function(vec){
  
  # creando data frame auxiliar, con el vector y un identificador de la posición
  # en que estaba cada elemento.
  aux <- data_frame(posicion = 1:length(vec), vec)
  
  # agrupando por valor los elementos de vec, calculando el sufijo del nombre
  # para cada grupo, y agrupando de nuevo (las posiciones impiden que se desordene
  # para siempre el vector).
  
  resultado <- ldply(unique(aux$vec), function(x, tabla){
    
    # tabla será aux, y x será un valor (único) que pueden tomar los elementos de vec.
    # la idea es: agrupar a los elementos del vector por valor, para cada subgrupo
    # calcular el número de elementos (renglones) y con un mutate crear el identificador.
    # finalmente, agregar todos. Para que no se revuelvan los elementos (puedan quedar
    # en su orden inicial, antes de todo ponerles un indicador de posición).
    
    tabla %>%
      # agrupando por valor:
      filter(
        vec == x
      ) %>%
      # calculando número de renglones por subgrupo y generando con ésto los nuevos
      # nombres.
      mutate(
        sufijo = 0:(nrow(.)-1)
      ) %>%
      # por el bug del mutate, poner los ifelse cada uno en su mutate.
      mutate(
        # generando los nombres nuevos.
        nombre_nuevo = ifelse(sufijo == 0,
          as.character(vec),
          paste0(vec, "_", sufijo))
      )
  # código del ldply: pasar "aux" como tabla.
  }, tabla = aux) %>%
    # al final, ordenar el resultado del ldply por posición
    arrange(posicion) %>%
    # y extraer el vector con nombres nuevos
    '$'(., "nombre_nuevo")
  
  #regresando el resultado:
  return(resultado)
}

# Advertencias:

# La función no corre para vectores con NA, puesto que filter regresa un df vacío
# y "sufijo" no puede ser calculado

# Ejemplo:
#y <- c(1,2,3,4,1,2,5,2,0,0)
#deduplicarVector(y)
