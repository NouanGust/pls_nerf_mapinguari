import bpy
import bmesh
import math
import os
import numpy as np
from mathutils import Vector, Matrix, Euler

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
BLOCKOUT_BLEND = os.path.join(ROOT_DIR, "models", "mae_dagua", "mae_dagua_blockout.blend")
FINAL_BLEND = os.path.join(ROOT_DIR, "models", "mae_dagua", "mae_dagua.blend")
TEXTURE_DIR = os.path.join(ROOT_DIR, "models", "mae_dagua", "textures")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "mae_dagua", "renders")
os.makedirs(TEXTURE_DIR, exist_ok=True)
os.makedirs(RENDER_DIR, exist_ok=True)

# 1. Open the refined blockout blend
bpy.ops.wm.open_mainfile(filepath=BLOCKOUT_BLEND)
scene = bpy.context.scene

geo_col = bpy.data.collections.get("GEO")
mesh_objs = [o for o in geo_col.objects if o.type == 'MESH']
print(f"Loaded {len(mesh_objs)} objects from GEO.")

# 2. Unify into single character mesh
bpy.ops.object.select_all(action='DESELECT')
for o in mesh_objs:
    o.select_set(True)
bpy.context.view_layer.objects.active = mesh_objs[0]
bpy.ops.object.join()
unified = bpy.context.active_object
unified.name = "MaeDagua"

# Ensure origin is at (0, 0, 0)
unified.location = (0, 0, 0)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

# 3. Decimate to technical budget target (6,000 - 9,000 tris)
depsgraph = bpy.context.evaluated_depsgraph_get()
eval_obj = unified.evaluated_get(depsgraph)
m = eval_obj.to_mesh()
m.calc_loop_triangles()
start_tris = len(m.loop_triangles)
eval_obj.to_mesh_clear()
print(f"Start triangles before final retopo: {start_tris}")

target_ratio = 7800.0 / start_tris if start_tris > 8500 else 1.0
if target_ratio < 0.98:
    dec = unified.modifiers.new("TargetBudget", 'DECIMATE')
    dec.ratio = target_ratio
    bpy.ops.object.modifier_apply(modifier="TargetBudget")

eval_obj = unified.evaluated_get(depsgraph)
m = eval_obj.to_mesh()
m.calc_loop_triangles()
final_tris = len(m.loop_triangles)
eval_obj.to_mesh_clear()
print(f"Final evaluated triangles: {final_tris} (Target budget: 6,000 - 9,000)")

# Recalculate normals
bm = bmesh.new()
bm.from_mesh(unified.data)
bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
bm.to_mesh(unified.data)
bm.free()
unified.data.update()

# 4. UV Unwrapping
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=66.0, island_margin=0.005)
bpy.ops.object.mode_set(mode='OBJECT')
print("UV unwrapped with 0.005 island margin.")

# 5. Bake Diffuse Color Texture Atlas (1024x1024)
atlas_base_path = os.path.join(TEXTURE_DIR, "mae_dagua_base_color.png")
atlas_img = bpy.data.images.new("MaeDagua_BaseColor", width=1024, height=1024, alpha=True)
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

# 6. Generate Tangent-Space Normal Map (1024x1024) with scale/fabric grain
normal_path = os.path.join(TEXTURE_DIR, "mae_dagua_normal.png")
norm_img = bpy.data.images.new("MaeDagua_Normal", width=1024, height=1024, alpha=False)
norm_img.filepath_raw = normal_path
norm_img.file_format = 'PNG'

# Fill neutral tangent normal (128, 128, 255) -> float (0.5, 0.5, 1.0, 1.0)
pixels = np.zeros((1024, 1024, 4), dtype=np.float32)
pixels[:, :, 0] = 0.5   # X (Tangent)
pixels[:, :, 1] = 0.5   # Y (Bitangent)
pixels[:, :, 2] = 1.0   # Z (Normal up)
pixels[:, :, 3] = 1.0   # Alpha

# Add subtle fish scale & organic skin micro-detail pattern
y_coords, x_coords = np.indices((1024, 1024))
scale_wave_x = np.sin(x_coords * 0.18) * np.cos(y_coords * 0.18) * 0.04
scale_wave_y = np.cos(x_coords * 0.18) * np.sin(y_coords * 0.18) * 0.04

