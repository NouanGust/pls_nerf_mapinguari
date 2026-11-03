"""
build_caatinga.py
=================
Agente Blender — Arena de Autochess na Caatinga
Construção automatizada de ambiente 3D estilizado com acabamento pictórico sombrio
em Blender 5.2+ (bpy) com renderização Cycles.

Entregáveis gerados por este script:
- caatinga_autochess_preview.png (960 x 540)
- caatinga_autochess_final.png   (1920 x 1080)
- caatinga_autochess.blend       (Cena organizada em CAATINGA_ENV)
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
    "scene_name": "Caatinga_Autochess",
    "unit_system": "METRIC",
    "vertical_axis": "Z",
    "front_direction": "-Y",
    "back_direction": "+Y",
    "hex_columns": 8,
    "hex_rows": 8,
    "hex_radius": 0.65,           # 0,65 m (ponta para cima)
    "groove_width": 0.024,        # Sulcos rasos entre 0,015 e 0,03 m
    "groove_depth": 0.012,        # Profundidade visual entre 0,005 e 0,015 m
    "reserve_slots": 9,
    "reserve_gap": 0.85,          # Intervalo entre o combate e a reserva frontal (Y negativo)
    "reserve_slot_width": 0.86,
    "reserve_slot_depth": 0.82,
    "exclusion_margin": 0.65,     # Margem de segurança >= 0,5 m ao redor do conjunto jogável
    "random_seed": 42,
    "aspect_ratio": (16, 9),
    "preview_resolution": (960, 540),
    "final_resolution": (1920, 1080),
    "preview_samples": 32,
    "final_samples": 96,
    "output_dir": os.path.abspath(os.path.dirname(__file__))
        if "__file__" in globals() else os.path.abspath("output/caatinga_autochess"),
}

SUBCOLLECTION_NAMES = [
    "00_CONTROLS",
    "01_TERRAIN",
    "02_BOARD",
    "03_RESERVE",
    "04_WHITE_FOREST",
    "05_CACTI",
    "06_UNDERGROWTH",
    "07_FENCE_AND_SKULL",
    "08_HORROR_DETAILS",
    "09_LIGHTS",
    "10_CAMERAS",
]


# ==============================================================================
# FUNÇÕES UTILITÁRIAS E DE LIMPEZA SEGURA (Sem apagar fora de CAATINGA_ENV)
# ==============================================================================
def ensure_output_dir():
    out_dir = CONFIG["output_dir"]
    os.makedirs(out_dir, exist_ok=True)
    # Também garante cópia na raiz do projeto caso solicitado
    return out_dir


def setup_scene_and_collections():
    """
    Etapa 1: Inspeciona a cena existente, preserva objetos externos e recria
    apenas a hierarquia da coleção principal CAATINGA_ENV para evitar duplicações.
    """
    scene = bpy.context.scene
    scene.name = CONFIG["scene_name"]
    scene.unit_settings.system = 'METRIC'
    scene.unit_settings.scale_length = 1.0

    # Oculta da renderização objetos padrão preexistentes fora de CAATINGA_ENV
    # sem apagá-los (Regra 2.3: Não apague conteúdo preexistente sem autorização)
    for obj in scene.objects:
        if not any(col.name.startswith("CAATINGA_ENV") or col.name in SUBCOLLECTION_NAMES for col in obj.users_collection):
            obj.hide_render = True
            obj.hide_viewport = True

    # Se CAATINGA_ENV já existir de uma execução anterior deste script, limpa apenas ela
    existing_main = bpy.data.collections.get("CAATINGA_ENV")
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

    main_col = bpy.data.collections.new("CAATINGA_ENV")
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
# CÁLCULO GEOMÉTRICO DO TABULEIRO E DA MÁSCARA DE EXCLUSÃO
# ==============================================================================
def compute_board_layout():
    """
    Calcula centros das 64 casas (8x8) ponta para cima com raio R = 0.65 m
    e 9 posições da reserva frontal (Y negativo), centralizando o conjunto.
    """
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
    # Deslocamos ligeiramente o campo para +Y (0.55 m) para que o conjunto
    # (Campo + Reserva Frontal em -Y) fique perfeitamente centrado na origem
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

    # Reserva frontal no lado Y negativo
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


def is_in_exclusion_zone(x, y, layout, extra_radius=0.0):
    """
    Seção 9 — Máscaras de exclusão:
    1. Interior de todas as casas + 2. Faixa completa de reserva + 3. Margem de segurança
    4. Corredor visual entre a câmera (Y negativo) e a borda frontal.
    Considera o raio/alcance horizontal (`extra_radius`) dos galhos/objetos.
    """
    p_min_x, p_max_x, p_min_y, p_max_y = layout["playable_bounds"]
    margin = CONFIG["exclusion_margin"] + extra_radius

    # Regiões 1, 2 e 3: Retângulo do conjunto jogável expandido pela margem + raio do objeto
    if (p_min_x - margin) <= x <= (p_max_x + margin) and (p_min_y - margin) <= y <= (p_max_y + margin):
        return True

    # Região 4: Corredor visual frontal entre a câmera (Y < playable_min_y) e a frente do tabuleiro
    if y < (p_min_y + 0.4):
        # Abre em leque na direção da câmera para não obstruir a borda frontal
        t_cam = max(0.0, (p_min_y - y) / 10.0)
        corridor_half_w = (p_max_x + 0.35 + extra_radius) + t_cam * 2.2
        if abs(x) <= corridor_half_w:
            return True

    return False


# ==============================================================================
# 15. MATERIAIS E DIREÇÃO VISUAL (Procedurais Nativos, Escala Coerente, Sem Plástico)
# ==============================================================================
def create_materials():
    mats = {}

    def _new_mat(name):
        m = bpy.data.materials.get(name)
        if m:
            bpy.data.materials.remove(m)
        m = bpy.data.materials.new(name=name)
        if hasattr(m, "use_nodes") and not m.use_nodes:
            m.use_nodes = True
        return m

    # 1. Solo Principal: Terra vermelha compactada, ocre queimado, erosão e manchas LOCALIZADAS de solo rachado
    m_soil = _new_mat("Mat_Terrain_RedEarth")
    nt = m_soil.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.94
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.14

    tex_coord = nodes.new("ShaderNodeTexCoord")
    noise_macro = nodes.new("ShaderNodeTexNoise")
    noise_macro.inputs["Scale"].default_value = 0.42
    noise_macro.inputs["Detail"].default_value = 6.0
    noise_macro.inputs["Roughness"].default_value = 0.68
    links.new(tex_coord.outputs["Object"], noise_macro.inputs["Vector"])

    # Máscara de manchas localizadas (apenas ~25% do solo externo exibe rachaduras visíveis)
    noise_patch = nodes.new("ShaderNodeTexNoise")
    noise_patch.inputs["Scale"].default_value = 0.22
    noise_patch.inputs["Detail"].default_value = 3.0
    links.new(tex_coord.outputs["Object"], noise_patch.inputs["Vector"])

    ramp_patch = nodes.new("ShaderNodeValToRGB")
    ramp_patch.color_ramp.elements[0].position = 0.56
    ramp_patch.color_ramp.elements[0].color = (1.0, 1.0, 1.0, 1.0)  # Sem rachadura (terra compactada)
    ramp_patch.color_ramp.elements[1].position = 0.72
    ramp_patch.color_ramp.elements[1].color = (0.0, 0.0, 0.0, 1.0)  # Mancha localizada de solo rachado
    links.new(noise_patch.outputs["Fac"], ramp_patch.inputs["Fac"])

    vor_cracks = nodes.new("ShaderNodeTexVoronoi")
    vor_cracks.feature = 'DISTANCE_TO_EDGE'
    vor_cracks.inputs["Scale"].default_value = 4.2
    links.new(tex_coord.outputs["Object"], vor_cracks.inputs["Vector"])

    ramp_cracks = nodes.new("ShaderNodeValToRGB")
    ramp_cracks.color_ramp.elements[0].position = 0.012
    ramp_cracks.color_ramp.elements[0].color = (0.45, 0.45, 0.45, 1.0)  # Fissura discreta
    ramp_cracks.color_ramp.elements[1].position = 0.055
    ramp_cracks.color_ramp.elements[1].color = (1.0, 1.0, 1.0, 1.0)
    links.new(vor_cracks.outputs["Distance"], ramp_cracks.inputs["Fac"])

    # Combina a máscara localizada com as rachaduras
    mix_crack_mask = nodes.new("ShaderNodeMath")
    mix_crack_mask.operation = 'MAXIMUM'
    links.new(ramp_cracks.outputs["Color"], mix_crack_mask.inputs[0])
    links.new(ramp_patch.outputs["Color"], mix_crack_mask.inputs[1])

    mix_tex = nodes.new("ShaderNodeMath")
    mix_tex.operation = 'MULTIPLY'
    links.new(noise_macro.outputs["Fac"], mix_tex.inputs[0])
    links.new(mix_crack_mask.outputs["Value"], mix_tex.inputs[1])

    ramp_soil = nodes.new("ShaderNodeValToRGB")
    ramp_soil.color_ramp.elements[0].position = 0.16
    ramp_soil.color_ramp.elements[0].color = (0.26, 0.11, 0.065, 1.0)   # Terra vermelha escura / fissura
    e_s1 = ramp_soil.color_ramp.elements.new(0.48)
    e_s1.color = (0.40, 0.18, 0.10, 1.0)                                # Terra vermelha compactada
    ramp_soil.color_ramp.elements[2].position = 0.85
    ramp_soil.color_ramp.elements[2].color = (0.52, 0.26, 0.15, 1.0)    # Poeira ocre queimada
    links.new(mix_tex.outputs["Value"], ramp_soil.inputs["Fac"])

    bump_soil = nodes.new("ShaderNodeBump")
    bump_soil.inputs["Strength"].default_value = 0.22
    bump_soil.inputs["Distance"].default_value = 0.035
    links.new(mix_tex.outputs["Value"], bump_soil.inputs["Height"])
    links.new(bump_soil.outputs["Normal"], bsdf.inputs["Normal"])
    links.new(ramp_soil.outputs["Color"], bsdf.inputs["Base Color"])
    mats["terrain"] = m_soil

    # 2. Casas Hexagonais: Terra batida marcada no chão com leve variação por objeto
    m_hex = _new_mat("Mat_Board_HexClay")
    nt = m_hex.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Roughness"].default_value = 0.89
    if "Specular IOR Level" in bsdf.inputs:
        bsdf.inputs["Specular IOR Level"].default_value = 0.20

    obj_info = nodes.new("ShaderNodeObjectInfo")
    tex_c = nodes.new("ShaderNodeTexCoord")
    noise_h = nodes.new("ShaderNodeTexNoise")
    noise_h.inputs["Scale"].default_value = 1.6
    noise_h.inputs["Detail"].default_value = 4.0
    links.new(tex_c.outputs["Object"], noise_h.inputs["Vector"])

    mix_val = nodes.new("ShaderNodeMath")
    mix_val.operation = 'MULTIPLY_ADD'
    mix_val.inputs[1].default_value = 0.45
    links.new(obj_info.outputs["Random"], mix_val.inputs[0])
    links.new(noise_h.outputs["Fac"], mix_val.inputs[2])

    ramp_hex = nodes.new("ShaderNodeValToRGB")
    ramp_hex.color_ramp.elements[0].position = 0.15
    ramp_hex.color_ramp.elements[0].color = (0.36, 0.17, 0.10, 1.0)  # Barro compactado
    ramp_hex.color_ramp.elements[1].position = 0.88
    ramp_hex.color_ramp.elements[1].color = (0.51, 0.26, 0.15, 1.0)  # Ocre terroso claro
    links.new(mix_val.outputs["Value"], ramp_hex.inputs["Fac"])
    links.new(ramp_hex.outputs["Color"], bsdf.inputs["Base Color"])

    bump_h = nodes.new("ShaderNodeBump")
    bump_h.inputs["Strength"].default_value = 0.10
    bump_h.inputs["Distance"].default_value = 0.02
    links.new(noise_h.outputs["Fac"], bump_h.inputs["Height"])
    links.new(bump_h.outputs["Normal"], bsdf.inputs["Normal"])
    mats["hex_surface"] = m_hex

    # 3. Sulcos das casas e da reserva: Terra escavada sombreada (sem emissão)
    m_groove = _new_mat("Mat_Board_Groove")
    bsdf_g = m_groove.node_tree.nodes.get("Principled BSDF")
    bsdf_g.inputs["Base Color"].default_value = (0.14, 0.06, 0.035, 1.0)
    bsdf_g.inputs["Roughness"].default_value = 0.96
    if "Specular IOR Level" in bsdf_g.inputs:
        bsdf_g.inputs["Specular IOR Level"].default_value = 0.08
    mats["groove"] = m_groove

    # 4. Reserva Frontal: Solo compactado levemente mais ocre/bege para leitura imediata
    m_res = _new_mat("Mat_Reserve_Earth")
    nt = m_res.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_r = nodes.get("Principled BSDF")
    bsdf_r.inputs["Roughness"].default_value = 0.90
    noise_r = nodes.new("ShaderNodeTexNoise")
    noise_r.inputs["Scale"].default_value = 2.0
    ramp_r = nodes.new("ShaderNodeValToRGB")
    ramp_r.color_ramp.elements[0].position = 0.2
    ramp_r.color_ramp.elements[0].color = (0.41, 0.20, 0.12, 1.0)
    ramp_r.color_ramp.elements[1].position = 0.8
    ramp_r.color_ramp.elements[1].color = (0.54, 0.29, 0.17, 1.0)
    links.new(noise_r.outputs["Fac"], ramp_r.inputs["Fac"])
    links.new(ramp_r.outputs["Color"], bsdf_r.inputs["Base Color"])
    mats["reserve_surface"] = m_res

    # 5. Floresta Branca: Casca cinza-prata, bege pálido e cinza amarronzado nas fissuras
    m_tree = _new_mat("Mat_WhiteForest_Bark")
    nt = m_tree.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_t = nodes.get("Principled BSDF")
    bsdf_t.inputs["Roughness"].default_value = 0.88
    if "Specular IOR Level" in bsdf_t.inputs:
        bsdf_t.inputs["Specular IOR Level"].default_value = 0.15

    tc_t = nodes.new("ShaderNodeTexCoord")
    map_t = nodes.new("ShaderNodeMapping")
    map_t.inputs["Scale"].default_value = (2.5, 2.5, 0.65)  # Estirado ao longo do tronco
    links.new(tc_t.outputs["Object"], map_t.inputs["Vector"])

    noise_bark = nodes.new("ShaderNodeTexNoise")
    noise_bark.inputs["Scale"].default_value = 3.8
    noise_bark.inputs["Detail"].default_value = 6.0
    noise_bark.inputs["Roughness"].default_value = 0.72
    links.new(map_t.outputs["Vector"], noise_bark.inputs["Vector"])

    ramp_bark = nodes.new("ShaderNodeValToRGB")
    ramp_bark.color_ramp.elements[0].position = 0.22
    ramp_bark.color_ramp.elements[0].color = (0.34, 0.28, 0.23, 1.0)  # Cinza amarronzado nas fissuras
    e_mid = ramp_bark.color_ramp.elements.new(0.52)
    e_mid.color = (0.64, 0.59, 0.52, 1.0)                             # Bege pálido / cinza-prata
    ramp_bark.color_ramp.elements[2].position = 0.84
    ramp_bark.color_ramp.elements[2].color = (0.78, 0.74, 0.67, 1.0)  # Branco sujo / casca seca
    links.new(noise_bark.outputs["Fac"], ramp_bark.inputs["Fac"])
    links.new(ramp_bark.outputs["Color"], bsdf_t.inputs["Base Color"])

    bump_bark = nodes.new("ShaderNodeBump")
    bump_bark.inputs["Strength"].default_value = 0.24
    bump_bark.inputs["Distance"].default_value = 0.03
    links.new(noise_bark.outputs["Fac"], bump_bark.inputs["Height"])
    links.new(bump_bark.outputs["Normal"], bsdf_t.inputs["Normal"])
    mats["white_forest"] = m_tree

    # 6. Cactos Colunares: Verde-oliva escuro e verde acinzentado fosco
    m_cactus = _new_mat("Mat_Cactus_Olive")
    nt = m_cactus.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_c = nodes.get("Principled BSDF")
    bsdf_c.inputs["Roughness"].default_value = 0.84
    if "Specular IOR Level" in bsdf_c.inputs:
        bsdf_c.inputs["Specular IOR Level"].default_value = 0.16

    noise_c = nodes.new("ShaderNodeTexNoise")
    noise_c.inputs["Scale"].default_value = 4.5
    noise_c.inputs["Detail"].default_value = 3.0
    ramp_c = nodes.new("ShaderNodeValToRGB")
    ramp_c.color_ramp.elements[0].position = 0.25
    ramp_c.color_ramp.elements[0].color = (0.14, 0.20, 0.11, 1.0)  # Verde-oliva escuro
    ramp_c.color_ramp.elements[1].position = 0.78
    ramp_c.color_ramp.elements[1].color = (0.25, 0.31, 0.21, 1.0)  # Verde acinzentado seco
    links.new(noise_c.outputs["Fac"], ramp_c.inputs["Fac"])
    links.new(ramp_c.outputs["Color"], bsdf_c.inputs["Base Color"])
    mats["cactus"] = m_cactus

    # 7. Caveira Bovina: Osso envelhecido, bege, ocre suave, manchas marrons e rugosidade alta
    m_skull = _new_mat("Mat_Skull_AgedBone")
    nt = m_skull.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_s = nodes.get("Principled BSDF")
    bsdf_s.inputs["Roughness"].default_value = 0.87
    if "Specular IOR Level" in bsdf_s.inputs:
        bsdf_s.inputs["Specular IOR Level"].default_value = 0.14

    tc_s = nodes.new("ShaderNodeTexCoord")
    noise_s = nodes.new("ShaderNodeTexNoise")
    noise_s.inputs["Scale"].default_value = 6.5
    noise_s.inputs["Detail"].default_value = 6.0
    links.new(tc_s.outputs["Object"], noise_s.inputs["Vector"])

    ramp_s = nodes.new("ShaderNodeValToRGB")
    ramp_s.color_ramp.elements[0].position = 0.20
    ramp_s.color_ramp.elements[0].color = (0.36, 0.25, 0.16, 1.0)  # Manchas marrons / fissuras
    e_bone = ramp_s.color_ramp.elements.new(0.50)
    e_bone.color = (0.68, 0.58, 0.44, 1.0)                         # Ocre suave / bege envelhecido
    ramp_s.color_ramp.elements[2].position = 0.82
    ramp_s.color_ramp.elements[2].color = (0.81, 0.75, 0.63, 1.0)  # Osso seco alvejado
    links.new(noise_s.outputs["Fac"], ramp_s.inputs["Fac"])
    links.new(ramp_s.outputs["Color"], bsdf_s.inputs["Base Color"])

    bump_s = nodes.new("ShaderNodeBump")
    bump_s.inputs["Strength"].default_value = 0.20
    bump_s.inputs["Distance"].default_value = 0.015
    links.new(noise_s.outputs["Fac"], bump_s.inputs["Height"])
    links.new(bump_s.outputs["Normal"], bsdf_s.inputs["Normal"])
    mats["skull_bone"] = m_skull

    # 8. Chifres Desgastados da Caveira
    m_horn = _new_mat("Mat_Skull_WeatheredHorn")
    bsdf_hn = m_horn.node_tree.nodes.get("Principled BSDF")
    bsdf_hn.inputs["Base Color"].default_value = (0.24, 0.18, 0.13, 1.0)
    bsdf_hn.inputs["Roughness"].default_value = 0.86
    mats["skull_horn"] = m_horn

    # 9. Mourão de Madeira Rachada
    m_wood = _new_mat("Mat_Fence_CrackedWood")
    nt = m_wood.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_w = nodes.get("Principled BSDF")
    bsdf_w.inputs["Roughness"].default_value = 0.93
    tc_w = nodes.new("ShaderNodeTexCoord")
    map_w = nodes.new("ShaderNodeMapping")
    map_w.inputs["Scale"].default_value = (4.0, 4.0, 0.5)
    links.new(tc_w.outputs["Object"], map_w.inputs["Vector"])
    noise_w = nodes.new("ShaderNodeTexNoise")
    noise_w.inputs["Scale"].default_value = 5.0
    noise_w.inputs["Detail"].default_value = 6.0
    links.new(map_w.outputs["Vector"], noise_w.inputs["Vector"])
    ramp_w = nodes.new("ShaderNodeValToRGB")
    ramp_w.color_ramp.elements[0].position = 0.25
    ramp_w.color_ramp.elements[0].color = (0.18, 0.12, 0.08, 1.0)
    ramp_w.color_ramp.elements[1].position = 0.78
    ramp_w.color_ramp.elements[1].color = (0.38, 0.27, 0.19, 1.0)
    links.new(noise_w.outputs["Fac"], ramp_w.inputs["Fac"])
    links.new(ramp_w.outputs["Color"], bsdf_w.inputs["Base Color"])
    mats["fence_wood"] = m_wood

    # 10. Arame Farpado Antigo
    m_wire = _new_mat("Mat_Fence_OldWire")
    bsdf_wr = m_wire.node_tree.nodes.get("Principled BSDF")
    bsdf_wr.inputs["Base Color"].default_value = (0.22, 0.14, 0.10, 1.0)
    bsdf_wr.inputs["Metallic"].default_value = 0.65
    bsdf_wr.inputs["Roughness"].default_value = 0.72
    mats["wire"] = m_wire

    # 11. Vegetação Baixa (Capim palha / arbustos secos) e Pedras
    m_straw = _new_mat("Mat_Undergrowth_Straw")
    bsdf_st = m_straw.node_tree.nodes.get("Principled BSDF")
    bsdf_st.inputs["Base Color"].default_value = (0.48, 0.36, 0.21, 1.0)
    bsdf_st.inputs["Roughness"].default_value = 0.91
    mats["straw"] = m_straw

    m_rock = _new_mat("Mat_DryRock")
    nt = m_rock.node_tree
    nodes, links = nt.nodes, nt.links
    bsdf_rk = nodes.get("Principled BSDF")
    bsdf_rk.inputs["Roughness"].default_value = 0.89
    noise_rk = nodes.new("ShaderNodeTexNoise")
    noise_rk.inputs["Scale"].default_value = 3.2
    ramp_rk = nodes.new("ShaderNodeValToRGB")
    ramp_rk.color_ramp.elements[0].position = 0.25
    ramp_rk.color_ramp.elements[0].color = (0.27, 0.19, 0.14, 1.0)
    ramp_rk.color_ramp.elements[1].position = 0.80
    ramp_rk.color_ramp.elements[1].color = (0.46, 0.34, 0.25, 1.0)
    links.new(noise_rk.outputs["Fac"], ramp_rk.inputs["Fac"])
    links.new(ramp_rk.outputs["Color"], bsdf_rk.inputs["Base Color"])
    mats["rock"] = m_rock

    # 12. Anomalia C: Marcas que cessam na poeira (depressão escura de terra removida)
    m_tracks = _new_mat("Mat_Horror_DustTracks")
    bsdf_tr = m_tracks.node_tree.nodes.get("Principled BSDF")
    bsdf_tr.inputs["Base Color"].default_value = (0.20, 0.085, 0.048, 1.0)
    bsdf_tr.inputs["Roughness"].default_value = 0.96
    mats["dust_tracks"] = m_tracks

    return mats


# ==============================================================================
# 6. TERRENO CONTÍNUO (Integra área jogável, reserva, laterais e fundo)
# ==============================================================================
def terrain_height_at(x, y, layout):
    """
    Calcula a elevação Z do terreno contínuo:
    - Região jogável (Campo + Reserva + Margem): estritamente plana (Z = 0.0).
    - Região externa: ondulações suaves, pequenos barrancos laterais e trilha
      erodida ao fundo (+Y), sem cortar nem criar plataforma separada.
    """
    p_min_x, p_max_x, p_min_y, p_max_y = layout["playable_bounds"]

    dx = 0.0
    if x < p_min_x - 0.35:
        dx = (p_min_x - 0.35) - x
    elif x > p_max_x + 0.35:
        dx = x - (p_max_x + 0.35)

    dy = 0.0
    if y < p_min_y - 0.45:
        dy = (p_min_y - 0.45) - y
    elif y > p_max_y + 0.45:
        dy = y - (p_max_y + 0.45)

    dist_out = math.sqrt(dx * dx + dy * dy)
    if dist_out <= 0.001:
        return 0.0

    # Transição suave fora da área jogável
    blend = min(1.0, dist_out / 3.8)
    smooth = blend * blend * (3.0 - 2.0 * blend)

    # Na frente da câmera (Y < p_min_y), manter terreno baixo para nunca obstruir a visão
    if y < p_min_y:
        front_wave = 0.08 * math.sin(x * 0.35) * math.cos(y * 0.4)
        return smooth * max(-0.12, min(0.14, front_wave))

    # Trilha sinuosa de terra vermelha erodida ao fundo (Y > p_max_y)
    trail_factor = 1.0
    if y > p_max_y:
        trail_center_x = 1.15 * math.sin((y - p_max_y) * 0.32) - 0.35
        dist_trail = abs(x - trail_center_x)
        # Deixa um leito mais baixo para o caminho que parece retornar (Anomalia A)
        trail_factor = min(1.0, max(0.12, (dist_trail - 0.85) / 2.2))

    # Pequenos barrancos laterais e ondulações naturais da Caatinga
    bank_rise = (min(dist_out, 14.0) ** 1.18) * 0.16 * trail_factor
    undulation = (
        0.22 * math.sin(x * 0.28 + 0.7) * math.cos(y * 0.24)
        + 0.11 * math.sin(x * 0.65 - y * 0.52)
    ) * smooth * trail_factor

    return max(-0.08, bank_rise + undulation)


def build_continuous_terrain(sub_cols, layout, mats):
    bm = bmesh.new()
    # Malha ampla (76m x 76m) que se estende muito além do enquadramento da câmera
    bmesh.ops.create_grid(bm, x_segments=128, y_segments=128, size=38.0)

    for v in bm.verts:
        # Desloca centro da malha para cobrir mais o horizonte ao fundo (+Y)
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
# 7. GRADE HEXAGONAL (8x8, Ponta para Cima, Sulcos Rasos Marcados na Terra)
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
        # Geometria individual com sulco perimetral escavado na terra e centro nivelado,
        # sem elevação de bloco e sem sobreposição coplanar.
        r_outer = R - 0.003
        r_groove_in = R - groove_w
        r_inner = R - groove_w * 1.65

        z_rim = 0.004
        z_groove = -groove_d
        z_surface = 0.006 + rng.uniform(-0.001, 0.001)

        ring_out = []
        ring_grv = []
        ring_in = []

        for k in range(6):
            # Ponta para cima (vértices em 30°, 90°, 150°, 210°, 270°, 330°)
            ang = math.radians(30.0 + k * 60.0)
            # Discreto desgaste orgânico nos vértices
            wear = 1.0 - rng.uniform(0.0, 0.012)
            ca, sa = math.cos(ang), math.sin(ang)
            ring_out.append(bm.verts.new((ca * r_outer * wear, sa * r_outer * wear, z_rim)))
            ring_grv.append(bm.verts.new((ca * r_groove_in * wear, sa * r_groove_in * wear, z_groove)))
            ring_in.append(bm.verts.new((ca * r_inner * wear, sa * r_inner * wear, z_surface)))

        for k in range(6):
            k2 = (k + 1) % 6
            # Face do sulco externo (material escuro de sulco)
            f_grv1 = bm.faces.new((ring_out[k], ring_out[k2], ring_grv[k2], ring_grv[k]))
            f_grv1.material_index = 1
            # Rampa interna do sulco
            f_grv2 = bm.faces.new((ring_grv[k], ring_grv[k2], ring_in[k2], ring_in[k]))
            f_grv2.material_index = 1

        # Superfície interna da casa alinhada ao solo
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
        link_to_collection(hex_obj, sub_cols["02_BOARD"])


# ==============================================================================
# 8. RESERVA FRONTAL (9 Posições no Lado Y Negativo, Integradas ao Solo)
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
        # Marcador retangular chanfrado escavado no mesmo solo, sem degraus ou pedestal
        corners_out = [
            (-hw, -hd), (hw, -hd), (hw, hd), (-hw, hd)
        ]
        corners_grv = [
            (-(hw - groove_w), -(hd - groove_w)),
            ((hw - groove_w), -(hd - groove_w)),
            ((hw - groove_w), (hd - groove_w)),
            (-(hw - groove_w), (hd - groove_w)),
        ]
        corners_in = [
            (-(hw - groove_w * 1.7), -(hd - groove_w * 1.7)),
            ((hw - groove_w * 1.7), -(hd - groove_w * 1.7)),
            ((hw - groove_w * 1.7), (hd - groove_w * 1.7)),
            (-(hw - groove_w * 1.7), (hd - groove_w * 1.7)),
        ]

        v_out = [bm.verts.new((x, y, 0.004)) for x, y in corners_out]
        v_grv = [bm.verts.new((x, y, -groove_d)) for x, y in corners_grv]
        v_in = [bm.verts.new((x, y, 0.005)) for x, y in corners_in]

        for k in range(4):
            k2 = (k + 1) % 4
            fg1 = bm.faces.new((v_out[k], v_out[k2], v_grv[k2], v_grv[k]))
            fg1.material_index = 1
            fg2 = bm.faces.new((v_grv[k], v_grv[k2], v_in[k2], v_in[k]))
            fg2.material_index = 1

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
        link_to_collection(slot_obj, sub_cols["03_RESERVE"])


# ==============================================================================
# 10. FLORESTA BRANCA (5 Variantes Botânicas e Silhuetas Distintas)
# ==============================================================================
def create_pale_tree_mesh(variant_letter, seed_offset, mat_bark):
    """
    Gera uma das 5 variantes de árvores secas da Caatinga (Tree_Pale_Variant_A..E)
    com diferenças em altura, espessura, inclinação, bifurcações e densidade de ramos,
    afinadas suavemente até as pontas.
    """
    rng = random.Random(CONFIG["random_seed"] + seed_offset)
    specs = {
        "A": {"height": 4.2, "radius": 0.21, "lean": (0.35, 0.15), "forks": 4, "twigs": 3},
        "B": {"height": 5.4, "radius": 0.26, "lean": (-0.42, 0.22), "forks": 5, "twigs": 4},
        "C": {"height": 3.5, "radius": 0.18, "lean": (0.55, -0.18), "forks": 6, "twigs": 3},
        "D": {"height": 6.1, "radius": 0.30, "lean": (-0.25, -0.30), "forks": 5, "twigs": 4},
        "E": {"height": 4.8, "radius": 0.23, "lean": (0.18, 0.45), "forks": 6, "twigs": 4},
    }[variant_letter]

    curve_data = bpy.data.curves.new(f"Tree_Pale_Variant_{variant_letter}_Curve", type='CURVE')
    curve_data.dimensions = '3D'
    curve_data.bevel_depth = 1.0
    curve_data.bevel_resolution = 3
    curve_data.use_fill_caps = True

    H = specs["height"]
    R0 = specs["radius"]
    lx, ly = specs["lean"]

    # Raízes expostas baixas agarrando o solo
    for r_i in range(3):
        ra = (r_i / 3.0) * math.pi * 2.0 + rng.uniform(-0.35, 0.35)
        rs = curve_data.splines.new('POLY')
        r_pts = [
            (math.cos(ra) * R0 * 0.3, math.sin(ra) * R0 * 0.3, 0.28, R0 * 0.52),
            (math.cos(ra) * R0 * 1.4, math.sin(ra) * R0 * 1.4, 0.05, R0 * 0.26),
            (math.cos(ra) * R0 * 2.1, math.sin(ra) * R0 * 2.1, -0.12, R0 * 0.07),
        ]
        rs.points.add(len(r_pts) - 1)
        for i, (px, py, pz, pr) in enumerate(r_pts):
            rs.points[i].co = (px, py, pz, 1.0)
            rs.points[i].radius = pr

    # Tronco tortuoso principal
    ts = curve_data.splines.new('POLY')
    t_pts = [
        (0.0, 0.0, -0.15, R0 * 1.15),
        (lx * 0.22 + rng.uniform(-0.15, 0.15), ly * 0.22 + rng.uniform(-0.15, 0.15), H * 0.24, R0 * 0.82),
        (lx * 0.52 + rng.uniform(-0.22, 0.22), ly * 0.52 + rng.uniform(-0.22, 0.22), H * 0.50, R0 * 0.56),
        (lx * 0.82 + rng.uniform(-0.20, 0.20), ly * 0.82 + rng.uniform(-0.20, 0.20), H * 0.76, R0 * 0.32),
        (lx * 1.05 + rng.uniform(-0.15, 0.15), ly * 1.05 + rng.uniform(-0.15, 0.15), H * 0.96, R0 * 0.10),
    ]
    ts.points.add(len(t_pts) - 1)
    for i, (px, py, pz, pr) in enumerate(t_pts):
        ts.points[i].co = (px, py, pz, 1.0)
        ts.points[i].radius = pr

    # Bifurcações primárias e ramos finos entrelaçados
    n_forks = specs["forks"]
    for b in range(n_forks):
        ang = (b / float(n_forks)) * math.pi * 2.0 + rng.uniform(-0.32, 0.32)
        anchor = t_pts[rng.choice([2, 3])]
        sx, sy, sz, sr = anchor
        reach = rng.uniform(1.15, 2.05)
        dx = math.cos(ang) * reach + lx * 0.25
        dy = math.sin(ang) * reach + ly * 0.25
        dz = rng.uniform(0.75, 1.55)

        bs = curve_data.splines.new('POLY')
        b_pts = [
            (sx, sy, sz, sr * 0.75),
            (sx + dx * 0.42, sy + dy * 0.42, sz + dz * 0.48, sr * 0.44),
            (sx + dx * 0.78, sy + dy * 0.78, sz + dz * 0.84, sr * 0.20),
            (sx + dx, sy + dy, sz + dz * 0.96, 0.018),
        ]
        bs.points.add(len(b_pts) - 1)
        for i, (px, py, pz, pr) in enumerate(b_pts):
            bs.points[i].co = (px, py, pz, 1.0)
            bs.points[i].radius = pr

        for tw in range(specs["twigs"]):
            tx, ty, tz, tr = b_pts[1 if tw % 2 == 0 else 2]
            t_ang = ang + rng.uniform(-0.85, 0.85)
            t_len = rng.uniform(0.55, 1.05)
            tw_s = curve_data.splines.new('POLY')
            tw_pts = [
                (tx, ty, tz, tr * 0.68),
                (tx + math.cos(t_ang) * t_len * 0.55, ty + math.sin(t_ang) * t_len * 0.55, tz + 0.38, tr * 0.30),
                (tx + math.cos(t_ang) * t_len, ty + math.sin(t_ang) * t_len, tz + 0.58, 0.010),
            ]
            tw_s.points.add(len(tw_pts) - 1)
            for i, (px, py, pz, pr) in enumerate(tw_pts):
                tw_s.points[i].co = (px, py, pz, 1.0)
                tw_s.points[i].radius = pr

    temp_obj = bpy.data.objects.new(f"Temp_Tree_{variant_letter}", curve_data)
    bpy.context.scene.collection.objects.link(temp_obj)
    bpy.context.view_layer.objects.active = temp_obj
    temp_obj.select_set(True)
    bpy.ops.object.convert(target='MESH')
    mesh = temp_obj.data.copy()
    mesh.name = f"Tree_Pale_Variant_{variant_letter}_Mesh"
    mesh.materials.append(mat_bark)
    bpy.data.objects.remove(temp_obj, do_unlink=True)
    bpy.data.curves.remove(curve_data)
    return mesh


def build_white_forest(sub_cols, layout, mats):
    rng = random.Random(CONFIG["random_seed"] + 100)
    variant_keys = ["A", "B", "C", "D", "E"]
    variant_meshes = {
        k: create_pale_tree_mesh(k, idx * 17, mats["white_forest"])
        for idx, k in enumerate(variant_keys)
    }

    # Posições em múltiplas camadas: grupos densos no fundo (+Y), árvores médias nas laterais,
    # intervalos orgânicos entre grupos e árvores maiores nas extremidades externas.
    # Nenhuma árvore bloqueia a frente (-Y) ou invade a máscara de exclusão.
    tree_placements = [
        # Camada lateral esquerda próxima (Oeste)
        ("A", -6.5, -2.0, 0.35, 0.90),
        ("C", -6.8,  0.4, 1.20, 0.88),
        ("B", -6.4,  2.8, -0.45, 0.94),
        ("E", -7.2,  4.5, 2.10, 0.98),
        # Camada lateral esquerda externa
        ("D", -8.8, -3.5, 0.65, 1.05),
        ("B", -9.2, -0.5, 0.80, 1.08),
        ("A", -9.5,  2.4, -1.10, 1.04),
        ("D", -10.8, 4.8, 0.50, 1.15),

        # Camada lateral direita próxima (Leste)
        ("C",  6.5, -1.8, -0.60, 0.88),
        ("A",  6.8,  0.7, 2.40, 0.92),
        ("E",  6.4,  3.1, -1.35, 0.95),
        ("B",  7.3,  4.7, 0.90, 1.00),
        # Camada lateral direita externa
        ("D",  8.9, -3.3, -0.55, 1.06),
        ("B",  9.3, -0.2, -0.75, 1.08),
        ("A",  9.6,  2.6, 1.55, 1.05),
        ("D", 10.9,  5.0, -2.10, 1.16),

        # Camada de fundo imediata (Borda Norte do campo, Y = 4.6 a 5.6, abrindo passagem para a trilha central)
        ("C", -4.6,  4.7, 0.30, 0.86),
        ("A", -2.7,  4.9, 1.65, 0.88),
        ("E",  2.6,  4.8, -0.85, 0.88),
        ("B",  4.7,  4.7, 2.15, 0.90),
        ("D", -6.2,  5.5, -0.40, 1.00),
        ("B",  6.3,  5.6, 1.15, 0.98),

        # Camada de fundo intermediária (Mata Branca densa, Y = 6.6 a 8.2)
        ("B", -5.2,  6.8, 0.95, 1.02),
        ("E", -3.2,  7.1, -1.40, 0.98),
        ("C", -1.6,  6.7, 0.45, 0.85),
        ("A",  1.7,  6.8, -0.60, 0.86),
        ("D",  3.5,  7.2, 0.65, 1.04),
        ("B",  5.5,  6.9, -2.05, 1.02),
        ("E", -8.0,  7.5, 1.80, 1.10),
        ("D",  8.2,  7.6, -0.50, 1.12),

        # Camada de horizonte ao fundo (Silhuetas altas, Y = 9.2 a 12.0)
        ("D", -6.8,  9.6, 0.30, 1.18),
        ("B", -4.2, 10.0, 2.15, 1.12),
        ("A", -2.0, 10.4, -0.90, 1.06),
        ("E",  2.1, 10.5, 1.40, 1.08),
        ("D",  4.4, 10.1, -1.70, 1.15),
        ("B",  7.0,  9.7, 0.85, 1.18),
        ("D", -9.8, 10.8, -0.40, 1.24),
        ("D", 10.0, 11.0, 1.10, 1.24),
    ]

    counts = {k: 0 for k in variant_keys}
    for v_key, tx, ty, rot_z, scale_f in tree_placements:
        # Verifica máscara de exclusão considerando raio seguro de 0.95 m
        if is_in_exclusion_zone(tx, ty, layout, extra_radius=0.95):
            continue
        counts[v_key] += 1
        idx = counts[v_key]
        obj_name = f"Tree_Pale_Variant_{v_key}_{idx:02d}"
        tz = terrain_height_at(tx, ty, layout) - 0.05
        t_obj = bpy.data.objects.new(obj_name, variant_meshes[v_key])
        t_obj.location = Vector((tx, ty, tz))
        t_obj.rotation_euler = Euler((rng.uniform(-0.04, 0.04), rng.uniform(-0.04, 0.04), rot_z), 'XYZ')
        t_obj.scale = Vector((scale_f, scale_f, scale_f))
        link_to_collection(t_obj, sub_cols["04_WHITE_FOREST"])


# ==============================================================================
# 11. CACTOS COLUNARES (3 Variantes com Sulcos Longitudinais, Secundários à Floresta)
# ==============================================================================
def _add_ribbed_cactus_stem(bm, base_co, height, radius, ribs=7, bend=(0.0, 0.0)):
    segs_z = 9
    segs_r = ribs * 2
    prev_ring = None
    for sz in range(segs_z + 1):
        t = sz / float(segs_z)
        taper = math.sin(min(1.0, t * 4.5) * (math.pi * 0.5)) * math.cos(max(0.0, (t - 0.84) / 0.16) * (math.pi * 0.48))
        cx = base_co[0] + bend[0] * (t ** 1.5)
        cy = base_co[1] + bend[1] * (t ** 1.5)
        cz = base_co[2] + t * height
        ring = []
        for sr in range(segs_r):
            ang = (sr / float(segs_r)) * math.pi * 2.0
            rib_f = 0.80 + 0.20 * (1.0 if sr % 2 == 0 else -1.0)
            r_c = max(0.015, radius * taper * rib_f)
            ring.append(bm.verts.new((cx + math.cos(ang) * r_c, cy + math.sin(ang) * r_c, cz)))
        if prev_ring:
            for sr in range(segs_r):
                sr2 = (sr + 1) % segs_r
                bm.faces.new((prev_ring[sr], prev_ring[sr2], ring[sr2], ring[sr]))
        prev_ring = ring


def create_cactus_variant_mesh(variant_key, mat_cactus):
    bm = bmesh.new()
    if variant_key == "A":
        # Variante 1: Coluna simples
        _add_ribbed_cactus_stem(bm, (0.0, 0.0, -0.08), 2.35, 0.16, ribs=7, bend=(0.06, -0.04))
    elif variant_key == "B":
        # Variante 2: Coluna com uma ramificação
        _add_ribbed_cactus_stem(bm, (0.0, 0.0, -0.08), 2.75, 0.18, ribs=8, bend=(-0.05, 0.03))
        _add_ribbed_cactus_stem(bm, (0.14, 0.0, 1.05), 1.35, 0.13, ribs=7, bend=(0.38, 0.08))
    else:
        # Variante 3: Grupo de colunas com alturas diferentes (Xique-Xique / Mandacaru em touceira)
        _add_ribbed_cactus_stem(bm, (0.0, 0.0, -0.08), 2.60, 0.16, ribs=8, bend=(0.04, 0.04))
        _add_ribbed_cactus_stem(bm, (-0.26, 0.14, -0.08), 1.85, 0.14, ribs=7, bend=(-0.22, 0.12))
        _add_ribbed_cactus_stem(bm, (0.24, -0.16, -0.08), 1.40, 0.12, ribs=7, bend=(0.20, -0.14))

    mesh = bpy.data.meshes.new(f"Cactus_Columnar_Variant_{variant_key}_Mesh")
    bm.to_mesh(mesh)
    bm.free()
    for p in mesh.polygons:
        p.use_smooth = True
    mesh.materials.append(mat_cactus)
    return mesh


def build_cacti(sub_cols, layout, mats):
    meshes = {
        k: create_cactus_variant_mesh(k, mats["cactus"])
        for k in ("A", "B", "C")
    }
    placements = [
        ("B", -6.9, -3.2, 0.4, 1.00),
        ("A", -8.8, -2.5, 1.6, 0.95),
        ("C", -6.8,  4.4, -0.8, 1.02),
        ("B",  7.1, -2.9, -1.2, 0.98),
        ("A",  8.7, -0.4, 0.9, 0.92),
        ("C",  6.9,  4.6, 2.1, 1.04),
        ("B", -4.8,  8.0, 0.3, 1.08),
        ("A",  4.9,  8.3, -0.7, 1.00),
        ("C", -7.5, 11.2, 1.4, 1.12),
        ("B",  7.8, 11.5, -1.5, 1.10),
    ]
    counts = {"A": 0, "B": 0, "C": 0}
    for v_key, cx, cy, rz, sc in placements:
        if is_in_exclusion_zone(cx, cy, layout, extra_radius=0.85):
            continue
        counts[v_key] += 1
        obj_name = f"Cactus_Columnar_Variant_{v_key}_{counts[v_key]:02d}"
        cz = terrain_height_at(cx, cy, layout)
        c_obj = bpy.data.objects.new(obj_name, meshes[v_key])
        c_obj.location = Vector((cx, cy, cz))
        c_obj.rotation_euler = Euler((0.0, 0.0, rz), 'XYZ')
        c_obj.scale = Vector((sc, sc, sc))
        link_to_collection(c_obj, sub_cols["05_CACTI"])


# ==============================================================================
# 12. VEGETAÇÃO BAIXA E DETALHES DE CHÃO (Manchas de Capim, Arbustos, Pedras e Galhos)
# ==============================================================================
def build_undergrowth(sub_cols, layout, mats):
    rng = random.Random(CONFIG["random_seed"] + 200)

    # Mesh 1: Tufo de capim seco / arbusto espinhoso baixo
    bm_tuft = bmesh.new()
    for i in range(9):
        ang = (i / 9.0) * math.pi * 2.0 + rng.uniform(-0.2, 0.2)
        tilt = rng.uniform(0.22, 0.48)
        h = rng.uniform(0.32, 0.55)
        v1 = bm_tuft.verts.new((math.cos(ang - 0.18) * 0.08, math.sin(ang - 0.18) * 0.08, -0.02))
        v2 = bm_tuft.verts.new((math.cos(ang + 0.18) * 0.08, math.sin(ang + 0.18) * 0.08, -0.02))
        vt = bm_tuft.verts.new((math.cos(ang) * tilt, math.sin(ang) * tilt, h))
        bm_tuft.faces.new((v1, v2, vt))
    mesh_tuft = bpy.data.meshes.new("Undergrowth_DryTuft_Mesh")
    bm_tuft.to_mesh(mesh_tuft)
    bm_tuft.free()
    mesh_tuft.materials.append(mats["straw"])

    # Mesh 2: Pedra irregular do sertão
    bm_rock = bmesh.new()
    bmesh.ops.create_icosphere(bm_rock, subdivisions=2, radius=0.28)
    for v in bm_rock.verts:
        v.co.x *= 1.35
        v.co.y *= 1.05
        v.co.z *= 0.58
    mesh_rock = bpy.data.meshes.new("Undergrowth_SmallRock_Mesh")
    bm_rock.to_mesh(mesh_rock)
    bm_rock.free()
    for p in mesh_rock.polygons:
        p.use_smooth = True
    mesh_rock.materials.append(mats["rock"])

    # Distribuição em manchas orgânicas nas margens externas
    patch_centers = [
        (-6.4, -4.6), (-7.2, -0.8), (-6.6, 3.2), (-5.2, 6.8),
        (6.4, -4.4), (7.1, -0.5), (6.7, 3.4), (5.4, 6.9),
        (-3.2, 8.2), (3.4, 8.5), (-8.4, 5.5), (8.6, 5.8),
    ]

    tuft_idx = 0
    rock_idx = 0
    for px, py in patch_centers:
        # 2 a 3 tufos e 1 a 2 pedras por mancha
        for _ in range(3):
            ox = px + rng.uniform(-0.85, 0.85)
            oy = py + rng.uniform(-0.85, 0.85)
            if is_in_exclusion_zone(ox, oy, layout, extra_radius=0.45):
                continue
            tuft_idx += 1
            oz = terrain_height_at(ox, oy, layout)
            t_obj = bpy.data.objects.new(f"Undergrowth_Tuft_{tuft_idx:02d}", mesh_tuft)
            t_obj.location = Vector((ox, oy, oz))
            t_obj.rotation_euler = Euler((0.0, 0.0, rng.uniform(0.0, math.pi * 2.0)), 'XYZ')
            sc = rng.uniform(0.85, 1.35)
            t_obj.scale = Vector((sc, sc, sc))
            link_to_collection(t_obj, sub_cols["06_UNDERGROWTH"])

        for _ in range(2):
            rx = px + rng.uniform(-0.95, 0.95)
            ry = py + rng.uniform(-0.95, 0.95)
            if is_in_exclusion_zone(rx, ry, layout, extra_radius=0.45):
                continue
            rock_idx += 1
            rz = terrain_height_at(rx, ry, layout) - 0.03
            r_obj = bpy.data.objects.new(f"Undergrowth_Rock_{rock_idx:02d}", mesh_rock)
            r_obj.location = Vector((rx, ry, rz))
            r_obj.rotation_euler = Euler((rng.uniform(-0.2, 0.2), rng.uniform(-0.2, 0.2), rng.uniform(0.0, math.pi * 2.0)), 'XYZ')
            sc = rng.uniform(0.75, 1.45)
            r_obj.scale = Vector((sc, sc, sc))
            link_to_collection(r_obj, sub_cols["06_UNDERGROWTH"])


# ==============================================================================
# 13. CAVEIRA DE BOI NO MOURÃO (Única Caveira Bovina Lateral + Mourão + Cerca)
# ==============================================================================
def build_fence_and_single_bovine_skull(sub_cols, layout, mats):
    """
    Constrói uma ÚNICA caveira bovina envelhecida presa ao mourão lateral no terço médio
    esquerdo da composição (-X), fora do campo, reconhecível e secundária ao tabuleiro.
    """
    # Posição no terço médio-frontal esquerdo, fora da máscara de exclusão
    skull_post_xy = (-5.85, -2.55)
    base_z = terrain_height_at(skull_post_xy[0], skull_post_xy[1], layout)

    # 1. Mourão principal da caveira (madeira rachada, topo irregular)
    bm_post = bmesh.new()
    bmesh.ops.create_cone(bm_post, cap_ends=True, cap_tris=False, segments=8, radius1=0.115, radius2=0.092, depth=1.65)
    for v in bm_post.verts:
        v.co.z += 0.72
        v.co.x += math.sin(v.co.z * 3.1) * 0.018
        if v.co.z > 1.4:
            # Topo irregular lascado
            v.co.z += 0.06 * math.cos(v.co.x * 18.0)
    mesh_post = bpy.data.meshes.new("Fence_Post_Skull_Mesh")
    bm_post.to_mesh(mesh_post)
    bm_post.free()
    mesh_post.materials.append(mats["fence_wood"])

    post_skull_obj = bpy.data.objects.new("Fence_Post_Skull", mesh_post)
    post_skull_obj.location = Vector((skull_post_xy[0], skull_post_xy[1], base_z))
    post_skull_obj.rotation_euler = Euler((0.04, 0.06, 0.28), 'XYZ')
    link_to_collection(post_skull_obj, sub_cols["07_FENCE_AND_SKULL"])

    # Continuação discreta da cerca com poucos postes inclinados na lateral esquerda
    other_posts = [
        ("Fence_Post_01", (-6.25, -0.35), (-0.06, 0.05, -0.15), 1.48),
        ("Fence_Post_02", (-6.55,  1.85), (0.05, -0.07, 0.22), 1.45),
        ("Fence_Post_03", (-6.80,  4.05), (-0.04, 0.06, -0.18), 1.42),
    ]
    all_post_tops = [Vector((skull_post_xy[0], skull_post_xy[1], base_z + 1.15))]
    for pname, (px, py), prot, ph in other_posts:
        pz = terrain_height_at(px, py, layout)
        bm_p = bmesh.new()
        bmesh.ops.create_cone(bm_p, cap_ends=True, cap_tris=False, segments=7, radius1=0.095, radius2=0.078, depth=ph)
        for v in bm_p.verts:
            v.co.z += ph * 0.45
        mp = bpy.data.meshes.new(f"{pname}_Mesh")
        bm_p.to_mesh(mp)
        bm_p.free()
        mp.materials.append(mats["fence_wood"])
        pobj = bpy.data.objects.new(pname, mp)
        pobj.location = Vector((px, py, pz))
        pobj.rotation_euler = Euler(prot, 'XYZ')
        link_to_collection(pobj, sub_cols["07_FENCE_AND_SKULL"])
        all_post_tops.append(Vector((px, py, pz + 1.05)))

    # Segmentos discretos de arame antigo entre os postes + amarração da caveira
    curve_wire = bpy.data.curves.new("Fence_Wire_Curve", type='CURVE')
    curve_wire.dimensions = '3D'
    curve_wire.bevel_depth = 0.012
    curve_wire.bevel_resolution = 2
    for z_offset in (0.0, -0.32):
        for i in range(len(all_post_tops) - 1):
            p0 = all_post_tops[i] + Vector((0.0, 0.0, z_offset))
            p1 = all_post_tops[i + 1] + Vector((0.0, 0.0, z_offset))
            pmid = 0.5 * (p0 + p1) + Vector((0.0, 0.0, -0.08))
            sp = curve_wire.splines.new('POLY')
            sp.points.add(2)
            sp.points[0].co = (p0.x, p0.y, p0.z, 1.0)
            sp.points[1].co = (pmid.x, pmid.y, pmid.z, 1.0)
            sp.points[2].co = (p1.x, p1.y, p1.z, 1.0)

    # Voltas de arame prendendo a caveira ao mourão
    for w_i in range(4):
        wz = base_z + 1.12 + w_i * 0.045
        sp_w = curve_wire.splines.new('POLY')
        pts_w = []
        for k in range(9):
            a = (k / 8.0) * math.pi * 2.0
            pts_w.append((skull_post_xy[0] + math.cos(a) * 0.115, skull_post_xy[1] + math.sin(a) * 0.115, wz))
        sp_w.points.add(len(pts_w) - 1)
        for k, (wx, wy, wz_c) in enumerate(pts_w):
            sp_w.points[k].co = (wx, wy, wz_c, 1.0)

    wire_obj = bpy.data.objects.new("Fence_Wire_Segments", curve_wire)
    wire_obj.data.materials.append(mats["wire"])
    link_to_collection(wire_obj, sub_cols["07_FENCE_AND_SKULL"])

    # 2. Modelagem Anatômica Estilizada da ÚNICA Caveira Bovina (`Skull_Bovine`)
    # Crânio alongado, fronte larga, cavidades orbitais laterais profundas, abertura nasal e chifres curvos
    bm_skull = bmesh.new()
    bmesh.ops.create_icosphere(bm_skull, subdivisions=3, radius=0.28)
    for v in bm_skull.verts:
        x, y, z = v.co.x, v.co.y, v.co.z
        if z < 0.04:
            # Afunilamento alongado do focinho/maxilar bovino para baixo/frente
            t_snout = min(1.0, abs(z - 0.04) / 0.28)
            v.co.x *= max(0.30, 0.94 - 0.58 * t_snout)
            v.co.y *= 0.72
            v.co.y -= 0.12 * t_snout
            v.co.z *= 1.68
            # Abertura nasal escavada por geometria (escura por sombra natural)
            if z < -0.18 and y < -0.03 and abs(x) < 0.075:
                v.co.y += 0.11
                v.co.z += 0.03
        else:
            # Região frontal larga entre as bases dos chifres
            v.co.x *= 1.26
            v.co.y *= 0.78
            v.co.z *= 0.88

        # Cavidades orbitais laterais profundas (escavadas na geometria para sombra própria)
        for side in (-1.0, 1.0):
            d_orb = math.sqrt((v.co.x - side * 0.185) ** 2 + (v.co.y + 0.11) ** 2 + (v.co.z - 0.02) ** 2)
            if d_orb < 0.105:
                depth_f = 1.0 - (d_orb / 0.105)
                v.co.x -= side * 0.075 * depth_f
                v.co.y += 0.085 * depth_f

    # Chifres bovinos curvos desgastados (material index 1)
    for side in (-1.0, 1.0):
        segs = 8
        prev_ring = None
        for s in range(segs + 1):
            t = s / float(segs)
            hx = side * (0.21 + t * 0.44)
            hy = -0.02 - math.sin(t * math.pi) * 0.15
            hz = 0.14 + (t ** 1.35) * 0.30
            hr = 0.068 * (1.0 - t * 0.85)
            ring = []
            for k in range(7):
                a = (k / 7.0) * math.pi * 2.0
                v_h = bm_skull.verts.new((hx + math.cos(a) * hr * 0.45, hy + math.cos(a) * hr, hz + math.sin(a) * hr))
                ring.append(v_h)
            if prev_ring:
                for k in range(7):
                    k2 = (k + 1) % 7
                    f_h = bm_skull.faces.new((prev_ring[k], prev_ring[k2], ring[k2], ring[k]))
                    f_h.material_index = 1
            prev_ring = ring

    mesh_skull = bpy.data.meshes.new("Skull_Bovine_Mesh")
    bm_skull.to_mesh(mesh_skull)
    bm_skull.free()
    for p in mesh_skull.polygons:
        p.use_smooth = True
    mesh_skull.materials.append(mats["skull_bone"])
    mesh_skull.materials.append(mats["skull_horn"])

    skull_obj = bpy.data.objects.new("Skull_Bovine", mesh_skull)
    # Fixada na face frontal/interna do mourão, orientada sutilmente entre a câmera e o campo
    skull_obj.location = Vector((skull_post_xy[0] + 0.14, skull_post_xy[1] - 0.10, base_z + 1.24))
    skull_obj.rotation_euler = Euler((0.18, -0.06, 0.52), 'XYZ')
    link_to_collection(skull_obj, sub_cols["07_FENCE_AND_SKULL"])


# ==============================================================================
# 14. HORROR AMBIENTAL SUTIL (As 3 Anomalias Discretas, Sem Criaturas/Olhos/Símbolos)
# ==============================================================================
def build_horror_anomalies(sub_cols, layout, mats):
    """
    Implementa as três anomalias discretas da Seção 14:
    A. Caminho que parece retornar (repetição parcial de dois troncos + pedra em camada mais distante na trilha).
    B. Galhos presos em nós improváveis em uma região lateral (sem formar símbolos ou letras).
    C. Marcas rasas de passagem na poeira próximas ao mourão da caveira que cessam abruptamente.
    """
    # --- ANOMALIA A: Caminho que parece retornar ---
    # Leito de trilha erodida atrás do campo + repetição parcial de dois troncos e uma pedra em camada mais distante
    bm_path = bmesh.new()
    segs_p = 18
    for s in range(segs_p):
        t0 = s / float(segs_p)
        t1 = (s + 1) / float(segs_p)
        y0 = 4.3 + t0 * 8.5
        y1 = 4.3 + t1 * 8.5
        x0 = 0.65 * math.sin((y0 - 4.3) * 0.52) - 0.15
        x1 = 0.65 * math.sin((y1 - 4.3) * 0.52) - 0.15
        w0 = 0.58 * (1.0 - 0.35 * t0)
        w1 = 0.58 * (1.0 - 0.35 * t1)
        z0 = terrain_height_at(x0, y0, layout) + 0.004
        z1 = terrain_height_at(x1, y1, layout) + 0.004
        v00 = bm_path.verts.new((x0 - w0, y0, z0))
        v01 = bm_path.verts.new((x0 + w0, y0, z0))
        v11 = bm_path.verts.new((x1 + w1, y1, z1))
        v10 = bm_path.verts.new((x1 - w1, y1, z1))
        bm_path.faces.new((v00, v01, v11, v10))
    m_path = bpy.data.meshes.new("Horror_ReturningTrail_Mesh")
    bm_path.to_mesh(m_path)
    bm_path.free()
    m_path.materials.append(mats["dust_tracks"])
    path_obj = bpy.data.objects.new("Horror_ReturningTrail", m_path)
    link_to_collection(path_obj, sub_cols["08_HORROR_DETAILS"])

    loop_pairs = [
        ("Horror_LoopPath_Near", (-0.85, 5.4, 0.0), 0.95, 0.18),
        ("Horror_LoopPath_Far",  (-0.52, 8.6, 0.0), 0.90, 0.22),
    ]
    for prefix, (bx, by, _), sc, yaw_off in loop_pairs:
        bz = terrain_height_at(bx, by, layout)
        # Dois troncos inclinados gêmeos e uma pedra angular ao pé
        curve_tr = bpy.data.curves.new(f"{prefix}_Trunks_Curve", type='CURVE')
        curve_tr.dimensions = '3D'
        curve_tr.bevel_depth = 1.0
        curve_tr.bevel_resolution = 3
        for idx_t, (ox, oy, lean_x, h_t, r_t) in enumerate([
            (0.0, 0.0, 0.65, 3.4 * sc, 0.15 * sc),
            (0.48 * sc, 0.22 * sc, 0.82, 2.8 * sc, 0.12 * sc),
        ]):
            sp = curve_tr.splines.new('POLY')
            pts = [
                (ox, oy, -0.1, r_t),
                (ox + lean_x * 0.35, oy + 0.1, h_t * 0.45, r_t * 0.68),
                (ox + lean_x * 0.85, oy + 0.2, h_t * 0.92, r_t * 0.22),
            ]
            sp.points.add(len(pts) - 1)
            for i, (px, py, pz, pr) in enumerate(pts):
                sp.points[i].co = (px, py, pz, 1.0)
                sp.points[i].radius = pr

        tr_obj = bpy.data.objects.new(f"{prefix}_TwinTrunks", curve_tr)
        tr_obj.location = Vector((bx, by, bz))
        tr_obj.rotation_euler = Euler((0.0, 0.0, yaw_off), 'XYZ')
        tr_obj.data.materials.append(mats["white_forest"])
        link_to_collection(tr_obj, sub_cols["08_HORROR_DETAILS"])

        bm_st = bmesh.new()
        bmesh.ops.create_icosphere(bm_st, subdivisions=2, radius=0.34 * sc)
        for v in bm_st.verts:
            v.co.x *= 1.3
            v.co.z *= 0.65
        m_st = bpy.data.meshes.new(f"{prefix}_MarkerStone_Mesh")
        bm_st.to_mesh(m_st)
        bm_st.free()
        m_st.materials.append(mats["rock"])
        st_obj = bpy.data.objects.new(f"{prefix}_MarkerStone", m_st)
        st_obj.location = Vector((bx + 0.55 * sc, by - 0.18 * sc, bz))
        st_obj.rotation_euler = Euler((0.0, 0.0, yaw_off + 0.4), 'XYZ')
        link_to_collection(st_obj, sub_cols["08_HORROR_DETAILS"])

    # --- ANOMALIA B: Galhos presos em nós improváveis (Lateral direita, orgânico, sem símbolos) ---
    knot_loc = (6.25, 0.65)
    knot_z = terrain_height_at(knot_loc[0], knot_loc[1], layout)
    curve_knot = bpy.data.curves.new("Horror_ImpossibleKnot_Curve", type='CURVE')
    curve_knot.dimensions = '3D'
    curve_knot.bevel_depth = 1.0
    curve_knot.bevel_resolution = 3

    # Três hastes secas que brotam do solo, entrelaçam-se num nó apertado a ~1.1m de altura e separam-se nas pontas
    for b_idx in range(3):
        sp_k = curve_knot.splines.new('POLY')
        phase = (b_idx / 3.0) * math.pi * 2.0
        n_pts = 12
        sp_k.points.add(n_pts - 1)
        for i in range(n_pts):
            t = i / float(n_pts - 1)
            # Base no chão (t=0), nó apertado no meio (t=0.45..0.75), pontas secas (t=1.0)
            pinch = 1.0 - 0.68 * math.exp(-((t - 0.60) / 0.18) ** 2)
            ang = phase + t * math.pi * 2.4
            rad = 0.34 * pinch
            kx = math.cos(ang) * rad + (t ** 1.4) * 0.25
            ky = math.sin(ang) * rad
            kz = -0.08 + t * 1.75
            sp_k.points[i].co = (kx, ky, kz, 1.0)
            sp_k.points[i].radius = 0.048 * (1.0 - 0.78 * t)

    knot_obj = bpy.data.objects.new("Horror_KnottedBranches", curve_knot)
    knot_obj.location = Vector((knot_loc[0], knot_loc[1], knot_z))
    knot_obj.data.materials.append(mats["white_forest"])
    link_to_collection(knot_obj, sub_cols["08_HORROR_DETAILS"])

    # --- ANOMALIA C: Marcas que cessam na poeira próximo ao mourão da caveira ---
    # 5 marcas rasas de passos/arrasto vindo da borda externa em direção ao mourão e parando no vazio
    track_steps = [
        (-7.45, -4.15, 0.42),
        (-7.05, -3.78, 0.38),
        (-6.68, -3.45, 0.44),
        (-6.32, -3.12, 0.36),
        (-5.98, -2.85, 0.40),  # Última marca cessa abruptamente na poeira antes do campo
    ]
    for idx_s, (sx, sy, s_rot) in enumerate(track_steps):
        sz = terrain_height_at(sx, sy, layout) + 0.003
        bm_tr = bmesh.new()
        bmesh.ops.create_cone(bm_tr, cap_ends=True, cap_tris=False, segments=10, radius1=0.14, radius2=0.11, depth=0.012)
        for v in bm_tr.verts:
            v.co.y *= 1.65  # Formato alongado de rastro na poeira
        m_tr = bpy.data.meshes.new(f"Horror_DustTrack_{idx_s:02d}_Mesh")
        bm_tr.to_mesh(m_tr)
        bm_tr.free()
        m_tr.materials.append(mats["dust_tracks"])
        tr_step = bpy.data.objects.new(f"Horror_DustTrack_{idx_s:02d}", m_tr)
        tr_step.location = Vector((sx, sy, sz))
        tr_step.rotation_euler = Euler((0.0, 0.0, s_rot), 'XYZ')
        link_to_collection(tr_step, sub_cols["08_HORROR_DETAILS"])


# ==============================================================================
# 16. ILUMINAÇÃO (Fim de Tarde Rasante da Esquerda/Trás + Preenchimento Frio Suave)
# ==============================================================================
def setup_lighting_and_world(scene, sub_cols):
    # 1. Luz Principal (`Light_Sunset_Key`): direcional baixa vinda da esquerda (-X) e de trás (+Y)
    sun_data = bpy.data.lights.new(name="Light_Sunset_Key_Data", type='SUN')
    sun_data.color = (1.0, 0.68, 0.44)  # Âmbar apagado / cobre pouco saturado
    sun_data.energy = 2.65
    sun_data.angle = math.radians(6.5)  # Sombras alongadas porém com bordas suaves

    sun_obj = bpy.data.objects.new("Light_Sunset_Key", sun_data)
    sun_obj.location = Vector((-10.0, 12.0, 6.5))
    # Aponta da esquerda-trás (-X, +Y, +Z) para a direita-frente (+X, -Y, -Z) com inclinação rasante (~24°)
    direction = Vector((1.0, -0.85, -0.46)).normalized()
    sun_obj.rotation_euler = direction.to_track_quat('-Z', 'Y').to_euler()
    link_to_collection(sun_obj, sub_cols["09_LIGHTS"])

    # 2. Luz Auxiliar de Leitura Fria e Ampla (`Light_Sky_Fill`)
    fill_data = bpy.data.lights.new(name="Light_Sky_Fill_Data", type='AREA')
    fill_data.shape = 'RECTANGLE'
    fill_data.size = 18.0
    fill_data.size_y = 16.0
    fill_data.color = (0.68, 0.78, 0.92)  # Fria e suave para manter casas, sulcos e caveira legíveis
    fill_data.energy = 185.0

    fill_obj = bpy.data.objects.new("Light_Sky_Fill", fill_data)
    fill_obj.location = Vector((2.5, -4.0, 12.5))
    fill_dir = (Vector((0.0, 0.0, 0.0)) - fill_obj.location).normalized()
    fill_obj.rotation_euler = fill_dir.to_track_quat('-Z', 'Y').to_euler()
    link_to_collection(fill_obj, sub_cols["09_LIGHTS"])

    # 3. Ambiente Mundial (Céu crepuscular seco da Caatinga)
    world = bpy.data.worlds.get("World_Caatinga")
    if not world:
        world = bpy.data.worlds.new("World_Caatinga")
    scene.world = world
    if hasattr(world, "use_nodes") and not world.use_nodes:
        world.use_nodes = True
    w_nodes = world.node_tree.nodes
    w_links = world.node_tree.links
    w_nodes.clear()

    bg = w_nodes.new("ShaderNodeBackground")
    bg.inputs["Color"].default_value = (0.16, 0.19, 0.25, 1.0)  # Ambiente frio crepuscular suave
    bg.inputs["Strength"].default_value = 0.55
    out_w = w_nodes.new("ShaderNodeOutputWorld")
    w_links.new(bg.outputs["Background"], out_w.inputs["Surface"])


# ==============================================================================
# 17. CÂMERA (`Camera_Game` — Três Quartos Elevada, 55% a 65% de Ocupação Horizontal)
# ==============================================================================
def setup_camera_and_controls(scene, sub_cols, layout):
    # Alvo central do conjunto jogável em 00_CONTROLS
    ctrl_target = bpy.data.objects.new("Control_Board_Center", None)
    ctrl_target.empty_display_type = 'PLAIN_AXES'
    ctrl_target.location = Vector((0.0, -0.35, 0.0))
    link_to_collection(ctrl_target, sub_cols["00_CONTROLS"])

    cam_data = bpy.data.cameras.new("Camera_Game_Data")
    cam_data.lens = 48.0  # Entre 45 e 60 mm
    cam_data.sensor_width = 36.0
    cam_data.clip_start = 0.1
    cam_data.clip_end = 200.0
    cam_data.dof.use_dof = False  # Todas as casas nítidas

    cam_obj = bpy.data.objects.new("Camera_Game", cam_data)
    # Posicionada no lado Y negativo olhando para o conjunto jogável com inclinação ~44° abaixo da horizontal
    # Tabuleiro inteiro + Reserva frontal inteira visíveis com folga na margem inferior,
    # ocupação horizontal de ~56% (dentro da meta de 55% a 65%) e Floresta Branca visível atrás e nas laterais.
    cam_obj.location = Vector((0.0, -16.8, 14.2))
    look_target = Vector((0.0, -0.35, 0.55))
    look_vec = (look_target - cam_obj.location).normalized()
    cam_obj.rotation_euler = look_vec.to_track_quat('-Z', 'Y').to_euler()

    link_to_collection(cam_obj, sub_cols["10_CAMERAS"])
    scene.camera = cam_obj
    return cam_obj


# ==============================================================================
# 18. RENDERIZAÇÃO (Prévia e Final 1920x1080 em PNG via Cycles)
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

    # Gerenciamento de cor seguro para a versão instalada
    try:
        enum_items = [it.identifier for it in scene.view_settings.bl_rna.properties['view_transform'].enum_items]
        for candidate in ('AgX', 'Filmic', 'Standard'):
            if candidate in enum_items:
                scene.view_settings.view_transform = candidate
                break
    except Exception:
        pass
    scene.view_settings.exposure = 0.15


def render_image(scene, filepath, resolution, samples):
    scene.render.resolution_x = resolution[0]
    scene.render.resolution_y = resolution[1]
    scene.render.resolution_percentage = 100
    scene.cycles.samples = samples
    scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    print(f"[RENDER OK] {filepath} ({resolution[0]}x{resolution[1]}, {samples} samples)")


# ==============================================================================
# EXECUÇÃO PRINCIPAL DAS 7 ETAPAS (Seção 19)
# ==============================================================================
def build_caatinga_autochess():
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
    setup_camera_and_controls(scene, sub_cols, layout)
    setup_lighting_and_world(scene, sub_cols)

    print("=== ETAPAS 4, 5 & 6: Floresta Branca (5 Variantes), Cactos (3 Variantes), Caveira no Mourão e 3 Anomalias ===")
    build_white_forest(sub_cols, layout, mats)
    build_cacti(sub_cols, layout, mats)
    build_undergrowth(sub_cols, layout, mats)
    build_fence_and_single_bovine_skull(sub_cols, layout, mats)
    build_horror_anomalies(sub_cols, layout, mats)

    # Render de Prévia (Etapa 2/18)
    preview_path = os.path.join(out_dir, "caatinga_autochess_preview.png")
    print("=== Gerando Render de Prévia ===")
    render_image(scene, preview_path, CONFIG["preview_resolution"], CONFIG["preview_samples"])

    # Render Final 1920x1080 (Etapa 7/18)
    final_path = os.path.join(out_dir, "caatinga_autochess_final.png")
    print("=== Gerando Render Final 1920x1080 ===")
    render_image(scene, final_path, CONFIG["final_resolution"], CONFIG["final_samples"])

    # Salvar arquivo .blend (Etapa 7/21)
    blend_path = os.path.join(out_dir, "caatinga_autochess.blend")
    bpy.ops.wm.save_as_mainfile(filepath=blend_path)
    print(f"[BLEND OK] Salvo em: {blend_path}")


if __name__ == "__main__":
    build_caatinga_autochess()
