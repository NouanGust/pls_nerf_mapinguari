import bpy
import bmesh
import math
import os
from mathutils import Vector, Matrix, Euler

# Paths for current environment
ROOT_DIR = r"C:\Users\Professor\Documents\Nohan\mapinguari\pls_nerf_mapinguari"
BUNDLE_PATH = os.path.join(ROOT_DIR, "docs", "human-base-mesh-bundle", "human_base_meshes_bundle.blend")
CONCEPT_PATH = os.path.join(ROOT_DIR, "art", "concepts", "mae_dagua", "mae_dagua_concept.png")
OUT_BLEND = os.path.join(ROOT_DIR, "models", "mae_dagua", "mae_dagua_blockout.blend")
RENDER_DIR = os.path.join(ROOT_DIR, "models", "mae_dagua", "renders")
os.makedirs(RENDER_DIR, exist_ok=True)

# Reset scene to clean state
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.unit_settings.system = 'METRIC'
scene.unit_settings.scale_length = 1.0
scene["unit_name"] = "MaeDagua"

# Collections per standard: GEO, RIG, ANIM, REFS
col_geo = bpy.data.collections.new("GEO")
col_rig = bpy.data.collections.new("RIG")
col_anim = bpy.data.collections.new("ANIM")
col_refs = bpy.data.collections.new("REFS")
for c in (col_geo, col_rig, col_anim, col_refs):
    scene.collection.children.link(c)

def make_mat(name, hex_color, roughness=0.50, metallic=0.0, emission_strength=0.0):
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
    "skin": make_mat("Mat_Skin", "#9C5A38", roughness=0.48),
    "hair": make_mat("Mat_Hair", "#151216", roughness=0.60),
    "tail_scales": make_mat("Mat_TailScales", "#185B64", roughness=0.35),
    "tail_accent": make_mat("Mat_TailAccent", "#21888F", roughness=0.32),
    "fin": make_mat("Mat_Fin", "#E09F3E", roughness=0.38),
    "fin_tip": make_mat("Mat_FinTip", "#1F7A8C", roughness=0.38),
    "gold": make_mat("Mat_Gold", "#D8A243", roughness=0.32, metallic=0.82),
    "feather_orange": make_mat("Mat_FeatherOrange", "#E87A24", roughness=0.55),
    "feather_green": make_mat("Mat_FeatherGreen", "#3A9D42", roughness=0.55),
    "feather_teal": make_mat("Mat_FeatherTeal", "#1F7A8C", roughness=0.55),
    "feather_navy": make_mat("Mat_FeatherNavy", "#16324F", roughness=0.55),
    "beads_red": make_mat("Mat_BeadsRed", "#C83E31", roughness=0.45),
    "beads_cyan": make_mat("Mat_BeadsCyan", "#43F0D3", roughness=0.30, emission_strength=0.7),
    "eye_iris": make_mat("Mat_EyeIris", "#231812", roughness=0.15),
    "eye_sclera": make_mat("Mat_EyeSclera", "#EDE5DC", roughness=0.20),
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

# Unparent eyes temporarily to avoid transform stacking, center X at 0
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
    link_to_geo(eye, mats["eye_iris"])

# Create clean Scalp Hair Cap directly from the head topology before deleting/decimating
bm_orig = bmesh.new()
bm_orig.from_mesh(body.data)
scalp_faces = [f for f in bm_orig.faces if f.calc_center_median().z > 1.51 or (f.calc_center_median().z > 1.45 and f.calc_center_median().y > -0.04)]
bm_scalp = bmesh.new()
vert_map = {}
for f in scalp_faces:
    for v in f.verts:
        if v not in vert_map:
            # Offset slightly outward along normal
            n_off = v.normal * 0.008
            vert_map[v] = bm_scalp.verts.new(v.co + n_off)
    bm_scalp.faces.new([vert_map[v] for v in f.verts])

