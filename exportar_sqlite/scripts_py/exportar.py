# coding: utf8
import os

# exportar a directorio de bases
db.export_to_csv_file(open(os.path.join(os.getcwd(),
	"applications/cliente_web2py/databases/snmb.csv"),'w'))
