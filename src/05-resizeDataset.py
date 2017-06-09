import glob
import os
import Image

from shutil import copyfile

import argparse
parser = argparse.ArgumentParser('create image pairs')
parser.add_argument('--dataset_path', dest='dataset_path', help='desired dataset resize', type=str, default='./dataval-preproc')
parser.add_argument('--dataset_resize_path', dest='dataset_resize_path', help='dataset path of resize', type=str, default='./dataval-preproc-288x432')
parser.add_argument('--base', dest='base', help='desired base width or heigt', type=int, default=288)
parser.add_argument('--ratio', dest='ratio', help='desired ratio of width and heigt', type=float, default=1.5)

args = parser.parse_args()
for arg in vars(args):
    print('[%s] = ' % arg,  getattr(args, arg))


# MAIN
print('Resize Dataset -------------------------------')
dataset_path = args.dataset_path  #'./data-preproc/'
save_dataset_path = args.dataset_resize_path  # './data-preproc-288x432/'
base = args.base #288
ratio = args.ratio # 1.5  # makes 450
base_other = int(base*ratio)

try:
    os.stat(save_dataset_path)
except:
    os.mkdir(save_dataset_path)

#copyfile(os.path.join(dataset_path, 'color_palette.json'), os.path.join(save_dataset_path, 'color_palette.json'))

img_path_iterator = glob.iglob(os.path.join(dataset_path, '*', '*.png')) # './data/*/*'
for (c, img_path) in enumerate(img_path_iterator):
    tmp = img_path.split('/')
    collection_name = tmp[-2] # Spring
    img_file = tmp[-1] # ColorWander2_150-1.png
    c = c+1
    # Mkdir collection path
    collection_path = os.path.join(save_dataset_path, collection_name)
    try:
        os.stat(collection_path)
    except:
        os.mkdir(collection_path)

    print(c, img_path)
    basename, ext = os.path.splitext(img_path)
    #img = Image.open(img_path).convert('RGB')
    outbasename = os.path.join(save_dataset_path, collection_name ,basename.split('/')[-1])
    # hueShift_KeepL_Step(img, outbasename, np.linspace(0, 360, 19)[1:-1])
    img = Image.open(img_path)
    if img.size[0] > img.size[1]: # h > w
        h = base_other
        w = base
    else: # h < w
        h = base
        w = base_other
    img = img.resize((h,w), Image.ANTIALIAS)
    img.save(outbasename + '.jpg')


