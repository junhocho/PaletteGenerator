# Split hueSplit data into img and palette.
# We split based on calculate on `dataset_path` because png images are original and hueShifted jpg images are lower quality

import numpy as np
import matplotlib.pyplot as plt
import matplotlib.image as mpimg
import os
import csv
import json
import glob

from skimage import io, color, img_as_ubyte, img_as_float
# img_file = '11_3_FloraHues_charleighmims_Catherine.png'#
# img_file = 'ColorSea6_150.png'

import argparse
parser = argparse.ArgumentParser('create image pairs')
parser.add_argument('--dataset_path', dest='dataset_path', help='desired dataset to split', type=str, default='./dataval')
#parser.add_argument('--dataset_hueshift_path', dest='dataset_hueshift_path', help='hueShifted dataset', type=str, default='./dataval-hueShift/')
parser.add_argument('--dataset_preproc_path', dest='dataset_preproc_path', help='desired dataset to split', type=str, default='./dataval-preproc')

args = parser.parse_args()
for arg in vars(args):
    print('[%s] = ' % arg,  getattr(args, arg))

dataset_path = args.dataset_path  #'./data' # .png
#dataset_hueshift_path =  args.dataset_hueshift_path  #'./data-hueShift_keepL'  # As hueshift
dataset_preproc_path = args.dataset_preproc_path # './data-preproc'



# Logging not really needed python `python -u script.py` option
# import logging
# LOG_FILENAME = 'preprocess.log'
# logging.basicConfig(filename=LOG_FILENAME,level=logging.DEBUG)

# ================ Fucntions =====

# Input : palette of 6 color and output ordered in AB or Saturation
def reorder_by_ab_sat(palette, vis = True):
    x = np.stack(palette, 0)
    x = x.reshape(1,6,3)
#     print x.shape
    x_lab = color.rgb2lab(x)
    x_hsv = color.rgb2hsv(x)
#     print x_lab
#     print x_hsv

    abs_ab = []
    sat = []

    for i in range(6):
        abs_ab.append(pow(x_lab[0][i][1],2) + pow(x_lab[0][i][2],2))
        sat.append(x_hsv[0][i][1])

    order_abs_ab = sorted(range(len(abs_ab)), key=lambda k: abs_ab[k])
    order_sat = sorted(range(len(sat)), key=lambda k: sat[k])

    ab_ordered = [ palette[i] for i in order_abs_ab]
    sat_ordered = [ palette[i] for i in order_sat]

    if vis:
        fig = plt.figure()
        for i in range(6):
            fig.add_subplot(1,6,i+1)
            p = np.tile(ab_ordered[i], (10,10,1))
            plt.imshow(p)

        fig = plt.figure()
        for i in range(6):
            fig.add_subplot(1,6,i+1)
            p = np.tile(sat_ordered[i], (10,10,1))
            plt.imshow(p)
    return ab_ordered, sat_ordered

def decideSplit(img_path, vis = False):

    img = mpimg.imread(img_path)
    if img_path.endswith('.jpg'):
        img = img_as_float(img)
    cropfail = False
    # import matplotlib.pyplot as plt

    rgb = 1-img[:,:,:]
    r, g, b = rgb[:,:,0], rgb[:,:,1], rgb[:,:,2]

    g = r+g+b
    h = img.shape[0]
    w = img.shape[1]
    if vis:
        plt.figure()

#         print(r.sum(0))
#         plt.figure()
        plt.plot(g.sum(0), label = 'x')
#         print(r.sum(1))
        plt.plot(g.sum(1), label = 'y')
        plt.legend()
        plt.imshow(img)
        plt.show()
        print(img.shape)
        print('g', np.where(g.sum(1)==g.sum(1).min()), g.sum(1).min())
        print('g', np.where(g.sum(0)==g.sum(0).min()), g.sum(0).min())
#     print(np.where(b.sum(1)==b.sum(1).min()), b.sum(1).min())
#     print(np.where(g.sum(1)==g.sum(1).min()), g.sum(1).min())
#     print(r.sum(1)[800:814])
#     print(r[:,800:814])
#     print(r[800:814,:].shape)
#     print(r.sum(1)[795-1:814+1]/img.shape[0])

#     print(r.sum(0).size, img.shape[1])



#     r = r[h/4:h*3/4, w/4:w*3/4]
        print 'img.shape:', img.shape # 'r.shape:', r.shape
#     print h,w, r.shape[0], r.shape[1], r[:,0].shape


    x_blank = np.where(g.sum(0)==g.sum(0).min())[0]   # VSP
    x_border_indices = np.where(x_blank < w/2 ) # Check those close to Left of half to exclude
    x_blank = np.delete(x_blank, x_border_indices) # and delete them

    y_blank = np.where(g.sum(1)==g.sum(1).min())[0]  # HSP
    y_border_indices = np.where(y_blank < h/2 ) # Close to Top
    y_blank = np.delete(y_blank, y_border_indices)

    if vis:
        print('x_blank', x_blank)
        print('y_blank', y_blank)

    #  because 588th image, Flora/PetaledHues2_150.png  has zeros at right bord. x_blank != []:
    #if len(x_blank) > len(y_blank):
    if y_blank.size == 0:
        return x_blank, 'Vertical'
    elif x_blank.size == 0:
        return y_blank, 'Horizontal'
    elif g.sum(0)[x_blank[0]] < g.sum(1)[y_blank[0]]:
        return x_blank, 'Vertical'
    else:
        return y_blank, 'Horizontal'

