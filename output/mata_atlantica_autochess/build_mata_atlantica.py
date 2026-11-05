"""
build_mata_atlantica.py
=======================
Agente Blender — Arena de Autochess na Mata Atlântica Noturna
Construção automatizada de ambiente 3D estilizado com acabamento pictórico sombrio
em Blender 5.2+ (bpy) com renderização Cycles.

Entregáveis gerados por este script:
- mata_atlantica_autochess_preview.png (960 x 540)
- mata_atlantica_autochess_final.png   (1920 x 1080)
- mata_atlantica_autochess.blend       (Cena organizada em MATA_ATLANTICA_ENV)
"""

import bpy
import bmesh
import math
import os
import random
from mathutils import Vector, Euler, Matrix

# ==============================================================================
# 4. PARÂMETROS CONFIGURÁVEIS (Configuração Única Centralizada)
# ==============================================================================
CONFIG = {
    "scene_name": "MataAtlantica_Autochess",
    "unit_system": "METRIC",
    "vertical_axis": "Z",
    "front_direction": "-Y",
    "back_direction": "+Y",
    "hex_columns": 8,
    "hex_rows": 8,
    "hex_radius": 0.65,           # 0,65 m (ponta para cima)
    "groove_width": 0.026,        # Sulcos rasos entre 0,015 e 0,03 m
    "groove_depth": 0.014,        # Profundidade visual entre 0,005 e 0,015 m
    "reserve_slots": 9,
    "reserve_gap": 0.85,          # Intervalo entre o combate e a reserva frontal (Y negativo)
    "reserve_slot_width": 0.86,
    "reserve_slot_depth": 0.82,
    "exclusion_margin": 0.60,     # Margem de segurança >= 0,5 m ao redor do conjunto jogável
    "random_seed": 42,
    "aspect_ratio": (16, 9),
    "preview_resolution": (960, 540),
    "final_resolution": (1920, 1080),
    "preview_samples": 36,
    "final_samples": 112,
    "output_dir": os.path.abspath(os.path.dirname(__file__))
        if "__file__" in globals() else os.path.abspath("output/mata_atlantica_autochess"),
}

SUBCOLLECTION_NAMES = [
    "00_CONTROLS",
    "01_TERRAIN",
    "02_BOARD",
    "03_RESERVE",
    "04_TREES",
    "05_CANOPY",
    "06_UNDERGROWTH",
    "07_ROOTS_AND_VINES",
    "08_STREAM_AND_ROCKS",
    "09_HORROR_DETAILS",
    "10_LIGHTS",
    "11_CAMERAS",
]


# ==============================================================================
# FUNÇÕES UTILITÁRIAS E DE LIMPEZA SEGURA (Restrita a MATA_ATLANTICA_ENV)
# ==============================================================================
def ensure_output_dir():
    out_dir = CONFIG["output_dir"]
    os.makedirs(out_dir, exist_ok=True)
    return out_dir


def setup_scene_and_collections():
    """
    Etapa 1: Inspeciona a cena existente, preserva objetos externos e recria
    apenas a hierarquia da coleção principal MATA_ATLANTICA_ENV para evitar duplicações.
    """
    scene = bpy.context.scene
    scene.name = CONFIG["scene_name"]
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1.0

    for obj in scene.objects:
        if not any(col.name.startswith("MATA_ATLANTICA_ENV") or col.name in SUBCOLLECTION_NAMES for col in obj.users_collection):
            obj.hide_render = True
            obj.hide_viewport = True

    existing_main = bpy.data.collections.get("MATA_ATLANTICA_ENV")
    if existing_main:
        objs_to_remove = set()
        def _collect_objs(col):
            for o in col.objects:
                objs_to_remove.add(o)
            for child_col in col.children:
                _collect_objs(child_col)
        _collect_objs(existing_main)
        for o in objs_to_remove:
            bpy.data.objects.remove(o, do_unlink=True)
        for sub_name in SUBCOLLECTION_NAMES:
            sub_col = bpy.data.collections.get(sub_name)
            if sub_col:
                bpy.data.collections.remove(sub_col)
        bpy.data.collections.remove(existing_main)

    main_col = bpy.data.collections.new("MATA_ATLANTICA_ENV")
    scene.collection.children.link(main_col)

    sub_cols = {}
    for sub_name in SUBCOLLECTION_NAMES:
        sc = bpy.data.collections.new(sub_name)
        main_col.children.link(sc)
        sub_cols[sub_name] = sc

    return scene, main_col, sub_cols


def link_to_collection(obj, target_col):
    for col in list(obj.users_collection):
        col.objects.unlink(obj)
    target_col.objects.link(obj)


# ==============================================================================
# CÁLCULO GEOMÉTRICO DO TABULEIRO, RIACHO E MÁSCARA DE EXCLUSÃO
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
    center_y = 0.5 * (min_y + max_y) - 0.55

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
    board_min_y = (min_y - center_y) - R
    board_max_y = (max_y - center_y) + R

    n_res = CONFIG["reserve_slots"]
    slot_w = CONFIG["reserve_slot_width"]
    slot_d = CONFIG["reserve_slot_depth"]
    slot_pitch = slot_w + 0.12
    reserve_y = board_min_y - CONFIG["reserve_gap"] - slot_d * 0.5

    reserve_slots = []
    for idx in range(n_res):
        sx = (idx - (n_res - 1) * 0.5) * slot_pitch
        reserve_slots.append({
            "index": idx,
            "x": sx,
            "y": reserve_y,
            "w": slot_w,
            "d": slot_d,
        })

    playable_min_x = min(board_min_x, reserve_slots[0]["x"] - slot_w * 0.6)
    playable_max_x = max(board_max_x, reserve_slots[-1]["x"] + slot_w * 0.6)
    playable_min_y = reserve_y - slot_d * 0.65
    playable_max_y = board_max_y

    return {
        "hex_cells": hex_cells,
        "reserve_slots": reserve_slots,
        "board_bounds": (board_min_x, board_max_x, board_min_y, board_max_y),
        "playable_bounds": (playable_min_x, playable_max_x, playable_min_y, playable_max_y),
        "reserve_y": reserve_y,
    }


def stream_center_x_at(y, layout):
    p_min_x, _, _, _ = layout["playable_bounds"]
    base_x = p_min_x - 1.85
    meander = 0.45 * math.sin(y * 0.46 + 0.4) + 0.18 * math.cos(y * 0.92 - 0.3)
    return base_x + meander


def stream_half_width_at(y):
    return 0.74 + 0.16 * math.sin(y * 0.68 + 0.9)


def is_in_exclusion_zone(x, y, layout, extra_radius=0.0):
    p_min_x, p_max_x, p_min_y, p_max_y = layout["playable_bounds"]
    margin = CONFIG["exclusion_margin"] + extra_radius

    if (p_min_x - margin) <= x <= (p_max_x + margin) and (p_min_y - margin) <= y <= (p_max_y + margin):
        return True

    if y < (p_min_y + 0.45):
        t_cam = max(0.0, (p_min_y - y) / 10.0)
        corridor_half_w = (p_max_x + 0.25 + extra_radius) + t_cam * 1.95
        if abs(x) <= corridor_half_w:
            return True

    return False


