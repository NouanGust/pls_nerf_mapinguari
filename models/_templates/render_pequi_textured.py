"""
Renderiza a apresentação texturizada PBR do Pequi
"""

import bpy
import math
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath="C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi.blend")

scene = bpy.context.scene
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.film_transparent = True

cam_obj = bpy.data.objects.get("Camera")
if not cam_obj:
    c = bpy.data.cameras.new("Cam")
    cam_obj = bpy.data.objects.new("Camera", c)
    bpy.context.collection.objects.link(cam_obj)
scene.camera = cam_obj

# Luzes da cena (sol do Cerrado + luz de preenchimento)
sun = bpy.data.objects.get("Sun")
if not sun:
    l = bpy.data.lights.new("Sun", type='SUN')
    l.energy = 4.0
    l.color = (1.0, 0.95, 0.85)
    sun = bpy.data.objects.new("Sun", l)
    bpy.context.collection.objects.link(sun)
sun.rotation_euler = (math.radians(45), math.radians(25), math.radians(-40))

fill = bpy.data.objects.get("FillLight")
if not fill:
    l2 = bpy.data.lights.new("FillLight", type='POINT')
    l2.energy = 70.0
    l2.color = (0.7, 0.85, 1.0)
    fill = bpy.data.objects.new("FillLight", l2)
    bpy.context.collection.objects.link(fill)
fill.location = Vector((-2.0, -2.5, 2.0))

target = Vector((0.0, 0.0, 1.30))

def setup_camera_orbit(dist, height, angle_deg):
    rad = math.radians(angle_deg)
    cx = target.x + dist * math.sin(rad)
    cy = target.y - dist * math.cos(rad)
    cz = height
    cam_obj.location = Vector((cx, cy, cz))
    
    direction = target - cam_obj.location
    rot_quat = direction.to_track_quat('-Z', 'Y')
    cam_obj.rotation_euler = rot_quat.to_euler()

angles = [
    ("textured_front.png", 180.0, 4.8, 1.45),
    ("textured_three_quarter.png", 145.0, 4.8, 1.55),
    ("textured_side.png", 90.0, 4.8, 1.45),
    ("textured_back.png", 0.0, 4.8, 1.45),
]

output_dir = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/renders/"

for filename, ang, dist, h in angles:
    setup_camera_orbit(dist, h, ang)
    scene.render.filepath = output_dir + filename
    bpy.ops.render.render(write_still=True)
    print(f"Renderizado: {output_dir + filename}")

