import bpy
import math
import os
from mathutils import Vector, Euler, Quaternion

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
FINAL_BLEND = os.path.join(ROOT_DIR, "models", "mae_dagua", "mae_dagua.blend")
GLB_OUT = os.path.join(ROOT_DIR, "models", "mae_dagua", "mae_dagua.glb")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "mae_dagua", "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

bpy.ops.wm.open_mainfile(filepath=FINAL_BLEND)
scene = bpy.context.scene

arm_obj = bpy.data.objects.get("MaeDagua_Armature")
mesh_obj = bpy.data.objects.get("MaeDagua")

if not arm_obj or not mesh_obj:
    raise RuntimeError("MaeDagua_Armature or MaeDagua not found!")

# Ensure Euler rotation mode on all pose bones for clean scripting
bpy.ops.object.select_all(action='DESELECT')
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

# =========================================================================
# 1. IDLE (Loop, 48 frames, 24 fps) - Undulating tail, breathing, royal posture
# =========================================================================
act_idle = bpy.data.actions.new("Idle")
arm_obj.animation_data.action = act_idle
num_frames_idle = 48

for f in range(1, num_frames_idle + 2):
    t = (f - 1) / float(num_frames_idle)
    sin1 = math.sin(t * 2.0 * math.pi)
    cos1 = math.cos(t * 2.0 * math.pi)
    sin2 = math.sin(t * 4.0 * math.pi)

    # Spine breathing & subtle floating bob
    key_bone("pelvis", f, loc=(0, 0, 0.015 * sin1), rot_deg=(1.5 * cos1, 0, 1.0 * sin1))
    key_bone("spine_01", f, rot_deg=(2.0 * cos1, 0, 1.0 * sin1))
    key_bone("spine_02", f, rot_deg=(2.5 * cos1, 0, 0.5 * sin1))
    key_bone("spine_03", f, rot_deg=(1.5 * cos1, 0, 0))
    key_bone("neck_01", f, rot_deg=(-1.5 * cos1, 0, -0.5 * sin1))
    key_bone("Head", f, rot_deg=(-2.0 * cos1, 0, -1.0 * sin1))

    # Arms subtle floating sway
    key_bone("upperarm_l", f, rot_deg=(4.0 + 3.0 * cos1, -4.0 + 2.0 * sin1, 2.0 * sin1))
    key_bone("lowerarm_l", f, rot_deg=(-2.0 * cos1, 2.0 * sin1, 0))
    key_bone("hand_l", f, rot_deg=(4.0 * sin1, 0, 2.0 * cos1))

    key_bone("upperarm_r", f, rot_deg=(4.0 + 3.0 * cos1, 4.0 - 2.0 * sin1, -2.0 * sin1))
    key_bone("lowerarm_r", f, rot_deg=(-2.0 * cos1, -2.0 * sin1, 0))
    key_bone("hand_r", f, rot_deg=(4.0 * sin1, 0, -2.0 * cos1))

    # Fish tail wave propagation down the 8 segments
    for i, bname in enumerate(["tail_01", "tail_02", "tail_03", "tail_04", "tail_05", "tail_06", "tail_07"]):
        phase = t * 2.0 * math.pi - i * 0.55
        amp = 4.0 + i * 1.5
        key_bone(bname, f, rot_deg=(amp * 0.4 * math.cos(phase), amp * 0.6 * math.sin(phase), amp * 0.5 * math.sin(phase)))

    # Fluke & Fin lobes fanning
    phase_fin = t * 2.0 * math.pi - 7 * 0.55
    key_bone("tail_fin", f, rot_deg=(6.0 * math.cos(phase_fin), 10.0 * math.sin(phase_fin), 8.0 * math.sin(phase_fin)))
    key_bone("fin_outer", f, rot_deg=(4.0 * math.sin(phase_fin), 8.0 * math.cos(phase_fin), 0))
    key_bone("fin_inner", f, rot_deg=(-3.0 * math.sin(phase_fin), -6.0 * math.cos(phase_fin), 0))

    # Hair & Cocar subtle flow
    key_bone("hair_l_01", f, rot_deg=(2.0 * cos1, 0, 4.0 * sin1))
    key_bone("hair_r_01", f, rot_deg=(2.0 * cos1, 0, -4.0 * sin1))
    key_bone("hair_back_01", f, rot_deg=(3.0 * sin1, 0, 0))
    key_bone("cocar", f, rot_deg=(-1.5 * cos1, 0, 1.0 * sin1))

