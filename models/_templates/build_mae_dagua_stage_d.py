import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
FINAL_BLEND = os.path.join(ROOT_DIR, "models", "mae_dagua", "mae_dagua.blend")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "mae_dagua", "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

bpy.ops.wm.open_mainfile(filepath=FINAL_BLEND)
scene = bpy.context.scene

unified = bpy.data.objects.get("MaeDagua")
if not unified:
    raise RuntimeError("MaeDagua object not found in scene!")

# Ensure Armature collection exists in RIG
rig_col = bpy.data.collections.get("RIG")
if not rig_col:
    rig_col = bpy.data.collections.new("RIG")
    scene.collection.children.link(rig_col)

# Create Armature
arm_data = bpy.data.armatures.new("MaeDagua_Armature")
arm_data.display_type = 'OCTAHEDRAL'
arm_obj = bpy.data.objects.new("MaeDagua_Armature", arm_data)
rig_col.objects.link(arm_obj)
scene.view_layers[0].active_layer_collection = scene.view_layers[0].layer_collection.children['RIG']

bpy.ops.object.select_all(action='DESELECT')
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj

bpy.ops.object.mode_set(mode='EDIT')
eb = arm_data.edit_bones

def make_bone(name, head, tail, parent_name=None, use_deform=True):
    b = eb.new(name)
    b.head = Vector(head)
    b.tail = Vector(tail)
    b.use_deform = use_deform
    if parent_name:
        b.parent = eb.get(parent_name)
    return b

# 1. Root & Core Humanoid Spine
make_bone("root",      (0.0, 0.0, 0.0),    (0.0, 0.0, 0.15))
make_bone("pelvis",    (0.0, -0.02, 0.88), (0.0, -0.02, 0.98), parent_name="root")
make_bone("spine_01",  (0.0, -0.02, 0.98), (0.0, -0.02, 1.10), parent_name="pelvis")
make_bone("spine_02",  (0.0, -0.02, 1.10), (0.0, -0.02, 1.22), parent_name="spine_01")
make_bone("spine_03",  (0.0, -0.02, 1.22), (0.0, -0.02, 1.32), parent_name="spine_02")
make_bone("neck_01",   (0.0, -0.02, 1.32), (0.0, -0.02, 1.40), parent_name="spine_03")
make_bone("Head",      (0.0, -0.02, 1.40), (0.0, -0.02, 1.58), parent_name="neck_01")

# 2. Arms (Left / Right)
make_bone("clavicle_l", ( 0.02, -0.02, 1.28), ( 0.10, -0.02, 1.28), parent_name="spine_03")
make_bone("upperarm_l", ( 0.10, -0.02, 1.28), ( 0.22, -0.03, 1.12), parent_name="clavicle_l")
make_bone("lowerarm_l", ( 0.22, -0.03, 1.12), ( 0.32, -0.06, 0.94), parent_name="upperarm_l")
make_bone("hand_l",     ( 0.32, -0.06, 0.94), ( 0.36, -0.08, 0.85), parent_name="lowerarm_l")

make_bone("clavicle_r", (-0.02, -0.02, 1.28), (-0.10, -0.02, 1.28), parent_name="spine_03")
make_bone("upperarm_r", (-0.10, -0.02, 1.28), (-0.22, -0.03, 1.12), parent_name="clavicle_r")
make_bone("lowerarm_r", (-0.22, -0.03, 1.12), (-0.32, -0.06, 0.94), parent_name="upperarm_r")
make_bone("hand_r",     (-0.32, -0.06, 0.94), (-0.36, -0.08, 0.85), parent_name="lowerarm_r")

# 3. Fish Tail Spline Chain (from pelvis downwards into S-curve)
tail_bone_coords = [
    ("tail_01", ( 0.00, -0.02, 0.88), ( 0.00, -0.03, 0.76), "pelvis"),
    ("tail_02", ( 0.00, -0.03, 0.76), ( 0.01, -0.02, 0.61), "tail_01"),
    ("tail_03", ( 0.01, -0.02, 0.61), ( 0.02,  0.01, 0.44), "tail_02"),
    ("tail_04", ( 0.02,  0.01, 0.44), ( 0.03,  0.05, 0.26), "tail_03"),
    ("tail_05", ( 0.03,  0.05, 0.26), (-0.09,  0.16, 0.04), "tail_04"),
    ("tail_06", (-0.09,  0.16, 0.04), (-0.33,  0.24, 0.24), "tail_05"),
    ("tail_07", (-0.33,  0.24, 0.24), (-0.49,  0.20, 0.70), "tail_06"),
    ("tail_fin",(-0.49,  0.20, 0.70), (-0.46,  0.06, 1.35), "tail_07"),
]
for bname, hd, tl, pr in tail_bone_coords:
    make_bone(bname, hd, tl, parent_name=pr)