# ==============================================================================
# 17. MATERIAIS E DIREÇÃO VISUAL (Procedurais Nativos de Alta Riqueza Tátil)
# ==============================================================================
def create_materials():
    mats = {}

    def _new_mat(name):
        m = bpy.data.materials.get(name)
        if m:
            bpy.data.materials.remove(m)
        m = bpy.data.materials.new(name=name)
        return m

    # 1. Solo Florestal Úmido (Terra orgânica escura, húmus, manchas de musgo e lama)
    m_soil = _new_mat("Mat_Terrain_WetForestSoil")
    nt = m_soil.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = nodes.get("Principled BSDF")
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.26

    tc = nodes.new("ShaderNodeTexCoord")
    noise_macro = nodes.new("ShaderNodeTexNoise")
    noise_macro.inputs["Scale"].default_value = 1.65
    noise_macro.inputs["Detail"].default_value = 8.0
    noise_macro.inputs["Roughness"].default_value = 0.74
    links.new(tc.outputs["Object"], noise_macro.inputs["Vector"])

    noise_micro = nodes.new("ShaderNodeTexNoise")
    noise_micro.inputs["Scale"].default_value = 8.5
    noise_micro.inputs["Detail"].default_value = 6.0
    noise_micro.inputs["Roughness"].default_value = 0.68
    links.new(tc.outputs["Object"], noise_micro.inputs["Vector"])

    mix_soil = nodes.new("ShaderNodeMath")
    mix_soil.operation = 'MULTIPLY'
    links.new(noise_macro.outputs["Fac"], mix_soil.inputs[0])
    links.new(noise_micro.outputs["Fac"], mix_soil.inputs[1])

    ramp_soil = nodes.new("ShaderNodeValToRGB")
    ramp_soil.color_ramp.elements[0].position = 0.14
    ramp_soil.color_ramp.elements[0].color = (0.045, 0.030, 0.020, 1.0)  # Húmus escuro encharcado
    e_s1 = ramp_soil.color_ramp.elements.new(0.45)
    e_s1.color = (0.108, 0.074, 0.046, 1.0)                              # Terra marrom-escura úmida
    e_s2 = ramp_soil.color_ramp.elements.new(0.72)
    e_s2.color = (0.064, 0.096, 0.044, 1.0)                              # Musgo rasteiro escuro
    ramp_soil.color_ramp.elements[3].position = 0.90
    ramp_soil.color_ramp.elements[3].color = (0.092, 0.138, 0.058, 1.0)  # Musgo úmido localizado
    links.new(mix_soil.outputs["Value"], ramp_soil.inputs["Fac"])
    links.new(ramp_soil.outputs["Color"], bsdf.inputs["Base Color"])

    ramp_rough = nodes.new("ShaderNodeValToRGB")
    ramp_rough.color_ramp.elements[0].position = 0.22
    ramp_rough.color_ramp.elements[0].color = (0.38, 0.38, 0.38, 1.0)
    ramp_rough.color_ramp.elements[1].position = 0.78
    ramp_rough.color_ramp.elements[1].color = (0.86, 0.86, 0.86, 1.0)
    links.new(noise_macro.outputs["Fac"], ramp_rough.inputs["Fac"])
    links.new(ramp_rough.outputs["Color"], bsdf.inputs["Roughness"])

    bump_soil = nodes.new("ShaderNodeBump")
    bump_soil.inputs["Strength"].default_value = 0.34
    bump_soil.inputs["Distance"].default_value = 0.025
    links.new(noise_micro.outputs["Fac"], bump_soil.inputs["Height"])
    links.new(bump_soil.outputs["Normal"], bsdf.inputs["Normal"])
    mats["terrain"] = m_soil

    # 2. Superfície Interna das Casas Hexagonais
    m_hex = _new_mat("Mat_Board_HexWetEarth")
    nt = m_hex.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_h = nodes.get("Principled BSDF")
    if "Specular IOR Level" in bsdf_h.inputs:
        bsdf_h.inputs["Specular IOR Level"].default_value = 0.25

    obj_info = nodes.new("ShaderNodeObjectInfo")
    tc_h = nodes.new("ShaderNodeTexCoord")

    noise_h = nodes.new("ShaderNodeTexNoise")
    noise_h.inputs["Scale"].default_value = 4.2
    noise_h.inputs["Detail"].default_value = 7.0
    noise_h.inputs["Roughness"].default_value = 0.68
    links.new(tc_h.outputs["Object"], noise_h.inputs["Vector"])

    mix_var = nodes.new("ShaderNodeMath")
    mix_var.operation = 'ADD'
    links.new(noise_h.outputs["Fac"], mix_var.inputs[0])

    mult_rand = nodes.new("ShaderNodeMath")
    mult_rand.operation = 'MULTIPLY'
    mult_rand.inputs[1].default_value = 0.24
    links.new(obj_info.outputs["Random"], mult_rand.inputs[0])
    links.new(mult_rand.outputs["Value"], mix_var.inputs[1])

    ramp_h = nodes.new("ShaderNodeValToRGB")
    ramp_h.color_ramp.elements[0].position = 0.20
    ramp_h.color_ramp.elements[0].color = (0.145, 0.098, 0.066, 1.0)
    e_h1 = ramp_h.color_ramp.elements.new(0.52)
    e_h1.color = (0.215, 0.152, 0.102, 1.0)
    ramp_h.color_ramp.elements[2].position = 0.86
    ramp_h.color_ramp.elements[2].color = (0.265, 0.192, 0.132, 1.0)
    links.new(mix_var.outputs["Value"], ramp_h.inputs["Fac"])
    links.new(ramp_h.outputs["Color"], bsdf_h.inputs["Base Color"])

    ramp_hr = nodes.new("ShaderNodeValToRGB")
    ramp_hr.color_ramp.elements[0].position = 0.25
    ramp_hr.color_ramp.elements[0].color = (0.45, 0.45, 0.45, 1.0)
    ramp_hr.color_ramp.elements[1].position = 0.80
    ramp_hr.color_ramp.elements[1].color = (0.78, 0.78, 0.78, 1.0)
    links.new(noise_h.outputs["Fac"], ramp_hr.inputs["Fac"])
    links.new(ramp_hr.outputs["Color"], bsdf_h.inputs["Roughness"])

    bump_h = nodes.new("ShaderNodeBump")
    bump_h.inputs["Strength"].default_value = 0.22
    bump_h.inputs["Distance"].default_value = 0.015
    links.new(noise_h.outputs["Fac"], bump_h.inputs["Height"])
    links.new(bump_h.outputs["Normal"], bsdf_h.inputs["Normal"])
    mats["hex_surface"] = m_hex

    m_rim = _new_mat("Mat_Board_HexRim")
    bsdf_rm = m_rim.node_tree.nodes.get("Principled BSDF")
    bsdf_rm.inputs["Base Color"].default_value = (0.24, 0.175, 0.122, 1.0)
    bsdf_rm.inputs["Roughness"].default_value = 0.55
    mats["hex_rim"] = m_rim

    # 3. Sulcos das Casas e da Reserva
    m_groove = _new_mat("Mat_Board_DarkGroove")
    bsdf_g = m_groove.node_tree.nodes.get("Principled BSDF")
    bsdf_g.inputs["Base Color"].default_value = (0.022, 0.018, 0.014, 1.0)
    bsdf_g.inputs["Roughness"].default_value = 0.40
    mats["groove"] = m_groove

    # 4. Superfície da Reserva Frontal
    m_res = m_hex.copy()
    m_res.name = "Mat_Reserve_SlotWetEarth"
    mats["reserve_surface"] = m_res

    # 5. Casca de Árvore Úmida com Musgo Localizado (Maioria casca marrom-escura e manchas localizadas de musgo)
    m_bark = _new_mat("Mat_Tree_WetBarkMoss")
    nt = m_bark.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_b = nodes.get("Principled BSDF")
    if "Specular IOR Level" in bsdf_b.inputs:
        bsdf_b.inputs["Specular IOR Level"].default_value = 0.22

    tc_b = nodes.new("ShaderNodeTexCoord")
    map_b = nodes.new("ShaderNodeMapping")
    map_b.inputs["Scale"].default_value = (3.5, 3.5, 0.70)
    links.new(tc_b.outputs["Object"], map_b.inputs["Vector"])

    noise_b = nodes.new("ShaderNodeTexNoise")
    noise_b.inputs["Scale"].default_value = 5.5
    noise_b.inputs["Detail"].default_value = 8.0
    noise_b.inputs["Roughness"].default_value = 0.74
    links.new(map_b.outputs["Vector"], noise_b.inputs["Vector"])

    ramp_b = nodes.new("ShaderNodeValToRGB")
    ramp_b.color_ramp.elements[0].position = 0.22
    ramp_b.color_ramp.elements[0].color = (0.048, 0.034, 0.024, 1.0)     # Casca molhada escura
    e_b1 = ramp_b.color_ramp.elements.new(0.58)
    e_b1.color = (0.125, 0.088, 0.062, 1.0)                              # Casca marrom-acinzentada natural
    e_b2 = ramp_b.color_ramp.elements.new(0.76)
    e_b2.color = (0.072, 0.122, 0.052, 1.0)                              # Mancha localizada de musgo
    ramp_b.color_ramp.elements[3].position = 0.92
    ramp_b.color_ramp.elements[3].color = (0.105, 0.165, 0.072, 1.0)     # Musgo úmido localizado
    links.new(noise_b.outputs["Fac"], ramp_b.inputs["Fac"])
    links.new(ramp_b.outputs["Color"], bsdf_b.inputs["Base Color"])

    bsdf_b.inputs["Roughness"].default_value = 0.72
    bump_b = nodes.new("ShaderNodeBump")
    bump_b.inputs["Strength"].default_value = 0.42
    bump_b.inputs["Distance"].default_value = 0.028
    links.new(noise_b.outputs["Fac"], bump_b.inputs["Height"])
    links.new(bump_b.outputs["Normal"], bsdf_b.inputs["Normal"])
    mats["bark_moss"] = m_bark

    # 6. Folhagem Densa de Copa e Galhos Folhosos (Sem aspecto plástico)
    m_canopy = _new_mat("Mat_Canopy_WetFoliage")
    nt = m_canopy.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_cp = nodes.get("Principled BSDF")
    bsdf_cp.inputs["Roughness"].default_value = 0.56
    if "Specular IOR Level" in bsdf_cp.inputs:
        bsdf_cp.inputs["Specular IOR Level"].default_value = 0.25
    noise_cp = nodes.new("ShaderNodeTexNoise")
    noise_cp.inputs["Scale"].default_value = 4.5
    noise_cp.inputs["Detail"].default_value = 6.0
    ramp_cp = nodes.new("ShaderNodeValToRGB")
    ramp_cp.color_ramp.elements[0].position = 0.20
    ramp_cp.color_ramp.elements[0].color = (0.025, 0.058, 0.030, 1.0)
    e_cp = ramp_cp.color_ramp.elements.new(0.55)
    e_cp.color = (0.055, 0.118, 0.058, 1.0)
    ramp_cp.color_ramp.elements[2].position = 0.88
    ramp_cp.color_ramp.elements[2].color = (0.095, 0.175, 0.085, 1.0)
    links.new(noise_cp.outputs["Fac"], ramp_cp.inputs["Fac"])
    links.new(ramp_cp.outputs["Color"], bsdf_cp.inputs["Base Color"])
    bump_cp = nodes.new("ShaderNodeBump")
    bump_cp.inputs["Strength"].default_value = 0.28
    bump_cp.inputs["Distance"].default_value = 0.02
    links.new(noise_cp.outputs["Fac"], bump_cp.inputs["Height"])
    links.new(bump_cp.outputs["Normal"], bsdf_cp.inputs["Normal"])
    mats["canopy_foliage"] = m_canopy

    # 7. Samambaias e Folhas Largas Úmidas
    m_fern = _new_mat("Mat_Undergrowth_WetFern")
    nt = m_fern.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_fn = nodes.get("Principled BSDF")
    bsdf_fn.inputs["Roughness"].default_value = 0.36
    if "Specular IOR Level" in bsdf_fn.inputs:
        bsdf_fn.inputs["Specular IOR Level"].default_value = 0.42
    obj_fn = nodes.new("ShaderNodeObjectInfo")
    ramp_fn = nodes.new("ShaderNodeValToRGB")
    ramp_fn.color_ramp.elements[0].position = 0.0
    ramp_fn.color_ramp.elements[0].color = (0.048, 0.118, 0.052, 1.0)
    e_fn = ramp_fn.color_ramp.elements.new(0.5)
    e_fn.color = (0.082, 0.175, 0.075, 1.0)
    ramp_fn.color_ramp.elements[2].position = 1.0
    ramp_fn.color_ramp.elements[2].color = (0.125, 0.225, 0.098, 1.0)
    links.new(obj_fn.outputs["Random"], ramp_fn.inputs["Fac"])
    links.new(ramp_fn.outputs["Color"], bsdf_fn.inputs["Base Color"])
    mats["fern"] = m_fern

    m_broad = _new_mat("Mat_Undergrowth_WetBroadleaf")
    nt = m_broad.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_bl = nodes.get("Principled BSDF")
    bsdf_bl.inputs["Roughness"].default_value = 0.28
    if "Specular IOR Level" in bsdf_bl.inputs:
        bsdf_bl.inputs["Specular IOR Level"].default_value = 0.50
    noise_bl = nodes.new("ShaderNodeTexNoise")
    noise_bl.inputs["Scale"].default_value = 5.5
    ramp_bl = nodes.new("ShaderNodeValToRGB")
    ramp_bl.color_ramp.elements[0].position = 0.20
    ramp_bl.color_ramp.elements[0].color = (0.038, 0.098, 0.048, 1.0)
    ramp_bl.color_ramp.elements[1].position = 0.82
    ramp_bl.color_ramp.elements[1].color = (0.098, 0.205, 0.102, 1.0)
    links.new(noise_bl.outputs["Fac"], ramp_bl.inputs["Fac"])
    links.new(ramp_bl.outputs["Color"], bsdf_bl.inputs["Base Color"])
    mats["broadleaf"] = m_broad

    # 8. Bromélias
    m_brom = _new_mat("Mat_Undergrowth_Bromeliad")
    bsdf_br = m_brom.node_tree.nodes.get("Principled BSDF")
    bsdf_br.inputs["Base Color"].default_value = (0.078, 0.158, 0.062, 1.0)
    bsdf_br.inputs["Roughness"].default_value = 0.36
    mats["bromeliad"] = m_brom

    m_brom_core = _new_mat("Mat_Undergrowth_BromeliadBract")
    bsdf_brc = m_brom_core.node_tree.nodes.get("Principled BSDF")
    bsdf_brc.inputs["Base Color"].default_value = (0.28, 0.072, 0.052, 1.0)
    bsdf_brc.inputs["Roughness"].default_value = 0.38
    mats["bromeliad_bract"] = m_brom_core

    # 9. Serrapilheira / Folhas Mortas Úmidas no Solo
    m_deadleaf = _new_mat("Mat_Undergrowth_FallenDeadLeaves")
    nt = m_deadleaf.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_dl = nodes.get("Principled BSDF")
    bsdf_dl.inputs["Roughness"].default_value = 0.52
    obj_dl = nodes.new("ShaderNodeObjectInfo")
    ramp_dl = nodes.new("ShaderNodeValToRGB")
    ramp_dl.color_ramp.elements[0].position = 0.0
    ramp_dl.color_ramp.elements[0].color = (0.10, 0.062, 0.034, 1.0)
    e_dl = ramp_dl.color_ramp.elements.new(0.5)
    e_dl.color = (0.165, 0.102, 0.052, 1.0)
    ramp_dl.color_ramp.elements[2].position = 1.0
    ramp_dl.color_ramp.elements[2].color = (0.22, 0.142, 0.072, 1.0)
    links.new(obj_dl.outputs["Random"], ramp_dl.inputs["Fac"])
    links.new(ramp_dl.outputs["Color"], bsdf_dl.inputs["Base Color"])
    mats["fallen_leaves"] = m_deadleaf

    # 10. Pedras Musgosas e Líquens Amarelados da Serra do Mar
    m_rock = _new_mat("Mat_Stream_MossyWetRock")
    nt = m_rock.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_rk = nodes.get("Principled BSDF")
    if "Specular IOR Level" in bsdf_rk.inputs:
        bsdf_rk.inputs["Specular IOR Level"].default_value = 0.32

    tc_rk = nodes.new("ShaderNodeTexCoord")
    geom_rk = nodes.new("ShaderNodeNewGeometry")
    sep_rk = nodes.new("ShaderNodeSeparateXYZ")
    links.new(geom_rk.outputs["Normal"], sep_rk.inputs["Vector"])

    noise_rk = nodes.new("ShaderNodeTexNoise")
    noise_rk.inputs["Scale"].default_value = 4.5
    noise_rk.inputs["Detail"].default_value = 7.0
    links.new(tc_rk.outputs["Object"], noise_rk.inputs["Vector"])

    mix_rk = nodes.new("ShaderNodeMath")
    mix_rk.operation = 'ADD'
    links.new(sep_rk.outputs["Z"], mix_rk.inputs[0])
    links.new(noise_rk.outputs["Fac"], mix_rk.inputs[1])

    ramp_rk = nodes.new("ShaderNodeValToRGB")
    ramp_rk.color_ramp.elements[0].position = 0.48
    ramp_rk.color_ramp.elements[0].color = (0.048, 0.054, 0.060, 1.0)
    e_rk1 = ramp_rk.color_ramp.elements.new(0.88)
    e_rk1.color = (0.088, 0.098, 0.102, 1.0)
    e_rk2 = ramp_rk.color_ramp.elements.new(1.18)
    e_rk2.color = (0.062, 0.125, 0.048, 1.0)
    ramp_rk.color_ramp.elements[3].position = 1.48
    ramp_rk.color_ramp.elements[3].color = (0.195, 0.205, 0.075, 1.0)
    links.new(mix_rk.outputs["Value"], ramp_rk.inputs["Fac"])
    links.new(ramp_rk.outputs["Color"], bsdf_rk.inputs["Base Color"])

    bsdf_rk.inputs["Roughness"].default_value = 0.48
    bump_rk = nodes.new("ShaderNodeBump")
    bump_rk.inputs["Strength"].default_value = 0.38
    bump_rk.inputs["Distance"].default_value = 0.025
    links.new(noise_rk.outputs["Fac"], bump_rk.inputs["Height"])
    links.new(bump_rk.outputs["Normal"], bsdf_rk.inputs["Normal"])
    mats["rock_mossy"] = m_rock

    # 11. Água Escura e Semi-Opaca do Riacho
    m_water = _new_mat("Mat_Stream_DarkWater")
    nt = m_water.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_w = nodes.get("Principled BSDF")
    bsdf_w.inputs["Base Color"].default_value = (0.015, 0.028, 0.025, 1.0)
    bsdf_w.inputs["Roughness"].default_value = 0.10
    if "Specular IOR Level" in bsdf_w.inputs:
        bsdf_w.inputs["Specular IOR Level"].default_value = 0.68
    if "Transmission Weight" in bsdf_w.inputs:
        bsdf_w.inputs["Transmission Weight"].default_value = 0.20

    tc_w = nodes.new("ShaderNodeTexCoord")
    map_w = nodes.new("ShaderNodeMapping")
    map_w.inputs["Scale"].default_value = (4.2, 1.5, 1.0)
    links.new(tc_w.outputs["Object"], map_w.inputs["Vector"])

    noise_w = nodes.new("ShaderNodeTexNoise")
    noise_w.inputs["Scale"].default_value = 7.5
    noise_w.inputs["Detail"].default_value = 6.0
    noise_w.inputs["Roughness"].default_value = 0.58
    links.new(map_w.outputs["Vector"], noise_w.inputs["Vector"])

    bump_w = nodes.new("ShaderNodeBump")
    bump_w.inputs["Strength"].default_value = 0.24
    bump_w.inputs["Distance"].default_value = 0.015
    links.new(noise_w.outputs["Fac"], bump_w.inputs["Height"])
    links.new(bump_w.outputs["Normal"], bsdf_w.inputs["Normal"])
    mats["stream_water"] = m_water

    # 12. Lama Escura de Pegadas e Trilha (Horror A e C)
    m_mud = _new_mat("Mat_Horror_DarkMud")
    bsdf_md = m_mud.node_tree.nodes.get("Principled BSDF")
    bsdf_md.inputs["Base Color"].default_value = (0.028, 0.019, 0.013, 1.0)
    bsdf_md.inputs["Roughness"].default_value = 0.24
    mats["dark_mud"] = m_mud

    # 13. Tecido Desbotado e Manchado de Barro (Vestígio humano discreto — Seção 16)
    m_cloth = _new_mat("Mat_Horror_FadedCloth")
    nt = m_cloth.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_cl = nodes.get("Principled BSDF")
    bsdf_cl.inputs["Roughness"].default_value = 0.88
    noise_cl = nodes.new("ShaderNodeTexNoise")
    noise_cl.inputs["Scale"].default_value = 5.0
    ramp_cl = nodes.new("ShaderNodeValToRGB")
    ramp_cl.color_ramp.elements[0].position = 0.25
    ramp_cl.color_ramp.elements[0].color = (0.14, 0.11, 0.085, 1.0)
    ramp_cl.color_ramp.elements[1].position = 0.78
    ramp_cl.color_ramp.elements[1].color = (0.34, 0.31, 0.26, 1.0)
    links.new(noise_cl.outputs["Fac"], ramp_cl.inputs["Fac"])
    links.new(ramp_cl.outputs["Color"], bsdf_cl.inputs["Base Color"])
    mats["faded_cloth"] = m_cloth

    # 14. Feixes Volumétricos Sutis de Luar Filtrado pela Copa
    m_beam = _new_mat("Mat_Canopy_MoonbeamShaft")
    if hasattr(m_beam, "blend_method"):
        m_beam.blend_method = 'BLEND'
    nt = m_beam.node_tree
    nodes, links = nt.nodes, nt.links
    nodes.clear()
    out_bm = nodes.new("ShaderNodeOutputMaterial")
    transp = nodes.new("ShaderNodeBsdfTransparent")
    emiss = nodes.new("ShaderNodeEmission")
    emiss.inputs["Color"].default_value = (0.65, 0.80, 0.96, 1.0)
    emiss.inputs["Strength"].default_value = 0.065

    tc_bm = nodes.new("ShaderNodeTexCoord")
    sep_bm = nodes.new("ShaderNodeSeparateXYZ")
    links.new(tc_bm.outputs["Generated"], sep_bm.inputs["Vector"])

    sin_z = nodes.new("ShaderNodeMath")
    sin_z.operation = 'SINE'
    mult_pi = nodes.new("ShaderNodeMath")
    mult_pi.operation = 'MULTIPLY'
    mult_pi.inputs[1].default_value = math.pi
    links.new(sep_bm.outputs["Z"], mult_pi.inputs[0])
    links.new(mult_pi.outputs["Value"], sin_z.inputs[0])

    mult_alpha = nodes.new("ShaderNodeMath")
    mult_alpha.operation = 'MULTIPLY'
    mult_alpha.inputs[1].default_value = 0.05
    links.new(sin_z.outputs["Value"], mult_alpha.inputs[0])

    mix_sh = nodes.new("ShaderNodeMixShader")
    links.new(mult_alpha.outputs["Value"], mix_sh.inputs["Fac"])
    links.new(transp.outputs["BSDF"], mix_sh.inputs[1])
    links.new(emiss.outputs["Emission"], mix_sh.inputs[2])
    links.new(mix_sh.outputs["Shader"], out_bm.inputs["Surface"])
    mats["moonbeam"] = m_beam

    return mats


