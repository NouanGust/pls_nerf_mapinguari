"""
Script de geração procedural do Blockout da Alamoa para Blender 5.2+.
Autochess de Horror Folclórico Brasileiro.

Checkpoint A:
- Proporções esguias e alongadas (~2.0m de altura até o topo do cabelo).
- Rosto cadavérico/craniano com cavidades orbitais profundas, maçãs do rosto e maxilar afilado.
- Cabelo em 7 massas angulares distintas (coroa, mechas laterais, volume posterior longo).
- Manto opaco drapeado com dobras ricas e geométricas.
- Braços esguios e mãos estilizadas com garras predadoras e dedos alongados agrupados.
- Pernas e pés assentados no plano Z=0.
- Origem no chão (0,0,0), Z para cima, frente voltada para -Y.
- Orçamento poligonal estritamente entre 2.000 e 4.000 triângulos.
"""

import bpy
import bmesh
from mathutils import Vector, Matrix, Euler
import math
import os
import sys

def limpar_cena():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    for c in list(bpy.data.collections):
        bpy.data.collections.remove(c)
    col = bpy.data.collections.new("Alamoa_Collection")
    bpy.context.scene.collection.children.link(col)
    bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection.children[col.name]
    return col

def criar_malha_objeto(nome, vertices, faces, colecao=None):
    me = bpy.data.meshes.new(nome + "_Mesh")
    me.from_pydata(vertices, [], faces)
    me.update(calc_edges=True)
    obj = bpy.data.objects.new(nome, me)
    if colecao:
        colecao.objects.link(obj)
    return obj

def gerar_geometria_cilindro_perfil(perfis, segmentos=10, fechar_topo=False, fechar_base=False):
    """
    perfis: lista de tuplas (z, raio_x, raio_y, centro_x, centro_y)
    Gera vértices e faces conectando anéis de elipses com topologia limpa.
    """
    verts = []
    faces = []
    num_perfis = len(perfis)
    
    for z, rx, ry, cx, cy in perfis:
        for i in range(segmentos):
            ang = 2.0 * math.pi * i / segmentos
            vx = cx + rx * math.cos(ang)
            vy = cy + ry * math.sin(ang)
            vz = z
            verts.append((vx, vy, vz))
            
    for p in range(num_perfis - 1):
        offset1 = p * segmentos
        offset2 = (p + 1) * segmentos
        for i in range(segmentos):
            i_next = (i + 1) % segmentos
            v1 = offset1 + i
            v2 = offset1 + i_next
            v3 = offset2 + i_next
            v4 = offset2 + i
            faces.append((v1, v2, v3, v4))
            
    if fechar_base:
        base_face = [i for i in range(segmentos)]
        base_face.reverse()
        faces.append(base_face)
        
    if fechar_topo:
        top_offset = (num_perfis - 1) * segmentos
        top_face = [top_offset + i for i in range(segmentos)]
        faces.append(top_face)
        
    return verts, faces

def construir_cranio_rosto():
    """
    Gera o crânio estilizado da Alamoa:
    Cavidades orbitais escuras, mandíbula afilada, maçãs do rosto proeminentes.
    Frente voltada para -Y.
    """
    bm = bmesh.new()
    
    # Base do crânio usando elipsoide com resolução suficiente
    bmesh.ops.create_uvsphere(
        bm,
        u_segments=20,
        v_segments=16,
        radius=0.115
    )
    
    # Deformar para crânio alongado e afilado
    for v in bm.verts:
        co = v.co
        x, y, z = co.x, co.y, co.z
        
        # Alongar verticalmente o topo
        if z > 0:
            z *= 1.12
        else:
            # Afunilar mandíbula cadavérica
            z *= 1.28
            factor = (z + 0.14) / 0.14
            factor = max(0.35, min(1.0, factor))
            x *= (0.55 + 0.45 * factor)
            if y < 0:
                y = y * 0.88 - 0.02 * (1.0 - factor)
                
        # Estreitar largura lateral da têmpora
        x *= 0.88
        
        # Recuo frontal profundo na região dos olhos (cavidades orbitais)
        if -0.05 < co.z < 0.045 and co.y < 0:
            dist_olho_l = math.sqrt((x - 0.042)**2 + (z - 0.005)**2)
            dist_olho_r = math.sqrt((x + 0.042)**2 + (z - 0.005)**2)
            
            if dist_olho_l < 0.046:
                depth = (0.046 - dist_olho_l) / 0.046
                y += depth * 0.045
            elif dist_olho_r < 0.046:
                depth = (0.046 - dist_olho_r) / 0.046
                y += depth * 0.045
                
            # Maçãs do rosto proeminentes
            if co.z < 0 and abs(x) > 0.04:
                y -= 0.018 * (abs(x) / 0.075)
                
        # Cavidade nasal estilizada (abertura piriforme)
        if -0.045 < co.z < -0.015 and abs(x) < 0.022 and co.y < 0:
            y += 0.022
            
        v.co = Vector((x, y, z + 1.80))
        
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    
    me = bpy.data.meshes.new("Alamoa_Head_Mesh")
    bm.to_mesh(me)
    bm.free()
    
    obj = bpy.data.objects.new("Head_Cranium", me)
    return obj

