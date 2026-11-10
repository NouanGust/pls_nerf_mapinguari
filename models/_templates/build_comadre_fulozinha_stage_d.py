import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
FINAL_BLEND = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "comadre_fulozinha.blend")
GLB_OUT = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "comadre_fulozinha.glb")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

# 1. Open production blend
bpy.ops.wm.open_mainfile(filepath=FINAL_BLEND)
scene = bpy.context.scene

unified = bpy.data.objects.get("ComadreFulozinha")
if not unified:
    raise RuntimeError("ComadreFulozinha object not found in scene!")

# Ensure Armature collection exists in RIG
rig_col = bpy.data.collections.get("RIG")
if not rig_col:
    rig_col = bpy.data.collections.new("RIG")
    scene.collection.children.link(rig_col)

# Create Armature
arm_data = bpy.data.armatures.new("Fulozinha_Armature")
arm_data.display_type = 'OCTAHEDRAL'
arm_obj = bpy.data.objects.new("Fulozinha_Armature", arm_data)
rig_col.objects.link(arm_obj)

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

# --- 1. Root & Core Spine (Cabocla juvenile stature ~1.35m) ---
make_bone("root",      (0.0, 0.0, 0.0),    (0.0, 0.0, 0.15))
make_bone("pelvis",    (0.0, -0.01, 0.65), (0.0, -0.01, 0.76), parent_name="root")
make_bone("spine_01",  (0.0, -0.01, 0.76), (0.0, -0.01, 0.90), parent_name="pelvis")
make_bone("spine_02",  (0.0, -0.01, 0.90), (0.0, -0.01, 1.05), parent_name="spine_01")
make_bone("spine_03",  (0.0, -0.01, 1.05), (0.0, -0.01, 1.15), parent_name="spine_02")
make_bone("neck_01",   (0.0, -0.01, 1.15), (0.0, -0.01, 1.22), parent_name="spine_03")
make_bone("Head",      (0.0, -0.01, 1.22), (0.0, -0.01, 1.38), parent_name="neck_01")

# --- 2. Legs ---
make_bone("thigh_l", (-0.08, -0.01, 0.65), (-0.09, -0.01, 0.35), parent_name="pelvis")
make_bone("shin_l",  (-0.09, -0.01, 0.35), (-0.09,  0.01, 0.08), parent_name="thigh_l")
make_bone("foot_l",  (-0.09,  0.01, 0.08), (-0.09, -0.10, 0.02), parent_name="shin_l")
make_bone("toe_l",   (-0.09, -0.10, 0.02), (-0.09, -0.16, 0.00), parent_name="foot_l")

make_bone("thigh_r", ( 0.08, -0.01, 0.65), ( 0.09, -0.01, 0.35), parent_name="pelvis")
make_bone("shin_r",  ( 0.09, -0.01, 0.35), ( 0.09,  0.01, 0.08), parent_name="thigh_r")
make_bone("foot_r",  ( 0.09,  0.01, 0.08), ( 0.09, -0.10, 0.02), parent_name="shin_r")
make_bone("toe_r",   ( 0.09, -0.10, 0.02), ( 0.09, -0.16, 0.00), parent_name="foot_r")

# --- 3. Arms ---
make_bone("clavicle_l", (-0.02, -0.01, 1.12), (-0.09, -0.01, 1.12), parent_name="spine_03")
make_bone("upperarm_l", (-0.09, -0.01, 1.12), (-0.17, -0.01, 0.92), parent_name="clavicle_l")
make_bone("lowerarm_l", (-0.17, -0.01, 0.92), (-0.22, -0.02, 0.74), parent_name="upperarm_l")
make_bone("hand_l",     (-0.22, -0.02, 0.74), (-0.25, -0.03, 0.62), parent_name="lowerarm_l")

make_bone("clavicle_r", ( 0.02, -0.01, 1.12), ( 0.09, -0.01, 1.12), parent_name="spine_03")
make_bone("upperarm_r", ( 0.09, -0.01, 1.12), ( 0.17, -0.01, 0.92), parent_name="clavicle_r")
make_bone("lowerarm_r", ( 0.17, -0.01, 0.92), ( 0.22, -0.02, 0.74), parent_name="upperarm_r")
make_bone("hand_r",     ( 0.22, -0.02, 0.74), ( 0.25, -0.03, 0.62), parent_name="lowerarm_r")