# ==============================================================================
# 7. TERRENO CONTÍNUO (Integra área jogável, leito do riacho e encosta da Serra do Mar)
# ==============================================================================
def terrain_height_at(x, y, layout):
    p_min_x, p_max_x, p_min_y, p_max_y = layout["playable_bounds"]

    dx = 0.0
    if x < p_min_x - 0.25:
        dx = (p_min_x - 0.25) - x
    elif x > p_max_x + 0.25:
        dx = x - (p_max_x + 0.25)

    dy = 0.0
    if y < p_min_y - 0.35:
        dy = (p_min_y - 0.35) - y
    elif y > p_max_y + 0.35:
        dy = y - (p_max_y + 0.35)

    dist_out = math.sqrt(dx * dx + dy * dy)
    if dist_out <= 0.001:
        return 0.0

    blend = min(1.0, dist_out / 3.2)
    smooth = blend * blend * (3.0 - 2.0 * blend)

    sc_x = stream_center_x_at(y, layout)
    sc_hw = stream_half_width_at(y)
    dist_stream = abs(x - sc_x)
    stream_cut = 0.0
    if dist_stream < sc_hw * 1.55 and x < (p_min_x - 0.35):
        t_st = max(0.0, 1.0 - (dist_stream / (sc_hw * 1.55)) ** 2)
        stream_cut = -0.32 * t_st * smooth

    if y < p_min_y:
        front_wave = 0.06 * math.sin(x * 0.38) * math.cos(y * 0.42)
        return smooth * max(-0.12, min(0.10, front_wave)) + stream_cut

    trail_factor = 1.0
    if y > p_max_y:
        trail_x = 0.55 * math.sin((y - p_max_y) * 0.36) + 0.25
        dist_trail = abs(x - trail_x)
        trail_factor = min(1.0, max(0.15, (dist_trail - 0.75) / 2.1))

    back_boost = 1.0 + max(0.0, (y - p_max_y) * 0.065)
    bank_rise = (min(dist_out, 15.0) ** 1.15) * 0.16 * trail_factor * back_boost
    undulation = (
        0.22 * math.sin(x * 0.30 + 0.5) * math.cos(y * 0.26)
        + 0.11 * math.sin(x * 0.62 - y * 0.48)
    ) * smooth * trail_factor

    return max(-0.34, bank_rise + undulation + stream_cut)


def build_continuous_terrain(sub_cols, layout, mats):
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=140, y_segments=140, size=38.0)

    for v in bm.verts:
        v.co.y += 8.0
        v.co.z = terrain_height_at(v.co.x, v.co.y, layout)

    mesh = bpy.data.meshes.new("Terrain_Main_Mesh")
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = True

    terrain_obj = bpy.data.objects.new("Terrain_Main", mesh)
    link_to_collection(terrain_obj, sub_cols["01_TERRAIN"])
    terrain_obj.data.materials.append(mats["terrain"])
    return terrain_obj


# ==============================================================================
# 8. GRADE HEXAGONAL (8x8, Ponta para Cima, Sulcos Rasos + Chanfro Tátil)
# ==============================================================================
def build_hex_board(sub_cols, layout, mats):
    R = CONFIG["hex_radius"]
    groove_w = CONFIG["groove_width"]
    groove_d = CONFIG["groove_depth"]
    rng = random.Random(CONFIG["random_seed"])

    for cell in layout["hex_cells"]:
        c = cell["col"]
        r = cell["row"]
        cx = cell["x"]
        cy = cell["y"]

        bm = bmesh.new()
        r_outer = R - 0.002
        r_groove_in = R - groove_w
        r_rim = R - groove_w * 1.55
        r_inner = R - groove_w * 2.35

        z_outer = 0.003
        z_groove = -groove_d
        z_rim = 0.011
        z_surface = 0.007 + rng.uniform(-0.0015, 0.0015)

        ring_out = []
        ring_grv = []
        ring_rim = []
        ring_in = []

        for k in range(6):
            ang = math.radians(30.0 + k * 60.0)
            wear = 1.0 - rng.uniform(0.0, 0.014)
            ca, sa = math.cos(ang), math.sin(ang)
            ring_out.append(bm.verts.new((ca * r_outer * wear, sa * r_outer * wear, z_outer)))
            ring_grv.append(bm.verts.new((ca * r_groove_in * wear, sa * r_groove_in * wear, z_groove)))
            ring_rim.append(bm.verts.new((ca * r_rim * wear, sa * r_rim * wear, z_rim)))
            ring_in.append(bm.verts.new((ca * r_inner * wear, sa * r_inner * wear, z_surface)))

        for k in range(6):
            k2 = (k + 1) % 6
            f_grv1 = bm.faces.new((ring_out[k], ring_out[k2], ring_grv[k2], ring_grv[k]))
            f_grv1.material_index = 1
            f_grv2 = bm.faces.new((ring_grv[k], ring_grv[k2], ring_rim[k2], ring_rim[k]))
            f_grv2.material_index = 1
            f_rim = bm.faces.new((ring_rim[k], ring_rim[k2], ring_in[k2], ring_in[k]))
            f_rim.material_index = 2

        f_top = bm.faces.new(ring_in)
        f_top.material_index = 0

        obj_name = f"Board_Hex_{r:02d}_{c:02d}"
        mesh = bpy.data.meshes.new(f"{obj_name}_Mesh")
        bm.to_mesh(mesh)
        bm.free()

        hex_obj = bpy.data.objects.new(obj_name, mesh)
        hex_obj.location = Vector((cx, cy, 0.0))
        hex_obj["grid_col"] = c
        hex_obj["grid_row"] = r
        hex_obj.data.materials.append(mats["hex_surface"])
        hex_obj.data.materials.append(mats["groove"])
        hex_obj.data.materials.append(mats["hex_rim"])
        link_to_collection(hex_obj, sub_cols["02_BOARD"])


