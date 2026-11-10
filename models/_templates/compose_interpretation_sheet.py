import os
from PIL import Image, ImageDraw, ImageFont

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
RENDER_DIR = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "renders")

sheet_w, sheet_h = 2560, 1440
sheet = Image.new("RGBA", (sheet_w, sheet_h), (16, 14, 18, 255))
draw = ImageDraw.Draw(sheet)

# Load Windows TrueType Fonts for clean typography
font_path = r"C:\Windows\Fonts\segoeui.ttf"
font_bold_path = r"C:\Windows\Fonts\segoeuib.ttf"

try:
    font_title = ImageFont.truetype(font_bold_path, 28)
    font_sub = ImageFont.truetype(font_path, 17)
    font_label = ImageFont.truetype(font_bold_path, 16)
    font_pal_title = ImageFont.truetype(font_bold_path, 16)
    font_pal_name = ImageFont.truetype(font_bold_path, 14)
    font_pal_hex = ImageFont.truetype(font_path, 13)
except Exception:
    font_title = font_sub = font_label = font_pal_title = font_pal_name = font_pal_hex = ImageFont.load_default()

# Header
title = "COMADRE FULOZINHA — PRANCHA DE INTERPRETAÇÃO E BLOCKOUT (FASE A)"
subtitle = "Fonte Canônica: art/lore/comadre_fulozinha.md | Estatura: 1.35m (5.8 cabeças) | Tier 4 Conjurador (Vozes + Vigília)"
draw.text((60, 32), title, fill=(245, 240, 235, 255), font=font_title)
draw.text((60, 78), subtitle, fill=(175, 170, 165, 255), font=font_sub)

view_files = [
    ("FRENTE (Manto & Vestimenta)", os.path.join(RENDER_DIR, "blockout_front.png")),
    ("PERFIL DIREITO (Chicote de Cipó)", os.path.join(RENDER_DIR, "blockout_side.png")),
    ("3/4 ÂNGULO (Espreita Ágil)", os.path.join(RENDER_DIR, "blockout_three_quarter.png")),
    ("COSTAS (Cascata de Cabelo Vivo)", os.path.join(RENDER_DIR, "blockout_back.png")),
    ("SILHUETA ISOMÉTRICA (Leitura a 20m)", os.path.join(RENDER_DIR, "blockout_silhouette.png")),
]

slot_w = 460
slot_h = 940
start_x = 60
y_pos = 130

for i, (label, fpath) in enumerate(view_files):
    x = start_x + i * (slot_w + 35)
    # Box frame
    draw.rectangle([x, y_pos, x + slot_w, y_pos + slot_h], fill=(24, 21, 26, 255), outline=(48, 42, 52, 255), width=2)
    # Header tag
    draw.rectangle([x, y_pos, x + slot_w, y_pos + 46], fill=(36, 31, 39, 255))
    draw.text((x + 18, y_pos + 12), label, fill=(225, 220, 212, 255), font=font_label)
    
    if os.path.exists(fpath):
        img = Image.open(fpath).convert("RGBA")
        img.thumbnail((slot_w - 24, slot_h - 70), Image.Resampling.LANCZOS)
        offset_x = x + (slot_w - img.width) // 2
        offset_y = y_pos + 52 + (slot_h - 70 - img.height) // 2
        sheet.alpha_composite(img, (offset_x, offset_y))

# Bottom Palette
pal_y = y_pos + slot_h + 32
draw.text((60, pal_y), "AMOSTRAS DE PALETA (CANÔNICA & DERIVADA DO FOLCLORE):", fill=(215, 210, 205, 255), font=font_pal_title)

palette = [
    ("Manto Cabelo Vivo", "#161314", (22, 19, 20)),
    ("Pele Cabocla", "#7E482B", (126, 72, 43)),
    ("Urtiga / Folhas", "#2F5227", (47, 82, 39)),
    ("Cipó do Chicote", "#4B3621", (75, 54, 33)),
    ("Flores Silvestres", "#D48B28", (212, 139, 40)),
    ("Olhos Jabuticaba", "#0C080E", (12, 8, 14)),
    ("Açoite Magia (Glow)", "#5AE38C", (90, 227, 140)),
]

swatch_w = 280
swatch_h = 58
swatch_start_x = 60
for j, (pname, phex, prgb) in enumerate(palette):
    sx = swatch_start_x + j * (swatch_w + 50)
    sy = pal_y + 36
    draw.rectangle([sx, sy, sx + 58, sy + swatch_h], fill=(*prgb, 255), outline=(75, 70, 80, 255), width=2)
    draw.text((sx + 70, sy + 8), pname, fill=(225, 220, 215, 255), font=font_pal_name)
    draw.text((sx + 70, sy + 32), phex, fill=(155, 150, 145, 255), font=font_pal_hex)

interp_path = os.path.join(RENDER_DIR, "interpretacao.png")
sheet.save(interp_path)
print(f"Prancha gerada com sucesso: {interp_path}")
