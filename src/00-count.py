# Download CSV links into `datasetPath`

import csv
import urllib
import os
# urllib.urlretrieve('https://www.design-seeds.com/wp-content/uploads/2016/07/ColorSea6_150.png','ColorSea6_150.png')
# matrix = []

import argparse
parser = argparse.ArgumentParser('create image pairs')
parser.add_argument('--csv', dest='csvfile', help='input csv to download designseeds data', type=str, default='./designseeds-v2.csv')
args = parser.parse_args()
for arg in vars(args):
    print('[%s] = ' % arg,  getattr(args, arg))

csvfile = args.csvfile #'./designseeds-val.csv'


with open(csvfile) as f:
    csvReader = csv.reader(f)
    next(f)

    xxx  = []
    for row in csvReader:
        # matrix.append(row)
        collection_name = row[2]                # "Spring"
        img_url = row[3]                        # "https://www.design-seeds.com/wp-content/uploads/2016/09/ColorWander2_150-1.png"
        img_file = img_url.split('/')[-1]       # "ColorWander2_150-1.png"
        xxx.append(img_file)

print(len(xxx))
print(len(set(xxx)))
print('Thus dataset has same name imgs. rename them with index.')
