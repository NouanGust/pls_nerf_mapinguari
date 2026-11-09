import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

ROOT_DIR = r"c:\Users\Sarah\Desktop\Nerf_mapinguari\pls_nerf_mapinguari-main"
BUNDLE_PATH = os.path.join(ROOT_DIR, "models", "_templates", "human_base_meshes_bundle.blend")
CONCEPT_PATH = os.path.join(ROOT_DIR, "art", "concepts", "mae_dagua", "mae_dagua_concept.png")
OUT_BLEND = os.path.join(ROOT_DIR, "models", "mae_dagua", "mae_dagua_blockout.blend")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "mae_dagua", "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

# Reset scene
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene["unit_name"] = "MaeDagua"

# Create standard collections per spec (GEO, RIG, ANIM, REFS)
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
    "skin": make_mat("Mat_Skin", "#9C5A38", roughness=0.50),
    "hair": make_mat("Mat_Hair", "#181518", roughness=0.65),
    "tail_scales": make_mat("Mat_TailScales", "#1F6E75", roughness=0.38),
    "tail_gold": make_mat("Mat_TailGold", "#D89C42", roughness=0.42),
    "fin": make_mat("Mat_Fin", "#E09F3E", roughness=0.40),
    "fin_tip": make_mat("Mat_FinTip", "#1B707E", roughness=0.40),
    "gold": make_mat("Mat_Gold", "#D4A346", roughness=0.35, metallic=0.75),
    "feather_orange": make_mat("Mat_FeatherOrange", "#E87A24", roughness=0.60),
    "feather_green": make_mat("Mat_FeatherGreen", "#3A9D42", roughness=0.60),
    "feather_teal": make_mat("Mat_FeatherTeal", "#1F7A8C", roughness=0.60),
    "feather_navy": make_mat("Mat_FeatherNavy", "#16324F", roughness=0.60),
    "beads_red": make_mat("Mat_BeadsRed", "#C83E31", roughness=0.45),
    "beads_cyan": make_mat("Mat_BeadsCyan", "#43F0D3", roughness=0.35, emission_strength=0.6),
    "eye_dark": make_mat("Mat_EyeDark", "#1E1410", roughness=0.20),
}

def link_to_geo(obj, mat=None):
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    col_geo.objects.link(obj)
    if mat:
        obj.data.materials.clear()
        obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True

def bbox_center(obj):
    pts = [obj.matrix_world @ Vector(corner) for corner in obj.bound_box]
    return sum(pts, Vector((0, 0, 0))) / 8.0

# 1. Load Stylized Female Primitive Upper Body from bundle
with bpy.data.libraries.load(BUNDLE_PATH, link=False) as (data_from, data_to):
    data_to.collections = ["Body Female - Primitive (Stylized)"]

src_col = data_to.collections[0]
imported_objs = [o for o in src_col.all_objects if o.type == 'MESH']

for o in imported_objs:
    scene.collection.objects.link(o)
bpy.context.view_layer.update()

keep_objs = []
pelvis_orig_x = -3.234
pelvis_orig_y = -0.037
pelvis_orig_z = 0.960
offset = Vector((-pelvis_orig_x, -pelvis_orig_y, 0.90 - pelvis_orig_z))

for o in imported_objs:
    lname = o.name.lower()
    if any(k in lname for k in ("leg_", "foot_", "toe_")):
        bpy.data.objects.remove(o, do_unlink=True)
        continue
    mw = o.matrix_world.copy()
    o.parent = None
    o.matrix_world = mw
    o.location += offset
    for mod in list(o.modifiers):
        o.modifiers.remove(mod)
    keep_objs.append(o)

bpy.context.view_layer.update()

arm_parts_L = [o for o in keep_objs if any(k in o.name for k in ("arm_", "hand_", "finger_", "thumb_")) and o.name.endswith(".L")]
arm_parts_R = [o for o in keep_objs if any(k in o.name for k in ("arm_", "hand_", "finger_", "thumb_")) and o.name.endswith(".R")]

pivot_L = Vector((0.125, 0.01, 1.18))
pivot_R = Vector((-0.125, 0.01, 1.18))
rot_L = Euler((math.radians(-16), math.radians(-28), math.radians(-15)), 'XYZ').to_matrix().to_4x4()
rot_R = Euler((math.radians(-16), math.radians(28), math.radians(15)), 'XYZ').to_matrix().to_4x4()

