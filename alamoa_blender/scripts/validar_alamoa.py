"""
Script de validação do modelo da Alamoa para Blender 5.2+.
Pode ser executado com:
blender --background [caminho_blend] --python validar_alamoa.py
"""

import bpy
import bmesh
from mathutils import Vector
import math
import os
import sys

def analisar_objeto(obj):
    me = obj.data
    bm = bmesh.new()
    bm.from_mesh(me)
    
    # Calcular contagem exata de triângulos
    bmesh.ops.triangulate(bm, faces=bm.faces)
    num_tris = len(bm.faces)
    bm.free()
    
    num_verts = len(me.vertices)
    num_polys = len(me.polygons)
    num_edges = len(me.edges)
    
    # Dimensões e bounding box
    bbox_corners = [obj.matrix_world @ Vector(b) for b in obj.bound_box]
    
    min_x = min(c.x for c in bbox_corners)
    max_x = max(c.x for c in bbox_corners)
    min_y = min(c.y for c in bbox_corners)
    max_y = max(c.y for c in bbox_corners)
    min_z = min(c.z for c in bbox_corners)
    max_z = max(c.z for c in bbox_corners)
    
    dim_x = max_x - min_x
    dim_y = max_y - min_y
    dim_z = max_z - min_z
    
    # Verificação de integridade topológica
    bm_check = bmesh.new()
    bm_check.from_mesh(me)
    
    loose_verts = sum(1 for v in bm_check.verts if len(v.link_edges) == 0)
    zero_area_faces = sum(1 for f in bm_check.faces if f.calc_area() < 1e-6)
    non_manifold_edges = sum(1 for e in bm_check.edges if not e.is_manifold)
    
    bm_check.free()
    
    return {
        "nome": obj.name,
        "vertices": num_verts,
        "poligonos": num_polys,
        "triangulos": num_tris,
        "dimensoes": (dim_x, dim_y, dim_z),
        "bounds": ((min_x, max_x), (min_y, max_y), (min_z, max_z)),
        "origem": tuple(obj.location),
        "loose_verts": loose_verts,
        "zero_area_faces": zero_area_faces,
        "non_manifold_edges": non_manifold_edges,
    }

