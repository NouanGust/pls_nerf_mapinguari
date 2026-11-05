"""
build_pantanal.py
=================
Agente Blender — Arena de Autochess no Pantanal
Construção automatizada de cena 3D pantaneira estilizada de horror ambiental
ao entardecer em Blender 5.2+ (bpy) com renderização Cycles.

Atende rigorosamente a Pantanal.md:
- Coleção principal: PANTANAL_ENV (00_CONTROLS a 11_CAMERAS)
- Grade de 8x8 hexágonos (R = 0,65 m, ponta para cima) planos com sulcos nítidos de terra batida
- Reserva frontal de 9 posições retangulares 100% visíveis integradas ao terreno
- Canais de água assimétricos de vazante e margens baixas de capim denso
- Grande árvore pantaneira à direita debruçada sobre o rio e capão ao fundo
- Cerca rural deteriorada de mourões de aroeira e canoa tradicional abandonada à esquerda
- Céu físico de entardecer pantaneiro (horizonte âmbar/cobre, meio lilás e topo índigo)
- Iluminação em 4 camadas com reflexos quentes fragmentados na água e preenchimento legível
- 3 anomalias sutis de horror ambiental (ramo misterioso no reflexo, esteira sob a água na canoa, capim amassado)
"""

import bpy
import bmesh
import math
import os
import random
from mathutils import Vector, Euler, Matrix

# ==============================================================================
# 1. CONFIGURAÇÃO CENTRALIZADA
# ==============================================================================
CONFIG = {
    "scene_name": "Pantanal_Autochess",
    "unit_system": "METRIC",
    "vertical_axis": "Z",
    "front_direction": "-Y",
    "back_direction": "+Y",
    "hex_columns": 8,
    "hex_rows": 8,
    "hex_radius": 0.65,           # 0,65 m (ponta para cima)
    "groove_width": 0.026,        # Sulcos rasos entre 0,015 e 0,03 m
    "groove_depth": 0.012,        # Profundidade visual entre 0,005 e 0,015 m
    "reserve_slots": 9,
    "reserve_gap": 0.85,          # Distância entre campo e reserva frontal
    "reserve_slot_width": 0.78,
    "reserve_slot_depth": 0.72,
    "exclusion_margin": 0.52,     # Margem de segurança >= 0,5 m
    "random_seed": 42,
    "water_level": -0.16,         # Nível comum das águas dos canais
    "ground_level": 0.08,         # Nível do terraço de terra firme do tabuleiro
    "preview_resolution": (960, 540),
    "final_resolution": (1920, 1080),
    "preview_samples": 40,
    "final_samples": 128,
    "output_dir": os.path.abspath(os.path.dirname(__file__))
        if "__file__" in globals() else os.path.abspath("output/pantanal_autochess"),
}

SUBCOLLECTION_NAMES = [
    "00_CONTROLS",
    "01_TERRAIN",
    "02_BOARD",
    "03_RESERVE",
    "04_WATER",
    "05_BANK_VEGETATION",
    "06_AQUATIC_PLANTS",
    "07_TREES",
    "08_FENCE_AND_CANOE",
    "09_HORROR_DETAILS",
    "10_LIGHTS",
    "11_CAMERAS",
]


# ==============================================================================
# 2. HIERARQUIA DE COLEÇÕES
# ==============================================================================
def setup_scene_and_collections():
    scene = bpy.context.scene
    scene.name = CONFIG["scene_name"]
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1.0

    for obj in scene.objects:
        if not any(col.name.startswith("PANTANAL_ENV") or col.name in SUBCOLLECTION_NAMES for col in obj.users_collection):
            obj.hide_render = True
            obj.hide_viewport = True

    existing_main = bpy.data.collections.get("PANTANAL_ENV")
    if existing_main:
        objs_to_remove = set()
        def _collect(col):
            for o in col.objects:
                objs_to_remove.add(o)
            for ch in col.children:
                _collect(ch)
        _collect(existing_main)
        for o in objs_to_remove:
            bpy.data.objects.remove(o, do_unlink=True)
        for sub_name in SUBCOLLECTION_NAMES:
            sc = bpy.data.collections.get(sub_name)
            if sc:
                bpy.data.collections.remove(sc)
        bpy.data.collections.remove(existing_main)

    main_col = bpy.data.collections.new("PANTANAL_ENV")
    scene.collection.children.link(main_col)

    sub_cols = {}
    for sub_name in SUBCOLLECTION_NAMES:
        sc = bpy.data.collections.new(sub_name)
        main_col.children.link(sc)
        sub_cols[sub_name] = sc

    return scene, main_col, sub_cols


def link_obj(obj, target_col):
    for col in list(obj.users_collection):
        col.objects.unlink(obj)
    target_col.objects.link(obj)