# 4. Caudal & Pelvic Fins
make_bone("fin_outer",    (-0.46,  0.06, 1.35), (-0.74, 0.11, 1.70), parent_name="tail_fin")
make_bone("fin_inner",    (-0.46,  0.06, 1.35), (-0.30, 0.04, 1.66), parent_name="tail_fin")
make_bone("fin_pelvic_l", ( 0.15, -0.01, 0.70), ( 0.31, 0.02, 0.45), parent_name="tail_02")
make_bone("fin_pelvic_r", (-0.15, -0.01, 0.70), (-0.31, 0.02, 0.45), parent_name="tail_02")

# 5. Hair Secondary Chains
make_bone("hair_l_01",    ( 0.10, -0.03, 1.48), ( 0.18, -0.03, 1.25), parent_name="Head")
make_bone("hair_l_02",    ( 0.18, -0.03, 1.25), ( 0.24, -0.03, 1.05), parent_name="hair_l_01")
make_bone("hair_r_01",    (-0.10, -0.03, 1.48), (-0.18, -0.03, 1.25), parent_name="Head")
make_bone("hair_r_02",    (-0.18, -0.03, 1.25), (-0.24, -0.03, 1.05), parent_name="hair_r_01")
make_bone("hair_back_01", ( 0.00,  0.08, 1.46), ( 0.00,  0.09, 1.25), parent_name="Head")
make_bone("hair_back_02", ( 0.00,  0.09, 1.25), ( 0.00,  0.09, 1.00), parent_name="hair_back_01")

# 6. Indigenous Cocar Headdress
make_bone("cocar",        ( 0.00, -0.03, 1.52), ( 0.00, -0.04, 1.88), parent_name="Head")

print(f"Total bones created: {len(eb)} (Spec budget: 25 - 45)")

bpy.ops.object.mode_set(mode='OBJECT')

# Bind mesh with Automatic Weights
bpy.ops.object.select_all(action='DESELECT')
unified.select_set(True)
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.parent_set(type='ARMATURE_AUTO')

# Limit max bone weights to 4 per vertex (Engine technical budget requirement)
bpy.context.view_layer.objects.active = unified
bpy.ops.object.vertex_group_limit_total(limit=4)
bpy.ops.object.vertex_group_clean(group_select_mode='ALL', limit=0.01)
print("Bound mesh to armature with Automatic Weights and clamped to max 4 influences/vert.")

# Test Pose in Pose Mode (subtle Idle / Queenly aquatic pose)
bpy.ops.object.mode_set(mode='OBJECT')
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='POSE')

# Pose bones gently to test skinning deformation
pose_bones = arm_obj.pose.bones
if "tail_01" in pose_bones:
    pose_bones["tail_01"].rotation_mode = 'XYZ'
    pose_bones["tail_01"].rotation_euler = (math.radians(4), math.radians(2), math.radians(-3))
if "tail_03" in pose_bones:
    pose_bones["tail_03"].rotation_mode = 'XYZ'
    pose_bones["tail_03"].rotation_euler = (math.radians(-6), math.radians(-4), math.radians(5))
if "tail_fin" in pose_bones:
    pose_bones["tail_fin"].rotation_mode = 'XYZ'
    pose_bones["tail_fin"].rotation_euler = (math.radians(8), math.radians(-5), math.radians(6))
if "upperarm_l" in pose_bones:
    pose_bones["upperarm_l"].rotation_mode = 'XYZ'
    pose_bones["upperarm_l"].rotation_euler = (math.radians(6), math.radians(-8), math.radians(4))
if "upperarm_r" in pose_bones:
    pose_bones["upperarm_r"].rotation_mode = 'XYZ'
    pose_bones["upperarm_r"].rotation_euler = (math.radians(6), math.radians(8), math.radians(-4))

bpy.ops.object.mode_set(mode='OBJECT')

# Save updated blend file
bpy.ops.wm.save_as_mainfile(filepath=FINAL_BLEND)
print(f"Saved rigged model to: {FINAL_BLEND}")

# Render Rigged Test Pose
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items.keys() else 'BLENDER_EEVEE'
scene.render.resolution_x = 1000
scene.render.resolution_y = 1000
scene.render.image_settings.file_format = 'PNG'

cam_obj = bpy.data.objects.get("ValidationCam")
target = Vector((-0.06, 0.00, 0.92))

cam_obj.location = Vector((-1.95, -2.55, 1.10))
direction = (target - cam_obj.location).normalized()
cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

out_png = os.path.join(RENDER_DIR, "rigged_pose_test.png")
scene.render.filepath = out_png
bpy.ops.render.render(write_still=True)
print(f"Rendered rigged pose test: {out_png}")

