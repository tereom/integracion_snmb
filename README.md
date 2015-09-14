## Revisión e integración de información del SNMB

Pasos a seguir para recibir información (clientes de captura) del SNMB:

1. Fusionar los clientes de captura.
2. Crear reporte de entrega.
3. Eliminar registros duplicados.
4. Migrar esquema: v10 a v12.
5. Fusionar a base final (postgresql).
6. Migrar archivos: grabaciones, imágenes y videos.
7. Crear _shapes_.

### 1. Fusionar
Este proceso consta de dos pasos: 

+ Extraer las bases sqlite de los clientes entregados y exportar a csv. Para esto el script de bash *exportar.sh* llama a los scripts de python *exportar.py* y *crear_tablas.py* almacenados en la carpeta *scripts_py*, este paso utiliza los modelos de la aplicación *cliente_v10* ([cliente_web2py](https://github.com/tereom/cliente_web2py) commit a4c07eb). Las bases exportadas se almacenaran en la carpeta *bases* en formato csv.
+ El segundo paso consiste en fusionar los csv's. Para este paso *exportar.sh* llama al script de python *fusionar_sqlite.py*, que utiliza los modelos de la aplicación *fusionador_sqlite_v10* ([fusionador_snmb](https://github.com/fpardourrutia/fusionador_snmb) rama hotfix). El resultado son dos archivos: *storage.sqlite* y *storage.csv*.

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
Genera reportes de entrega para el SNMB, consiste en hacer queries a la base de datos local (sqlite) y crear tablas para identificar si se llenaron todas las pestañas del cliente y el volumen de información capturada. Además, genera un reporte de conglomerados repetidos. En el caso de existir conglomerados repetidos se debe analizar el reporte de repetidos para decidir como eliminar las copias, una vez que exista un único registro por conglomerado es necesario volver a correr el reporte de entrega.

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
* copia base de datos en formato csv: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.csv
* reporte pdf: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.pdf
* copia en word: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega.docx
* reporte repetidos pdf: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega_rep.docx
* lista de ids correspondientes a repetidos: reportes/aaaa_mm_dd_entrega/aaaa_mm_dd_entrega_rep.txt

### 3. Eliminar duplicados
Una vez que se corre el reporte correspondiente a una base de datos sqlite (esquema v10), si existen duplicados, éstos se deberán eliminar antes de proseguir. Para ello, *deduplicar_v10.sh* llama a *crear_tablas.py* y *eliminar_registros.py*,
script que, haciendo uso de los modelos del *fusionador_sqlite_v10* ([fusionador_snmb](https://github.com/fpardourrutia/fusionador_snmb) rama hotfix), realiza el proceso.

Se corre el script *deduplicar_v10.sh* desde la terminal. Por ejemplo:
```
> bash deduplicar_v10.sh '../1_exportar_sqlite/bases/nombre_base.sqlite' '../archivo.txt'
```

donde los argumentos son:
* _base_ruta_: ruta de la base de datos con registros que se desean eliminar.
* _archivo_ruta_: ruta del archivo que contiene una única columna con las id's de los conglomerados a eliminar, es decir, el archivo contiene las id's de dichos conglomerados separados por saltos de línea. Ejemplo:  
4  
22

El resultado es:
* copia base de datos: bases/nombre_base/nombre_base.sqlite
* copia csv: bases/nombre_base/nombre_base.csv
* archivo csv con la relación de los conglomerados eliminados: bases/nombre_base/nombre_base_eliminados.csv

### 4. Migrar esquema
La base de datos final (postgres) tendrá implementado el esquema de datos más reciente, por ello, antes de fusionar la base sqlite obtenida en el paso 1, se deberá asegurar que esté en dicho esquema, de lo contrario, se deberá realizar una migración.

+ *migrar_v10_v12.sh* llama a *migrar_v10_v12.R*, que a su vez llama a *etl_v10_v12.Rmd* y es el encargado de migrar una base de datos a la versión final (ambas sqlite).
+ después de eso, *migrar_v10_v12.sh* llama a *crear_tablas.py* y *crear_csv.py* para exportar la nueva base de datos _sqlite_ a formato _csv_. Para ésto utiliza los modelos de la aplicación de Web2py: *fusionador_sqlite_v12* (commit bacfe4b).

Se corre el script *migrar_v10_v12.sh* desde la terminal. Por ejemplo:
```
> bash migrar_v10_v12.sh '../1_exportar_sqlite/bases/nombre_base.sqlite' 'FMCN'
```
donde los argumentos son:
* _base_ruta_: ruta a la base de datos a migrar de esquema.
* _institucion_: institución que entregó los datos.

El resultado es:
* migración de la base de datos al esquema más reciente: migraciones/nombre_base_v10_v12/nombre_base_v10_v12.sqlite
* la base de datos anterior en formato csv:
migraciones/nombre_base_v10_v12/nombre_base_v10_v12.csv

### 5. Fusionar en la base de datos final
Utilizar el archivo csv correspondiente a una base de datos fusionada sqlite (creado en el paso 1 ó 3), para integrar su información a la base de datos final (postgres). Adicionalmente, después de cada fusión, crea una copia sqlite de la base postgres (la cuál contendrá la información más reciente). Cabe destacar que no se lleva un registro de estas copias, sino que se borrarán las antiguas.

#### Requerimientos previos
Para poder realizar éste paso, es necesario hacer lo siguiente:

* [Instalar PostgreSQL con ayuda de Homebrew](https://marcinkubala.wordpress.com/2013/11/11/postgresql-on-os-x-mavericks/).
* Instalar la librería de Python [psycopg2](http://initd.org/psycopg/):
```
> pip install psycopg2
```
* [Descargar una versión de Web2py en código fuente](http://www.web2py.com/init/default/download), ésto debido a que se deberá
utilizar el python local para correr Web2py, pues es el que tiene instalado psycopg2.
* [Descargar una aplicación del fusionador (commit 7cc098c)](https://github.com/fpardourrutia/fusionador) y guardarla en la carpeta de *applications* dentro de Web2py. Cambiarle el nombre de *fusionador_snmb* a *fusionador_postgres_v12*.
* Abrir la terminal para crear la base de datos postgres:
```
> cd /usr/local/var
> #creando la base de datos:
> initdb nombre_base
> #encendiendo el servidor
> postgres -D postgres
> #registrándola adecuadamente
> createdb nombre_base
```
* Abrir el archivo: *fusionador_postgres/models/00_0_db_f.py*, y revisar que la siguiente línea esté correcta:
```
db = DAL('postgres://usuario:contrasena@localhost/nombre_base', db_codec='UTF-8',check_reserved=['all'], migrate = True)
```
Nota: `migrate = False` se utiliza para bases de datos preexistentes (por ejemplo, que hayan sido pobladas mediante algún ETL,
antes de utilizarlas de esta manera.

#### Uso

+ *fusionar.sh* llama al script de python *fusionar_postgres.py*, que corre utilizando los modelos de la aplicación *fusionador_postgres_v12*, para guardar la información en la base de datos.
+ Después de lo anterior, *fusionar.py* exportará la base postgres a csv, con ayuda del script *crear_csv.py*, para finalmente crear la imagen sqlite con ayuda de los scripts: *crear_tablas.py* y *fusionar_sqlite.py*, utilizando la app de web2py: *fusionador_sqlite_v12*. 

Para correr este script desde la terminal:
+ Encender el servidor postgres:
```
> postgres -D /usr/local/var/postgres
```
+ Correr el script:

```
> bash fusionar.sh ../1_exportar_sqlite/bases/storage.csv 
```
donde el argumento es:
* _csv_ruta_: path del csv a fusionar.

el resultado es:
* incorporación de la información en el archivo csv a la base de datos postgres.
* exportación de la base postgres más reciente a formato sqlite:  
imagen/aaaa_mm_dd.sqlite

### 6. Migrar archivos
Ya que tenemos la base local en el esquema más reciente, lo siguiente es utilizar los registros de archivos que contiene para encontrarlos en la estructura de carpetas, y mapearlos a una estructura prediseñada.

La estructura prediseñada es la siguiente:

```
nombre_entrega
├───conglomerado_anio 
|   |   formato_campo.pdf
|   ├───fotos_videos
|   ├───grabaciones_audibles
|   ├───grabaciones_ultrasonicas
|   ├───especies_invasoras
|   ├───huellas_excretas
|   ├───registros_extra
|   ├───referencias
|   ├───otros
...
├───aaaa_mm_dd_no_reg (archivos no registrados en la base)
|   ├───fotos_videos
|   ├───audio
|   ├───archivos_pdf
```

Como los formatos de campo no se encuentran registrados en el cliente de captura, se tienen dos supuestos adicionales: 

1. Los formatos se encuentran en una ruta que contiene la palabra “formatos” (no importando mayúsculas ni minúsculas).
2. Los formatos tienen un nombre de la forma: "0*num_conglomerado[_fecha]?[otra_cosa]?.pdf"

Se corre el script *migrar_archivos.R* desde la terminal. Por ejemplo:
```
> Rscript migrar_archivos.R 'archivos_snmb' '/Volumes/sacmod' '../4_migrar_esquema/migraciones/prueba/base.sqlite' '../../clientes'
```
donde los argumentos son:
* _nombre_entrega_: nombre de la carpeta donde se guardarán los datos.
* _ruta_entrega_: directorio donde se quiere colocar la carpeta con los datos (puede ya existir la carpeta).
* _base_: ruta de la base de datos a utilizar.
* _dir\_j_: ruta de la carpeta donde se encuentran los clientes de captura.

El resultado es:
* Creación de la estructura de archivos con el contenido de los clientes de captura, de acuerdo a lo especificado por la base de datos.
* En caso de ser necesario, archivo csv que contiene la información (conglomerado, nombre y ruta), de archivos que no se pudieron migrar: reportes/nombre_base/nombre_base_fallidos.csv.
* En caso de ser necesario, archivo csv que contiene una lista de conglomerados con formato no encontrado: reportes/nombre_base/nombre_base_sin_formato.csv

### 7. Crear shapes
El objetivo es crear archivos shape de puntos, donde cada punto corresponde a un conglomerado que tiene asociada información como: número de sitios, número de archivos de audio, número de fotos con fauna,...  
La sección de shapes tiene dos scripts: 

* _crear\_shape.R_ crea una carpeta con los shapes correspondientes para cada combinación de institución y año. El script lee la información de una base sqlite. Adicionalmente guarda un Rdata para cada institucion donde se almacena un data frame con las coordenadas de cada conglomerado (obtenidas de la nformación capturada) y con el resumen de la información del mismo.
* _prueba\_ggvis.Rmd_ crea un html con la información de los shapes en un mapa de googlemaps.

Se corre el script crear_reporte.R desde la terminal. Por ejemplo:

```
> Rscript crear_shape.R '.'
```
donde el argumento es el directorio donde se debe buscar la base de datos (en el ejemplo es la misma carpeta '.').

### Carpetas y Archivos
La estructura de archivos y carpetas es como sigue.

```
integracion_snmb
│   README.md
├───web2py** 
|   ├───applications
|   |   |   cliente_v10
│   │   |   fusionador_sqlite_v10
|   |   |   fusionador_sqlite_v12
|   |   |   fusionador_postgres_v12
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
|   |   revision_repetidos.Rmd
|   ├───reportes*
|   |   ├───aaaa_mm_dd_TITULO
|   |   |   |   aaaa_mm_dd_TITULO.csv
|   |   |   |   aaaa_mm_dd_TITULO.sqlite
|   |   |   |   aaaa_mm_dd_TITULO.docx
|   |   |   |   aaaa_mm_dd_TITULO.pdf
|   |   |   |   aaaa_mm_dd_TITULO_rep.pdf
|   |   |   |   aaaa_mm_dd_TITULO_rep.txt
└───3_eliminar_duplicados
|   |   deduplicar_v10.sh
|   ├───scripts_py
|   |   |   crear_tablas.py
|   |   |   eliminar_registros.py
|   |   |   crear_csv.py
|   ├───bases*
|   |   ├───nombre_base
|   |   |   |   nombre_base.sqlite
|   |   |   |   nombre_base.csv
|   |   |   |   nombre_base_eliminados.csv
└───4_migrar_esquema
|   |   migrar_v10_v12.sh
|   ├───scripts
|   |   |   migrar_v10_v12.R
|   |   |   etl_v10_v12.R
|   |   |   crear_tablas.py
|   |   |   crear_csv.py
|   ├───aux**
|   |   |   output_vacio
|   ├───migraciones*
|   |   ├──nombre_base_v10_v12
|   |   |   |   nombre_base_v10_v12.sqlite
|   |   |   |   nombre_base_v10_v12.csv
└───5_fusionar_postgres
|   |   fusionar.sh
|   ├───scripts_py
|   │   |   fusionar_postgres.py
|   |   |   crear_csv.py
|   |   |   crear_tablas.py
|   |   |   fusionar_sqlite.py***
|   ├───imagen*
|   |   |   aaaa_mm_dd.sqlite
└───7_crear_shapes
|   │   crear_shape.R
|   |   prueba_ggvis.Rmd
|   │   ├───salidas**
|   |   |   aaaa_institucion1.Rdata
|   |   |   aaaa_institucion2.Rdata
|   │   ├───shapes*
|   |   |   ├───aaaa_NOMBRE
|   |   |   |   |   aaaa_NOMBRE.dbf
|   |   |   |   |   aaaa_NOMBRE.prj
|   |   |   |   |   aaaa_NOMBRE.shp
|   |   |   |   |   aaaa_NOMBRE.shx
```
\*La carpeta *bases* y sus contenidos se generan al correr el script *exportar.sh*, de manera similar las carpetas *reportes*, *bases*, *migraciones*, *imagen* y *shapes* (con sus contenidos) se generan con los scripts *crear_reportes.R*, *deduplicar_v10.sh*, *migrar_v10_v12.sh*, *fusionar.sh* y *crear_shape.R* respectivamente.  
\*\*La carpeta *web2py* corresponde a una carpeta de _código fuente_ de [Web2py](http://www.web2py.com/init/default/download), por lo que se debe agregar manualmente. Dentro de esta se guardan las respectivas aplicaciones del [fusionador](https://github.com/fpardourrutia/fusionador) y del [cliente](https://github.com/tereom/cliente_web2py), en sus versiones correspondientes. Estas aplicaciones deben llamarse *fusionador_sqlite_v10*, *fusionador_sqlite_v12*, *fusionador_postgres_v12* y *cliente_v10* respectivamente.  
\*\*La carpeta *aux* se agrega manualmente y contiene una base sqlite vacía creada al iniciar el *fusionador_sqlite_v12*.  
\*\*La carpeta *mallaSiNaMBioD* se agrega manualmente y contiene los shapes de la malla del SNMB.  

