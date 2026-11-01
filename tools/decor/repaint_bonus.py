#!/usr/bin/env python3
# Repeint le niveau bonus (désert au coucher du soleil) pour que la moto et
# son pilote se détachent mieux du décor :
#
#   - perspective atmosphérique : plus un calque est loin, plus il se fond
#     dans la brume du ciel (mauve), avec moins de contraste et de saturation ;
#   - les buttes passent du rouge bordeaux (même teinte que la moto) au
#     violet crépusculaire ; la modulation de BonusBackground.tscn est
#     désormais intégrée dans l'image ;
#   - dunes, sable et cactus perdent en saturation et en contraste interne :
#     les valeurs les plus sombres et les couleurs les plus vives sont
#     réservées à ce qui est jouable (moto, obstacles) ;
#   - l'asphalte est un peu éclairci pour que les pneus noirs et le contour
#     sombre de la moto se lisent dessus ;
#   - le rouge de la moto est éclairci et plus saturé (rouge cerise).
#
# Le contour sombre de la moto et des obstacles vient du shader partagé
# src/Shared/outline.gdshader (outline_material.tres), branché dans les .tscn.
#
# Le script remplace des couleurs précises par d'autres (les silhouettes et
# les dimensions ne changent pas, les régions des .tscn restent valides).
# Les nouvelles couleurs ne sont jamais des couleurs d'origine : relancer le
# script ne repeint pas deux fois.
#
# Usage : python3 tools/decor/repaint_bonus.py
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SHARED = "src/Levels/Shared/"
VEHICLES = "src/Actors/Vehicles/"


def rgb(hex_color):
	hex_color = hex_color.lstrip("#")
	return tuple(int(hex_color[i:i + 2], 16) for i in (0, 2, 4))


# Sable partagé entre le calque des cactus et le bas-côté de la route
SAND = {
	"#d98f55": "#cf9a74",  # sable du bas-côté
	"#f0ac6c": "#ddae88",  # crête éclairée
	"#9a6a48": "#8f6a58",  # bordure de la route
}

PALETTES = {
	# Le plus loin : presque la couleur du ciel à cette hauteur
	SHARED + "bonus_mesas_far.png": {
		"#5b2d5c": "#8c4a74",
		"#7a3f6c": "#9a5680",
	},
	# Plus proches donc un peu plus sombres, mais violets et non plus rouges
	SHARED + "bonus_buttes.png": {
		"#8c3d48": "#6c3a66",
		"#7a3440": "#62345f",
		"#72323b": "#5c3159",
		"#642a34": "#532c52",
		"#c0605a": "#82486f",
	},
	# Plan moyen : sable poussiéreux, contraste interne réduit
	SHARED + "bonus_dunes.png": {
		"#c8743f": "#b77d63",
		"#a45f33": "#a06c5c",
		"#e8995a": "#c98e6e",
		"#b0643a": "#a8745f",
		"#5a4a2e": "#8a6058",
	},
	# Cactus moins saturés et sans noir : le sombre est pour la moto
	SHARED + "bonus_cacti.png": {
		**SAND,
		"#366644": "#4f6e5e",
		"#598a5c": "#6b8a72",
		"#224430": "#3d564e",
		"#8a5a3c": "#8a6252",
		"#b5713f": "#ac7e62",
		"#b07a50": "#a8846e",
		"#64402b": "#6e4c48",
		"#8a7a3a": "#857c5e",
		"#a8944a": "#9e9670",
	},
	# Asphalte un peu plus clair : pneus et contour noirs lisibles
	SHARED + "bonus_road.png": {
		**SAND,
		"#3a3440": "#4a4353",
		"#2c2733": "#3b3545",
		"#433c4a": "#544c5e",
		"#4d4656": "#5e566a",
	},
	# Rocher plus clair que l'asphalte
	SHARED + "bonus_obstacles.png": {
		"#5e463c": "#7a5a4c",
		"#8a6a58": "#a5826c",
		"#b8927a": "#c9a68c",
	},
}

# Rouge cerise plus lumineux pour la moto (toutes les planches)
BIKE_RED = {
	"#98001a": "#cc1630",
	"#720316": "#8e0c24",
}
for name in ("motobike-riding", "motobike-take-water", "motobike-take-desserts", "motobike-alone"):
	PALETTES[VEHICLES + name + ".png"] = BIKE_RED


def repaint(path, mapping):
	mapping = {rgb(old): rgb(new) for old, new in mapping.items()}
	assert not set(mapping) & set(mapping.values()), path
	image = Image.open(ROOT / path).convert("RGBA")
	pixels = image.load()
	changed = 0
	for y in range(image.height):
		for x in range(image.width):
			r, g, b, a = pixels[x, y]
			new = mapping.get((r, g, b))
			if a and new:
				pixels[x, y] = new + (a,)
				changed += 1
	image.save(ROOT / path)
	print(f"{path}: {changed} pixels")


for path, mapping in PALETTES.items():
	repaint(path, mapping)
