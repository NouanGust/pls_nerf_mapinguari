import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler
from mathutils.bvhtree import BVHTree

ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
BUNDLE_PATH = os.path.join(ROOT_DIR, "docs", "human-base-mesh-bundle", "human_base_meshes_bundle.blend")
OUT_BLEND = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "comadre_fulozinha_blockout.blend")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "comadre_fulozinha", "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

# 1. Reset scene to factory settings
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene["unit_name"] = "ComadreFulozinha"

# Setup collections
col_geo = bpy.data.collections.new("GEO")
col_props = bpy.data.collections.new("PROPS") # Accessories / Props
col_rig = bpy.data.collections.new("RIG")
col_anim = bpy.data.collections.new("ANIM")
col_refs = bpy.data.collections.new("REFS")
for c in (col_geo, col_props, col_rig, col_anim, col_refs):
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
    "skin": make_mat("Mat_Skin", "#7E482B", roughness=0.52),
    "hair": make_mat("Mat_Hair", "#141113", roughness=0.65),
    "urtiga": make_mat("Mat_Urtiga", "#2A4D23", roughness=0.38),
    "cipo": make_mat("Mat_Cipo", "#42301D", roughness=0.55),
    "fulo": make_mat("Mat_Fulo", "#D88F28", roughness=0.58),
    "fulo_amber": make_mat("Mat_FuloAmber", "#E2C46A", roughness=0.52),
    "eye": make_mat("Mat_EyeJabuticaba", "#0A070C", roughness=0.08),
    "glow": make_mat("Mat_UrtigaGlow", "#5CE890", roughness=0.25, emission_strength=2.0),
}

def link_to_col(obj, col, mat=None):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    col.objects.link(obj)
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

for obj in [body] + eyes:
    obj.animation_data_clear()
    for m in list(obj.modifiers):
        obj.modifiers.remove(m)

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
    link_to_col(eye, col_geo, mats["eye"])

link_to_col(body, col_geo, mats["skin"])

# 2. Rescale & Proportion Body into Juvenile Cabocla (~1.35 m tall, ~5.8 heads)
bm_body = bmesh.new()
bm_body.from_mesh(body.data)

min_z = min(v.co.z for v in bm_body.verts)
max_z = max(v.co.z for v in bm_body.verts)
orig_height = max_z - min_z

target_height = 1.35
scale_factor = target_height / orig_height

for v in bm_body.verts:
    v.co.z -= min_z
    z_norm = v.co.z / orig_height
    v.co.x *= scale_factor
    v.co.y *= scale_factor
    v.co.z *= scale_factor
    
    if z_norm > 0.82:
        head_factor = 1.08
        head_center_z = 1.22
        v.co.x *= head_factor
        v.co.y *= head_factor
        v.co.z = head_center_z + (v.co.z - head_center_z) * head_factor
    elif z_norm > 0.40 and z_norm <= 0.82:
        v.co.x *= 0.92
        v.co.y *= 0.92

bm_body.to_mesh(body.data)
bm_body.free()
body.data.update()

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

min_z_new = min(v.co.z for v in body.data.vertices)
max_z_new = max(v.co.z for v in body.data.vertices)
print(f"Juvenile body scaled: height = {max_z_new - min_z_new:.3f}m (Z: {min_z_new:.3f} to {max_z_new:.3f})")

# 3. Build a BVH Tree of the body to guarantee anti-clipping
# Every vertex of hair will be checked and repelled from body surface!
bvh_body = BVHTree.FromPolygons([v.co for v in body.data.vertices], [p.vertices for p in body.data.polygons])

def prevent_clipping(bm, margin=0.015):
    """Pushes any vertex that is inside or closer than margin outside the body mesh."""
    for v in bm.verts:
        loc, norm, idx, dist = bvh_body.find_nearest(v.co)
        if loc is not None:
            to_vert = v.co - loc
            dot = to_vert.dot(norm)
            # If vertex is behind surface or too close to surface normal
            if dot < margin:
                v.co = loc + norm * margin