# --- 4. Whip Chain in Right Hand ---
make_bone("whip_grip", (0.24, -0.03, 0.64), (0.26, -0.04, 0.58), parent_name="hand_r")
make_bone("whip_01",   (0.26, -0.04, 0.58), (0.33,  0.01, 0.62), parent_name="whip_grip")
make_bone("whip_02",   (0.33,  0.01, 0.62), (0.38,  0.04, 0.44), parent_name="whip_01")
make_bone("whip_03",   (0.38,  0.04, 0.44), (0.34,  0.01, 0.25), parent_name="whip_02")
make_bone("whip_04",   (0.34,  0.01, 0.25), (0.24,  0.00, 0.08), parent_name="whip_03")
make_bone("whip_tip",  (0.24,  0.00, 0.08), (0.15, -0.03, 0.01), parent_name="whip_04")

# --- 5. Hair Secondary Chains ---
make_bone("hair_front_l", (-0.08, -0.07, 1.25), (-0.08, -0.08, 0.95), parent_name="Head")
make_bone("hair_front_r", ( 0.08, -0.07, 1.25), ( 0.08, -0.08, 0.95), parent_name="Head")
make_bone("hair_back_01", ( 0.00,  0.08, 1.28), ( 0.00,  0.10, 1.05), parent_name="Head")
make_bone("hair_back_02", ( 0.00,  0.10, 1.05), ( 0.00,  0.11, 0.75), parent_name="hair_back_01")
make_bone("hair_back_03", ( 0.00,  0.11, 0.75), ( 0.00,  0.08, 0.42), parent_name="hair_back_02")

print(f"Total bones created: {len(eb)} (Spec budget: 25 - 40)")

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

# Setup Pose Mode & Euler Rotations
bpy.ops.object.mode_set(mode='OBJECT')
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='POSE')

for pb in arm_obj.pose.bones:
    pb.rotation_mode = 'XYZ'
    pb.location = Vector((0, 0, 0))
    pb.rotation_euler = Euler((0, 0, 0), 'XYZ')

if not arm_obj.animation_data:
    arm_obj.animation_data_create()

# Clear existing actions / tracks
arm_obj.animation_data.action = None
for track in list(arm_obj.animation_data.nla_tracks):
    arm_obj.animation_data.nla_tracks.remove(track)
for act in list(bpy.data.actions):
    bpy.data.actions.remove(act)

def set_bone(pb_name, rot_deg=None, loc=None):
    pb = arm_obj.pose.bones.get(pb_name)
    if not pb:
        return
    if rot_deg is not None:
        pb.rotation_euler = Euler(tuple(math.radians(a) for a in rot_deg), 'XYZ')
    if loc is not None:
        pb.location = Vector(loc)

def key_bone(pb_name, frame, rot_deg=None, loc=None):
    pb = arm_obj.pose.bones.get(pb_name)
    if not pb:
        return
    set_bone(pb_name, rot_deg=rot_deg, loc=loc)
    if rot_deg is not None:
        pb.keyframe_insert(data_path="rotation_euler", frame=frame)
    if loc is not None:
        pb.keyframe_insert(data_path="location", frame=frame)

actions = {}

# =========================================================================
# 1. IDLE (Loop, 48 frames, 24 fps = 2.0s) - Agile cabocla stance, breathing, whip sway
# =========================================================================
act_idle = bpy.data.actions.new("Idle")
arm_obj.animation_data.action = act_idle
actions["Idle"] = act_idle

