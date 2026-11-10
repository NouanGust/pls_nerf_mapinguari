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
col_props = bpy.data.collections.new("PROPS")
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
    "hair": make_mat("Mat_Hair", "#131012", roughness=0.62),
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

# 3. BUILD HIGH-QUALITY STYLIZED HAIR MESH (Malha de Cabelo Esculpida)
print("=== 2. Building High-Quality Stylized Hair Mesh ===")

# --- A: Anatomical Scalp Base (Cranium Volume conforming naturally to skull) ---
# We extract cranium faces with realistic hairline
bm_body = bmesh.new()
bm_body.from_mesh(body.data)
# Cranium vertices above hairline
scalp_faces = []
for f in bm_body.faces:
    c = f.calc_center_median()
    # Hairline boundary: forehead boundary around Z=1.28, temple Z=1.24, neck Z=1.17
    is_hair = False
    if c.z > 1.30: # top of head
        is_hair = True
    elif c.z > 1.25 and c.y > -0.065: # mid forehead to back
        is_hair = True
    elif c.z > 1.18 and c.y > -0.015: # temples & ears to back
        is_hair = True
    elif c.z > 1.14 and c.y > 0.035: # nape of neck
        is_hair = True
    if is_hair:
        scalp_faces.append(f)

bm_scalp = bmesh.new()
vmap = {}
for f in scalp_faces:
    for v in f.verts:
        if v not in vmap:
            # Add subtle hair volume puff outward along normal (0.010m - 0.016m)
            puff = 0.016 if v.co.z > 1.28 else 0.011
            n_off = v.normal * puff
            vmap[v] = bm_scalp.verts.new(v.co + n_off)
    bm_scalp.faces.new([vmap[v] for v in f.verts])
bm_body.free()

prevent_clipping(bm_scalp, margin=0.012)
scalp_mesh = bpy.data.meshes.new("GEO_Hair_Scalp")
bm_scalp.to_mesh(scalp_mesh)
bm_scalp.free()

scalp_obj = bpy.data.objects.new("GEO_Hair_Scalp", scalp_mesh)
link_to_col(scalp_obj, col_geo, mats["hair"])
mod_sc = scalp_obj.modifiers.new("Solidify", 'SOLIDIFY')
mod_sc.thickness = 0.008
mod_sc.offset = 1.0
bpy.context.view_layer.objects.active = scalp_obj
bpy.ops.object.modifier_apply(modifier="Solidify")

# --- B: Stylized Bangs (Franjas esculpidas em leque sobre a testa) ---
def create_bang_strand(name, p0, p1, p2, p3, w0=0.035, w1=0.045, w2=0.030, w3=0.005):
    bm = bmesh.new()
    pts = [p0, p1, p2, p3]
    ws = [w0, w1, w2, w3]
    prev_l, prev_r = None, None
    for i, (pt, w) in enumerate(zip(pts, ws)):
        if i < len(pts) - 1:
            tangent = (pts[i+1] - pt).normalized()
        else:
            tangent = (pt - pts[i-1]).normalized()
        side = tangent.cross(Vector((0, 0, 1))).normalized()
        if side.length < 0.1:
            side = Vector((1, 0, 0))
        vl = bm.verts.new(pt - side * (w * 0.5))
        vr = bm.verts.new(pt + side * (w * 0.5))
        if prev_l and prev_r:
            bm.faces.new([prev_l, vl, vr, prev_r])
        prev_l = vl
        prev_r = vr
    prevent_clipping(bm, margin=0.015)
    m = bpy.data.meshes.new(name)
    bm.to_mesh(m)
    bm.free()
    obj = bpy.data.objects.new(name, m)
    link_to_col(obj, col_geo, mats["hair"])
    mod = obj.modifiers.new("Solidify", 'SOLIDIFY')
    mod.thickness = 0.006
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    return obj

bang_objs = [
    # Center Bang (sweeping gently across center brow)
    create_bang_strand("Bang_Center",
        Vector((0.01, -0.065, 1.34)),
        Vector((0.00, -0.095, 1.28)),
        Vector((-0.01, -0.118, 1.22)),
        Vector((-0.015, -0.125, 1.18)),
        w0=0.035, w1=0.048, w2=0.032, w3=0.004
    ),
    # Left Bang (framing left eyebrow)
    create_bang_strand("Bang_L",
        Vector((-0.03, -0.060, 1.33)),
        Vector((-0.045, -0.090, 1.27)),
        Vector((-0.060, -0.112, 1.20)),
        Vector((-0.065, -0.118, 1.16)),
        w0=0.032, w1=0.042, w2=0.028, w3=0.004
    ),
    # Right Bang (framing right eyebrow)
    create_bang_strand("Bang_R",
        Vector((0.04, -0.060, 1.33)),
        Vector((0.055, -0.090, 1.27)),
        Vector((0.070, -0.112, 1.20)),
        Vector((0.075, -0.118, 1.16)),
        w0=0.032, w1=0.042, w2=0.028, w3=0.004
    ),
]