# 4. Create Sculpted Stylized Hair System (Mesh-based)
# A: Hair Cap / Scalp Base
bm_body = bmesh.new()
bm_body.from_mesh(body.data)
# Scalp vertices on cranium
scalp_faces = [f for f in bm_body.faces if f.calc_center_median().z > 1.26 or (f.calc_center_median().z > 1.20 and f.calc_center_median().y > -0.04)]
bm_scalp = bmesh.new()
vmap = {}
for f in scalp_faces:
    for v in f.verts:
        if v not in vmap:
            n_off = v.normal * 0.012
            vmap[v] = bm_scalp.verts.new(v.co + n_off)
    bm_scalp.faces.new([vmap[v] for v in f.verts])

bm_body.free()

# Give the scalp cap some volume and smooth curvature
prevent_clipping(bm_scalp, margin=0.012)
scalp_mesh = bpy.data.meshes.new("GEO_Hair_Cap")
bm_scalp.to_mesh(scalp_mesh)
bm_scalp.free()

scalp_obj = bpy.data.objects.new("GEO_Hair_Cap", scalp_mesh)
link_to_col(scalp_obj, col_geo, mats["hair"])
mod_s = scalp_obj.modifiers.new("Solidify", 'SOLIDIFY')
mod_s.thickness = 0.012
mod_s.offset = 1.0
bpy.context.view_layer.objects.active = scalp_obj
bpy.ops.object.modifier_apply(modifier="Solidify")

# B: Helper function to generate clean stylized hair ribbons (Quad strips with bevel)
def create_stylized_hair_strand(name, points, widths, col=col_geo, mat=mats["hair"]):
    """Creates a clean stylized hair strand with ribbon profile that curves naturally."""
    bm = bmesh.new()
    prev_left = None
    prev_right = None
    
    # We create a quad strip along the curve points
    for i in range(len(points)):
        pt = points[i]
        w = widths[i]
        
        # Calculate tangent
        if i < len(points) - 1:
            tangent = (points[i+1] - pt).normalized()
        else:
            tangent = (pt - points[i-1]).normalized()
            
        # Normal pointing outward roughly along pt.xy
        up = Vector((0, 0, 1))
        side = tangent.cross(up).normalized()
        if side.length < 0.1:
            side = Vector((1, 0, 0))
            
        v_l = bm.verts.new(pt - side * (w * 0.5))
        v_r = bm.verts.new(pt + side * (w * 0.5))
        
        if prev_left and prev_right:
            bm.faces.new([prev_left, v_l, v_r, prev_right])
            
        prev_left = v_l
        prev_right = v_r
        
    prevent_clipping(bm, margin=0.016)
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    link_to_col(obj, col, mat)
    
    # Solidify modifier for stylized hair volume
    mod_solid = obj.modifiers.new("Solidify", 'SOLIDIFY')
    mod_solid.thickness = 0.010
    mod_solid.offset = 0.0
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    
    # Subdivision surface for smooth stylized finish
    mod_sub = obj.modifiers.new("Subsurf", 'SUBSURF')
    mod_sub.levels = 1
    bpy.ops.object.modifier_apply(modifier="Subsurf")
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj

# Carefully planned hair locks with GUARANTEED clearance from the body
# Back of body: Y_max is ~ +0.060 (upper back) and ~ +0.095 (hips).
# All back hair points are placed at Y >= +0.095 (upper) and Y >= +0.130 (hips/thighs)
hair_strands = []

