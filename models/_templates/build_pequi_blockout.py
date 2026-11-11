import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT_BLEND = os.path.join(ROOT_DIR, "models", "pequi", "pequi_blockout.blend")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "pequi", "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

# 1. Reset scene
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene["unit_name"] = "Pequi"

# Setup collections as required by spec
col_geo = bpy.data.collections.new("GEO")
col_rig = bpy.data.collections.new("RIG")
col_anim = bpy.data.collections.new("ANIM")
col_refs = bpy.data.collections.new("REFS")
for c in (col_geo, col_rig, col_anim, col_refs):
    scene.collection.children.link(c)

def make_mat(name, hex_color, roughness=0.65, metallic=0.0, emission_hex=None, emission_strength=0.0):
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
        eh = (emission_hex or hex_color).lstrip('#')
        ergb = tuple(int(eh[i:i+2], 16) / 255.0 for i in (0, 2, 4))
        elin = tuple(pow(c, 2.2) for c in ergb)
        bsdf.inputs["Emission Color"].default_value = (*elin, 1.0)
        bsdf.inputs["Emission Strength"].default_value = emission_strength
    return mat

mats = {
    "bark": make_mat("Mat_Bark", "#3B2B22", roughness=0.85),
    "bark_dark": make_mat("Mat_BarkDark", "#241913", roughness=0.90),
    "lichen": make_mat("Mat_Lichen", "#5E574A", roughness=0.80),
    "leaf": make_mat("Mat_Leaf", "#3E5A28", roughness=0.55),
    "leaf_light": make_mat("Mat_LeafLight", "#567533", roughness=0.50),
    "fruit_skin": make_mat("Mat_FruitSkin", "#465D28", roughness=0.65),
    "fruit_rind": make_mat("Mat_FruitRind", "#C8B878", roughness=0.60),
    "pulp_gold": make_mat("Mat_PulpGold", "#F29F05", roughness=0.35, emission_hex="#F29F05", emission_strength=0.35),
    "oil_drop": make_mat("Mat_OilDrop", "#FFC72C", roughness=0.25, emission_hex="#FFB833", emission_strength=0.8),
    "seed_core": make_mat("Mat_SeedCore", "#B87324", roughness=0.45, metallic=0.1, emission_hex="#FFB833", emission_strength=0.6),
    "seed_spine": make_mat("Mat_SeedSpine", "#E6A832", roughness=0.40, metallic=0.15, emission_hex="#FFB833", emission_strength=1.1),
    "sap_glow": make_mat("Mat_SapGlow", "#FFB833", roughness=0.30, emission_hex="#FFB833", emission_strength=3.2),
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

def create_tapered_curve_mesh(name, points, radii, bevel_depth=0.08, res_u=10, bevel_res=4, mat=mats["bark"], tilt_list=None):
    curve_data = bpy.data.curves.new(name=name, type='CURVE')
    curve_data.dimensions = '3D'
    spline = curve_data.splines.new('BEZIER')
    spline.bezier_points.add(len(points) - 1)
    for i, pt in enumerate(points):
        bp = spline.bezier_points[i]
        bp.co = Vector(pt)
        bp.radius = radii[i]
        bp.handle_left_type = 'AUTO'
        bp.handle_right_type = 'AUTO'
        if tilt_list and i < len(tilt_list):
            bp.tilt = tilt_list[i]
    curve_data.bevel_depth = bevel_depth
    curve_data.bevel_resolution = bevel_res
    curve_data.resolution_u = res_u
    curve_data.use_fill_caps = True
    obj = bpy.data.objects.new(name, curve_data)
    link_to_geo(obj, mat)
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.convert(target='MESH')
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj

# ---------------------------------------------------------
# 2. MAIN GNARLED TRUNK IN 'C' ARCH + TWISTED BARK STRANDS
# ---------------------------------------------------------
# Main C-shaped arch sweeping from base (0,0,0) -> Left (-X) -> Top Arch -> Pointed Beak above center
trunk_pts = [
    (0.02,  0.04, 0.00),
    (-0.14, 0.06, 0.28),
    (-0.36, 0.08, 0.62),
    (-0.38, 0.05, 0.98),
    (-0.22, 0.02, 1.34),
    (-0.02, -0.02, 1.44),
    (0.09, -0.05, 1.28),
    (-0.02, -0.08, 1.07), # Gnarled wooden beak pointing down toward floating seed
]
trunk_radii = [1.55, 1.35, 1.25, 1.15, 1.05, 0.90, 0.62, 0.12]
create_tapered_curve_mesh("BLK_MainTrunk_Arch", trunk_pts, trunk_radii, bevel_depth=0.105, res_u=12, bevel_res=5, mat=mats["bark"])

# Secondary twisted bark strands wrapping the trunk to form deep suberose fissures & upper sap eye cavity
bark_strands = [
    ("BLK_BarkStrand_01", [
        (-0.08, -0.06, 0.00), (-0.24, -0.05, 0.32), (-0.44, -0.02, 0.68),
        (-0.42, -0.04, 1.04), (-0.24, -0.06, 1.36), (-0.05, -0.08, 1.38), (0.03, -0.09, 1.13)
    ], [1.1, 1.0, 0.95, 0.85, 0.80, 0.65, 0.15], 0.055, mats["bark_dark"]),
    ("BLK_BarkStrand_02", [
        (0.10, 0.08, 0.00), (-0.06, 0.14, 0.30), (-0.28, 0.16, 0.65),
        (-0.30, 0.13, 1.02), (-0.12, 0.09, 1.38), (0.08, 0.03, 1.34), (0.01, -0.04, 1.10)
    ], [1.2, 1.05, 0.95, 0.90, 0.85, 0.65, 0.15], 0.055, mats["bark"]),
    # Outer crest bark forming the eyebrow/hood around the glowing sap fissure
    ("BLK_BarkHood_L", [
        (-0.34, -0.06, 0.92), (-0.20, -0.10, 1.24), (-0.06, -0.11, 1.34), (0.04, -0.10, 1.16)
    ], [0.75, 0.90, 0.80, 0.20], 0.045, mats["bark_dark"]),
    ("BLK_BarkHood_R", [
        (-0.24, 0.08, 0.95), (-0.06, 0.06, 1.28), (0.12, -0.02, 1.32), (0.02, -0.06, 1.09)
    ], [0.80, 0.95, 0.85, 0.18], 0.048, mats["bark"]),
    # Moss/lichen crust patches along the mid-left trunk
    ("BLK_LichenRidge_01", [
        (-0.22, -0.09, 0.38), (-0.42, -0.08, 0.66), (-0.40, -0.08, 0.94)
    ], [0.6, 1.0, 0.5], 0.038, mats["lichen"]),
]
for bname, bpts, brad, bdepth, bmat in bark_strands:
    create_tapered_curve_mesh(bname, bpts, brad, bevel_depth=bdepth, res_u=8, bevel_res=3, mat=bmat)

# Glowing Amber Sap Fissure ("Eye of Vigília") nestled inside the upper trunk arch
sap_pts = [
    (-0.15, -0.02, 1.16),
    (-0.06, -0.03, 1.27),
    (0.02, -0.04, 1.22),
    (-0.01, -0.06, 1.12),
]
sap_radii = [0.45, 1.05, 0.95, 0.25]
create_tapered_curve_mesh("BLK_SapFissure_Front", sap_pts, sap_radii, bevel_depth=0.048, res_u=8, bevel_res=3, mat=mats["sap_glow"])

# Secondary narrow Sap Fissure on the dorsal trunk (authorial decision #1)
sap_back_pts = [
    (-0.28, 0.13, 0.82),
    (-0.24, 0.12, 1.06),
    (-0.14, 0.10, 1.24),
]
create_tapered_curve_mesh("BLK_SapFissure_Back", sap_back_pts, [0.3, 0.85, 0.3], bevel_depth=0.032, res_u=6, bevel_res=3, mat=mats["sap_glow"])

# ---------------------------------------------------------
# 3. 5 GNARLED ROOTS PLANTED AT Z = 0.0
# ---------------------------------------------------------
roots_data = [
    ("BLK_Root_FrontL", [(-0.05, 0.00, 0.22), (-0.24, -0.18, 0.08), (-0.44, -0.32, 0.02), (-0.56, -0.40, 0.00)], [1.2, 0.95, 0.60, 0.20]),
    ("BLK_Root_FrontR", [(0.06, -0.02, 0.20), (0.22, -0.16, 0.07), (0.40, -0.26, 0.02), (0.52, -0.34, 0.00)], [1.1, 0.85, 0.55, 0.18]),
    ("BLK_Root_SideL",  [(-0.14, 0.04, 0.25), (-0.38, 0.06, 0.09), (-0.58, 0.08, 0.02), (-0.68, 0.10, 0.00)], [1.15, 0.85, 0.50, 0.18]),
    ("BLK_Root_BackL",  [(-0.08, 0.10, 0.22), (-0.22, 0.28, 0.08), (-0.36, 0.44, 0.02), (-0.46, 0.54, 0.00)], [1.1, 0.85, 0.50, 0.18]),
    ("BLK_Root_BackR",  [(0.08, 0.08, 0.18), (0.24, 0.22, 0.07), (0.38, 0.36, 0.02), (0.48, 0.44, 0.00)], [1.0, 0.80, 0.45, 0.15]),
]
for rname, rpts, rrad in roots_data:
    create_tapered_curve_mesh(rname, rpts, rrad, bevel_depth=0.065, res_u=8, bevel_res=4, mat=mats["bark"])

# Ensure no root vertices dip below Z = 0.0
for obj in col_geo.objects:
    if obj.name.startswith("BLK_Root") or obj.name.startswith("BLK_MainTrunk") or obj.name.startswith("BLK_Bark"):
        for v in obj.data.vertices:
            if v.co.z < 0.0:
                v.co.z = 0.0
        obj.data.update()

# ---------------------------------------------------------
# 4. LOWER CRADLE BRANCH & GIANT SPLIT-OPEN PEQUI FRUIT
# ---------------------------------------------------------
cradle_pts = [
    (-0.30, 0.02, 0.62),
    (-0.12, -0.06, 0.56),
    (0.08, -0.12, 0.48),
    (0.28, -0.14, 0.46),
    (0.46, -0.12, 0.52),
    (0.56, -0.08, 0.60),
]
cradle_rad = [1.15, 1.0, 0.92, 0.85, 0.65, 0.20]
create_tapered_curve_mesh("BLK_CradleBranch_Main", cradle_pts, cradle_rad, bevel_depth=0.072, res_u=10, bevel_res=4, mat=mats["bark"])

# Supporting wooden claws holding the open fruit at (0.26, -0.14, 0.58)
claw_front = [
    (0.10, -0.14, 0.48), (0.22, -0.24, 0.50), (0.34, -0.25, 0.58), (0.40, -0.20, 0.66)
]
create_tapered_curve_mesh("BLK_CradleClaw_Front", claw_front, [0.7, 0.6, 0.45, 0.12], bevel_depth=0.042, res_u=7, bevel_res=3, mat=mats["bark_dark"])

claw_back = [
    (0.14, -0.10, 0.49), (0.26, -0.02, 0.52), (0.38, -0.04, 0.60), (0.44, -0.08, 0.68)
]
create_tapered_curve_mesh("BLK_CradleClaw_Back", claw_back, [0.7, 0.6, 0.45, 0.12], bevel_depth=0.042, res_u=7, bevel_res=3, mat=mats["bark_dark"])

# Split-open Pequi Fruit resting in the cradle at fruit_center = (0.27, -0.14, 0.60)
fruit_center = Vector((0.27, -0.14, 0.60))

def create_open_fruit_half(name, side_sign):
    # Outer green shell hemisphere + inner pale mesocarp rim + lush golden fleshy pulp lobe
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.145, location=(0, 0, 0))
    shell = bpy.context.active_object
    shell.name = name + "_Shell"
    bm = bmesh.new()
    bm.from_mesh(shell.data)
    for v in bm.verts:
        # Flatten top slightly and carve bowl shape
        if v.co.z > 0.035:
            v.co.z = 0.035 + (v.co.z - 0.035) * 0.25
        # Elongate slightly along X/Y
        v.co.x *= 1.10
        v.co.y *= 0.95
    bm.to_mesh(shell.data)
    bm.free()
    shell.location = fruit_center + Vector((side_sign * 0.075, 0.0, 0.0))
    shell.rotation_euler = Euler((math.radians(14), side_sign * math.radians(24), side_sign * math.radians(-10)), 'XYZ')
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    link_to_geo(shell, mats["fruit_skin"])

    # Golden Pulp Lobe crowning the open shell
    bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=12, radius=0.118, location=(0, 0, 0))
    pulp = bpy.context.active_object
    pulp.name = name + "_Pulp"
    bm = bmesh.new()
    bm.from_mesh(pulp.data)
    for v in bm.verts:
        v.co.z *= 0.78
        v.co.x *= 1.05
        # Bulge outward toward the front-top
        if v.co.y < 0 and v.co.z > 0:
            v.co.y *= 1.15
            v.co.z *= 1.15
    bm.to_mesh(pulp.data)
    bm.free()
    pulp.location = fruit_center + Vector((side_sign * 0.068, -0.01, 0.035))
    pulp.rotation_euler = Euler((math.radians(18), side_sign * math.radians(18), 0.0), 'XYZ')
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    link_to_geo(pulp, mats["pulp_gold"])

