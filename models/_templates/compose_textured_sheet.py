import os
from PIL import Image, ImageDraw, ImageFont

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
RENDER_DIR = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "renders")
TEXTURE_DIR = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "textures")

sheet_w, sheet_h = 2560, 800
sheet = Image.new("RGBA", (sheet_w, sheet_h), (16, 14, 18, 255))
draw = ImageDraw.Draw(sheet)

font_path = r"C:\Windows\Fonts\segoeui.ttf"
font_bold_path = r"C:\Windows\Fonts\segoeuib.ttf"
try:
    font_title = ImageFont.truetype(font_bold_path, 24)
    font_label = ImageFont.truetype(font_bold_path, 15)
except Exception:
    font_title = font_label = ImageFont.load_default()

title = "COMADRE FULOZINHA — VALIDAÇÃO TEXTURIZADA PBR (ETAPAS B & C: 7.799 TRIS, 1 MATERIAL PBR)"
draw.text((60, 25), title, fill=(245, 240, 235, 255), font=font_title)

CONCEPT_PATH = os.path.join(ROOT_DIR, "art", "concepts", "comadre_fulozinha", "comadre_fulozinha_splash.jpg")
atlas_base_path = os.path.join(TEXTURE_DIR, "comadre_fulozinha_base_color.png")

panels = [
    ("1. CONCEITO ORIGINAL (LORE)", CONCEPT_PATH),
    ("2. TEXTURIZADO FRENTE", os.path.join(RENDER_DIR, "textured_front.png")),
    ("3. TEXTURIZADO 3/4", os.path.join(RENDER_DIR, "textured_three_quarter.png")),
    ("4. ATLAS PBR (BASE COLOR 1K)", atlas_base_path),
]

slot_w = 580
slot_h = 680
start_x = 60
y_pos = 75

for i, (label, fpath) in enumerate(panels):
    x = start_x + i * (slot_w + 25)
    draw.rectangle([x, y_pos, x + slot_w, y_pos + slot_h], fill=(24, 21, 26, 255), outline=(48, 42, 52, 255), width=2)
    draw.rectangle([x, y_pos, x + slot_w, y_pos + 38], fill=(36, 31, 39, 255))
    draw.text((x + 16, y_pos + 10), label, fill=(225, 220, 212, 255), font=font_label)
    
    if os.path.exists(fpath):
        img = Image.open(fpath).convert("RGBA")
        img.thumbnail((slot_w - 20, slot_h - 55), Image.Resampling.LANCZOS)
        offset_x = x + (slot_w - img.width) // 2
        offset_y = y_pos + 42 + (slot_h - 55 - img.height) // 2
        sheet.alpha_composite(img, (offset_x, offset_y))

pres_path = os.path.join(RENDER_DIR, "textured_presentation.png")
sheet.save(pres_path)
print(f"Presentation sheet saved: {pres_path}")