# Push Idle to NLA
track_idle = arm_obj.animation_data.nla_tracks.new()
track_idle.name = "Idle"
strip_idle = track_idle.strips.new("Idle", 1, act_idle)

# =========================================================================
# 2. ATTACK (One-shot, 26 frames, 24 fps) - Anticipation -> Water whip strike -> Recovery
# =========================================================================
act_attack = bpy.data.actions.new("Attack")
arm_obj.animation_data.action = act_attack

# Reset pose
for pb in arm_obj.pose.bones:
    pb.rotation_euler = Euler((0, 0, 0), 'XYZ')
    pb.location = Vector((0, 0, 0))

# F1: Rest pose
for b in ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head", "upperarm_r", "lowerarm_r", "hand_r", "tail_01", "tail_04", "tail_fin"]:
    key_bone(b, 1, rot_deg=(0, 0, 0), loc=(0, 0, 0))

# F8: Anticipation - torso coils back, right arm pulls back gathering water
key_bone("pelvis", 8, loc=(0, 0.04, -0.02), rot_deg=(-6, 0, -12))
key_bone("spine_01", 8, rot_deg=(-8, 0, -10))
key_bone("spine_02", 8, rot_deg=(-10, 0, -8))
key_bone("Head", 8, rot_deg=(6, 0, 14))
key_bone("upperarm_r", 8, rot_deg=(-35, 25, 45))
key_bone("lowerarm_r", 8, rot_deg=(-55, 15, 0))
key_bone("hand_r", 8, rot_deg=(20, 0, 30))
key_bone("tail_01", 8, rot_deg=(-10, 0, 12))
key_bone("tail_04", 8, rot_deg=(15, 0, -10))
key_bone("tail_fin", 8, rot_deg=(-20, 15, 10))

# F13: Strike / Impact - explosive water whip forward
key_bone("pelvis", 13, loc=(0, -0.05, 0.03), rot_deg=(12, 0, 18))
key_bone("spine_01", 13, rot_deg=(16, 0, 15))
key_bone("spine_02", 13, rot_deg=(18, 0, 12))
key_bone("Head", 13, rot_deg=(-10, 0, -18))
key_bone("upperarm_r", 13, rot_deg=(48, -15, -35))
key_bone("lowerarm_r", 13, rot_deg=(15, -10, 0))
key_bone("hand_r", 13, rot_deg=(-25, 0, -20))
key_bone("tail_01", 13, rot_deg=(14, 0, -15))
key_bone("tail_04", 13, rot_deg=(-18, 0, 12))
key_bone("tail_fin", 13, rot_deg=(25, -18, -12))

# F18: Overshoot & follow-through
key_bone("pelvis", 18, loc=(0, -0.02, 0.01), rot_deg=(4, 0, 6))
key_bone("spine_01", 18, rot_deg=(5, 0, 4))
key_bone("upperarm_r", 18, rot_deg=(30, -5, -15))
key_bone("lowerarm_r", 18, rot_deg=(8, -5, 0))
key_bone("tail_fin", 18, rot_deg=(10, -5, -4))

# F26: Return to neutral
for b in ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01", "Head", "upperarm_r", "lowerarm_r", "hand_r", "tail_01", "tail_04", "tail_fin"]:
    key_bone(b, 26, rot_deg=(0, 0, 0), loc=(0, 0, 0))

track_attack = arm_obj.animation_data.nla_tracks.new()
track_attack.name = "Attack"
strip_attack = track_attack.strips.new("Attack", 1, act_attack)

# =========================================================================
# 3. STUNNED (Loop, 30 frames, 24 fps) - Slumped torso, shivering tail
# =========================================================================
act_stunned = bpy.data.actions.new("Stunned")
arm_obj.animation_data.action = act_stunned
num_frames_stun = 30