create_open_fruit_half("BLK_OpenFruit_L", -1.0)
create_open_fruit_half("BLK_OpenFruit_R",  1.0)

# Inner thorny core peeking between the two open fruit halves
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2, radius=0.068, location=fruit_center + Vector((0.0, -0.01, 0.065)))
inner_core = bpy.context.active_object
inner_core.name = "BLK_OpenFruit_InnerThornyCore"
link_to_geo(inner_core, mats["seed_core"])

# Dripping golden oil drops at the front of the split fruit
oil_drops = [
    (fruit_center + Vector((0.05, -0.14, 0.01)), (0.022, 0.022, 0.045)),
    (fruit_center + Vector((0.09, -0.15, -0.04)), (0.018, 0.018, 0.038)),
    (fruit_center + Vector((-0.03, -0.13, 0.00)), (0.020, 0.020, 0.036)),
]
for idx, (dloc, dscale) in enumerate(oil_drops):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=10, ring_count=8, radius=1.0, location=dloc)
    drop = bpy.context.active_object
    drop.name = f"BLK_OilDrop_{idx+1:02d}"
    drop.scale = dscale
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    link_to_geo(drop, mats["oil_drop"])

# ---------------------------------------------------------
# 5. CENTRAL FLOATING ARCANE SPINY SEED ("SEMENTE ESPINHOSA")
# ---------------------------------------------------------
seed_center = Vector((0.02, -0.05, 0.89))

bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=14, radius=0.115, location=seed_center)
seed_core = bpy.context.active_object
seed_core.name = "BLK_SpinySeed_Core"
seed_core.scale = (1.08, 0.96, 0.92)
seed_core.rotation_euler = Euler((math.radians(12), math.radians(-18), math.radians(8)), 'XYZ')
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
link_to_geo(seed_core, mats["seed_core"])

# Generate 64 sharp conical thorns over the floating seed using a Fibonacci sphere distribution
bm_spines = bmesh.new()
num_spines = 64
golden_angle = math.pi * (3.0 - math.sqrt(5.0))
for i in range(num_spines):
    y = 1.0 - (i / float(num_spines - 1)) * 2.0
    radius_at_y = math.sqrt(max(0.0, 1.0 - y * y))
    theta = golden_angle * i
    nx = math.cos(theta) * radius_at_y
    nz = math.sin(theta) * radius_at_y
    normal = Vector((nx * 1.08, y * 0.96, nz * 0.92)).normalized()
    base_pos = seed_center + Vector((nx * 0.115 * 1.04, y * 0.115 * 0.92, nz * 0.115 * 0.88))
    spine_len = 0.052 if (i % 3 == 0) else 0.038
    base_r = 0.015 if (i % 3 == 0) else 0.012
    tip_pos = base_pos + normal * spine_len

    # Build a 5-sided cone for each spine
    up = Vector((0, 0, 1)) if abs(normal.z) < 0.9 else Vector((1, 0, 0))
    t1 = normal.cross(up).normalized()
    t2 = normal.cross(t1).normalized()
    ring_verts = []
    for k in range(5):
        ang = (2.0 * math.pi * k) / 5.0
        v_pos = base_pos + (t1 * math.cos(ang) + t2 * math.sin(ang)) * base_r
        ring_verts.append(bm_spines.verts.new(v_pos))
    v_tip = bm_spines.verts.new(tip_pos)
    for k in range(5):
        bm_spines.faces.new((ring_verts[k], ring_verts[(k + 1) % 5], v_tip))
    bm_spines.faces.new(tuple(reversed(ring_verts)))

