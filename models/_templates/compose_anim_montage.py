import os
from PIL import Image, ImageDraw, ImageFont

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
RENDER_DIR = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "renders")

sheet_w, sheet_h = 2400, 700
sheet = Image.new("RGBA", (sheet_w, sheet_h), (16, 14, 18, 255))
draw = ImageDraw.Draw(sheet)

font_path = r"C:\Windows\Fonts\segoeui.ttf"
font_bold_path = r"C:\Windows\Fonts\segoeuib.ttf"
try:
    font_title = ImageFont.truetype(font_bold_path, 22)
    font_label = ImageFont.truetype(font_bold_path, 15)
except Exception:
    font_title = font_label = ImageFont.load_default()

title = "COMADRE FULOZINHA — MONTAGEM DE ANIMAÇÕES DE GAMEPLAY (ETAPA D: 6 CLIPES NLA SEM ROOT MOTION)"
draw.text((50, 22), title, fill=(245, 240, 235, 255), font=font_title)

anims = [
    ("1. IDLE (Postura Ágil / Respiração)", os.path.join(RENDER_DIR, "anim_idle.png")),
    ("2. ATTACK (Estalo do Chicote de Cipó)", os.path.join(RENDER_DIR, "anim_attack.png")),
    ("3. CHANNEL (Assobio Místico da Mata)", os.path.join(RENDER_DIR, "anim_channel.png")),
    ("4. ABILITY (Invocação da Floresta / Giro 360°)", os.path.join(RENDER_DIR, "anim_ability.png")),
]

slot_w = 540
slot_h = 580
start_x = 50
y_pos = 70

for i, (label, fpath) in enumerate(anims):
    x = start_x + i * (slot_w + 35)
    draw.rectangle([x, y_pos, x + slot_w, y_pos + slot_h], fill=(24, 21, 26, 255), outline=(48, 42, 52, 255), width=2)
    draw.rectangle([x, y_pos, x + slot_w, y_pos + 38], fill=(36, 31, 39, 255))
    draw.text((x + 16, y_pos + 10), label, fill=(225, 220, 212, 255), font=font_label)
    
    if os.path.exists(fpath):
        img = Image.open(fpath).convert("RGBA")
        img.thumbnail((slot_w - 20, slot_h - 55), Image.Resampling.LANCZOS)
        offset_x = x + (slot_w - img.width) // 2
        offset_y = y_pos + 42 + (slot_h - 55 - img.height) // 2
        sheet.alpha_composite(img, (offset_x, offset_y))

out_path = os.path.join(RENDER_DIR, "animations_montage.png")
sheet.save(out_path)
print(f"Animation montage saved: {out_path}")

