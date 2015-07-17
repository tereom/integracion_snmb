# coding: utf8
import os
import sys

dir_bases = sys.argv[1]
for file in os.listdir(dir_bases):
	if file.endswith(".csv"):
		file_f = os.path.join(dir_bases,file)
		db.import_from_csv_file(open(file_f,'r'))

db.export_to_csv_file(open(os.path.join(os.getcwd(),
	"applications/fusionador_sqlite_v10/databases/storage.csv"),'w'))
