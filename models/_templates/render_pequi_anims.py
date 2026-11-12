"""
Renderiza os frames-chave de cada animação do Pequi (com criação segura de câmera e iluminação)
"""

import bpy
import math
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath="C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi.blend")

scene = bpy.context.scene
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.film_transparent = True

arm_obj = bpy.data.objects.get("Pequi_Armature")

# Criar câmera se não existir
cam_obj = bpy.data.objects.get("Camera")
if not cam_obj:
    c = bpy.data.cameras.new("RenderCam")
    cam_obj = bpy.data.objects.new("Camera", c)
    bpy.context.collection.objects.link(cam_obj)
scene.camera = cam_obj

# Luzes
sun = bpy.data.objects.get("Sun")
if not sun:
    l = bpy.data.lights.new("Sun", type='SUN')
    l.energy = 4.0
    sun = bpy.data.objects.new("Sun", l)
    bpy.context.collection.objects.link(sun)
sun.rotation_euler = (math.radians(45), math.radians(25), math.radians(-40))

# Câmera frontal dinâmica em três quartos
target = Vector((0.0, 0.0, 1.30))
cam_obj.location = Vector((1.8, 4.2, 1.6))
direction = target - cam_obj.location
cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

output_dir = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/renders/"

anims = [
    ("anim_idle.png", "Idle", 30),
    ("anim_attack.png", "Attack", 20),
    ("anim_ability.png", "Ability", 30),
    ("anim_channel.png", "Channel", 15),
    ("anim_stunned.png", "Stunned", 20),
    ("anim_death.png", "Death", 38),
]

for filename, act_name, frame in anims:
    act = bpy.data.actions.get(act_name)
    if act:
        arm_obj.animation_data.action = act
        scene.frame_set(frame)
        scene.render.filepath = output_dir + filename
        bpy.ops.render.render(write_still=True)
        print(f"Renderizado: {output_dir + filename}")
