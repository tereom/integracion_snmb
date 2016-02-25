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

# En este script, como su nombre lo indica, se mapean los formatos de campo
# cuyas rutas fueron encontradas en "8_encontrar_rutas_formatos.sh" a la estructura
# de carpetas.

# Cabe destacar que éste paso no se separa en dos partes (crear nuevas rutas, y
# mapearlas después), a diferencia de lo que sucede con los otros
# archivos. Ésto debido a que los formularios no están registrados en la base de
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

# El output de este script es el archivo:
# reportes/temp_basename(ruta_entrega)/productos/
# temp_basename(dir_entrega)_9_mapeo_rutas_formatos.csv
# que contiene las rutas origen y destino de los formatos de campo.