scalp_mesh = bpy.data.meshes.new("GEO_Hair_Cap")
bm_scalp.to_mesh(scalp_mesh)
bm_scalp.free()
scalp_obj = bpy.data.objects.new("GEO_Hair_Cap", scalp_mesh)
link_to_geo(scalp_obj, mats["hair"])
solid_scalp = scalp_obj.modifiers.new("Solidify", 'SOLIDIFY')
solid_scalp.thickness = 0.010
solid_scalp.offset = 1.0
bpy.context.view_layer.objects.active = scalp_obj
bpy.ops.object.modifier_apply(modifier="Solidify")

# Remove legs below waist (Z < 0.88m)
to_del = [v for v in bm_orig.verts if v.co.z < 0.875]
bmesh.ops.delete(bm_orig, geom=to_del, context='VERTS')
bm_orig.to_mesh(body.data)
bm_orig.free()
body.data.update()

# Apply Decimate modifier (0.52 ratio)
dec = body.modifiers.new("Decimate", 'DECIMATE')
dec.ratio = 0.52
bpy.context.view_layer.objects.active = body
bpy.ops.object.modifier_apply(modifier="Decimate")

link_to_geo(body, mats["skin"])
print("Upper body prepared. Verts:", len(body.data.vertices), "Polys:", len(body.data.polygons))

# Re-parent eyes to body
for eye in eyes:
    eye.parent = body
    eye.matrix_parent_inverse = body.matrix_world.inverted()