for f in range(1, num_frames_stun + 2):
    t = (f - 1) / float(num_frames_stun)
    shiver1 = math.sin(t * 8.0 * math.pi)
    shiver2 = math.cos(t * 12.0 * math.pi)
    sway = math.sin(t * 2.0 * math.pi)

    key_bone("pelvis", f, loc=(0, 0.02 * sway, -0.04), rot_deg=(-8 + 1.5 * shiver1, 0, 2.0 * sway))
    key_bone("spine_01", f, rot_deg=(-10 + 1.5 * shiver1, 0, 0))
    key_bone("spine_02", f, rot_deg=(-12, 0, 0))
    key_bone("neck_01", f, rot_deg=(12, 0, 1.0 * shiver2))
    key_bone("Head", f, rot_deg=(16 + 2.0 * shiver2, 0, 2.0 * shiver1))

    # Limp hanging arms
    key_bone("upperarm_l", f, rot_deg=(-12 + 1.5 * shiver1, 8, -6))
    key_bone("lowerarm_l", f, rot_deg=(18, 0, 0))
    key_bone("upperarm_r", f, rot_deg=(-12 + 1.5 * shiver1, -8, 6))
    key_bone("lowerarm_r", f, rot_deg=(18, 0, 0))

    # Trembling tail
    key_bone("tail_01", f, rot_deg=(-6 + 3.0 * shiver1, 2.0 * shiver2, 0))
    key_bone("tail_03", f, rot_deg=(8 + 4.0 * shiver2, -2.0 * shiver1, 0))
    key_bone("tail_fin", f, rot_deg=(-12 + 5.0 * shiver1, 3.0 * shiver2, 0))

track_stunned = arm_obj.animation_data.nla_tracks.new()
track_stunned.name = "Stunned"
strip_stunned = track_stunned.strips.new("Stunned", 1, act_stunned)

# =========================================================================
# 4. CHANNEL (Loop, 40 frames, 24 fps) - Siren incantation song, hands raised
# =========================================================================
act_channel = bpy.data.actions.new("Channel")
arm_obj.animation_data.action = act_channel
num_frames_chan = 40

for f in range(1, num_frames_chan + 2):
    t = (f - 1) / float(num_frames_chan)
    s1 = math.sin(t * 2.0 * math.pi)
    c1 = math.cos(t * 2.0 * math.pi)

    key_bone("pelvis", f, loc=(0, 0, 0.04 + 0.02 * s1), rot_deg=(4 * c1, 0, 2 * s1))
    key_bone("spine_01", f, rot_deg=(4 * c1, 0, 0))
    key_bone("spine_02", f, rot_deg=(6 * c1, 0, 0))
    key_bone("neck_01", f, rot_deg=(-6 * c1, 0, 0))
    key_bone("Head", f, rot_deg=(-10 + 3 * c1, 0, 0))

    # Hands brought near chest/mouth entreating hypnotic song
    key_bone("upperarm_l", f, rot_deg=(28 + 4 * s1, -18, 22))
    key_bone("lowerarm_l", f, rot_deg=(48 + 5 * c1, 15, 0))
    key_bone("hand_l", f, rot_deg=(15 * s1, 0, -10))

    key_bone("upperarm_r", f, rot_deg=(28 + 4 * s1, 18, -22))
    key_bone("lowerarm_r", f, rot_deg=(48 + 5 * c1, -15, 0))
    key_bone("hand_r", f, rot_deg=(15 * s1, 0, 10))

    # Hypnotic rhythmic tail wave
    for i, bname in enumerate(["tail_01", "tail_03", "tail_05", "tail_fin"]):
        ph = t * 2.0 * math.pi - i * 0.8
        key_bone(bname, f, rot_deg=(8 * math.sin(ph), 12 * math.cos(ph), 6 * math.sin(ph)))

track_channel = arm_obj.animation_data.nla_tracks.new()
track_channel.name = "Channel"
strip_channel = track_channel.strips.new("Channel", 1, act_channel)

# =========================================================================
# 5. DEATH (One-shot, 42 frames, 24 fps) - Gentle collapse onto the floor
# =========================================================================
act_death = bpy.data.actions.new("Death")
arm_obj.animation_data.action = act_death

for b in ["pelvis", "spine_01", "spine_02", "spine_03", "Head", "upperarm_l", "lowerarm_l", "upperarm_r", "lowerarm_r", "tail_01", "tail_03", "tail_fin"]:
    key_bone(b, 1, rot_deg=(0, 0, 0), loc=(0, 0, 0))

# F12: Loss of balance & strength
key_bone("pelvis", 12, loc=(0, -0.05, -0.10), rot_deg=(-15, 0, 10))
key_bone("spine_01", 12, rot_deg=(-12, 0, 8))
key_bone("Head", 12, rot_deg=(18, 0, -12))
key_bone("upperarm_l", 12, rot_deg=(-20, 10, -15))
key_bone("upperarm_r", 12, rot_deg=(-20, -10, 15))
key_bone("tail_01", 12, rot_deg=(-15, 0, -10))
key_bone("tail_fin", 12, rot_deg=(20, 0, 15))

