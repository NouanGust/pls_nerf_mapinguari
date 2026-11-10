import bpy
import bmesh
import math
import os
import numpy as np
from mathutils import Vector, Matrix, Euler

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
BLOCKOUT_BLEND = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "comadre_fulozinha_blockout.blend")
FINAL_BLEND = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "comadre_fulozinha.blend")
TEXTURE_DIR = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "textures")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "renders")
os.makedirs(TEXTURE_DIR, exist_ok=True)
os.makedirs(RENDER_DIR, exist_ok=True)

# 1. Open refined blockout blend
bpy.ops.wm.open_mainfile(filepath=BLOCKOUT_BLEND)
scene = bpy.context.scene

# Remove helper pedestal from geometry processing
pedestal = bpy.data.objects.get("FloorPedestal")
if pedestal:
    bpy.data.objects.remove(pedestal, do_unlink=True)

# Convert all curves in GEO and PROPS into meshes
for obj in list(scene.objects):
    if obj.type == 'CURVE':
        bpy.ops.object.select_all(action='DESELECT')
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.convert(target='MESH')
        print(f"Converted curve to mesh: {obj.name}")

# Collect all character mesh objects
char_objs = [o for o in scene.objects if o.type == 'MESH']
print(f"Total mesh parts to unify: {len(char_objs)}")

# Unify into single character mesh
bpy.ops.object.select_all(action='DESELECT')
for o in char_objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = char_objs[0]
bpy.ops.object.join()
unified = bpy.context.active_object
unified.name = "ComadreFulozinha"

# Apply all transforms
unified.location = (0, 0, 0)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# 2. Check and decimate to target budget (6,000 - 9,000 tris)
depsgraph = bpy.context.evaluated_depsgraph_get()
eval_obj = unified.evaluated_get(depsgraph)
m = eval_obj.to_mesh()
m.calc_loop_triangles()
start_tris = len(m.loop_triangles)
eval_obj.to_mesh_clear()
print(f"Initial unified triangles: {start_tris}")

target_ratio = 7800.0 / start_tris if start_tris > 8800 else 1.0
if target_ratio < 0.98:
    dec = unified.modifiers.new("TargetBudget", 'DECIMATE')
    dec.ratio = target_ratio
    bpy.ops.object.modifier_apply(modifier="TargetBudget")

eval_obj = unified.evaluated_get(depsgraph)
m = eval_obj.to_mesh()
m.calc_loop_triangles()
final_tris = len(m.loop_triangles)
eval_obj.to_mesh_clear()
print(f"Final retopo triangles: {final_tris} (Target spec budget: 6,000 - 9,000 tris)")

# Recalculate normals
bm = bmesh.new()
bm.from_mesh(unified.data)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(unified.data)
bm.free()
unified.data.update()

# 3. UV Unwrapping (Single 0-1 Tile)
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.005)
bpy.ops.object.mode_set(mode='OBJECT')
print("UV unwrapped with 0.005 island margin.")

# 4. Bake Diffuse Color Texture Atlas (1024x1024)
atlas_base_path = os.path.join(TEXTURE_DIR, "comadre_fulozinha_base_color.png")
atlas_img = bpy.data.images.new("Fulozinha_BaseColor", width=1024, height=1024, alpha=True)
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

print("Baking Base Color atlas...")
bpy.ops.object.bake(type='DIFFUSE')
atlas_img.save()
print(f"Base Color atlas saved: {atlas_base_path}")

# 5. Generate Tangent-Space Normal Map (1024x1024)
normal_path = os.path.join(TEXTURE_DIR, "comadre_fulozinha_normal.png")
norm_img = bpy.data.images.new("Fulozinha_Normal", width=1024, height=1024, alpha=False)
norm_img.filepath_raw = normal_path
norm_img.file_format = 'PNG'

# Neutral normal (0.5, 0.5, 1.0)
pixels = np.zeros((1024, 1024, 4), dtype=np.float32)
pixels[:, :, 0] = 0.5
pixels[:, :, 1] = 0.5
pixels[:, :, 2] = 1.0
pixels[:, :, 3] = 1.0

# Add organic leaf / bark / hair stylized micro-noise
y_coords, x_coords = np.indices((1024, 1024))
bark_wave_x = np.sin(x_coords * 0.22) * np.cos(y_coords * 0.22) * 0.035
bark_wave_y = np.cos(x_coords * 0.22) * np.sin(y_coords * 0.22) * 0.035

pixels[:, :, 0] += bark_wave_x
pixels[:, :, 1] += bark_wave_y
norm_len = np.sqrt(pixels[:, :, 0]**2 + pixels[:, :, 1]**2 + pixels[:, :, 2]**2)
pixels[:, :, 0] /= norm_len
pixels[:, :, 1] /= norm_len
pixels[:, :, 2] /= norm_len
pixels[:, :, 0] = pixels[:, :, 0] * 0.5 + 0.5
pixels[:, :, 1] = pixels[:, :, 1] * 0.5 + 0.5
pixels[:, :, 2] = pixels[:, :, 2] * 0.5 + 0.5

norm_img.pixels.foreach_set(pixels.ravel())
norm_img.save()
print(f"Normal Map saved: {normal_path}")