print("=== 2. Building S-Curved Muscular Fish Tail ===")
# Tail center in Y is aligned with waist center (Y ≈ -0.020)
tail_pts = [
    ( 0.00, -0.020, 0.880, 0.148, 0.106),
    ( 0.00, -0.030, 0.760, 0.162, 0.118),
    ( 0.01, -0.020, 0.610, 0.155, 0.114),
    ( 0.02,  0.010, 0.440, 0.140, 0.105),
    ( 0.03,  0.050, 0.260, 0.122, 0.095),
    ( 0.00,  0.100, 0.100, 0.105, 0.085),
    (-0.09,  0.160, 0.040, 0.092, 0.075),
    (-0.21,  0.210, 0.100, 0.082, 0.068),
    (-0.33,  0.240, 0.240, 0.072, 0.060),
    (-0.43,  0.240, 0.450, 0.062, 0.052),
    (-0.49,  0.200, 0.700, 0.052, 0.044),
    (-0.52,  0.150, 0.960, 0.042, 0.036),
    (-0.50,  0.100, 1.200, 0.034, 0.028),
    (-0.46,  0.060, 1.350, 0.026, 0.020),
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
            z_dip = 0.035 * math.sin(ang) * (1.0 if i == 0 else 0.5)
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

# Close caps
bm_tail.faces.new(reversed(rings[0]))
bm_tail.faces.new(rings[-1])
bmesh.ops.recalc_face_normals(bm_tail, faces=bm_tail.faces)

tail_mesh = bpy.data.meshes.new("GEO_Tail")
bm_tail.to_mesh(tail_mesh)
bm_tail.free()
tail_obj = bpy.data.objects.new("GEO_Tail", tail_mesh)
link_to_geo(tail_obj, mats["tail_scales"])

# Scale waist transition sash hugging the belly curve at Z=0.880
bpy.ops.mesh.primitive_torus_add(major_segments=22, minor_segments=8, major_radius=0.134, minor_radius=0.015, location=(0.0, -0.018, 0.880))
waist_sash = bpy.context.active_object
waist_sash.name = "GEO_WaistSash"
waist_sash.scale = (1.08, 0.88, 1.0)
waist_sash.rotation_euler = (math.radians(-6), 0, 0)
bpy.ops.object.transform_apply(rotation=True, scale=True)
link_to_geo(waist_sash, mats["gold"])

print("=== 3. Building Caudal & Lateral Fins ===")
def create_curved_fin(name, base_pos, tip_offset, width, num_ribs=5, thickness=0.008, mat=mats["fin"]):
    bm = bmesh.new()
    steps = 6
    cols = num_ribs
    grid = []
    for r in range(steps + 1):
        t = r / steps
        row = []
        spine = base_pos + tip_offset * t + Vector((0, 0.03 * math.sin(t * math.pi), 0.04 * math.sin(t * math.pi)))
        w = width * math.sin(t * math.pi * 0.85 + 0.15)
        for c in range(cols):
            u = (c / (cols - 1)) - 0.5
            perp = Vector((tip_offset.z, 0.15, -tip_offset.x)).normalized()
            ripple = 0.005 * math.sin(u * math.pi * 6.0)
            pt = spine + perp * (u * w) + Vector((0, ripple, 0))
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

fluke_base = Vector((-0.46, 0.06, 1.34))
create_curved_fin("GEO_CaudalFin_Outer", fluke_base, Vector((-0.28, 0.05, 0.36)), 0.22, 6, 0.010, mats["fin"])
create_curved_fin("GEO_CaudalFin_Inner", fluke_base, Vector((0.16, -0.02, 0.32)), 0.20, 6, 0.010, mats["fin_tip"])

# Hip / Pelvic Fins
create_curved_fin("GEO_HipFin_L", Vector((0.15, -0.01, 0.70)), Vector((0.16, 0.03, -0.25)), 0.15, 4, 0.008, mats["fin"])
create_curved_fin("GEO_HipFin_R", Vector((-0.15, -0.01, 0.70)), Vector((-0.16, 0.03, -0.25)), 0.15, 4, 0.008, mats["fin"])

# Lower curve dorsal ridge fins
create_curved_fin("GEO_TailRidgeFin_1", Vector((-0.09, 0.16, 0.12)), Vector((-0.08, 0.04, 0.16)), 0.10, 4, 0.007, mats["fin"])
create_curved_fin("GEO_TailRidgeFin_2", Vector((-0.35, 0.24, 0.34)), Vector((-0.12, 0.03, 0.14)), 0.09, 4, 0.007, mats["fin"])

print("=== 4. Building Headdress (Cocar) & Tiara right across Forehead ===")
# Headband / Tiara encircling forehead: Center at Y = -0.026, Z = 1.520 (above brows, across hairline)
bpy.ops.mesh.primitive_cylinder_add(vertices=24, radius=0.116, depth=0.032, location=(0.0, -0.026, 1.525))
tiara = bpy.context.active_object
tiara.name = "GEO_Tiara"
tiara.scale = (0.95, 1.10, 1.0)
tiara.rotation_euler = (math.radians(-9), 0, 0)
bpy.ops.object.transform_apply(rotation=True, scale=True)
link_to_geo(tiara, mats["gold"])

# 11 radiating fan feathers rising from the tiara rim
num_feathers = 11
for idx in range(num_feathers):
    norm = (idx - (num_feathers - 1) / 2.0) / ((num_feathers - 1) / 2.0)
    ang = norm * math.radians(66)
    dist_from_center = abs(norm)
    length = 0.36 * (1.0 - 0.35 * dist_from_center)
    width = 0.046 if idx == num_feathers // 2 else 0.036

    bpy.ops.mesh.primitive_grid_add(x_subdivisions=2, y_subdivisions=5, size=1.0)
    f_obj = bpy.context.active_object
    f_obj.name = f"GEO_Feather_{idx:02d}"
    bm = bmesh.new()
    bm.from_mesh(f_obj.data)
    for v in bm.verts:
        ty = v.co.y + 0.5
        taper = math.sin(ty * math.pi * 0.88 + 0.12)
        v.co.x = v.co.x * width * taper
        v.co.z = ty * length
        v.co.y = -0.014 * math.sin(ty * math.pi)
    bm.to_mesh(f_obj.data)
    bm.free()

    solid = f_obj.modifiers.new("Solidify", 'SOLIDIFY')
    solid.thickness = 0.006
    bpy.ops.object.modifier_apply(modifier="Solidify")

    base_x = math.sin(ang) * 0.102
    base_y = -0.050 + abs(norm) * 0.040
    base_z = 1.535 + math.cos(ang) * 0.030
    f_obj.location = (base_x, base_y, base_z)
    f_obj.rotation_euler = (math.radians(-8), ang * 0.82, 0)
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

print("=== 5. Building Voluminous Wavy Hair framing the Face ===")
# Fluid wavy hair locks modeled as ribbon clusters framing the face and shoulders
hair_locks_spec = [
    # (name, side_sign, start_x, start_z, spread_x, y_off, length_z, wave_amp)
    ("FrontWave_L",   1.0, 0.105, 1.51, 0.14, -0.075, 0.46, 0.035),
    ("FrontWave_R",  -1.0, 0.105, 1.51, 0.14, -0.075, 0.46, 0.035),
    ("TempleWave_L",  1.0, 0.110, 1.49, 0.26, -0.025, 0.54, 0.055),
    ("TempleWave_R", -1.0, 0.110, 1.49, 0.26, -0.025, 0.54, 0.055),
    ("SideVolume_L",  1.0, 0.102, 1.47, 0.38,  0.025, 0.50, 0.065),
    ("SideVolume_R", -1.0, 0.102, 1.47, 0.38,  0.025, 0.50, 0.065),
    ("BackCascade_L", 1.0, 0.065, 1.46, 0.16,  0.085, 0.60, 0.035),
    ("BackCascade_R",-1.0, 0.065, 1.46, 0.16,  0.085, 0.60, 0.035),
    ("BackCenter",    0.0, 0.000, 1.46, 0.00,  0.100, 0.62, 0.025),
]

for hname, sgn, stx, stz, spx, yoff, lz, wamp in hair_locks_spec:
    bm = bmesh.new()
    h_steps = 9
    h_segs = 6
    h_rings = []
    for st in range(h_steps + 1):
        t = st / h_steps
        px = sgn * (stx + spx * math.pow(t, 0.85)) + sgn * wamp * math.sin(t * math.pi * 2.2)
        py = yoff + 0.028 * math.cos(t * math.pi * 1.6)
        pz = stz - lz * t + 0.020 * math.sin(t * math.pi * 2.0)
        rad_x = 0.048 * (1.0 - 0.60 * t) if sgn != 0 else 0.095 * (1.0 - 0.45 * t)
        rad_y = 0.028 * (1.0 - 0.55 * t)
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
    hm = bpy.data.meshes.new(f"GEO_Hair_{hname}")
    bm.to_mesh(hm)
    bm.free()
    ho = bpy.data.objects.new(f"GEO_Hair_{hname}", hm)
    link_to_geo(ho, mats["hair"])

print("=== 6. Building Bikini Top & Amazonian Adornments ===")
# Scale Bikini Top fitted on chest surface (Y ≈ -0.115, Z ≈ 1.155)
for side, sx in (("L", 0.056), ("R", -0.056)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=14, ring_count=10, radius=0.055, location=(sx, -0.112, 1.155))
    cup = bpy.context.active_object
    cup.name = f"GEO_ScaleTop_{side}"
    cup.scale = (1.06, 0.78, 1.12)
    bpy.ops.object.transform_apply(scale=True)
    link_to_geo(cup, mats["tail_scales"])

# Layered indigenous bead necklaces resting on collarbones/upper chest (Neck Y ≈ -0.080, Chest Y ≈ -0.120)
necklace_specs = [
    ("Choker_Cyan",  0.064, -0.040, 1.250, 0.006, 32, 1.05, mats["beads_cyan"]),
    ("Strand_Green", 0.074, -0.055, 1.210, 0.007, 42, 1.15, mats["feather_green"]),
    ("Strand_Red",   0.082, -0.068, 1.170, 0.007, 50, 1.25, mats["beads_red"]),
    ("Strand_Gold",  0.090, -0.080, 1.125, 0.008, 56, 1.35, mats["gold"]),
]
for nname, nrad, ny, nz, r_minor, rot_x, sy, nmat in necklace_specs:
    bpy.ops.mesh.primitive_torus_add(major_segments=20, minor_segments=6, major_radius=nrad, minor_radius=r_minor, location=(0.0, ny, nz))
    nobj = bpy.context.active_object
    nobj.name = f"GEO_Necklace_{nname}"
    nobj.rotation_euler = (math.radians(rot_x), 0, 0)
    nobj.scale = (0.92, sy, 1.0)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    link_to_geo(nobj, nmat)

# Golden leaf/feather earrings
for side, ex in (("L", 0.096), ("R", -0.096)):
    bpy.ops.mesh.primitive_cone_add(vertices=8, radius1=0.014, radius2=0.002, depth=0.048, location=(ex, -0.020, 1.355))
    ear_o = bpy.context.active_object
    ear_o.name = f"GEO_Earring_{side}"
    ear_o.scale = (0.35, 1.0, 1.0)
    bpy.ops.object.transform_apply(scale=True)
    link_to_geo(ear_o, mats["gold"])

# Triple golden armlet on right bicep
bpy.ops.mesh.primitive_torus_add(major_segments=16, minor_segments=6, major_radius=0.042, minor_radius=0.008, location=(-0.210, -0.015, 1.160))
armlet = bpy.context.active_object
armlet.name = "GEO_Armlet_R"
armlet.rotation_euler = (math.radians(-16), math.radians(28), math.radians(15))
bpy.ops.object.transform_apply(rotation=True, scale=True)
link_to_geo(armlet, mats["gold"])

# Glowing cyan water-magic wisps at wrists
for side, wx in (("L", 0.320), ("R", -0.320)):
    bpy.ops.mesh.primitive_torus_add(major_segments=14, minor_segments=6, major_radius=0.046, minor_radius=0.006, location=(wx, -0.065, 0.940))
    wisp = bpy.context.active_object
    wisp.name = f"GEO_WaterAura_{side}"
    wisp.rotation_euler = (math.radians(-14), math.radians(-26 if side == "L" else 26), 0)
    bpy.ops.object.transform_apply(rotation=True, scale=True)
    link_to_geo(wisp, mats["beads_cyan"])

print("=== 7. Lighting and Cameras ===")
def add_light(name, ltype, energy, loc, rot_deg, color=(1.0, 1.0, 1.0)):
    ldata = bpy.data.lights.new(name=name, type=ltype)
    ldata.energy = energy
    ldata.color = color
    lobj = bpy.data.objects.new(name=name, object_data=ldata)
    lobj.location = loc
    lobj.rotation_euler = tuple(math.radians(a) for a in rot_deg)
    col_refs.objects.link(lobj)
    return lobj

add_light("Key_Light",  'SUN', 3.4, (2.0, -2.8, 3.2), (48, 15, 32), (1.0, 0.98, 0.95))
add_light("Fill_Light", 'SUN', 1.6, (-2.5, -2.0, 2.2), (55, -20, -40), (0.85, 0.93, 1.0))
add_light("Rim_Light",  'SUN', 2.2, (0.0, 2.6, 2.6), (-45, 0, 180), (0.75, 0.98, 0.95))

world = bpy.data.worlds.new("ValidationWorld")
scene.world = world
bg = world.node_tree.nodes.get("Background")
if bg:
    bg.inputs[0].default_value = (0.055, 0.075, 0.085, 1.0)
    bg.inputs[1].default_value = 1.0

# Count evaluated triangles in GEO
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

print(f"=== MODEL STATS === Objects in GEO: {total_objs}, Evaluated Triangles: {total_tris}")

cam_data = bpy.data.cameras.new("ValidationCam")
cam_data.lens = 50
cam_obj = bpy.data.objects.new("ValidationCam", cam_data)
col_refs.objects.link(cam_obj)
scene.camera = cam_obj

# Save main blendfile
bpy.ops.wm.save_as_mainfile(filepath=OUT_BLEND)
print(f"Saved refined model to: {OUT_BLEND}")

# Render orthographic / key views
scene.render.engine = 'BLENDER_EEVEE_NEXT' if 'BLENDER_EEVEE_NEXT' in bpy.types.RenderSettings.bl_rna.properties['engine'].enum_items.keys() else 'BLENDER_EEVEE'
scene.render.resolution_x = 900
scene.render.resolution_y = 900
scene.render.image_settings.file_format = 'PNG'

target = Vector((-0.06, 0.00, 0.92))
views = {
    "blockout_front": (Vector((-0.06, -3.15, 0.94)), target),
    "blockout_side": (Vector((-3.25, 0.00, 0.94)), target),
    "blockout_three_quarter": (Vector((-1.95, -2.55, 1.10)), target),
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
