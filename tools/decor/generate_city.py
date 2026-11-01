#!/usr/bin/env python3
# Génère les calques de parallaxe de la ville de nuit (niveau 1) :
#   src/Levels/Shared/city_far.png   silhouettes lointaines, brumeuses
#   src/Levels/Shared/city_mid.png   immeubles sombres, quelques fenêtres
#   src/Levels/Shared/city_near.png  immeubles détaillés, enseignes
#
# Pixel art à la résolution du jeu (1 pixel = 1 pixel de jeu). Chaque calque
# fait 1920x800 et boucle horizontalement (motion_mirroring = 1920).
# Le tirage est fixé : relancer le script redonne les mêmes images.
#
# Usage : python3 tools/decor/generate_city.py
import random
from pathlib import Path

from PIL import Image

WIDTH = 1920
HEIGHT = 800
OUT_DIR = Path(__file__).resolve().parents[2] / "src/Levels/Shared"


def rgb(hex_color):
	hex_color = hex_color.lstrip("#")
	return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4)) + (255,)


class Canvas:
	def __init__(self):
		self.img = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
		self.px = self.img.load()

	def put(self, x, y, color):
		# Boucle horizontale : ce qui dépasse à droite revient à gauche
		if 0 <= y < HEIGHT:
			self.px[x % WIDTH, y] = color

	def rect(self, x, y, w, h, color):
		for j in range(y, y + h):
			for i in range(x, x + w):
				self.put(i, j, color)

	def save(self, name):
		self.img.save(OUT_DIR / name)


# --- Toits ------------------------------------------------------------------

def antenna(c, x, top, height, color, light):
	c.rect(x, top - height, 1, height, color)
	c.put(x, top - height - 1, light)


def water_tower(c, x, top, color, dark):
	# Réservoir sur pieds
	c.rect(x, top - 9, 7, 5, color)
	c.rect(x + 1, top - 10, 5, 1, color)
	c.rect(x, top - 7, 7, 1, dark)
	c.rect(x + 1, top - 4, 1, 4, dark)
	c.rect(x + 5, top - 4, 1, 4, dark)