# F28: Body collapses sideways toward ground
key_bone("pelvis", 28, loc=(-0.15, 0.05, -0.55), rot_deg=(-45, -25, 35))
key_bone("spine_01", 28, rot_deg=(-25, -15, 20))
key_bone("spine_02", 28, rot_deg=(-15, -10, 15))
key_bone("Head", 28, rot_deg=(25, 10, -25))
key_bone("upperarm_l", 28, rot_deg=(-45, 20, -35))
key_bone("upperarm_r", 28, rot_deg=(-35, -30, 20))
key_bone("tail_01", 28, rot_deg=(-35, 15, -30))
key_bone("tail_03", 28, rot_deg=(-20, 25, 20))
key_bone("tail_fin", 28, rot_deg=(-15, -30, -25))

# F42: Final resting posture on the side of the tail
key_bone("pelvis", 42, loc=(-0.25, 0.10, -0.72), rot_deg=(-65, -35, 45))
key_bone("spine_01", 42, rot_deg=(-30, -20, 25))
key_bone("spine_02", 42, rot_deg=(-20, -15, 18))
key_bone("Head", 42, rot_deg=(30, 15, -30))
key_bone("upperarm_l", 42, rot_deg=(-55, 25, -45))
key_bone("upperarm_r", 42, rot_deg=(-45, -35, 25))
key_bone("tail_01", 42, rot_deg=(-45, 20, -40))
key_bone("tail_03", 42, rot_deg=(-30, 30, 25))
key_bone("tail_fin", 42, rot_deg=(-25, -40, -35))

track_death = arm_obj.animation_data.nla_tracks.new()
track_death.name = "Death"
strip_death = track_death.strips.new("Death", 1, act_death)

# =========================================================================
# 6. ABILITY - "Bênção das Águas" (One-shot, 52 frames, 24 fps) - Majestic tidal invocation
# =========================================================================
act_ability = bpy.data.actions.new("Ability")
arm_obj.animation_data.action = act_ability

# F1: Neutral
for b in ["pelvis", "spine_01", "spine_02", "spine_03", "Head", "upperarm_l", "lowerarm_l", "hand_l", "upperarm_r", "lowerarm_r", "hand_r", "tail_01", "tail_04", "tail_fin", "fin_outer", "fin_inner"]:
    key_bone(b, 1, rot_deg=(0, 0, 0), loc=(0, 0, 0))

# F12: Deep anticipation coil - crouching into the tail
key_bone("pelvis", 12, loc=(0, 0.05, -0.06), rot_deg=(-12, 0, 0))
key_bone("spine_01", 12, rot_deg=(-10, 0, 0))
key_bone("Head", 12, rot_deg=(14, 0, 0))
key_bone("upperarm_l", 12, rot_deg=(20, 15, -25))
key_bone("lowerarm_l", 12, rot_deg=(65, 0, 0))
key_bone("upperarm_r", 12, rot_deg=(20, -15, 25))
key_bone("lowerarm_r", 12, rot_deg=(65, 0, 0))
key_bone("tail_01", 12, rot_deg=(-15, 0, 0))
key_bone("tail_04", 12, rot_deg=(22, 0, 0))
key_bone("tail_fin", 12, rot_deg=(-25, 0, 0))

# F24: Royal tidal elevation - rises majestic on tail base, arms burst wide open!
key_bone("pelvis", 24, loc=(0, -0.04, 0.14), rot_deg=(15, 0, 0))
key_bone("spine_01", 24, rot_deg=(18, 0, 0))
key_bone("spine_02", 24, rot_deg=(14, 0, 0))
key_bone("Head", 24, rot_deg=(-20, 0, 0))
key_bone("upperarm_l", 24, rot_deg=(15, -45, 68))
key_bone("lowerarm_l", 24, rot_deg=(25, -20, 0))
key_bone("hand_l", 24, rot_deg=(15, 0, -25))
key_bone("upperarm_r", 24, rot_deg=(15, 45, -68))
key_bone("lowerarm_r", 24, rot_deg=(25, 20, 0))
key_bone("hand_r", 24, rot_deg=(15, 0, 25))
key_bone("tail_01", 24, rot_deg=(20, 0, 0))
key_bone("tail_04", 24, rot_deg=(-28, 0, 0))
key_bone("tail_fin", 24, rot_deg=(35, 0, 0))
key_bone("fin_outer", 24, rot_deg=(15, 25, 0))
key_bone("fin_inner", 24, rot_deg=(-15, -25, 0))