def construir_cabelo():
    """
    Gera 7 massas angulares de cabelo estilizado:
    1. hair_crown (topo e crista angular)
    2. hair_back_upper (volume occipital)
    3. hair_back_lower (drapeamento longo posterior até meio das costas)
    4. hair_front_l (mecha frontal esquerda)
    5. hair_front_r (mecha frontal direita)
    6. hair_side_l (volume parietal esquerdo)
    7. hair_side_r (volume parietal direito)
    """
    hair_objs = []
    
    # 1. Coroa (Crown)
    bm_crown = bmesh.new()
    bmesh.ops.create_cone(
        bm_crown,
        cap_ends=True,
        cap_tris=False,
        segments=10,
        radius1=0.135,
        radius2=0.035,
        depth=0.24,
        matrix=Matrix.Translation(Vector((0, 0.02, 1.90))) @ Matrix.Rotation(math.radians(-14), 4, 'X')
    )
    for v in bm_crown.verts:
        v.co.x *= 0.94
    me_crown = bpy.data.meshes.new("Hair_Crown_Mesh")
    bm_crown.to_mesh(me_crown)
    bm_crown.free()
    hair_objs.append(bpy.data.objects.new("Hair_Crown", me_crown))
    
    # 2. Back Upper
    perfis_back_upper = [
        (1.89, 0.125, 0.085, 0.0, 0.065),
        (1.78, 0.145, 0.095, 0.0, 0.09),
        (1.64, 0.165, 0.090, 0.0, 0.11),
    ]
    v_bu, f_bu = gerar_geometria_cilindro_perfil(perfis_back_upper, segmentos=10, fechar_topo=True, fechar_base=False)
    hair_objs.append(criar_malha_objeto("Hair_Back_Upper", v_bu, f_bu))
    
    # 3. Back Lower (vai até a cintura Z ~ 1.18)
    perfis_back_lower = [
        (1.64, 0.165, 0.090, 0.0, 0.11),
        (1.50, 0.185, 0.080, 0.0, 0.12),
        (1.34, 0.195, 0.070, 0.0, 0.11),
        (1.18, 0.130, 0.035, 0.0, 0.09),
    ]
    v_bl, f_bl = gerar_geometria_cilindro_perfil(perfis_back_lower, segmentos=10, fechar_topo=False, fechar_base=True)
    hair_objs.append(criar_malha_objeto("Hair_Back_Lower", v_bl, f_bl))
    
    # 4 & 5. Front Locks (L & R) - Mechas pontiagudas que caem sobre a frente dos ombros
    for side, sign in [("L", 1.0), ("R", -1.0)]:
        perfis_front = [
            (1.83, 0.055, 0.055, sign * 0.095, -0.04),
            (1.72, 0.050, 0.045, sign * 0.105, -0.06),
            (1.57, 0.042, 0.038, sign * 0.115, -0.08),
            (1.42, 0.028, 0.025, sign * 0.095, -0.07),
            (1.27, 0.010, 0.010, sign * 0.085, -0.05),
        ]
        v_f, f_f = gerar_geometria_cilindro_perfil(perfis_front, segmentos=8, fechar_topo=True, fechar_base=True)
        hair_objs.append(criar_malha_objeto(f"Hair_Front_{side}", v_f, f_f))
        
    # 6 & 7. Side Masses (L & R) - Laterais que contornam a mandíbula
    for side, sign in [("L", 1.0), ("R", -1.0)]:
        perfis_side = [
            (1.86, 0.065, 0.075, sign * 0.105, 0.01),
            (1.73, 0.075, 0.085, sign * 0.125, 0.03),
            (1.59, 0.070, 0.075, sign * 0.135, 0.04),
            (1.43, 0.045, 0.045, sign * 0.115, 0.05),
            (1.29, 0.015, 0.015, sign * 0.105, 0.05),
        ]
        v_s, f_s = gerar_geometria_cilindro_perfil(perfis_side, segmentos=8, fechar_topo=True, fechar_base=True)
        hair_objs.append(criar_malha_objeto(f"Hair_Side_{side}", v_s, f_s))
        
    return hair_objs