# ==============================================================================
# 9. RESERVA FRONTAL (9 Posições no Lado Y Negativo, Integradas ao Solo Úmido)
# ==============================================================================
def build_reserve_slots(sub_cols, layout, mats):
    groove_w = CONFIG["groove_width"] * 1.15
    groove_d = CONFIG["groove_depth"]

    for slot in layout["reserve_slots"]:
        idx = slot["index"]
        sx = slot["x"]
        sy = slot["y"]
        hw = slot["w"] * 0.5
        hd = slot["d"] * 0.5

        bm = bmesh.new()
        corners_out = [(-hw, -hd), (hw, -hd), (hw, hd), (-hw, hd)]
        corners_grv = [
            (-(hw - groove_w), -(hd - groove_w)),
            ((hw - groove_w), -(hd - groove_w)),
            ((hw - groove_w), (hd - groove_w)),
            (-(hw - groove_w), (hd - groove_w)),
        ]
        corners_rim = [
            (-(hw - groove_w * 1.5), -(hd - groove_w * 1.5)),
            ((hw - groove_w * 1.5), -(hd - groove_w * 1.5)),
            ((hw - groove_w * 1.5), (hd - groove_w * 1.5)),
            (-(hw - groove_w * 1.5), (hd - groove_w * 1.5)),
        ]
        corners_in = [
            (-(hw - groove_w * 2.2), -(hd - groove_w * 2.2)),
            ((hw - groove_w * 2.2), -(hd - groove_w * 2.2)),
            ((hw - groove_w * 2.2), (hd - groove_w * 2.2)),
            (-(hw - groove_w * 2.2), (hd - groove_w * 2.2)),
        ]

        v_out = [bm.verts.new((x, y, 0.003)) for x, y in corners_out]
        v_grv = [bm.verts.new((x, y, -groove_d)) for x, y in corners_grv]
        v_rim = [bm.verts.new((x, y, 0.010)) for x, y in corners_rim]
        v_in = [bm.verts.new((x, y, 0.006)) for x, y in corners_in]

        for k in range(4):
            k2 = (k + 1) % 4
            fg1 = bm.faces.new((v_out[k], v_out[k2], v_grv[k2], v_grv[k]))
            fg1.material_index = 1
            fg2 = bm.faces.new((v_grv[k], v_grv[k2], v_rim[k2], v_rim[k]))
            fg2.material_index = 1
            fr = bm.faces.new((v_rim[k], v_rim[k2], v_in[k2], v_in[k]))
            fr.material_index = 2

        ft = bm.faces.new(v_in)
        ft.material_index = 0

        slot_name = f"Reserve_Slot_{idx:02d}"
        mesh = bpy.data.meshes.new(f"{slot_name}_Mesh")
        bm.to_mesh(mesh)
        bm.free()

        slot_obj = bpy.data.objects.new(slot_name, mesh)
        slot_obj.location = Vector((sx, sy, 0.0))
        slot_obj["reserve_index"] = idx
        slot_obj.data.materials.append(mats["reserve_surface"])
        slot_obj.data.materials.append(mats["groove"])
        slot_obj.data.materials.append(mats["hex_rim"])
        link_to_collection(slot_obj, sub_cols["03_RESERVE"])


# ==============================================================================
# 11. ÁRVORES DA MATA ATLÂNTICA (5 Variantes Botânicas Sem Esferas de Copa)
# ==============================================================================
def _add_tube_branch(bm, pts, radii, segments=7, mat_idx=0):
    rings = []
    for i, pt in enumerate(pts):
        p = Vector(pt)
        if i == 0:
            tangent = (Vector(pts[1]) - p).normalized()
        elif i == len(pts) - 1:
            tangent = (p - Vector(pts[i - 1])).normalized()
        else:
            tangent = (Vector(pts[i + 1]) - Vector(pts[i - 1])).normalized()
        up = Vector((0.0, 0.0, 1.0)) if abs(tangent.z) < 0.92 else Vector((1.0, 0.0, 0.0))
        side = tangent.cross(up).normalized()
        binorm = side.cross(tangent).normalized()
        r = radii[i]
        ring = []
        for s in range(segments):
            ang = (s / float(segments)) * math.pi * 2.0
            ca, sa = math.cos(ang), math.sin(ang)
            flute = 1.0 + (0.24 * math.cos(ang * 4.0) if i <= 1 else 0.06 * math.sin(ang * 3.0))
            v_pos = p + (side * ca + binorm * sa) * (r * flute)
            ring.append(bm.verts.new(v_pos))
        rings.append(ring)

    for i in range(len(rings) - 1):
        r0, r1 = rings[i], rings[i + 1]
        for s in range(segments):
            s2 = (s + 1) % segments
            f = bm.faces.new((r0[s], r0[s2], r1[s2], r1[s]))
            f.material_index = mat_idx

    top_ring = rings[-1]
    tip_center = sum((v.co for v in top_ring), Vector((0.0, 0.0, 0.0))) / float(len(top_ring))
    v_tip = bm.verts.new(tip_center + Vector((0.0, 0.0, 0.04)))
    for s in range(segments):
        s2 = (s + 1) % segments
        f = bm.faces.new((top_ring[s], top_ring[s2], v_tip))
        f.material_index = mat_idx


def _add_leafy_bough_cluster(bm, center, spread_r, z_span, n_boughs=14, mat_idx=1, seed_val=7):
    """
    Constrói copa botânica de ramos folhosos arqueados (sem esferas ou blocos),
    gerando silhueta recortada autêntica de folhas tropicais.
    """
    rng = random.Random(seed_val)
    cx, cy, cz = center
    for b_i in range(n_boughs):
        ang = (b_i / float(n_boughs)) * math.pi * 2.0 + rng.uniform(-0.25, 0.25)
        ca, sa = math.cos(ang), math.sin(ang)
        px, py = -sa, ca
        length = spread_r * rng.uniform(0.75, 1.25)
        z_off = rng.uniform(-z_span * 0.45, z_span * 0.45)
        arch = rng.uniform(0.18, 0.42)
        w_max = rng.uniform(0.28, 0.46)
        segs = 4
        prev_pair = None
        for s in range(segs + 1):
            t = s / float(segs)
            dist = t * length
            z = cz + z_off + math.sin(t * math.pi * 0.78) * arch - (t ** 2) * 0.28
            w = w_max * math.sin(max(0.08, t) * math.pi)
            vl = bm.verts.new((cx + ca * dist - px * w, cy + sa * dist - py * w, z))
            vr = bm.verts.new((cx + ca * dist + px * w, cy + sa * dist + py * w, z + 0.03))
            if prev_pair:
                f = bm.faces.new((prev_pair[0], prev_pair[1], vr, vl))
                f.material_index = mat_idx
            prev_pair = (vl, vr)


def create_atlantic_tree_mesh(variant_letter, seed_offset, mats):
    rng = random.Random(CONFIG["random_seed"] + seed_offset)
    bm = bmesh.new()

    if variant_letter == "A":
        # Figueira centenária com sapopemas e galhos altos ramificados
        pts = [
            (0.0, 0.0, -0.25),
            (0.05, -0.04, 1.5),
            (0.14, 0.08, 3.4),
            (0.06, 0.16, 5.6),
            (-0.08, 0.12, 8.2),
        ]
        radii = [0.68, 0.44, 0.36, 0.28, 0.16]
        _add_tube_branch(bm, pts, radii, segments=9, mat_idx=0)
        for k in range(5):
            ang = k * (math.pi * 0.4) + rng.uniform(-0.18, 0.18)
            ca, sa = math.cos(ang), math.sin(ang)
            r_pts = [
                (ca * 0.22, sa * 0.22, 1.65),
                (ca * 0.72, sa * 0.72, 0.48),
                (ca * 1.38, sa * 1.38, -0.08),
            ]
            _add_tube_branch(bm, r_pts, [0.17, 0.13, 0.05], segments=6, mat_idx=0)
        for b in range(4):
            ang = b * (math.pi * 0.5) + 0.4
            ca, sa = math.cos(ang), math.sin(ang)
            b_pts = [
                (0.06, 0.12, 4.6 + b * 0.65),
                (ca * 1.35, sa * 1.35, 5.8 + b * 0.55),
                (ca * 2.45, sa * 2.45, 6.8 + b * 0.45),
            ]
            _add_tube_branch(bm, b_pts, [0.20, 0.13, 0.05], segments=6, mat_idx=0)
            _add_leafy_bough_cluster(bm, b_pts[-1], 1.55, 0.75, n_boughs=14, mat_idx=1, seed_val=seed_offset + b)

    elif variant_letter == "B":
        # Pau-Brasil nodoso
        pts = [
            (0.0, 0.0, -0.20),
            (-0.12, 0.08, 1.5),
            (0.18, -0.10, 3.2),
            (-0.08, 0.16, 5.0),
            (0.15, 0.05, 7.0),
        ]
        radii = [0.46, 0.34, 0.28, 0.22, 0.12]
        _add_tube_branch(bm, pts, radii, segments=8, mat_idx=0)
        for b in range(3):
            ang = b * 2.1 + 0.2
            ca, sa = math.cos(ang), math.sin(ang)
            b_pts = [
                (0.0, 0.0, 4.0 + b * 0.75),
                (ca * 1.15, sa * 1.15, 5.1 + b * 0.65),
                (ca * 2.05, sa * 2.05, 6.0 + b * 0.55),
            ]
            _add_tube_branch(bm, b_pts, [0.16, 0.10, 0.05], segments=6, mat_idx=0)
            _add_leafy_bough_cluster(bm, b_pts[-1], 1.35, 0.65, n_boughs=12, mat_idx=1, seed_val=seed_offset + b + 10)

    elif variant_letter == "C":
        # Palmito-Juçara (Euterpe edulis)
        pts = [
            (0.0, 0.0, -0.15),
            (0.06, 0.04, 1.3),
            (0.12, 0.07, 2.7),
            (0.18, 0.10, 4.0),
            (0.22, 0.12, 5.1),
        ]
        radii = [0.18, 0.14, 0.12, 0.10, 0.09]
        _add_tube_branch(bm, pts, radii, segments=7, mat_idx=0)
        top_x, top_y, top_z = pts[-1]
        for f_idx in range(11):
            ang = (f_idx / 11.0) * math.pi * 2.0 + rng.uniform(-0.12, 0.12)
            ca, sa = math.cos(ang), math.sin(ang)
            frond_len = rng.uniform(1.50, 2.00)
            segs_f = 6
            prev_pair = None
            for s in range(segs_f + 1):
                t = s / float(segs_f)
                r_dist = t * frond_len
                z_arch = math.sin(t * math.pi * 0.78) * 0.55 - (t ** 2) * 0.45
                fx = top_x + ca * r_dist
                fy = top_y + sa * r_dist
                fz = top_z + z_arch
                w_leaf = 0.25 * math.sin(max(0.05, t) * math.pi)
                px, py = -sa * w_leaf, ca * w_leaf
                v_l = bm.verts.new((fx - px, fy - py, fz))
                v_r = bm.verts.new((fx + px, fy + py, fz))
                if prev_pair:
                    f_leaf = bm.faces.new((prev_pair[0], prev_pair[1], v_r, v_l))
                    f_leaf.material_index = 1
                prev_pair = (v_l, v_r)

    elif variant_letter == "D":
        # Árvore inclinada de encosta com galhos folhosos
        pts = [
            (0.0, 0.0, -0.20),
            (0.26, 0.10, 1.4),
            (0.58, 0.22, 3.1),
            (0.88, 0.32, 4.9),
            (1.10, 0.38, 6.8),
        ]
        radii = [0.48, 0.35, 0.27, 0.20, 0.11]
        _add_tube_branch(bm, pts, radii, segments=8, mat_idx=0)
        for b in range(3):
            ang = b * 1.9 + 0.5
            ca, sa = math.cos(ang), math.sin(ang)
            b_pts = [
                (0.58, 0.22, 3.6 + b * 0.75),
                (0.78 + ca * 1.25, 0.28 + sa * 1.25, 4.7 + b * 0.65),
                (0.95 + ca * 2.05, 0.32 + sa * 2.05, 5.5 + b * 0.55),
            ]
            _add_tube_branch(bm, b_pts, [0.15, 0.10, 0.05], segments=6, mat_idx=0)
            _add_leafy_bough_cluster(bm, b_pts[-1], 1.40, 0.65, n_boughs=12, mat_idx=1, seed_val=seed_offset + b + 20)

    else:
        # Variante E: Par de troncos antigos entrelaçados
        for idx_s, t_side in enumerate((-1.0, 1.0)):
            pts = [
                (t_side * 0.28, 0.0, -0.20),
                (t_side * 0.12, t_side * 0.18, 1.6),
                (-t_side * 0.14, -t_side * 0.12, 3.5),
                (t_side * 0.22, t_side * 0.15, 5.4),
                (t_side * 0.42, 0.0, 7.2),
            ]
            radii = [0.38, 0.29, 0.23, 0.17, 0.10]
            _add_tube_branch(bm, pts, radii, segments=7, mat_idx=0)
            _add_leafy_bough_cluster(bm, (t_side * 0.85, 0.0, 7.2), 1.50, 0.75, n_boughs=14, mat_idx=1, seed_val=seed_offset + idx_s + 30)

    mesh = bpy.data.meshes.new(f"Tree_Variant_{variant_letter}_Mesh")
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = True
    mesh.materials.append(mats["bark_moss"])
    mesh.materials.append(mats["canopy_foliage"])
    return mesh