def splitImg(img_path, split_band, orientation, vis=False):
    img = mpimg.imread(img_path)
    if img_path.endswith('.jpg'):
        img = img_as_float(img)
    cropfail = False

    if orientation == 'Vertical':
#         print('Vertical')
        img_crop = img[:,:split_band[0],:] # img on left
        pre_color = img[:,split_band[-1]+10,:]
    elif orientation == 'Horizontal':
#         print('Horizontal')
        img_crop = img[:split_band[0],:,:] # img on top
        pre_color = img[split_band[-1]+10,:,:]

    if vis:
        plt.figure()
        plt.imshow(img_crop)
        plt.show()
    if img_crop.size < img.size/2:
        cropfail = True #error('img_crop cannot be smaller than half of img')

    color_palette = {}
    color_palette_npy = np.array([])
    bs = len(pre_color)/6
    for i in range(6):
        ind = bs*i+bs/2
        color = pre_color[ind]
        # color_json = {'r': str(color[0]), 'g': str(color[1]), 'b': str(color[2])}
        # color_palette[i+1] = color_json
        color_palette_npy = np.append(color_palette_npy, [color[0], color[1], color[2]])
        # print(color)
    return img_crop, color_palette_npy, cropfail

# ================= MAIN

# Use glob module
print("data2img-palette.py  running")
vis_color = False
vis = False # Plot split

data_json = {}


try:
    os.stat(dataset_preproc_path)
except:
    os.mkdir(dataset_preproc_path)


img_path_iterator = glob.iglob(os.path.join(dataset_path, '*/*.*')) # ignore jpg. Palette extraction doesn't work


# Wrong split images
wrong_split_path = ['FloraTones6_150-1']
debug_split = False
#['PetaledHues2_150-1', 'FloraHues2_150-5' , 'FloraHues1_150-4', 'FloraHues1_150-1', 'FloraDream_150-1' , 'AutumnFloraH1a','RusticTones_150-1']

c = 1
for (i, img_path) in enumerate(img_path_iterator, 1):
    path_split = img_path.split('/')
    collection_name = path_split[-2]  # Summer
    img_file = path_split[-1] # 'ColorHoliday5_150.jpg'
    basename, ext = os.path.splitext(img_path) #'./data/Summer/ColorHoliday5_150' , '.jpg'
    img_name = basename.split('/')[-1] # ColorHoliday5_150

    # DEBUGGING specific imgs
    if debug_split and img_name not in wrong_split_path:
        continue
    else:
        #assert(c == (i-1)*18+1)
        print(i, c, 'original', img_path) # 1, './data/Summer/ColorHoliday5_150.jpg'
        #logging.debug('%d %d original %s', i, c, img_path)

    # Input should be float. jpg : uint8, png: float.
    img = mpimg.imread(img_path)
    if img_file.endswith('.jpg'):
        img = img_as_float(img)
    cropfail = False
    # import matplotlib.pyplot as plt


    split_band , orientation = decideSplit(img_path, vis) # Calculate split with original ./data/*/*.*


    # img_hueshift_path_iterator = glob.iglob(os.path.join(dataset_hueshift_path, collection_name, img_name + '_hue_*'))
    #'./data-hueShift_keepL/Summer/ColorHoliday5_150_hue*'
    #'./data-hueShift_keepL/Summer/ColorHoliday5_150_hue_keepL+100.jpg
    #'./data-hueShift_keepL/Summer/ColorHoliday5_150_hue_keepL.jpg'

    # for img_hueShift_path in  img_hueshift_path_iterator:        #print(img_hueShift_path)
    #     path_split = img_hueShift_path.split('/')
    #     img_file = path_split[-1] # Redefine img_file as each hueShifted

    img_preproc, color_palette_npy, cropfail = splitImg(img_path, split_band, orientation, vis)
    #img_preproc, color_palette, cropfail = preprocess(img_path, vis = True)


    if cropfail:
        print("Will not use preprocess " + img_path)
        continue


    # if vis_color:
    #     plt.figure()
    #     plt.imshow(img_preproc)
    #     plt.show()
    # #             print(color_palette)
    # color_check=[]
    # for i in range(1,7):
    # #             print(color_palette[i]['r'])
    # #             print float(color_palette[i]['g'])
    #     color_check.append(np.array([float(color_palette[i]['r']),
    #                     float(color_palette[i]['g']),
    #                     float(color_palette[i]['b'])], dtype='f'))
    # #         print color_check
    # #         p1 = np.ones((100,100,3), dtype='f')
    # #         p1 * color_check[1]
    # if vis_color:
    #     fig = plt.figure()
    # for j in range(6):
    #     p = np.tile(color_check[j], (10,10,1))
    #     if vis_color:
    #         fig.add_subplot(1,6,j+1)
    #         plt.imshow(p)
    # if vis_color:
    #     print(color_check)
    #     plt.show()

    #     t = reorder_by_ab_sat(color_check, True)

    save_path = os.path.join(dataset_preproc_path, collection_name, img_file)
    collection_path = os.path.join(dataset_preproc_path, collection_name)
    try:
        os.stat(collection_path)
    except:
        os.mkdir(collection_path)
    mpimg.imsave(save_path, img_preproc)
    np.save(save_path[:-3]+'npy', color_palette_npy)

    #hueshift = img_file.split('.')[-2].split('+')[-1] # 0 , 20 , 40 , ... 340
    #data_json[c] = {'img_path': os.path.join(collection_name, img_file), 'color_palette' : color_palette}
    c = c + 1

#with open(os.path.join(dataset_preproc_path,'color_palette.json'), 'w') as outfile:
#    json.dump(data_json, outfile)