for o in arm_parts_L:
    o.matrix_world = Matrix.Translation(pivot_L) @ rot_L @ Matrix.Translation(-pivot_L) @ o.matrix_world
for o in arm_parts_R:
    o.matrix_world = Matrix.Translation(pivot_R) @ rot_R @ Matrix.Translation(-pivot_R) @ o.matrix_world

bpy.context.view_layer.update()

arm_upper_R_obj = None
hand_L_obj = None
hand_R_obj = None

for o in keep_objs:
    if o.name == "GEO-arm_upper_female_primitive_stylized.R":
        arm_upper_R_obj = o
    elif o.name == "GEO-hand_female_primitive_stylized.L":
        hand_L_obj = o
    elif o.name == "GEO-hand_female_primitive_stylized.R":
        hand_R_obj = o

    o.data = o.data.copy()
    bpy.ops.object.select_all(action='DESELECT')
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    neg_scale = (o.scale.x * o.scale.y * o.scale.z) < 0
    bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
    if neg_scale:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bmesh.ops.reverse_faces(bm, faces=bm.faces)
        bm.to_mesh(o.data)
        bm.free()
    # Keep primitive parts within target 6k-9k triangle budget
    dec = o.modifiers.new("Decimate", 'DECIMATE')
    dec.ratio = 0.55
    bpy.ops.object.modifier_apply(modifier="Decimate")
    if "eye_" in o.name.lower():
        link_to_geo(o, mats["eye_dark"])
    else:
        link_to_geo(o, mats["skin"])

# 2. Build Scale Bikini Top
for side, sx in (("L", 0.054), ("R", -0.054)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=12, ring_count=8, radius=0.052, location=(sx, -0.048, 1.108))
    cup = bpy.context.active_object
    cup.name = f"BLK_scale_top_{side}"
    cup.scale = (1.02, 0.85, 1.12)
    bpy.ops.object.transform_apply(scale=True)
    link_to_geo(cup, mats["tail_scales"])

# 3. Build Muscular S-Curved Fish Tail
tail_pts = [
    (0.00,  0.00, 0.91, 0.145, 0.102),
    (0.00, -0.01, 0.77, 0.164, 0.118),
    (0.01,  0.00, 0.60, 0.152, 0.112),
    (0.03,  0.03, 0.42, 0.136, 0.102),
    (0.04,  0.07, 0.24, 0.118, 0.092),
    (0.00,  0.12, 0.09, 0.102, 0.082),
    (-0.10, 0.18, 0.05, 0.090, 0.074),
    (-0.23, 0.24, 0.12, 0.080, 0.066),
    (-0.35, 0.27, 0.27, 0.070, 0.058),
    (-0.45, 0.26, 0.48, 0.060, 0.050),
    (-0.51, 0.22, 0.72, 0.050, 0.042),
    (-0.53, 0.17, 0.98, 0.041, 0.034),
    (-0.50, 0.13, 1.20, 0.033, 0.026),
    (-0.46, 0.10, 1.34, 0.026, 0.019),
]

bm_tail = bmesh.new()
segs = 16
rings = []
for i, (cx, cy, cz, rx, ry) in enumerate(tail_pts):
    p_cur = Vector((cx, cy, cz))
    if i == 0:
        tangent = (Vector(tail_pts[i+1][:3]) - p_cur).normalized()
    elif i == len(tail_pts) - 1:
        tangent = (p_cur - Vector(tail_pts[i-1][:3])).normalized()
    else:
        tangent = (Vector(tail_pts[i+1][:3]) - Vector(tail_pts[i-1][:3])).normalized()
    up_ref = Vector((0, 1, 0))
    side_v = tangent.cross(up_ref).normalized()
    fwd_v = side_v.cross(tangent).normalized()

    ring_verts = []
    for s in range(segs):
        ang = 2.0 * math.pi * s / segs
        z_dip = 0.0
        if i in (0, 1) and math.sin(ang) < 0:
            z_dip = 0.045 * math.sin(ang) * (1.0 if i == 0 else 0.5)
        pos = p_cur + side_v * (math.cos(ang) * rx) + fwd_v * (math.sin(ang) * ry) + Vector((0, 0, z_dip))
        ring_verts.append(bm_tail.verts.new(pos))
    rings.append(ring_verts)