# --- BACK HAIR MANTLE (Cascading Cloak down to knees Z=0.38) ---
back_strands_defs = [
    # Center Back Backbone Locks
    ("Strand_Back_C1", [
        Vector((0.00, 0.080, 1.33)),
        Vector((0.00, 0.115, 1.20)),
        Vector((0.00, 0.135, 1.05)),
        Vector((0.01, 0.145, 0.88)),
        Vector((0.00, 0.160, 0.68)),
        Vector((0.01, 0.150, 0.50)),
        Vector((0.00, 0.125, 0.38)),
    ], [0.09, 0.12, 0.13, 0.12, 0.10, 0.08, 0.02]),
    
    ("Strand_Back_C2_L", [
        Vector((-0.04, 0.075, 1.32)),
        Vector((-0.05, 0.110, 1.18)),
        Vector((-0.06, 0.130, 1.02)),
        Vector((-0.05, 0.145, 0.85)),
        Vector((-0.04, 0.155, 0.65)),
        Vector((-0.03, 0.145, 0.48)),
        Vector((-0.02, 0.120, 0.36)),
    ], [0.08, 0.11, 0.12, 0.11, 0.09, 0.07, 0.02]),
    
    ("Strand_Back_C2_R", [
        Vector((0.04, 0.075, 1.32)),
        Vector((0.05, 0.110, 1.18)),
        Vector((0.06, 0.130, 1.02)),
        Vector((0.05, 0.145, 0.85)),
        Vector((0.04, 0.155, 0.65)),
        Vector((0.03, 0.145, 0.48)),
        Vector((0.02, 0.120, 0.36)),
    ], [0.08, 0.11, 0.12, 0.11, 0.09, 0.07, 0.02]),

    # Left Shoulder Mantle Curtain
    ("Strand_Back_L1", [
        Vector((-0.08, 0.060, 1.30)),
        Vector((-0.12, 0.095, 1.16)),
        Vector((-0.15, 0.120, 1.00)),
        Vector((-0.14, 0.135, 0.82)),
        Vector((-0.12, 0.145, 0.62)),
        Vector((-0.09, 0.130, 0.46)),
    ], [0.08, 0.10, 0.11, 0.10, 0.08, 0.02]),
    
    ("Strand_Back_L2", [
        Vector((-0.11, 0.030, 1.28)),
        Vector((-0.17, 0.070, 1.14)),
        Vector((-0.20, 0.095, 0.98)),
        Vector((-0.18, 0.115, 0.80)),
        Vector((-0.15, 0.125, 0.60)),
        Vector((-0.11, 0.110, 0.44)),
    ], [0.07, 0.09, 0.10, 0.09, 0.07, 0.02]),

    # Right Shoulder Mantle Curtain
    ("Strand_Back_R1", [
        Vector((0.08, 0.060, 1.30)),
        Vector((0.12, 0.095, 1.16)),
        Vector((0.15, 0.120, 1.00)),
        Vector((0.14, 0.135, 0.82)),
        Vector((0.12, 0.145, 0.62)),
        Vector((0.09, 0.130, 0.46)),
    ], [0.08, 0.10, 0.11, 0.10, 0.08, 0.02]),
    
    ("Strand_Back_R2", [
        Vector((0.11, 0.030, 1.28)),
        Vector((0.17, 0.070, 1.14)),
        Vector((0.20, 0.095, 0.98)),
        Vector((0.18, 0.115, 0.80)),
        Vector((0.15, 0.125, 0.60)),
        Vector((0.11, 0.110, 0.44)),
    ], [0.07, 0.09, 0.10, 0.09, 0.07, 0.02]),

    # Outer Wild Strands (quebrando a silhueta externa sem tocar braços)
    ("Strand_Flank_L", [
        Vector((-0.13, -0.010, 1.27)),
        Vector((-0.21, 0.020, 1.15)),
        Vector((-0.24, 0.045, 1.00)),
        Vector((-0.22, 0.065, 0.84)),
        Vector((-0.18, 0.075, 0.68)),
        Vector((-0.13, 0.070, 0.52)),
    ], [0.06, 0.08, 0.09, 0.08, 0.06, 0.02]),
    
    ("Strand_Flank_R", [
        Vector((0.13, -0.010, 1.27)),
        Vector((0.21, 0.020, 1.15)),
        Vector((0.24, 0.045, 1.00)),
        Vector((0.22, 0.065, 0.84)),
        Vector((0.18, 0.075, 0.68)),
        Vector((0.13, 0.070, 0.52)),
    ], [0.06, 0.08, 0.09, 0.08, 0.06, 0.02]),
]

