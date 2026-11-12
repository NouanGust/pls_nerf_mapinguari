"""
Etapa 2 (Ajuste Fino de Cores do Atlas e Mapeamento UV das Folhas):
- Leaves: U in [0.55, 0.95], V in [0.05, 0.45] -> Verde folha viçosa com variações
- Bark: U in [0.05, 0.45], V in [0.55, 0.95] -> Marrom corticoso estriado
- Rind: U in [0.05, 0.45], V in [0.05, 0.45] -> Verde oliva pequi
- Pulp: U in [0.55, 0.75], V in [0.75, 0.95] -> Amarelo ouro brilhante
- Seed: U in [0.78, 0.98], V in [0.75, 0.95] -> Ocre/dourado com espinhos
- Eye:  U in [0.55, 0.95], V in [0.55, 0.70] -> Laranja brasa
"""

from PIL import Image, ImageDraw, ImageFilter
import random
import os

tex_dir = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/textures/"
os.makedirs(tex_dir, exist_ok=True)
w, h = 1024, 1024

# Base Color
bc = Image.new("RGBA", (w, h), (85, 55, 35, 255))
draw = ImageDraw.Draw(bc)

# 1. Bark (Tronco): [0..512, 0..512]
draw.rectangle([0, 0, 512, 512], fill=(95, 62, 40, 255))
random.seed(42)
for _ in range(4000):
    rx = random.randint(0, 511)
    ry = random.randint(0, 511)
    cv = random.randint(-20, 20)
    draw.line([rx, ry, rx + random.randint(-4, 4), ry + random.randint(12, 30)], fill=(95 + cv, 62 + cv, 40 + cv, 255), width=2)

# 2. Leaves (Folhas): [512..1024, 512..1024]
draw.rectangle([512, 512, 1024, 1024], fill=(58, 125, 32, 255))
for _ in range(3500):
    rx = random.randint(512, 1023)
    ry = random.randint(512, 1023)
    cv = random.randint(-22, 22)
    draw.ellipse([rx, ry, rx + random.randint(8, 18), ry + random.randint(8, 18)], fill=(58 + cv, 125 + cv, 32 + cv, 255))

# 3. Rind (Casca verde fruto): [0..512, 512..1024]
draw.rectangle([0, 512, 512, 1024], fill=(85, 120, 38, 255))
for _ in range(2500):
    rx = random.randint(0, 511)
    ry = random.randint(512, 1023)
    cv = random.randint(-15, 15)
    draw.point((rx, ry), fill=(85 + cv, 120 + cv, 38 + cv, 255))

# 4. Pulp (Polpa amarelo ouro): [512..768, 0..256]
draw.rectangle([512, 0, 768, 256], fill=(255, 185, 8, 255))
for _ in range(1500):
    rx = random.randint(512, 767)
    ry = random.randint(0, 255)
    cv = random.randint(-12, 15)
    draw.point((rx, ry), fill=(255, min(255, 185 + cv), max(0, 8 + cv), 255))

# 5. Seed (Semente com espinhos): [768..1024, 0..256]
draw.rectangle([768, 0, 1024, 256], fill=(215, 145, 45, 255))
for _ in range(1500):
    rx = random.randint(768, 1023)
    ry = random.randint(0, 255)
    cv = random.randint(-15, 15)
    draw.point((rx, ry), fill=(215 + cv, 145 + cv, 45 + cv, 255))

# 6. Eye (Fenda sentinela âmbar): [512..1024, 256..512]
draw.rectangle([512, 256, 1024, 512], fill=(255, 100, 0, 255))

bc = bc.filter(ImageFilter.GaussianBlur(radius=0.7))
bc_path = os.path.join(tex_dir, "pequi_base_color.png")
bc.save(bc_path)
print(f"Base Color atualizada: {bc_path}")