for i in range(len(rings) - 1):
    for s in range(segs):
        v1 = rings[i][s]
        v2 = rings[i][(s + 1) % segs]
        v3 = rings[i + 1][(s + 1) % segs]
        v4 = rings[i + 1][s]
        bm_tail.faces.new((v1, v2, v3, v4))

bm_tail.faces.new(reversed(rings[0]))
bm_tail.faces.new(rings[-1])
bmesh.ops.recalc_face_normals(bm_tail, faces=bm_tail.faces)

tail_mesh = bpy.data.meshes.new("BLK_Tail")
bm_tail.to_mesh(tail_mesh)
bm_tail.free()
tail_obj = bpy.data.objects.new("BLK_Tail", tail_mesh)
link_to_geo(tail_obj, mats["tail_scales"])

# 4. Build Caudal Fin & Hip/Ridge Fins
def create_fin_lobe(name, base_pos, tip_offset, mid_width, thickness=0.010, mat=mats["fin"]):
    bm = bmesh.new()
    steps = 5
    cols = 4
    grid = []
    for r in range(steps + 1):
        t = r / steps
        row = []
        spine = base_pos + tip_offset * t + Vector((0, 0, 0.05 * math.sin(t * math.pi)))
        w = mid_width * math.sin(t * math.pi * 0.85 + 0.15)
        for c in range(cols):
            u = (c / (cols - 1)) - 0.5
            perp = Vector((tip_offset.z, 0.20, -tip_offset.x)).normalized()
            pt = spine + perp * (u * w)
            row.append(bm.verts.new(pt))
        grid.append(row)
    for r in range(steps):
        for c in range(cols - 1):
            bm.faces.new((grid[r][c], grid[r][c+1], grid[r+1][c+1], grid[r+1][c]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    m = bpy.data.meshes.new(name)
    bm.to_mesh(m)
    bm.free()
    obj = bpy.data.objects.new(name, m)
    solid = obj.modifiers.new("Solidify", 'SOLIDIFY')
    solid.thickness = thickness
    solid.offset = 0.0
    link_to_geo(obj, mat)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier="Solidify")
    return obj

fluke_base = Vector((-0.46, 0.10, 1.32))
create_fin_lobe("BLK_CaudalFin_Outer", fluke_base, Vector((-0.26, 0.05, 0.38)), 0.19, 0.010, mats["fin"])
create_fin_lobe("BLK_CaudalFin_Inner", fluke_base, Vector((0.18, -0.03, 0.34)), 0.17, 0.010, mats["fin_tip"])

create_fin_lobe("BLK_HipFin_L", Vector((0.15, 0.01, 0.68)), Vector((0.16, 0.04, -0.26)), 0.14, 0.008, mats["fin"])
create_fin_lobe("BLK_HipFin_R", Vector((-0.15, 0.01, 0.68)), Vector((-0.16, 0.04, -0.26)), 0.14, 0.008, mats["fin"])

create_fin_lobe("BLK_TailRidgeFin_1", Vector((-0.10, 0.18, 0.13)), Vector((-0.08, 0.04, 0.16)), 0.09, 0.007, mats["fin"])
create_fin_lobe("BLK_TailRidgeFin_2", Vector((-0.38, 0.27, 0.36)), Vector((-0.14, 0.04, 0.12)), 0.08, 0.007, mats["fin"])

# 5. Build Indigenous Feather Headdress (Cocar) with full visible headband across forehead
bpy.ops.mesh.primitive_cylinder_add(vertices=20, radius=0.118, depth=0.046, location=(0.0, -0.002, 1.465))
tiara = bpy.context.active_object
tiara.name = "BLK_Cocar_Tiara"
tiara.scale = (0.98, 1.14, 1.0)
tiara.rotation_euler = (math.radians(-12), 0, 0)
bpy.ops.object.transform_apply(rotation=True, scale=True)
link_to_geo(tiara, mats["gold"])

num_feathers = 11
for idx in range(num_feathers):
    norm = (idx - (num_feathers - 1) / 2.0) / ((num_feathers - 1) / 2.0)
    ang = norm * math.radians(68)
    dist_from_center = abs(norm)
    length = 0.35 * (1.0 - 0.36 * dist_from_center)
    width = 0.046 if idx == num_feathers // 2 else 0.036

    bpy.ops.mesh.primitive_grid_add(x_subdivisions=2, y_subdivisions=5, size=1.0)
    f_obj = bpy.context.active_object
    f_obj.name = f"BLK_Feather_{idx:02d}"
    bm = bmesh.new()
    bm.from_mesh(f_obj.data)
    for v in bm.verts:
        ty = v.co.y + 0.5
        taper = math.sin(ty * math.pi * 0.88 + 0.12)
        v.co.x = v.co.x * width * taper
        v.co.z = ty * length
        v.co.y = -0.012 * math.sin(ty * math.pi)
    bm.to_mesh(f_obj.data)
    bm.free()

    solid = f_obj.modifiers.new("Solidify", 'SOLIDIFY')
    solid.thickness = 0.006
    bpy.ops.object.modifier_apply(modifier="Solidify")

    base_x = math.sin(ang) * 0.098
    base_z = 1.475 + math.cos(ang) * 0.035
    f_obj.location = (base_x, 0.015 + abs(norm) * 0.02, base_z)
    f_obj.rotation_euler = (math.radians(-8), ang * 0.85, 0)
    bpy.ops.object.transform_apply(rotation=True, scale=True)

    if dist_from_center < 0.12:
        f_mat = mats["feather_orange"]
    elif dist_from_center < 0.45:
        f_mat = mats["feather_green"]
    elif dist_from_center < 0.78:
        f_mat = mats["feather_teal"]
    else:
        f_mat = mats["feather_navy"]
    link_to_geo(f_obj, f_mat)

# 6. Build Volumetric Long Wavy Hair Blockout (covering crown above tiara + flowing from temples)
bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=10, radius=0.118, location=(0.0, 0.022, 1.448))
hair_cap = bpy.context.active_object
hair_cap.name = "BLK_Hair_Cap"
# Sculpt hair_cap so it covers the top scalp/temples above Z=1.44 while keeping face (Y < -0.03, Z < 1.445) open
bm_hc = bmesh.new()
bm_hc.from_mesh(hair_cap.data)
for v in bm_hc.verts:
    wco = hair_cap.matrix_world @ v.co
    if wco.y < -0.01 and wco.z < 1.445:
        v.co.y += 0.08
    elif wco.z > 1.445:
        v.co.x *= 1.08
        v.co.z += 0.015
