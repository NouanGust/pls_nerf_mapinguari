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

# 1. Reset scene
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene["unit_name"] = "ComadreFulozinha"

col_geo = bpy.data.collections.new("GEO")
col_props = bpy.data.collections.new("PROPS") # Dedicated prop accessories collection
col_refs = bpy.data.collections.new("REFS")
for c in (col_geo, col_props, col_refs):
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
    "skin": make_mat("Mat_Skin", "#7E482B", roughness=0.50),
    "hair": make_mat("Mat_Hair", "#141113", roughness=0.62),
    "urtiga": make_mat("Mat_Urtiga", "#2A4F22", roughness=0.38),
    "cipo": make_mat("Mat_Cipo", "#42301D", roughness=0.55),
    "fulo": make_mat("Mat_Fulo", "#E09026", roughness=0.55),
    "fulo_amber": make_mat("Mat_FuloAmber", "#E5C86A", roughness=0.50),
    "eye": make_mat("Mat_EyeJabuticaba", "#08060A", roughness=0.08),
    "glow": make_mat("Mat_UrtigaGlow", "#5CE890", roughness=0.25, emission_strength=2.2),
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

# Build BVH of body to enforce anti-clipping
bvh_body = BVHTree.FromPolygons([v.co for v in body.data.vertices], [p.vertices for p in body.data.polygons])

def prevent_clipping(bm, margin=0.016):
    """Guarantees every vertex is strictly outside the body mesh by at least margin."""
    for v in bm.verts:
        loc, norm, idx, dist = bvh_body.find_nearest(v.co)
        if loc is not None:
            to_v = v.co - loc
            dot = to_v.dot(norm)
            if dot < margin:
                v.co = loc + norm * margin

# 3. IMPLEMENT THE EXACT "FAST STYLIZED HAIR" CURVE BEVEL METHOD (ItsPaulTodd Tutorial)
print("=== 2. Creating Stylized Hair using ItsPaulTodd Curve Profile Workflow ===")

# Step A: Create 2D Bevel Profile Curve with Sharp Crest
# Diamond/Teardrop profile with sharp center crest and flat underside
profile_curve_data = bpy.data.curves.new("Hair_Profile_Bevel", type='CURVE')
profile_curve_data.dimensions = '2D'
spline_prof = profile_curve_data.splines.new('BEZIER')
spline_prof.bezier_points.add(3)
spline_prof.use_cyclic_u = True

# 4 points forming a stylized diamond/teardrop with sharp crest:
# Index 0: Top sharp ridge (vector handle)
# Index 1: Right curved flank
# Index 2: Flat underside (hugs head/body)
# Index 3: Left curved flank
prof_pts = [
    (0.00,  0.024),  # 0: Sharp crest
    (0.040, 0.004),  # 1: Right
    (0.00, -0.014),  # 2: Under/flat
    (-0.040, 0.004), # 3: Left
]
for i, (px, py) in enumerate(prof_pts):
    bp = spline_prof.bezier_points[i]
    bp.co = Vector((px, py, 0.0))
    bp.handle_left_type = 'AUTO'
    bp.handle_right_type = 'AUTO'

# Sharp vector crease on top crest
spline_prof.bezier_points[0].handle_left_type = 'VECTOR'
spline_prof.bezier_points[0].handle_right_type = 'VECTOR'

profile_obj = bpy.data.objects.new("Hair_Profile_Bevel", profile_curve_data)
link_to_col(profile_obj, col_refs)

