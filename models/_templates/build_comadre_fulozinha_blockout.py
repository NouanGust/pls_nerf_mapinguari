import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
BUNDLE_PATH = os.path.join(ROOT_DIR, "docs", "human-base-mesh-bundle", "human_base_meshes_bundle.blend")
OUT_BLEND = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "comadre_fulozinha_blockout.blend")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

# 1. Reset scene
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene["unit_name"] = "ComadreFulozinha"

# Setup collections
col_geo = bpy.data.collections.new("GEO")
col_rig = bpy.data.collections.new("RIG")
col_anim = bpy.data.collections.new("ANIM")
col_refs = bpy.data.collections.new("REFS")
for c in (col_geo, col_rig, col_anim, col_refs):
    scene.collection.children.link(c)

def make_mat(name, hex_color, roughness=0.55, metallic=0.0, emission_strength=0.0):
    mat = bpy.data.materials.new(name=name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    h = hex_color.lstrip('#')
    rgb = tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    lin = tuple(pow(c, 2.2) for c in rgb)
    bsdf.inputs["Base Color"].default_value = (*lin, 1.0)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    if emission_strength > 0.0 and "Emission Color" in bsdf.inputs:
        bsdf.inputs["Emission Color"].default_value = (*lin, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat

mats = {
    "skin": make_mat("Mat_Skin", "#7E482B", roughness=0.55),
    "hair": make_mat("Mat_Hair", "#161314", roughness=0.70),
    "urtiga": make_mat("Mat_Urtiga", "#2F5227", roughness=0.40),
    "cipo": make_mat("Mat_Cipo", "#4B3621", roughness=0.50),
    "fulo": make_mat("Mat_Fulo", "#D48B28", roughness=0.60),
    "fulo_amber": make_mat("Mat_FuloAmber", "#E0C068", roughness=0.55),
    "eye": make_mat("Mat_EyeJabuticaba", "#0C080E", roughness=0.10),
    "glow": make_mat("Mat_UrtigaGlow", "#5AE38C", roughness=0.30, emission_strength=1.5),
}

def link_to_geo(obj, mat=None):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    col_geo.objects.link(obj)
    if mat:
        obj.data.materials.clear()
        obj.data.materials.append(mat)
    if hasattr(obj.data, "polygons"):
        for poly in obj.data.polygons:
            poly.use_smooth = True

print("=== 1. Loading GEO-body_female_stylized from bundle ===")
with bpy.data.libraries.load(BUNDLE_PATH, link=False) as (data_from, data_to):
    data_to.objects = [
        "GEO-body_female_stylized",
        "GEO-body_female_stylized.eye.L",
        "GEO-body_female_stylized.eye.R"
    ]

body = None
eyes = []
for o in data_to.objects:
    scene.collection.objects.link(o)
    if "eye" in o.name.lower():
        eyes.append(o)
    else:
        body = o

bpy.context.view_layer.update()

# Clear drivers/modifiers
for obj in [body] + eyes:
    obj.animation_data_clear()
    for m in list(obj.modifiers):
        obj.modifiers.remove(m)

# Unparent eyes, center X at 0
for eye in eyes:
    mw = eye.matrix_world.copy()
    eye.parent = None
    eye.matrix_world = mw

body_offset_x = body.location.x
body.location.x = 0.0
for eye in eyes:
    eye.location.x -= body_offset_x

bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
bpy.context.view_layer.objects.active = body
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

for eye in eyes:
    eye.select_set(True)
    bpy.context.view_layer.objects.active = eye
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    link_to_geo(eye, mats["eye"])

link_to_geo(body, mats["skin"])

# 2. Rescale & Proportion Body into Juvenile Cabocla (~1.35 m tall, ~5.8 heads)
# Original base mesh: feet ~0.0m, top of head ~1.60m -> 1.60m tall
# Let's analyze bounding box and rescale vertices
bm_body = bmesh.new()
bm_body.from_mesh(body.data)

min_z = min(v.co.z for v in bm_body.verts)
max_z = max(v.co.z for v in bm_body.verts)
orig_height = max_z - min_z

target_height = 1.35
scale_factor = target_height / orig_height

# Adjust proportions: scale down body, but keep head slightly larger (~1.12x relative)
# and narrow the waist/torso slightly for a slender juvenile build (franzina)
for v in bm_body.verts:
    # shift to ground at min_z = 0
    v.co.z -= min_z
    
    z_norm = v.co.z / orig_height
    # Scale coordinates
    v.co.x *= scale_factor
    v.co.y *= scale_factor
    v.co.z *= scale_factor
    
    # Juvenile adjustment:
    # Head (z_norm > 0.85): slight boost to head size for 5.8 head proportion
    if z_norm > 0.82:
        head_factor = 1.08
        head_center_z = 1.22
        v.co.x *= head_factor
        v.co.y *= head_factor
        v.co.z = head_center_z + (v.co.z - head_center_z) * head_factor
    elif z_norm > 0.40 and z_norm <= 0.82:
        # Torso and hips: slender, narrower waist
        v.co.x *= 0.92
        v.co.y *= 0.92

bm_body.to_mesh(body.data)
bm_body.free()
body.data.update()

# Also scale and adjust eyes to match the head
for eye in eyes:
    bm_eye = bmesh.new()
    bm_eye.from_mesh(eye.data)
    for v in bm_eye.verts:
        v.co.z -= min_z
        v.co.x *= scale_factor
        v.co.y *= scale_factor
        v.co.z *= scale_factor
        head_factor = 1.08
        head_center_z = 1.22
        v.co.x *= head_factor
        v.co.y *= head_factor
        v.co.z = head_center_z + (v.co.z - head_center_z) * head_factor
    bm_eye.to_mesh(eye.data)
    bm_eye.free()
    eye.data.update()

# Recalculate new bounding box
min_z_new = min(v.co.z for v in body.data.vertices)
max_z_new = max(v.co.z for v in body.data.vertices)
print(f"Juvenile body scaled: height = {max_z_new - min_z_new:.3f}m (Z: {min_z_new:.3f} to {max_z_new:.3f})")

# 3. Create Scalp Hair Cap from top of the head
bm_body = bmesh.new()
bm_body.from_mesh(body.data)
scalp_faces = [f for f in bm_body.faces if f.calc_center_median().z > 1.28 or (f.calc_center_median().z > 1.22 and f.calc_center_median().y > -0.035)]
bm_scalp = bmesh.new()
vmap = {}
for f in scalp_faces:
    for v in f.verts:
        if v not in vmap:
            n_off = v.normal * 0.007
            vmap[v] = bm_scalp.verts.new(v.co + n_off)
    bm_scalp.faces.new([vmap[v] for v in f.verts])

scalp_mesh = bpy.data.meshes.new("GEO_Hair_Cap")
bm_scalp.to_mesh(scalp_mesh)
bm_scalp.free()
bm_body.free()

scalp_obj = bpy.data.objects.new("GEO_Hair_Cap", scalp_mesh)
link_to_geo(scalp_obj, mats["hair"])
solid_scalp = scalp_obj.modifiers.new("Solidify", 'SOLIDIFY')
solid_scalp.thickness = 0.009
solid_scalp.offset = 1.0
bpy.context.view_layer.objects.active = scalp_obj
bpy.ops.object.modifier_apply(modifier="Solidify")

# 4. Build Colossal Hair Mantle (Manto de Cabelo Vivo)
# Comadre Fulozinha is covered by her colossal hair mantle down to her knees/calves.
# We create organic hair lock ribbons/tapered tubes cascading:
# - Back cloak (layers down to Z = 0.35m - knee height)
# - Side cascades framing the shoulders and torso
# - Front chest & hip covering locks (vestimenta de cabelo)

def create_hair_lock(name, points, radii, mat=mats["hair"], segments=8):
    curve_data = bpy.data.curves.new(name=name, type='CURVE')
    curve_data.dimensions = '3D'
    spline = curve_data.splines.new('BEZIER')
    spline.bezier_points.add(len(points) - 1)
    
    for i, pt in enumerate(points):
        bp = spline.bezier_points[i]
        bp.co = pt
        bp.radius = radii[i]
        bp.handle_left_type = 'AUTO'
        bp.handle_right_type = 'AUTO'
        
    curve_data.bevel_depth = 0.035
    curve_data.bevel_resolution = 3
    curve_data.resolution_u = 8
    
    obj = bpy.data.objects.new(name, curve_data)
    link_to_geo(obj, mat)
    
    # Convert to mesh for clean blockout geometry
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target='MESH')
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj

# Hair Lock Layers (Back cloak, left/right cascades, front locks)
hair_locks_data = [
    # Center Back Cascade 1 (long to calves)
    ("Hair_Back_Center_01", [Vector((0.0, 0.04, 1.32)), Vector((0.0, 0.12, 1.15)), Vector((0.0, 0.16, 0.90)), Vector((0.02, 0.18, 0.65)), Vector((0.0, 0.15, 0.38))], [1.2, 1.4, 1.5, 1.2, 0.5]),
    # Center Back Cascade 2 (deep mantle)
    ("Hair_Back_Center_02", [Vector((-0.04, 0.03, 1.31)), Vector((-0.06, 0.13, 1.12)), Vector((-0.08, 0.17, 0.85)), Vector((-0.06, 0.16, 0.55)), Vector((-0.04, 0.13, 0.34))], [1.1, 1.3, 1.4, 1.1, 0.4]),
    ("Hair_Back_Center_03", [Vector((0.04, 0.03, 1.31)), Vector((0.06, 0.13, 1.12)), Vector((0.08, 0.17, 0.85)), Vector((0.06, 0.16, 0.55)), Vector((0.04, 0.13, 0.34))], [1.1, 1.3, 1.4, 1.1, 0.4]),
    
    # Back-Left Mantle (covering left shoulder and ribcage to thigh)
    ("Hair_Back_L_01", [Vector((-0.08, 0.02, 1.30)), Vector((-0.16, 0.08, 1.10)), Vector((-0.20, 0.12, 0.88)), Vector((-0.17, 0.11, 0.60)), Vector((-0.12, 0.08, 0.40))], [1.0, 1.3, 1.4, 1.1, 0.4]),
    ("Hair_Back_L_02", [Vector((-0.11, -0.01, 1.28)), Vector((-0.20, 0.05, 1.08)), Vector((-0.24, 0.09, 0.82)), Vector((-0.20, 0.07, 0.55)), Vector((-0.15, 0.04, 0.42))], [0.9, 1.2, 1.3, 1.0, 0.3]),
    
    # Back-Right Mantle (covering right shoulder to thigh)
    ("Hair_Back_R_01", [Vector((0.08, 0.02, 1.30)), Vector((0.16, 0.08, 1.10)), Vector((0.20, 0.12, 0.88)), Vector((0.17, 0.11, 0.60)), Vector((0.12, 0.08, 0.40))], [1.0, 1.3, 1.4, 1.1, 0.4]),
    ("Hair_Back_R_02", [Vector((0.11, -0.01, 1.28)), Vector((0.20, 0.05, 1.08)), Vector((0.24, 0.09, 0.82)), Vector((0.20, 0.07, 0.55)), Vector((0.15, 0.04, 0.42))], [0.9, 1.2, 1.3, 1.0, 0.3]),
    
    # Front-Left Vestment Locks (covering chest, waist down to hip)
    ("Hair_Front_L_01", [Vector((-0.07, -0.03, 1.28)), Vector((-0.12, -0.07, 1.12)), Vector((-0.10, -0.09, 0.94)), Vector((-0.08, -0.08, 0.76)), Vector((-0.06, -0.05, 0.58))], [0.9, 1.2, 1.2, 0.9, 0.3]),
    ("Hair_Front_L_02", [Vector((-0.05, -0.04, 1.27)), Vector((-0.06, -0.08, 1.08)), Vector((-0.04, -0.10, 0.90)), Vector((-0.05, -0.09, 0.72)), Vector((-0.06, -0.06, 0.52))], [0.8, 1.1, 1.1, 0.8, 0.3]),
    
    # Front-Right Vestment Locks
    ("Hair_Front_R_01", [Vector((0.07, -0.03, 1.28)), Vector((0.12, -0.07, 1.12)), Vector((0.10, -0.09, 0.94)), Vector((0.08, -0.08, 0.76)), Vector((0.06, -0.05, 0.58))], [0.9, 1.2, 1.2, 0.9, 0.3]),
    ("Hair_Front_R_02", [Vector((0.05, -0.04, 1.27)), Vector((0.06, -0.08, 1.08)), Vector((0.04, -0.10, 0.90)), Vector((0.05, -0.09, 0.72)), Vector((0.06, -0.06, 0.52))], [0.8, 1.1, 1.1, 0.8, 0.3]),
    
    # Wild framing tendrils (florestal/desalinhado)
    ("Hair_Tendril_L", [Vector((-0.12, -0.02, 1.29)), Vector((-0.22, 0.01, 1.18)), Vector((-0.25, -0.04, 1.02)), Vector((-0.20, -0.06, 0.85))], [0.7, 0.8, 0.6, 0.2]),
    ("Hair_Tendril_R", [Vector((0.12, -0.02, 1.29)), Vector((0.22, 0.01, 1.18)), Vector((0.25, -0.04, 1.02)), Vector((0.20, -0.06, 0.85))], [0.7, 0.8, 0.6, 0.2]),
]

hair_objs = []
for name, pts, rads in hair_locks_data:
    obj = create_hair_lock(name, pts, rads, mats["hair"])
    hair_objs.append(obj)

# 5. Build Stinging Nettle (Urtiga) Vines & Serrated Leaves entwined in the hair
# Urtica has serrated, heart-ovate leaves on fibrous stems.
def create_urtiga_leaf(name, loc, rot, scale=Vector((0.035, 0.055, 0.006))):
    # Oval-triangular leaf shape with denteated silhouette
    bm = bmesh.new()
    # 7 points for a stylized serrated leaf
    v0 = bm.verts.new((0.0, 0.0, 0.0)) # stem base
    v1 = bm.verts.new((-0.6, 0.3, 0.05)) # tooth 1 left
    v2 = bm.verts.new((-0.8, 0.6, 0.02)) # tooth 2 left
    v3 = bm.verts.new((-0.4, 0.85, 0.01))# tooth 3 left
    v4 = bm.verts.new((0.0, 1.0, 0.0))   # apex tip
    v5 = bm.verts.new((0.4, 0.85, 0.01)) # tooth 3 right
    v6 = bm.verts.new((0.8, 0.6, 0.02))  # tooth 2 right
    v7 = bm.verts.new((0.6, 0.3, 0.05))  # tooth 1 right
    
    bm.faces.new([v0, v1, v2, v3, v4, v5, v6, v7])
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    obj.rotation_euler = rot
    obj.scale = scale
    link_to_geo(obj, mats["urtiga"])
    
    # Add solidify
    mod = obj.modifiers.new("Solidify", 'SOLIDIFY')
    mod.thickness = 0.003
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    return obj

urtiga_leaf_positions = [
    # Crown foliage (head / hair top)
    ("Urtiga_Crown_01", Vector((0.03, 0.05, 1.38)), Euler((math.radians(35), math.radians(15), math.radians(40))), Vector((0.030, 0.050, 0.006))),
    ("Urtiga_Crown_02", Vector((-0.05, 0.04, 1.36)), Euler((math.radians(40), math.radians(-25), math.radians(-30))), Vector((0.032, 0.052, 0.006))),
    ("Urtiga_Crown_03", Vector((0.08, -0.01, 1.34)), Euler((math.radians(20), math.radians(45), math.radians(70))), Vector((0.028, 0.046, 0.006))),
    ("Urtiga_Crown_04", Vector((-0.09, -0.01, 1.33)), Euler((math.radians(25), math.radians(-40), math.radians(-65))), Vector((0.028, 0.046, 0.006))),
    # Shoulder & Mantle branches
    ("Urtiga_Shoulder_L", Vector((-0.18, 0.05, 1.15)), Euler((math.radians(45), math.radians(-30), math.radians(-20))), Vector((0.035, 0.058, 0.006))),
    ("Urtiga_Shoulder_R", Vector((0.18, 0.05, 1.15)), Euler((math.radians(45), math.radians(30), math.radians(20))), Vector((0.035, 0.058, 0.006))),
    ("Urtiga_Back_01", Vector((0.00, 0.15, 0.95)), Euler((math.radians(70), math.radians(10), math.radians(180))), Vector((0.038, 0.062, 0.006))),
    ("Urtiga_Back_02", Vector((-0.08, 0.16, 0.78)), Euler((math.radians(65), math.radians(-20), math.radians(160))), Vector((0.036, 0.058, 0.006))),
    ("Urtiga_Back_03", Vector((0.08, 0.16, 0.78)), Euler((math.radians(65), math.radians(20), math.radians(-160))), Vector((0.036, 0.058, 0.006))),
    ("Urtiga_Hip_L", Vector((-0.14, 0.08, 0.62)), Euler((math.radians(30), math.radians(-15), math.radians(-45))), Vector((0.034, 0.055, 0.006))),
    ("Urtiga_Hip_R", Vector((0.14, 0.08, 0.62)), Euler((math.radians(30), math.radians(15), math.radians(45))), Vector((0.034, 0.055, 0.006))),
]

urtiga_objs = []
for name, loc, rot, scl in urtiga_leaf_positions:
    obj = create_urtiga_leaf(name, loc, rot, scl)
    urtiga_objs.append(obj)

# 6. Add Wild Forest Flowers (Fulô)
# 5-petaled small forest flower
def create_forest_flower(name, loc, rot, radius=0.022, mat=mats["fulo"]):
    bm = bmesh.new()
    v_center = bm.verts.new((0.0, 0.0, 0.005))
    petal_verts = []
    num_petals = 5
    for i in range(num_petals):
        angle = i * (2.0 * math.pi / num_petals)
        angle_half = angle + (math.pi / num_petals)
        
        # Outer tip
        px = math.cos(angle) * radius
        py = math.sin(angle) * radius
        pz = 0.0
        v_tip = bm.verts.new((px, py, pz))
        
        # Intermediate side
        sx = math.cos(angle_half) * (radius * 0.45)
        sy = math.sin(angle_half) * (radius * 0.45)
        v_side = bm.verts.new((sx, sy, 0.002))
        
        petal_verts.extend([v_tip, v_side])
        
    for i in range(num_petals):
        v_tip = petal_verts[i*2]
        v_side = petal_verts[i*2 + 1]
        v_prev_side = petal_verts[(i*2 - 1) % len(petal_verts)]
        bm.faces.new([v_center, v_prev_side, v_tip, v_side])
        
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    obj.rotation_euler = rot
    link_to_geo(obj, mat)
    
    mod = obj.modifiers.new("Solidify", 'SOLIDIFY')
    mod.thickness = 0.003
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    return obj

flower_positions = [
    ("Fulo_Head_01", Vector((0.05, 0.02, 1.37)), Euler((math.radians(35), math.radians(20), math.radians(15))), 0.022, mats["fulo"]),
    ("Fulo_Head_02", Vector((-0.06, 0.01, 1.35)), Euler((math.radians(30), math.radians(-30), math.radians(-10))), 0.019, mats["fulo_amber"]),
    ("Fulo_Chest_01", Vector((-0.04, -0.09, 0.96)), Euler((math.radians(-15), math.radians(-10), math.radians(45))), 0.018, mats["fulo"]),
    ("Fulo_Back_01", Vector((0.04, 0.16, 0.88)), Euler((math.radians(80), math.radians(15), math.radians(120))), 0.024, mats["fulo_amber"]),
    ("Fulo_Back_02", Vector((-0.03, 0.15, 0.68)), Euler((math.radians(75), math.radians(-10), math.radians(150))), 0.020, mats["fulo"]),
    ("Fulo_Hip_R", Vector((0.11, 0.06, 0.58)), Euler((math.radians(40), math.radians(30), math.radians(60))), 0.020, mats["fulo"]),
]

flower_objs = []
for name, loc, rot, rad, fmat in flower_positions:
    obj = create_forest_flower(name, loc, rot, rad, fmat)
    flower_objs.append(obj)

# 7. Build Vine & Stinging Nettle Whip (Chicote de Cipó e Urtiga)
# Held in right hand (around X=0.28, Y=-0.08, Z=0.68), sweeping in dynamic curve down to ground
whip_points = [
    Vector((0.26, -0.06, 0.70)),   # Grip in right hand
    Vector((0.34, -0.12, 0.73)),   # Loop forward/up
    Vector((0.44, -0.14, 0.65)),   # Arc right
    Vector((0.48, -0.06, 0.48)),   # Arc down
    Vector((0.42, 0.08, 0.32)),    # Arc behind/lower
    Vector((0.30, 0.18, 0.18)),    # Sweeping near feet
    Vector((0.18, 0.22, 0.06)),    # Ground touch
    Vector((0.08, 0.24, 0.01)),    # Tip spiral on floor
]
whip_radii = [0.8, 0.75, 0.65, 0.55, 0.45, 0.40, 0.35, 0.25]

curve_whip = bpy.data.curves.new(name="GEO_Chicote_Cipo", type='CURVE')
curve_whip.dimensions = '3D'
spline_whip = curve_whip.splines.new('BEZIER')
spline_whip.bezier_points.add(len(whip_points) - 1)

for i, pt in enumerate(whip_points):
    bp = spline_whip.bezier_points[i]
    bp.co = pt
    bp.radius = whip_radii[i]
    bp.handle_left_type = 'AUTO'
    bp.handle_right_type = 'AUTO'

curve_whip.bevel_depth = 0.015
curve_whip.bevel_resolution = 3
curve_whip.resolution_u = 12

whip_obj = bpy.data.objects.new("GEO_Chicote_Cipo", curve_whip)
link_to_geo(whip_obj, mats["cipo"])
bpy.ops.object.select_all(action='DESELECT')
whip_obj.select_set(True)
bpy.context.view_layer.objects.active = whip_obj
bpy.ops.object.convert(target='MESH')
for poly in whip_obj.data.polygons:
    poly.use_smooth = True

# Add small nettle thorn clusters on whip
whip_thorns = [
    ("Thorn_01", Vector((0.36, -0.12, 0.71)), Euler((math.radians(20), math.radians(40), math.radians(60))), Vector((0.016, 0.028, 0.004))),
    ("Thorn_02", Vector((0.46, -0.10, 0.58)), Euler((math.radians(-10), math.radians(60), math.radians(30))), Vector((0.018, 0.030, 0.004))),
    ("Thorn_03", Vector((0.44, 0.05, 0.38)), Euler((math.radians(30), math.radians(-40), math.radians(110))), Vector((0.016, 0.026, 0.004))),
    ("Thorn_Tip_Glow", Vector((0.10, 0.24, 0.02)), Euler((math.radians(10), math.radians(20), math.radians(180))), Vector((0.014, 0.022, 0.004))),
]

for name, loc, rot, scl in whip_thorns:
    mat_th = mats["glow"] if "Glow" in name else mats["urtiga"]
    create_urtiga_leaf(name, loc, rot, scl)

# 8. Setup Lighting & Cameras for 4-angle Interpretation Sheet
# We need Front, Side, Three-Quarter, Back views + Flat Silhouette view
bpy.ops.object.select_all(action='DESELECT')

# Clean existing lights/cameras
for o in list(scene.objects):
    if o.type in ('CAMERA', 'LIGHT'):
        bpy.data.objects.remove(o)

# 3-Point Studio Lighting
key_light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
key_light_data.energy = 3.5
key_light_data.color = (1.0, 0.98, 0.95)
key_light = bpy.data.objects.new("KeyLight", key_light_data)
key_light.rotation_euler = (math.radians(50), math.radians(15), math.radians(-35))
scene.collection.objects.link(key_light)

fill_light_data = bpy.data.lights.new(name="FillLight", type='SUN')
fill_light_data.energy = 1.6
fill_light_data.color = (0.85, 0.90, 1.0)
fill_light = bpy.data.objects.new("FillLight", fill_light_data)
fill_light.rotation_euler = (math.radians(45), math.radians(-25), math.radians(130))
scene.collection.objects.link(fill_light)

rim_light_data = bpy.data.lights.new(name="RimLight", type='SUN')
rim_light_data.energy = 2.2
rim_light_data.color = (0.75, 1.0, 0.85)
rim_light = bpy.data.objects.new("RimLight", rim_light_data)
rim_light.rotation_euler = (math.radians(-35), math.radians(30), math.radians(170))
scene.collection.objects.link(rim_light)

# Ground shadow catcher / neutral floor
bpy.ops.mesh.primitive_cylinder_add(radius=0.75, depth=0.02, location=(0, 0, -0.01))
floor_pedestal = bpy.context.active_object
floor_pedestal.name = "FloorPedestal"
mat_floor = bpy.data.materials.new("Mat_FloorNeutral")
mat_floor.use_nodes = True
bsdf_floor = mat_floor.node_tree.nodes.get("Principled BSDF")
bsdf_floor.inputs["Base Color"].default_value = (0.08, 0.07, 0.09, 1.0)
bsdf_floor.inputs["Roughness"].default_value = 0.8
floor_pedestal.data.materials.append(mat_floor)
col_refs.objects.link(floor_pedestal)
scene.collection.objects.unlink(floor_pedestal)

# Camera Setup
cam_data = bpy.data.cameras.new("RenderCam")
cam_data.lens = 65
cam_obj = bpy.data.objects.new("RenderCam", cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE'
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.film_transparent = True

# Target focus point is character chest/center: (0, 0, 0.72)
center_target = Vector((0.0, 0.0, 0.72))
cam_dist = 2.6

views = {
    "front": (math.radians(0), Vector((0, -cam_dist, 0.82))),
    "side": (math.radians(90), Vector((cam_dist, 0, 0.82))),
    "three_quarter": (math.radians(45), Vector((cam_dist * 0.707, -cam_dist * 0.707, 0.90))),
    "back": (math.radians(180), Vector((0, cam_dist, 0.82))),
}

def point_at(obj, target):
    direction = target - obj.location
    rot_quat = direction.to_track_quat('-Z', 'Y')
    obj.rotation_euler = rot_quat.to_euler()

# Render individual views
for view_name, (angle, loc) in views.items():
    cam_obj.location = loc
    point_at(cam_obj, center_target)
    bpy.context.view_layer.update()
    
    out_img = os.path.join(RENDER_DIR, f"blockout_{view_name}.png")
    scene.render.filepath = out_img
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {out_img}")

# 9. Render Silhouette (flat black on white)
# Temporarily assign pure black emission to all geo objects
sil_mat = bpy.data.materials.new("Mat_Silhouette")
sil_mat.use_nodes = True
bsdf_sil = sil_mat.node_tree.nodes.get("Principled BSDF")
bsdf_sil.inputs["Base Color"].default_value = (0.0, 0.0, 0.0, 1.0)
bsdf_sil.inputs["Roughness"].default_value = 1.0
if "Emission Color" in bsdf_sil.inputs:
    bsdf_sil.inputs["Emission Color"].default_value = (0.0, 0.0, 0.0, 1.0)
    bsdf_sil.inputs["Emission Strength"].default_value = 0.0

orig_mats = {}
for obj in col_geo.objects:
    if obj.type == 'MESH':
        orig_mats[obj] = list(obj.data.materials)
        obj.data.materials.clear()
        obj.data.materials.append(sil_mat)

floor_pedestal.hide_render = True

# Front 3/4 silhouette view
cam_obj.location = views["three_quarter"][1]
point_at(cam_obj, center_target)
bpy.context.view_layer.update()

sil_path = os.path.join(RENDER_DIR, "blockout_silhouette.png")
scene.render.filepath = sil_path
bpy.ops.render.render(write_still=True)
print(f"Rendered silhouette: {sil_path}")

# Restore materials and floor
for obj, m_list in orig_mats.items():
    obj.data.materials.clear()
    for m in m_list:
        obj.data.materials.append(m)
floor_pedestal.hide_render = False

# 10. Save Blockout Blend File
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
print(f"Saved blockout blend: {OUT_BLEND}")

# 11. Compose Interpretation Sheet (prancha de interpretação)
# We compose a 2048x1024 sheet with Front, Profile/Side, 3/4, Back, and Silhouette + Palette
try:
    from PIL import Image, ImageDraw, ImageFont
    
    sheet_w, sheet_h = 2560, 1440
    sheet = Image.new("RGBA", (sheet_w, sheet_h), (18, 16, 20, 255))
    draw = ImageDraw.Draw(sheet)
    
    # Title Header
    title = "COMADRE FULOZINHA — PRANCHA DE INTERPRETAÇÃO E BLOCKOUT (FASE 4)"
    subtitle = "Fonte: Descrição Textual (art/lore/comadre_fulozinha.md) | Altura: 1.35m | Proporção: 5.8 cabeças | Tier 4 Conjurador"
    draw.text((60, 40), title, fill=(240, 235, 230, 255))
    draw.text((60, 80), subtitle, fill=(180, 175, 170, 255))
    
    # Place 5 views: Front, Side, Three-Quarter, Back, Silhouette
    view_files = [
        ("FRENTE", os.path.join(RENDER_DIR, "blockout_front.png")),
        ("PERFIL", os.path.join(RENDER_DIR, "blockout_side.png")),
        ("3/4 ÂNGULO", os.path.join(RENDER_DIR, "blockout_three_quarter.png")),
        ("COSTAS", os.path.join(RENDER_DIR, "blockout_back.png")),
        ("SILHUETA", os.path.join(RENDER_DIR, "blockout_silhouette.png")),
    ]
    
    slot_w = 460
    slot_h = 920
    start_x = 60
    y_pos = 140
    
    for i, (label, fpath) in enumerate(view_files):
        x = start_x + i * (slot_w + 35)
        # Background slot box
        draw.rectangle([x, y_pos, x + slot_w, y_pos + slot_h], fill=(28, 25, 30, 255), outline=(50, 45, 55, 255))
        draw.text((x + 20, y_pos + 15), label, fill=(210, 205, 195, 255))
        
        if os.path.exists(fpath):
            img = Image.open(fpath).convert("RGBA")
            img.thumbnail((slot_w - 20, slot_h - 60), Image.Resampling.LANCZOS)
            offset_x = x + (slot_w - img.width) // 2
            offset_y = y_pos + 50 + (slot_h - 60 - img.height) // 2
            sheet.alpha_composite(img, (offset_x, offset_y))
            
    # Bottom Palette Bar
    pal_y = y_pos + slot_h + 30
    draw.text((60, pal_y), "AMOSTRAS DE PALETA (CANÔNICA & DERIVADA):", fill=(210, 205, 195, 255))
    
    palette = [
        ("Manto Cabelo Vivo", "#161314", (22, 19, 20)),
        ("Pele Cabocla", "#7E482B", (126, 72, 43)),
        ("Urtigas (Folhas)", "#2F5227", (47, 82, 39)),
        ("Cipó do Chicote", "#4B3621", (75, 54, 33)),
        ("Flores Silvestres", "#D48B28", (212, 139, 40)),
        ("Olhos Jabuticaba", "#0C080E", (12, 8, 14)),
        ("Açoite Magia (Glow)", "#5AE38C", (90, 227, 140)),
    ]
    
    swatch_w = 280
    swatch_h = 55
    swatch_start_x = 60
    for j, (pname, phex, prgb) in enumerate(palette):
        sx = swatch_start_x + j * (swatch_w + 50)
        sy = pal_y + 35
        draw.rectangle([sx, sy, sx + 55, sy + swatch_h], fill=(*prgb, 255), outline=(80, 75, 85, 255))
        draw.text((sx + 65, sy + 8), pname, fill=(220, 215, 210, 255))
        draw.text((sx + 65, sy + 30), phex, fill=(150, 145, 140, 255))
        
    interp_path = os.path.join(RENDER_DIR, "interpretacao.png")
    sheet.save(interp_path)
    print(f"Prancha de interpretacao salva: {interp_path}")

except Exception as e:
    print(f"PIL prancha generation error: {e}")

print("=== CONCLUÍDO BLOCKOUT E PRANCHA DA COMADRE FULOZINHA ===")
