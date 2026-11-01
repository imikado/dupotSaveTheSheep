#!/usr/bin/env python3
# Repeint les tuiles du premier plan du niveau 1 dans l'ambiance nocturne des
# calques de fond (generate_city.py) :
#   src/Levels/Shared/BuildingTileMap.png  immeubles (pierre et brique)
#   src/Levels/Shared/TileMap.png          sol (trottoir et terre)
#
# Les silhouettes (alpha) ne changent pas : les collisions des TileSets
# restent valides. Le script part des images d'origine versionnées dans git
# (ORIGINAL_REV), il peut donc être relancé sans repeindre deux fois.
#
# Usage : python3 tools/decor/repaint_city_tiles.py
import io
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ORIGINAL_REV = "0b98609"
BUILDINGS = "src/Levels/Shared/BuildingTileMap.png"
GROUND = "src/Levels/Shared/TileMap.png"


def rgb(hex_color):
	hex_color = hex_color.lstrip("#")
	return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def load_original(path):
	data = subprocess.run(["git", "show", f"{ORIGINAL_REV}:{path}"], cwd=ROOT,
						  capture_output=True, check=True).stdout
	return Image.open(io.BytesIO(data)).convert("RGBA")


def mix(a, b, t):
	return tuple(round(a[i] + (b[i] - a[i]) * t) for i in range(3)) + (255,)


# --- Immeubles --------------------------------------------------------------

BUILDING_TILE = (32, 46)

# Couleurs d'origine
A_WALL = (120, 111, 88, 255)
A_TRIM = (82, 75, 55, 255)
A_LEDGE = (96, 88, 64, 255)
A_FRAME = (84, 58, 57, 255)
A_DOOR_DARK = (56, 38, 37, 255)
B_WALL = (87, 72, 48, 255)
B_TRIM = (85, 52, 2, 255)
B_WOOD = (105, 63, 0, 255)
GLASS = (6, 31, 70, 255)
GLASS_EDGE = (2, 10, 23, 255)

STONE = {
	A_WALL: rgb("#5f5b73"),
	A_TRIM: rgb("#3f3b52"),
	A_LEDGE: rgb("#4d4963"),
	A_FRAME: rgb("#35303f"),
	A_DOOR_DARK: rgb("#2a2433"),
	GLASS: rgb("#1f2850"),
	GLASS_EDGE: rgb("#101329"),
}
STONE_COURSE = rgb("#57536b")

BRICK = {
	B_WALL: rgb("#5a3a42"),
	B_TRIM: rgb("#3a2732"),
	B_WOOD: rgb("#6b4a3a"),
	GLASS: rgb("#1f2850"),
	GLASS_EDGE: rgb("#101329"),
}
BRICK_MORTAR = rgb("#4a2f38")
BRICK_LIGHT = rgb("#64424a")

GLINT = rgb("#4a5c94")
LIT = rgb("#f0c46a")
LIT_LOW = rgb("#d9974f")
MOON_EDGE = 0.35
SHADOW_EDGE = 0.35
LAMP = rgb("#ffe7a3")
LAMP_GLOW = rgb("#ffcf70")