for f in range(1, 49):
    t = (f - 1) / 48.0
    sin1 = math.sin(t * 2.0 * math.pi)
    cos1 = math.cos(t * 2.0 * math.pi)
    sin2 = math.sin(t * 4.0 * math.pi)

    # Pelvis subtle weight shift and breathing
    key_bone("pelvis", f, loc=(0.005 * sin1, 0, 0.012 * sin2), rot_deg=(1.5 * cos1, 0, 2.0 * sin1))
    key_bone("spine_01", f, rot_deg=(2.0 * cos1, 0, 1.0 * sin1))
    key_bone("spine_02", f, rot_deg=(2.0 * cos1, 0, 0.5 * sin1))
    key_bone("spine_03", f, rot_deg=(1.5 * cos1, 0, 0))
    key_bone("neck_01", f, rot_deg=(-1.5 * cos1, 0, -1.0 * sin1))
    key_bone("Head", f, rot_deg=(-2.0 * cos1, 0, -1.5 * sin1))

    # Agile bent knees stance
    key_bone("thigh_l", f, rot_deg=(-4.0 + 1.0 * sin1, 2.0, -1.0 * sin1))
    key_bone("shin_l",  f, rot_deg=(6.0 - 1.5 * sin1, 0, 0))
    key_bone("thigh_r", f, rot_deg=(-4.0 - 1.0 * sin1, -2.0, 1.0 * sin1))
    key_bone("shin_r",  f, rot_deg=(6.0 + 1.5 * sin1, 0, 0))

    # Left arm relaxed guard
    key_bone("upperarm_l", f, rot_deg=(8.0 + 3.0 * cos1, -6.0 + 2.0 * sin1, 4.0 * sin1))
    key_bone("lowerarm_l", f, rot_deg=(-15.0 - 2.0 * cos1, 4.0 * sin1, 0))
    key_bone("hand_l",     f, rot_deg=(6.0 * sin1, 0, 2.0 * cos1))

    # Right arm holding whip with subtle ready twitch
    key_bone("upperarm_r", f, rot_deg=(10.0 + 3.0 * cos1, 8.0 - 2.0 * sin1, -3.0 * sin1))
    key_bone("lowerarm_r", f, rot_deg=(-25.0 - 3.0 * cos1, -3.0 * sin1, 0))
    key_bone("hand_r",     f, rot_deg=(8.0 * sin1, 0, -3.0 * cos1))

    # Whip secondary coil undulation
    for i, bname in enumerate(["whip_01", "whip_02", "whip_03", "whip_04", "whip_tip"]):
        phase = t * 2.0 * math.pi - i * 0.7
        amp = 4.0 + i * 2.0
        key_bone(bname, f, rot_deg=(amp * 0.3 * math.cos(phase), amp * 0.5 * math.sin(phase), amp * 0.4 * math.sin(phase)))

    # Hair breathing sway
    for i, bname in enumerate(["hair_back_01", "hair_back_02", "hair_back_03"]):
        phase = t * 2.0 * math.pi - i * 0.6
        key_bone(bname, f, rot_deg=(3.0 * math.cos(phase), 0, 2.0 * math.sin(phase)))
    key_bone("hair_front_l", f, rot_deg=(2.0 * cos1, 0, 1.5 * sin1))
    key_bone("hair_front_r", f, rot_deg=(2.0 * cos1, 0, -1.5 * sin1))

print("Created Action: Idle")

# =========================================================================
# 2. ATTACK (Single play, 24 frames = 1.0s) - Explosive whip strike & snap
# =========================================================================
act_attack = bpy.data.actions.new("Attack")
arm_obj.animation_data.action = act_attack
actions["Attack"] = act_attack

# Anticipation (frames 1-8): wind-up right arm back, chest arches
# Strike (frames 9-14): explosive forward crack with whip extension
# Recoil & Return (frames 15-24): recoil, recover to idle
for f in range(1, 25):
    if f <= 8:
        p = (f - 1) / 7.0
        # Wind up
        key_bone("pelvis", f, rot_deg=(-5.0 * p, 0, -10.0 * p))
        key_bone("spine_02", f, rot_deg=(-8.0 * p, 0, -15.0 * p))
        key_bone("Head", f, rot_deg=(5.0 * p, 0, 12.0 * p))
        key_bone("upperarm_r", f, rot_deg=(-45.0 * p, 30.0 * p, 35.0 * p))
        key_bone("lowerarm_r", f, rot_deg=(-70.0 * p, 10.0 * p, 0))
        key_bone("hand_r", f, rot_deg=(-25.0 * p, 0, 0))
        key_bone("whip_01", f, rot_deg=(-20.0 * p, -15.0 * p, 0))
        key_bone("whip_03", f, rot_deg=(-30.0 * p, -25.0 * p, 0))
    elif f <= 13:
        p = (f - 8) / 5.0
        # Forward whip lash & snap
        key_bone("pelvis", f, rot_deg=(-5.0 + 20.0 * p, 0, -10.0 + 25.0 * p))
        key_bone("spine_02", f, rot_deg=(-8.0 + 25.0 * p, 0, -15.0 + 30.0 * p))
        key_bone("Head", f, rot_deg=(5.0 - 15.0 * p, 0, 12.0 - 20.0 * p))
        key_bone("upperarm_r", f, rot_deg=(-45.0 + 110.0 * p, 30.0 - 40.0 * p, 35.0 - 45.0 * p))
        key_bone("lowerarm_r", f, rot_deg=(-70.0 + 85.0 * p, 10.0 - 15.0 * p, 0))
        key_bone("hand_r", f, rot_deg=(-25.0 + 65.0 * p, 0, 0))
        # Whip uncoils straight forward
        key_bone("whip_01", f, rot_deg=(40.0 * p, 20.0 * p, 0))
        key_bone("whip_02", f, rot_deg=(50.0 * p, 15.0 * p, 0))
        key_bone("whip_03", f, rot_deg=(60.0 * p, 10.0 * p, 0))
        key_bone("whip_tip", f, rot_deg=(75.0 * p, 0, 0))
    else:
        p = (f - 13) / 11.0
        # Recovery
        key_bone("pelvis", f, rot_deg=(15.0 * (1 - p), 0, 15.0 * (1 - p)))
        key_bone("spine_02", f, rot_deg=(17.0 * (1 - p), 0, 15.0 * (1 - p)))
        key_bone("Head", f, rot_deg=(-10.0 * (1 - p), 0, -8.0 * (1 - p)))
        key_bone("upperarm_r", f, rot_deg=(65.0 * (1 - p) + 10.0 * p, -10.0 * (1 - p) + 8.0 * p, -10.0 * (1 - p) - 3.0 * p))
        key_bone("lowerarm_r", f, rot_deg=(15.0 * (1 - p) - 25.0 * p, -5.0 * (1 - p), 0))
        key_bone("hand_r", f, rot_deg=(40.0 * (1 - p), 0, 0))
        key_bone("whip_01", f, rot_deg=(40.0 * (1 - p), 0, 0))
        key_bone("whip_02", f, rot_deg=(50.0 * (1 - p), 0, 0))
        key_bone("whip_03", f, rot_deg=(60.0 * (1 - p), 0, 0))
        key_bone("whip_tip", f, rot_deg=(75.0 * (1 - p), 0, 0))