def construir_pescoco_tronco():
    """
    Pescoço esguio e tronco estilizado (clavícula, costelas afiladas, cintura).
    """
    # Pescoço
    perfis_pescoco = [
        (1.74, 0.046, 0.050, 0.0, -0.01),
        (1.67, 0.044, 0.048, 0.0, -0.005),
        (1.58, 0.054, 0.058, 0.0, 0.0),
    ]
    v_p, f_p = gerar_geometria_cilindro_perfil(perfis_pescoco, segmentos=10, fechar_topo=True, fechar_base=True)
    obj_pescoco = criar_malha_objeto("Body_Neck", v_p, f_p)
    
    # Tronco (Tórax e Cintura)
    perfis_tronco = [
        (1.58, 0.145, 0.090, 0.0, 0.0),      # Clavícula e ombros estreitos
        (1.47, 0.140, 0.095, 0.0, -0.01),    # Tórax alto
        (1.36, 0.125, 0.085, 0.0, -0.005),   # Caixa torácica inferior
        (1.24, 0.105, 0.078, 0.0, 0.0),      # Cintura fina
        (1.12, 0.135, 0.098, 0.0, 0.01),     # Quadril
        (0.98, 0.145, 0.110, 0.0, 0.01),     # Pelve base
    ]
    v_t, f_t = gerar_geometria_cilindro_perfil(perfis_tronco, segmentos=12, fechar_topo=True, fechar_base=True)
    obj_tronco = criar_malha_objeto("Body_Torso", v_t, f_t)
    
    return [obj_pescoco, obj_tronco]

def construir_manto():
    """
    Manto opaco que drapeia sobre os ombros, envolve tronco e quadris,
    descendo em dobras geométricas largas até ~Z=0.22 (altura da canela).
    """
    perfis_manto = [
        (1.60, 0.165, 0.115, 0.0, 0.0),       # Gola assentada nos ombros
        (1.48, 0.180, 0.130, 0.0, -0.01),     # Peitoral
        (1.33, 0.168, 0.125, 0.0, 0.0),       # Cintura
        (1.15, 0.188, 0.145, 0.0, 0.01),      # Quadril
        (0.95, 0.228, 0.175, 0.0, 0.02),      # Coxas altas
        (0.74, 0.265, 0.205, 0.0, 0.02),      # Joelhos
        (0.50, 0.295, 0.235, 0.0, 0.03),      # Canela alta
        (0.24, 0.325, 0.260, 0.0, 0.03),      # Bainha inferior
    ]
    
    v_m, f_m = gerar_geometria_cilindro_perfil(perfis_manto, segmentos=16, fechar_topo=True, fechar_base=True)
    
    # Aplicar ondulações nas dobras para efeito de tecido pesado e espectral
    v_m_mod = []
    for x, y, z in v_m:
        ang = math.atan2(y, x)
        dobra = 0.025 * math.cos(5 * ang) * ((1.60 - z) / 1.60)
        raio_extra = 1.0 + dobra
        if y < 0 and abs(x) < 0.06 and z < 0.8:
            y += 0.035 * (0.8 - z) / 0.8
        v_m_mod.append((x * raio_extra, y * raio_extra, z))
        
    obj_manto = criar_malha_objeto("Cloak_Mantle", v_m_mod, f_m)
    return obj_manto