spines_mesh = bpy.data.meshes.new("BLK_SpinySeed_Spines")
bm_spines.to_mesh(spines_mesh)
bm_spines.free()
spines_obj = bpy.data.objects.new("BLK_SpinySeed_Spines", spines_mesh)
link_to_geo(spines_obj, mats["seed_spine"])

# Arcane swirling energy ribbons orbiting the floating spiny seed
orbit_1_pts = [
    (seed_center.x - 0.18, seed_center.y - 0.06, seed_center.z - 0.08),
    (seed_center.x - 0.06, seed_center.y - 0.16, seed_center.z + 0.06),
    (seed_center.x + 0.14, seed_center.y - 0.08, seed_center.z + 0.15),
    (seed_center.x + 0.19, seed_center.y + 0.08, seed_center.z + 0.02),
    (seed_center.x + 0.06, seed_center.y + 0.15, seed_center.z - 0.12),
]
create_tapered_curve_mesh("BLK_ArcaneOrbit_01", orbit_1_pts, [0.15, 0.85, 1.0, 0.85, 0.15], bevel_depth=0.010, res_u=10, bevel_res=2, mat=mats["sap_glow"])

orbit_2_pts = [
    (seed_center.x + 0.17, seed_center.y - 0.05, seed_center.z - 0.11),
    (seed_center.x + 0.02, seed_center.y - 0.15, seed_center.z - 0.16),
    (seed_center.x - 0.17, seed_center.y - 0.02, seed_center.z - 0.03),
    (seed_center.x - 0.15, seed_center.y + 0.12, seed_center.z + 0.12),
    (seed_center.x + 0.04, seed_center.y + 0.14, seed_center.z + 0.16),
]
create_tapered_curve_mesh("BLK_ArcaneOrbit_02", orbit_2_pts, [0.15, 0.80, 1.0, 0.80, 0.15], bevel_depth=0.009, res_u=10, bevel_res=2, mat=mats["sap_glow"])