# ==============================================================================
# 3. MATERIAIS PBR PROCEDURAIS DE ALTA FIDELIDADE
# ==============================================================================
def create_pantanal_materials():
    mats = {}

    def _new_mat(name):
        mat = bpy.data.materials.new(name)
        mat.use_nodes = True
        nodes = mat.node_tree.nodes
        links = mat.node_tree.links
        nodes.clear()
        node_out = nodes.new("ShaderNodeOutputMaterial")
        node_out.location = (500, 0)
        node_bsdf = nodes.new("ShaderNodeBsdfPrincipled")
        node_bsdf.location = (150, 0)
        links.new(node_bsdf.outputs["BSDF"], node_out.inputs["Surface"])
        return mat, nodes, links, node_bsdf

    # 1. Barro de Vazante Pantaneira (Rico em ruído de húmus, argila e granulação)
    mat_terrain, tn, tl, t_bsdf = _new_mat("Mat_Pantanal_Terrain")
    t_bsdf.inputs["Roughness"].default_value = 0.90
    if "Specular IOR Level" in t_bsdf.inputs:
        t_bsdf.inputs["Specular IOR Level"].default_value = 0.12

    tc_t = tn.new("ShaderNodeTexCoord")
    noise_macro = tn.new("ShaderNodeTexNoise")
    noise_macro.inputs["Scale"].default_value = 2.2
    noise_macro.inputs["Detail"].default_value = 6.0
    noise_macro.inputs["Roughness"].default_value = 0.70
    tl.new(tc_t.outputs["Object"], noise_macro.inputs["Vector"])

    noise_micro = tn.new("ShaderNodeTexNoise")
    noise_micro.inputs["Scale"].default_value = 9.0
    noise_micro.inputs["Detail"].default_value = 5.0
    noise_micro.inputs["Roughness"].default_value = 0.65
    tl.new(tc_t.outputs["Object"], noise_micro.inputs["Vector"])

    mix_soil = tn.new("ShaderNodeMath")
    mix_soil.operation = 'MULTIPLY'
    tl.new(noise_macro.outputs["Fac"], mix_soil.inputs[0])
    tl.new(noise_micro.outputs["Fac"], mix_soil.inputs[1])

    ramp_soil = tn.new("ShaderNodeValToRGB")
    ramp_soil.color_ramp.elements[0].position = 0.18
    ramp_soil.color_ramp.elements[0].color = (0.09, 0.065, 0.045, 1.0)   # Barro escuro de vazante
    e_s1 = ramp_soil.color_ramp.elements.new(0.48)
    e_s1.color = (0.19, 0.14, 0.095, 1.0)                                # Barro argiloso ocre
    e_s2 = ramp_soil.color_ramp.elements.new(0.75)
    e_s2.color = (0.14, 0.16, 0.08, 1.0)                                 # Limo/musgo de margem
    ramp_soil.color_ramp.elements[3].position = 0.92
    ramp_soil.color_ramp.elements[3].color = (0.24, 0.18, 0.12, 1.0)     # Terra seca mais clara
    tl.new(mix_soil.outputs["Value"], ramp_soil.inputs["Fac"])
    tl.new(ramp_soil.outputs["Color"], t_bsdf.inputs["Base Color"])

    bump_soil = tn.new("ShaderNodeBump")
    bump_soil.inputs["Strength"].default_value = 0.28
    bump_soil.inputs["Distance"].default_value = 0.02
    tl.new(noise_micro.outputs["Fac"], bump_soil.inputs["Height"])
    tl.new(bump_soil.outputs["Normal"], t_bsdf.inputs["Normal"])
    mats["terrain"] = mat_terrain

    # 2. Hexágonos do Tabuleiro — Lado Aliado (mais quente/ocre) e Inimigo (mais escuro e úmido)
    def _create_hex_mat(name, col_a, col_b):
        mat, hn, hl, h_bsdf = _new_mat(name)
        h_bsdf.inputs["Roughness"].default_value = 0.86
        if "Specular IOR Level" in h_bsdf.inputs:
            h_bsdf.inputs["Specular IOR Level"].default_value = 0.14
        tc_h = hn.new("ShaderNodeTexCoord")
        noise_h = hn.new("ShaderNodeTexNoise")
        noise_h.inputs["Scale"].default_value = 4.8
        noise_h.inputs["Detail"].default_value = 6.0
        hl.new(tc_h.outputs["Object"], noise_h.inputs["Vector"])

        ramp_h = hn.new("ShaderNodeValToRGB")
        ramp_h.color_ramp.elements[0].position = 0.25
        ramp_h.color_ramp.elements[0].color = col_a
        ramp_h.color_ramp.elements[1].position = 0.78
        ramp_h.color_ramp.elements[1].color = col_b
        hl.new(noise_h.outputs["Fac"], ramp_h.inputs["Fac"])
        hl.new(ramp_h.outputs["Color"], h_bsdf.inputs["Base Color"])

        bump_h = hn.new("ShaderNodeBump")
        bump_h.inputs["Strength"].default_value = 0.18
        bump_h.inputs["Distance"].default_value = 0.015
        hl.new(noise_h.outputs["Fac"], bump_h.inputs["Height"])
        hl.new(bump_h.outputs["Normal"], h_bsdf.inputs["Normal"])
        return mat

    mats["hex_player"] = _create_hex_mat("Mat_Hex_Player", (0.28, 0.20, 0.14, 1.0), (0.36, 0.27, 0.18, 1.0))
    mats["hex_enemy"] = _create_hex_mat("Mat_Hex_Enemy", (0.18, 0.13, 0.09, 1.0), (0.25, 0.18, 0.12, 1.0))
    mats["reserve"] = _create_hex_mat("Mat_Reserve_Slot", (0.27, 0.19, 0.13, 1.0), (0.34, 0.25, 0.17, 1.0))

    # Sulcos escuros das divisórias
    mat_groove, _, _, g_bsdf = _new_mat("Mat_Board_Groove")
    g_bsdf.inputs["Base Color"].default_value = (0.045, 0.032, 0.022, 1.0)
    g_bsdf.inputs["Roughness"].default_value = 0.95
    mats["groove"] = mat_groove

    # 3. Água Pantaneira (Água escura límpida de vazante, alta refletividade e ondulação de correnteza)
    mat_water, wn, wl, w_bsdf = _new_mat("Mat_Pantanal_Water")
    w_bsdf.inputs["Base Color"].default_value = (0.015, 0.038, 0.035, 1.0)
    w_bsdf.inputs["Roughness"].default_value = 0.045
    if "Specular IOR Level" in w_bsdf.inputs:
        w_bsdf.inputs["Specular IOR Level"].default_value = 0.95
    elif "Specular" in w_bsdf.inputs:
        w_bsdf.inputs["Specular"].default_value = 0.95
    if "Transmission Weight" in w_bsdf.inputs:
        w_bsdf.inputs["Transmission Weight"].default_value = 0.45
    elif "Transmission" in w_bsdf.inputs:
        w_bsdf.inputs["Transmission"].default_value = 0.45

    tc_w = wn.new("ShaderNodeTexCoord")
    map_w = wn.new("ShaderNodeMapping")
    map_w.inputs["Scale"].default_value = (1.8, 4.2, 1.0)  # Ondas fluindo na direção do canal
    wl.new(tc_w.outputs["Object"], map_w.inputs["Vector"])

    noise_w = wn.new("ShaderNodeTexNoise")
    noise_w.inputs["Scale"].default_value = 8.5
    noise_w.inputs["Detail"].default_value = 3.0
    noise_w.inputs["Roughness"].default_value = 0.52
    wl.new(map_w.outputs["Vector"], noise_w.inputs["Vector"])

    bump_w = wn.new("ShaderNodeBump")
    bump_w.inputs["Strength"].default_value = 0.045
    bump_w.inputs["Distance"].default_value = 0.08
    wl.new(noise_w.outputs["Fac"], bump_w.inputs["Height"])
    wl.new(bump_w.outputs["Normal"], w_bsdf.inputs["Normal"])
    mats["water"] = mat_water

    # 4. Capim Pantaneiro (Verde-oliva vibrante com pontas douradas)
    mat_grass, gn, gl, g_bsdf = _new_mat("Mat_Pantanal_Grass")
    g_bsdf.inputs["Base Color"].default_value = (0.18, 0.29, 0.09, 1.0)
    g_bsdf.inputs["Roughness"].default_value = 0.65
    if "Subsurface Weight" in g_bsdf.inputs:
        g_bsdf.inputs["Subsurface Weight"].default_value = 0.15
    mats["grass"] = mat_grass

    # 5. Plantas Aquáticas (Folhas de ninfeia e vitória-régia verde-esmeralda com cutícula cerosa)
    mat_aquatic, an, al, a_bsdf = _new_mat("Mat_Aquatic_Leaf")
    a_bsdf.inputs["Base Color"].default_value = (0.12, 0.28, 0.14, 1.0)
    a_bsdf.inputs["Roughness"].default_value = 0.38
    if "Specular IOR Level" in a_bsdf.inputs:
        a_bsdf.inputs["Specular IOR Level"].default_value = 0.45
    mats["aquatic"] = mat_aquatic

    # 6. Casca de Árvore Pantaneira (Estrias profundas de aroeira/piúva)
    mat_bark, bn, bl, b_bsdf = _new_mat("Mat_Pantanal_Bark")
    b_bsdf.inputs["Roughness"].default_value = 0.90
    tc_b = bn.new("ShaderNodeTexCoord")
    map_b = bn.new("ShaderNodeMapping")
    map_b.inputs["Scale"].default_value = (2.0, 2.0, 0.4)
    bl.new(tc_b.outputs["Object"], map_b.inputs["Vector"])
    noise_b = bn.new("ShaderNodeTexNoise")
    noise_b.inputs["Scale"].default_value = 5.0
    noise_b.inputs["Detail"].default_value = 7.0
    bl.new(map_b.outputs["Vector"], noise_b.inputs["Vector"])
    ramp_b = bn.new("ShaderNodeValToRGB")
    ramp_b.color_ramp.elements[0].position = 0.25
    ramp_b.color_ramp.elements[0].color = (0.08, 0.065, 0.05, 1.0)
    ramp_b.color_ramp.elements[1].position = 0.80
    ramp_b.color_ramp.elements[1].color = (0.18, 0.15, 0.12, 1.0)
    bl.new(noise_b.outputs["Fac"], ramp_b.inputs["Fac"])
    bl.new(ramp_b.outputs["Color"], b_bsdf.inputs["Base Color"])
    bump_b = bn.new("ShaderNodeBump")
    bump_b.inputs["Strength"].default_value = 0.38
    bump_b.inputs["Distance"].default_value = 0.03
    bl.new(noise_b.outputs["Fac"], bump_b.inputs["Height"])
    bl.new(bump_b.outputs["Normal"], b_bsdf.inputs["Normal"])
    mats["bark"] = mat_bark

    # 7. Copa de Folhas
    mat_foliage, fn, fl, f_bsdf = _new_mat("Mat_Pantanal_Foliage")
    f_bsdf.inputs["Base Color"].default_value = (0.16, 0.26, 0.08, 1.0)
    f_bsdf.inputs["Roughness"].default_value = 0.60
    if "Subsurface Weight" in f_bsdf.inputs:
        f_bsdf.inputs["Subsurface Weight"].default_value = 0.22
    mats["foliage"] = mat_foliage

    # 8. Madeira Desgastada da Canoa e Mourões da Cerca (com veios longitudinais)
    mat_wood, on, ol, o_bsdf = _new_mat("Mat_Pantanal_Wood")
    o_bsdf.inputs["Roughness"].default_value = 0.84
    tc_o = on.new("ShaderNodeTexCoord")
    map_o = on.new("ShaderNodeMapping")
    map_o.inputs["Scale"].default_value = (6.0, 0.6, 6.0)  # Veios esticados
    ol.new(tc_o.outputs["Object"], map_o.inputs["Vector"])
    noise_o = on.new("ShaderNodeTexNoise")
    noise_o.inputs["Scale"].default_value = 6.0
    noise_o.inputs["Detail"].default_value = 5.0
    ol.new(map_o.outputs["Vector"], noise_o.inputs["Vector"])
    ramp_o = on.new("ShaderNodeValToRGB")
    ramp_o.color_ramp.elements[0].position = 0.28
    ramp_o.color_ramp.elements[0].color = (0.10, 0.08, 0.065, 1.0)
    ramp_o.color_ramp.elements[1].position = 0.75
    ramp_o.color_ramp.elements[1].color = (0.22, 0.18, 0.14, 1.0)
    ol.new(noise_o.outputs["Fac"], ramp_o.inputs["Fac"])
    ol.new(ramp_o.outputs["Color"], o_bsdf.inputs["Base Color"])
    bump_o = on.new("ShaderNodeBump")
    bump_o.inputs["Strength"].default_value = 0.25
    bump_o.inputs["Distance"].default_value = 0.015
    ol.new(noise_o.outputs["Fac"], bump_o.inputs["Height"])
    ol.new(bump_o.outputs["Normal"], o_bsdf.inputs["Normal"])
    mats["wood"] = mat_wood

    # 9. Arame Farpado Enferrujado
    mat_wire, _, _, wire_bsdf = _new_mat("Mat_Fence_Wire")
    wire_bsdf.inputs["Base Color"].default_value = (0.14, 0.10, 0.08, 1.0)
    wire_bsdf.inputs["Roughness"].default_value = 0.72
    wire_bsdf.inputs["Metallic"].default_value = 0.68
    mats["wire"] = mat_wire

    return mats


