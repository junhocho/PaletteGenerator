# Palette Generator

written by [Junho Cho](http://tmmse.xyz/junhocho/)

Train and validate with `th paletteGenerator.lua`.

more options with `-exp_name` or `-saveResultsPath`.

eg)
`th paletteGenerator.lua -exp_name L2only -saveResultsPath l2only_results`.
`th paletteGenerator.lua -exp_name GANonly -saveResultsPath GANonly_results`.

## Intro

This repo contains Palette Generator.
Palette Generator is implemented with Torch, inspired by [colormind.io](http://colormind.io).
Palette Generator uses L2 and adversarial loss to train.

## Dataset

Palette is crawled from [design-seeds.com](http://design-seeds.com) and composed of 6 colors.
Crawled with [webscraper.io](http://webscraper.io) Chrome extension.
Use following `./src/crawl_script.json` to crawl.
Dataset code is in `./src`. It also includes hueshift process on img-palette pairs.
However, this implementation do not use images.

For convinience, Dataset is already prepared as `./designseeds-v3-train.t7` and `./designseeds-val.t7`.

## Visualize

Install `display` to visualize results.

![](https://tmmsexy.s3.amazonaws.com/imgs/2017-06-09-084609.jpg)

- Prior color is given sometimes. Output palette will contain the color.
- red : prior color locked 
- yellow : prior color is loosely given.

## Results

### L2+GAN
![](https://tmmsexy.s3.amazonaws.com/imgs/2017-06-18-889.jpg)

Best model proposed

### L2 only
![](https://tmmsexy.s3.amazonaws.com/imgs/2017-06-18-890.jpg)

Cannot learn to generate various color palette

### GAN only
![](https://tmmsexy.s3.amazonaws.com/imgs/2017-06-18-891.jpg)

Seems like mode collapse occur

