import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
FINAL_BLEND = os.path.join(ROOT_DIR, "models", "pequi", "pequi.blend")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "pequi", "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

bpy.ops.wm.open_mainfile(filepath=FINAL_BLEND)
scene = bpy.context.scene

unified = bpy.data.objects.get("Pequi")
if not unified:
    raise RuntimeError("Pequi mesh object not found in pequi.blend!")

# Remove any old armature if re-running
for obj in list(bpy.data.objects):
    if obj.type == 'ARMATURE':
        bpy.data.objects.remove(obj, do_unlink=True)
for m in list(unified.modifiers):
    if m.type == 'ARMATURE':
        unified.modifiers.remove(m)
unified.vertex_groups.clear()

rig_col = bpy.data.collections.get("RIG")
if not rig_col:
    rig_col = bpy.data.collections.new("RIG")
    scene.collection.children.link(rig_col)

# 1. Create Pequi_Armature (32 bones total — inside 25..45 budget)
arm_data = bpy.data.armatures.new("Pequi_Armature")
arm_data.display_type = 'OCTAHEDRAL'
arm_obj = bpy.data.objects.new("Pequi_Armature", arm_data)
rig_col.objects.link(arm_obj)

bpy.ops.object.select_all(action='DESELECT')
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='EDIT')
eb = arm_data.edit_bones

def make_bone(name, head, tail, parent_name=None, use_connect=False):
    b = eb.new(name)
    b.head = Vector(head)
    b.tail = Vector(tail)
    b.use_deform = True
    if parent_name and eb.get(parent_name):
        b.parent = eb.get(parent_name)
        b.use_connect = use_connect
    return b

# Core Trunk C-Arch Hierarchy (9 bones)
make_bone("root",      (0.00,  0.00, 0.00), (0.00,  0.00, 0.16))
make_bone("hips",      (0.00,  0.04, 0.16), (-0.12, 0.06, 0.36), "root")
make_bone("spine_01",  (-0.12, 0.06, 0.36), (-0.34, 0.08, 0.64), "hips", True)
make_bone("spine_02",  (-0.34, 0.08, 0.64), (-0.37, 0.05, 1.00), "spine_01", True)
make_bone("spine_03",  (-0.37, 0.05, 1.00), (-0.20, 0.02, 1.34), "spine_02", True)
make_bone("neck_01",   (-0.20, 0.02, 1.34), (-0.01, -0.02, 1.42), "spine_03", True)
make_bone("Head",      (-0.01, -0.02, 1.42), (0.08, -0.05, 1.26), "neck_01", True)
make_bone("beak_tip",  (0.08, -0.05, 1.26), (-0.02, -0.08, 1.07), "Head", True)
make_bone("sap_eye",   (-0.14, -0.02, 1.16), (0.01, -0.04, 1.24), "spine_03")

# Grounded Root Chains (5 bones)
make_bone("root_fl",   (-0.05,  0.00, 0.18), (-0.52, -0.36, 0.02), "root")
make_bone("root_fr",   ( 0.06, -0.02, 0.18), ( 0.48, -0.30, 0.02), "root")
make_bone("root_sl",   (-0.14,  0.04, 0.20), (-0.62,  0.08, 0.02), "root")
make_bone("root_bl",   (-0.08,  0.10, 0.18), (-0.42,  0.48, 0.02), "root")
make_bone("root_br",   ( 0.08,  0.08, 0.16), ( 0.44,  0.40, 0.02), "root")

# Cradle Branch & Split-Open Pequi Fruit (6 bones)
make_bone("cradle_01",        (-0.28,  0.02, 0.60), (-0.02, -0.09, 0.52), "spine_01")
make_bone("cradle_02",        (-0.02, -0.09, 0.52), ( 0.27, -0.14, 0.48), "cradle_01", True)
make_bone("cradle_03",        ( 0.27, -0.14, 0.48), ( 0.55, -0.09, 0.58), "cradle_02", True)
make_bone("fruit_valve_l",    ( 0.23, -0.14, 0.55), ( 0.13, -0.14, 0.72), "cradle_02")
make_bone("fruit_valve_r",    ( 0.31, -0.14, 0.55), ( 0.41, -0.14, 0.72), "cradle_02")
make_bone("fruit_inner_core", ( 0.27, -0.15, 0.58), ( 0.27, -0.15, 0.72), "cradle_02")

