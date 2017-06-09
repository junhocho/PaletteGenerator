# Palette Generator

## Intro

This repo contains Palette Generator.
Palette Generator is implemented with Torch, inspired by `colormind.io`.
Palette Generator uses L2 and adversarial loss to train.

## Dataset

Palette is crawled from `design-seeds.com` and composed of 6 colors.
Dataset code is in `./src`. It also includes hueshift process on img-palette pairs.
Dataset is already prepared as `./designseeds-v3-train.t7`.

# Visualize

Install `display` to visualize results.

![](https://tmmsexy.s3.amazonaws.com/imgs/2017-06-09-084609.jpg)