# ==============================================================================
# 4. CÁLCULO DO TABULEIRO E MÁSCARAS
# ==============================================================================
def compute_board_layout():
    cols = CONFIG["hex_columns"]
    rows = CONFIG["hex_rows"]
    R = CONFIG["hex_radius"]
    h_spacing = math.sqrt(3.0) * R
    v_spacing = 1.5 * R

    raw_centers = []
    for r in range(rows):
        for c in range(cols):
            x = c * h_spacing + (0.5 * h_spacing if (r % 2 == 1) else 0.0)
            y = r * v_spacing
            raw_centers.append((c, r, x, y))

    min_x = min(p[2] for p in raw_centers)
    max_x = max(p[2] for p in raw_centers)
    min_y = min(p[3] for p in raw_centers)
    max_y = max(p[3] for p in raw_centers)

    center_x = 0.5 * (min_x + max_x)
    center_y = 0.5 * (min_y + max_y) - 0.60

    hex_cells = []
    for c, r, x, y in raw_centers:
        hex_cells.append({
            "col": c,
            "row": r,
            "x": x - center_x,
            "y": y - center_y,
        })

    board_min_x = (min_x - center_x) - R * 0.95
    board_max_x = (max_x - center_x) + R * 0.95
    board_min_y = (min_y - center_y) - R * 0.95
    board_max_y = (max_y - center_y) + R * 0.95

    # Reserva Frontal
    reserve_y = board_min_y - CONFIG["reserve_gap"]
    reserve_slots = []
    total_slots = CONFIG["reserve_slots"]
    slot_w = CONFIG["reserve_slot_width"]
    slot_d = CONFIG["reserve_slot_depth"]
    spacing_x = slot_w * 1.16
    start_x = -0.5 * (total_slots - 1) * spacing_x

    for s_idx in range(total_slots):
        sx = start_x + s_idx * spacing_x
        reserve_slots.append({
            "idx": s_idx,
            "x": sx,
            "y": reserve_y,
            "w": slot_w,
            "d": slot_d,
        })

    return {
        "hex_cells": hex_cells,
        "reserve_slots": reserve_slots,
        "board_bounds": (board_min_x, board_max_x, board_min_y, board_max_y),
        "reserve_bounds": (
            start_x - slot_w * 0.5,
            start_x + (total_slots - 1) * spacing_x + slot_w * 0.5,
            reserve_y - slot_d * 0.5,
            reserve_y + slot_d * 0.5,
        ),
    }


def is_in_exclusion(x, y, layout, margin=None):
    if margin is None:
        margin = CONFIG["exclusion_margin"]
    b_min_x, b_max_x, b_min_y, b_max_y = layout["board_bounds"]
    r_min_x, r_max_x, r_min_y, r_max_y = layout["reserve_bounds"]

    if (b_min_x - margin) <= x <= (b_max_x + margin) and (b_min_y - margin) <= y <= (b_max_y + margin):
        return True
    if (r_min_x - margin) <= x <= (r_max_x + margin) and (r_min_y - margin) <= y <= (r_max_y + margin):
        return True
    if (r_min_x - 0.25) <= x <= (r_max_x + 0.25) and y < (r_min_y - 0.2):
        return True
    return False


# ==============================================================================
# 5. TERRENO E CANAIS DE VAZANTE (01_TERRAIN e 04_WATER)
# ==============================================================================
def build_terrain_and_water(layout, sub_cols, mats):
    bm_t = bmesh.new()
    bm_w = bmesh.new()

    size_x = 54.0
    size_y = 50.0
    res_x = 108
    res_y = 100

    dx = size_x / res_x
    dy = size_y / res_y
    start_x = -size_x * 0.5
    start_y = -size_y * 0.5 + 3.0

    b_min_x, b_max_x, b_min_y, b_max_y = layout["board_bounds"]
    r_min_x, r_max_x, r_min_y, r_max_y = layout["reserve_bounds"]
    z_water = CONFIG["water_level"]
    z_ground = CONFIG["ground_level"]

    def _height_at(x, y):
        in_board = (b_min_x - 0.45 <= x <= b_max_x + 0.45) and (b_min_y - 0.45 <= y <= b_max_y + 0.45)
        in_reserve = (r_min_x - 0.45 <= x <= r_max_x + 0.45) and (r_min_y - 0.45 <= y <= r_max_y + 0.45)

        if in_board or in_reserve:
            return z_ground

        # Conexão de terra firme contínua na frente (sul) e sudeste
        is_front_land = (y < r_min_y) and (x > -9.5) and (x < 15.0)
        is_east_land = (x > b_max_x) and (y < b_max_y + 1.2)

        if is_front_land:
            h = z_ground - 0.025 * (1.0 - math.cos((x + 2.0) * 0.18))
        elif is_east_land:
            h = z_ground - 0.035 * math.sin(x * 0.22) + 0.015 * math.cos(y * 0.2)
        elif y > b_max_y + 0.9:
            # Canal largo do fundo
            fall = clamp((y - (b_max_y + 0.9)) / 2.6, 0.0, 1.0)
            h = lerp(z_ground, z_water - 0.38, fall)
            h += math.sin(x * 0.28) * 0.06
        elif x < b_min_x - 0.9:
            # Canal sinuoso da margem esquerda
            fall = clamp((b_min_x - 0.9 - x) / 2.2, 0.0, 1.0)
            h = lerp(z_ground, z_water - 0.35, fall)
            h += math.cos(y * 0.30) * 0.05
        else:
            h = z_ground

        h += 0.02 * math.sin(x * 0.45 + y * 0.32)
        return h

    grid_verts = []
    for iy in range(res_y + 1):
        row = []
        cy = start_y + iy * dy
        for ix in range(res_x + 1):
            cx = start_x + ix * dx
            cz = _height_at(cx, cy)
            v = bm_t.verts.new((cx, cy, cz))
            row.append(v)
        grid_verts.append(row)

    bm_t.verts.ensure_lookup_table()
    for iy in range(res_y):
        for ix in range(res_x):
            v0 = grid_verts[iy][ix]
            v1 = grid_verts[iy][ix + 1]
            v2 = grid_verts[iy + 1][ix + 1]
            v3 = grid_verts[iy + 1][ix]
            bm_t.faces.new((v0, v1, v2, v3))

    bmesh.ops.recalc_face_normals(bm_t, faces=bm_t.faces)

    m_terrain = bpy.data.meshes.new("Terrain_Pantanal_Mesh")
    bm_t.to_mesh(m_terrain)
    bm_t.free()

    m_terrain.materials.append(mats["terrain"])
    terrain_obj = bpy.data.objects.new("Terrain_Main", m_terrain)
    for p in m_terrain.polygons:
        p.use_smooth = True
    link_obj(terrain_obj, sub_cols["01_TERRAIN"])

    # Malha de Água dos Canais
    w_verts = []
    w_res_x = 84
    w_res_y = 78
    w_dx = size_x / w_res_x
    w_dy = size_y / w_res_y

    for iy in range(w_res_y + 1):
        row = []
        cy = start_y + iy * w_dy
        for ix in range(w_res_x + 1):
            cx = start_x + ix * w_dx
            v = bm_w.verts.new((cx, cy, z_water))
            row.append(v)
        w_verts.append(row)

    bm_w.verts.ensure_lookup_table()
    for iy in range(w_res_y):
        for ix in range(w_res_x):
            cx = start_x + (ix + 0.5) * w_dx
            cy = start_y + (iy + 0.5) * w_dy
            th = _height_at(cx, cy)
            if th <= z_water + 0.08:
                v0 = w_verts[iy][ix]
                v1 = w_verts[iy][ix + 1]
                v2 = w_verts[iy + 1][ix + 1]
                v3 = w_verts[iy + 1][ix]
                bm_w.faces.new((v0, v1, v2, v3))

    bmesh.ops.recalc_face_normals(bm_w, faces=bm_w.faces)

    m_water = bpy.data.meshes.new("Water_Pantanal_Mesh")
    bm_w.to_mesh(m_water)
    bm_w.free()

    m_water.materials.append(mats["water"])
    water_obj = bpy.data.objects.new("Water_MainChannel", m_water)
    for p in m_water.polygons:
        p.use_smooth = True
    link_obj(water_obj, sub_cols["04_WATER"])

    return terrain_obj, water_obj