# ---------------------------------------------------------
# 6. CANOPY BRANCHES, CLOSED GREEN FRUITS & TRIFOLIATE LEAVES
# ---------------------------------------------------------
branches_data = [
    # Upper-right sweeping bough holding the 3 closed green fruits
    ("BLK_Branch_UpperR", [
        (-0.04, 0.00, 1.38), (0.18, 0.02, 1.35), (0.36, 0.00, 1.24), (0.50, -0.02, 1.08), (0.58, -0.04, 0.94)
    ], [0.95, 0.80, 0.65, 0.45, 0.18], 0.058),
    # Upper-left crown branch
    ("BLK_Branch_CrownL", [
        (-0.24, 0.04, 1.30), (-0.42, 0.06, 1.44), (-0.56, 0.02, 1.54), (-0.66, -0.02, 1.60)
    ], [0.85, 0.68, 0.48, 0.18], 0.052),
    # Top crown branch reaching 1.72m
    ("BLK_Branch_CrownTop", [
        (-0.12, 0.04, 1.38), (-0.08, 0.08, 1.54), (0.04, 0.06, 1.66), (0.16, 0.02, 1.72)
    ], [0.80, 0.62, 0.42, 0.16], 0.048),
    # Lower-left branch holding the 2 hanging closed green fruits
    ("BLK_Branch_LowerL", [
        (-0.36, 0.04, 0.64), (-0.52, -0.02, 0.56), (-0.64, -0.06, 0.48)
    ], [0.80, 0.58, 0.20], 0.048),
]
for br_name, br_pts, br_rad, br_depth in branches_data:
    create_tapered_curve_mesh(br_name, br_pts, br_rad, bevel_depth=br_depth, res_u=8, bevel_res=3, mat=mats["bark"])

def create_closed_pequi_fruit(name, loc, radius=0.095, rot_deg=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=radius, location=loc)
    fr = bpy.context.active_object
    fr.name = name
    fr.scale = (0.96, 0.96, 1.08)
    fr.rotation_euler = Euler(tuple(math.radians(a) for a in rot_deg), 'XYZ')
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    link_to_geo(fr, mats["fruit_skin"])