def roof_details(c, rnd, x, w, top, palette, allow_lights=True):
	kind = rnd.random()
	if kind < 0.3 and w >= 12:
		# Étage en retrait, éventuellement avec antenne
		inset = rnd.randint(3, max(3, w // 4))
		h = rnd.randint(6, 16)
		c.rect(x + inset, top - h, w - 2 * inset, h, palette["body"])
		if rnd.random() < 0.6:
			antenna(c, x + w // 2, top - h, rnd.randint(8, 22), palette["body"],
					palette["red"] if allow_lights else palette["body"])
	elif kind < 0.5 and w >= 14:
		water_tower(c, x + rnd.randint(2, w - 10), top, palette["body"], palette["dark"])
	elif kind < 0.65:
		antenna(c, x + rnd.randint(2, w - 3), top, rnd.randint(6, 30), palette["body"],
				palette["red"] if allow_lights else palette["body"])
	elif kind < 0.75 and w >= 10:
		# Flèche pointue
		half = w // 2
		for k in range(half):
			c.rect(x + k, top - (k + 1) // 2 - 1, w - 2 * k, 1, palette["body"])
		antenna(c, x + half, top - half // 2 - 1, 10, palette["body"],
				palette["red"] if allow_lights else palette["body"])
	elif w >= 10:
		# Blocs de climatisation
		for _ in range(rnd.randint(1, 3)):
			bw = rnd.randint(3, 6)
			c.rect(x + rnd.randint(1, max(1, w - bw - 1)), top - 3, bw, 3, palette["body"])


# --- Fenêtres ---------------------------------------------------------------

def windows(c, rnd, x, w, top, palette, lit_ratio, size, gap):
	ww, wh = size
	gx, gy = gap
	margin = 3
	cols = (w - 2 * margin + gx) // (ww + gx)
	if cols <= 0:
		return
	# Centre la grille dans la façade
	start_x = x + (w - (cols * (ww + gx) - gx)) // 2
	y = top + 5
	floor_lit = 0.0
	while y + wh < HEIGHT:
		# Certains étages sont plus éclairés que d'autres
		if rnd.random() < 0.15:
			floor_lit = lit_ratio * 3
		else:
			floor_lit = lit_ratio
		for i in range(cols):
			wx = start_x + i * (ww + gx)
			r = rnd.random()
			if r < floor_lit:
				color = rnd.choice(palette["lit"])
			else:
				color = palette["window"]
			c.rect(wx, y, ww, wh, color)
			# Rebord lumineux sous les fenêtres allumées
			if r < floor_lit and "sill" in palette:
				c.rect(wx, y + wh, ww, 1, palette["sill"])
		y += wh + gy


def neon_sign(c, rnd, x, top, colors):
	# Enseigne verticale : cadre sombre et lettres en tirets lumineux
	color, glow = rnd.choice(colors)
	h = rnd.randint(22, 36)
	c.rect(x - 1, top - 1, 7, h + 2, glow)
	c.rect(x, top, 5, h, (24, 18, 40, 255))
	for y in range(top + 2, top + h - 2, 4):
		c.rect(x + 1, y, 3, 2, color)


# --- Calques ----------------------------------------------------------------

def skyline(c, rnd, palette, widths, tops, gaps, details):
	x = 0
	while x < WIDTH - widths[0]:
		w = rnd.randint(*widths)
		if x + w > WIDTH:
			w = WIDTH - x
		top = rnd.randint(*tops)
		details(c, rnd, x, w, top)
		x += w + rnd.randint(*gaps)


def far_layer():
	rnd = random.Random(11)
	c = Canvas()
	palette = {
		"body": rgb("#241f47"),
		"dark": rgb("#1d1a3c"),
		"red": rgb("#7a3550"),
	}

	def details(c, rnd, x, w, top):
		c.rect(x, top, w, HEIGHT - top, palette["body"])
		roof_details(c, rnd, x, w, top, palette, allow_lights=False)
		# Quelques fenêtres très ternes
		for _ in range(rnd.randint(0, 4)):
			c.rect(x + rnd.randint(2, max(2, w - 4)), rnd.randint(top + 4, top + 200), 2, 2, rgb("#3a3058"))

	skyline(c, rnd, palette, (26, 70), (262, 346), (-6, 4), details)
	c.save("city_far.png")


def mid_layer():
	rnd = random.Random(23)
	c = Canvas()
	palette = {
		"body": rgb("#191934"),
		"dark": rgb("#121229"),
		"red": rgb("#d0405a"),
		"window": rgb("#14142b"),
		"lit": [rgb("#8a6b3c"), rgb("#9a7a44"), rgb("#4d6a86")],
	}

	def details(c, rnd, x, w, top):
		c.rect(x, top, w, HEIGHT - top, palette["body"])
		roof_details(c, rnd, x, w, top, palette)
		windows(c, rnd, x, w, top, palette, 0.07, (2, 2), (3, 4))

	skyline(c, rnd, palette, (30, 72), (258, 330), (2, 30), details)
	c.save("city_mid.png")


def near_layer():
	rnd = random.Random(37)
	c = Canvas()
	palette = {
		"body": rgb("#252851"),
		"shade": rgb("#1e2145"),
		"light": rgb("#3d447a"),
		"dark": rgb("#181a38"),
		"red": rgb("#ff4d5e"),
		"window": rgb("#191b37"),
		"lit": [rgb("#d9ae5c"), rgb("#e8c97f"), rgb("#cf8f52"), rgb("#7bb2dc")],
		"sill": rgb("#33355c"),
	}
	neons = [
		(rgb("#ff5fae"), rgb("#4a2350")),
		(rgb("#5ff2ff"), rgb("#1f3e5a")),
		(rgb("#ffd25f"), rgb("#4a3a2a")),
	]

	def details(c, rnd, x, w, top):
		c.rect(x, top, w, HEIGHT - top, palette["body"])
		# Lune à droite : arête droite éclairée, côté gauche dans l'ombre
		c.rect(x, top, 3, HEIGHT - top, palette["shade"])
		c.rect(x + w - 1, top, 1, HEIGHT - top, palette["light"])
		# Corniche
		c.rect(x - 1, top, w + 2, 2, palette["light"])
		c.rect(x - 1, top + 2, w + 2, 1, palette["dark"])
		roof_details(c, rnd, x, w, top, palette)
		# Bandeaux horizontaux tous les quelques étages
		if rnd.random() < 0.4:
			step = rnd.choice((40, 56, 72))
			for y in range(top + step, HEIGHT, step):
				c.rect(x, y, w, 1, palette["shade"])
		windows(c, rnd, x, w, top + 2, palette, 0.1,
				rnd.choice(((3, 4), (2, 4), (4, 3))), rnd.choice(((3, 5), (4, 6), (2, 5))))
		if w >= 40 and rnd.random() < 0.45:
			neon_sign(c, rnd, x + w - 9, top + rnd.randint(30, 110), neons)

	skyline(c, rnd, palette, (40, 84), (272, 340), (24, 80), details)
	c.save("city_near.png")


if __name__ == "__main__":
	far_layer()
	mid_layer()
	near_layer()
	print("Calques générés dans", OUT_DIR)