for sname, spts, swids in back_strands_defs:
    s_obj = create_stylized_hair_strand(sname, spts, swids, col_geo, mats["hair"])
    hair_strands.append(s_obj)

# --- FRONT & SIDE FACIAL/CHEST STRANDS (Vestimenta viva sobre o tórax sem clipar) ---
# Chest min_Y is -0.117. Front hair floats cleanly at Y <= -0.128
front_strands_defs = [
    # Forehead Bangs (Franja estilizada sobre a testa)
    ("Bangs_Center", [
        Vector((0.00, -0.075, 1.34)),
        Vector((0.01, -0.115, 1.27)),
        Vector((0.02, -0.135, 1.20)),
    ], [0.07, 0.08, 0.02]),
    
    ("Bangs_L", [
        Vector((-0.04, -0.065, 1.33)),
        Vector((-0.06, -0.110, 1.26)),
        Vector((-0.08, -0.128, 1.18)),
    ], [0.06, 0.07, 0.02]),
    
    ("Bangs_R", [
        Vector((0.04, -0.065, 1.33)),
        Vector((0.06, -0.110, 1.26)),
        Vector((0.08, -0.128, 1.18)),
    ], [0.06, 0.07, 0.02]),

    # Side Face-Framing Locks (emolduram as bochechas e descem sobre o peito)
    ("Strand_Face_L", [
        Vector((-0.09, -0.040, 1.28)),
        Vector((-0.11, -0.080, 1.18)),
        Vector((-0.10, -0.120, 1.06)),
        Vector((-0.08, -0.132, 0.94)),
        Vector((-0.06, -0.125, 0.82)),
        Vector((-0.04, -0.110, 0.70)),
    ], [0.07, 0.09, 0.09, 0.08, 0.06, 0.02]),

    ("Strand_Face_R", [
        Vector((0.09, -0.040, 1.28)),
        Vector((0.11, -0.080, 1.18)),
        Vector((0.10, -0.120, 1.06)),
        Vector((0.08, -0.132, 0.94)),
        Vector((0.06, -0.125, 0.82)),
        Vector((0.04, -0.110, 0.70)),
    ], [0.07, 0.09, 0.09, 0.08, 0.06, 0.02]),

    # Front Chest Covering Vestment Locks (cobre peito e cintura)
    ("Strand_Chest_C_L", [
        Vector((-0.04, -0.095, 1.12)),
        Vector((-0.05, -0.135, 1.02)),
        Vector((-0.04, -0.140, 0.90)),
        Vector((-0.03, -0.130, 0.78)),
        Vector((-0.02, -0.115, 0.65)),
    ], [0.08, 0.10, 0.09, 0.08, 0.02]),

    ("Strand_Chest_C_R", [
        Vector((0.04, -0.095, 1.12)),
        Vector((0.05, -0.135, 1.02)),
        Vector((0.04, -0.140, 0.90)),
        Vector((0.03, -0.130, 0.78)),
        Vector((0.02, -0.115, 0.65)),
    ], [0.08, 0.10, 0.09, 0.08, 0.02]),
]

for sname, spts, swids in front_strands_defs:
    s_obj = create_stylized_hair_strand(sname, spts, swids, col_geo, mats["hair"])
    hair_strands.append(s_obj)

# 5. Build Urtiga (Stinging Nettle) Leaves on Hair (delicadas, bem posicionadas)
def create_urtiga_leaf(name, loc, rot, scale=Vector((0.032, 0.052, 0.005))):
    bm = bmesh.new()
    v0 = bm.verts.new((0.0, 0.0, 0.0))
    v1 = bm.verts.new((-0.6, 0.3, 0.04))
    v2 = bm.verts.new((-0.8, 0.6, 0.02))
    v3 = bm.verts.new((-0.4, 0.85, 0.01))
    v4 = bm.verts.new((0.0, 1.0, 0.0))
    v5 = bm.verts.new((0.4, 0.85, 0.01))
    v6 = bm.verts.new((0.8, 0.6, 0.02))
    v7 = bm.verts.new((0.6, 0.3, 0.04))
    bm.faces.new([v0, v1, v2, v3, v4, v5, v6, v7])
    
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    
    obj = bpy.data.objects.new(name, mesh)
    obj.location = loc
    obj.rotation_euler = rot
    obj.scale = scale
    link_to_col(obj, col_geo, mats["urtiga"])
    
    mod = obj.modifiers.new("Solidify", 'SOLIDIFY')
    mod.thickness = 0.003
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    return obj

