import os
import sys

dir_bases = sys.argv[1]
for file in os.listdir(dir_bases):
	if file.endswith(".csv"):
		file_f = os.path.join(dir_bases,file)
		db.import_from_csv_file(open(file_f,'r'))