def build_trees_and_canopy(sub_cols, layout, mats):
    rng = random.Random(CONFIG["random_seed"] + 101)
    variants = ["A", "B", "C", "D", "E"]
    variant_meshes = {
        v: create_atlantic_tree_mesh(v, idx * 37, mats)
        for idx, v in enumerate(variants)
    }

    tree_placements = [
        # --- Moldura nos cantos frontais extremos (fora do corredor da câmera) ---
        ("A", -8.8, -5.0, 0.35, 1.15),
        ("D", -9.2, -1.8, -0.42, 1.10),
        ("A",  8.7, -4.8, 2.75, 1.14),
        ("B",  9.1, -1.6, 2.35, 1.08),

        # --- Camada 1: Borda imediata (flancos e fundo próximo) ---
        ("B", -8.2,  0.9, 0.25, 1.04),
        ("C", -7.5,  2.7, 1.10, 0.98),
        ("E", -6.8,  4.8, 0.65, 1.06),
        ("A", -4.5,  5.9, -0.35, 1.08),
        ("C", -2.2,  5.7, 0.80, 0.94),
        ("B",  2.3,  5.7, 1.95, 1.00),
        ("D",  4.7,  5.9, 2.40, 1.06),
        ("E",  6.4,  4.0, 2.85, 1.02),
        ("C",  6.2,  1.6, 1.65, 0.96),
        ("B",  6.4, -0.5, 2.15, 1.04),

        # --- Camada 2: Segundo plano ---
        ("A", -10.8, -0.6, 0.55, 1.20),
        ("D", -10.2,  3.2, 0.90, 1.16),
        ("B", -8.4,   6.6, 0.40, 1.14),
        ("E", -5.8,   7.9, 1.25, 1.14),
        ("C", -3.2,   7.5, 0.15, 1.04),
        ("C",  3.0,   7.6, 2.60, 1.04),
        ("A",  5.8,   8.1, 2.10, 1.18),
        ("B",  8.4,   6.3, 1.75, 1.12),
        ("D",  9.8,   2.5, 2.55, 1.16),
        ("E", 10.4,  -1.0, 1.90, 1.18),

        # --- Camada 3: Fundo denso (encosta da Serra do Mar) ---
        ("A", -12.5,  6.5, 0.20, 1.30),
        ("B", -10.0,  9.8, 1.10, 1.26),
        ("E", -7.2,  11.0, 0.75, 1.28),
        ("A", -4.0,  11.2, 1.45, 1.32),
        ("C", -1.6,  10.2, 0.30, 1.12),
        ("D",  1.8,  10.4, 2.20, 1.20),
        ("A",  4.6,  11.4, 1.85, 1.30),
        ("E",  7.6,  10.8, 2.65, 1.26),
        ("B", 10.8,   9.2, 1.50, 1.24),
        ("A", 12.6,   5.6, 2.40, 1.28),
    ]

    for idx, (v_let, tx, ty, rot_z, sc) in enumerate(tree_placements):
        if is_in_exclusion_zone(tx, ty, layout, extra_radius=0.80):
            continue
        tz = terrain_height_at(tx, ty, layout)
        t_obj = bpy.data.objects.new(f"Tree_Variant_{v_let}_{idx:02d}", variant_meshes[v_let])
        t_obj.location = Vector((tx, ty, tz))
        tilt_x = rng.uniform(-0.05, 0.05)
        tilt_y = rng.uniform(-0.05, 0.05)
        t_obj.rotation_euler = Euler((tilt_x, tilt_y, rot_z), 'XYZ')
        t_obj.scale = Vector((sc, sc, sc * rng.uniform(0.95, 1.06)))
        link_to_collection(t_obj, sub_cols["04_TREES"])

    # --- 05_CANOPY: Ramos folhosos elevados de mata fechada + Gobo lunar ---
    canopy_clusters = [
        (-8.2,  2.2, 7.8, 2.8, 1.1),
        (-5.0,  6.8, 8.2, 3.2, 1.2),
        ( 0.0,  8.8, 8.5, 3.6, 1.2),
        ( 5.0,  6.8, 8.2, 3.2, 1.2),
        ( 8.2,  2.0, 7.8, 2.8, 1.1),
        # Gobos altos fora do enquadramento para projetar sombras recortadas de copa sobre o campo
        (-5.8,  6.2, 12.8, 3.0, 1.0),
        (-2.0,  7.4, 13.2, 2.6, 0.9),
    ]
    for c_idx, (cx, cy, cz, spread_r, z_span) in enumerate(canopy_clusters):
        bm_c = bmesh.new()
        _add_leafy_bough_cluster(bm_c, (0.0, 0.0, 0.0), spread_r, z_span, n_boughs=18, mat_idx=0, seed_val=500 + c_idx)
        m_c = bpy.data.meshes.new(f"Canopy_Cluster_{c_idx:02d}_Mesh")
        bm_c.to_mesh(m_c)
        bm_c.free()
        for p in m_c.polygons:
            p.use_smooth = True
        m_c.materials.append(mats["canopy_foliage"])
        c_obj = bpy.data.objects.new(f"Canopy_Cluster_{c_idx:02d}", m_c)
        c_obj.location = Vector((cx, cy, cz))
        link_to_collection(c_obj, sub_cols["05_CANOPY"])

    # Feixes diagonais sutis de luar filtrado pela abertura superior da mata
    beam_specs = [
        ("Moonbeam_Shaft_01", (-1.6, 5.2, 4.8), (0.38, 0.42, -0.25), 0.75, 1.25, 10.5),
        ("Moonbeam_Shaft_02", ( 1.4, 5.8, 5.0), (0.38, 0.42, -0.25), 0.65, 1.10, 10.0),
        ("Moonbeam_Shaft_03", ( 3.4, 4.4, 4.6), (0.38, 0.42, -0.25), 0.55, 0.90,  9.5),
    ]
    for b_name, loc, rot_e, r_top, r_bot, height in beam_specs:
        bm_b = bmesh.new()
        bmesh.ops.create_cone(
            bm_b, cap_ends=False, cap_tris=False, segments=16,
            radius1=r_bot, radius2=r_top, depth=height
        )
        m_b = bpy.data.meshes.new(f"{b_name}_Mesh")
        bm_b.to_mesh(m_b)
        bm_b.free()
        for p in m_b.polygons:
            p.use_smooth = True
        m_b.materials.append(mats["moonbeam"])
        b_obj = bpy.data.objects.new(b_name, m_b)
        b_obj.location = Vector(loc)
        b_obj.rotation_euler = Euler(rot_e, 'XYZ')
        if hasattr(b_obj, "visible_shadow"):
            b_obj.visible_shadow = False
        link_to_collection(b_obj, sub_cols["05_CANOPY"])


# ==============================================================================
# 12 & 13. SUB-BOSQUE BOTÂNICO E RAÍZES/CIPÓS ORGÂNICOS
# ==============================================================================
def create_fern_cluster_mesh(mats, seed_val=1):
    """
    Gera tufo de samambaia da Mata Atlântica com 14 frondes arqueadas contínuas
    e serrilhadas (unidas em malha contínua com vinco central, sem triângulos soltos).
    """
    rng = random.Random(seed_val)
    bm = bmesh.new()
    n_fronds = 14
    for f_i in range(n_fronds):
        ang = (f_i / float(n_fronds)) * math.pi * 2.0 + rng.uniform(-0.14, 0.14)
        ca, sa = math.cos(ang), math.sin(ang)
        px, py = -sa, ca
        length = rng.uniform(0.68, 1.08)
        arch_h = rng.uniform(0.28, 0.48)
        w_max = rng.uniform(0.14, 0.21)
        segs = 8
        prev_row = None
        for s in range(segs + 1):
            t = s / float(segs)
            dist = t * length
            z_mid = math.sin(t * math.pi * 0.80) * arch_h - (t ** 2) * 0.14
            # Contorno serrilhado de samambaia (alterna largura entre nós pares e ímpares)
            serration = 0.72 if (s % 2 == 1 and 0 < s < segs) else 1.0
            w = w_max * math.sin(max(0.06, t) * math.pi) * serration
            z_edge = z_mid - 0.018
            vl = bm.verts.new((ca * dist - px * w, sa * dist - py * w, z_edge))
            vm = bm.verts.new((ca * dist, sa * dist, z_mid))
            vr = bm.verts.new((ca * dist + px * w, sa * dist + py * w, z_edge))
            if prev_row:
                bm.faces.new((prev_row[0], prev_row[1], vm, vl))
                bm.faces.new((prev_row[1], prev_row[2], vr, vm))
            prev_row = (vl, vm, vr)

    m = bpy.data.meshes.new("Fern_Cluster_Mesh")
    bm.to_mesh(m)
    bm.free()
    for p in m.polygons:
        p.use_smooth = True
    m.materials.append(mats["fern"])
    return m


def create_broadleaf_cluster_mesh(mats, seed_val=2):
    rng = random.Random(seed_val)
    bm = bmesh.new()
    n_leaves = 6
    for l_i in range(n_leaves):
        ang = (l_i / float(n_leaves)) * math.pi * 2.0 + rng.uniform(-0.22, 0.22)
        ca, sa = math.cos(ang), math.sin(ang)
        px, py = -sa, ca
        stem_r = rng.uniform(0.18, 0.36)
        stem_h = rng.uniform(0.22, 0.42)
        leaf_len = rng.uniform(0.42, 0.65)
        leaf_w = rng.uniform(0.20, 0.30)

        v_s0 = bm.verts.new((px * 0.015, py * 0.015, 0.0))
        v_s1 = bm.verts.new((-px * 0.015, -py * 0.015, 0.0))
        v_s2 = bm.verts.new((ca * stem_r - px * 0.012, sa * stem_r - py * 0.012, stem_h))
        v_s3 = bm.verts.new((ca * stem_r + px * 0.012, sa * stem_r + py * 0.012, stem_h))
        bm.faces.new((v_s0, v_s1, v_s2, v_s3))

        segs = 5
        prev_row = None
        for s in range(segs + 1):
            t = s / float(segs)
            dist = stem_r + (t - 0.12) * leaf_len
            w = leaf_w * math.sin(max(0.06, t) * math.pi)
            z_mid = stem_h + math.sin(t * math.pi * 0.68) * 0.10 - (t ** 2) * 0.12
            z_edge = z_mid + 0.028 * math.sin(t * math.pi)
            vl = bm.verts.new((ca * dist - px * w, sa * dist - py * w, z_edge))
            vm = bm.verts.new((ca * dist, sa * dist, z_mid))
            vr = bm.verts.new((ca * dist + px * w, sa * dist + py * w, z_edge))
            if prev_row:
                bm.faces.new((prev_row[0], prev_row[1], vm, vl))
                bm.faces.new((prev_row[1], prev_row[2], vr, vm))
            prev_row = (vl, vm, vr)

    m = bpy.data.meshes.new("Broadleaf_Cluster_Mesh")
    bm.to_mesh(m)
    bm.free()
    for p in m.polygons:
        p.use_smooth = True
    m.materials.append(mats["broadleaf"])
    return m