# 3 closed fruits on upper right branch + 2 closed fruits on lower left branch
closed_fruits = [
    ("BLK_ClosedFruit_R1", (0.40, -0.06, 1.07), 0.102, (8, -12, 5)),
    ("BLK_ClosedFruit_R2", (0.50,  0.03, 1.15), 0.092, (-6, 15, -10)),
    ("BLK_ClosedFruit_R3", (0.31,  0.05, 1.12), 0.084, (10, 6, 12)),
    ("BLK_ClosedFruit_L1", (-0.36, -0.08, 0.43), 0.096, (-8, -10, 0)),
    ("BLK_ClosedFruit_L2", (-0.23, -0.10, 0.36), 0.105, (6, 12, -8)),
]
for fname, floc, frad, frot in closed_fruits:
    create_closed_pequi_fruit(fname, floc, frad, frot)

def create_trifoliate_leaf_cluster(name, origin, rot_deg, scale=1.0):
    # Creates a 3-leaflet compound leaf cluster characteristic of Caryocar brasiliense
    bm = bmesh.new()
    leaflet_angles = [-42.0, 0.0, 42.0]
    leaflet_scales = [0.82, 1.0, 0.82]
    for idx, (ang_deg, lsc) in enumerate(zip(leaflet_angles, leaflet_scales)):
        ang = math.radians(ang_deg)
        length = 0.24 * scale * lsc
        width = 0.11 * scale * lsc
        # Create diamond/ovate leaflet with midrib arch
        p0 = Vector((0.0, 0.0, 0.0))
        p1 = Vector((-width * 0.65, length * 0.35, 0.015 * scale))
        p2 = Vector((0.0, length * 0.45, 0.028 * scale))
        p3 = Vector((width * 0.65, length * 0.35, 0.015 * scale))
        p4 = Vector((-width * 0.85, length * 0.72, -0.005 * scale))
        p5 = Vector((0.0, length * 0.75, 0.012 * scale))
        p6 = Vector((width * 0.85, length * 0.72, -0.005 * scale))
        p7 = Vector((0.0, length, -0.035 * scale))

        rot_m = Matrix.Rotation(ang, 3, 'Z')
        pts = [rot_m @ p for p in (p0, p1, p2, p3, p4, p5, p6, p7)]
        verts = [bm.verts.new(pt) for pt in pts]
        bm.faces.new((verts[0], verts[1], verts[2]))
        bm.faces.new((verts[0], verts[2], verts[3]))
        bm.faces.new((verts[1], verts[4], verts[5], verts[2]))
        bm.faces.new((verts[2], verts[5], verts[6], verts[3]))
        bm.faces.new((verts[4], verts[7], verts[5]))
        bm.faces.new((verts[5], verts[7], verts[6]))

    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    obj.location = Vector(origin)
    obj.rotation_euler = Euler(tuple(math.radians(a) for a in rot_deg), 'XYZ')
    link_to_geo(obj, mats["leaf"] if "Light" not in name else mats["leaf_light"])
    solid = obj.modifiers.new("Solidify", 'SOLIDIFY')
    solid.thickness = 0.008
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    bpy.ops.object.select_all(action='DESELECT')
    obj.select_set(True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    return obj

leaf_clusters = [
    ("BLK_LeafCluster_TopR1",   (0.24, -0.02, 1.36), (-20, 15, -35), 1.15),
    ("BLK_LeafCluster_TopR2_Light", (0.42, 0.04, 1.26), (-30, 28, -75), 1.10),
    ("BLK_LeafCluster_FarR",    (0.54, -0.04, 1.02), (-40, 35, -110), 0.95),
    ("BLK_LeafCluster_Crown1_Light", (-0.04, 0.06, 1.62), (15, -10, 10), 1.15),
    ("BLK_LeafCluster_Crown2",  (-0.34, 0.04, 1.48), (22, -28, 55), 1.15),
    ("BLK_LeafCluster_UpperL",  (-0.56, 0.00, 1.52), (-15, -35, 95), 1.05),
    ("BLK_LeafCluster_MidL_Light", (-0.42, -0.08, 0.72), (-35, -20, 125), 0.95),
    ("BLK_LeafCluster_BottomR", (0.32, -0.18, 0.44), (-55, 18, -145), 1.05),
    ("BLK_LeafCluster_BottomC", (0.04, -0.16, 0.42), (-60, -8, 175), 1.00),
    ("BLK_LeafCluster_Back1",   (-0.18, 0.16, 1.32), (35, 0, 180), 1.05),
]
for lname, lorig, lrot, lsc in leaf_clusters:
    create_trifoliate_leaf_cluster(lname, lorig, lrot, lsc)

# ---------------------------------------------------------
# 7. LIGHTING, PEDESTAL & CAMERA FOR PRANCHA DE INTERPRETAÇÃO
# ---------------------------------------------------------
bpy.ops.mesh.primitive_cylinder_add(vertices=48, radius=0.85, depth=0.02, location=(0, 0, -0.01))
floor_pedestal = bpy.context.active_object
floor_pedestal.name = "REF_Pedestal"
mat_floor = make_mat("Mat_Floor", "#2A262B", roughness=0.90)
floor_pedestal.data.materials.append(mat_floor)
for c in list(floor_pedestal.users_collection):
    c.objects.unlink(floor_pedestal)
col_refs.objects.link(floor_pedestal)

# 3-Point Neutral Studio Lighting + Warm Rim
def add_light(name, ltype, loc, rot_deg, energy, color_hex="#FFFFFF", size=1.5):
    ldata = bpy.data.lights.new(name=name, type=ltype)
    h = color_hex.lstrip('#')
    ldata.color = tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    ldata.energy = energy
    if ltype == 'AREA':
        ldata.size = size
    lobj = bpy.data.objects.new(name=name, object_data=ldata)
    lobj.location = Vector(loc)
    lobj.rotation_euler = Euler(tuple(math.radians(a) for a in rot_deg), 'XYZ')
    col_refs.objects.link(lobj)
    return lobj

add_light("KeyLight",  'AREA', (1.8, -2.2, 2.4), (48, 0, 38), 160.0, "#FFF6E8", size=2.0)
add_light("FillLight", 'AREA', (-2.2, -1.6, 1.6), (60, 0, -48), 75.0, "#D8E4F0", size=2.2)
add_light("RimLight",  'AREA', (0.0, 2.4, 2.2), (-52, 0, 180), 110.0, "#FFE0B2", size=2.0)

# World background
world = bpy.data.worlds.new("StudioWorld")
scene.world = world
world.use_nodes = True
bg_node = world.node_tree.nodes.get("Background")
if bg_node:
    bg_node.inputs[0].default_value = (0.04, 0.035, 0.045, 1.0)
    bg_node.inputs[1].default_value = 0.6

# Camera Setup
cam_data = bpy.data.cameras.new("RenderCam")
cam_data.lens = 58
cam_obj = bpy.data.objects.new("RenderCam", cam_data)
col_refs.objects.link(cam_obj)
scene.camera = cam_obj

scene.render.engine = 'BLENDER_EEVEE_NEXT' if hasattr(bpy.types, 'RenderSettings') and 'BLENDER_EEVEE_NEXT' in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items] else 'BLENDER_EEVEE'
scene.render.resolution_x = 1024
scene.render.resolution_y = 1024
scene.render.film_transparent = True

center_target = Vector((0.02, 0.0, 0.86))
cam_dist = 2.95

views = {
    "front": (math.radians(0), Vector((0.02, -cam_dist, 0.92))),
    "side": (math.radians(90), Vector((cam_dist, 0.0, 0.92))),
    "three_quarter": (math.radians(38), Vector((cam_dist * 0.62, -cam_dist * 0.78, 1.02))),
    "back": (math.radians(180), Vector((0.02, cam_dist, 0.92))),
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

# Render flat black silhouette on lighter neutral background or alpha for sheet
sil_mat = bpy.data.materials.new("Mat_Silhouette")
sil_mat.use_nodes = True
bsdf_sil = sil_mat.node_tree.nodes.get("Principled BSDF")
bsdf_sil.inputs["Base Color"].default_value = (0.02, 0.02, 0.025, 1.0)
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
cam_obj.location = views["front"][1]
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

# Save blockout blend
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
print(f"Saved blockout blend: {OUT_BLEND}")

