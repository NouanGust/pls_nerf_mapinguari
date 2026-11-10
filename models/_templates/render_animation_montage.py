import bpy
import os
from mathutils import Vector

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
FINAL_BLEND = os.path.join(ROOT_DIR, "models", "mae_dagua", "mae_dagua.blend")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "mae_dagua", "renders")

bpy.ops.wm.open_mainfile(filepath=FINAL_BLEND)
scene = bpy.context.scene

arm_obj = bpy.data.objects.get("MaeDagua_Armature")
mesh_obj = bpy.data.objects.get("MaeDagua")

# Clean mesh name & drivers
if mesh_obj:
    mesh_obj.data.name = "MaeDagua"
    mesh_obj.animation_data_clear()

cam_obj = bpy.data.objects.get("ValidationCam")
scene.camera = cam_obj
target = Vector((-0.06, 0.00, 0.92))
cam_obj.location = Vector((-1.85, -2.55, 1.10))
direction = (target - cam_obj.location).normalized()
cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items.keys() else 'BLENDER_EEVEE'
scene.render.resolution_x = 600
scene.render.resolution_y = 600
scene.render.image_settings.file_format = 'PNG'

# Disable NLA temporarily so we can preview and render individual actions directly
arm_obj.animation_data.use_nla = False

states = [
    ("anim_idle", "Idle", 24),
    ("anim_attack", "Attack", 13),
    ("anim_channel", "Channel", 20),
    ("anim_ability", "Ability", 24),
]

temp_pngs = []
for sname, act_name, frame in states:
    act = bpy.data.actions.get(act_name)
    if act:
        arm_obj.animation_data.action = act
        scene.frame_set(frame)
        bpy.context.view_layer.update()
        out_p = os.path.join(RENDER_DIR, f"{sname}.png")
        scene.render.filepath = out_p
        bpy.ops.render.render(write_still=True)
        temp_pngs.append(out_p)
        print(f"Rendered {sname} at frame {frame}")

# Re-enable NLA for export and production
arm_obj.animation_data.use_nla = True
arm_obj.animation_data.action = bpy.data.actions.get("Idle")
bpy.ops.wm.save_as_mainfile(filepath=FINAL_BLEND)

# Export GLB cleanly
GLB_OUT = os.path.join(ROOT_DIR, "models", "mae_dagua", "mae_dagua.glb")
bpy.ops.object.select_all(action='DESELECT')
mesh_obj.select_set(True)
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj

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
print(f"Clean GLB exported: {GLB_OUT} ({os.path.getsize(GLB_OUT)} bytes)")

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
