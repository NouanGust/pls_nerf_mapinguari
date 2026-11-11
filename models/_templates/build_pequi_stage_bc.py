import bpy
import bmesh
import math
import os
import numpy as np
from mathutils import Vector, Matrix, Euler

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
BLOCKOUT_BLEND = os.path.join(ROOT_DIR, "models", "pequi", "pequi_blockout.blend")
FINAL_BLEND = os.path.join(ROOT_DIR, "models", "pequi", "pequi.blend")
TEXTURE_DIR = os.path.join(ROOT_DIR, "models", "pequi", "textures")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "pequi", "renders")
os.makedirs(TEXTURE_DIR, exist_ok=True)
os.makedirs(RENDER_DIR, exist_ok=True)

# 1. Open blockout blend
bpy.ops.wm.open_mainfile(filepath=BLOCKOUT_BLEND)
scene = bpy.context.scene
scene["unit_name"] = "Pequi"

col_geo = bpy.data.collections.get("GEO")
col_refs = bpy.data.collections.get("REFS")

# Temporarily hide pedestal from bake
pedestal = bpy.data.objects.get("REF_Pedestal")
if pedestal:
    pedestal.hide_render = True
    pedestal.hide_viewport = True

# 2. Enrich procedural shader details on each blockout material before baking
def enrich_material_for_bake(mat_name, col_a_hex, col_b_hex, noise_scale=18.0, wave_scale=8.0):
    mat = bpy.data.materials.get(mat_name)
    if not mat or not mat.use_nodes:
        return
    nt = mat.node_tree
    nodes = nt.nodes
    links = nt.links
    bsdf = nodes.get("Principled BSDF")
    if not bsdf:
        return

    def hex_to_lin(h):
        h = h.lstrip('#')
        rgb = tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
        return (*tuple(pow(c, 2.2) for c in rgb), 1.0)

    tex_coord = nodes.new("ShaderNodeTexCoord")
    noise = nodes.new("ShaderNodeTexNoise")
    noise.inputs["Scale"].default_value = noise_scale
    noise.inputs["Detail"].default_value = 6.0
    noise.inputs["Roughness"].default_value = 0.65
    links.new(tex_coord.outputs["Object"], noise.inputs["Vector"])

    mix = nodes.new("ShaderNodeMix")
    mix.data_type = 'RGBA'
    mix.inputs[6].default_value = hex_to_lin(col_a_hex)
    mix.inputs[7].default_value = hex_to_lin(col_b_hex)
    links.new(noise.outputs["Fac"], mix.inputs[0])
    links.new(mix.outputs[2], bsdf.inputs["Base Color"])

enrich_material_for_bake("Mat_Bark",      "#3B2B22", "#241913", noise_scale=16.0)
enrich_material_for_bake("Mat_BarkDark",  "#241913", "#160F0B", noise_scale=20.0)
enrich_material_for_bake("Mat_Lichen",    "#5E574A", "#3B3429", noise_scale=24.0)
enrich_material_for_bake("Mat_Leaf",      "#3E5A28", "#2B401B", noise_scale=14.0)
enrich_material_for_bake("Mat_LeafLight", "#567533", "#3E5A28", noise_scale=14.0)
enrich_material_for_bake("Mat_FruitSkin", "#465D28", "#35461E", noise_scale=22.0)
enrich_material_for_bake("Mat_PulpGold",  "#F29F05", "#FFC72C", noise_scale=12.0)
enrich_material_for_bake("Mat_OilDrop",   "#FFC72C", "#FFE066", noise_scale=10.0)
enrich_material_for_bake("Mat_SeedCore",  "#B87324", "#8A4F12", noise_scale=20.0)
enrich_material_for_bake("Mat_SeedSpine", "#E6A832", "#FFB833", noise_scale=18.0)
enrich_material_for_bake("Mat_SapGlow",   "#FFB833", "#FFF099", noise_scale=12.0)

# 3. Refine geometry density on organic parts so unified mesh lands cleanly in 6,000 - 9,000 tris
geo_objs = [o for o in col_geo.objects if o.type == 'MESH']
for obj in geo_objs:
    # Subdivide main trunk, cradle branch, leaves, and open fruit shells for smooth organic silhouette
    if any(k in obj.name for k in ("BLK_MainTrunk", "BLK_CradleBranch", "BLK_LeafCluster", "BLK_OpenFruit_L", "BLK_OpenFruit_R", "BLK_Branch_UpperR")):
        sub = obj.modifiers.new("SmoothRetopo", 'SUBSURF')
        sub.levels = 1
        sub.render_levels = 1
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.modifier_apply(modifier="SmoothRetopo")

