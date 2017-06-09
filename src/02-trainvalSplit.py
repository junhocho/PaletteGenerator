import os
import glob
import random
import shutil

import argparse
parser = argparse.ArgumentParser('create image pairs')
parser.add_argument('--dataset_path', dest='dataset_path', help='desired dataset to split train val', type=str, default='./data')
parser.add_argument('--dataset_val_path', dest='dataset_val_path', help='dataset path where to store validation', type=str, default='./dataval')

args = parser.parse_args()
for arg in vars(args):
    print('[%s] = ' % arg,  getattr(args, arg))

dataset_path = args.dataset_path # './data'
dataset_val_path = args.dataset_val_path #'./dataval/'

try:
    os.stat(dataset_val_path)
except:
    os.mkdir(dataset_val_path)

# img_path_iterator = glob.iglob(os.path.join(dataset_path, '*', '*')) # './data/*/*'
img_paths  = glob.glob(os.path.join(dataset_path, '*', '*')) # './data/*/*'
random.shuffle(img_paths)
paths_validation = img_paths[:50]
for (c, img_path) in enumerate(paths_validation):
    tmp = img_path.split('/')
    collection_name = tmp[-2] # Spring
    img_file = tmp[-1] # ColorWander2_150-1.png
    c = c+1
    # Mkdir collection path
    collection_path = os.path.join(dataset_val_path, collection_name)
    try:
        os.stat(collection_path)
    except:
        os.mkdir(collection_path)
    img_val_path = os.path.join(dataset_val_path, collection_name, img_file)

    print(c, img_path,'moved to',img_val_path)

    shutil.move(img_path, img_val_path) #shutil.move("path/to/current/file.foo", "path/to/new/destination/for/file.foo")