print("Created Action: Attack")

# =========================================================================
# 3. STUNNED (Loop, 36 frames = 1.5s) - Staggered recoil, dizzy wobble
# =========================================================================
act_stunned = bpy.data.actions.new("Stunned")
arm_obj.animation_data.action = act_stunned
actions["Stunned"] = act_stunned

for f in range(1, 37):
    t = (f - 1) / 36.0
    sin1 = math.sin(t * 2.0 * math.pi)
    cos1 = math.cos(t * 2.0 * math.pi)
    
    key_bone("pelvis", f, loc=(0.01 * sin1, -0.02, 0), rot_deg=(-8.0 + 3.0 * cos1, 0, 4.0 * sin1))
    key_bone("spine_02", f, rot_deg=(-12.0 + 4.0 * cos1, 2.0 * sin1, 6.0 * sin1))
    key_bone("Head", f, rot_deg=(15.0 + 10.0 * cos1, 8.0 * sin1, 6.0 * cos1))
    key_bone("upperarm_l", f, rot_deg=(-10.0 + 5.0 * sin1, -20.0, 10.0 * cos1))
    key_bone("lowerarm_l", f, rot_deg=(-45.0 + 8.0 * sin1, 0, 0))
    key_bone("upperarm_r", f, rot_deg=(-15.0 + 5.0 * cos1, 15.0, -10.0 * sin1))
    key_bone("lowerarm_r", f, rot_deg=(-40.0 + 8.0 * cos1, 0, 0))
    key_bone("whip_01", f, rot_deg=(-15.0 * sin1, 0, 0))
    key_bone("whip_03", f, rot_deg=(-20.0 * cos1, 0, 0))

print("Created Action: Stunned")

# =========================================================================
# 4. CHANNEL (Loop, 36 frames = 1.5s) - Mystical whistling, raising left hand
# =========================================================================
act_channel = bpy.data.actions.new("Channel")
arm_obj.animation_data.action = act_channel
actions["Channel"] = act_channel

