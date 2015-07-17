# coding: utf8
import os
import sys

dir_base = sys.argv[1]

db.export_to_csv_file(open(os.path.join(os.getcwd(),
	"applications/fusionador_sqlite_v12/databases/storage.csv"),'w'))