def create_bromeliad_mesh(mats, seed_val=3):
    rng = random.Random(seed_val)
    bm = bmesh.new()
    for ring_idx, (n_b, l_len, z_lift, mat_id) in enumerate([
        (10, 0.42, 0.16, 0),
        (7,  0.28, 0.24, 0),
        (5,  0.16, 0.28, 1),
    ]):
        for k in range(n_b):
            ang = (k / float(n_b)) * math.pi * 2.0 + ring_idx * 0.35 + rng.uniform(-0.1, 0.1)
            ca, sa = math.cos(ang), math.sin(ang)
            w = 0.055 if mat_id == 0 else 0.038
            px, py = -sa * w, ca * w
            v0 = bm.verts.new((ca * 0.03 - px * 0.5, sa * 0.03 - py * 0.5, 0.02))
            v1 = bm.verts.new((ca * 0.03 + px * 0.5, sa * 0.03 + py * 0.5, 0.02))
            v2 = bm.verts.new((ca * l_len + px, sa * l_len + py, z_lift))
            v3 = bm.verts.new((ca * l_len - px, sa * l_len - py, z_lift))
            f = bm.faces.new((v0, v1, v2, v3))
            f.material_index = mat_id

    m = bpy.data.meshes.new("Bromeliad_Cluster_Mesh")
    bm.to_mesh(m)
    bm.free()
    for p in m.polygons:
        p.use_smooth = True
    m.materials.append(mats["bromeliad"])
    m.materials.append(mats["bromeliad_bract"])
    return m


def build_undergrowth_roots_and_vines(sub_cols, layout, mats):
    rng = random.Random(CONFIG["random_seed"] + 202)
    fern_mesh = create_fern_cluster_mesh(mats, 11)
    broad_mesh = create_broadleaf_cluster_mesh(mats, 22)
    brom_mesh = create_bromeliad_mesh(mats, 33)

    p_min_x, p_max_x, p_min_y, p_max_y = layout["playable_bounds"]

    undergrowth_zones = []
    for iy in range(26):
        y = -6.4 + iy * 0.62 + rng.uniform(-0.18, 0.18)
        sc_x = stream_center_x_at(y, layout)
        undergrowth_zones.append((sc_x - rng.uniform(0.68, 1.95), y))
        undergrowth_zones.append((sc_x + rng.uniform(0.62, 1.15), y))
    for iy in range(24):
        y = -6.0 + iy * 0.65 + rng.uniform(-0.18, 0.18)
        undergrowth_zones.append((p_max_x + rng.uniform(0.75, 3.40), y))
        undergrowth_zones.append((p_max_x + rng.uniform(1.40, 4.20), y + 0.25))
    for ix in range(20):
        x = -7.5 + ix * 0.80 + rng.uniform(-0.22, 0.22)
        undergrowth_zones.append((x, p_max_y + rng.uniform(0.72, 3.60)))
    for px, py in [
        (-6.0, -6.2), (-5.2, -6.4), (-6.8, -5.4), (-4.5, -6.5),
        ( 4.5, -6.5), ( 5.3, -6.4), ( 6.1, -6.2), ( 6.9, -5.4),
    ]:
        undergrowth_zones.append((px, py))

    f_cnt, bl_cnt, br_cnt = 0, 0, 0
    for ux, uy in undergrowth_zones:
        if is_in_exclusion_zone(ux, uy, layout, extra_radius=0.32):
            continue
        if abs(ux - stream_center_x_at(uy, layout)) < 0.46:
            continue
        uz = terrain_height_at(ux, uy, layout)
        choice = rng.random()
        if choice < 0.48:
            obj = bpy.data.objects.new(f"Fern_Cluster_{f_cnt:02d}", fern_mesh)
            f_cnt += 1
            sc = rng.uniform(0.82, 1.38)
        elif choice < 0.82:
            obj = bpy.data.objects.new(f"Broadleaf_Cluster_{bl_cnt:02d}", broad_mesh)
            bl_cnt += 1
            sc = rng.uniform(0.85, 1.40)
        else:
            obj = bpy.data.objects.new(f"Bromeliad_Cluster_{br_cnt:02d}", brom_mesh)
            br_cnt += 1
            sc = rng.uniform(0.88, 1.32)

        obj.location = Vector((ux, uy, uz))
        obj.rotation_euler = Euler((rng.uniform(-0.08, 0.08), rng.uniform(-0.08, 0.08), rng.uniform(0.0, math.pi * 2.0)), 'XYZ')
        obj.scale = Vector((sc, sc, sc))
        link_to_collection(obj, sub_cols["06_UNDERGROWTH"])

    # Folhas mortas caídas (serrapilheira)
    bm_dl = bmesh.new()
    for i in range(115):
        angle = rng.uniform(0.0, math.pi * 2.0)
        rx = rng.uniform(p_min_x - 3.6, p_max_x + 3.6)
        ry = rng.uniform(p_min_y - 1.5, p_max_y + 3.4)
        if (p_min_x - 0.15) <= rx <= (p_max_x + 0.15) and (p_min_y + 0.15) <= ry <= (p_max_y - 0.15):
            continue
        if abs(rx - stream_center_x_at(ry, layout)) < 0.52:
            continue
        rz = terrain_height_at(rx, ry, layout) + 0.008
        lw = rng.uniform(0.05, 0.11)
        ll = rng.uniform(0.10, 0.20)
        ca, sa = math.cos(angle), math.sin(angle)
        v0 = bm_dl.verts.new((rx - ca * ll, ry - sa * ll, rz))
        v1 = bm_dl.verts.new((rx - sa * lw, ry + ca * lw, rz + 0.006))
        v2 = bm_dl.verts.new((rx + ca * ll, ry + sa * ll, rz + 0.003))
        v3 = bm_dl.verts.new((rx + sa * lw, ry - ca * lw, rz + 0.006))
        bm_dl.faces.new((v0, v1, v2, v3))

    m_dl = bpy.data.meshes.new("FallenLeaves_Patches_Mesh")
    bm_dl.to_mesh(m_dl)
    bm_dl.free()
    m_dl.materials.append(mats["fallen_leaves"])
    dl_obj = bpy.data.objects.new("FallenLeaves_Patches", m_dl)
    link_to_collection(dl_obj, sub_cols["06_UNDERGROWTH"])

    # --- 07_ROOTS_AND_VINES: Raízes nodosas esculpidas em BMesh serpenteando pelas margens ---
    root_paths = [
        [(-8.2,  0.9), (-7.7,  1.5), (-7.1,  2.2), (-6.8,  3.0), (-6.6,  3.8)],
        [(-6.8,  4.8), (-6.0,  5.0), (-5.2,  4.7), (-4.5,  4.8), (-3.8,  4.5)],
        [(-4.5,  5.9), (-3.8,  5.3), (-3.0,  4.9), (-2.2,  4.6), (-1.5,  4.5)],
        [( 2.3,  5.7), ( 3.0,  5.1), ( 3.7,  4.8), ( 4.4,  4.6), ( 5.0,  4.4)],
        [( 6.4,  4.0), ( 5.8,  3.2), ( 5.4,  2.4), ( 5.2,  1.6), ( 5.5,  0.8)],
        [( 6.4, -0.5), ( 5.8, -1.2), ( 5.4, -2.0), ( 5.2, -2.8), ( 5.4, -3.5)],
    ]
    for r_idx, pts2d in enumerate(root_paths):
        bm_rt = bmesh.new()
        pts3d = []
        radii = []
        for k, (px, py) in enumerate(pts2d):
            t = k / float(len(pts2d) - 1)
            z_off = 0.14 * ((1.0 - t) ** 2.0) + 0.03 * math.sin(t * math.pi * 3.0)
            pz = terrain_height_at(px, py, layout) + z_off
            pts3d.append((px, py, pz))
            radii.append(0.11 * (1.0 - 0.72 * t))
        _add_tube_branch(bm_rt, pts3d, radii, segments=6, mat_idx=0)
        m_rt = bpy.data.meshes.new(f"Root_{r_idx:02d}_Mesh")
        bm_rt.to_mesh(m_rt)
        bm_rt.free()
        for p in m_rt.polygons:
            p.use_smooth = True
        m_rt.materials.append(mats["bark_moss"])
        r_obj = bpy.data.objects.new(f"Root_{r_idx:02d}", m_rt)
        link_to_collection(r_obj, sub_cols["07_ROOTS_AND_VINES"])

    # 3 variantes de Cipós pendentes em alturas visíveis na câmera (Z = 2.6m a 5.6m nas bordas e fundo)
    vine_spans = [
        ("Vine_Variant_A_01", (-8.4, -4.6, 5.2), (-8.8, -1.8, 4.8), 1.45, 0.034),
        ("Vine_Variant_A_02", (-8.1, -1.5, 5.0), (-7.6,  1.6, 5.3), 1.55, 0.030),
        ("Vine_Variant_B_01", (-7.3,  2.4, 5.4), (-6.6,  4.8, 5.1), 1.35, 0.028),
        ("Vine_Variant_B_02", ( 8.3, -4.4, 5.2), ( 8.7, -1.6, 4.9), 1.45, 0.034),
        ("Vine_Variant_C_01", ( 6.3,  1.2, 5.1), ( 6.2,  4.0, 5.3), 1.40, 0.028),
        ("Vine_Variant_C_02", (-4.4,  5.8, 5.5), (-2.1,  5.7, 5.2), 1.25, 0.026),
        ("Vine_Variant_C_03", ( 2.2,  5.7, 5.3), ( 4.6,  5.8, 5.5), 1.30, 0.026),
    ]
    for v_name, p_start, p_end, sag, rad in vine_spans:
        curve_v = bpy.data.curves.new(f"{v_name}_Curve", type='CURVE')
        curve_v.dimensions = '3D'
        curve_v.bevel_depth = 1.0
        curve_v.bevel_resolution = 2
        sp_cat = curve_v.splines.new('NURBS')
        n_seg = 9
        sp_cat.points.add(n_seg - 1)
        for s in range(n_seg):
            t = s / float(n_seg - 1)
            vx = p_start[0] + (p_end[0] - p_start[0]) * t + math.sin(t * math.pi * 2.0) * 0.12
            vy = p_start[1] + (p_end[1] - p_start[1]) * t
            vz = p_start[2] + (p_end[2] - p_start[2]) * t - math.sin(t * math.pi) * sag
            sp_cat.points[s].co = (vx, vy, vz, 1.0)
            sp_cat.points[s].radius = rad * (0.85 + 0.3 * abs(t - 0.5))
        sp_cat.use_endpoint_u = True

        for h_t in (0.28, 0.52, 0.74):
            sp_h = curve_v.splines.new('POLY')
            sp_h.points.add(4)
            hx = p_start[0] + (p_end[0] - p_start[0]) * h_t
            hy = p_start[1] + (p_end[1] - p_start[1]) * h_t
            hz_top = p_start[2] + (p_end[2] - p_start[2]) * h_t - math.sin(h_t * math.pi) * sag
            h_len = rng.uniform(1.8, 2.9)
            for k in range(5):
                kt = k / 4.0
                sp_h.points[k].co = (
                    hx + math.sin(kt * 4.0) * 0.08,
                    hy + math.cos(kt * 3.5) * 0.06,
                    hz_top - kt * h_len,
                    1.0,
                )
                sp_h.points[k].radius = rad * 0.72 * (1.0 - 0.65 * kt)

        v_obj = bpy.data.objects.new(v_name, curve_v)
        v_obj.data.materials.append(mats["bark_moss"])
        link_to_collection(v_obj, sub_cols["07_ROOTS_AND_VINES"])