# Central Floating Spiny Seed & Arcane Orbits (3 bones)
make_bone("seed_core",    ( 0.02, -0.05, 0.89), ( 0.02, -0.20, 0.89), "spine_02")
make_bone("seed_orbit_l", (-0.12, -0.05, 0.89), (-0.12, -0.05, 1.05), "seed_core")
make_bone("seed_orbit_r", ( 0.16, -0.05, 0.89), ( 0.16, -0.05, 1.05), "seed_core")

# Canopy Branches, Closed Fruit Clusters & Foliage (9 bones)
make_bone("branch_up_r_01",   (-0.02,  0.00, 1.38), ( 0.32,  0.00, 1.26), "neck_01")
make_bone("branch_up_r_02",   ( 0.32,  0.00, 1.26), ( 0.58, -0.04, 0.94), "branch_up_r_01", True)
make_bone("fruit_cluster_r",  ( 0.40, -0.01, 1.18), ( 0.40, -0.02, 0.96), "branch_up_r_01")
make_bone("branch_crown_l_01",(-0.24,  0.04, 1.30), (-0.46,  0.04, 1.48), "spine_03")
make_bone("branch_crown_l_02",(-0.46,  0.04, 1.48), (-0.66, -0.02, 1.60), "branch_crown_l_01", True)
make_bone("branch_crown_top", (-0.10,  0.05, 1.38), ( 0.14,  0.02, 1.72), "neck_01")
make_bone("branch_low_l",     (-0.36,  0.04, 0.64), (-0.64, -0.06, 0.48), "spine_01")
make_bone("fruit_cluster_l",  (-0.30, -0.06, 0.48), (-0.30, -0.09, 0.28), "branch_low_l")
make_bone("foliage_back",     (-0.18,  0.14, 1.28), (-0.18,  0.28, 1.36), "spine_03")

total_bones = len(eb)
print(f"Total bones created in Pequi_Armature: {total_bones} (Spec budget: 25 - 45)")

bone_segments = {}
for b in eb:
    bone_segments[b.name] = (b.head.copy(), b.tail.copy())

bpy.ops.object.mode_set(mode='OBJECT')

# Parent mesh to armature with Armature modifier
unified.parent = arm_obj
arm_mod = unified.modifiers.new("Armature", 'ARMATURE')
arm_mod.object = arm_obj

for bname in bone_segments.keys():
    if bname not in unified.vertex_groups:
        unified.vertex_groups.new(name=bname)

def dist_point_to_segment(p, a, b):
    ab = b - a
    len_sq = ab.length_squared
    if len_sq < 1e-8:
        return (p - a).length
    t = max(0.0, min(1.0, (p - a).dot(ab) / len_sq))
    proj = a + t * ab
    return (p - proj).length

bm = bmesh.new()
bm.from_mesh(unified.data)
bm.verts.ensure_lookup_table()

visited = set()
islands = []
for v in bm.verts:
    if v.index in visited:
        continue
    stack = [v]
    comp = []
    visited.add(v.index)
    while stack:
        curr = stack.pop()
        comp.append(curr.index)
        for e in curr.link_edges:
            other = e.other_vert(curr)
            if other.index not in visited:
                visited.add(other.index)
                stack.append(other)
    center = sum((bm.verts[idx].co for idx in comp), Vector((0, 0, 0))) / len(comp)
    islands.append((comp, center))

bm.free()

seed_center = Vector((0.02, -0.05, 0.89))
fruit_center = Vector((0.27, -0.14, 0.60))

special_bones = {"seed_core", "seed_orbit_l", "seed_orbit_r", "fruit_valve_l", "fruit_valve_r", "fruit_inner_core", "fruit_cluster_r", "fruit_cluster_l"}
structural_bones = [bn for bn in bone_segments.keys() if bn not in special_bones]

mesh_verts = unified.data.vertices