pixels[:, :, 0] += scale_wave_x
pixels[:, :, 1] += scale_wave_y
# Normalize RGB
norm_len = np.sqrt(pixels[:, :, 0]**2 + pixels[:, :, 1]**2 + pixels[:, :, 2]**2)
pixels[:, :, 0] /= norm_len
pixels[:, :, 1] /= norm_len
pixels[:, :, 2] /= norm_len
# Remap from [-1, 1] to [0, 1]
pixels[:, :, 0] = pixels[:, :, 0] * 0.5 + 0.5
pixels[:, :, 1] = pixels[:, :, 1] * 0.5 + 0.5
pixels[:, :, 2] = pixels[:, :, 2] * 0.5 + 0.5

norm_img.pixels.foreach_set(pixels.ravel())
norm_img.save()
print(f"Normal Map saved: {normal_path}")

# 7. Setup Single Final PBR Material (MaeDagua_Mat)
unified.data.materials.clear()
pbr_mat = bpy.data.materials.new("MaeDagua_Mat")
pbr_mat.use_nodes = True
nodes = pbr_mat.node_tree.nodes
links = pbr_mat.node_tree.links
nodes.clear()

node_output = nodes.new("ShaderNodeOutputMaterial")
node_output.location = (400, 0)

node_bsdf = nodes.new("ShaderNodeBsdfPrincipled")
node_bsdf.location = (0, 0)
node_bsdf.inputs["Roughness"].default_value = 0.45
node_bsdf.inputs["Metallic"].default_value = 0.05
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
node_normal_map.inputs["Strength"].default_value = 0.65
links.new(tex_norm_node.outputs["Color"], node_normal_map.inputs["Color"])
links.new(node_normal_map.outputs["Normal"], node_bsdf.inputs["Normal"])

unified.data.materials.append(pbr_mat)
print(f"Assigned single PBR material: {pbr_mat.name} to {unified.name}")

# 8. Save Final Production Model
bpy.ops.wm.save_as_mainfile(filepath=FINAL_BLEND)
print(f"Saved production model to: {FINAL_BLEND}")

# 9. Render Textured Validation Views in EEVEE
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items.keys() else 'BLENDER_EEVEE'
scene.render.resolution_x = 1000
scene.render.resolution_y = 1000
scene.render.image_settings.file_format = 'PNG'

cam_obj = bpy.data.objects.get("ValidationCam")
target = Vector((-0.06, 0.00, 0.92))

views = {
    "textured_front": (Vector((-0.06, -3.15, 0.94)), target),
    "textured_side": (Vector((-3.25, 0.00, 0.94)), target),
    "textured_three_quarter": (Vector((-1.95, -2.55, 1.10)), target),
}

for vname, (cpos, ctgt) in views.items():
    cam_obj.location = cpos
    direction = (ctgt - cpos).normalized()
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    out_png = os.path.join(RENDER_DIR, f"{vname}.png")
    scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {out_png}")

# 10. Presentation Sheet (Concept | Textured Front | Textured 3/4 | Atlas UV)
bpy.ops.wm.read_factory_settings(use_empty=True)
comp_scene = bpy.context.scene
comp_scene.render.resolution_x = 2400
comp_scene.render.resolution_y = 600
comp_scene.render.image_settings.file_format = 'PNG'
if not comp_scene.sequence_editor:
    comp_scene.sequence_editor_create()
seq = comp_scene.sequence_editor

CONCEPT_PATH = os.path.join(ROOT_DIR, "art", "concepts", "mae_dagua", "mae_dagua_concept.png")
panels = [
    ("Concept", CONCEPT_PATH),
    ("Front", os.path.join(RENDER_DIR, "textured_front.png")),
    ("ThreeQuarter", os.path.join(RENDER_DIR, "textured_three_quarter.png")),
    ("Atlas", atlas_base_path),
]
for idx, (pname, ppath) in enumerate(panels):
    st = seq.strips.new_image(name=pname, filepath=ppath, channel=idx+1, frame_start=1)
    st.blend_type = 'ALPHA_OVER'
    orig_img = bpy.data.images.load(ppath)
    iw, ih = orig_img.size
    scale_factor = 600.0 / max(iw, ih)
    st.transform.scale_x = scale_factor
    st.transform.scale_y = scale_factor
    st.transform.offset_x = -900 + idx * 600

comp_out = os.path.join(RENDER_DIR, "textured_presentation.png")
comp_scene.frame_set(1)
comp_scene.render.filepath = comp_out
bpy.ops.render.render(write_still=True)
print(f"Rendered presentation sheet: {comp_out}")