def repaint_buildings():
	src = load_original(BUILDINGS)
	out = src.copy()
	s = src.load()
	o = out.load()
	tw, th = BUILDING_TILE

	for ty in range(src.height // th):
		for tx in range(src.width // tw):
			kit = "A" if tx < 4 else "B"
			col = tx % 4
			# Fenêtres allumées : colonne de gauche des immeubles en brique
			lit = kit == "B" and col == 0 and ty >= 1
			for y in range(th):
				for x in range(tw):
					px, py = tx * tw + x, ty * th + y
					c = s[px, py]
					if c[3] == 0:
						continue
					o[px, py] = paint_building_pixel(c, kit, x, y, lit)
			moon_edges(s, o, tx, ty, col)
			if ty == 2 and col == 2:
				door_lamp(s, o, tx, ty, kit)

	out.save(ROOT / BUILDINGS)


def paint_building_pixel(c, kit, x, y, lit):
	if c in (GLASS, GLASS_EDGE):
		if lit:
			return LIT if c == GLASS and y % 6 < 4 else LIT_LOW
		# Reflet de lune en diagonale sur les vitres
		if c == GLASS and (x + y) % 13 in (0, 1):
			return GLINT
		return STONE[c]
	if kit == "A":
		if c == A_WALL:
			# Assises de pierre
			return STONE_COURSE if y % 7 == 3 else STONE[c]
		return STONE.get(c, c)
	if c == B_WALL:
		# Briques de 8x4 décalées d'une rangée à l'autre
		row = y // 4
		if y % 4 == 3:
			return BRICK_MORTAR
		if (x + (row % 2) * 4) % 8 == 0:
			return BRICK_MORTAR
		return BRICK_LIGHT if (x // 8 + row) % 5 == 0 else BRICK[c]
	return BRICK.get(c, c)


def moon_edges(s, o, tx, ty, col):
	# Lune à droite comme sur le fond : arête droite éclairée, gauche dans l'ombre
	tw, th = BUILDING_TILE
	if col not in (0, 2):
		return
	for y in range(th):
		py = ty * th + y
		xs = [x for x in range(tw) if s[tx * tw + x, py][3]]
		if not xs:
			continue
		if col == 2:
			px = tx * tw + max(xs)
			o[px, py] = mix(o[px, py], (190, 200, 255), MOON_EDGE)
		else:
			px = tx * tw + min(xs)
			o[px, py] = mix(o[px, py], (10, 8, 24), SHADOW_EDGE)


def door_lamp(s, o, tx, ty, kit):
	# Applique au-dessus de la porte et halo chaud sur le mur
	tw, th = BUILDING_TILE
	cx = tx * tw + 13
	cy = ty * th + 2
	for dy in range(-3, 5):
		for dx in range(-6, 7):
			px, py = cx + dx, cy + dy
			if py < ty * th or not s[px, py][3]:
				continue
			d = (dx * dx + dy * dy * 2) ** 0.5
			if d < 6.5:
				o[px, py] = mix(o[px, py], LAMP_GLOW, 0.35 if d < 4 else 0.18)
	o[cx - 1, cy] = LAMP
	o[cx, cy] = LAMP
	o[cx + 1, cy] = LAMP
	o[cx, cy - 1] = rgb("#2a2433")


# --- Sol --------------------------------------------------------------------

GROUND_TILE = 32
DIRT = (87, 65, 57, 255)
DIRT_SPECK = (115, 87, 79, 255)
GRASS = (69, 103, 63, 255)
WATER = (73, 132, 164, 255)
HOLE = (0, 0, 0, 255)

SOIL = {
	DIRT: rgb("#2f2838"),
	DIRT_SPECK: rgb("#3f3549"),
	WATER: rgb("#2f5f86"),
	HOLE: rgb("#0c0a12"),
}
CURB_TOP = rgb("#8a8cab")
CURB = rgb("#5e5f7e")
SLAB_LIGHT = rgb("#525370")
SLAB = rgb("#474862")
SLAB_JOINT = rgb("#35364d")
SIDEWALK_SHADOW = rgb("#221d2b")
WATER_TOP = rgb("#5f9ccc")


def repaint_ground():
	src = load_original(GROUND)
	out = src.copy()
	s = src.load()
	o = out.load()
	n = GROUND_TILE

	for ty in range(src.height // n):
		for tx in range(src.width // n):
			grass_rows = set()
			for y in range(n):
				for x in range(n):
					px, py = tx * n + x, ty * n + y
					c = s[px, py]
					if c == GRASS:
						grass_rows.add(y)
					if c[3]:
						o[px, py] = SOIL.get(c, c)
					if c == WATER and (py == 0 or s[px, py - 1] != WATER):
						o[px, py] = WATER_TOP
			if grass_rows:
				sidewalk(s, o, tx, ty, min(grass_rows))

	out.save(ROOT / GROUND)


def sidewalk(s, o, tx, ty, top):
	# Le gazon devient un trottoir : bordure, dalles, puis ombre sur la terre
	n = GROUND_TILE
	rows = [CURB_TOP, CURB, SLAB_LIGHT, SLAB, SLAB, SIDEWALK_SHADOW]
	for i, color in enumerate(rows):
		y = top + i
		if y >= n:
			break
		for x in range(n):
			px, py = tx * n + x, ty * n + y
			# Garde la silhouette, en remplissant les touffes de la 1re ligne
			ref = s[px, py + 1] if i == 0 and y + 1 < n else s[px, py]
			if not ref[3] or ref == HOLE:
				continue
			c = color
			if 2 <= i <= 4 and x % 16 == 0:
				c = SLAB_JOINT
			o[px, py] = c


if __name__ == "__main__":
	repaint_buildings()
	repaint_ground()
	print("Tuiles repeintes :", BUILDINGS, GROUND)
