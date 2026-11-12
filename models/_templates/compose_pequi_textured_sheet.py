"""
Monta prancha 2x2 com os 4 ângulos de visualização do Pequi Texturizado PBR.
"""

from PIL import Image, ImageDraw, ImageFont
import os

renders_dir = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/renders"

views = [
    ("FRENTE", os.path.join(renders_dir, "textured_front.png")),
    ("TRÊS-QUARTOS", os.path.join(renders_dir, "textured_three_quarter.png")),
    ("LATERAL", os.path.join(renders_dir, "textured_side.png")),
    ("TRASEIRA", os.path.join(renders_dir, "textured_back.png")),
]

target_w, target_h = 600, 600
padding = 24
header_h = 70
canvas_w = target_w * 2 + padding * 3
canvas_h = target_h * 2 + padding * 3 + header_h

sheet = Image.new("RGBA", (canvas_w, canvas_h), (20, 18, 16, 255))
draw = ImageDraw.Draw(sheet)

try:
    font_title = ImageFont.truetype("arial.ttf", 32)
    font_label = ImageFont.truetype("arial.ttf", 22)
except:
    font_title = ImageFont.load_default()
    font_label = ImageFont.load_default()

draw.text((padding, 20), "PEQUI — MODELO TEXTURIZADO PBR (Cerrado / Suporte)", fill=(245, 205, 75, 255), font=font_title)

positions = [
    (padding, header_h + padding),
    (padding * 2 + target_w, header_h + padding),
    (padding, header_h + padding * 2 + target_h),
    (padding * 2 + target_w, header_h + padding * 2 + target_h)
]

for (label, filepath), (x, y) in zip(views, positions):
    if os.path.exists(filepath):
        im = Image.open(filepath).convert("RGBA")
        im_resized = im.resize((target_w, target_h), Image.Resampling.LANCZOS)
        draw.rectangle([x - 2, y - 2, x + target_w + 1, y + target_h + 1], outline=(70, 60, 45, 255), width=2)
        sheet.paste(im_resized, (x, y), im_resized)
        draw.rectangle([x + 10, y + 10, x + 180, y + 42], fill=(15, 15, 15, 200))
        draw.text((x + 18, y + 14), label, fill=(245, 245, 240, 255), font=font_label)

out_file = os.path.join(renders_dir, "textured_presentation.png")
sheet.save(out_file)
print(f"Prancha texturizada salva em: {out_file}")

brain_dest = "C:/Users/Professor/.gemini/antigravity/brain/8d64f2bc-a675-4a71-b613-580d14bea8a8/pequi_textured_presentation.png"
sheet.save(brain_dest)
print(f"Copiado para brain artifacts: {brain_dest}")

