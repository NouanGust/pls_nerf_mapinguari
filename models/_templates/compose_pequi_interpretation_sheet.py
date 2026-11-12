import os
from PIL import Image, ImageDraw, ImageFont

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
RENDER_DIR = os.path.join(ROOT_DIR, "models", "pequi", "renders")

sheet_w, sheet_h = 2560, 1440
sheet = Image.new("RGBA", (sheet_w, sheet_h), (16, 14, 18, 255))
draw = ImageDraw.Draw(sheet)

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

title = "PEQUI (Caryocar brasiliense) — PRANCHA DE INTERPRETAÇÃO E BLOCKOUT (FASE 4)"
subtitle = "Fonte Canônica: art/lore/pequi.md | Altura: 1.75m | Tier 1 Suporte Estacionário (Seiva + Vigília | Flora | Cerrado)"
draw.text((60, 32), title, fill=(245, 240, 235, 255), font=font_title)
draw.text((60, 78), subtitle, fill=(175, 170, 165, 255), font=font_sub)

view_files = [
    ("FRENTE (Arco, Fruto Aberto & Semente)", os.path.join(RENDER_DIR, "blockout_front.png"), (24, 21, 26, 255)),
    ("PERFIL DIREITO (Berço & Envergadura)", os.path.join(RENDER_DIR, "blockout_side.png"), (24, 21, 26, 255)),
    ("3/4 ÂNGULO (Leitura no Tabuleiro)", os.path.join(RENDER_DIR, "blockout_three_quarter.png"), (24, 21, 26, 255)),
    ("COSTAS (Casca Suberosa & Fenda Dorsal)", os.path.join(RENDER_DIR, "blockout_back.png"), (24, 21, 26, 255)),
    ("SILHUETA PRETA CHAPADA (Leitura a 20m)", os.path.join(RENDER_DIR, "blockout_silhouette.png"), (215, 210, 202, 255)),
]

slot_w = 460
slot_h = 940
start_x = 60
y_pos = 130

for i, (label, fpath, bg_col) in enumerate(view_files):
    x = start_x + i * (slot_w + 35)
    draw.rectangle([x, y_pos, x + slot_w, y_pos + slot_h], fill=bg_col, outline=(48, 42, 52, 255), width=2)
    draw.rectangle([x, y_pos, x + slot_w, y_pos + 46], fill=(36, 31, 39, 255))
    draw.text((x + 16, y_pos + 12), label, fill=(225, 220, 212, 255), font=font_label)

    if os.path.exists(fpath):
        img = Image.open(fpath).convert("RGBA")
        if "silhouette" in fpath:
            # Make silhouette pure black using alpha mask over the light slot background
            r, g, b, a = img.split()
            black_rgb = Image.new("RGB", img.size, (12, 10, 14))
            img = Image.merge("RGBA", (*black_rgb.split(), a))
        img.thumbnail((slot_w - 24, slot_h - 70), Image.Resampling.LANCZOS)
        offset_x = x + (slot_w - img.width) // 2
        offset_y = y_pos + 52 + (slot_h - 70 - img.height) // 2
        sheet.alpha_composite(img, (offset_x, offset_y))

pal_y = y_pos + slot_h + 32
draw.text((60, pal_y), "AMOSTRAS DE PALETA (CANÔNICA & DERIVADA — art/lore/pequi.md):", fill=(215, 210, 205, 255), font=font_pal_title)

palette = [
    ("Casca Suberosa", "#3B2B22", (59, 43, 34)),
    ("Folhas Coriáceas", "#3E5A28", (62, 90, 40)),
    ("Casca do Fruto", "#465D28", (70, 93, 40)),
    ("Polpa Ouro-Cerrado", "#F29F05", (242, 159, 5)),
    ("Óleo Sagrado", "#FFC72C", (255, 199, 44)),
    ("Semente Espinhosa", "#B87324", (184, 115, 36)),
    ("Seiva Vigília (Glow)", "#FFB833", (255, 184, 51)),
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

