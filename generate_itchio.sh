#!/bin/bash
# Génère les assets de la page itch.io dans export/itchio à partir des captures :
#   cover.png (vignette 630x500), banner.png (bannière 960x300),
#   embed_bg.png (fond du cadre HTML5, « Embed BG » de l'éditeur de thème),
#   ITCHIO.md (couleurs du thème et textes à recopier, depuis l'appdata).
# Description EN : export/itchio/description.html (fait main, prioritaire sur l'appdata).
# Une vignette faite main (sans la signature du script) est conservée sauf FORCE=1.
#
# Usage : ./generate_itchio.sh        Variables : FORCE=1, OUT_DIR
# Dépendance : python3-pil
set -e

TITLE="Save the Sheep"
TAGLINE="Protect the sheep, solo or 2 players co-op"
SHOTS_DIR="export/Linux/screenshots"
ICON="export/Linux/flatpak/icons/512x512.png"
FONT="src/UI/Controls/Shared/Pixeled.ttf"
COVER_SHOT="level_01_start.png"
BANNER_SHOTS="level_01_trex.png level_01_two_players.png bonus_level_two_players.png"
EMBED_SHOT="level_01_two_players.png"
EMBED_SIZE="1920x1080"
TITLE_COLOR="#ffffff"
APPDATA=""  # vide : export/*/flatpak/*.appdata.xml
# Thème itch.io : couleurs calculées depuis COVER_SHOT si vides
ITCH_FONT="Lato"
ITCH_FONT_SIZE="Large"
BG_COLOR=""
BG2_COLOR=""
TEXT_COLOR=""
LINK_COLOR="#ffd34d"
PIXEL_ART="1"

# ---------------------------------------------------------------------------
OUT_DIR="${OUT_DIR:-export/itchio}"
FORCE="${FORCE:-0}"

cd "$(dirname "$0")"

if ! python3 -c "import PIL" 2>/dev/null; then
	echo "Python Pillow requis (apt install python3-pil)" >&2
	exit 1
