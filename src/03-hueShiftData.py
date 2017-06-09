import os
import Image
import numpy as np
import glob

import json

import argparse
parser = argparse.ArgumentParser('create image pairs')
parser.add_argument('--paletteset_path', dest='paletteset_path', help='palette stored preproc path', type=str, default='./dataval')
parser.add_argument('--dataset_path', dest='dataset_path', help='desired dataset to shift hue', type=str, default='./dataval')
parser.add_argument('--dataset_hueshift_path', dest='dataset_hueshift_path', help='dataset path where to store hue shifted', type=str, default='./dataval-hueShift_KeepL/')

args = parser.parse_args()
for arg in vars(args):
    print('[%s] = ' % arg,  getattr(args, arg))

paletteset_path = args.paletteset_path
dataset_path = args.dataset_path # './data'
save_dataset_path = args.dataset_hueshift_path #'./data-hueShift_keepL/'

from skimage import io, color, img_as_ubyte, img_as_float
import matplotlib.pyplot as plt

def rgb_to_hsv(rgb):
    # Translated from source of colorsys.rgb_to_hsv
    # r,g,b should be a numpy arrays with values between 0 and 255
    # rgb_to_hsv returns an array of floats between 0.0 and 1.0.
    rgb = rgb.astype('float')
    hsv = np.zeros_like(rgb)
    # in case an RGBA array was passed, just copy the A channel
    hsv[..., 3:] = rgb[..., 3:]
    r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
    maxc = np.max(rgb[..., :3], axis=-1)
    minc = np.min(rgb[..., :3], axis=-1)
    hsv[..., 2] = maxc
    mask = maxc != minc
    hsv[mask, 1] = (maxc - minc)[mask] / maxc[mask]
    rc = np.zeros_like(r)
    gc = np.zeros_like(g)
    bc = np.zeros_like(b)
    rc[mask] = (maxc - r)[mask] / (maxc - minc)[mask]
    gc[mask] = (maxc - g)[mask] / (maxc - minc)[mask]
    bc[mask] = (maxc - b)[mask] / (maxc - minc)[mask]
    hsv[..., 0] = np.select(
        [r == maxc, g == maxc], [bc - gc, 2.0 + rc - bc], default=4.0 + gc - rc)
    hsv[..., 0] = (hsv[..., 0] / 6.0) % 1.0
    return hsv

def hsv_to_rgb(hsv):
    # Translated from source of colorsys.hsv_to_rgb
    # h,s should be a numpy arrays with values between 0.0 and 1.0
    # v should be a numpy array with values between 0.0 and 255.0
    # hsv_to_rgb returns an array of uints between 0 and 255.
    rgb = np.empty_like(hsv)
    rgb[..., 3:] = hsv[..., 3:]
    h, s, v = hsv[..., 0], hsv[..., 1], hsv[..., 2]
    i = (h * 6.0).astype('uint8')
    f = (h * 6.0) - i
    p = v * (1.0 - s)
    q = v * (1.0 - s * f)
    t = v * (1.0 - s * (1.0 - f))
    i = i % 6
    conditions = [s == 0.0, i == 1, i == 2, i == 3, i == 4, i == 5]
    rgb[..., 0] = np.select(conditions, [v, q, p, p, t, v], default=v)
    rgb[..., 1] = np.select(conditions, [v, v, v, q, p, p], default=t)
    rgb[..., 2] = np.select(conditions, [v, p, t, v, v, q], default=p)
    return rgb.astype('uint8')

def rgb_to_lab(rgb):
    lab = color.rgb2lab(rgb)
    return lab # L: 0~100

def lab_to_rgb(lab):
    #print lab
    rgb = color.lab2rgb(lab)
    #print('rgb====', rgb)
    #print(rgb.min(), rgb.max())

    rgb = np.clip(rgb, 0, 1)
    rgb = img_as_ubyte(rgb)
    #print rgb
    return rgb

def hueChange(img, hue):
    arr = np.array(img)
    hsv = rgb_to_hsv(arr)
    hsv[..., 0] = hue
    rgb = hsv_to_rgb(hsv)
    return Image.fromarray(rgb, 'RGB')

def hueShift(img, amount):
    arr = np.array(img)
    hsv = rgb_to_hsv(arr)
    hsv[..., 0] = (hsv[..., 0]+amount) % 1.0
    rgb = hsv_to_rgb(hsv)
    return Image.fromarray(rgb, 'RGB')

# ====== jhcho

def SwapL(rgb, L_desired):
    LAB = rgb_to_lab(rgb)
    LAB[..., 0] = L_desired
    #print(LAB)
    RGB = lab_to_rgb(LAB)
    return RGB, LAB

def hueShift_KeepL(img, amount, L_desired): # Not using in multi hueshift of single image. Used in one-time hueshift
    arr = np.array(img)
    hsv = rgb_to_hsv(arr)
    hsv[..., 0] = (hsv[..., 0]+amount) % 1.0
    rgb = hsv_to_rgb(hsv)
    rgb, lab = SwapL(rgb, L_desired)
    return Image.fromarray(rgb, 'RGB')