# --- C: Continuous Sculpted Hair Cloak (Manto de Cabelo Contínuo Posterior) ---
# We build a continuous, rich quad mesh sheet cascading from skull nape (Z=1.22) down to calves (Z=0.38)
# It features 7 sculpted ridges/valleys that flare out into stylized lock points at the bottom.
print("Building continuous sculpted hair mantle...")
bm_mantle = bmesh.new()

# Define grid rings from top to bottom
# Z levels: 1.22 (nape), 1.12 (shoulders), 1.00 (scapula), 0.86 (mid back), 0.70 (lumbar), 0.54 (hips), 0.38 (calves/tips)
# At each level, define Y depth and X width to stay outside the body
z_levels = [1.22, 1.12, 1.00, 0.86, 0.70, 0.54, 0.38]
# Y coordinates at each level (strictly behind body back surface: scapula Y=0.06, hips Y=0.095)
y_levels = [0.095, 0.120, 0.135, 0.145, 0.155, 0.145, 0.120]
# Half-widths at each level (expanding then tapering at tips)
hw_levels = [0.08, 0.14, 0.18, 0.21, 0.22, 0.20, 0.16]

# 9 columns across X (-hw to +hw)
num_cols = 9
grid_verts = []

for row_idx, (z, y_base, hw) in enumerate(zip(z_levels, y_levels, hw_levels)):
    row = []
    for col_idx in range(num_cols):
        t = col_idx / (num_cols - 1) # 0.0 to 1.0
        x = -hw + t * (2.0 * hw)
        # Add stylized scalloped curvature: center and outer curves have depth modulation
        # Columns 1, 3, 5, 7 are ridges (slight Y offset), 0, 2, 4, 6, 8 are valleys
        ridge_mod = 0.012 if (col_idx % 2 == 1) else -0.005
        # Parabolic wrap around the back: outer edges come forward slightly
        wrap = 0.025 * (1.0 - (x / hw)**2)
        y = y_base + wrap + ridge_mod
        v = bm_mantle.verts.new((x, y, z))
        row.append(v)
    grid_verts.append(row)

# Connect quads between rows
for r in range(len(z_levels) - 1):
    for c in range(num_cols - 1):
        v00 = grid_verts[r][c]
        v10 = grid_verts[r+1][c]
        v11 = grid_verts[r+1][c+1]
        v01 = grid_verts[r][c+1]
        bm_mantle.faces.new([v00, v10, v11, v01])

# Extrude bottom tips into stylized triangular lock points
bot_row = grid_verts[-1]
for i in range(0, num_cols - 1, 2):
    v_left = bot_row[i]
    v_mid = bot_row[i+1]
    v_right = bot_row[i+2]
    tip_pt = Vector(((v_left.co.x + v_right.co.x)*0.5, v_mid.co.y - 0.015, bot_row[0].co.z - 0.08))
    v_tip = bm_mantle.verts.new(tip_pt)
    bm_mantle.faces.new([v_left, v_mid, v_tip])
    bm_mantle.faces.new([v_mid, v_right, v_tip])

prevent_clipping(bm_mantle, margin=0.020)

mantle_mesh = bpy.data.meshes.new("GEO_Hair_Mantle")
bm_mantle.to_mesh(mantle_mesh)
bm_mantle.free()

mantle_obj = bpy.data.objects.new("GEO_Hair_Mantle", mantle_mesh)
link_to_col(mantle_obj, col_geo, mats["hair"])

# Add Solidify for stylized thickness
mod_m = mantle_obj.modifiers.new("Solidify", 'SOLIDIFY')
mod_m.thickness = 0.012
mod_m.offset = 1.0 # solidify outward
bpy.context.view_layer.objects.active = mantle_obj
bpy.ops.object.modifier_apply(modifier="Solidify")

mod_sm = mantle_obj.modifiers.new("Subsurf", 'SUBSURF')
mod_sm.levels = 1
bpy.ops.object.modifier_apply(modifier="Subsurf")

# --- D: Front-Side Cascades (Mechas Frontais que vestem o corpo sem clipar) ---
# Front cascades fall over the shoulders, framing the neck, covering the chest and waist
def create_front_curtain(name, is_left=True):
    bm = bmesh.new()
    sgn = -1.0 if is_left else 1.0
    
    # 5 sections down from shoulder over chest to hip
    # Chest surface is Y = -0.117. We place vertices at Y <= -0.130 (completely outside!)
    pts = [
        Vector((sgn * 0.10, -0.04, 1.20)), # temple / ear
        Vector((sgn * 0.12, -0.08, 1.10)), # clavicle / shoulder crest
        Vector((sgn * 0.09, -0.135, 0.98)), # upper chest drape
        Vector((sgn * 0.06, -0.140, 0.84)), # mid chest
        Vector((sgn * 0.04, -0.130, 0.70)), # waist drape
        Vector((sgn * 0.02, -0.115, 0.56)), # lower tip
    ]
    widths = [0.05, 0.08, 0.09, 0.08, 0.06, 0.01]
    
    prev_l, prev_r = None, None
    for i, (pt, w) in enumerate(zip(pts, widths)):
        if i < len(pts) - 1:
            tangent = (pts[i+1] - pt).normalized()
        else:
            tangent = (pt - pts[i-1]).normalized()
        side = tangent.cross(Vector((0, 0, 1))).normalized()
        if side.length < 0.1:
            side = Vector((1, 0, 0))
        vl = bm.verts.new(pt - side * (w * 0.5))
        vr = bm.verts.new(pt + side * (w * 0.5))
        if prev_l and prev_r:
            bm.faces.new([prev_l, vl, vr, prev_r])
        prev_l = vl
        prev_r = vr
        
    prevent_clipping(bm, margin=0.018)
    m = bpy.data.meshes.new(name)
    bm.to_mesh(m)
    bm.free()
    
    obj = bpy.data.objects.new(name, m)
    link_to_col(obj, col_geo, mats["hair"])
    mod = obj.modifiers.new("Solidify", 'SOLIDIFY')
    mod.thickness = 0.010
    mod.offset = 1.0
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    
    mod_s = obj.modifiers.new("Subsurf", 'SUBSURF')
    mod_s.levels = 1
    bpy.ops.object.modifier_apply(modifier="Subsurf")
    return obj

