## Revisión e integración de información del SNMB

Pasos a seguir para recibir información (clientes de captura) del SNMB:

1. Fusionar los clientes de captura.
2. Crear reporte de entrega.
3. Fusionar a base final (postgresql).
4. Guardar _media_: grabaciones, imágenes y videos.
5. Crear _shapes_ para navegador.

### 1. Fusionar
Este proceso consta de dos pasos: 

+ Extraer las bases sqlite de los clientes entregados y exportar a csv. Para esto el script de bash *exportar.sh* llama a los scripts de python *exportar.py* y *crear_tablas.py* almacenados en la carpeta *scripts_py*, este paso debe hacerse usando el python de web2py pues se utiliza la aplicación *cliente_web2py*. Las bases exportadas se almacenaran en la carpeta *bases* en formato csv.
+ El segundo paso consiste en fusionar los csv's. Para este paso *exportar.sh* llama al script de python *fusionar_sqlite.py*, que corre en el python de web2py usando los modelos de la aplicación *fusionador_sqlite*. El resultado son dos archivos: *storage.sqlite* y *storage.csv*.

Ejemplo:
```
bash exportar.sh /Volumes/sacmod/FMCN
```
donde el argumento es:
* _dir\_j_: ruta de la carpeta donde se buscarán los clientes a considerar.

El resultado es: 
* base de datos fusionada: bases/storage.sqlite
* archivo csv correspondiente a la anterior: bases/storage.csv

### 2. Reporte de entrega
Genera reportes de entrega para el SNMB, consiste en hacer queries a la base de datos local (sqlite) y crear tablas para identificar si se llenaron todas las pestañas del cliente y el volumen de información capturada. 

+ *crear_reporte.R* llama a *revision_gral.Rmd* que crea un reporte en _pdf_ y a *revision_gral_word.Rmd* que crea un reporte análogo en formato _.docx_.

Se corre el script *crear_reporte.R* desde la terminal. Por ejemplo:
```
> Rscript crear_reporte.R 'FMCN' '../1_exportar_sqlite'
```
donde los argumentos son:
* _entrega_: nombre del directorio donde se guardará el análisis
* _dir\_j_: ruta de la carpeta donde se buscará la base de datos a revisar

El resultado es:
* copia base de datos: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.sqlite
* copia csv: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.csv
* reporte pdf: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.pdf
* copia en word: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.docx

### 3. Fusionar en la base de datos final
Utilizar el archivo csv correspondiente a una base de datos fusionada sqlite (creado en el paso 1), para integrar su información a la base de datos final (postgres). Para poder realizar éste paso, es necesario hacer lo siguiente:

1. [Instalar PostgreSQL con ayuda de Homebrew](https://marcinkubala.wordpress.com/2013/11/11/postgresql-on-os-x-mavericks/).
2. Instalar la librería de Python [psycopg2](http://initd.org/psycopg/):
```
> pip install psycopg2
```
3. [Descargar una versión de Web2py en código fuente](http://www.web2py.com/init/default/download)

### Carpetas y Archivos
La estructura de archivos y carpetas es como sigue.

```
integracion_snmb
│   README.md
├───web2py** |...|   cliente_web2py
│   │            |   fusionador_sqlite
|   |            |   fusionador_postgres
└───1_exportar_sqlite
|   │   exportar.sh
|   ├───scripts_py
|   │   |   crear_tablas.py
|   │   |   exportar.py
|   │   |   fusionar_sqlite.py
|   ├───bases*
|   │   |   snmb_0.csv
|   │   |   snmb_1.csv
|   │   |   ...
|   │   |   storage.sqlite
|   |   |   storage.csv
└───2_crear_reportes
|   │   crear_reporte.R
|   │   revision_gral.Rmd
|   │   revision_gral_word.Rmd
|   ├───reportes*
|   |   ├───aaaa_mm_dd_TITULO
|   |   |   |   aaaa_mm_dd_TITULO.csv
|   |   |   |   aaaa_mm_dd_TITULO.sqlite
|   |   |   |   aaaa_mm_dd_TITULO.docx
|   |   |   |   aaaa_mm_dd_TITULO.pdf
└───3_fusionar_postgres
|   |   fusionar.sh
|   ├───scripts_py
|   │   |   fusionar_postgres.py
└───5_crear_shapes
|   │   crear_shape.R
|   │   ├───mallaSiNaMBioD
|   │   ├───shapes*
|   |   |   ├───aaaa_NOMBRE
|   |   |   |   |   aaaa_NOMBRE.dbf
|   |   |   |   |   aaaa_NOMBRE.prj
|   |   |   |   |   aaaa_NOMBRE.shp
|   |   |   |   |   aaaa_NOMBRE.shx

```
\*La carpeta *bases* y sus contenidos se generan al correr el script *exportar.sh*, de manera similar las carpetas *reportes* y *shapes* (con sus contenidos) se generan con el script *crear_reportes.R* y *crear_shape.R* respectivamente.    
\*\*La carpeta *web2py* corresponde a una carpeta de _código fuente_ de [Web2py](http://www.web2py.com/init/default/download), por lo que se debe agregar manualmente. Dentro de esta se guardan las aplicaciones del [fusionador](https://github.com/fpardourrutia/fusionador) y del [cliente](https://github.com/tereom/cliente_web2py). Estas aplicaciones deben llamarse *fusionador_sqlite*, *fusionador_postgres* y *cliente_web2py* respectivamente.