for comp, center in islands:
    # Check bounding radius of every vertex in the island relative to seed_center & fruit_center
    max_dist_to_seed = max((mesh_verts[idx].co - seed_center).length for idx in comp)
    max_dist_to_fruit = max((mesh_verts[idx].co - fruit_center).length for idx in comp)
    min_z_island = min(mesh_verts[idx].co.z for idx in comp)

    # 1. Floating Spiny Seed + Thorns + Orbits: ALL vertices strictly inside 0.25m of seed_center and above Z=0.68m
    if max_dist_to_seed < 0.245 and min_z_island > 0.68:
        if max_dist_to_seed > 0.185 and len(comp) > 25:
            target_vg = "seed_orbit_l" if center.z >= seed_center.z else "seed_orbit_r"
            for idx in comp:
                unified.vertex_groups[target_vg].add([idx], 1.0, 'REPLACE')
        else:
            for idx in comp:
                unified.vertex_groups["seed_core"].add([idx], 1.0, 'REPLACE')
        continue

    # 2. Split-Open Pequi Fruit Halves, Pulp & Oil Drops: ALL vertices strictly inside 0.25m of fruit_center
    if max_dist_to_fruit < 0.245 and min_z_island > 0.42:
        if abs(center.x - fruit_center.x) < 0.025 and center.z > 0.62:
            for idx in comp:
                unified.vertex_groups["fruit_inner_core"].add([idx], 0.85, 'REPLACE')
                unified.vertex_groups["cradle_02"].add([idx], 0.15, 'ADD')
        elif center.x < fruit_center.x:
            for idx in comp:
                unified.vertex_groups["fruit_valve_l"].add([idx], 0.85, 'REPLACE')
                unified.vertex_groups["cradle_02"].add([idx], 0.15, 'ADD')
        else:
            for idx in comp:
                unified.vertex_groups["fruit_valve_r"].add([idx], 0.85, 'REPLACE')
                unified.vertex_groups["cradle_02"].add([idx], 0.15, 'ADD')
        continue

    # 3. Upper-right closed fruits: all vertices strictly inside 0.22m of (0.40, 0.0, 1.11)
    if max((mesh_verts[idx].co - Vector((0.40, 0.0, 1.11))).length for idx in comp) < 0.22:
        for idx in comp:
            unified.vertex_groups["fruit_cluster_r"].add([idx], 0.85, 'REPLACE')
            unified.vertex_groups["branch_up_r_01"].add([idx], 0.15, 'ADD')
        continue

    # 4. Lower-left closed fruits: all vertices strictly inside 0.22m of (-0.30, -0.09, 0.40)
    if max((mesh_verts[idx].co - Vector((-0.30, -0.09, 0.40))).length for idx in comp) < 0.22:
        for idx in comp:
            unified.vertex_groups["fruit_cluster_l"].add([idx], 0.85, 'REPLACE')
            unified.vertex_groups["branch_low_l"].add([idx], 0.15, 'ADD')
        continue

    # 5. Structural Trunk, Roots, Cradle Branch, Canopy Branches & Leaves: per-vertex smooth skinning
    for idx in comp:
        co = mesh_verts[idx].co
        if co.z < 0.04:
            unified.vertex_groups["root"].add([idx], 0.70, 'REPLACE')
        dists = []
        for bname in structural_bones:
            a, b = bone_segments[bname]
            d = dist_point_to_segment(co, a, b)
            dists.append((d, bname))
        dists.sort(key=lambda x: x[0])
        top3 = dists[:3]
        inv_weights = [1.0 / (max(d, 0.018) ** 2.5) for d, _ in top3]
        w_sum = sum(inv_weights)
        for (d, bname), iw in zip(top3, inv_weights):
            unified.vertex_groups[bname].add([idx], iw / w_sum, 'ADD')

# Strictly enforce <= 4 influences per vertex and normalize all weights
bpy.ops.object.select_all(action='DESELECT')
unified.select_set(True)
bpy.context.view_layer.objects.active = unified
bpy.ops.object.vertex_group_limit_total(limit=4)
bpy.ops.object.vertex_group_clean(group_select_mode='ALL', limit=0.01)
bpy.ops.object.vertex_group_normalize_all(lock_active=False)

max_influences = max(len(v.groups) for v in unified.data.vertices)
print(f"Verified max bone influences per vertex: {max_influences} (Spec limit: <= 4)")

# Render 3 Extreme Test Poses to validate skinning deformation
for o in bpy.data.collections["REFS"].objects:
    o.hide_render = False
    o.hide_set(False)

scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE'
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.film_transparent = True