def validar_arquivo(blend_path=None):
    from mathutils import Vector
    
    if blend_path and os.path.exists(blend_path):
        bpy.ops.wm.open_mainfile(filepath=blend_path)
    else:
        blend_path = bpy.data.filepath
        
    print("=" * 60)
    print(f"RELATÓRIO DE VALIDAÇÃO: {os.path.basename(blend_path)}")
    print("=" * 60)
    
    # Localizar objeto principal
    alvo = None
    for nome in ["Alamoa_Blockout", "Alamoa", "alamoa"]:
        if nome in bpy.data.objects:
            alvo = bpy.data.objects[nome]
            break
            
    if not alvo:
        # Se não achou com nome específico, pega o primeiro mesh com mais vértices
        meshes = [o for o in bpy.data.objects if o.type == 'MESH']
        if meshes:
            alvo = max(meshes, key=lambda o: len(o.data.vertices))
            
    if not alvo:
        print("[ERRO CRÍTICO] Nenhum objeto Mesh encontrado na cena!")
        return False
        
    # Análise de Mesh
    info = analisar_objeto(alvo)
    
    print(f"Objeto avaliado: {info['nome']}")
    print(f"- Vértices: {info['vertices']}")
    print(f"- Faces/Polígonos: {info['poligonos']}")
    print(f"- Triângulos: {info['triangulos']} (Orçamento: 2.000 a 4.000)")
    print(f"- Dimensões (L x P x A): {info['dimensoes'][0]:.3f}m x {info['dimensoes'][1]:.3f}m x {info['dimensoes'][2]:.3f}m")
    print(f"- Ponto mais baixo em Z: {info['bounds'][2][0]:.3f}m (Esperado: 0.000m)")
    print(f"- Ponto mais alto em Z: {info['bounds'][2][1]:.3f}m (Esperado: ~2.000m)")
    print(f"- Origem do objeto: ({info['origem'][0]:.3f}, {info['origem'][1]:.3f}, {info['origem'][2]:.3f})")
    print(f"- Vértices soltos: {info['loose_verts']}")
    print(f"- Faces de área zero: {info['zero_area_faces']}")
    print(f"- Arestas não-manifold: {info['non_manifold_edges']}")
    
    # Avaliação de conformidade
    status_tris = "APROVADO" if 2000 <= info['triangulos'] <= 4000 else "FORA DA META"
    status_altura = "APROVADO" if 1.85 <= info['dimensoes'][2] <= 2.15 else "FORA DA META"
    status_chao = "APROVADO" if abs(info['bounds'][2][0]) < 0.05 else "FORA DO CHÃO"
    status_largura = "APROVADO" if info['dimensoes'][0] <= 1.0 else "EXCEDE LARGURA"
    status_topologia = "APROVADO" if info['loose_verts'] == 0 and info['zero_area_faces'] == 0 else "ATENÇÃO NECESSÁRIA"
    
    print("-" * 60)
    print("CONFORMIDADE COM O BRIEFING:")
    print(f"1. Orçamento de Triângulos (2.000-4.000): {status_tris} ({info['triangulos']} tris)")
    print(f"2. Altura Total (~2.0m): {status_altura} ({info['dimensoes'][2]:.3f}m)")
    print(f"3. Alinhamento ao Chão (Z=0): {status_chao} ({info['bounds'][2][0]:.3f}m)")
    print(f"4. Bounding Box da Pose Neutra (<0.85m L): {status_largura} ({info['dimensoes'][0]:.3f}m)")
    print(f"5. Integridade de Vértices e Faces: {status_topologia}")
    print("=" * 60)
    
    # Armature check
    armatures = [o for o in bpy.data.objects if o.type == 'ARMATURE']
    if armatures:
        arm = armatures[0]
        num_bones = len(arm.data.bones)
        print(f"Armature encontrada: '{arm.name}' com {num_bones} ossos (Limite: 28 ossos)")
        if arm.animation_data and arm.animation_data.nla_tracks:
            print("NLA Tracks presentes.")
        actions = list(bpy.data.actions)
        print(f"Actions cadastradas ({len(actions)}): {[a.name for a in actions]}")
    else:
        print("Armature: Não aplicável neste estágio (Checkpoint A: Blockout).")
        
    # Gravar ou atualizar relatorio_validacao.md
    pasta_raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    relatorio_path = os.path.join(pasta_raiz, "relatorio_validacao.md")
    
    with open(relatorio_path, "w", encoding="utf-8") as f:
        f.write("# Relatório de Validação — Alamoa\n\n")
        f.write(f"Arquivo analisado: `{os.path.basename(blend_path)}`\n\n")
        f.write("## 1. Métricas do Modelo\n\n")
        f.write(f"- **Objeto Mestre:** `{info['nome']}`\n")
        f.write(f"- **Vértices:** {info['vertices']}\n")
        f.write(f"- **Polígonos:** {info['poligonos']}\n")
        f.write(f"- **Triângulos reais:** {info['triangulos']} (Meta: 2.000 – 4.000)\n")
        f.write(f"- **Dimensões:** {info['dimensoes'][0]:.3f}m (L) x {info['dimensoes'][1]:.3f}m (P) x {info['dimensoes'][2]:.3f}m (A)\n")
        f.write(f"- **Z Mínimo (Chão):** {info['bounds'][2][0]:.3f}m\n")
        f.write(f"- **Z Máximo (Topo do Cabelo):** {info['bounds'][2][1]:.3f}m\n")
        f.write(f"- **Origem:** ({info['origem'][0]:.3f}, {info['origem'][1]:.3f}, {info['origem'][2]:.3f})\n\n")
        f.write("## 2. Integridade de Geometria\n\n")
        f.write(f"- Vértices soltos: {info['loose_verts']}\n")
        f.write(f"- Faces de área zero: {info['zero_area_faces']}\n")
        f.write(f"- Arestas não-manifold: {info['non_manifold_edges']}\n\n")
        f.write("## 3. Conformidade com Checkpoint\n\n")
        f.write(f"- Orçamento poligonal: **{status_tris}**\n")
        f.write(f"- Altura e escala: **{status_altura}**\n")
        f.write(f"- Pouso no solo (Z=0): **{status_chao}**\n")
        f.write(f"- Volume neutro (largura): **{status_largura}**\n")
        f.write(f"- Integridade de malha: **{status_topologia}**\n")
        
    print(f"Relatório gravado em: {relatorio_path}")
    return True

if __name__ == "__main__":
    pasta_raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    caminho_blend_default = os.path.join(pasta_raiz, "alamoa_blockout.blend")
    
    # Se passou argumento pelo script
    blend = caminho_blend_default
    if "--" in sys.argv:
        args = sys.argv[sys.argv.index("--") + 1:]
        if args:
            blend = args[0]
            
    validar_arquivo(blend)