def construir_bracos_e_maos():
    """
    Braços esguios e mãos detalhadas com dedos alongados e pose convidativa/predatória.
    """
    objs = []
    
    for side, sign in [("L", 1.0), ("R", -1.0)]:
        # Braço Superior (Ombro Z=1.54 até Cotovelo Z=1.24)
        perfis_upper_arm = [
            (1.54, 0.040, 0.040, sign * 0.17, 0.0),
            (1.42, 0.034, 0.034, sign * 0.22, -0.02),
            (1.32, 0.031, 0.031, sign * 0.24, -0.03),
            (1.24, 0.029, 0.029, sign * 0.25, -0.04),
        ]
        v_ua, f_ua = gerar_geometria_cilindro_perfil(perfis_upper_arm, segmentos=10, fechar_topo=True, fechar_base=True)
        objs.append(criar_malha_objeto(f"Arm_Upper_{side}", v_ua, f_ua))
        
        # Antebraço (Cotovelo Z=1.24 até Pulso Z=0.96)
        perfis_forearm = [
            (1.24, 0.029, 0.029, sign * 0.25, -0.04),
            (1.14, 0.027, 0.026, sign * 0.27, -0.07),
            (1.04, 0.025, 0.024, sign * 0.28, -0.10),
            (0.96, 0.023, 0.021, sign * 0.29, -0.14),
        ]
        v_fa, f_fa = gerar_geometria_cilindro_perfil(perfis_forearm, segmentos=10, fechar_topo=True, fechar_base=True)
        objs.append(criar_malha_objeto(f"Arm_Forearm_{side}", v_fa, f_fa))
        
        # Mão estilizada: Palma + 4 dedos distintos + polegar
        bm_hand = bmesh.new()
        
        # Palma fina e alongada
        bmesh.ops.create_cube(
            bm_hand,
            size=0.036,
            matrix=Matrix.Translation(Vector((sign * 0.295, -0.165, 0.92))) @ Matrix.Scale(0.65, 4, Vector((0, 0, 1)))
        )
        
        # 4 Dedos agrupados longos com articulações e garras afiladas
        finger_offsets = [-0.014, -0.005, 0.005, 0.014]
        for f_idx, off_x in enumerate(finger_offsets):
            f_len = 0.085 - abs(off_x) * 0.5
            pos = Vector((sign * (0.295 + off_x), -0.19, 0.915))
            bmesh.ops.create_cone(
                bm_hand,
                cap_ends=True,
                segments=6,
                radius1=0.0065,
                radius2=0.0015,
                depth=f_len,
                matrix=Matrix.Translation(pos) @ Matrix.Rotation(math.radians(40 + f_idx * 2), 4, 'X')
            )
            
        # Polegar opositor ligeiramente curvado
        pos_thumb = Vector((sign * (0.295 - sign * 0.022), -0.165, 0.925))
        bmesh.ops.create_cone(
            bm_hand,
            cap_ends=True,
            segments=6,
            radius1=0.007,
            radius2=0.002,
            depth=0.055,
            matrix=Matrix.Translation(pos_thumb) @ Matrix.Rotation(math.radians(-sign * 35), 4, 'Z') @ Matrix.Rotation(math.radians(25), 4, 'X')
        )
        
        me_hand = bpy.data.meshes.new(f"Hand_{side}_Mesh")
        bm_hand.to_mesh(me_hand)
        bm_hand.free()
        objs.append(bpy.data.objects.new(f"Hand_{side}", me_hand))
        
    return objs

def construir_pernas_e_pes():
    """
    Pernas longas e delgadas, joelhos marcados, pés pousados no chão Z=0.
    """
    objs = []
    
    for side, sign in [("L", 1.0), ("R", -1.0)]:
        # Coxa (Z=1.00 a Z=0.56)
        perfis_coxa = [
            (1.00, 0.062, 0.068, sign * 0.08, 0.01),
            (0.85, 0.056, 0.060, sign * 0.08, 0.008),
            (0.70, 0.048, 0.050, sign * 0.08, 0.004),
            (0.56, 0.042, 0.044, sign * 0.08, 0.0),
        ]
        v_c, f_c = gerar_geometria_cilindro_perfil(perfis_coxa, segmentos=10, fechar_topo=True, fechar_base=True)
        objs.append(criar_malha_objeto(f"Leg_Thigh_{side}", v_c, f_c))
        
        # Canela / Panturrilha (Z=0.56 a Z=0.08)
        perfis_canela = [
            (0.56, 0.040, 0.042, sign * 0.08, 0.0),
            (0.42, 0.038, 0.044, sign * 0.08, 0.01),
            (0.26, 0.030, 0.032, sign * 0.08, 0.0),
            (0.08, 0.026, 0.028, sign * 0.08, -0.01),
        ]
        v_cn, f_cn = gerar_geometria_cilindro_perfil(perfis_canela, segmentos=10, fechar_topo=True, fechar_base=True)
        objs.append(criar_malha_objeto(f"Leg_Shin_{side}", v_cn, f_cn))
        
        # Pé (Z=0.08 até Z=0.0 no chão, Y de +0.03 a -0.15)
        bm_foot = bmesh.new()
        bmesh.ops.create_cube(
            bm_foot,
            size=0.055,
            matrix=Matrix.Translation(Vector((sign * 0.08, -0.05, 0.04)))
        )
        for v in bm_foot.verts:
            if v.co.y < -0.05:
                v.co.y *= 1.75
                v.co.z = max(0.0, v.co.z * 0.5)
                v.co.x = sign * 0.08 + (v.co.x - sign * 0.08) * 0.72
            if v.co.z < 0.04:
                v.co.z = 0.0
                
        me_foot = bpy.data.meshes.new(f"Foot_{side}_Mesh")
        bm_foot.to_mesh(me_foot)
        bm_foot.free()
        objs.append(bpy.data.objects.new(f"Foot_{side}", me_foot))
        
    return objs

