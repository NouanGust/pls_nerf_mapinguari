"""
Reconstrução do Pequi baseada nas referências reais do Cerrado:
- Tronco esguio, inclinado e profundamente sinuoso/retorcido (curvatura em 'S' e cotovelos angulares).
- Bifurcações e ramificações tortuosas horizontais que descem e sobem como serpentes de madeira.
- Fruto de pequi aberto e semente de espinhos integrados organicamente na forquilha central.
- Folhagem arejada e copas nos ramos superiores.
"""

import bpy
import bmesh
import math
from mathutils import Vector, Matrix

# Limpar cena
for o in list(bpy.data.objects):
    bpy.data.objects.remove(o, do_unlink=True)
for m in list(bpy.data.meshes):
    bpy.data.meshes.remove(m, do_unlink=True)
for mat in list(bpy.data.materials):
    bpy.data.materials.remove(mat, do_unlink=True)

# 1. Materiais com tons autênticos do Pequizeiro
def make_mat(name, col, rough=0.85, emissive=None, emissive_str=1.0):
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

mat_bark = make_mat("Mat_Bark", (0.32, 0.22, 0.14, 1.0), rough=0.92) # Casca corticosa e estriada
mat_leaves = make_mat("Mat_Leaves", (0.24, 0.42, 0.10, 1.0), rough=0.6) # Verde vivo com tom amarelado
mat_rind = make_mat("Mat_Rind", (0.35, 0.45, 0.15, 1.0), rough=0.8) # Casca verde do pequi
mat_pulp = make_mat("Mat_Pulp", (1.0, 0.68, 0.0, 1.0), rough=0.35, emissive=(1.0, 0.65, 0.0, 1.0), emissive_str=0.9)
mat_seed = make_mat("Mat_Seed", (0.75, 0.50, 0.20, 1.0), rough=0.85, emissive=(1.0, 0.75, 0.2, 1.0), emissive_str=1.3)
mat_eye = make_mat("Mat_Eye", (1.0, 0.40, 0.0, 1.0), rough=0.2, emissive=(1.0, 0.40, 0.0, 1.0), emissive_str=3.5)

# Função auxiliar para gerar galhos/ramos curvos ao longo de uma spline com raio decrescente
def build_twisted_branch(mesh_name, obj_name, points_radii, sides=10, twist_factor=1.0):
    m = bpy.data.meshes.new(mesh_name)
    o = bpy.data.objects.new(obj_name, m)
    bpy.context.collection.objects.link(o)
    bm = bmesh.new()
    
    prev_verts = []
    total_pts = len(points_radii)
    
    for i, (pos, radius) in enumerate(points_radii):
        # Calcular vetor tangente
        if i < total_pts - 1:
            tangent = (points_radii[i+1][0] - pos).normalized()
        else:
            tangent = (pos - points_radii[i-1][0]).normalized()
            
        up = Vector((0, 0, 1)) if abs(tangent.z) < 0.85 else Vector((1, 0, 0))
        normal = tangent.cross(up).normalized()
        binormal = tangent.cross(normal).normalized()
        
        curr_verts = []
        twist = i * 0.4 * twist_factor
        for j in range(sides):
            angle = (j / sides) * 2 * math.pi + twist
            # Irregularidade orgânica da casca
            bark_noise = 1.0 + 0.12 * math.sin(j * 3 + i * 2) + 0.06 * math.cos(j * 5)
            r = radius * bark_noise
            offset = (normal * math.cos(angle) + binormal * math.sin(angle)) * r
            v = bm.verts.new(pos + offset)
            curr_verts.append(v)
            
        if prev_verts:
            for j in range(sides):
                bm.faces.new((prev_verts[j], prev_verts[(j+1)%sides], curr_verts[(j+1)%sides], curr_verts[j]))
        prev_verts = curr_verts
        
    # Fechar pontas
    bm.faces.new(list(reversed(bm.verts[:sides])))
    bm.faces.new(prev_verts)
    
    bm.to_mesh(m)
    bm.free()
    o.data.materials.append(mat_bark)
    return o

