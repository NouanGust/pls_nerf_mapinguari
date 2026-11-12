"""
Ajuste da semente de espinhos e iluminação do Pequi
"""

import bpy
from mathutils import Vector

seed_obj = bpy.data.objects.get("Spike_Seed")
if seed_obj:
    seed_obj.location = Vector((0.0, 0.40, 1.48))
    # Aumentar tamanho do caroço
    seed_obj.scale = (1.4, 1.4, 1.4)
    bpy.context.view_layer.objects.active = seed_obj
    bpy.ops.object.transform_apply(location=False, scale=True)

# Aumentar energia do sol frontal
sun = bpy.data.objects.get("Sun")
if sun:
    sun.data.energy = 5.0
    sun.location = Vector((1.0, 3.0, 3.5))

# Adicionar uma luz pontual quente focada no fruto do pequi
l_fruit = bpy.data.objects.get("FruitGlow")
if not l_fruit:
    d = bpy.data.lights.new("FruitGlow", type='POINT')
    d.energy = 45.0
    d.color = (1.0, 0.75, 0.2)
    l_fruit = bpy.data.objects.new("FruitGlow", d)
    bpy.context.collection.objects.link(l_fruit)
l_fruit.location = Vector((0.0, 0.65, 1.60))

bpy.ops.wm.save_as_mainfile(filepath="C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi_blockout.blend")