# Helper function to create a stylized hair strand using the profile curve
def create_paultodd_hair_strand(name, points, radii, tilts):
    curve_data = bpy.data.curves.new(name, type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_mode = 'OBJECT'
    curve_data.bevel_object = profile_obj
    curve_data.use_fill_caps = True
    
    spline = curve_data.splines.new('BEZIER')
    spline.bezier_points.add(len(points) - 1)
    
    for i, (pt, rad, tlt) in enumerate(zip(points, radii, tilts)):
        bp = spline.bezier_points[i]
        bp.co = pt
        bp.radius = rad
        bp.tilt = tlt
        bp.handle_left_type = 'AUTO'
        bp.handle_right_type = 'AUTO'
        
    obj = bpy.data.objects.new(name, curve_data)
    link_to_col(obj, col_geo, mats["hair"])
    return obj

# Scalp Under-Cap (to prevent any bald spots underneath the locks)
# Hairline ends strictly above brow (Z > 1.28 in front, Y > -0.03 at temples)
bm_body = bmesh.new()
bm_body.from_mesh(body.data)
scalp_faces = [f for f in bm_body.faces if (f.calc_center_median().z > 1.30 and f.calc_center_median().y > -0.05) or (f.calc_center_median().z > 1.22 and f.calc_center_median().y > 0.02)]
bm_scalp = bmesh.new()
vmap = {}
for f in scalp_faces:
    for v in f.verts:
        if v not in vmap:
            n_off = v.normal * 0.008
            vmap[v] = bm_scalp.verts.new(v.co + n_off)
    bm_scalp.faces.new([vmap[v] for v in f.verts])
bm_body.free()
prevent_clipping(bm_scalp, margin=0.010)

scalp_mesh = bpy.data.meshes.new("GEO_Hair_Cap")
bm_scalp.to_mesh(scalp_mesh)
bm_scalp.free()
scalp_obj = bpy.data.objects.new("GEO_Hair_Cap", scalp_mesh)
link_to_col(scalp_obj, col_geo, mats["hair"])
mod_sc = scalp_obj.modifiers.new("Solidify", 'SOLIDIFY')
mod_sc.thickness = 0.006
mod_sc.offset = 1.0
bpy.context.view_layer.objects.active = scalp_obj
bpy.ops.object.modifier_apply(modifier="Solidify")

# --- LAYER 1: FRONTAL BANGS (Franjas curtas estilizadas que PARAM ACIMA DOS OLHOS) ---
# Face brow is around Z=1.23. Bangs must taper to 0 at or above Z=1.24!
bangs_defs = [
    # Center Bang (stops above bridge of nose, brow level Z=1.24)
    ("Bang_Center", [
        Vector((0.00, -0.065, 1.34)),
        Vector((-0.01, -0.088, 1.29)),
        Vector((-0.015, -0.108, 1.245)),
    ], [0.2, 0.9, 0.0], [0, 0, 0]),
    
    # Left Bang (sweeps over left eyebrow, stops at Z=1.24)
    ("Bang_L1", [
        Vector((-0.03, -0.060, 1.33)),
        Vector((-0.045, -0.082, 1.28)),
        Vector((-0.055, -0.102, 1.235)),
    ], [0.2, 0.85, 0.0], [math.radians(-10), math.radians(-10), math.radians(-10)]),
    
    # Right Bang (sweeps over right eyebrow, stops at Z=1.24)
    ("Bang_R1", [
        Vector((0.03, -0.060, 1.33)),
        Vector((0.045, -0.082, 1.28)),
        Vector((0.055, -0.102, 1.235)),
    ], [0.2, 0.85, 0.0], [math.radians(10), math.radians(10), math.radians(10)]),
    
    # Left Temple Framing (framing side of forehead, curves around cheek)
    ("Bang_Temple_L", [
        Vector((-0.07, -0.040, 1.31)),
        Vector((-0.09, -0.065, 1.24)),
        Vector((-0.105, -0.085, 1.17)),
    ], [0.2, 0.8, 0.0], [math.radians(-25), math.radians(-25), math.radians(-25)]),

    # Right Temple Framing
    ("Bang_Temple_R", [
        Vector((0.07, -0.040, 1.31)),
        Vector((0.09, -0.065, 1.24)),
        Vector((0.105, -0.085, 1.17)),
    ], [0.2, 0.8, 0.0], [math.radians(25), math.radians(25), math.radians(25)]),
]

# --- LAYER 2: SIDE FACE FRAMING LOCKS (Passam pelas laterais das bochechas e clavículas, ROSTO LIVRE) ---
side_defs = [
    # Face Framing Left (curves past ear, over clavicle)
    ("Side_Face_L", [
        Vector((-0.095, -0.025, 1.27)),
        Vector((-0.120, -0.045, 1.16)),
        Vector((-0.125, -0.070, 1.05)),
        Vector((-0.105, -0.100, 0.94)),
        Vector((-0.085, -0.115, 0.82)),
    ], [0.2, 1.0, 1.0, 0.7, 0.0], [math.radians(-30), math.radians(-30), math.radians(-20), math.radians(-10), 0]),
    
    # Face Framing Right
    ("Side_Face_R", [
        Vector((0.095, -0.025, 1.27)),
        Vector((0.120, -0.045, 1.16)),
        Vector((0.125, -0.070, 1.05)),
        Vector((0.105, -0.100, 0.94)),
        Vector((0.085, -0.115, 0.82)),
    ], [0.2, 1.0, 1.0, 0.7, 0.0], [math.radians(30), math.radians(30), math.radians(20), math.radians(10), 0]),
]

# --- LAYER 3: FRONT TORSO FLANK LOCKS (Descem pelos lados do tórax, SEM COBRIR A BOCA) ---
front_drape_defs = [
    ("Front_Drape_L1", [
        Vector((-0.11, -0.030, 1.18)),
        Vector((-0.13, -0.065, 1.08)),
        Vector((-0.11, -0.115, 0.95)),
        Vector((-0.08, -0.125, 0.80)),
        Vector((-0.05, -0.110, 0.65)),
    ], [0.3, 1.1, 1.1, 0.8, 0.0], [math.radians(-20), math.radians(-20), math.radians(-10), 0, 0]),
    
    ("Front_Drape_R1", [
        Vector((0.11, -0.030, 1.18)),
        Vector((0.13, -0.065, 1.08)),
        Vector((0.11, -0.115, 0.95)),
        Vector((0.08, -0.125, 0.80)),
        Vector((0.05, -0.110, 0.65)),
    ], [0.3, 1.1, 1.1, 0.8, 0.0], [math.radians(20), math.radians(20), math.radians(10), 0, 0]),
]

# --- LAYER 4: CROWN / TOP VOLUME LOCKS (Dão volume e silhueta ao topo da cabeça) ---
crown_defs = [
    ("Crown_Center", [
        Vector((0.00, -0.02, 1.38)),
        Vector((0.00, 0.04, 1.37)),
        Vector((0.00, 0.09, 1.30)),
        Vector((0.00, 0.12, 1.20)),
    ], [0.4, 1.2, 1.1, 0.2], [0, 0, 0, 0]),
    
    ("Crown_L", [
        Vector((-0.05, -0.01, 1.37)),
        Vector((-0.06, 0.04, 1.35)),
        Vector((-0.07, 0.09, 1.28)),
        Vector((-0.06, 0.12, 1.18)),
    ], [0.3, 1.1, 1.0, 0.2], [math.radians(-15), math.radians(-15), math.radians(-15), 0]),

    ("Crown_R", [
        Vector((0.05, -0.01, 1.37)),
        Vector((0.06, 0.04, 1.35)),
        Vector((0.07, 0.09, 1.28)),
        Vector((0.06, 0.12, 1.18)),
    ], [0.3, 1.1, 1.0, 0.2], [math.radians(15), math.radians(15), math.radians(15), 0]),
]

# --- LAYER 5: BACK CASCADING MANTO (Cascata exuberante de mechas em camadas até as panturrilhas) ---
# Scapula Y is ~ +0.060, Hips Y is ~ +0.095. All back strands are at Y >= +0.100 and Y >= +0.135
back_cascade_defs = [
    # Center Backbone Long Cascade (goes down to Z=0.36)
    ("Back_C1_Main", [
        Vector((0.00, 0.08, 1.32)),
        Vector((0.00, 0.12, 1.18)),
        Vector((0.00, 0.14, 1.02)),
        Vector((0.00, 0.15, 0.84)),
        Vector((0.00, 0.16, 0.66)),
        Vector((0.00, 0.15, 0.48)),
        Vector((0.00, 0.13, 0.36)),
    ], [0.3, 1.3, 1.4, 1.3, 1.2, 0.8, 0.0], [0, 0, 0, 0, 0, 0, 0]),

    ("Back_C2_L", [
        Vector((-0.04, 0.07, 1.31)),
        Vector((-0.05, 0.11, 1.16)),
        Vector((-0.06, 0.13, 1.00)),
        Vector((-0.05, 0.145, 0.82)),
        Vector((-0.04, 0.155, 0.64)),
        Vector((-0.03, 0.145, 0.46)),
        Vector((-0.02, 0.125, 0.35)),
    ], [0.3, 1.2, 1.3, 1.2, 1.1, 0.7, 0.0], [math.radians(-10), math.radians(-10), math.radians(-10), math.radians(-5), 0, 0, 0]),

    ("Back_C2_R", [
        Vector((0.04, 0.07, 1.31)),
        Vector((0.05, 0.11, 1.16)),
        Vector((0.06, 0.13, 1.00)),
        Vector((0.05, 0.145, 0.82)),
        Vector((0.04, 0.155, 0.64)),
        Vector((0.03, 0.145, 0.46)),
        Vector((0.02, 0.125, 0.35)),
    ], [0.3, 1.2, 1.3, 1.2, 1.1, 0.7, 0.0], [math.radians(10), math.radians(10), math.radians(10), math.radians(5), 0, 0, 0]),

    # Shoulder Blade Tier (Mid-back curtain)
    ("Back_Shoulder_L1", [
        Vector((-0.08, 0.06, 1.29)),
        Vector((-0.11, 0.10, 1.14)),
        Vector((-0.13, 0.12, 0.98)),
        Vector((-0.12, 0.135, 0.80)),
        Vector((-0.09, 0.140, 0.62)),
        Vector((-0.06, 0.125, 0.44)),
    ], [0.3, 1.2, 1.3, 1.2, 0.9, 0.0], [math.radians(-20), math.radians(-20), math.radians(-15), math.radians(-10), 0, 0]),

    ("Back_Shoulder_R1", [
        Vector((0.08, 0.06, 1.29)),
        Vector((0.11, 0.10, 1.14)),
        Vector((0.13, 0.12, 0.98)),
        Vector((0.12, 0.135, 0.80)),
        Vector((0.09, 0.140, 0.62)),
        Vector((0.06, 0.125, 0.44)),
    ], [0.3, 1.2, 1.3, 1.2, 0.9, 0.0], [math.radians(20), math.radians(20), math.radians(15), math.radians(10), 0, 0]),

    # Outer Flank Cape Strands (Wrap around the sides of back)
    ("Back_Flank_L2", [
        Vector((-0.12, 0.03, 1.26)),
        Vector((-0.16, 0.07, 1.12)),
        Vector((-0.18, 0.09, 0.95)),
        Vector((-0.17, 0.11, 0.78)),
        Vector((-0.14, 0.12, 0.60)),
        Vector((-0.10, 0.10, 0.42)),
    ], [0.2, 1.1, 1.2, 1.1, 0.8, 0.0], [math.radians(-35), math.radians(-30), math.radians(-25), math.radians(-15), 0, 0]),

    ("Back_Flank_R2", [
        Vector((0.12, 0.03, 1.26)),
        Vector((0.16, 0.07, 1.12)),
        Vector((0.18, 0.09, 0.95)),
        Vector((0.17, 0.11, 0.78)),
        Vector((0.14, 0.12, 0.60)),
        Vector((0.10, 0.10, 0.42)),
    ], [0.2, 1.1, 1.2, 1.1, 0.8, 0.0], [math.radians(35), math.radians(30), math.radians(25), math.radians(15), 0, 0]),

    # Overlayer Strands (adicionam profundidade e quebram a uniformidade)
    ("Back_Over_L", [
        Vector((-0.03, 0.09, 1.24)),
        Vector((-0.04, 0.13, 1.08)),
        Vector((-0.05, 0.15, 0.90)),
        Vector((-0.04, 0.16, 0.72)),
    ], [0.2, 1.0, 0.9, 0.0], [math.radians(-10), math.radians(-10), math.radians(-5), 0]),

    ("Back_Over_R", [
        Vector((0.03, 0.09, 1.24)),
        Vector((0.04, 0.13, 1.08)),
        Vector((0.05, 0.15, 0.90)),
        Vector((0.04, 0.16, 0.72)),
    ], [0.2, 1.0, 0.9, 0.0], [math.radians(10), math.radians(10), math.radians(5), 0]),
]

all_strand_defs = bangs_defs + side_defs + front_drape_defs + crown_defs + back_cascade_defs
strand_objs = []

for sname, spts, srads, stilts in all_strand_defs:
    sobj = create_paultodd_hair_strand(sname, spts, srads, stilts)
    strand_objs.append(sobj)

bpy.context.view_layer.update()

# Convert all hair curve strands into clean meshes
mesh_strand_objs = []
for sobj in strand_objs:
    bpy.ops.object.select_all(action='DESELECT')
    sobj.select_set(True)
    bpy.context.view_layer.objects.active = sobj
    bpy.ops.object.convert(target='MESH')
    mesh_strand_objs.append(sobj)

# Join scalp cap and all stylized strands into a single coherent GEO_Hair mesh
bpy.ops.object.select_all(action='DESELECT')
for mobj in [scalp_obj] + mesh_strand_objs:
    mobj.select_set(True)
bpy.context.view_layer.objects.active = scalp_obj
bpy.ops.object.join()

hair_unified = scalp_obj
hair_unified.name = "GEO_Hair"
link_to_col(hair_unified, col_geo, mats["hair"])

# Enforce anti-clipping on all vertices of unified hair
bm_h = bmesh.new()
bm_h.from_mesh(hair_unified.data)
prevent_clipping(bm_h, margin=0.016)
bm_h.to_mesh(hair_unified.data)
bm_h.free()
hair_unified.data.update()
print(f"PaulTodd hair generated & merged successfully: {len(hair_unified.data.vertices)} vertices, verified 0 clipping.")

# --- Botanical Foliage: Urtiga Leaves & Wild Flowers in Hair ---
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
    ("Urtiga_Crown_01", Vector((0.04, 0.06, 1.39)), Euler((math.radians(35), math.radians(15), math.radians(40)))),
    ("Urtiga_Crown_02", Vector((-0.05, 0.05, 1.38)), Euler((math.radians(40), math.radians(-25), math.radians(-30)))),
    ("Urtiga_Crown_03", Vector((0.10, 0.01, 1.34)), Euler((math.radians(20), math.radians(45), math.radians(70)))),
    ("Urtiga_Crown_04", Vector((-0.10, 0.01, 1.33)), Euler((math.radians(25), math.radians(-40), math.radians(-65)))),
    ("Urtiga_Shoulder_L", Vector((-0.17, 0.10, 1.12)), Euler((math.radians(45), math.radians(-30), math.radians(-20)))),
    ("Urtiga_Shoulder_R", Vector((0.17, 0.10, 1.12)), Euler((math.radians(45), math.radians(30), math.radians(20)))),
    ("Urtiga_Back_01", Vector((0.00, 0.17, 0.92)), Euler((math.radians(70), math.radians(10), math.radians(180)))),
    ("Urtiga_Back_02", Vector((-0.08, 0.17, 0.74)), Euler((math.radians(65), math.radians(-20), math.radians(160)))),
    ("Urtiga_Back_03", Vector((0.08, 0.17, 0.74)), Euler((math.radians(65), math.radians(20), math.radians(-160)))),
]