# ==============================================================================
# 6. GRADE HEXAGONAL (02_BOARD) E RESERVA (03_RESERVE)
# ==============================================================================
def build_flat_hex_cell_mesh(R, groove_w, groove_d):
    """
    Hexágono perfeitamente plano com sulco perimetral nítido.
    Slot 100% legível com 2 materiais: superfície de terra batida e sulco chanfrado.
    """
    bm = bmesh.new()

    r_inner = R - groove_w
    r_outer = R

    v_center = bm.verts.new((0.0, 0.0, 0.0))
    inner_verts = []
    outer_verts = []

    for i in range(6):
        ang = math.radians(30.0 + i * 60.0)
        ca = math.cos(ang)
        sa = math.sin(ang)

        vi = bm.verts.new((r_inner * ca, r_inner * sa, 0.0))
        vo = bm.verts.new((r_outer * ca, r_outer * sa, -groove_d))
        inner_verts.append(vi)
        outer_verts.append(vo)

    bm.verts.ensure_lookup_table()

    # Superfície plana útil (Material index 0)
    for i in range(6):
        next_i = (i + 1) % 6
        f = bm.faces.new((v_center, inner_verts[i], inner_verts[next_i]))
        f.material_index = 0

    # Sulco rebaixado chanfrado (Material index 1)
    for i in range(6):
        next_i = (i + 1) % 6
        f = bm.faces.new((inner_verts[i], outer_verts[i], outer_verts[next_i], inner_verts[next_i]))
        f.material_index = 1

    m = bpy.data.meshes.new("Hex_Mesh_Template")
    bm.to_mesh(m)
    bm.free()
    for p in m.polygons:
        p.use_smooth = True
    return m


