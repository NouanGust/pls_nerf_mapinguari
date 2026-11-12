"""
Blockout refinado do Pequi:
- Tronco retorcido com proporções mais dinâmicas e ameaçadoras/místicas do Cerrado
- Galhos frontais segurando/protegendo o fruto
- O fruto aberto é maior, com cálice rugoso, polpa amarelo-ouro e o caroço espinhoso evidente em destaque
- Olho/fenda sentinela no tronco
- Iluminação direcional quente (sol dourado do Cerrado)
"""

import bpy
import bmesh
import math
from mathutils import Vector, Matrix

for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes):
    bpy.data.meshes.remove(m, do_unlink=True)
for mat in list(bpy.data.materials):
    bpy.data.materials.remove(mat, do_unlink=True)

# 1. Materiais
def make_mat(name, col, rough=0.8, emissive=None, emissive_str=1.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    b = mat.node_tree.nodes.get("Principled BSDF")
    if b:
        b.inputs['Base Color'].default_value = col
        b.inputs['Roughness'].default_value = rough
        if emissive and 'Emission Color' in b.inputs:
            b.inputs['Emission Color'].default_value = emissive
            b.inputs['Emission Strength'].default_value = emissive_str
    return mat

mat_bark = make_mat("Mat_Bark", (0.28, 0.18, 0.11, 1.0), rough=0.92)
mat_leaves = make_mat("Mat_Leaves", (0.16, 0.32, 0.08, 1.0), rough=0.65)
mat_rind = make_mat("Mat_Rind", (0.32, 0.40, 0.12, 1.0), rough=0.85)
mat_pulp = make_mat("Mat_Pulp", (1.0, 0.65, 0.02, 1.0), rough=0.35, emissive=(1.0, 0.62, 0.02, 1.0), emissive_str=0.8)
mat_seed = make_mat("Mat_Seed", (0.65, 0.42, 0.16, 1.0), rough=0.85, emissive=(0.95, 0.70, 0.15, 1.0), emissive_str=1.2)
mat_eye = make_mat("Mat_Eye", (1.0, 0.35, 0.0, 1.0), rough=0.2, emissive=(1.0, 0.35, 0.0, 1.0), emissive_str=3.0)

# 2. Tronco Retorcido (Caryocar brasiliense)
m_trunk = bpy.data.meshes.new("Mesh_Trunk")
o_trunk = bpy.data.objects.new("Trunk", m_trunk)
bpy.context.collection.objects.link(o_trunk)

bm = bmesh.new()
rings = [
    # (z, r, ox, oy)
    (0.00, 0.48, 0.00, 0.00),
    (0.20, 0.38, 0.05, -0.04),
    (0.45, 0.30, 0.10, -0.02),
    (0.70, 0.28, 0.08, 0.04),
    (0.95, 0.30, -0.02, 0.06), # Ponto do olho
    (1.20, 0.34, -0.06, 0.02),
    (1.40, 0.38, -0.02, -0.04), # Berço do fruto
    (1.55, 0.25, 0.00, -0.02)
]
p_verts = []
num_pts = 14
for i, (z, r, ox, oy) in enumerate(rings):
    c_verts = []
    for j in range(num_pts):
        ang = (j / num_pts) * 2 * math.pi
        noise = 1.0 + 0.14 * math.sin(j * 3 + i * 2) + 0.08 * math.cos(j * 4)
        vx = ox + (r * noise) * math.cos(ang)
        vy = oy + (r * noise) * math.sin(ang)
        vz = z
        if i == 0:
            # Pés/raízes de apoio na base
            if j in [1, 4, 8, 11]:
                vx *= 1.4
                vy *= 1.4
        v = bm.verts.new((vx, vy, vz))
        c_verts.append(v)
    if p_verts:
        for j in range(num_pts):
            bm.faces.new((p_verts[j], p_verts[(j+1)%num_pts], c_verts[(j+1)%num_pts], c_verts[j]))
    p_verts = c_verts

bm.faces.new(list(reversed(bm.verts[:num_pts])))
bm.faces.new(p_verts)
bm.to_mesh(m_trunk)
bm.free()
o_trunk.data.materials.append(mat_bark)

# 3. Raízes em Garra ancoradas no solo
def add_root_claw(name, p1, p2, p3, r1, r2):
    m = bpy.data.meshes.new(f"Mesh_{name}")
    o = bpy.data.objects.new(name, m)
    bpy.context.collection.objects.link(o)
    bm_r = bmesh.new()
    for pts, r in [(p1, r1), (p2, (r1+r2)*0.5), (p3, r2)]:
        pass
    steps = 5
    pv = []
    for s in range(steps):
        t = s / (steps - 1)
        # Bezier quadrática
        pos = (1-t)**2 * p1 + 2*(1-t)*t * p2 + t**2 * p3
        cr = r1 * (1 - t) + r2 * t
        cv = []
        for j in range(8):
            ang = (j / 8) * 2 * math.pi
            cv.append(bm_r.verts.new((pos.x + cr * math.cos(ang), pos.y + cr * math.sin(ang), max(0.0, pos.z + cr * 0.4 * math.sin(ang)))))
        if pv:
            for j in range(8):
                bm_r.faces.new((pv[j], pv[(j+1)%8], cv[(j+1)%8], cv[j]))
        pv = cv
    bm_r.to_mesh(m)
    bm_r.free()
    o.data.materials.append(mat_bark)
    return o

add_root_claw("Root_FL", Vector((-0.2, 0.15, 0.25)), Vector((-0.45, 0.35, 0.15)), Vector((-0.60, 0.55, 0.0)), 0.15, 0.05)
add_root_claw("Root_FR", Vector((0.2, 0.15, 0.25)), Vector((0.45, 0.35, 0.15)), Vector((0.60, 0.55, 0.0)), 0.15, 0.05)
add_root_claw("Root_BL", Vector((-0.25, -0.15, 0.25)), Vector((-0.50, -0.35, 0.15)), Vector((-0.65, -0.50, 0.0)), 0.16, 0.06)
add_root_claw("Root_BR", Vector((0.25, -0.15, 0.25)), Vector((0.50, -0.35, 0.15)), Vector((0.65, -0.50, 0.0)), 0.16, 0.06)
add_root_claw("Root_FrontMid", Vector((0.0, 0.20, 0.20)), Vector((0.05, 0.50, 0.10)), Vector((0.0, 0.70, 0.0)), 0.14, 0.04)

# 4. Galhos / Braços Guardiões (Emoldurando o fruto frontal)
def add_branch_curve(name, pts, radii):
    m = bpy.data.meshes.new(f"Mesh_{name}")
    o = bpy.data.objects.new(name, m)
    bpy.context.collection.objects.link(o)
    bm_b = bmesh.new()
    pv = []
    for (pt, r) in zip(pts, radii):
        cv = []
        for j in range(8):
            ang = (j / 8) * 2 * math.pi
            cv.append(bm_b.verts.new((pt.x + r * math.cos(ang), pt.y + r * math.sin(ang), pt.z + r * math.sin(ang + 0.5))))
        if pv:
            for j in range(8):
                bm_b.faces.new((pv[j], pv[(j+1)%8], cv[(j+1)%8], cv[j]))
        pv = cv
    bm_b.to_mesh(m)
    bm_b.free()
    o.data.materials.append(mat_bark)
    return o

# Galho Esquerdo
b_left = [
    (Vector((-0.18, 0.0, 1.40)), 0.15),
    (Vector((-0.45, 0.08, 1.58)), 0.13),
    (Vector((-0.68, 0.22, 1.78)), 0.11),
    (Vector((-0.65, 0.38, 1.98)), 0.08),
    (Vector((-0.40, 0.42, 2.08)), 0.06),
    (Vector((-0.22, 0.32, 2.05)), 0.04)
]
add_branch_curve("Branch_Left", [p[0] for p in b_left], [p[1] for p in b_left])

# Galho Direito
b_right = [
    (Vector((0.18, 0.0, 1.40)), 0.15),
    (Vector((0.48, 0.08, 1.56)), 0.13),
    (Vector((0.70, 0.20, 1.76)), 0.11),
    (Vector((0.66, 0.36, 1.96)), 0.08),
    (Vector((0.42, 0.40, 2.06)), 0.06),
    (Vector((0.20, 0.30, 2.02)), 0.04)
]
add_branch_curve("Branch_Right", [p[0] for p in b_right], [p[1] for p in b_right])

# Galhos Dorsais / Copa
b_back_l = [
    (Vector((-0.10, -0.15, 1.45)), 0.13),
    (Vector((-0.28, -0.40, 1.72)), 0.10),
    (Vector((-0.20, -0.55, 1.98)), 0.07),
    (Vector((0.0, -0.45, 2.15)), 0.04)
]
add_branch_curve("Branch_Back_L", [p[0] for p in b_back_l], [p[1] for p in b_back_l])

b_back_r = [
    (Vector((0.10, -0.15, 1.45)), 0.13),
    (Vector((0.28, -0.38, 1.70)), 0.10),
    (Vector((0.22, -0.52, 1.95)), 0.07),
    (Vector((0.05, -0.40, 2.15)), 0.04)
]
add_branch_curve("Branch_Back_R", [p[0] for p in b_back_r], [p[1] for p in b_back_r])

# 5. Tufos de Folhagem Coriácea do Cerrado
def add_leaf_bundle(name, loc, scale):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = scale
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(mat_leaves)
    return o

add_leaf_bundle("Leaf_Top", Vector((0.0, -0.20, 2.25)), Vector((0.42, 0.35, 0.22)))
add_leaf_bundle("Leaf_L1", Vector((-0.72, 0.28, 1.88)), Vector((0.28, 0.24, 0.18)))
add_leaf_bundle("Leaf_L2", Vector((-0.38, 0.44, 2.12)), Vector((0.25, 0.22, 0.16)))
add_leaf_bundle("Leaf_R1", Vector((0.74, 0.26, 1.86)), Vector((0.28, 0.24, 0.18)))
add_leaf_bundle("Leaf_R2", Vector((0.40, 0.42, 2.10)), Vector((0.25, 0.22, 0.16)))
add_leaf_bundle("Leaf_Back", Vector((0.0, -0.55, 2.05)), Vector((0.35, 0.30, 0.20)))

# 6. O Fruto Sagrado do Pequi (Núcleo Místico Central em Destaque)
# Posicionado em Z=1.50m, frontal (Y=0.20m), bem visível e heróico
fruit_center = Vector((0.0, 0.22, 1.48))

# 6.1 Casca Verde do Pequi Aberto (Cálice côncavo virado para frente)
bpy.ops.mesh.primitive_uv_sphere_add(segments=18, ring_count=12, radius=0.38, location=fruit_center)
o_rind = bpy.context.active_object
o_rind.name = "Pequi_Rind"
o_rind.scale = (1.1, 0.85, 1.0)
bpy.ops.object.transform_apply(scale=True)
# Remover calota frontal para deixar o fruto escancarado
bm_rind = bmesh.new()
bm_rind.from_mesh(o_rind.data)
verts_cut = [v for v in bm_rind.verts if (v.co.y - fruit_center.y) > 0.05 and (v.co.z - fruit_center.z) > -0.15]
bmesh.ops.delete(bm_rind, geom=verts_cut, context='VERTS')
bm_rind.to_mesh(o_rind.data)
bm_rind.free()
o_rind.data.materials.append(mat_rind)

# 6.2 Polpa Carnosa Amarelo-Ouro (Dois lóculos robustos brilhantes)
bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.20, location=fruit_center + Vector((-0.11, 0.06, -0.02)))
p_l = bpy.context.active_object
p_l.name = "Pulp_L"
p_l.scale = (0.9, 1.15, 0.95)
bpy.ops.object.transform_apply(scale=True)
p_l.data.materials.append(mat_pulp)

bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.20, location=fruit_center + Vector((0.11, 0.06, -0.02)))
p_r = bpy.context.active_object
p_r.name = "Pulp_R"
p_r.scale = (0.9, 1.15, 0.95)
bpy.ops.object.transform_apply(scale=True)
p_r.data.materials.append(mat_pulp)

# 6.3 O Caroço Sagrado (Endocarpo Espinhoso Místico - O projétil e núcleo de poder)
seed_pos = fruit_center + Vector((0.0, 0.18, 0.08))
bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=0.15, location=seed_pos)
o_seed = bpy.context.active_object
o_seed.name = "Spike_Seed"
o_seed.data.materials.append(mat_seed)

# Espinhos cônicos procedurais bem proeminentes
bm_seed = bmesh.new()
bm_seed.from_mesh(o_seed.data)
spikes = [
    Vector((0.0, 1.0, 0.0)),
    Vector((0.6, 0.7, 0.2)),
    Vector((-0.6, 0.7, 0.2)),
    Vector((0.0, 0.6, 0.7)),
    Vector((0.0, 0.6, -0.7)),
    Vector((0.7, 0.3, 0.6)),
    Vector((-0.7, 0.3, 0.6)),
    Vector((0.7, 0.3, -0.6)),
    Vector((-0.7, 0.3, -0.6)),
    Vector((0.0, 0.9, 0.4)),
    Vector((0.4, 0.8, -0.3)),
    Vector((-0.4, 0.8, -0.3)),
]
for d in spikes:
    tip = seed_pos + d.normalized() * 0.26
    base = seed_pos + d.normalized() * 0.14
    v_tip = bm_seed.verts.new(tip)
    v1 = bm_seed.verts.new(base + Vector((0.025, 0.0, 0.0)))
    v2 = bm_seed.verts.new(base + Vector((-0.015, 0.02, 0.0)))
    v3 = bm_seed.verts.new(base + Vector((-0.015, -0.02, 0.0)))
    bm_seed.faces.new((v_tip, v1, v2))
    bm_seed.faces.new((v_tip, v2, v3))
    bm_seed.faces.new((v_tip, v3, v1))
bm_seed.to_mesh(o_seed.data)
bm_seed.free()

# 7. Olho Sentinela Místico no Tronco (Fenda em brasa âmbar)
bpy.ops.mesh.primitive_cylinder_add(radius=0.12, depth=0.18, location=Vector((0.0, 0.26, 0.95)))
o_eye = bpy.context.active_object
o_eye.name = "Sentinel_Eye"
o_eye.rotation_euler = (math.radians(90), 0, 0)
o_eye.scale = (1.5, 0.32, 1.0)
bpy.ops.object.transform_apply(rotation=True, scale=True)
o_eye.data.materials.append(mat_eye)

# Salvar o blend do blockout
output_path = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi_blockout.blend"
bpy.ops.wm.save_as_mainfile(filepath=output_path)
print(f"Blockout do Pequi v2 salvo com sucesso em: {output_path}")