bm_hc.to_mesh(hair_cap.data)
bm_hc.free()
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
link_to_geo(hair_cap, mats["hair"])

hair_strands_spec = [
    # (name, side_sign, start_x, start_z, spread_x, y_offset, length_z, wave_amp)
    ("TempleWave_L",  1.0, 0.085, 1.47, 0.25, -0.01, 0.52, 0.045),
    ("TempleWave_R", -1.0, 0.085, 1.47, 0.25, -0.01, 0.52, 0.045),
    ("MidSpread_L",   1.0, 0.095, 1.45, 0.39,  0.03, 0.48, 0.065),
    ("MidSpread_R",  -1.0, 0.095, 1.45, 0.39,  0.03, 0.48, 0.065),
    ("UpperWing_L",   1.0, 0.090, 1.44, 0.45,  0.06, 0.36, 0.055),
    ("UpperWing_R",  -1.0, 0.090, 1.44, 0.45,  0.06, 0.36, 0.055),
    ("BackCascade_L", 1.0, 0.065, 1.43, 0.18,  0.09, 0.56, 0.035),
    ("BackCascade_R",-1.0, 0.065, 1.43, 0.18,  0.09, 0.56, 0.035),
    ("BackCenter",    0.0, 0.000, 1.43, 0.00,  0.11, 0.58, 0.025),
]