urtiga_positions = [
    ("Urtiga_Crown_01", Vector((0.03, 0.07, 1.37)), Euler((math.radians(35), math.radians(15), math.radians(40)))),
    ("Urtiga_Crown_02", Vector((-0.05, 0.06, 1.36)), Euler((math.radians(40), math.radians(-25), math.radians(-30)))),
    ("Urtiga_Crown_03", Vector((0.09, 0.01, 1.34)), Euler((math.radians(20), math.radians(45), math.radians(70)))),
    ("Urtiga_Crown_04", Vector((-0.09, 0.01, 1.33)), Euler((math.radians(25), math.radians(-40), math.radians(-65)))),
    ("Urtiga_Shoulder_L", Vector((-0.19, 0.08, 1.15)), Euler((math.radians(45), math.radians(-30), math.radians(-20)))),
    ("Urtiga_Shoulder_R", Vector((0.19, 0.08, 1.15)), Euler((math.radians(45), math.radians(30), math.radians(20)))),
    ("Urtiga_Back_01", Vector((0.00, 0.16, 0.95)), Euler((math.radians(70), math.radians(10), math.radians(180)))),
    ("Urtiga_Back_02", Vector((-0.09, 0.17, 0.78)), Euler((math.radians(65), math.radians(-20), math.radians(160)))),
    ("Urtiga_Back_03", Vector((0.09, 0.17, 0.78)), Euler((math.radians(65), math.radians(20), math.radians(-160)))),
]

for name, loc, rot in urtiga_positions:
    create_urtiga_leaf(name, loc, rot)

# 6. Build Wild Forest Flowers (Fulô)
def create_forest_flower(name, loc, rot, radius=0.020, mat=mats["fulo"]):
    bm = bmesh.new()
    v_center = bm.verts.new((0.0, 0.0, 0.005))
    petal_verts = []
    num_petals = 5
    for i in range(num_petals):
        angle = i * (2.0 * math.pi / num_petals)
        angle_half = angle + (math.pi / num_petals)
        px = math.cos(angle) * radius
        py = math.sin(angle) * radius
        v_tip = bm.verts.new((px, py, 0.0))
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
    link_to_col(obj, col_geo, mat)
    
    mod = obj.modifiers.new("Solidify", 'SOLIDIFY')
    mod.thickness = 0.003
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    return obj

flower_positions = [
    ("Fulo_Head_01", Vector((0.05, 0.03, 1.37)), Euler((math.radians(35), math.radians(20), math.radians(15))), 0.022, mats["fulo"]),
    ("Fulo_Head_02", Vector((-0.06, 0.02, 1.35)), Euler((math.radians(30), math.radians(-30), math.radians(-10))), 0.019, mats["fulo_amber"]),
    ("Fulo_Chest_01", Vector((-0.03, -0.14, 0.95)), Euler((math.radians(-15), math.radians(-10), math.radians(45))), 0.018, mats["fulo"]),
    ("Fulo_Back_01", Vector((0.04, 0.17, 0.88)), Euler((math.radians(80), math.radians(15), math.radians(120))), 0.022, mats["fulo_amber"]),
    ("Fulo_Back_02", Vector((-0.03, 0.16, 0.68)), Euler((math.radians(75), math.radians(-10), math.radians(150))), 0.020, mats["fulo"]),
]

for name, loc, rot, rad, fmat in flower_positions:
    create_forest_flower(name, loc, rot, rad, fmat)

# 7. BUILD THE WHIP AS A DISTINCT HELD ACCESSORY (Acessório Chicote de Cipó e Urtiga)
# It is placed in collection PROPS with clear Handle Grip held in the Right Hand!
print("=== 4. Building Accessory Whip (Acessório Chicote) ===")

