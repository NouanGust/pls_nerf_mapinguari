"""
Câmera com enquadramento completo (distância maior para caber os galhos horizontais e topo)
"""

import bpy
import math
from mathutils import Vector

scene = bpy.context.scene
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.film_transparent = True

cam_obj = bpy.data.objects.get("Camera")
scene.camera = cam_obj

# Ponto de foco centralizado na criatura
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

# Aumentamos a distância para 4.8m para enquadrar a silhueta retorcida por inteiro
angles = [
    ("blockout_front.png", 180.0, 4.8, 1.45),
    ("blockout_three_quarter.png", 145.0, 4.8, 1.55),
    ("blockout_side.png", 90.0, 4.8, 1.45),
    ("blockout_back.png", 0.0, 4.8, 1.45),
]

output_dir = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/renders/"

for filename, ang, dist, h in angles:
    setup_camera_orbit(dist, h, ang)
    scene.render.filepath = output_dir + filename
    bpy.ops.render.render(write_still=True)
    print(f"Renderizado: {output_dir + filename}")
