# coding: utf8
import os
import sys

archivo_entrada_ruta = sys.argv[1]
archivo_salida_ruta = sys.argv[2]

# leyendo el archivo donde se encuentran los id's de los conglomerados

archivo_entrada = open(archivo_entrada_ruta, 'r')
lista_ids = list(archivo_entrada)
lista_ids = map(lambda s: int(s.strip()), lista_ids)

# la siguiente función elimina un registro de la tabla Conglomerado_muestra,
# dado el id.

def elimina_registros(x):
	query = db(db.Conglomerado_muestra.id == x)
	registro = query.select(
		db.Conglomerado_muestra.nombre,
		db.Conglomerado_muestra.fecha_visita).first()
	query.delete()
	return str(x) + "," + str(registro.nombre) + "," + str(registro.fecha_visita)

# eliminando registros en lista_ids:

lista_salida = map(elimina_registros, lista_ids)

# creando archivo de salida:
archivo_salida = open(archivo_salida_ruta, 'w')
archivo_salida.write("id,nombre,fecha\n")
for item in lista_salida:
  archivo_salida.write("%s\n" % item)

archivo_entrada.close()
archivo_salida.close()