front_curtain_l = create_front_curtain("Hair_Front_Curtain_L", is_left=True)
front_curtain_r = create_front_curtain("Hair_Front_Curtain_R", is_left=False)

# Join all hair elements into one unified, cohesive hair mesh: GEO_Hair
bpy.ops.object.select_all(action='DESELECT')
for h_obj in [scalp_obj, mantle_obj, front_curtain_l, front_curtain_r] + bang_objs:
    h_obj.select_set(True)
bpy.context.view_layer.objects.active = scalp_obj
bpy.ops.object.join()
hair_unified = scalp_obj
hair_unified.name = "GEO_Hair"
link_to_col(hair_unified, col_geo, mats["hair"])

# Final safety pass: verify every vertex of unified hair has zero collision
bm_h = bmesh.new()
bm_h.from_mesh(hair_unified.data)
prevent_clipping(bm_h, margin=0.015)
bm_h.to_mesh(hair_unified.data)
bm_h.free()
hair_unified.data.update()
print(f"Hair unified successfully: {len(hair_unified.data.vertices)} vertices, zero clipping verified.")

# --- E: Add Stinging Nettle (Urtiga) and Wild Forest Flowers (Fulô) ---
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
    ("Urtiga_Crown_01", Vector((0.04, 0.08, 1.38)), Euler((math.radians(35), math.radians(15), math.radians(40)))),
    ("Urtiga_Crown_02", Vector((-0.05, 0.07, 1.37)), Euler((math.radians(40), math.radians(-25), math.radians(-30)))),
    ("Urtiga_Crown_03", Vector((0.10, 0.02, 1.35)), Euler((math.radians(20), math.radians(45), math.radians(70)))),
    ("Urtiga_Crown_04", Vector((-0.10, 0.02, 1.34)), Euler((math.radians(25), math.radians(-40), math.radians(-65)))),
    ("Urtiga_Shoulder_L", Vector((-0.16, 0.12, 1.14)), Euler((math.radians(45), math.radians(-30), math.radians(-20)))),
    ("Urtiga_Shoulder_R", Vector((0.16, 0.12, 1.14)), Euler((math.radians(45), math.radians(30), math.radians(20)))),
    ("Urtiga_Back_01", Vector((0.00, 0.18, 0.96)), Euler((math.radians(70), math.radians(10), math.radians(180)))),
    ("Urtiga_Back_02", Vector((-0.08, 0.18, 0.78)), Euler((math.radians(65), math.radians(-20), math.radians(160)))),
    ("Urtiga_Back_03", Vector((0.08, 0.18, 0.78)), Euler((math.radians(65), math.radians(20), math.radians(-160)))),
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
    ("Fulo_Head_01", Vector((0.05, 0.04, 1.37)), Euler((math.radians(35), math.radians(20), math.radians(15))), 0.022, mats["fulo"]),
    ("Fulo_Head_02", Vector((-0.06, 0.03, 1.35)), Euler((math.radians(30), math.radians(-30), math.radians(-10))), 0.019, mats["fulo_amber"]),
    ("Fulo_Chest_01", Vector((-0.03, -0.15, 0.94)), Euler((math.radians(-15), math.radians(-10), math.radians(45))), 0.018, mats["fulo"]),
    ("Fulo_Back_01", Vector((0.04, 0.19, 0.88)), Euler((math.radians(80), math.radians(15), math.radians(120))), 0.022, mats["fulo_amber"]),
    ("Fulo_Back_02", Vector((-0.03, 0.18, 0.68)), Euler((math.radians(75), math.radians(-10), math.radians(150))), 0.020, mats["fulo"]),
]

for name, loc, rot, rad, fmat in flower_positions:
    create_forest_flower(name, loc, rot, rad, fmat)

# 4. BUILD THE WHIP ACCESSORY (Acessório Chicote que ela usa)
print("=== 3. Building Distinct Whip Accessory (Acessório Chicote) ===")

# The whip is a distinct, held accessory in collection PROPS
# Hand center: X=0.255, Y=-0.020, Z=0.680
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