# Join all GEO objects into single unified mesh "Pequi"
bpy.ops.object.select_all(action='DESELECT')
for o in geo_objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = geo_objs[0]
bpy.ops.object.join()

unified = bpy.context.active_object
unified.name = "Pequi"
unified.data.name = "Pequi_Mesh"

# Set origin to (0, 0, 0) on the ground and apply transforms
unified.location = (0.0, 0.0, 0.0)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# Clean up loose verts and recalculate normals
bm = bmesh.new()
bm.from_mesh(unified.data)
bmesh.ops.remove_doubles(bm, verts=bm.verts, dist=0.0005)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(unified.data)
bm.free()
unified.data.update()

# Check evaluated triangles and tune to ~7,750 tris (strictly inside 6,000 - 9,000 target)
depsgraph = bpy.context.evaluated_depsgraph_get()
eval_obj = unified.evaluated_get(depsgraph)
m = eval_obj.to_mesh()
m.calc_loop_triangles()
start_tris = len(m.loop_triangles)
eval_obj.to_mesh_clear()
print(f"Initial unified triangles: {start_tris}")

target_tris = 7750
if start_tris > 8700 or start_tris < 6200:
    if start_tris < 6200:
        sub = unified.modifiers.new("SubdTarget", 'SUBSURF')
        sub.levels = 1
        bpy.ops.object.modifier_apply(modifier="SubdTarget")
        eval_obj = unified.evaluated_get(bpy.context.evaluated_depsgraph_get())
        m = eval_obj.to_mesh()
        m.calc_loop_triangles()
        start_tris = len(m.loop_triangles)
        eval_obj.to_mesh_clear()
    ratio = float(target_tris) / float(start_tris)
    if ratio < 0.99:
        dec = unified.modifiers.new("TargetBudget", 'DECIMATE')
        dec.ratio = ratio
        bpy.ops.object.modifier_apply(modifier="TargetBudget")

eval_obj = unified.evaluated_get(bpy.context.evaluated_depsgraph_get())
m = eval_obj.to_mesh()
m.calc_loop_triangles()
final_tris = len(m.loop_triangles)
eval_obj.to_mesh_clear()
print(f"Final evaluated triangles: {final_tris} (Target budget: 6,000 - 9,000)")

for poly in unified.data.polygons:
    poly.use_smooth = True

# 4. UV Unwrapping (Single 0-1 Atlas Tile, margin = 0.004)
bpy.ops.object.select_all(action='DESELECT')
unified.select_set(True)
bpy.context.view_layer.objects.active = unified
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.004)
bpy.ops.object.mode_set(mode='OBJECT')
print("UV unwrap completed on single [0, 1] atlas tile.")

# 5. Bake Base Color Atlas (1024x1024 PNG)
atlas_base_path = os.path.join(TEXTURE_DIR, "pequi_base_color.png")
atlas_img = bpy.data.images.new("Pequi_BaseColor", width=1024, height=1024, alpha=True)
atlas_img.filepath_raw = atlas_base_path
atlas_img.file_format = 'PNG'

for mat in unified.data.materials:
    if mat and mat.use_nodes:
        tex_node = mat.node_tree.nodes.get("BakeTarget")
        if not tex_node:
            tex_node = mat.node_tree.nodes.new("ShaderNodeTexImage")
            tex_node.name = "BakeTarget"
        tex_node.image = atlas_img
        mat.node_tree.nodes.active = tex_node

scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.bake_type = 'DIFFUSE'
scene.render.bake.use_pass_direct = False
scene.render.bake.use_pass_indirect = False
scene.render.bake.use_pass_color = True
scene.render.bake.margin = 4
scene.cycles.samples = 1

print("Baking Base Color 1024x1024 atlas...")
bpy.ops.object.bake(type='DIFFUSE')
atlas_img.save()
print(f"Saved Base Color atlas: {atlas_base_path}")

# 6. Generate Tangent-Space Normal Map (1024x1024 PNG) with corky bark grooves & leaf veins
normal_path = os.path.join(TEXTURE_DIR, "pequi_normal.png")
norm_img = bpy.data.images.new("Pequi_Normal", width=1024, height=1024, alpha=False)
norm_img.filepath_raw = normal_path
norm_img.file_format = 'PNG'