# 6. Setup Single Final PBR Material (Fulozinha_Mat)
unified.data.materials.clear()
pbr_mat = bpy.data.materials.new("Fulozinha_Mat")
pbr_mat.use_nodes = True
nodes = pbr_mat.node_tree.nodes
links = pbr_mat.node_tree.links
nodes.clear()

node_output = nodes.new("ShaderNodeOutputMaterial")
node_output.location = (400, 0)

node_bsdf = nodes.new("ShaderNodeBsdfPrincipled")
node_bsdf.location = (0, 0)
node_bsdf.inputs["Roughness"].default_value = 0.52
node_bsdf.inputs["Metallic"].default_value = 0.02
links.new(node_bsdf.outputs["BSDF"], node_output.inputs["Surface"])

# Base Color texture node
tex_color_node = nodes.new("ShaderNodeTexImage")
tex_color_node.location = (-400, 150)
tex_color_node.image = atlas_img
links.new(tex_color_node.outputs["Color"], node_bsdf.inputs["Base Color"])

# Normal Map node
tex_norm_node = nodes.new("ShaderNodeTexImage")
tex_norm_node.location = (-400, -200)
tex_norm_node.image = norm_img
tex_norm_node.image.colorspace_settings.name = 'Non-Color'

node_normal_map = nodes.new("ShaderNodeNormalMap")
node_normal_map.location = (-150, -200)
node_normal_map.inputs["Strength"].default_value = 0.60
links.new(tex_norm_node.outputs["Color"], node_normal_map.inputs["Color"])
links.new(node_normal_map.outputs["Normal"], node_bsdf.inputs["Normal"])

unified.data.materials.append(pbr_mat)
print(f"Assigned single PBR material: {pbr_mat.name} to {unified.name}")

# 7. Save Production Model Blend
bpy.ops.wm.save_as_mainfile(filepath=FINAL_BLEND)
print(f"Saved production blend file to: {FINAL_BLEND}")

# 8. Render Textured Validation Views in EEVEE
scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE'
scene.render.resolution_x = 1000
scene.render.resolution_y = 1000
scene.render.film_transparent = True

cam_obj = bpy.data.objects.get("RenderCam")
if not cam_obj:
    cam_data = bpy.data.cameras.new("RenderCam")
    cam_data.lens = 65
    cam_obj = bpy.data.objects.new("RenderCam", cam_data)
    scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

center_target = Vector((0.0, 0.0, 0.72))
cam_dist = 2.6

views = {
    "textured_front": Vector((0, -cam_dist, 0.82)),
    "textured_side": Vector((cam_dist, 0, 0.82)),
    "textured_three_quarter": Vector((cam_dist * 0.707, -cam_dist * 0.707, 0.90)),
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

# 9. Composite Textured Presentation Sheet
from PIL import Image, ImageDraw, ImageFont

sheet_w, sheet_h = 2560, 800
sheet = Image.new("RGBA", (sheet_w, sheet_h), (16, 14, 18, 255))
draw = ImageDraw.Draw(sheet)

font_path = r"C:\Windows\Fonts\segoeui.ttf"
font_bold_path = r"C:\Windows\Fonts\segoeuib.ttf"
try:
    font_title = ImageFont.truetype(font_bold_path, 24)
    font_label = ImageFont.truetype(font_bold_path, 15)
except Exception:
    font_title = font_label = ImageFont.load_default()

title = "COMADRE FULOZINHA — VALIDAÇÃO TEXTURIZADA PBR (ETAPAS B & C)"
draw.text((60, 25), title, fill=(245, 240, 235, 255), font=font_title)

CONCEPT_PATH = os.path.join(ROOT_DIR, "art", "concepts", "comadre_fulozinha", "comadre_fulozinha_splash.jpg")
panels = [
    ("1. CONCEITO ORIGINAL (LORE)", CONCEPT_PATH),
    ("2. TEXTURIZADO FRENTE", os.path.join(RENDER_DIR, "textured_front.png")),
    ("3. TEXTURIZADO 3/4", os.path.join(RENDER_DIR, "textured_three_quarter.png")),
    ("4. ATLAS PBR (BASE COLOR 1K)", atlas_base_path),
]

slot_w = 580
slot_h = 680
start_x = 60
y_pos = 75

for i, (label, fpath) in enumerate(panels):
    x = start_x + i * (slot_w + 25)
    draw.rectangle([x, y_pos, x + slot_w, y_pos + slot_h], fill=(24, 21, 26, 255), outline=(48, 42, 52, 255), width=2)
    draw.rectangle([x, y_pos, x + slot_w, y_pos + 38], fill=(36, 31, 39, 255))
    draw.text((x + 16, y_pos + 10), label, fill=(225, 220, 212, 255), font=font_label)
    
    if os.path.exists(fpath):
        img = Image.open(fpath).convert("RGBA")
        img.thumbnail((slot_w - 20, slot_h - 55), Image.Resampling.LANCZOS)
        offset_x = x + (slot_w - img.width) // 2
        offset_y = y_pos + 42 + (slot_h - 55 - img.height) // 2
        sheet.alpha_composite(img, (offset_x, offset_y))

pres_path = os.path.join(RENDER_DIR, "textured_presentation.png")
sheet.save(pres_path)
print(f"Presentation sheet saved: {pres_path}")

