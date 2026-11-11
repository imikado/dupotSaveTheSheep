#!/usr/bin/env python3
"""Joueur 2 (mode 2 joueurs), comme dans Beat and Match to Pass : copie des
planches de Gordon avec la fourrure grise passée en bleu-gris. Seuls les gris
neutres opaques changent (contour noir, blanc des yeux, sangle, jean restent).

Sorties :
  src/Actors/Players/Player2/player-*.png        planches du joueur 2
  src/UI/Controls/Shared/icon-player2.png         icône du HUD
  src/Actors/Vehicles/motobike-*-player2.png      moto du niveau bonus, sans le
                                                  mouton (il roule avec le joueur 1)

Usage : python3 tools/generate_player2.py   (dépendance : python3-pil)
"""
import colorsys
import glob
import os
from collections import deque

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PLAYER_DIR = os.path.join(ROOT, "src/Actors/Players/Player")
PLAYER2_DIR = os.path.join(ROOT, "src/Actors/Players/Player2")
ICON = os.path.join(ROOT, "src/UI/Controls/Shared/icon-player.png")
ICON2 = os.path.join(ROOT, "src/UI/Controls/Shared/icon-player2.png")
VEHICLES_DIR = os.path.join(ROOT, "src/Actors/Vehicles")
# planche de la moto -> nombre d'images
MOTORBIKES = {"motobike-riding": 3, "motobike-take-water": 4, "motobike-take-desserts": 4}

# gris de la fourrure : saturation faible, ni noir (contour) ni blanc (yeux)
MAX_SATURATION = 0.08
MIN_VALUE = 0.15
MAX_VALUE = 0.8

HUE = 0.60
SATURATION = 0.30
BRIGHTNESS = 1.08

# Mouton derrière Gordon sur la moto : taches claires qui partent du bord gauche
SHEEP_MIN_PIXELS = 12
SHEEP_MAX_LEFT = 12
SPECK_MAX_PIXELS = 6
SPECK_MAX_LEFT = 16


def recolor(pixel):
    r, g, b, a = pixel
    if a < 255:
        return pixel
    h, s, v = colorsys.rgb_to_hsv(r / 255, g / 255, b / 255)
    if s > MAX_SATURATION or v < MIN_VALUE or v > MAX_VALUE:
        return pixel
    nr, ng, nb = colorsys.hsv_to_rgb(HUE, SATURATION, min(1.0, v * BRIGHTNESS))
    return (round(nr * 255), round(ng * 255), round(nb * 255), a)


def recolored(path):
    image = Image.open(path).convert("RGBA")
    image.putdata([recolor(p) for p in image.getdata()])
    return image


def components(image, keep):
    """Groupes de pixels voisins (8-connexité) pour lesquels keep(pixel) est vrai."""
    px = image.load()
    width, height = image.size
    seen = set()
    for y in range(height):
        for x in range(width):
            if (x, y) in seen or not keep(px[x, y]):
                continue
            group = []
            queue = deque([(x, y)])
            seen.add((x, y))
            while queue:
                cx, cy = queue.popleft()
                group.append((cx, cy))
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        nx, ny = cx + dx, cy + dy
                        if 0 <= nx < width and 0 <= ny < height and (nx, ny) not in seen and keep(px[nx, ny]):
                            seen.add((nx, ny))
                            queue.append((nx, ny))
            yield group


def light(pixel):
    r, g, b, a = pixel
    return a > 0 and min(r, g, b) >= 150 and max(r, g, b) - min(r, g, b) < 70


def without_sheep(path, frames):
    image = Image.open(path).convert("RGBA")
    px = image.load()
    frame_width = image.width // frames
    for group in list(components(image, light)):
        if len(group) >= SHEEP_MIN_PIXELS and min(x % frame_width for x, _ in group) < SHEEP_MAX_LEFT:
            for point in group:
                px[point] = (0, 0, 0, 0)
    # restes isolés du mouton (yeux, museau)
    for group in list(components(image, lambda p: p[3] > 0)):
        if len(group) <= SPECK_MAX_PIXELS and min(x % frame_width for x, _ in group) < SPECK_MAX_LEFT:
            for point in group:
                px[point] = (0, 0, 0, 0)
    # roue arrière cachée par le mouton : reprise de la première image
    for frame in range(1, frames):
        for x in range(22):
            for y in range(40, image.height):
                if px[frame * frame_width + x, y][3] == 0 and px[x, y][3] > 0:
                    px[frame * frame_width + x, y] = px[x, y]
    return image


def main():
    os.makedirs(PLAYER2_DIR, exist_ok=True)
    for path in sorted(glob.glob(os.path.join(PLAYER_DIR, "player-*.png"))):
        target = os.path.join(PLAYER2_DIR, os.path.basename(path))
        recolored(path).save(target)
        print(target)

    recolored(ICON).save(ICON2)
    print(ICON2)

    for name, frames in MOTORBIKES.items():
        image = without_sheep(os.path.join(VEHICLES_DIR, name + ".png"), frames)
        image.putdata([recolor(p) for p in image.getdata()])
        target = os.path.join(VEHICLES_DIR, name + "-player2.png")
        image.save(target)
        print(target)


if __name__ == "__main__":
    main()