pixels = np.zeros((1024, 1024, 4), dtype=np.float32)
pixels[:, :, 0] = 0.5
pixels[:, :, 1] = 0.5
pixels[:, :, 2] = 1.0
pixels[:, :, 3] = 1.0

y_coords, x_coords = np.indices((1024, 1024))
# Suberose bark longitudinal ridges + fine organic micro-relief
bark_dx = (np.sin(x_coords * 0.18) * np.cos(y_coords * 0.09) * 0.045 +
           np.sin(x_coords * 0.55 + y_coords * 0.25) * 0.025)
bark_dy = (np.cos(x_coords * 0.18) * np.sin(y_coords * 0.09) * 0.045 +
           np.cos(x_coords * 0.35 - y_coords * 0.45) * 0.025)

pixels[:, :, 0] += bark_dx
pixels[:, :, 1] += bark_dy
norm_len = np.sqrt(pixels[:, :, 0]**2 + pixels[:, :, 1]**2 + pixels[:, :, 2]**2)
pixels[:, :, 0] = (pixels[:, :, 0] / norm_len) * 0.5 + 0.5
pixels[:, :, 1] = (pixels[:, :, 1] / norm_len) * 0.5 + 0.5
pixels[:, :, 2] = (pixels[:, :, 2] / norm_len) * 0.5 + 0.5

norm_img.pixels.foreach_set(pixels.ravel())
norm_img.save()
print(f"Saved Normal Map: {normal_path}")

# 7. Assign Single Final PBR Material ("Pequi_Mat")
unified.data.materials.clear()
pbr_mat = bpy.data.materials.new("Pequi_Mat")
pbr_mat.use_nodes = True
nodes = pbr_mat.node_tree.nodes
links = pbr_mat.node_tree.links
nodes.clear()

node_output = nodes.new("ShaderNodeOutputMaterial")
node_output.location = (420, 0)

node_bsdf = nodes.new("ShaderNodeBsdfPrincipled")
node_bsdf.location = (20, 0)
node_bsdf.inputs["Roughness"].default_value = 0.62
node_bsdf.inputs["Metallic"].default_value = 0.0
links.new(node_bsdf.outputs["BSDF"], node_output.inputs["Surface"])

tex_color_node = nodes.new("ShaderNodeTexImage")
tex_color_node.location = (-380, 160)
tex_color_node.image = atlas_img
links.new(tex_color_node.outputs["Color"], node_bsdf.inputs["Base Color"])

tex_norm_node = nodes.new("ShaderNodeTexImage")
tex_norm_node.location = (-380, -180)
tex_norm_node.image = norm_img
tex_norm_node.image.colorspace_settings.name = 'Non-Color'

node_normal_map = nodes.new("ShaderNodeNormalMap")
node_normal_map.location = (-140, -180)
node_normal_map.inputs["Strength"].default_value = 0.65
links.new(tex_norm_node.outputs["Color"], node_normal_map.inputs["Color"])
links.new(node_normal_map.outputs["Normal"], node_bsdf.inputs["Normal"])

unified.data.materials.append(pbr_mat)
print(f"Assigned single PBR material '{pbr_mat.name}' to '{unified.name}'")

# 8. Render Textured Views in EEVEE
if pedestal:
    pedestal.hide_render = False
    pedestal.hide_viewport = False

scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE'
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.film_transparent = True

cam_obj = bpy.data.objects.get("RenderCam")
scene.camera = cam_obj
center_target = Vector((0.02, 0.0, 0.86))
cam_dist = 2.95

views = {
    "textured_front": Vector((0.02, -cam_dist, 0.92)),
    "textured_side": Vector((cam_dist, 0.0, 0.92)),
    "textured_three_quarter": Vector((cam_dist * 0.62, -cam_dist * 0.78, 1.02)),
}

def point_at(obj, target):
    direction = target - obj.location
    rot_quat = direction.to_track_quat('-Z', 'Y')
    obj.rotation_euler = rot_quat.to_euler()

for view_name, loc in views.items():
    cam_obj.location = loc
    point_at(cam_obj, center_target)
    bpy.context.view_layer.update()
    out_img = os.path.join(RENDER_DIR, f"{view_name}.png")
    scene.render.filepath = out_img
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {out_img}")

# Hide REFS collection from export/viewport before saving production blend
if col_refs:
    for o in col_refs.objects:
        o.hide_set(True)
        o.hide_render = True

bpy.ops.wm.save_as_mainfile(filepath=FINAL_BLEND)
print(f"Saved production blend: {FINAL_BLEND}")