for f in range(1, 37):
    t = (f - 1) / 36.0
    sin1 = math.sin(t * 2.0 * math.pi)
    cos1 = math.cos(t * 2.0 * math.pi)
    
    # Proud upright stance, chest high
    key_bone("pelvis", f, loc=(0, 0, 0.015 * sin1), rot_deg=(3.0 * cos1, 0, 0))
    key_bone("spine_02", f, rot_deg=(5.0 + 2.0 * cos1, 0, 0))
    key_bone("Head", f, rot_deg=(8.0 + 4.0 * cos1, 0, 2.0 * sin1))
    
    # Left arm raised high towards canopy (whistling call)
    key_bone("upperarm_l", f, rot_deg=(75.0 + 4.0 * cos1, -30.0 + 3.0 * sin1, 20.0 * sin1))
    key_bone("lowerarm_l", f, rot_deg=(-40.0 + 5.0 * sin1, 0, 0))
    key_bone("hand_l",     f, rot_deg=(20.0 + 6.0 * cos1, 0, 0))
    
    # Right arm holding whip ready at hip
    key_bone("upperarm_r", f, rot_deg=(15.0 + 2.0 * cos1, 10.0, -5.0))
    key_bone("lowerarm_r", f, rot_deg=(-35.0, 0, 0))
    
    # Hair floating upwards with magic wind
    key_bone("hair_back_01", f, rot_deg=(-10.0 + 4.0 * cos1, 0, 3.0 * sin1))
    key_bone("hair_back_02", f, rot_deg=(-15.0 + 6.0 * cos1, 0, 4.0 * sin1))
    key_bone("hair_back_03", f, rot_deg=(-20.0 + 8.0 * cos1, 0, 5.0 * sin1))

print("Created Action: Channel")

# =========================================================================
# 5. DEATH (Single play, 36 frames = 1.5s) - Kneeling collapse into forest ground
# =========================================================================
act_death = bpy.data.actions.new("Death")
arm_obj.animation_data.action = act_death
actions["Death"] = act_death

for f in range(1, 37):
    p = (f - 1) / 35.0
    p_ease = 1.0 - math.pow(1.0 - p, 2.5) # Fast drop, slow settle
    
    key_bone("pelvis", f, loc=(0, 0.05 * p_ease, -0.38 * p_ease), rot_deg=(-15.0 * p_ease, 0, -10.0 * p_ease))
    key_bone("thigh_l", f, rot_deg=(-65.0 * p_ease, -15.0 * p_ease, 0))
    key_bone("shin_l",  f, rot_deg=(110.0 * p_ease, 0, 0))
    key_bone("thigh_r", f, rot_deg=(-55.0 * p_ease, 20.0 * p_ease, 0))
    key_bone("shin_r",  f, rot_deg=(95.0 * p_ease, 0, 0))
    
    # Torso crumples forward
    key_bone("spine_02", f, rot_deg=(40.0 * p_ease, 0, 8.0 * p_ease))
    key_bone("Head", f, rot_deg=(25.0 * p_ease, 0, -12.0 * p_ease))
    
    # Arms drape to ground
    key_bone("upperarm_l", f, rot_deg=(-20.0 * p_ease, -25.0 * p_ease, 0))
    key_bone("lowerarm_l", f, rot_deg=(-35.0 * p_ease, 0, 0))
    key_bone("upperarm_r", f, rot_deg=(-15.0 * p_ease, 20.0 * p_ease, 0))
    key_bone("lowerarm_r", f, rot_deg=(-30.0 * p_ease, 0, 0))
    
    # Whip falls limp to ground
    key_bone("whip_grip", f, rot_deg=(-40.0 * p_ease, 0, 0))
    key_bone("whip_01", f, rot_deg=(-30.0 * p_ease, 0, 0))
    key_bone("whip_03", f, rot_deg=(-15.0 * p_ease, 0, 0))
    
    # Hair draping over body and floor
    key_bone("hair_back_01", f, rot_deg=(25.0 * p_ease, 0, 0))
    key_bone("hair_back_02", f, rot_deg=(40.0 * p_ease, 0, 0))
    key_bone("hair_back_03", f, rot_deg=(50.0 * p_ease, 0, 0))

print("Created Action: Death")

# =========================================================================
# 6. ABILITY (Single play, 48 frames = 2.0s) - Invocação da Floresta / Whirlwind Whip Lash
# =========================================================================
act_ability = bpy.data.actions.new("Ability")
arm_obj.animation_data.action = act_ability
actions["Ability"] = act_ability

