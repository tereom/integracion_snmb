# coding: utf8
import os
import sys

reload(sys)
sys.setdefaultencoding("utf-8")

csv_ruta = sys.argv[1]
db.import_from_csv_file(open(csv_ruta,'r'))