# 2. Tronco Principal do Pequi (Inclinado, retorcido em S, mais fino e tortuoso)
# Base firme no solo em Z=0, curvando acentuadamente para a direita/traseira e depois subindo em cotovelo
trunk_spine = [
    (Vector((0.00,  0.00, 0.00)), 0.28), # Solo
    (Vector((0.05, -0.05, 0.20)), 0.23),
    (Vector((0.18, -0.08, 0.45)), 0.20),
    (Vector((0.32, -0.02, 0.70)), 0.18), # Cotovelo inferior característico da foto 2
    (Vector((0.38,  0.10, 0.95)), 0.17),
    (Vector((0.26,  0.16, 1.20)), 0.16), # Curva de retorno
    (Vector((0.08,  0.12, 1.40)), 0.16), # Forquilha central onde surge o fruto e bifurcam os ramos
]
o_trunk = build_twisted_branch("Mesh_Trunk", "Trunk", trunk_spine, sides=12)

# Raízes superficiais que brotam do solo
roots = [
    # (posicoes, raios)
    [(Vector((0.00, 0.00, 0.08)), 0.20), (Vector((-0.25, 0.20, 0.02)), 0.12), (Vector((-0.45, 0.35, 0.00)), 0.04)],
    [(Vector((0.00, 0.00, 0.08)), 0.18), (Vector((0.25, -0.22, 0.02)), 0.11), (Vector((0.48, -0.38, 0.00)), 0.03)],
    [(Vector((0.00, 0.00, 0.08)), 0.18), (Vector((-0.20, -0.25, 0.02)), 0.10), (Vector((-0.38, -0.42, 0.00)), 0.03)],
]
for idx, r_pts in enumerate(roots):
    build_twisted_branch(f"Mesh_Root_{idx}", f"Root_{idx}", r_pts, sides=8)

# 3. Grande Galho Horizontal Esquerdo (O "braço serpenteante" que desce quase ao solo e sobe, igual à foto 1)
branch_left_arm = [
    (Vector((0.08,  0.12, 1.38)), 0.14),
    (Vector((-0.22, 0.08, 1.25)), 0.12),
    (Vector((-0.52, 0.00, 1.05)), 0.11), # Desce em cotovelo
    (Vector((-0.78, 0.10, 0.85)), 0.09), # Ponto mais baixo
    (Vector((-0.95, 0.28, 0.95)), 0.07), # Arqueia para cima
    (Vector((-1.05, 0.42, 1.15)), 0.05),
    (Vector((-1.00, 0.55, 1.35)), 0.03),
]
build_twisted_branch("Mesh_Branch_Arm_L", "Branch_Arm_L", branch_left_arm, sides=10)

# Sub-ramo que brota do braço esquerdo para cima
sub_branch_l = [
    (Vector((-0.52, 0.00, 1.05)), 0.08),
    (Vector((-0.60, -0.15, 1.35)), 0.06),
    (Vector((-0.50, -0.25, 1.65)), 0.04),
    (Vector((-0.55, -0.20, 1.90)), 0.025),
]
build_twisted_branch("Mesh_Sub_L", "Sub_L", sub_branch_l, sides=8)

# 4. Grande Galho Direito / Superior (Curva e abre a copa para a direita e para o topo)
branch_right = [
    (Vector((0.08, 0.12, 1.42)), 0.14),
    (Vector((0.35, 0.15, 1.55)), 0.12),
    (Vector((0.65, 0.05, 1.70)), 0.10),
    (Vector((0.85, -0.10, 1.85)), 0.08),
    (Vector((0.95, -0.05, 2.05)), 0.06),
    (Vector((0.80, 0.12, 2.25)), 0.04),
    (Vector((0.65, 0.22, 2.40)), 0.025),
]
build_twisted_branch("Mesh_Branch_R", "Branch_R", branch_right, sides=10)

# Ramo Superior Central (Continuação da forquilha que vai para o topo)
branch_top = [
    (Vector((0.08, 0.12, 1.42)), 0.13),
    (Vector((0.02, 0.05, 1.70)), 0.10),
    (Vector((-0.08, -0.12, 1.98)), 0.08),
    (Vector((0.05, -0.18, 2.25)), 0.06),
    (Vector((0.15, -0.08, 2.48)), 0.035),
]
build_twisted_branch("Mesh_Branch_Top", "Branch_Top", branch_top, sides=9)

# 5. Folhagem Estilizada Orgânica em Clusters Arejados (Copa típica do Pequizeiro)
def add_leaf_fan(name, loc, sc):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=8, ring_count=6, radius=1.0, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = sc
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(mat_leaves)
    return o