def hueShift_KeepL_Step(img, palette,  outbasename, step):

    orig_name = '{}_hue_keepL+0.jpg'.format(outbasename)
    #img.save(orig_name) # this moved in to for loop
    img_arr = np.array(img)
    # palette as pixel. (18) -> (1x6x3)
    palette_arr = np.reshape(palette, [1,6,3])
    #print(palette_arr)

    # Get Luminacne
    L_img = rgb_to_lab(img_arr)[..., 0]
    L_palette = rgb_to_lab(palette_arr)[..., 0]
    #print(L_palette)

    hsv_img_orig = rgb_to_hsv(img_arr)
    hsv_palette_orig = rgb_to_hsv(img_as_ubyte(palette_arr))
    #print(hsv_palette_orig)
    len_step = len(step)
    for (i, amount) in enumerate(step, 1):
        #img2 = hueShift_KeepL(img, amount/360., L_desired) # RGB

        # Image alteration
        hsv = np.copy(hsv_img_orig)
        hsv[..., 0] = (hsv[..., 0]+amount/360.) % 1.0 # gradually shift
        rgb = hsv_to_rgb(hsv)
        rgb, lab = SwapL(rgb, L_img) # (H, W, C)
        # Palette alteration
        hsv_p = np.copy(hsv_palette_orig)
        hsv_p[..., 0] = (hsv_p[..., 0]+amount/360.) % 1.0 # gradually shift
        #print(hsv_p)
        rgb_p = hsv_to_rgb(hsv_p)
        rgb_p, lab_p = SwapL(rgb_p, L_palette) # (1, 6, 3)
        # Save image rgb
        img2 =  Image.fromarray(rgb, 'RGB') # L maintained hueshift image
        out_name = '{}_hue_keepL{:+03d}.jpg'.format(outbasename, int(amount))
        img2.save(out_name)

        out_path_json = '/'.join(out_name.split('/')[-2:])
        #print(out_name)             # ../data/designseeds-v3/trainset/hueShift/Flora/239-FloraHues_150-1_hue_keepL+60.jpg
        print(out_path_json)        # Flora/239-FloraHues_150-1_hue_keepL+60.jpg
        #print(os.path.join(collection_name, img_file))  #Flora/239-FloraHues_150-1.jpg

        # Save image lab
        npy_name =  '{}_hue_keepL{:+03d}.npy'.format(outbasename, int(amount))
        np.save(npy_name, lab)
        # Save palette rgb
        # npy_name =  '{}_hue_keepL{:+03d}.npy'.format(outbasename, int(amount))
        # np.save(npy_name, lab)
        # Save palette lab

        #print(rgb_p)
        #print(lab_p) # Can see L keep maintained

        color_palette = {}
        color_palette_lab = {}
        for j in range(6):
            rgb_json = {'r': str(rgb_p[0, j, 0]), 'g': str(rgb_p[0, j, 1]), 'b': str(rgb_p[0, j, 2])}
            lab_json = {'l': str(lab_p[0, j, 0]), 'a': str(lab_p[0, j, 1]), 'b': str(lab_p[0, j, 2])}
            color_palette[j+1] = rgb_json     # json starts with 1 for lua
            color_palette_lab[j+1] = lab_json
        data_json[len_step*(img_idx-1)+i] = {'img_path': out_path_json,
                'color_palette' : color_palette,
                'color_palette_lab' : color_palette_lab}

# MAIN
print('========== hueShiftData ========')
try:
    os.stat(save_dataset_path)
except:
    os.mkdir(save_dataset_path)

data_json = {} # Treat as global variable

img_path_iterator = glob.iglob(os.path.join(dataset_path, '*', '*')) # './data/*/*'
for (img_idx, img_path) in enumerate(img_path_iterator, 1): # img_idx start with 1
    tmp = img_path.split('/')
    collection_name = tmp[-2]               # Spring
    img_file = tmp[-1]                      # ColorWander2_150-1.png
    palette_file = img_file[:-3]+'npy'      # ColorWander2_150-1.npy
    # Mkdir collection path
    collection_path = os.path.join(save_dataset_path, collection_name)
    try:
        os.stat(collection_path)
    except:
        os.mkdir(collection_path)

    print(img_idx, img_path)
    basename, ext = os.path.splitext(img_path)
    img = Image.open(img_path).convert('RGB')

    # Palette load from path
    palette_path = os.path.join(paletteset_path, collection_name, palette_file)
    palette = np.load(palette_path)
    # perfrom hueshift on image
    outbasename = os.path.join(save_dataset_path, collection_name ,basename.split('/')[-1])
    hueShift_KeepL_Step(img, palette, outbasename, np.linspace(0, 360, 19)[0:-1]) # +20~+340 to 0,+340

with open(os.path.join(save_dataset_path,'color_palette.json'), 'w') as outfile:
    json.dump(data_json, outfile)