def unificar_e_finalizar_blockout(colecao, caminho_blend):
    """
    Unifica ou organiza as peças do modelo para o Blockout,
    garante que a origem está em (0, 0, 0), escala 1.0, e calcula as métricas.
    """
    bpy.ops.object.select_all(action='DESELECT')
    for obj in colecao.objects:
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    
    # Criar objeto unificado mestre
    bpy.ops.object.select_all(action='DESELECT')
    for obj in colecao.objects:
        obj.select_set(True)
    
    bpy.context.view_layer.objects.active = colecao.objects[0]
    bpy.ops.object.duplicate()
    duplicados = bpy.context.selected_objects
    
    bpy.context.view_layer.objects.active = duplicados[0]
    bpy.ops.object.join()
    obj_unificado = bpy.context.active_object
    obj_unificado.name = "Alamoa_Blockout"
    
    # Limpeza de faces degeneradas (zero-area)
    bm = bmesh.new()
    bm.from_mesh(obj_unificado.data)
    zero_faces = [f for f in bm.faces if f.calc_area() < 1e-6]
    if zero_faces:
        bmesh.ops.delete(bm, geom=zero_faces, context='FACES')
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    bm.to_mesh(obj_unificado.data)
    bm.free()
    
    # Mover objetos componentes originais para coleção secundária de apoio
    col_partes = bpy.data.collections.new("Alamoa_Partes_Base")
    bpy.context.scene.collection.children.link(col_partes)
    
    for obj in list(colecao.objects):
        if obj != obj_unificado:
            colecao.objects.unlink(obj)
            col_partes.objects.link(obj)
            
    # Suavização uniforme
    for poly in obj_unificado.data.polygons:
        poly.use_smooth = True
        
    # Salvar blend
    bpy.ops.wm.save_as_mainfile(filepath=caminho_blend)
    print(f"Arquivo de Blockout salvo com sucesso em: {caminho_blend}")
    return obj_unificado

def executar_criacao_blockout(caminho_saida_blend):
    print("Iniciando criação procedural refinada do Blockout da Alamoa...")
    colecao = limpar_cena()
    
    # 1. Cabeça craniana com cavidades profundas
    obj_head = construir_cranio_rosto()
    colecao.objects.link(obj_head)
    
    # 2. Cabelo (7 massas estilizadas)
    objs_hair = construir_cabelo()
    for o in objs_hair:
        colecao.objects.link(o)
        
    # 3. Pescoço e Tronco
    objs_torso = construir_pescoco_tronco()
    for o in objs_torso:
        colecao.objects.link(o)
        
    # 4. Manto opaco drapeado
    obj_cloak = construir_manto()
    colecao.objects.link(obj_cloak)
    
    # 5. Braços e Mãos gélidas/convidativas
    objs_arms = construir_bracos_e_maos()
    for o in objs_arms:
        colecao.objects.link(o)
        
    # 6. Pernas e Pés
    objs_legs = construir_pernas_e_pes()
    for o in objs_legs:
        colecao.objects.link(o)
        
    # Finalização
    obj_final = unificar_e_finalizar_blockout(colecao, caminho_saida_blend)
    print("Criação do Blockout finalizada com êxito!")

if __name__ == "__main__":
    pasta_raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    caminho_blend = os.path.join(pasta_raiz, "alamoa_blockout.blend")
    executar_criacao_blockout(caminho_blend)
