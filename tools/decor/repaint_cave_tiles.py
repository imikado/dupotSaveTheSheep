#!/usr/bin/env python3
# Repeint les tuiles du premier plan du niveau 2 (grotte) :
#   src/Levels/Level2/TileMap.png
#
# Le fond (cave_background.gdshader) est bleu-vert froid et sombre : la roche
# jouable passe dans une rampe chaude (brun, ombres vers le violet, lumières
# vers l'ocre) pour s'en détacher par la teinte, et ses surfaces reçoivent un
# liseré éclairé par le haut (sol clair, plafond sombre, parois en bordure)
# pour s'en détacher par la valeur. L'intérieur reste calme : de grandes
# pierres peu contrastées, le détail est concentré sur les bords.
#
# Les silhouettes (alpha) ne changent pas : les collisions du TileSet restent
# valides. Le script part de l'image d'origine versionnée dans git
# (ORIGINAL_REV), il peut donc être relancé sans repeindre deux fois.
#
# Usage : python3 tools/decor/repaint_cave_tiles.py
import io
import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
ORIGINAL_REV = "0b98609"
CAVE = "src/Levels/Level2/TileMap.png"
TILE = 32


def rgb(hex_color):
	hex_color = hex_color.lstrip("#")
	return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


def load_original(path):
	data = subprocess.run(["git", "show", f"{ORIGINAL_REV}:{path}"], cwd=ROOT,
						  capture_output=True, check=True).stdout
	return Image.open(io.BytesIO(data)).convert("RGBA")


# Couleurs d'origine de la roche (la lave de la tuile 2:0 est gardée)
ROCK = (37, 63, 75, 255)
ROCK_SPECK = (25, 87, 115, 255)

# Rampe de la roche, de l'ombre à la lumière : l'intérieur reste plus sombre
# que le fond, seuls les bords sont clairs
OUTLINE = rgb("#0f0a10")
JOINT = rgb("#1a1117")
STONE_DARK = rgb("#2b1d21")
STONE = rgb("#352427")
STONE_LIGHT = rgb("#45302c")
BOUNCE = rgb("#4d3530")
RIM = rgb("#6e4c30")
LIGHT = rgb("#a0723b")
TOP = rgb("#d9a957")
# Mousse sur le sol, par touffes
MOSS = rgb("#6f8a35")
MOSS_LIGHT = rgb("#a3bd4a")

# Pierres de l'intérieur : cellules de Voronoï sur une grille 3x3 refermée sur
# elle-même pour que le motif se raccorde d'une tuile à l'autre
PEBBLES = 3
STONE_SHADES = [STONE, STONE_DARK, STONE, STONE_DARK, STONE]


def hash2(x, y):
	h = (x * 374761393 + y * 668265263) & 0xFFFFFFFF
	h = ((h ^ (h >> 13)) * 1274126177) & 0xFFFFFFFF
	return (h ^ (h >> 16)) & 0xFFFF


def repaint_cave():
	src = load_original(CAVE)
	out = src.copy()
	s = src.load()
	o = out.load()

	for ty in range(src.height // TILE):
		for tx in range(src.width // TILE):
			for y in range(TILE):
				for x in range(TILE):
					px, py = tx * TILE + x, ty * TILE + y
					if s[px, py] in (ROCK, ROCK_SPECK):
						o[px, py] = paint_rock_pixel(s, tx, ty, x, y)

	out.save(ROOT / CAVE)


def air_distance(s, tx, ty, x, y, dx, dy, limit=4):
	# Distance au vide dans une direction, sans sortir de la tuile : au bord de
	# la tuile la roche continue dans la tuile voisine
	for k in range(1, limit + 1):
		nx, ny = x + dx * k, y + dy * k
		if not (0 <= nx < TILE and 0 <= ny < TILE):
			return None
		if s[tx * TILE + nx, ty * TILE + ny][3] == 0:
			return k
	return None


def open_above(s, tx, ty, x, y):
	# Au moins 3 px de vide au-dessus de (x, y), sans sortir de la tuile
	for k in range(3):
		if y - k < 0 or s[tx * TILE + x, ty * TILE + y - k][3]:
			return False
	return True


def paint_rock_pixel(s, tx, ty, x, y):
	up = air_distance(s, tx, ty, x, y, 0, -1)
	# Un trou de 1 ou 2 px dans une bordure n'est pas un sol
	if up is not None and open_above(s, tx, ty, x, y - up):
		return floor_pixel(tx, x, up)
	down = air_distance(s, tx, ty, x, y, 0, 1)
	if down == 1:
		return BOUNCE
	if down == 2:
		return OUTLINE
	left = air_distance(s, tx, ty, x, y, -1, 0)
	right = air_distance(s, tx, ty, x, y, 1, 0)
	side = min(d for d in (left, right, 9) if d is not None)
	if side == 1:
		return RIM
	if side == 2:
		return JOINT
	return stone_pixel(x, y)


def floor_pixel(tx, x, depth):
	# Sol éclairé par le haut, avec des touffes de mousse
	moss = hash2(tx * TILE + x // 3, 7) % 5 == 0
	if depth == 1:
		return MOSS_LIGHT if moss else TOP
	if depth == 2:
		return MOSS if moss else LIGHT
	if depth == 3:
		return RIM
	return STONE_LIGHT


def pebble_centers():
	cell = TILE / PEBBLES
	return [((i + 0.2 + (hash2(i, j) % 60) / 100) * cell,
			 (j + 0.2 + (hash2(j, i + 9) % 60) / 100) * cell)
			for i in range(PEBBLES) for j in range(PEBBLES)]


CENTERS = pebble_centers()


def pebble(x, y):
	# Index de la pierre la plus proche et écart avec la deuxième, en distance
	# torique ; les pierres sont plus larges que hautes, comme des strates
	dists = []
	for index, (cx, cy) in enumerate(CENTERS):
		dx = min(abs(x - cx), TILE - abs(x - cx))
		dy = min(abs(y - cy), TILE - abs(y - cy)) * 1.4
		dists.append(((dx * dx + dy * dy) ** 0.5, index))
	dists.sort()
	return dists[0][1], dists[1][0] - dists[0][0]


def stone_pixel(x, y):
	index, gap = pebble(x, y)
	if gap < 1.2:
		return JOINT
	shade = STONE_SHADES[index % len(STONE_SHADES)]
	# Haut de la pierre éclairé, bas dans l'ombre
	above, _ = pebble(x, (y - 1) % TILE)
	if above != index:
		return STONE_LIGHT if shade != STONE_LIGHT else BOUNCE
	below, _ = pebble(x, (y + 1) % TILE)
	if below != index:
		return STONE_DARK
	return shade


if __name__ == "__main__":
	repaint_cave()
	print("Tuiles repeintes :", CAVE)