# F36: Sustained crest - hovering in the water spray
key_bone("pelvis", 36, loc=(0, -0.02, 0.10), rot_deg=(8, 0, 0))
key_bone("spine_01", 36, rot_deg=(10, 0, 0))
key_bone("upperarm_l", 36, rot_deg=(20, -35, 55))
key_bone("upperarm_r", 36, rot_deg=(20, 35, -55))
key_bone("tail_fin", 36, rot_deg=(20, 0, 0))

# F52: Smooth return to royal Idle pose
for b in ["pelvis", "spine_01", "spine_02", "spine_03", "Head", "upperarm_l", "lowerarm_l", "hand_l", "upperarm_r", "lowerarm_r", "hand_r", "tail_01", "tail_04", "tail_fin", "fin_outer", "fin_inner"]:
    key_bone(b, 52, rot_deg=(0, 0, 0), loc=(0, 0, 0))

track_ability = arm_obj.animation_data.nla_tracks.new()
track_ability.name = "Ability"
strip_ability = track_ability.strips.new("Ability", 1, act_ability)

print("All 6 animation clips created and stashed in NLA tracks:")
for t in arm_obj.animation_data.nla_tracks:
    print(f"  - {t.name} (action: {t.strips[0].action.name if t.strips else 'None'})")

# Leave Idle as active action in viewport
arm_obj.animation_data.action = act_idle
bpy.ops.object.mode_set(mode='OBJECT')

# Save production blend
bpy.ops.wm.save_as_mainfile(filepath=FINAL_BLEND)
print(f"Saved blendfile with animations: {FINAL_BLEND}")

# =========================================================================
# 7. EXPORT TO GLB FOR GODOT 4.X
# =========================================================================
# Select mesh and armature
bpy.ops.object.select_all(action='DESELECT')
mesh_obj.select_set(True)
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj

print(f"Exporting binary glTF (.glb) to: {GLB_OUT}...")
bpy.ops.export_scene.gltf(
    filepath=GLB_OUT,
    export_format='GLB',
    use_selection=True,
    export_yup=True,
    export_apply=False,
    export_animations=True,
    export_animation_mode='NLA_TRACKS',
    export_materials='EXPORT',
    export_image_format='AUTO',
    export_leaf_bone=False,
    export_skins=True,
    export_morph=False
)
print(f"glTF export complete! File size: {os.path.getsize(GLB_OUT)} bytes")

# =========================================================================
# 8. Render Animation States Montage (Idle, Attack, Channel, Ability)
# =========================================================================
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items.keys() else 'BLENDER_EEVEE'
scene.render.resolution_x = 2400
scene.render.resolution_y = 600
scene.render.image_settings.file_format = 'PNG'

# Render each state still
states = [
    ("anim_idle", act_idle, 24),
    ("anim_attack", act_attack, 13),
    ("anim_channel", act_channel, 20),
    ("anim_ability", act_ability, 24),
]

temp_pngs = []
for sname, act, frame in states:
    arm_obj.animation_data.action = act
    scene.frame_set(frame)
    bpy.context.view_layer.update()
    sp = os.path.join(RENDER_DIR, f"{sname}.png")
    scene.render.filepath = sp
    scene.render.resolution_x = 600
    scene.render.resolution_y = 600
    bpy.ops.render.render(write_still=True)
    temp_pngs.append(sp)

# Create 4-panel animation montage
bpy.ops.wm.read_factory_settings(use_empty=True)
comp_scene = bpy.context.scene
comp_scene.render.resolution_x = 2400
comp_scene.render.resolution_y = 600
comp_scene.render.image_settings.file_format = 'PNG'
if not comp_scene.sequence_editor:
    comp_scene.sequence_editor_create()
seq = comp_scene.sequence_editor

for idx, ppath in enumerate(temp_pngs):
    st = seq.strips.new_image(name=f"Strip_{idx}", filepath=ppath, channel=idx+1, frame_start=1)
    st.blend_type = 'ALPHA_OVER'
    orig_img = bpy.data.images.load(ppath)
    iw, ih = orig_img.size
    scale_factor = 600.0 / max(iw, ih)
    st.transform.scale_x = scale_factor
    st.transform.scale_y = scale_factor
    st.transform.offset_x = -900 + idx * 600

montage_out = os.path.join(RENDER_DIR, "animations_montage.png")
comp_scene.frame_set(1)
comp_scene.render.filepath = montage_out
bpy.ops.render.render(write_still=True)
print(f"Rendered animations montage: {montage_out}")