# A: Handle / Grip (Empunhadura de madeira rústica / cipó trançado)
# Hand center: X=0.255, Y=-0.020, Z=0.680
handle_loc = Vector((0.255, -0.020, 0.680))
handle_rot = Euler((math.radians(15), math.radians(-25), math.radians(-20)))

bpy.ops.mesh.primitive_cylinder_add(
    radius=0.014, depth=0.22,
    location=handle_loc,
    rotation=handle_rot
)
handle_obj = bpy.context.active_object
handle_obj.name = "Acessorio_Chicote_Cabo"
link_to_col(handle_obj, col_props, mats["cipo"])

# Add pommel knot and guard rings
bpy.ops.mesh.primitive_torus_add(
    major_radius=0.019, minor_radius=0.006,
    location=handle_loc + Vector((-0.02, 0.01, -0.09)),
    rotation=handle_rot
)
pommel_obj = bpy.context.active_object
pommel_obj.name = "Acessorio_Chicote_Pomo"
link_to_col(pommel_obj, col_props, mats["cipo"])

bpy.ops.mesh.primitive_torus_add(
    major_radius=0.018, minor_radius=0.005,
    location=handle_loc + Vector((0.02, -0.01, 0.09)),
    rotation=handle_rot
)
guard_obj = bpy.context.active_object
guard_obj.name = "Acessorio_Chicote_Anel"
link_to_col(guard_obj, col_props, mats["cipo"])

# B: Whip Flexible Body (Lash)
# Emerges from the top of the handle, arcs dynamically through the air and curls on the floor
lash_points = [
    handle_loc + Vector((0.025, -0.015, 0.10)),  # Emerge from handle top
    Vector((0.34, -0.08, 0.82)),                 # Arc forward & up
    Vector((0.44, -0.10, 0.72)),                 # Dynamic right curve
    Vector((0.48, -0.02, 0.52)),                 # S-curve down
    Vector((0.42, 0.10, 0.32)),                  # Mid loop
    Vector((0.32, 0.18, 0.16)),                  # Sweeping to floor
    Vector((0.20, 0.22, 0.04)),                  # Ground contact
    Vector((0.10, 0.25, 0.01)),                  # Tail spiral
]
lash_radii = [0.8, 0.75, 0.65, 0.55, 0.45, 0.38, 0.30, 0.20]

curve_lash = bpy.data.curves.new(name="Acessorio_Chicote_Corpo", type='CURVE')
curve_lash.dimensions = '3D'
spline_lash = curve_lash.splines.new('BEZIER')
spline_lash.bezier_points.add(len(lash_points) - 1)

for i, pt in enumerate(lash_points):
    bp = spline_lash.bezier_points[i]
    bp.co = pt
    bp.radius = lash_radii[i]
    bp.handle_left_type = 'AUTO'
    bp.handle_right_type = 'AUTO'

curve_lash.bevel_depth = 0.013
curve_lash.bevel_resolution = 3
curve_lash.resolution_u = 12

lash_obj = bpy.data.objects.new("Acessorio_Chicote_Corpo", curve_lash)
link_to_col(lash_obj, col_props, mats["cipo"])
bpy.ops.object.select_all(action='DESELECT')
lash_obj.select_set(True)
bpy.context.view_layer.objects.active = lash_obj
bpy.ops.object.convert(target='MESH')
for poly in lash_obj.data.polygons:
    poly.use_smooth = True

# Join Handle, Pommel, Guard and Lash into a unified accessory: Acessorio_Chicote
bpy.ops.object.select_all(action='DESELECT')
for p in [pommel_obj, guard_obj, lash_obj, handle_obj]:
    p.select_set(True)
bpy.context.view_layer.objects.active = handle_obj
bpy.ops.object.join()
whip_accessory = handle_obj
whip_accessory.name = "Acessorio_Chicote"

