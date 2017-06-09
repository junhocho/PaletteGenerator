# Download CSV links into `datasetPath`

import csv
import urllib
import os
# urllib.urlretrieve('https://www.design-seeds.com/wp-content/uploads/2016/07/ColorSea6_150.png','ColorSea6_150.png')
# matrix = []

import argparse
parser = argparse.ArgumentParser('create image pairs')
parser.add_argument('--csv', dest='csvfile', help='input csv to download designseeds data', type=str, default='./designseeds-val.csv')
parser.add_argument('--dataset_path', dest='datasetPath', help='desired dataset path to download', type=str, default='./dataval')
args = parser.parse_args()
for arg in vars(args):
    print('[%s] = ' % arg,  getattr(args, arg))

datasetPath = args.datasetPath  #'./dataval'
csvfile = args.csvfile #'./designseeds-val.csv'

try:
    os.stat(datasetPath)
except:
    os.mkdir(datasetPath)

with open(csvfile) as f:
    csvReader = csv.reader(f)
    next(f)
    c = 1
    for row in csvReader:
        # matrix.append(row)
        collection_name = row[2]                # "Spring"
        img_url = row[3]                        # "https://www.design-seeds.com/wp-content/uploads/2016/09/ColorWander2_150-1.png"
        img_file = img_url.split('/')[-1]       # "ColorWander2_150-1.png"
        save_path = os.path.join(datasetPath,collection_name, str(c)+'-'+img_file)     # "Spring/ColorWander2_150-1.png"

        try:
            os.stat(os.path.join(datasetPath,collection_name))
        except:
            os.mkdir(os.path.join(datasetPath,collection_name))
        print(save_path)
        urllib.urlretrieve(img_url, save_path)
        c = c + 1