for hname, sgn, stx, stz, spx, yoff, lz, wamp in hair_strands_spec:
    bm = bmesh.new()
    h_steps = 8
    h_segs = 6
    h_rings = []
    for st in range(h_steps + 1):
        t = st / h_steps
        px = sgn * (stx + spx * math.pow(t, 0.82)) + sgn * wamp * math.sin(t * math.pi * 2.2)
        py = yoff + 0.025 * math.cos(t * math.pi * 1.5)
        pz = stz - lz * t + 0.025 * math.sin(t * math.pi * 2.0)
        rad_x = 0.055 * (1.0 - 0.65 * t) if sgn != 0 else 0.11 * (1.0 - 0.4 * t)
        rad_y = 0.032 * (1.0 - 0.60 * t)
        ring = []
        for sg in range(h_segs):
            a = 2.0 * math.pi * sg / h_segs
            ring.append(bm.verts.new((px + math.cos(a) * rad_x, py + math.sin(a) * rad_y, pz)))
        h_rings.append(ring)
    for st in range(h_steps):
        for sg in range(h_segs):
            bm.faces.new((h_rings[st][sg], h_rings[st][(sg+1)%h_segs], h_rings[st+1][(sg+1)%h_segs], h_rings[st+1][sg]))
    bm.faces.new(reversed(h_rings[0]))
    bm.faces.new(h_rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    hm = bpy.data.meshes.new(f"BLK_Hair_{hname}")
    bm.to_mesh(hm)
    bm.free()
    ho = bpy.data.objects.new(f"BLK_Hair_{hname}", hm)
    link_to_geo(ho, mats["hair"])

# 7. Necklaces, Earrings, Armlet & Bioluminescent Aura Orbs at Hands
necklace_specs = [
    ("Choker_Cyan",  0.068, -0.022, 1.215, 0.007, 42, 1.0,  mats["beads_cyan"]),
    ("Strand_Green", 0.075, -0.032, 1.165, 0.008, 52, 1.15, mats["feather_green"]),
    ("Strand_Red",   0.082, -0.038, 1.115, 0.008, 58, 1.30, mats["beads_red"]),
    ("Strand_Long",  0.088, -0.042, 1.065, 0.008, 62, 1.45, mats["gold"]),
]
for nname, nrad, ny, nz, r_minor, rot_x, sy, nmat in necklace_specs:
    bpy.ops.mesh.primitive_torus_add(major_segments=16, minor_segments=6, major_radius=nrad, minor_radius=r_minor, location=(0.0, ny, nz))
    nobj = bpy.context.active_object
    nobj.name = f"BLK_Necklace_{nname}"
    nobj.rotation_euler = (math.radians(rot_x), 0, 0)
    nobj.scale = (0.92, sy, 1.0)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    link_to_geo(nobj, nmat)

for side, ex in (("L", 0.102), ("R", -0.102)):
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.015, radius2=0.002, depth=0.052, location=(ex, 0.00, 1.335))
    ear_o = bpy.context.active_object
    ear_o.name = f"BLK_Earring_{side}"
    ear_o.scale = (0.38, 1.0, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    link_to_geo(ear_o, mats["gold"])

# Right upper-arm golden armlet centered directly on arm_upper.R bbox
arm_r_pos = bbox_center(arm_upper_R_obj) if arm_upper_R_obj else Vector((-0.21, -0.02, 1.12))
bpy.ops.mesh.primitive_torus_add(major_segments=16, minor_segments=6, major_radius=0.045, minor_radius=0.008, location=arm_r_pos)
armlet = bpy.context.active_object
armlet.name = "BLK_Armlet_R"
armlet.rotation_euler = (math.radians(-16), math.radians(28), math.radians(15))
bpy.ops.object.transform_apply(rotation=True, scale=True)
link_to_geo(armlet, mats["gold"])

# Subtle cyan water-magic wisps centered directly on hands/wrists
for side, h_obj in (("L", hand_L_obj), ("R", hand_R_obj)):
    h_pos = bbox_center(h_obj) if h_obj else Vector((0.36 if side == "L" else -0.36, -0.08, 0.90))
    bpy.ops.mesh.primitive_torus_add(major_segments=14, minor_segments=6, major_radius=0.052, minor_radius=0.006, location=h_pos)
    wisp = bpy.context.active_object
    wisp.name = f"BLK_WaterAura_{side}"
    wisp.rotation_euler = (math.radians(-16), math.radians(-28 if side == "L" else 28), 0)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    link_to_geo(wisp, mats["beads_cyan"])

# Lights & Cameras in REFS
def add_light(name, ltype, energy, loc, rot_deg, color=(1.0, 1.0, 1.0)):
    ldata = bpy.data.lights.new(name=name, type=ltype)
    ldata.energy = energy
    ldata.color = color
    lobj = bpy.data.objects.new(name=name, object_data=ldata)
    lobj.location = loc
    lobj.rotation_euler = tuple(math.radians(a) for a in rot_deg)
    col_refs.objects.link(lobj)
    return lobj

add_light("Key_Light", 'SUN', 3.2, (2.0, -2.5, 3.0), (48, 15, 32), (1.0, 0.98, 0.95))
add_light("Fill_Light", 'SUN', 1.4, (-2.5, -1.8, 2.0), (55, -20, -40), (0.85, 0.93, 1.0))
add_light("Rim_Light", 'SUN', 2.0, (0.0, 2.5, 2.5), (-45, 0, 180), (0.75, 0.98, 0.95))

world = bpy.data.worlds.new("ValidationWorld")
scene.world = world
world.use_nodes = True
bg = world.node_tree.nodes.get("Background")
if bg:
    bg.inputs[0].default_value = (0.055, 0.075, 0.085, 1.0)
    bg.inputs[1].default_value = 1.0

# Count triangles in GEO
depsgraph = bpy.context.evaluated_depsgraph_get()
total_tris = 0
total_objs = 0
for o in col_geo.objects:
    if o.type == 'MESH':
        total_objs += 1
        eval_obj = o.evaluated_get(depsgraph)
        m = eval_obj.to_mesh()
        m.calc_loop_triangles()
        total_tris += len(m.loop_triangles)
        eval_obj.to_mesh_clear()

print(f"BLOCKOUT STATS: objects={total_objs}, evaluated_triangles={total_tris}")

cam_data = bpy.data.cameras.new("ValidationCam")
cam_data.lens = 50
cam_obj = bpy.data.objects.new("ValidationCam", cam_data)
col_refs.objects.link(cam_obj)
scene.camera = cam_obj

bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
print(f"Saved blockout to: {OUT_BLEND}")

scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items.keys() else 'BLENDER_EEVEE'
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.image_settings.file_format = 'PNG'

target = Vector((-0.06, 0.04, 0.90))
views = {
    "blockout_front": (Vector((-0.06, -3.15, 0.94)), target),
    "blockout_side": (Vector((-3.25, 0.04, 0.94)), target),
    "blockout_three_quarter": (Vector((-1.95, -2.55, 1.08)), target),
}

for vname, (cpos, ctgt) in views.items():
    cam_obj.location = cpos
    direction = (ctgt - cpos).normalized()
    cam_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    out_png = os.path.join(RENDER_DIR, f"{vname}.png")
    scene.render.filepath = out_png
    bpy.ops.render.render(write_still=True)
    print(f"Rendered: {out_png}")

# Build side-by-side comparison sheet (Concept | Front | 3/4 | Side) using Blender VSE
bpy.ops.wm.read_factory_settings(use_empty=True)
comp_scene = bpy.context.scene
comp_scene.render.resolution_x = 2400
comp_scene.render.resolution_y = 600
comp_scene.render.image_settings.file_format = 'PNG'
if not comp_scene.sequence_editor:
    comp_scene.sequence_editor_create()
seq = comp_scene.sequence_editor

panels = [
    ("Concept", CONCEPT_PATH),
    ("Front", os.path.join(RENDER_DIR, "blockout_front.png")),
    ("ThreeQuarter", os.path.join(RENDER_DIR, "blockout_three_quarter.png")),
    ("Side", os.path.join(RENDER_DIR, "blockout_side.png")),
]
for idx, (pname, ppath) in enumerate(panels):
    st = seq.strips.new_image(name=pname, filepath=ppath, channel=idx+1, frame_start=1)
    st.blend_type = 'ALPHA_OVER'
    orig_img = bpy.data.images.load(ppath)
    iw, ih = orig_img.size
    scale_factor = 600.0 / max(iw, ih)
    st.transform.scale_x = scale_factor
    st.transform.scale_y = scale_factor
    st.transform.offset_x = -900 + idx * 600

comp_out = os.path.join(RENDER_DIR, "blockout_comparison.png")
comp_scene.frame_set(1)
comp_scene.render.filepath = comp_out
bpy.ops.render.render(write_still=True)
print(f"Rendered comparison sheet: {comp_out}")