# Add thorns/nettle nodes on the whip accessory
whip_nodes = [
    ("Thorn_Acc_01", Vector((0.36, -0.09, 0.80)), Euler((math.radians(20), math.radians(40), math.radians(60))), Vector((0.014, 0.024, 0.003)), mats["urtiga"]),
    ("Thorn_Acc_02", Vector((0.46, -0.06, 0.62)), Euler((math.radians(-10), math.radians(60), math.radians(30))), Vector((0.016, 0.026, 0.003)), mats["urtiga"]),
    ("Thorn_Acc_03", Vector((0.44, 0.06, 0.38)), Euler((math.radians(30), math.radians(-40), math.radians(110))), Vector((0.014, 0.024, 0.003)), mats["urtiga"]),
    ("Thorn_Acc_Tip", Vector((0.11, 0.25, 0.02)), Euler((math.radians(10), math.radians(20), math.radians(180))), Vector((0.013, 0.020, 0.003)), mats["glow"]),
]

for name, loc, rot, scl, nmat in whip_nodes:
    th = create_urtiga_leaf(name, loc, rot, scl)
    link_to_col(th, col_props, nmat)
    # Join into whip accessory
    bpy.ops.object.select_all(action='DESELECT')
    th.select_set(True)
    whip_accessory.select_set(True)
    bpy.context.view_layer.objects.active = whip_accessory
    bpy.ops.object.join()

print(f"Whip accessory built successfully: {whip_accessory.name}")

# 8. Setup Lighting & Cameras for 4-angle Interpretation Sheet
bpy.ops.object.select_all(action='DESELECT')
for o in list(scene.objects):
    if o.type in ('CAMERA', 'LIGHT'):
        bpy.data.objects.remove(o)

key_light_data = bpy.data.lights.new(name="KeyLight", type='SUN')
key_light_data.energy = 3.6
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
rim_light_data.energy = 2.4
rim_light_data.color = (0.75, 1.0, 0.85)
rim_light = bpy.data.objects.new("RimLight", rim_light_data)
rim_light.rotation_euler = (math.radians(-35), math.radians(30), math.radians(170))
scene.collection.objects.link(rim_light)

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

cam_data = bpy.data.cameras.new("RenderCam")
cam_data.lens = 65
cam_obj = bpy.data.objects.new("RenderCam", cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE'
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.film_transparent = True

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

for view_name, (angle, loc) in views.items():
    cam_obj.location = loc
    point_at(cam_obj, center_target)
    bpy.context.view_layer.update()
    
    out_img = os.path.join(RENDER_DIR, f"blockout_{view_name}.png")
    scene.render.filepath = out_img
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {out_img}")

# 9. Render Silhouette
sil_mat = bpy.data.materials.new("Mat_Silhouette")
sil_mat.use_nodes = True
bsdf_sil = sil_mat.node_tree.nodes.get("Principled BSDF")
bsdf_sil.inputs["Base Color"].default_value = (0.0, 0.0, 0.0, 1.0)
bsdf_sil.inputs["Roughness"].default_value = 1.0

orig_mats = {}
all_render_objs = list(col_geo.objects) + list(col_props.objects)
for obj in all_render_objs:
    if obj.type == 'MESH':
        orig_mats[obj] = list(obj.data.materials)
        obj.data.materials.clear()
        obj.data.materials.append(sil_mat)

floor_pedestal.hide_render = True

cam_obj.location = views["three_quarter"][1]
point_at(cam_obj, center_target)
bpy.context.view_layer.update()

sil_path = os.path.join(RENDER_DIR, "blockout_silhouette.png")
scene.render.filepath = sil_path
bpy.ops.render.render(write_still=True)
print(f"Rendered silhouette: {sil_path}")

for obj, m_list in orig_mats.items():
    obj.data.materials.clear()
    for m in m_list:
        obj.data.materials.append(m)
floor_pedestal.hide_render = False

# 10. Save Blockout Blend File
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
print(f"Saved refined blockout blend: {OUT_BLEND}")

print("=== CONCLUÍDO REFINAMENTO DO BLOCKOUT V2 ===")

