"""Assemble toutes les planches en tools/sprite_baker/contact.png.

Une section par element ; une ligne par direction (numero ecrit a gauche) ;
pour chaque animation, trois colonnes : premiere image, image du milieu, derniere image.
Usage : python3 contact_sheet.py [echelle]   (echelle 1.0 par defaut)
"""
import json
import os
import sys

from PIL import Image, ImageDraw

HERE = os.path.dirname(os.path.abspath(__file__))
SPRITES = os.path.join(HERE, "..", "..", "assets", "sprites")
LABEL_W = 40
TITLE_H = 22
BG = (58, 58, 74, 255)


def main() -> None:
    scale = float(sys.argv[1]) if len(sys.argv) > 1 else 1.0
    sections = []
    for item in sorted(os.listdir(SPRITES)):
        path = os.path.join(SPRITES, item, "sheet.json")
        if not os.path.exists(path):
            continue
        with open(path, encoding="utf-8") as f:
            sheet = json.load(f)
        cw, ch = sheet["cell"]
        dirs = sheet["directions"]
        cols = []
        for name, anim in sheet["animations"].items():
            img = Image.open(os.path.join(SPRITES, item, anim["file"])).convert("RGBA")
            n = anim["frames"]
            for fi in sorted({0, n // 2, n - 1}):
                cols.append((name + " " + str(fi), img, fi))
        w = LABEL_W + cw * len(cols)
        h = TITLE_H + ch * dirs
        sec = Image.new("RGBA", (w, h), BG)
        d = ImageDraw.Draw(sec)
        d.text((4, 4), item, fill=(255, 255, 255, 255))
        for ci, (label, img, fi) in enumerate(cols):
            x = LABEL_W + ci * cw
            d.text((x + 4, 4 + 8 * (ci % 2)), label, fill=(255, 226, 59, 255))
            for k in range(dirs):
                cell = img.crop((fi * cw, k * ch, (fi + 1) * cw, (k + 1) * ch))
                sec.alpha_composite(cell, (x, TITLE_H + k * ch))
                # repere d'ancrage
                ax, ay = sheet["anchor"]
                d.point((x + ax, TITLE_H + k * ch + ay), fill=(255, 0, 0, 255))
        for k in range(dirs):
            d.text((10, TITLE_H + k * ch + ch // 2), str(k), fill=(255, 255, 255, 255))
        sections.append(sec)
    width = max(s.width for s in sections)
    height = sum(s.height for s in sections)
    out = Image.new("RGBA", (width, height), BG)
    y = 0
    for s in sections:
        out.alpha_composite(s, (0, y))
        y += s.height
    if scale != 1.0:
        out = out.resize((int(out.width * scale), int(out.height * scale)), Image.LANCZOS)
    out.save(os.path.join(HERE, "contact.png"))
    print("contact.png", out.size)


if __name__ == "__main__":
    main()