# ==============================================================================
# 14. RIACHO E PEDRAS MUSGOSAS (Margem Esquerda + Paredão Rochoso Úmido ao Fundo)
# ==============================================================================
def build_stream_and_mossy_rocks(sub_cols, layout, mats):
    rng = random.Random(CONFIG["random_seed"] + 303)

    bm_st = bmesh.new()
    n_steps = 52
    y_start = -8.2
    y_end = 11.2
    prev_verts = None
    for i in range(n_steps + 1):
        t = i / float(n_steps)
        y = y_start + t * (y_end - y_start)
        cx = stream_center_x_at(y, layout)
        hw = stream_half_width_at(y) * 1.08
        z_bed = terrain_height_at(cx, y, layout)
        z_water = z_bed + 0.15
        vl = bm_st.verts.new((cx - hw, y, z_water))
        vc = bm_st.verts.new((cx, y, z_water - 0.008))
        vr = bm_st.verts.new((cx + hw, y, z_water))
        if prev_verts:
            bm_st.faces.new((prev_verts[0], prev_verts[1], vc, vl))
            bm_st.faces.new((prev_verts[1], prev_verts[2], vr, vc))
        prev_verts = (vl, vc, vr)

    m_st = bpy.data.meshes.new("Stream_Surface_Mesh")
    bm_st.to_mesh(m_st)
    bm_st.free()
    for p in m_st.polygons:
        p.use_smooth = True
    m_st.materials.append(mats["stream_water"])
    st_obj = bpy.data.objects.new("Stream_Surface", m_st)
    link_to_collection(st_obj, sub_cols["08_STREAM_AND_ROCKS"])

    rock_variants = {}
    for v_idx, (v_let, sx, sy, sz) in enumerate([
        ("A", 1.20, 0.92, 0.48),
        ("B", 0.82, 1.30, 0.62),
        ("C", 1.40, 1.05, 0.35),
        ("D", 1.08, 0.88, 1.12),
    ]):
        bm_r = bmesh.new()
        bmesh.ops.create_icosphere(bm_r, subdivisions=2, radius=0.52)
        for v in bm_r.verts:
            n_val = math.sin(v.co.x * 4.5 + v_idx) * math.cos(v.co.y * 4.0 - v_idx)
            v.co.x *= sx * (1.0 + 0.18 * n_val)
            v.co.y *= sy * (1.0 - 0.14 * n_val)
            v.co.z *= sz * (1.0 + 0.12 * math.sin(v.co.z * 3.0))
            if v.co.z < -0.14:
                v.co.z = -0.14 + (v.co.z + 0.14) * 0.3
        m_r = bpy.data.meshes.new(f"Rock_Mossy_Variant_{v_let}_Mesh")
        bm_r.to_mesh(m_r)
        bm_r.free()
        for p in m_r.polygons:
            p.use_smooth = True
        m_r.materials.append(mats["rock_mossy"])
        rock_variants[v_let] = m_r

    rk_count = 0
    for i in range(38):
        ry = -6.8 + i * 0.42 + rng.uniform(-0.14, 0.14)
        sc_x = stream_center_x_at(ry, layout)
        hw = stream_half_width_at(ry)
        side = -1.0 if (i % 2 == 0) else 1.0
        rx = sc_x + side * rng.uniform(hw * 0.48, hw * 1.12)
        if is_in_exclusion_zone(rx, ry, layout, extra_radius=0.32):
            continue
        rz = terrain_height_at(rx, ry, layout) + 0.03
        v_let = ["A", "B", "C"][i % 3]
        r_obj = bpy.data.objects.new(f"Rock_Mossy_{v_let}_{rk_count:02d}", rock_variants[v_let])
        rk_count += 1
        r_obj.location = Vector((rx, ry, rz))
        sc = rng.uniform(0.58, 1.18)
        r_obj.scale = Vector((sc, sc * rng.uniform(0.85, 1.15), sc * rng.uniform(0.70, 1.05)))
        r_obj.rotation_euler = Euler((rng.uniform(-0.12, 0.12), rng.uniform(-0.12, 0.12), rng.uniform(0.0, math.pi * 2.0)), 'XYZ')
        link_to_collection(r_obj, sub_cols["08_STREAM_AND_ROCKS"])

    escarpment_rocks = [
        ("D", -5.6, 7.4, 1.75),
        ("D", -3.2, 8.6, 1.95),
        ("B",  3.4, 8.4, 1.85),
        ("D",  5.8, 7.6, 1.70),
        ("C",  5.6, 2.2, 1.05),
        ("A",  5.8, -2.4, 0.90),
    ]
    for v_let, rx, ry, sc in escarpment_rocks:
        rz = terrain_height_at(rx, ry, layout)
        r_obj = bpy.data.objects.new(f"Rock_Mossy_{v_let}_{rk_count:02d}", rock_variants[v_let])
        rk_count += 1
        r_obj.location = Vector((rx, ry, rz))
        r_obj.scale = Vector((sc, sc, sc * 1.12))
        r_obj.rotation_euler = Euler((0.08, -0.06, rng.uniform(0.0, math.pi * 2.0)), 'XYZ')
        link_to_collection(r_obj, sub_cols["08_STREAM_AND_ROCKS"])


# ==============================================================================
# 15 & 16. HORROR AMBIENTAL SUTIL E VESTÍGIO HUMANO DISCRETO (09_HORROR_DETAILS)
# ==============================================================================
def build_horror_and_human_traces(sub_cols, layout, mats):
    # --- INDÍCIO A: Pegadas de orientação suspeita na lama à margem do riacho ---
    footprint_steps = [
        (-5.05, -2.35, -0.45),
        (-4.95, -1.78, -0.38),
        (-4.88, -1.22, -0.42),
        (-4.82, -0.64, -0.36),
        (-4.80, -0.05, -0.40),
        (-4.85,  0.52, -0.48),
    ]
    for idx_f, (fx, fy, f_rot) in enumerate(footprint_steps):
        fz = terrain_height_at(fx, fy, layout) + 0.005
        bm_fp = bmesh.new()
        bmesh.ops.create_cone(bm_fp, cap_ends=True, cap_tris=False, segments=10, radius1=0.075, radius2=0.065, depth=0.010)
        for v in bm_fp.verts:
            v.co.y *= 1.65
            if v.co.y > 0.0:
                v.co.x *= 0.72
            else:
                v.co.x *= 1.15
        for toe_i in range(5):
            tx = (toe_i - 2.0) * 0.028
            ty = -0.145 - abs(toe_i - 2.0) * 0.008
            g_t = bmesh.ops.create_icosphere(bm_fp, subdivisions=1, radius=0.014)
            for v in g_t["verts"]:
                v.co.x += tx
                v.co.y += ty
                v.co.z *= 0.4

        m_fp = bpy.data.meshes.new(f"Horror_Footprint_{idx_f:02d}_Mesh")
        bm_fp.to_mesh(m_fp)
        bm_fp.free()
        m_fp.materials.append(mats["dark_mud"])
        fp_obj = bpy.data.objects.new(f"Horror_Footprint_{idx_f:02d}", m_fp)
        fp_obj.location = Vector((fx + (0.09 if idx_f % 2 == 0 else -0.09), fy, fz))
        fp_obj.rotation_euler = Euler((0.0, 0.0, f_rot), 'XYZ')
        link_to_collection(fp_obj, sub_cols["09_HORROR_DETAILS"])

    # --- INDÍCIO B: Cipós em nós improváveis na lateral direita ---
    knot_loc = (5.45, -0.25)
    knot_z = terrain_height_at(knot_loc[0], knot_loc[1], layout)
    curve_knot = bpy.data.curves.new("Horror_ImpossibleVineKnot_Curve", type='CURVE')
    curve_knot.dimensions = '3D'
    curve_knot.bevel_depth = 1.0
    curve_knot.bevel_resolution = 3

    for b_idx in range(4):
        sp_k = curve_knot.splines.new('NURBS')
        phase = (b_idx / 4.0) * math.pi * 2.0
        n_pts = 14
        sp_k.points.add(n_pts - 1)
        for i in range(n_pts):
            t = i / float(n_pts - 1)
            pinch = 1.0 - 0.72 * math.exp(-((t - 0.55) / 0.16) ** 2)
            ang = phase + t * math.pi * 3.2
            rad = 0.34 * pinch
            kx = math.cos(ang) * rad + math.sin(t * math.pi) * 0.16
            ky = math.sin(ang) * rad
            kz = -0.05 + t * 2.20
            sp_k.points[i].co = (kx, ky, kz, 1.0)
            sp_k.points[i].radius = 0.038 * (1.0 - 0.55 * abs(t - 0.55))
        sp_k.use_endpoint_u = True

    knot_obj = bpy.data.objects.new("Horror_ImpossibleVineKnot", curve_knot)
    knot_obj.location = Vector((knot_loc[0], knot_loc[1], knot_z))
    knot_obj.data.materials.append(mats["bark_moss"])
    link_to_collection(knot_obj, sub_cols["09_HORROR_DETAILS"])

    # --- INDÍCIO C: Passagem que parece retornar ao fundo (+Y) ---
    bm_path = bmesh.new()
    segs_p = 18
    for s in range(segs_p):
        t0 = s / float(segs_p)
        t1 = (s + 1) / float(segs_p)
        y0 = 4.2 + t0 * 8.2
        y1 = 4.2 + t1 * 8.2
        x0 = 0.55 * math.sin((y0 - 4.2) * 0.36) + 0.25
        x1 = 0.55 * math.sin((y1 - 4.2) * 0.36) + 0.25
        w0 = 0.56 * (1.0 - 0.30 * t0)
        w1 = 0.56 * (1.0 - 0.30 * t1)
        z0 = terrain_height_at(x0, y0, layout) + 0.005
        z1 = terrain_height_at(x1, y1, layout) + 0.005
        v00 = bm_path.verts.new((x0 - w0, y0, z0))
        v01 = bm_path.verts.new((x0 + w0, y0, z0))
        v11 = bm_path.verts.new((x1 + w1, y1, z1))
        v10 = bm_path.verts.new((x1 - w1, y1, z1))
        bm_path.faces.new((v00, v01, v11, v10))
    m_path = bpy.data.meshes.new("Horror_ReturningMudTrail_Mesh")
    bm_path.to_mesh(m_path)
    bm_path.free()
    m_path.materials.append(mats["dark_mud"])
    path_obj = bpy.data.objects.new("Horror_ReturningMudTrail", m_path)
    link_to_collection(path_obj, sub_cols["09_HORROR_DETAILS"])

    passage_pairs = [
        ("Horror_RepeatingPassage_Near", (0.15, 5.4, 0.0), 1.00, 0.08),
        ("Horror_RepeatingPassage_Far",  (0.32, 8.6, 0.0), 0.94, 0.11),
    ]
    for prefix, (bx, by, _), sc, yaw_off in passage_pairs:
        bz = terrain_height_at(bx, by, layout)
        curve_tr = bpy.data.curves.new(f"{prefix}_TwinTrunks_Curve", type='CURVE')
        curve_tr.dimensions = '3D'
        curve_tr.bevel_depth = 1.0
        curve_tr.bevel_resolution = 3
        for ox, oy, lean_x, h_t, r_t in [
            (-0.92 * sc, 0.0,  0.55 * sc, 4.2 * sc, 0.19 * sc),
            ( 0.92 * sc, 0.15 * sc, -0.50 * sc, 4.0 * sc, 0.17 * sc),
        ]:
            sp = curve_tr.splines.new('POLY')
            pts = [
                (ox, oy, -0.15, r_t),
                (ox + lean_x * 0.45, oy + 0.08, h_t * 0.48, r_t * 0.72),
                (ox + lean_x * 0.95, oy + 0.16, h_t * 0.96, r_t * 0.32),
            ]
            sp.points.add(len(pts) - 1)
            for i, (px, py, pz, pr) in enumerate(pts):
                sp.points[i].co = (px, py, pz, 1.0)
                sp.points[i].radius = pr

        tr_obj = bpy.data.objects.new(f"{prefix}_ArchTrunks", curve_tr)
        tr_obj.location = Vector((bx, by, bz))
        tr_obj.rotation_euler = Euler((0.0, 0.0, yaw_off), 'XYZ')
        tr_obj.data.materials.append(mats["bark_moss"])
        link_to_collection(tr_obj, sub_cols["09_HORROR_DETAILS"])

        bm_st = bmesh.new()
        bmesh.ops.create_icosphere(bm_st, subdivisions=2, radius=0.36 * sc)
        for v in bm_st.verts:
            v.co.x *= 1.25
            v.co.z *= 0.65
        m_st = bpy.data.meshes.new(f"{prefix}_MarkerRock_Mesh")
        bm_st.to_mesh(m_st)
        bm_st.free()
        m_st.materials.append(mats["rock_mossy"])
        st_obj = bpy.data.objects.new(f"{prefix}_MarkerRock", m_st)
        st_obj.location = Vector((bx - 0.65 * sc, by - 0.20 * sc, bz))
        st_obj.rotation_euler = Euler((0.0, 0.0, yaw_off + 0.35), 'XYZ')
        link_to_collection(st_obj, sub_cols["09_HORROR_DETAILS"])

    # --- SEÇÃO 16: Vestígio humano discreto (Tecido desbotado preso em galho baixo) ---
    cloth_pos = (-0.65, 5.20, terrain_height_at(-0.65, 5.20, layout) + 1.02)
    bm_cl = bmesh.new()
    segs_x, segs_z = 4, 6
    for iz in range(segs_z):
        for ix in range(segs_x):
            x0 = (ix / float(segs_x) - 0.5) * 0.18
            x1 = ((ix + 1) / float(segs_x) - 0.5) * 0.18
            z0 = -(iz / float(segs_z)) * 0.32
            z1 = -((iz + 1) / float(segs_z)) * 0.32
            taper0 = 1.0 - 0.55 * (iz / float(segs_z))
            taper1 = 1.0 - 0.55 * ((iz + 1) / float(segs_z))
            y_w0 = 0.025 * math.sin(iz * 1.1 + ix * 0.8)
            y_w1 = 0.025 * math.sin((iz + 1) * 1.1 + ix * 0.8)
            v00 = bm_cl.verts.new((x0 * taper0, y_w0, z0))
            v10 = bm_cl.verts.new((x1 * taper0, y_w0, z0))
            v11 = bm_cl.verts.new((x1 * taper1, y_w1, z1))
            v01 = bm_cl.verts.new((x0 * taper1, y_w1, z1))
            bm_cl.faces.new((v00, v10, v11, v01))

    m_cl = bpy.data.meshes.new("Horror_FadedCloth_Mesh")
    bm_cl.to_mesh(m_cl)
    bm_cl.free()
    for p in m_cl.polygons:
        p.use_smooth = True
    m_cl.materials.append(mats["faded_cloth"])
    cl_obj = bpy.data.objects.new("Horror_FadedCloth", m_cl)
    cl_obj.location = Vector(cloth_pos)
    cl_obj.rotation_euler = Euler((0.12, 0.08, 0.35), 'XYZ')
    link_to_collection(cl_obj, sub_cols["09_HORROR_DETAILS"])