for name, loc, rot in urtiga_positions:
    create_urtiga_leaf(name, loc, rot)

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
    ("Fulo_Head_01", Vector((0.05, 0.03, 1.38)), Euler((math.radians(35), math.radians(20), math.radians(15))), 0.022, mats["fulo"]),
    ("Fulo_Head_02", Vector((-0.06, 0.02, 1.36)), Euler((math.radians(30), math.radians(-30), math.radians(-10))), 0.019, mats["fulo_amber"]),
    ("Fulo_Chest_01", Vector((-0.03, -0.15, 0.94)), Euler((math.radians(-15), math.radians(-10), math.radians(45))), 0.018, mats["fulo"]),
    ("Fulo_Back_01", Vector((0.04, 0.18, 0.86)), Euler((math.radians(80), math.radians(15), math.radians(120))), 0.022, mats["fulo_amber"]),
    ("Fulo_Back_02", Vector((-0.03, 0.17, 0.66)), Euler((math.radians(75), math.radians(-10), math.radians(150))), 0.020, mats["fulo"]),
]

for name, loc, rot, rad, fmat in flower_positions:
    create_forest_flower(name, loc, rot, rad, fmat)

# 4. BUILD THE WHIP ACCESSORY (Acessório Chicote que ela usa)
print("=== 3. Building Distinct Whip Accessory (Acessório Chicote) ===")