cam_obj = bpy.data.objects.get("RenderCam")
scene.camera = cam_obj
center_target = Vector((0.02, 0.0, 0.86))
cam_obj.location = Vector((2.95 * 0.55, -2.95 * 0.83, 1.00))
direction = center_target - cam_obj.location
cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()

def reset_pose(arm):
    for pb in arm.pose.bones:
        pb.rotation_mode = 'XYZ'
        pb.location = (0.0, 0.0, 0.0)
        pb.rotation_euler = (0.0, 0.0, 0.0)
        pb.scale = (1.0, 1.0, 1.0)

bpy.ops.object.select_all(action='DESELECT')
arm_obj.select_set(True)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='POSE')
pb = arm_obj.pose.bones

# Extreme Pose 1: Expansão da Copa & Arremesso da Semente
reset_pose(arm_obj)
pb["spine_01"].rotation_euler = (math.radians(-6), math.radians(-5), 0)
pb["spine_02"].rotation_euler = (math.radians(-8), math.radians(-6), 0)
pb["neck_01"].rotation_euler  = (math.radians(-10), 0, 0)
pb["cradle_01"].rotation_euler = (math.radians(8), 0, math.radians(-6))
pb["fruit_valve_l"].rotation_euler = (0, math.radians(-22), 0)
pb["fruit_valve_r"].rotation_euler = (0, math.radians(22), 0)
pb["seed_core"].location = (0.0, 0.24, 0.05)
pb["seed_core"].rotation_euler = (math.radians(35), math.radians(45), math.radians(25))
pb["seed_core"].scale = (1.20, 1.20, 1.20)
bpy.context.view_layer.update()
pose1_path = os.path.join(RENDER_DIR, "pose_test_1_expand.png")
scene.render.filepath = pose1_path
bpy.ops.render.render(write_still=True)

# Extreme Pose 2: Torção Espiral do Tronco & Giro das Órbitas
reset_pose(arm_obj)
pb["spine_01"].rotation_euler = (math.radians(5), math.radians(8), math.radians(12))
pb["spine_02"].rotation_euler = (math.radians(5), math.radians(8), math.radians(15))
pb["spine_03"].rotation_euler = (0, math.radians(-8), math.radians(12))
pb["cradle_01"].rotation_euler = (0, math.radians(10), math.radians(12))
pb["seed_core"].rotation_euler = (math.radians(-30), math.radians(65), math.radians(-40))
pb["seed_orbit_l"].rotation_euler = (math.radians(55), math.radians(35), 0)
pb["seed_orbit_r"].rotation_euler = (math.radians(-55), math.radians(-35), 0)
bpy.context.view_layer.update()
pose2_path = os.path.join(RENDER_DIR, "pose_test_2_twist.png")
scene.render.filepath = pose2_path
bpy.ops.render.render(write_still=True)

# Extreme Pose 3: Compressão / Agachamento Defensivo
reset_pose(arm_obj)
pb["hips"].rotation_euler = (math.radians(8), math.radians(5), 0)
pb["spine_01"].rotation_euler = (math.radians(12), math.radians(10), 0)
pb["spine_02"].rotation_euler = (math.radians(14), math.radians(8), 0)
pb["Head"].rotation_euler = (math.radians(16), 0, 0)
pb["cradle_01"].rotation_euler = (math.radians(-10), 0, math.radians(8))
pb["fruit_valve_l"].rotation_euler = (0, math.radians(16), 0)
pb["fruit_valve_r"].rotation_euler = (0, math.radians(-16), 0)
pb["seed_core"].location = (0.04, -0.05, -0.14)
pb["seed_core"].scale = (0.85, 0.85, 0.85)
bpy.context.view_layer.update()
pose3_path = os.path.join(RENDER_DIR, "pose_test_3_crouch.png")
scene.render.filepath = pose3_path
bpy.ops.render.render(write_still=True)

# Reset to clean Rest Pose before saving pequi.blend
reset_pose(arm_obj)
bpy.ops.object.mode_set(mode='OBJECT')

for o in bpy.data.collections["REFS"].objects:
    o.hide_render = True
    o.hide_set(True)

bpy.ops.wm.save_as_mainfile(filepath=FINAL_BLEND)
print(f"Saved rigged pequi.blend in Rest Pose: {FINAL_BLEND}")
