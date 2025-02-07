import os
import py360convert
import cv2

resolve_root = os.getcwd()
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