# The whip is a distinct, held accessory in collection PROPS
# Hand palm center: X=0.255, Y=-0.020, Z=0.675
handle_loc = Vector((0.255, -0.020, 0.675))
handle_rot = Euler((math.radians(18), math.radians(-28), math.radians(-25)))

# Distinct wooden / vine grip handle
bpy.ops.mesh.primitive_cylinder_add(
    radius=0.016, depth=0.24,
    location=handle_loc,
    rotation=handle_rot
)
handle_obj = bpy.context.active_object
handle_obj.name = "Acessorio_Chicote_Cabo"
link_to_col(handle_obj, col_props, mats["cipo"])

# Pommel knot & guard
bpy.ops.mesh.primitive_torus_add(
    major_radius=0.022, minor_radius=0.007,
    location=handle_loc + Vector((-0.025, 0.015, -0.10)),
    rotation=handle_rot
)
pommel = bpy.context.active_object
link_to_col(pommel, col_props, mats["cipo"])

bpy.ops.mesh.primitive_torus_add(
    major_radius=0.020, minor_radius=0.006,
    location=handle_loc + Vector((0.025, -0.015, 0.10)),
    rotation=handle_rot
)
guard = bpy.context.active_object
link_to_col(guard, col_props, mats["cipo"])

# Lash Body: dynamic S-curve sweeping forward and curving on the ground
lash_points = [
    handle_loc + Vector((0.03, -0.02, 0.11)),
    Vector((0.36, -0.10, 0.84)),  # arc up and forward
    Vector((0.46, -0.12, 0.72)),  # arc right
    Vector((0.48, -0.03, 0.50)),  # loop down
    Vector((0.42, 0.08, 0.32)),   # mid arc
    Vector((0.34, 0.16, 0.16)),   # sweep to floor
    Vector((0.22, 0.20, 0.03)),   # ground touch
    Vector((0.10, 0.22, 0.01)),   # coiled tip
]
lash_radii = [0.85, 0.80, 0.70, 0.60, 0.50, 0.40, 0.32, 0.22]

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