# ==============================================================================
# 18. ILUMINAÇÃO NOTURNA FILTRADA PELA COPA (4 Camadas de Luz + Mundo Noturno Úmido)
# ==============================================================================
def setup_lighting_and_world(scene, sub_cols):
    moon_data = bpy.data.lights.new(name="Light_Moon_Key_Data", type='SUN')
    moon_data.color = (0.74, 0.85, 0.98)
    moon_data.energy = 2.45
    moon_data.angle = math.radians(7.0)

    moon_obj = bpy.data.objects.new("Light_Moon_Key", moon_data)
    moon_obj.location = Vector((-9.0, 11.0, 14.0))
    direction = Vector((0.68, -0.78, -0.92)).normalized()
    moon_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    link_to_collection(moon_obj, sub_cols["10_LIGHTS"])

    fill_data = bpy.data.lights.new(name="Light_Ambient_Fill_Data", type='AREA')
    fill_data.shape = 'RECTANGLE'
    fill_data.size = 19.0
    fill_data.size_y = 17.0
    fill_data.color = (0.64, 0.78, 0.86)
    fill_data.energy = 205.0

    fill_obj = bpy.data.objects.new("Light_Ambient_Fill", fill_data)
    fill_obj.location = Vector((1.5, -3.5, 13.5))
    fill_dir = (Vector((0.0, 0.0, 0.0)) - fill_obj.location).normalized()
    fill_obj.rotation_euler = fill_dir.to_track_quat('-Z', 'Y').to_euler()
    link_to_collection(fill_obj, sub_cols["10_LIGHTS"])

    rim_data = bpy.data.lights.new(name="Light_Wet_Specular_Rim_Data", type='AREA')
    rim_data.shape = 'DISK'
    rim_data.size = 6.5
    rim_data.color = (0.74, 0.88, 1.0)
    rim_data.energy = 120.0

    rim_obj = bpy.data.objects.new("Light_Wet_Specular_Rim", rim_data)
    rim_obj.location = Vector((-7.5, 5.5, 6.8))
    rim_dir = (Vector((-4.8, -1.0, 0.0)) - rim_obj.location).normalized()
    rim_obj.rotation_euler = rim_dir.to_track_quat('-Z', 'Y').to_euler()
    link_to_collection(rim_obj, sub_cols["10_LIGHTS"])

    back_data = bpy.data.lights.new(name="Light_Canopy_Back_Data", type='AREA')
    back_data.shape = 'RECTANGLE'
    back_data.size = 14.0
    back_data.size_y = 6.0
    back_data.color = (0.58, 0.76, 0.84)
    back_data.energy = 145.0

    back_obj = bpy.data.objects.new("Light_Canopy_Back", back_data)
    back_obj.location = Vector((0.0, 10.5, 7.5))
    back_dir = (Vector((0.0, 3.5, 1.2)) - back_obj.location).normalized()
    back_obj.rotation_euler = back_dir.to_track_quat('-Z', 'Y').to_euler()
    link_to_collection(back_obj, sub_cols["10_LIGHTS"])

    world = bpy.data.worlds.get("World_MataAtlantica")
    if not world:
        world = bpy.data.worlds.new("World_MataAtlantica")
    scene.world = world
    w_nodes = world.node_tree.nodes
    w_links = world.node_tree.links
    w_nodes.clear()

    bg = w_nodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (0.048, 0.078, 0.098, 1.0)
    bg.inputs["Strength"].default_value = 0.54
    out_w = w_nodes.new("ShaderNodeOutputWorld")
    w_links.new(bg.outputs["Background"], out_w.inputs["Surface"])


# ==============================================================================
# 19. CÂMERA (`Camera_Game` — Perspectiva 3/4 Elevada, 55% a 65% de Ocupação Horizontal)
# ==============================================================================
def setup_camera_and_controls(scene, sub_cols):
    ctrl_target = bpy.data.objects.new("Control_Board_Center", None)
    ctrl_target.empty_display_type = 'PLAIN_AXES'
    ctrl_target.location = Vector((0.0, -0.35, 0.0))
    link_to_collection(ctrl_target, sub_cols["00_CONTROLS"])

    cam_data = bpy.data.cameras.new("Camera_Game_Data")
    cam_data.lens = 47.0
    cam_data.sensor_width = 36.0
    cam_data.clip_start = 0.1
    cam_data.clip_end = 200.0
    cam_data.dof.use_dof = False

    cam_obj = bpy.data.objects.new("Camera_Game", cam_data)
    cam_obj.location = Vector((0.0, -16.6, 13.9))
    look_target = Vector((0.0, -0.30, 0.55))
    look_vec = (look_target - cam_obj.location).normalized()
    cam_obj.rotation_euler = look_vec.to_track_quat('-Z', 'Y').to_euler()

    link_to_collection(cam_obj, sub_cols["11_CAMERAS"])
    scene.camera = cam_obj
    return cam_obj


# ==============================================================================
# 21. RENDERIZAÇÃO (Prévia e Final 1920x1080 em PNG via Cycles)
# ==============================================================================
def configure_render_engine(scene):
    scene.render.engine = 'CYCLES'
    prefs = bpy.context.preferences.addons['cycles'].preferences
    try:
        prefs.refresh_devices()
        for dev in prefs.devices:
            if dev.type in ('OPTIX', 'CUDA'):
                prefs.compute_device_type = dev.type
                dev.use = True
                scene.cycles.device = 'GPU'
                break
    except Exception:
        scene.cycles.device = 'CPU'

    scene.cycles.use_denoising = True
    scene.render.image_settings.file_format = 'PNG'
    scene.render.image_settings.color_mode = 'RGBA'
    scene.render.film_transparent = False

    try:
        enum_items = [it.identifier for it in scene.view_settings.bl_rna.properties['view_transform'].enum_items]
        for candidate in ('AgX', 'Filmic', 'Standard'):
            if candidate in enum_items:
                scene.view_settings.view_transform = candidate
                break
    except Exception:
        pass
    scene.view_settings.exposure = 0.25


def render_image(scene, filepath, resolution, samples):
    scene.render.resolution_x = resolution[0]
    scene.render.resolution_y = resolution[1]
    scene.render.resolution_percentage = 100
    scene.cycles.samples = samples
    scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    print(f"[RENDER OK] {filepath} ({resolution[0]}x{resolution[1]}, {samples} samples)")


# ==============================================================================
# EXECUÇÃO PRINCIPAL DAS 8 ETAPAS (Seção 23)
# ==============================================================================
def build_mata_atlantica_autochess():
    random.seed(CONFIG["random_seed"])
    out_dir = ensure_output_dir()

    print("=== ETAPA 1: Inspeção e Configuração ===")
    scene, main_col, sub_cols = setup_scene_and_collections()
    layout = compute_board_layout()
    mats = create_materials()
    configure_render_engine(scene)

    print("=== ETAPAS 2 & 3: Blockout, Terreno Contínuo, Grade Hexagonal 8x8 e Reserva (9 slots) ===")
    build_continuous_terrain(sub_cols, layout, mats)
    build_hex_board(sub_cols, layout, mats)
    build_reserve_slots(sub_cols, layout, mats)
    setup_camera_and_controls(scene, sub_cols)
    setup_lighting_and_world(scene, sub_cols)

    print("=== ETAPAS 4, 5, 6 & 7: Árvores (5 Variantes), Copa Fechada, Sub-Bosque, Riacho e Horror Sutil ===")
    build_trees_and_canopy(sub_cols, layout, mats)
    build_undergrowth_roots_and_vines(sub_cols, layout, mats)
    build_stream_and_mossy_rocks(sub_cols, layout, mats)
    build_horror_and_human_traces(sub_cols, layout, mats)

    # Render de Prévia
    preview_path = os.path.join(out_dir, "mata_atlantica_autochess_preview.png")
    print("=== Gerando Render de Prévia ===")
    render_image(scene, preview_path, CONFIG["preview_resolution"], CONFIG["preview_samples"])

    # Render Final 1920x1080
    final_path = os.path.join(out_dir, "mata_atlantica_autochess_final.png")
    print("=== Gerando Render Final 1920x1080 ===")
    render_image(scene, final_path, CONFIG["final_resolution"], CONFIG["final_samples"])

    # Salvar arquivo .blend
    blend_path = os.path.join(out_dir, "mata_atlantica_autochess.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"[BLEND OK] Salvo em: {blend_path}")


if __name__ == "__main__":
    build_mata_atlantica_autochess()