fi
if ! ls "$SHOTS_DIR"/*.png >/dev/null 2>&1; then
	echo "Aucune capture dans $SHOTS_DIR : générer les captures d'abord" >&2
	exit 1
fi

mkdir -p "$OUT_DIR"
touch "$OUT_DIR/.gdignore"

env TITLE="$TITLE" TAGLINE="$TAGLINE" SHOTS_DIR="$SHOTS_DIR" ICON="$ICON" FONT="$FONT" \
	COVER_SHOT="$COVER_SHOT" BANNER_SHOTS="$BANNER_SHOTS" EMBED_SHOT="$EMBED_SHOT" EMBED_SIZE="$EMBED_SIZE" APPDATA="$APPDATA" \
	ITCH_FONT="$ITCH_FONT" ITCH_FONT_SIZE="$ITCH_FONT_SIZE" BG_COLOR="$BG_COLOR" BG2_COLOR="$BG2_COLOR" TEXT_COLOR="$TEXT_COLOR" LINK_COLOR="$LINK_COLOR" \
	TITLE_COLOR="$TITLE_COLOR" OUT_DIR="$OUT_DIR" FORCE="$FORCE" PIXEL_ART="$PIXEL_ART" \
	python3 - <<'PY'
import os, glob, subprocess
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from PIL.PngImagePlugin import PngInfo

E = os.environ
OUT = E["OUT_DIR"]
MARK = "dupot generate_itchio"
SHOTS = sorted(glob.glob(os.path.join(E["SHOTS_DIR"], "*.png")))
RESAMPLE = Image.NEAREST if E.get("PIXEL_ART") == "1" else Image.LANCZOS
TITLE_COLOR = E.get("TITLE_COLOR") or "#ffffff"


def shot(name):
    p = os.path.join(E["SHOTS_DIR"], name)
    return Image.open(p if os.path.exists(p) else name).convert("RGB")


def pick(var, default):
    names = E.get(var, "").split()
    return [shot(n) for n in names] if names else [Image.open(p).convert("RGB") for p in default]


def font_path():
    if E.get("FONT") and os.path.exists(E["FONT"]):
        return E["FONT"]
    try:
        return subprocess.check_output(["fc-match", "-f", "%{file}", "Ubuntu:bold"], text=True)
    except Exception:
        return None


FONT = font_path()


def font(size):
    return ImageFont.truetype(FONT, size) if FONT else ImageFont.load_default(size)


def fit(text, max_w, max_size, min_size=10):
    d = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    for s in range(max_size, min_size - 1, -1):
        f = font(s)
        if d.textlength(text, font=f) <= max_w:
            return f
    return font(min_size)


def cover_crop(img, w, h):
    r = max(w / img.width, h / img.height)
    img = img.resize((max(w, round(img.width * r)), max(h, round(img.height * r))), Image.LANCZOS)
    x, y = (img.width - w) // 2, (img.height - h) // 2
    return img.crop((x, y, x + w, y + h))


def shade(img, top=0.0, bottom=0.75):
    w, h = img.size
    grad = Image.new("L", (1, h))
    for y in range(h):
        grad.putpixel((0, y), int(255 * (top + (bottom - top) * y / (h - 1))))
    black = Image.new("RGB", (w, h), (0, 0, 0))
    return Image.composite(black, img, grad.resize((w, h)))


def text(draw, xy, s, f, fill, anchor="mm", stroke=None):
    stroke = stroke if stroke is not None else max(2, f.size // 14)
    sx, sy = xy
    off = max(2, f.size // 18)
    draw.text((sx + off, sy + off), s, font=f, fill=(0, 0, 0, 160), anchor=anchor,
              stroke_width=stroke, stroke_fill=(0, 0, 0, 160))
    draw.text(xy, s, font=f, fill=fill, anchor=anchor, stroke_width=stroke, stroke_fill=(0, 0, 0))


def icon(size):
    p = E.get("ICON")
    if not p or not os.path.exists(p):
        return None
    ic = Image.open(p).convert("RGBA")
    return ic.resize((size, size), RESAMPLE if ic.width < size else Image.LANCZOS)


def save(img, path, protect=False):
    if protect and os.path.exists(path) and E.get("FORCE") != "1":
        if Image.open(path).info.get("Software") != MARK:
            print(f"  conservé (fait main, FORCE=1 pour écraser) : {path}")
            return
    meta = PngInfo()
    meta.add_text("Software", MARK)
    img.convert("RGB").save(path, optimize=True, pnginfo=meta)
    print(f"  {path} ({img.width}x{img.height})")


title, tagline = E["TITLE"], E.get("TAGLINE", "")

# Vignette (cover) 630x500
W, H = 630, 500
cv = shade(cover_crop(pick("COVER_SHOT", SHOTS[:1])[0], W, H), 0.05, 0.85)
d = ImageDraw.Draw(cv, "RGBA")
ic = icon(110)
if ic:
    cv.paste(ic, (W - 110 - 18, 18), ic)
ft = fit(title, W - 50, 84)
text(d, (W // 2, H - (125 if tagline else 80)), title, ft, TITLE_COLOR)
if tagline:
    text(d, (W // 2, H - 52), tagline, fit(tagline, W - 50, 30), "#ffffff")
save(cv, os.path.join(OUT, "cover.png"), protect=True)

# Bannière 960x300
W, H = 960, 300
imgs = pick("BANNER_SHOTS", SHOTS[:3])[:3]
bn = Image.new("RGB", (W, H))
cw = W // len(imgs)
for i, im in enumerate(imgs):
    bn.paste(cover_crop(im, cw + (W - cw * len(imgs) if i == len(imgs) - 1 else 0), H), (i * cw, 0))
bn = bn.filter(ImageFilter.GaussianBlur(2))
bn = Image.blend(bn, Image.new("RGB", (W, H), (0, 0, 0)), 0.45)
d = ImageDraw.Draw(bn, "RGBA")
ic = icon(200)
x0 = 40
if ic:
    bn.paste(ic, (x0, (H - 200) // 2), ic)
    x0 += 230
cx = x0 + (W - x0 - 30) // 2
ft = fit(title, W - x0 - 40, 96)
text(d, (cx, H // 2 - (30 if tagline else 0)), title, ft, TITLE_COLOR)
if tagline:
    text(d, (cx, H // 2 + 50), tagline, fit(tagline, W - x0 - 40, 32), "#ffffff")
save(bn, os.path.join(OUT, "banner.png"))

# Fond du cadre HTML5 (Embed BG) : zone centrale libre pour le bouton "Run game"
W, H = (int(v) for v in E.get("EMBED_SIZE", "1920x1080").split("x"))
eb = cover_crop(pick("EMBED_SHOT", SHOTS[:1])[0], W, H).filter(ImageFilter.GaussianBlur(W // 300))
eb = Image.blend(eb, Image.new("RGB", (W, H), (0, 0, 0)), 0.55)
d = ImageDraw.Draw(eb, "RGBA")
isz = H // 5
ic = icon(isz)
ft = fit(title, W * 0.6 if ic else W * 0.8, H // 7)
tw = d.textlength(title, font=ft)
gap = isz // 4 if ic else 0
x = (W - tw - (isz + gap if ic else 0)) / 2
if ic:
    eb.paste(ic, (round(x), round(H * 0.2 - isz / 2)), ic)
    x += isz + gap
text(d, (x, H * 0.2), title, ft, TITLE_COLOR, anchor="lm")
if tagline:
    text(d, (W // 2, H * 0.82), tagline, fit(tagline, W * 0.8, H // 16), "#ffffff")
save(eb, os.path.join(OUT, "embed_bg.png"))

# Fiche à recopier dans l'éditeur de thème itch.io (couleurs + description)
import colorsys
import xml.etree.ElementTree as ET


def hexc(rgb):
    return "#%02x%02x%02x" % tuple(round(c * 255) for c in rgb)


def tone(rgb, l, s_max=0.45):
    h, _, s = colorsys.rgb_to_hls(*rgb)
    return colorsys.hls_to_rgb(h, l, min(s, s_max))


src = pick("COVER_SHOT", SHOTS[:1])[0].resize((64, 64), Image.LANCZOS)
q = src.quantize(8).convert("RGB")
dom = max(q.getcolors(), key=lambda c: c[0] * (0.3 + colorsys.rgb_to_hls(*[v / 255 for v in c[1]])[2]))[1]
dom = [v / 255 for v in dom]
theme = {
    "BG": E.get("BG_COLOR") or hexc(tone(dom, 0.10)),
    "BG 2": E.get("BG2_COLOR") or hexc(tone(dom, 0.17)),
    "Text": E.get("TEXT_COLOR") or "#ececec",
    "Link": E.get("LINK_COLOR") or TITLE_COLOR,
}

XL = "{http://www.w3.org/XML/1998/namespace}lang"


def html_desc(desc, lang):
    from html import escape
    clean = lambda el: escape(" ".join("".join(el.itertext()).split()))
    out = []
    for el in desc:
        if el.tag == "p" and el.get(XL) == lang:
            out.append(f"<p>{clean(el)}</p>")
        elif el.tag in ("ul", "ol"):
            items = [li for li in el if li.get(XL) == lang]
            if items:
                out.append(f"<{el.tag}>\n" + "\n".join(f"  <li>{clean(li)}</li>" for li in items) + f"\n</{el.tag}>")
    return "\n".join(out)


texts = {}
ap = E.get("APPDATA") or next(iter(sorted(glob.glob("export/*/flatpak/*.appdata.xml"))), None)
if ap and os.path.exists(ap):
    root = ET.parse(ap).getroot()
    desc = root.find("description")
    for lang, label in ((None, "EN"), ("fr", "FR")):
        summ = [x.text for x in root.findall("summary") if x.get(XL) == lang]
        body = html_desc(desc, lang) if desc is not None else ""
        if summ or body:
            texts[label] = (summ[0] if summ else "", body)

custom = os.path.join(OUT, "description.html")
if os.path.exists(custom):
    summ = E.get("TAGLINE") or texts.get("EN", ("", ""))[0]
    with open(custom) as f:
        texts["EN"] = (summ, f.read().strip())
md = [f"# {title} — page itch.io", "",
      "Généré par `generate_itchio.sh` : ne pas modifier à la main, régler les variables du script.", "",
      "## Thème (Edit theme)", "",
      "| Champ | Valeur |", "|---|---|"]
md += [f"| **{k}** | `{v}` |" for k, v in theme.items()]
md += [f"| **Font** | {E.get('ITCH_FONT') or 'Lato'} |",
       f"| **Size** | {E.get('ITCH_FONT_SIZE') or 'Large'} |",
       "| **Screenshots** | Sidebar |",
       "| **Banner** | `banner.png` |",
       "| **Background** | aucune (couleur BG) |",
       "| **Embed BG** | `embed_bg.png` |",
       f"| **Embed BG – Color 1** | `{theme['BG']}` |",
       f"| **Embed BG – Color 2** | `{theme['BG 2']}` |",
       "| **Embed BG – Alpha** | 100 % (curseur à droite) |", "",
       "## Images", "",
       "| Fichier | Où |", "|---|---|",
       "| `cover.png` (630x500) | Edit game → Cover image |",
       "| `banner.png` (960x300) | Edit theme → Banner |",
       "| `embed_bg.png` | Edit theme → Embed BG |",
       f"| captures `{E['SHOTS_DIR']}/` | Edit game → Screenshots |", ""]
for label, (summ, body) in texts.items():
    md += [f"## Texte ({label})", "", f"**Short description / tagline :** {summ}", ""]
    if body:
        md += ["**Description** (éditeur itch.io en mode HTML) :", "", "```html", body, "```", ""]
with open(os.path.join(OUT, "ITCHIO.md"), "w") as f:
    f.write("\n".join(md))
print(f"  {os.path.join(OUT, 'ITCHIO.md')}")
PY

echo "Assets itch.io : $OUT_DIR"
