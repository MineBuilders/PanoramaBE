"""
Copyright (C) 2025 Cdm2883

This file is part of PanoramaBE.

This software is licensed under the GNU General Public License v2.
"""

import argparse
import os
import py360convert
import cv2

parser = argparse.ArgumentParser()
parser.add_argument('--inputs', type=str, default=str(os.getcwd()))
args = parser.parse_args()

resolve_root = args.inputs
out_path = os.path.join(resolve_root, "panorama.png")
quality_para = 0
target_size_w = 3000

cube_dice0 = cv2.imread(os.path.join(resolve_root, "panorama_0.png"))
cube_dice1 = cv2.imread(os.path.join(resolve_root, "panorama_1.png"))
cube_dice2 = cv2.imread(os.path.join(resolve_root, "panorama_2.png"))
cube_dice3 = cv2.imread(os.path.join(resolve_root, "panorama_3.png"))
cube_dice4 = cv2.imread(os.path.join(resolve_root, "panorama_4.png"))
cube_dice5 = cv2.imread(os.path.join(resolve_root, "panorama_5.png"))

target_size_w = int(target_size_w)
target_size_h = int(target_size_w // 2)
quality_map = {
    0: 40,
    1: 60,
    2: 90,
    3: 100
}
quality_save = quality_map.get(quality_para, 70)
cube_dice1 = cv2.flip(cube_dice1, 1)
cube_dice2 = cv2.flip(cube_dice2, 1)
cube_dice4 = cv2.flip(cube_dice4, 0)

res = py360convert.c2e(
    [cube_dice0, cube_dice1, cube_dice2, cube_dice3, cube_dice4, cube_dice5],
    target_size_h, target_size_w, cube_format='list'
)
cv2.imwrite(out_path, res, [int(cv2.IMWRITE_JPEG_QUALITY), quality_save])
print("Panorama equirectangular image saved at: " + out_path)
