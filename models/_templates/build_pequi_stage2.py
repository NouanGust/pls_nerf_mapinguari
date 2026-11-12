"""
Etapa 2 — Unificação, UV Mapping por Regiões no Atlas e Configuração PBR no Blender (Robusto)
"""

import bpy
import bmesh
import math
from mathutils import Vector

# Abrir o blockout aprovado
bpy.ops.wm.open_mainfile(filepath="C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi_blockout.blend")

mesh_objs = [o for o in list(bpy.data.objects) if o.type == 'MESH']
print(f"Objetos encontrados: {[o.name for o in mesh_objs]}")

# 1. Unir todas as malhas primeiro para ter um único contexto sólido
bpy.ops.object.select_all(action='DESELECT')
for o in mesh_objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = mesh_objs[0]
bpy.ops.object.join()

pequi_obj = bpy.context.active_object
pequi_obj.name = "Pequi"

# 2. Desembrulho UV único
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.remove_doubles(threshold=0.001)
bpy.ops.mesh.delete_loose()
bpy.ops.uv.smart_project(angle_limit=math.radians(66.0), island_margin=0.015)
bpy.ops.object.mode_set(mode='OBJECT')
pequi_obj.data.shade_smooth()

# 3. Mapear cada face para a região correta da textura com base na posição e características
bm = bmesh.new()
bm.from_mesh(pequi_obj.data)
uv_layer = bm.loops.layers.uv.verify()

# Centro do fruto para identificação
fruit_center = Vector((0.08, 0.28, 1.35))
eye_center = Vector((0.34, 0.08, 0.85))

quadrants = {
    "bark":   (0.02, 0.52, 0.46, 0.46),
    "leaves": (0.52, 0.52, 0.46, 0.46),
    "rind":   (0.02, 0.02, 0.46, 0.46),
    "pulp":   (0.52, 0.27, 0.21, 0.21),
    "seed":   (0.77, 0.27, 0.21, 0.21),
    "eye":    (0.52, 0.02, 0.46, 0.21),
}

for face in bm.faces:
    center = face.calc_center_median()
    # Classificar região
    dist_fruit = (center - fruit_center).length
    dist_eye = (center - eye_center).length
    
    if dist_eye < 0.15:
        q_key = "eye"
    elif dist_fruit < 0.22 and center.y > 0.40:
        q_key = "seed"
    elif dist_fruit < 0.25 and center.z > 1.25 and center.y > 0.28:
        q_key = "pulp"
    elif dist_fruit < 0.42 and center.y > 0.15 and center.z > 1.15:
        q_key = "rind"
    elif center.z > 1.80 or (center.x < -0.6 and center.z > 1.0) or (center.x > 0.6 and center.z > 1.6):
        # Folhas nas pontas
        q_key = "leaves"
    else:
        q_key = "bark"
        
    u_min, v_min, u_sz, v_sz = quadrants[q_key]
    
    # Encolher UV da face para dentro do quadrante correto
    for loop in face.loops:
        # Normalizar UV existente na ilha para o quadrante
        curr_uv = loop[uv_layer].uv
        loop[uv_layer].uv.x = u_min + (curr_uv.x % 1.0) * u_sz
        loop[uv_layer].uv.y = v_min + (curr_uv.y % 1.0) * v_sz

bm.to_mesh(pequi_obj.data)
bm.free()

tri_count = sum(len(f.vertices) - 2 for f in pequi_obj.data.polygons)
print(f"Pequi unificado: {len(pequi_obj.data.vertices)} vértices, {tri_count} triângulos.")

# 4. Configurar o Material PBR Único
mat_pbr = bpy.data.materials.new("Pequi_Mat")
mat_pbr.use_nodes = True
nodes = mat_pbr.node_tree.nodes
links = mat_pbr.node_tree.links
nodes.clear()

node_output = nodes.new('ShaderNodeOutputMaterial')
node_bsdf = nodes.new('ShaderNodeBsdfPrincipled')
node_tex_bc = nodes.new('ShaderNodeTexImage')
node_tex_norm = nodes.new('ShaderNodeTexImage')
node_norm_map = nodes.new('ShaderNodeNormalMap')

bc_path = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/textures/pequi_base_color.png"
norm_path = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/textures/pequi_normal.png"

img_bc = bpy.data.images.load(bc_path)
node_tex_bc.image = img_bc

img_norm = bpy.data.images.load(norm_path)
img_norm.colorspace_settings.name = 'Non-Color'
node_tex_norm.image = img_norm

links.new(node_tex_bc.outputs['Color'], node_bsdf.inputs['Base Color'])
links.new(node_tex_norm.outputs['Color'], node_norm_map.inputs['Color'])
links.new(node_norm_map.outputs['Normal'], node_bsdf.inputs['Normal'])
links.new(node_bsdf.outputs['BSDF'], node_output.inputs['Surface'])

if 'Emission Color' in node_bsdf.inputs:
    links.new(node_tex_bc.outputs['Color'], node_bsdf.inputs['Emission Color'])
    node_bsdf.inputs['Emission Strength'].default_value = 0.35
node_bsdf.inputs['Roughness'].default_value = 0.85

pequi_obj.data.materials.clear()
pequi_obj.data.materials.append(mat_pbr)

# Salvar o blend de produção
prod_blend = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi.blend"
bpy.ops.wm.save_as_mainfile(filepath=prod_blend)
print(f"Pequi PBR salvo com sucesso em: {prod_blend}")
