"""
Refinamento da modelagem da Drupa de Pequi e do Caroço de Espinhos:
- Cria a casca verde externa aberta em cálice
- Duas metades de polpa amarela carnosa (arilo)
- Um caroço de espinhos destacado na frente com agulhas cônicas visíveis
"""

import bpy
import bmesh
import math
from mathutils import Vector

# Remover objetos antigos de fruto/semente
for name in ["Pequi_Rind", "Pulp_L", "Pulp_R", "Spike_Seed"]:
    obj = bpy.data.objects.get(name)
    if obj:
        bpy.data.objects.remove(obj, do_unlink=True)

mat_rind = bpy.data.materials.get("Mat_Rind")
mat_pulp = bpy.data.materials.get("Mat_Pulp")
mat_seed = bpy.data.materials.get("Mat_Seed")

center = Vector((0.0, 0.22, 1.48))

# 1. Casca externa (Drupa aberta em taça)
m_rind = bpy.data.meshes.new("Mesh_Pequi_Rind")
o_rind = bpy.data.objects.new("Pequi_Rind", m_rind)
bpy.context.collection.objects.link(o_rind)

bm_r = bmesh.new()
# Concha hemisférica aberta para frente (+Y)
u_steps = 14
v_steps = 8
radius = 0.40
grid_verts = []
for v in range(v_steps):
    v_phi = (v / (v_steps - 1)) * (math.pi * 0.65) # de trás para a borda frontal
    row = []
    for u in range(u_steps):
        u_theta = (u / u_steps) * 2 * math.pi
        rx = radius * math.sin(v_phi) * math.cos(u_theta)
        # Mais profundo atrás (-Y) e abrindo na frente
        ry = -radius * math.cos(v_phi) * 0.75 + 0.15
        rz = radius * math.sin(v_phi) * math.sin(u_theta) * 0.95
        vert = bm_r.verts.new(center + Vector((rx, ry, rz)))
        row.append(vert)
    grid_verts.append(row)

for v in range(v_steps - 1):
    for u in range(u_steps):
        v1 = grid_verts[v][u]
        v2 = grid_verts[v][(u + 1) % u_steps]
        v3 = grid_verts[v + 1][(u + 1) % u_steps]
        v4 = grid_verts[v + 1][u]
        bm_r.faces.new((v1, v2, v3, v4))

bm_r.to_mesh(m_rind)
bm_r.free()
o_rind.data.materials.append(mat_rind)

# 2. Polpa amarela dos dois caroços (arilos arredondados)
def add_pulp_lobe(name, loc, sc):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.20, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = sc
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(mat_pulp)
    return o

add_pulp_lobe("Pulp_L", center + Vector((-0.12, 0.12, -0.04)), Vector((0.9, 1.1, 0.9)))
add_pulp_lobe("Pulp_R", center + Vector((0.12, 0.12, -0.04)), Vector((0.9, 1.1, 0.9)))

# 3. Caroço Sagrado de Espinhos (Endocarpo ameaçador em destaque)
seed_center = center + Vector((0.0, 0.32, 0.12))
m_seed = bpy.data.meshes.new("Mesh_Spike_Seed")
o_seed = bpy.data.objects.new("Spike_Seed", m_seed)
bpy.context.collection.objects.link(o_seed)

bm_s = bmesh.new()
# Esfera central do endocarpo
bmesh.ops.create_uvsphere(bm_s, u_segments=12, v_segments=8, radius=0.14)
# Deslocar para a posição da semente
for v in bm_s.verts:
    v.co += seed_center

# Espinhos pontiagudos em múltiplas direções
spike_dirs = [
    Vector((0.0, 1.0, 0.0)),
    Vector((0.5, 0.8, 0.3)),
    Vector((-0.5, 0.8, 0.3)),
    Vector((0.0, 0.8, 0.6)),
    Vector((0.0, 0.8, -0.5)),
    Vector((0.7, 0.4, 0.5)),
    Vector((-0.7, 0.4, 0.5)),
    Vector((0.7, 0.4, -0.4)),
    Vector((-0.7, 0.4, -0.4)),
    Vector((0.0, 1.0, 0.3)),
    Vector((0.3, 0.9, -0.2)),
    Vector((-0.3, 0.9, -0.2)),
    Vector((0.0, 0.2, 1.0)),
    Vector((0.8, 0.0, 0.2)),
    Vector((-0.8, 0.0, 0.2)),
]

for d in spike_dirs:
    d_norm = d.normalized()
    tip = seed_center + d_norm * 0.28
    base = seed_center + d_norm * 0.13
    
    # Vetores ortogonais para a base do espinho
    up = Vector((0, 0, 1)) if abs(d_norm.z) < 0.9 else Vector((1, 0, 0))
    side = d_norm.cross(up).normalized() * 0.025
    ortho = d_norm.cross(side).normalized() * 0.025
    
    v_tip = bm_s.verts.new(tip)
    v1 = bm_s.verts.new(base + side)
    v2 = bm_s.verts.new(base - side * 0.5 + ortho * 0.86)
    v3 = bm_s.verts.new(base - side * 0.5 - ortho * 0.86)
    
    bm_s.faces.new((v_tip, v1, v2))
    bm_s.faces.new((v_tip, v2, v3))
    bm_s.faces.new((v_tip, v3, v1))

bm_s.to_mesh(m_seed)
bm_s.free()
o_seed.data.materials.append(mat_seed)

bpy.ops.wm.save_as_mainfile(filepath="C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi_blockout.blend")