def build_board_and_reserve(layout, sub_cols, mats):
    R = CONFIG["hex_radius"]
    gw = CONFIG["groove_width"]
    gd = CONFIG["groove_depth"]
    z_g = CONFIG["ground_level"]

    hex_mesh_player = build_flat_hex_cell_mesh(R, gw, gd)
    hex_mesh_player.materials.append(mats["hex_player"])
    hex_mesh_player.materials.append(mats["groove"])

    hex_mesh_enemy = build_flat_hex_cell_mesh(R, gw, gd)
    hex_mesh_enemy.materials.append(mats["hex_enemy"])
    hex_mesh_enemy.materials.append(mats["groove"])

    # 1. 8x8 Hexágonos
    for cell in layout["hex_cells"]:
        c = cell["col"]
        r = cell["row"]
        x = cell["x"]
        y = cell["y"]

        is_player = (r < CONFIG["hex_rows"] // 2)
        mesh_to_use = hex_mesh_player if is_player else hex_mesh_enemy

        obj = bpy.data.objects.new(f"Board_Hex_{r:02d}_{c:02d}", mesh_to_use)
        obj.location = (x, y, z_g + 0.003)
        link_obj(obj, sub_cols["02_BOARD"])

    # 2. 9 Posições da Reserva Frontal
    bm_res = bmesh.new()
    sw = CONFIG["reserve_slot_width"] * 0.5
    sd = CONFIG["reserve_slot_depth"] * 0.5
    rw = sw - 0.024
    rd = sd - 0.024

    v0 = bm_res.verts.new((-rw, -rd, 0.0))
    v1 = bm_res.verts.new((rw, -rd, 0.0))
    v2 = bm_res.verts.new((rw, rd, 0.0))
    v3 = bm_res.verts.new((-rw, rd, 0.0))
    f_center = bm_res.faces.new((v0, v1, v2, v3))
    f_center.material_index = 0

    o0 = bm_res.verts.new((-sw, -sd, -gd))
    o1 = bm_res.verts.new((sw, -sd, -gd))
    o2 = bm_res.verts.new((sw, sd, -gd))
    o3 = bm_res.verts.new((-sw, sd, -gd))

    bm_res.faces.new((o0, o1, v1, v0)).material_index = 1
    bm_res.faces.new((o1, o2, v2, v1)).material_index = 1
    bm_res.faces.new((o2, o3, v3, v2)).material_index = 1
    bm_res.faces.new((o3, o0, v0, v3)).material_index = 1

    m_res = bpy.data.meshes.new("Reserve_Slot_Mesh")
    bm_res.to_mesh(m_res)
    bm_res.free()
    m_res.materials.append(mats["reserve"])
    m_res.materials.append(mats["groove"])
    for p in m_res.polygons:
        p.use_smooth = True

    for slot in layout["reserve_slots"]:
        idx = slot["idx"]
        sx = slot["x"]
        sy = slot["y"]

        obj = bpy.data.objects.new(f"Reserve_Slot_{idx:02d}", m_res)
        obj.location = (sx, sy, z_g + 0.003)
        link_obj(obj, sub_cols["03_RESERVE"])


# ==============================================================================
# 7. VEGETAÇÃO DE MARGEM (05_BANK_VEGETATION)
# ==============================================================================
def create_grass_tuft_mesh(blade_count=14, max_h=0.55):
    bm = bmesh.new()
    for b in range(blade_count):
        ang = (b / blade_count) * math.pi * 2.0 + random.uniform(-0.25, 0.25)
        h = max_h * random.uniform(0.75, 1.25)
        w = random.uniform(0.018, 0.030)
        lean = random.uniform(0.20, 0.42)

        ca = math.cos(ang)
        sa = math.sin(ang)
        px = -sa * w
        py = ca * w

        v0 = bm.verts.new((-px, -py, 0.0))
        v1 = bm.verts.new((px, py, 0.0))
        v2 = bm.verts.new((px + ca * lean * 0.5, py + sa * lean * 0.5, h * 0.55))
        v3 = bm.verts.new((-px + ca * lean * 0.5, -py + sa * lean * 0.5, h * 0.55))
        v_tip = bm.verts.new((ca * lean, sa * lean, h))

        bm.faces.new((v0, v1, v2, v3))
        bm.faces.new((v3, v2, v_tip))

    m = bpy.data.meshes.new("Grass_Tuft_Mesh")
    bm.to_mesh(m)
    bm.free()
    for p in m.polygons:
        p.use_smooth = True
    return m


def scatter_bank_vegetation(layout, sub_cols, mats):
    random.seed(CONFIG["random_seed"] + 10)
    tuft_mesh = create_grass_tuft_mesh(blade_count=14, max_h=0.58)
    tuft_mesh.materials.append(mats["grass"])

    num_tufts = 110
    b_min_x, b_max_x, b_min_y, b_max_y = layout["board_bounds"]
    r_min_x, r_max_x, r_min_y, r_max_y = layout["reserve_bounds"]

    count = 0
    for _ in range(num_tufts * 4):
        if count >= num_tufts:
            break
        side = random.choice(["south", "east", "west_bank", "north_bank"])
        if side == "south":
            x = random.uniform(-11.5, 12.5)
            y = random.uniform(r_min_y - 3.2, r_min_y - 0.6)
        elif side == "east":
            x = random.uniform(b_max_x + 0.6, b_max_x + 7.5)
            y = random.uniform(-6.5, 5.5)
        elif side == "west_bank":
            x = random.uniform(-8.8, b_min_x - 0.8)
            y = random.uniform(-6.5, 5.0)
        else:
            x = random.uniform(-9.5, 10.5)
            y = random.uniform(b_max_y + 0.9, b_max_y + 6.0)

        if is_in_exclusion(x, y, layout, margin=0.35):
            continue

        obj = bpy.data.objects.new(f"Grass_Bank_{count:02d}", tuft_mesh)
        sc = random.uniform(0.85, 1.45)
        obj.scale = (sc, sc, sc * random.uniform(0.9, 1.25))
        obj.rotation_euler = (random.uniform(-0.08, 0.08), random.uniform(-0.08, 0.08), random.uniform(0, math.pi * 2))
        obj.location = (x, y, CONFIG["ground_level"] - 0.02)
        link_obj(obj, sub_cols["05_BANK_VEGETATION"])
        count += 1


# ==============================================================================
# 8. PLANTAS AQUÁTICAS (06_AQUATIC_PLANTS)
# ==============================================================================
def create_victoria_leaf_mesh(radius=0.45):
    bm = bmesh.new()
    segs = 20
    v_center = bm.verts.new((0.0, 0.0, 0.0))

    outer_verts = []
    for i in range(segs):
        t = i / float(segs - 1)
        ang = math.radians(lerp(22.0, 338.0, t))
        ca = math.cos(ang)
        sa = math.sin(ang)
        r = radius * (1.0 + 0.04 * math.sin(ang * 4.0))
        vo = bm.verts.new((r * ca, r * sa, 0.012))
        outer_verts.append(vo)

    bm.verts.ensure_lookup_table()
    for i in range(segs - 1):
        bm.faces.new((v_center, outer_verts[i], outer_verts[i + 1]))

    m = bpy.data.meshes.new("Victoria_Leaf_Mesh")
    bm.to_mesh(m)
    bm.free()
    for p in m.polygons:
        p.use_smooth = True
    return m


def scatter_aquatic_plants(layout, sub_cols, mats):
    random.seed(CONFIG["random_seed"] + 25)
    leaf_mesh = create_victoria_leaf_mesh(radius=0.38)
    leaf_mesh.materials.append(mats["aquatic"])

    clusters = [
        {"cx": -5.6, "cy": -1.4, "count": 8, "spread": 1.3},
        {"cx": -5.2, "cy": -3.5, "count": 6, "spread": 1.0},
        {"cx": -3.2, "cy": 5.8, "count": 9, "spread": 2.0},
        {"cx": 3.6, "cy": 6.2, "count": 10, "spread": 2.4},
        {"cx": 9.2, "cy": 5.2, "count": 7, "spread": 1.5},
    ]

    idx = 0
    for cl in clusters:
        for _ in range(cl["count"]):
            rx = cl["cx"] + random.uniform(-cl["spread"], cl["spread"])
            ry = cl["cy"] + random.uniform(-cl["spread"] * 0.7, cl["spread"] * 0.7)
            if is_in_exclusion(rx, ry, layout, margin=0.3):
                continue
            obj = bpy.data.objects.new(f"Aquatic_Leaf_{idx:02d}", leaf_mesh)
            s = random.uniform(0.65, 1.35)
            obj.scale = (s, s, s)
            obj.rotation_euler = (0, 0, random.uniform(0, math.pi * 2))
            obj.location = (rx, ry, CONFIG["water_level"] + 0.006)
            link_obj(obj, sub_cols["06_AQUATIC_PLANTS"])
            idx += 1


# ==============================================================================
# 9. ÁRVORES PANTANEIRAS (07_TREES)
# ==============================================================================
def create_pantanal_tree_mesh(trunk_r=0.36, height=7.2, lean_dir=Vector((0.45, 0.25, 0.0))):
    bm_t = bmesh.new()
    bm_f = bmesh.new()

    segs = 8
    n_rings = 8
    base_rings = []
    for ir in range(n_rings):
        t = ir / float(n_rings - 1)
        z = t * height
        r = trunk_r * (1.0 - t * 0.55)
        ox = lean_dir.x * (t ** 1.3) * 2.1 + math.sin(t * 3.5) * 0.18
        oy = lean_dir.y * (t ** 1.3) * 2.1 + math.cos(t * 3.2) * 0.14

        ring = []
        for iseg in range(segs):
            ang = (iseg / segs) * math.pi * 2.0
            vx = ox + math.cos(ang) * r
            vy = oy + math.sin(ang) * r
            v = bm_t.verts.new((vx, vy, z))
            ring.append(v)
        base_rings.append(ring)

    bm_t.verts.ensure_lookup_table()
    for ir in range(n_rings - 1):
        for iseg in range(segs):
            next_s = (iseg + 1) % segs
            bm_t.faces.new((
                base_rings[ir][iseg],
                base_rings[ir][next_s],
                base_rings[ir + 1][next_s],
                base_rings[ir + 1][iseg]
            ))

    canopy_centers = [
        Vector((lean_dir.x * 2.1, lean_dir.y * 2.1, height)),
        Vector((lean_dir.x * 2.1 + 1.4, lean_dir.y * 2.1 - 0.8, height - 0.5)),
        Vector((lean_dir.x * 2.1 - 1.2, lean_dir.y * 2.1 + 1.0, height - 0.4)),
    ]

    for cc in canopy_centers:
        for layer in range(3):
            lz = cc.z + layer * 0.42
            lr = (2.1 - layer * 0.45)
            l_segs = 12
            c_vert = bm_f.verts.new((cc.x, cc.y, lz + 0.22))
            l_ring = []
            for ils in range(l_segs):
                ang = (ils / l_segs) * math.pi * 2.0
                vx = cc.x + math.cos(ang) * lr * random.uniform(0.85, 1.15)
                vy = cc.y + math.sin(ang) * lr * random.uniform(0.85, 1.15)
                v = bm_f.verts.new((vx, vy, lz - 0.16))
                l_ring.append(v)
            bm_f.verts.ensure_lookup_table()
            for ils in range(l_segs):
                n_ils = (ils + 1) % l_segs
                bm_f.faces.new((c_vert, l_ring[ils], l_ring[n_ils]))

    m_trunk = bpy.data.meshes.new("Tree_Trunk_Mesh")
    bm_t.to_mesh(m_trunk)
    bm_t.free()

    m_foliage = bpy.data.meshes.new("Tree_Foliage_Mesh")
    bm_f.to_mesh(m_foliage)
    bm_f.free()

    for p in m_trunk.polygons:
        p.use_smooth = True
    for p in m_foliage.polygons:
        p.use_smooth = True

    return m_trunk, m_foliage


def build_trees(layout, sub_cols, mats):
    # 1. Grande árvore pantaneira na margem direita debruçada sobre o rio
    t1_trunk, t1_fol = create_pantanal_tree_mesh(trunk_r=0.44, height=8.4, lean_dir=Vector((-0.85, 0.25, 0.0)))
    t1_trunk.materials.append(mats["bark"])
    t1_fol.materials.append(mats["foliage"])

    obj_t1 = bpy.data.objects.new("Tree_Gnarly_Right", t1_trunk)
    obj_t1.location = (5.5, 0.2, CONFIG["ground_level"] - 0.04)
    link_obj(obj_t1, sub_cols["07_TREES"])

    obj_t1_f = bpy.data.objects.new("Tree_Gnarly_Right_Canopy", t1_fol)
    obj_t1_f.location = obj_t1.location
    link_obj(obj_t1_f, sub_cols["07_TREES"])

    # 2. Árvore esbelta na margem esquerda distante
    t2_trunk, t2_fol = create_pantanal_tree_mesh(trunk_r=0.28, height=6.6, lean_dir=Vector((0.35, 0.25, 0.0)))
    t2_trunk.materials.append(mats["bark"])
    t2_fol.materials.append(mats["foliage"])

    obj_t2 = bpy.data.objects.new("Tree_Left_Bank", t2_trunk)
    obj_t2.location = (-9.8, 1.2, CONFIG["ground_level"] - 0.15)
    link_obj(obj_t2, sub_cols["07_TREES"])

    obj_t2_f = bpy.data.objects.new("Tree_Left_Bank_Canopy", t2_fol)
    obj_t2_f.location = obj_t2.location
    link_obj(obj_t2_f, sub_cols["07_TREES"])

    # 3. Pequeno capão ao fundo (árvores distantes espaçadas)
    background_trees = [
        Vector((-6.5, 14.5, CONFIG["water_level"] - 0.05)),
        Vector((0.6, 16.2, CONFIG["water_level"] - 0.05)),
        Vector((9.0, 15.0, CONFIG["water_level"] - 0.05)),
    ]
    for idx, pos in enumerate(background_trees):
        tb_trunk, tb_fol = create_pantanal_tree_mesh(trunk_r=0.25, height=6.2, lean_dir=Vector((0.2, -0.1, 0.0)))
        tb_trunk.materials.append(mats["bark"])
        tb_fol.materials.append(mats["foliage"])

        o_tr = bpy.data.objects.new(f"Tree_Capao_{idx:02d}", tb_trunk)
        o_tr.location = pos
        sc = random.uniform(1.0, 1.35)
        o_tr.scale = (sc, sc, sc)
        link_obj(o_tr, sub_cols["07_TREES"])

        o_fl = bpy.data.objects.new(f"Tree_Capao_{idx:02d}_Canopy", tb_fol)
        o_fl.location = pos
        o_fl.scale = (sc, sc, sc)
        link_obj(o_fl, sub_cols["07_TREES"])

    # 4. Tronco Morto Quebrado em ilhota externa à direita
    bm_dead = bmesh.new()
    dh = 2.6
    dr = 0.24
    for ring_i in range(5):
        tz = (ring_i / 4.0) * dh
        curr_r = dr * (1.0 - ring_i * 0.12)
        for s in range(6):
            ang = s * math.pi / 3.0
            vx = math.cos(ang) * curr_r + tz * 0.22
            vy = math.sin(ang) * curr_r
            bm_dead.verts.new((vx, vy, tz))
    bm_dead.verts.ensure_lookup_table()
    for ring_i in range(4):
        for s in range(6):
            ns = (s + 1) % 6
            bm_dead.faces.new((
                bm_dead.verts[ring_i * 6 + s],
                bm_dead.verts[ring_i * 6 + ns],
                bm_dead.verts[(ring_i + 1) * 6 + ns],
                bm_dead.verts[(ring_i + 1) * 6 + s]
            ))
    v_top = bm_dead.verts.new((dh * 0.24, 0.05, dh + 0.35))
    bm_dead.verts.ensure_lookup_table()
    for s in range(6):
        ns = (s + 1) % 6
        bm_dead.faces.new((bm_dead.verts[24 + s], bm_dead.verts[24 + ns], v_top))

    m_dead = bpy.data.meshes.new("Tree_DeadTrunk_Mesh")
    bm_dead.to_mesh(m_dead)
    bm_dead.free()
    m_dead.materials.append(mats["wood"])

    obj_dead = bpy.data.objects.new("Tree_DeadTrunk", m_dead)
    obj_dead.location = (8.2, 6.8, CONFIG["ground_level"] - 0.22)
    obj_dead.rotation_euler = (0.15, -0.22, 0.85)
    link_obj(obj_dead, sub_cols["07_TREES"])


# ==============================================================================
# 10. CERCA RURAL E CANOA ABANDONADA (08_FENCE_AND_CANOE)
# ==============================================================================
def build_fence_and_canoe(layout, sub_cols, mats):
    # 1. Mourões da Cerca ao longo da margem esquerda
    fence_posts = [
        Vector((-5.9, -4.6, CONFIG["ground_level"])),
        Vector((-6.2, -3.0, CONFIG["ground_level"])),
        Vector((-6.5, -1.2, CONFIG["ground_level"])),
        Vector((-6.9, 0.6, CONFIG["ground_level"] - 0.05)),
        Vector((-7.4, 2.5, CONFIG["water_level"] + 0.02)),
    ]

    bm_post = bmesh.new()
    ph = 1.38
    pr = 0.075
    for ir in range(4):
        pz = (ir / 3.0) * ph
        for iseg in range(5):
            ang = iseg * math.pi * 2.0 / 5.0
            vx = math.cos(ang) * pr * random.uniform(0.85, 1.15)
            vy = math.sin(ang) * pr * random.uniform(0.85, 1.15)
            bm_post.verts.new((vx, vy, pz))
    bm_post.verts.ensure_lookup_table()
    for ir in range(3):
        for iseg in range(5):
            niseg = (iseg + 1) % 5
            bm_post.faces.new((
                bm_post.verts[ir * 5 + iseg],
                bm_post.verts[ir * 5 + niseg],
                bm_post.verts[(ir + 1) * 5 + niseg],
                bm_post.verts[(ir + 1) * 5 + iseg]
            ))
    m_post = bpy.data.meshes.new("Fence_Post_Mesh")
    bm_post.to_mesh(m_post)
    bm_post.free()
    m_post.materials.append(mats["wood"])

    for idx, pos in enumerate(fence_posts):
        obj = bpy.data.objects.new(f"Fence_Post_{idx:02d}", m_post)
        obj.location = pos
        obj.rotation_euler = (random.uniform(-0.15, 0.15), random.uniform(-0.15, 0.15), random.uniform(0, math.pi))
        link_obj(obj, sub_cols["08_FENCE_AND_CANOE"])

    curve_data = bpy.data.curves.new("Fence_Wire", 'CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_depth = 0.007

    for wire_level in [0.45, 0.95]:
        spline = curve_data.splines.new('POLY')
        spline.points.add(len(fence_posts) - 1)
        for p_idx, post_pos in enumerate(fence_posts):
            sag = 0.06 if (0 < p_idx < len(fence_posts) - 1) else 0.0
            spline.points[p_idx].co = (post_pos.x, post_pos.y, post_pos.z + wire_level - sag, 1.0)

    wire_obj = bpy.data.objects.new("Fence_Wires", curve_data)
    wire_obj.data.materials.append(mats["wire"])
    link_obj(wire_obj, sub_cols["08_FENCE_AND_CANOE"])

    # 2. Canoa Pantaneira Abandonada (Piroga de tronco)
    bm_c = bmesh.new()
    canoe_len = 3.6
    canoe_w = 0.72
    canoe_depth = 0.40
    steps_len = 14

    top_outer = []
    top_inner = []
    bottom_outer = []
    bottom_inner = []

    for i in range(steps_len + 1):
        t = i / float(steps_len)
        u = (t - 0.5) * 2.0
        y_pos = u * (canoe_len * 0.5)

        w_factor = math.cos(u * math.pi * 0.5) ** 0.65
        w_cur = canoe_w * 0.5 * w_factor
        w_in = max(0.02, w_cur - 0.065)

        sheer = (u ** 2) * 0.14
        z_top = sheer
        z_bot = -canoe_depth * (0.8 + 0.2 * w_factor) + sheer * 0.5
        z_in_bot = z_bot + 0.06

        v_to_l = bm_c.verts.new((-w_cur, y_pos, z_top))
        v_to_r = bm_c.verts.new((w_cur, y_pos, z_top))
        v_ti_l = bm_c.verts.new((-w_in, y_pos, z_top - 0.02))
        v_ti_r = bm_c.verts.new((w_in, y_pos, z_top - 0.02))

        v_bo_l = bm_c.verts.new((-w_cur * 0.55, y_pos, z_bot))
        v_bo_r = bm_c.verts.new((w_cur * 0.55, y_pos, z_bot))
        v_bi_l = bm_c.verts.new((-w_in * 0.55, y_pos, z_in_bot))
        v_bi_r = bm_c.verts.new((w_in * 0.55, y_pos, z_in_bot))

        top_outer.append((v_to_l, v_to_r))
        top_inner.append((v_ti_l, v_ti_r))
        bottom_outer.append((v_bo_l, v_bo_r))
        bottom_inner.append((v_bi_l, v_bi_r))

    bm_c.verts.ensure_lookup_table()
    for i in range(steps_len):
        bm_c.faces.new((top_outer[i][0], top_outer[i + 1][0], bottom_outer[i + 1][0], bottom_outer[i][0]))
        bm_c.faces.new((top_outer[i][1], bottom_outer[i][1], bottom_outer[i + 1][1], top_outer[i + 1][1]))
        bm_c.faces.new((bottom_outer[i][0], bottom_outer[i + 1][0], bottom_outer[i + 1][1], bottom_outer[i][1]))
        bm_c.faces.new((top_outer[i][0], top_inner[i][0], top_inner[i + 1][0], top_outer[i + 1][0]))
        bm_c.faces.new((top_outer[i][1], top_outer[i + 1][1], top_inner[i + 1][1], top_inner[i][1]))
        bm_c.faces.new((top_inner[i][0], bottom_inner[i][0], bottom_inner[i + 1][0], top_inner[i + 1][0]))
        bm_c.faces.new((top_inner[i][1], top_inner[i + 1][1], bottom_inner[i + 1][1], bottom_inner[i][1]))
        bm_c.faces.new((bottom_inner[i][0], bottom_inner[i][1], bottom_inner[i + 1][1], bottom_inner[i + 1][0]))

    m_canoe = bpy.data.meshes.new("Canoe_Mesh")
    bm_c.to_mesh(m_canoe)
    bm_c.free()
    m_canoe.materials.append(mats["wood"])
    for p in m_canoe.polygons:
        p.use_smooth = True

    canoe_obj = bpy.data.objects.new("Canoe_Abandoned", m_canoe)
    canoe_obj.location = (-5.4, -2.0, CONFIG["ground_level"] + 0.06)
    canoe_obj.rotation_euler = (0.15, 0.08, 0.40)
    link_obj(canoe_obj, sub_cols["08_FENCE_AND_CANOE"])

    # Remo de madeira
    bm_oar = bmesh.new()
    oar_len = 1.6
    oar_r = 0.022
    for ring_i in range(5):
        oz = (ring_i / 4.0) * oar_len
        for s in range(5):
            ang = s * math.pi * 2.0 / 5.0
            bm_oar.verts.new((math.cos(ang) * oar_r, oz, math.sin(ang) * oar_r))
    bm_oar.verts.ensure_lookup_table()
    for ring_i in range(4):
        for s in range(5):
            ns = (s + 1) % 5
            bm_oar.faces.new((
                bm_oar.verts[ring_i * 5 + s],
                bm_oar.verts[ring_i * 5 + ns],
                bm_oar.verts[(ring_i + 1) * 5 + ns],
                bm_oar.verts[(ring_i + 1) * 5 + s]
            ))
    p0 = bm_oar.verts.new((-0.07, oar_len, 0.0))
    p1 = bm_oar.verts.new((0.07, oar_len, 0.0))
    p2 = bm_oar.verts.new((0.09, oar_len + 0.38, 0.0))
    p3 = bm_oar.verts.new((-0.09, oar_len + 0.38, 0.0))
    bm_oar.faces.new((p0, p1, p2, p3))

    m_oar = bpy.data.meshes.new("Canoe_Oar_Mesh")
    bm_oar.to_mesh(m_oar)
    bm_oar.free()
    m_oar.materials.append(mats["wood"])

    oar_obj = bpy.data.objects.new("Canoe_Oar", m_oar)
    oar_obj.location = (-5.35, -1.9, CONFIG["ground_level"] + 0.14)
    oar_obj.rotation_euler = (0.35, -0.15, 0.54)
    link_obj(oar_obj, sub_cols["08_FENCE_AND_CANOE"])


# ==============================================================================
# 11. HORROR AMBIENTAL SUTIL (09_HORROR_DETAILS)
# ==============================================================================
def build_horror_details(layout, sub_cols, mats):
    # Anomalia A: Ramo submerso adicional na árvore direita (visível no reflexo)
    bm_branch = bmesh.new()
    br_len = 1.8
    for ri in range(4):
        tz = ri * (br_len / 3.0)
        curr_r = 0.08 * (1.0 - ri * 0.25)
        for s in range(5):
            ang = s * math.pi * 2.0 / 5.0
            bm_branch.verts.new((math.cos(ang) * curr_r + tz * 0.45, math.sin(ang) * curr_r, -tz * 0.35))
    bm_branch.verts.ensure_lookup_table()
    for ri in range(3):
        for s in range(5):
            ns = (s + 1) % 5
            bm_branch.faces.new((
                bm_branch.verts[ri * 5 + s],
                bm_branch.verts[ri * 5 + ns],
                bm_branch.verts[(ri + 1) * 5 + ns],
                bm_branch.verts[(ri + 1) * 5 + s]
            ))
    m_branch = bpy.data.meshes.new("Horror_ExtraBranch_Mesh")
    bm_branch.to_mesh(m_branch)
    bm_branch.free()
    m_branch.materials.append(mats["bark"])

    branch_obj = bpy.data.objects.new("Horror_ExtraBranchReflection", m_branch)
    branch_obj.location = (6.4, 1.0, CONFIG["water_level"] - 0.04)
    branch_obj.rotation_euler = (0.25, 0.45, -0.65)
    link_obj(branch_obj, sub_cols["09_HORROR_DETAILS"])

    # Anomalia B: Ondulações de esteira submersa recente junto à canoa vazia
    bm_wake = bmesh.new()
    rings = 4
    for r_i in range(rings):
        rad = 0.35 + r_i * 0.28
        h_wake = 0.012 * math.cos(r_i * math.pi)
        for s in range(12):
            ang = s * math.pi * 2.0 / 12.0
            vx = math.cos(ang) * rad * 1.35
            vy = math.sin(ang) * rad
            bm_wake.verts.new((vx, vy, h_wake))
    bm_wake.verts.ensure_lookup_table()
    for r_i in range(rings - 1):
        for s in range(12):
            ns = (s + 1) % 12
            bm_wake.faces.new((
                bm_wake.verts[r_i * 12 + s],
                bm_wake.verts[r_i * 12 + ns],
                bm_wake.verts[(r_i + 1) * 12 + ns],
                bm_wake.verts[(r_i + 1) * 12 + s]
            ))
    m_wake = bpy.data.meshes.new("Horror_Wake_Mesh")
    bm_wake.to_mesh(m_wake)
    bm_wake.free()
    m_wake.materials.append(mats["water"])
    for p in m_wake.polygons:
        p.use_smooth = True

    wake_obj = bpy.data.objects.new("Horror_SubmergedWake", m_wake)
    wake_obj.location = (-4.0, -1.5, CONFIG["water_level"] + 0.003)
    link_obj(wake_obj, sub_cols["09_HORROR_DETAILS"])

    # Anomalia C: Capim amassado que entra na água e ressurge
    tuft_flattened = create_grass_tuft_mesh(blade_count=8, max_h=0.22)
    tuft_flattened.materials.append(mats["grass"])

    trail_points = [
        Vector((-5.4, 0.2, CONFIG["ground_level"] - 0.05)),
        Vector((-5.8, 0.8, CONFIG["ground_level"] - 0.10)),
        Vector((-6.2, 1.4, CONFIG["water_level"])),
        Vector((-7.4, 3.2, CONFIG["water_level"])),
        Vector((-7.8, 3.8, CONFIG["ground_level"] - 0.12)),
    ]
    for p_idx, pos in enumerate(trail_points):
        t_obj = bpy.data.objects.new(f"Horror_FlattenedGrass_{p_idx:02d}", tuft_flattened)
        t_obj.location = pos
        t_obj.rotation_euler = (0.75, 0.0, 0.35)
        link_obj(t_obj, sub_cols["09_HORROR_DETAILS"])


# ==============================================================================
# 12. CÉU PROCEDURAL DE ENTARDECER E ILUMINAÇÃO (10_LIGHTS)
# ==============================================================================
def setup_lighting_and_world(sub_cols):
    scene = bpy.context.scene
    world = scene.world
    if not world:
        world = bpy.data.worlds.new("Pantanal_World")
        scene.world = world
    world.use_nodes = True
    wn = world.node_tree.nodes
    wl = world.node_tree.links
    wn.clear()

    node_out = wn.new("ShaderNodeOutputWorld")
    node_out.location = (600, 0)
    node_bg = wn.new("ShaderNodeBackground")
    node_bg.location = (350, 0)
    node_bg.inputs["Strength"].default_value = 1.15

    tc = wn.new("ShaderNodeTexCoord")
    tc.location = (-600, 0)
    sep = wn.new("ShaderNodeSeparateXYZ")
    sep.location = (-400, 0)
    wl.new(tc.outputs["Normal"], sep.inputs["Vector"])

    # Mapeia Z de [-1, 1] para [0, 1]
    map_range = wn.new("ShaderNodeMapRange")
    map_range.location = (-250, 0)
    map_range.inputs["From Min"].default_value = -0.05
    map_range.inputs["From Max"].default_value = 0.85
    map_range.inputs["To Min"].default_value = 0.0
    map_range.inputs["To Max"].default_value = 1.0
    wl.new(sep.outputs["Z"], map_range.inputs["Value"])

    ramp_sky = wn.new("ShaderNodeValToRGB")
    ramp_sky.location = (-50, 0)
    cr = ramp_sky.color_ramp
    cr.color_mode = 'RGB'
    cr.interpolation = 'EASE'

    # Horizonte âmbar/cobre (pôr do sol), meio lilás crepuscular e topo azul-noite
    cr.elements[0].position = 0.02
    cr.elements[0].color = (0.95, 0.48, 0.18, 1.0)  # Laranja/âmbar no horizonte

    e1 = cr.elements.new(0.14)
    e1.color = (0.75, 0.28, 0.25, 1.0)              # Rosa queimado / cobre

    e2 = cr.elements.new(0.32)
    e2.color = (0.28, 0.16, 0.32, 1.0)              # Lilás crepuscular

    cr.elements[len(cr.elements) - 1].position = 0.75
    cr.elements[len(cr.elements) - 1].color = (0.04, 0.08, 0.18, 1.0)  # Azul-índigo noturno

    wl.new(map_range.outputs["Result"], ramp_sky.inputs["Fac"])
    wl.new(ramp_sky.outputs["Color"], node_bg.inputs["Color"])
    wl.new(node_bg.outputs["Background"], node_out.inputs["Surface"])

    # Camada 1: Sol Poente Rasante Âmbar (baixo à esquerda e atrás do campo)
    sun_data = bpy.data.lights.new(name="Sun_SunsetKey_Data", type='SUN')
    sun_data.color = (1.0, 0.58, 0.26)
    sun_data.energy = 4.4
    sun_data.angle = math.radians(2.2)

    sun_obj = bpy.data.objects.new("Light_Sunset_Key", sun_data)
    # Inclinação suave a 15° de elevação vindo do oeste-noroeste
    sun_obj.rotation_euler = (math.radians(-75.0), math.radians(14.0), math.radians(55.0))
    link_obj(sun_obj, sub_cols["10_LIGHTS"])

    # Camada 2: Luz de Preenchimento de Céu Crepuscular Frio (garante contraste limpo nas 64 casas)
    fill_data = bpy.data.lights.new(name="Fill_CoolSky_Data", type='SUN')
    fill_data.color = (0.46, 0.66, 0.88)
    fill_data.energy = 1.30
    fill_data.angle = math.radians(18.0)

    fill_obj = bpy.data.objects.new("Light_Cool_Fill", fill_data)
    fill_obj.rotation_euler = (math.radians(-15.0), 0.0, 0.0)
    link_obj(fill_obj, sub_cols["10_LIGHTS"])

    # Camada 3: Preenchimento Suave da Reserva Frontal
    bench_data = bpy.data.lights.new(name="Fill_Reserve_Data", type='POINT')
    bench_data.color = (0.95, 0.82, 0.70)
    bench_data.energy = 38.0
    bench_obj = bpy.data.objects.new("Light_Reserve_SoftFill", bench_data)
    bench_obj.location = (0.0, -5.2, 4.2)
    link_obj(bench_obj, sub_cols["10_LIGHTS"])


# ==============================================================================
# 13. ENQUADRAMENTO DA CÂMERA (11_CAMERAS)
# ==============================================================================
def setup_camera(layout, sub_cols):
    cam_data = bpy.data.cameras.new("Camera_Game_Data")
    cam_data.lens = 38.0
    cam_data.clip_start = 0.1
    cam_data.clip_end = 150.0

    cam_obj = bpy.data.objects.new("Camera_Game", cam_data)
    cam_obj.location = (0.0, -14.2, 12.5)
    cam_obj.rotation_euler = (math.radians(50.5), 0.0, 0.0)
    link_obj(cam_obj, sub_cols["11_CAMERAS"])

    bpy.context.scene.camera = cam_obj
    return cam_obj


# ==============================================================================
# 14. RENDERIZAÇÃO E README
# ==============================================================================
def render_outputs():
    out_dir = CONFIG["output_dir"]
    os.makedirs(out_dir, exist_ok=True)

    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    cycles = scene.cycles
    cycles.device = 'GPU' if bpy.context.preferences.addons.get('cycles') else 'CPU'

    scene.view_settings.view_transform = 'Filmic' if 'Filmic' in [v.name for v in bpy.types.ColorManagedViewSettings.bl_rna.properties['view_transform'].enum_items] else 'Standard'
    scene.view_settings.look = 'Medium Contrast'

    # 1. Preview
    scene.render.resolution_x, scene.render.resolution_y = CONFIG["preview_resolution"]
    cycles.samples = CONFIG["preview_samples"]
    preview_path = os.path.join(out_dir, "pantanal_autochess_preview.png")
    scene.render.filepath = preview_path
    print(f">> Renderizando Preview ({scene.render.resolution_x}x{scene.render.resolution_y})...")
    bpy.ops.render.render(write_still=True)
    print(f">> Preview salvo em: {preview_path}")

    # 2. Final
    scene.render.resolution_x, scene.render.resolution_y = CONFIG["final_resolution"]
    cycles.samples = CONFIG["final_samples"]
    final_path = os.path.join(out_dir, "pantanal_autochess_final.png")
    scene.render.filepath = final_path
    print(f">> Renderizando Imagem Final ({scene.render.resolution_x}x{scene.render.resolution_y})...")
    bpy.ops.render.render(write_still=True)
    print(f">> Render final salvo em: {final_path}")

    # 3. Salvar .blend
    blend_path = os.path.join(out_dir, "pantanal_autochess.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f">> Projeto .blend salvo em: {blend_path}")


def write_readme():
    out_dir = CONFIG["output_dir"]
    readme_path = os.path.join(out_dir, "README.md")
    content = f"""# Pantanal Autochess — Arena 3D de Horror Folclórico

Cena 3D procedural do bioma Pantanal ao entardecer desenvolvida para o jogo de autochess de horror folclórico brasileiro.

## 1. Especificações Técnicas
- **Versão do Blender**: 5.2.2 LTS
- **Motor de Renderização**: Cycles (GPU)
- **Gerenciamento de Cor**: Filmic / Medium Contrast
- **Resolução Final**: 1920 × 1080 (16:9)
- **Coleção Raiz**: `PANTANAL_ENV` (subcoleções `00_CONTROLS` a `11_CAMERAS`)

## 2. Estrutura da Cena e Parâmetros
- **Grade Hexagonal**: 8 colunas × 8 fileiras ({CONFIG['hex_columns'] * CONFIG['hex_rows']} casas), raio `R = {CONFIG['hex_radius']} m`, pointy-topped.
- **Ladrilhos Planos**: Superfície dos hexágonos 100% plana com sulcos rasos de {CONFIG['groove_width']} m e profundidade de {CONFIG['groove_depth']} m esculpidos na terra batida de vazante pantaneira.
- **Reserva Frontal**: {CONFIG['reserve_slots']} posições retangulares alinhadas na frente (`Y < 0`), integradas à mesma terra firme.
- **Água e Canais**: Canais de vazante ao fundo e à esquerda (`Z = {CONFIG['water_level']} m`), com água escura e reflexos quentes de cobre/âmbar.
- **Vegetação**: Touceiras de capim pantaneiro e folhas aquáticas flutuantes (aguapés e vitórias-régias jovens).
- **Elementos Rurais**: Cerca de mourões de aroeira com arame farpado frouxo e canoa de madeira tradicional abandonada encalhada na margem.
- **Horror Ambiental Sutil**:
  1. `Horror_ExtraBranchReflection`: Ramo submerso anômalo visível no reflexo da água sob a árvore lateral.
  2. `Horror_SubmergedWake`: Ondulações concêntricas de esteira recente ao lado da canoa vazia.
  3. `Horror_FlattenedGrassTrail`: Trilha de capim amassado que entra na água e ressurge na margem oposta.
- **Iluminação de Entardecer**: Sol poente âmbar/cobre baixo vindo de trás e à esquerda (`Light_Sunset_Key`), preenchimento suave frio (`Light_Cool_Fill`), e céu físico de entardecer pantaneiro.

## 3. Arquivos Entregues
- `pantanal_autochess.blend` — Cena completa editável e organizada.
- `pantanal_autochess_final.png` — Render final 1920 × 1080.
- `pantanal_autochess_preview.png` — Render de prévia 960 × 540.
- `build_pantanal.py` — Script completo de automação em Blender Python.
"""
    with open(readme_path, "w", encoding="utf-8") as f:
        f.write(content)
    print(f">> README.md gerado em: {readme_path}")


# ==============================================================================
# 15. FUNÇÃO PRINCIPAL
# ==============================================================================
def main():
    print("=================================================================")
    print("Iniciando geração da Arena do Pantanal (Pantanal_Autochess)...")
    print("=================================================================")

    random.seed(CONFIG["random_seed"])
    scene, main_col, sub_cols = setup_scene_and_collections()
    mats = create_pantanal_materials()

    layout = compute_board_layout()
    build_terrain_and_water(layout, sub_cols, mats)
    build_board_and_reserve(layout, sub_cols, mats)
    scatter_bank_vegetation(layout, sub_cols, mats)
    scatter_aquatic_plants(layout, sub_cols, mats)
    build_trees(layout, sub_cols, mats)
    build_fence_and_canoe(layout, sub_cols, mats)
    build_horror_details(layout, sub_cols, mats)

    setup_lighting_and_world(sub_cols)
    setup_camera(layout, sub_cols)

    render_outputs()
    write_readme()
    print("=================================================================")
    print("Construção e Renderização da Arena do Pantanal concluídas!")
    print("=================================================================")


def clamp(val, min_v, max_v):
    return max(min_v, min(max_v, val))

def lerp(a, b, t):
    return a + (b - a) * t


if __name__ == "__main__":
    main()