# Clusters de folhas nas pontas dos galhos retorcidos
leaf_clusters = [
    ("Leaf_L_End",   Vector((-1.00,  0.55, 1.40)), Vector((0.32, 0.28, 0.16))),
    ("Leaf_L_Mid",   Vector((-0.80,  0.20, 1.05)), Vector((0.26, 0.22, 0.14))),
    ("Leaf_L_Top",   Vector((-0.55, -0.20, 1.95)), Vector((0.30, 0.25, 0.18))),
    ("Leaf_R_Mid",   Vector((0.70,   0.00, 1.80)), Vector((0.30, 0.26, 0.16))),
    ("Leaf_R_Top",   Vector((0.65,   0.22, 2.45)), Vector((0.34, 0.28, 0.18))),
    ("Leaf_R_Far",   Vector((0.95,  -0.05, 2.10)), Vector((0.28, 0.24, 0.15))),
    ("Leaf_Crown",   Vector((0.15,  -0.08, 2.52)), Vector((0.38, 0.32, 0.20))),
    ("Leaf_Crown_L", Vector((-0.10, -0.15, 2.10)), Vector((0.32, 0.26, 0.16))),
]
for l_name, l_pos, l_sc in leaf_clusters:
    add_leaf_fan(l_name, l_pos, l_sc)

# 6. O Fruto de Pequi Aberto (Encaixado na forquilha central Z=1.35m a 1.45m)
fruit_pos = Vector((0.08, 0.28, 1.35))

# Casca em cálice côncavo
m_rind = bpy.data.meshes.new("Mesh_Pequi_Rind")
o_rind = bpy.data.objects.new("Pequi_Rind", m_rind)
bpy.context.collection.objects.link(o_rind)
bm_r = bmesh.new()
u_s, v_s = 14, 8
rad = 0.34
grid = []
for v in range(v_s):
    phi = (v / (v_s - 1)) * (math.pi * 0.62)
    row = []
    for u in range(u_s):
        theta = (u / u_s) * 2 * math.pi
        rx = rad * math.sin(phi) * math.cos(theta)
        ry = -rad * math.cos(phi) * 0.75 + 0.12
        rz = rad * math.sin(phi) * math.sin(theta) * 0.95
        row.append(bm_r.verts.new(fruit_pos + Vector((rx, ry, rz))))
    grid.append(row)

for v in range(v_s - 1):
    for u in range(u_s):
        bm_r.faces.new((grid[v][u], grid[v][(u+1)%u_s], grid[v+1][(u+1)%u_s], grid[v+1][u]))
bm_r.to_mesh(m_rind)
bm_r.free()
o_rind.data.materials.append(mat_rind)

# Polpa amarela dos 2 caroços (arilos)
def add_pulp(name, loc, sc):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.17, location=loc)
    o = bpy.context.active_object
    o.name = name
    o.scale = sc
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(mat_pulp)
    return o

add_pulp("Pulp_L", fruit_pos + Vector((-0.09, 0.09, -0.03)), Vector((0.85, 1.05, 0.85)))
add_pulp("Pulp_R", fruit_pos + Vector((0.09, 0.09, -0.03)), Vector((0.85, 1.05, 0.85)))

# Caroço sagrado de espinhos (Endocarpo ameaçador em destaque frontal)
seed_center = fruit_pos + Vector((0.0, 0.24, 0.08))
m_seed = bpy.data.meshes.new("Mesh_Spike_Seed")
o_seed = bpy.data.objects.new("Spike_Seed", m_seed)
bpy.context.collection.objects.link(o_seed)
bm_s = bmesh.new()
bmesh.ops.create_uvsphere(bm_s, u_segments=12, v_segments=8, radius=0.12)
for v in bm_s.verts:
    v.co += seed_center

spikes = [
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
]
for d in spikes:
    d_norm = d.normalized()
    tip = seed_center + d_norm * 0.24
    base = seed_center + d_norm * 0.11
    up = Vector((0, 0, 1)) if abs(d_norm.z) < 0.9 else Vector((1, 0, 0))
    side = d_norm.cross(up).normalized() * 0.02
    ortho = d_norm.cross(side).normalized() * 0.02
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

# 7. Olho Sentinela na fenda da casca do tronco (Z=0.85m)
bpy.ops.mesh.primitive_cylinder_add(radius=0.08, depth=0.14, location=Vector((0.34, 0.08, 0.85)))
o_eye = bpy.context.active_object
o_eye.name = "Sentinel_Eye"
o_eye.rotation_euler = (math.radians(90), 0, math.radians(20))
o_eye.scale = (1.4, 0.35, 1.0)
bpy.ops.object.transform_apply(rotation=True, scale=True)
o_eye.data.materials.append(mat_eye)

output_path = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi_blockout.blend"
bpy.ops.wm.save_as_mainfile(filepath=output_path)
print(f"Pequi retorcido autêntico salvo em: {output_path}")

