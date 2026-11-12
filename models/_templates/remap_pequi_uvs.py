"""
Mapeia precisamente as UVs de acordo com a orientação da imagem do Atlas:
Em Blender UVs: V=0 é a base inferior da imagem (Y=1024 no Pillow) e V=1 é o topo da imagem (Y=0 no Pillow).
Portanto:
Pillow [Y: 0..256]    -> Blender V in [0.75, 1.0]
Pillow [Y: 256..512]  -> Blender V in [0.50, 0.75]
Pillow [Y: 512..1024] -> Blender V in [0.0, 0.50]
"""

import bpy
import bmesh
import math
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath="C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi_blockout.blend")

# Mapeamento exato de UVs no espaço Blender (U: 0..1, V: 0..1):
# Bark:   U in [0.05, 0.45], V in [0.55, 0.95]
# Rind:   U in [0.05, 0.45], V in [0.05, 0.45]
# Leaves: U in [0.55, 0.95], V in [0.05, 0.45]
# Eye:    U in [0.55, 0.95], V in [0.55, 0.70]
# Pulp:   U in [0.55, 0.72], V in [0.78, 0.95]
# Seed:   U in [0.78, 0.95], V in [0.78, 0.95]

quadrants = {
    "bark":   (0.05, 0.55, 0.40, 0.40),
    "rind":   (0.05, 0.05, 0.40, 0.40),
    "leaves": (0.55, 0.05, 0.40, 0.40),
    "eye":    (0.55, 0.55, 0.40, 0.15),
    "pulp":   (0.55, 0.78, 0.17, 0.17),
    "seed":   (0.78, 0.78, 0.17, 0.17),
}

mesh_objs = [o for o in list(bpy.data.objects) if o.type == 'MESH']

for o in mesh_objs:
    n = o.name.lower()
    q_key = "bark"
    if "leaf" in n:
        q_key = "leaves"
    elif "rind" in n:
        q_key = "rind"
    elif "pulp" in n:
        q_key = "pulp"
    elif "seed" in n or "spike" in n:
        q_key = "seed"
    elif "eye" in n:
        q_key = "eye"
        
    u_min, v_min, u_sz, v_sz = quadrants[q_key]
    
    bm = bmesh.new()
    bm.from_mesh(o.data)
    uv_layer = bm.loops.layers.uv.verify()
    
    for f in bm.faces:
        for l in f.loops:
            v_co = l.vert.co
            u_norm = (math.atan2(v_co.x, v_co.y) / (2 * math.pi) + 0.5) % 1.0
            v_norm = (v_co.z % 1.0)
            l[uv_layer].uv.x = u_min + u_norm * u_sz
            l[uv_layer].uv.y = v_min + v_norm * v_sz
            
    bm.to_mesh(o.data)
    bm.free()

bpy.ops.object.select_all(action='DESELECT')
for o in mesh_objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = mesh_objs[0]
bpy.ops.object.join()

pequi_obj = bpy.context.active_object
pequi_obj.name = "Pequi"
pequi_obj.data.shade_smooth()

# Configurar Material PBR
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

prod_blend = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi.blend"
bpy.ops.wm.save_as_mainfile(filepath=prod_blend)
print("Pequi UV remapeado com alinhamento correto!")