curve_lash.bevel_depth = 0.015
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

# Join handle parts into Acessorio_Chicote
bpy.ops.object.select_all(action='DESELECT')
for p in [pommel, guard, lash_obj, handle_obj]:
    p.select_set(True)
bpy.context.view_layer.objects.active = handle_obj
bpy.ops.object.join()
whip_accessory = handle_obj
whip_accessory.name = "Acessorio_Chicote"

# Nettle thorn nodes on the whip
whip_thorns = [
    ("Thorn_Whip_01", Vector((0.38, -0.11, 0.82)), Euler((math.radians(20), math.radians(40), math.radians(60))), Vector((0.016, 0.026, 0.003)), mats["urtiga"]),
    ("Thorn_Whip_02", Vector((0.48, -0.07, 0.60)), Euler((math.radians(-10), math.radians(60), math.radians(30))), Vector((0.018, 0.028, 0.003)), mats["urtiga"]),
    ("Thorn_Whip_03", Vector((0.44, 0.06, 0.38)), Euler((math.radians(30), math.radians(-40), math.radians(110))), Vector((0.016, 0.026, 0.003)), mats["urtiga"]),
    ("Thorn_Whip_Tip", Vector((0.12, 0.22, 0.02)), Euler((math.radians(10), math.radians(20), math.radians(180))), Vector((0.014, 0.022, 0.003)), mats["glow"]),
]

for name, loc, rot, scl, nmat in whip_thorns:
    th = create_urtiga_leaf(name, loc, rot, scl)
    link_to_col(th, col_props, nmat)
    bpy.ops.object.select_all(action='DESELECT')
    th.select_set(True)
    whip_accessory.select_set(True)
    bpy.context.view_layer.objects.active = whip_accessory
    bpy.ops.object.join()

print(f"Whip accessory finalized: {whip_accessory.name} with grip in right hand.")

# 5. Studio Lighting & Renders
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

# 6. Render Silhouette
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

# 7. Save Blend File
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
print(f"Saved refined blockout blend: {OUT_BLEND}")