# Leap & 360 spin with circular whip storm
for f in range(1, 49):
    p = (f - 1) / 47.0
    sin_spin = math.sin(p * math.pi)
    
    # Jump height
    jump_z = 0.18 * math.sin(p * math.pi)
    # Full 360 yaw rotation
    yaw_rot = p * 360.0
    
    key_bone("pelvis", f, loc=(0, 0, jump_z), rot_deg=(-5.0, yaw_rot, 0))
    key_bone("spine_02", f, rot_deg=(10.0 * math.sin(p * 2 * math.pi), 0, 0))
    key_bone("Head", f, rot_deg=(-8.0 * math.sin(p * 2 * math.pi), 0, 0))
    
    # Whirlwind wide whip slash
    key_bone("upperarm_r", f, rot_deg=(30.0 + 40.0 * sin_spin, 45.0 * sin_spin, -60.0 * sin_spin))
    key_bone("lowerarm_r", f, rot_deg=(-15.0, 0, 0))
    key_bone("hand_r", f, rot_deg=(30.0 * sin_spin, 0, 0))
    
    # Whip trail expanding centrifugally
    key_bone("whip_01", f, rot_deg=(35.0 * sin_spin, 40.0 * sin_spin, 0))
    key_bone("whip_02", f, rot_deg=(50.0 * sin_spin, 60.0 * sin_spin, 0))
    key_bone("whip_03", f, rot_deg=(65.0 * sin_spin, 70.0 * sin_spin, 0))
    key_bone("whip_tip", f, rot_deg=(85.0 * sin_spin, 80.0 * sin_spin, 0))
    
    # Left arm counter-balancing
    key_bone("upperarm_l", f, rot_deg=(25.0 * sin_spin, -45.0 * sin_spin, 40.0 * sin_spin))
    key_bone("lowerarm_l", f, rot_deg=(-20.0, 0, 0))
    
    # Hair flaring outwards centrifugally
    key_bone("hair_back_01", f, rot_deg=(-25.0 * sin_spin, 0, 20.0 * math.sin(p * 4 * math.pi)))
    key_bone("hair_back_02", f, rot_deg=(-35.0 * sin_spin, 0, 30.0 * math.sin(p * 4 * math.pi)))
    key_bone("hair_back_03", f, rot_deg=(-45.0 * sin_spin, 0, 40.0 * math.sin(p * 4 * math.pi)))

print("Created Action: Ability")

# =========================================================================
# 7. Push all 6 Actions to NLA Tracks for Godot Export
# =========================================================================
bpy.ops.object.mode_set(mode='OBJECT')

for name, act in actions.items():
    track = arm_obj.animation_data.nla_tracks.new()
    track.name = name
    strip = track.strips.new(name, int(act.frame_range[0]), act)
    strip.name = name
    print(f"Pushed to NLA: {name} [{act.frame_range[0]} - {act.frame_range[1]}]")

# Set active action to Idle
arm_obj.animation_data.action = actions["Idle"]

# Save production blend
bpy.ops.wm.save_as_mainfile(filepath=FINAL_BLEND)
print(f"Saved production blend with rig and animations: {FINAL_BLEND}")

# =========================================================================
# 8. Export GLB for Godot Engine 4.x
# =========================================================================
bpy.ops.export_scene.gltf(
    filepath=GLB_OUT,
    export_format='GLB',
    use_selection=False,
    export_apply=True,
    export_animations=True,
    export_animation_mode='NLA_TRACKS',
    export_optimize_animation_size=True,
    export_current_frame=False,
    export_skins=True,
    export_all_influences=False,
    export_def_bones=True,
)
print(f"GLB exported successfully to: {GLB_OUT}")

# =========================================================================
# 9. Render Animation Montage Preview Sheet
# =========================================================================
scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE'
scene.render.resolution_x = 768
scene.render.resolution_y = 768
scene.render.film_transparent = True

cam_obj = bpy.data.objects.get("RenderCam")
if not cam_obj:
    cam_data = bpy.data.cameras.new("RenderCam")
    cam_data.lens = 65
    cam_obj = bpy.data.objects.new("RenderCam", cam_data)
    scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

center_target = Vector((0.0, 0.0, 0.72))
cam_pos = Vector((1.8, -1.8, 0.95))
cam_obj.location = cam_pos
direction = center_target - cam_pos
cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

anim_renders = {}
anim_sample_frames = {
    "Idle": 24,
    "Attack": 12,
    "Channel": 18,
    "Ability": 24,
}

for aname, fnum in anim_sample_frames.items():
    arm_obj.animation_data.action = actions[aname]
    scene.frame_set(fnum)
    bpy.context.view_layer.update()
    
    out_f = os.path.join(RENDER_DIR, f"anim_{aname.lower()}.png")
    scene.render.filepath = out_f
    bpy.ops.render.render(write_still=True)
    anim_renders[aname] = out_f
    print(f"Rendered anim frame: {out_f}")

print("Animation montage frames rendered successfully.")

