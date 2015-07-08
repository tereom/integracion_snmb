import os
import sys

csv_ruta = sys.argv[1]
db.import_from_csv_file(open(csv_ruta,'r'))