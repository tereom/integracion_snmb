# coding: utf8
import os
import sys

dir_csv = sys.argv[1]

db.export_to_csv_file(open(os.path.join(os.getcwd(), dir_csv),'w'))
