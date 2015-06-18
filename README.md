Pasos a seguir para recibir información (clientes de captura) del SNAMB
1. Fusionar los clientes de captura.
2. Crear reporte de entrega
3. Fusionar a base fnal (postgresql)

## 1. Fusionar
Este proceso consta de dos pasos: 
a. Extraer las bases sqlite de los clientes entregados y exportar a csv, este paso debe hacerse usando el python de web2py y cargando los modelos del cliente. Para esto se utilzan los scripts de la carpeta *exportar_csv*, y se corre el bash exportar.sh indicando el directorio que contiene los clientes a exportar, por ejemplo:
```
bash exportar.sh ~/Documents/SNMB/revision_snmb
```
Las bases exportadas se almacenaran en la carpeta *bases* en formato csv.

b. Fusionar los archivos csv y crear una nueva base sqlite.


# Reportes_SNMB

Genera reportes de entrega para el SNMB, consiste en generar queries a la base de datos local (sqlite) y generar tablas para identificar si se llenaron todas las pestañas del cliente y el volumen de información capturada.

### Ejemplo: 
Se corre el script crear_reporte.R desde la terminal:
```
> Rscript crear_reporte.R 'FMCN' 'bases_prueba' '\.sqlite'
```
donde los argumentos son:
* _entrega_: nombre del directorio donde se guardará el análisis
* _dir\_j_: ruta de la carpeta donde se buscará la base de datos a revisar
* _pattern_db_: regex que identifica las bases de datos a considerar

El resultado es:
* copia base de datos: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.db
* reporte pdf: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.pdf
* copia en word: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.docx

Funcionamiento:

**crear_reporte.R** genera variables de la entrega y llama a **revision_gral.Rmd** que crea el _pdf_ y a **revision_gral_word.Rmd** que crea un reporte análogo en formato _.docx_.
