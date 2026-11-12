"""
Etapa 3 — Rigging & Skinning da Unidade Pequi
- Cria Armature 'Pequi_Armature' com hierarquia de 14 ossos:
  * Root (base no chão)
  * Trunk_01, Trunk_02, Trunk_Forquilha (coluna retorcida da árvore)
  * Branch_Arm_L_01, Branch_Arm_L_02 (o braço serpenteante horizontal)
  * Branch_R_01, Branch_R_02 (galho direito)
  * Branch_Top (copa superior)
  * Fruit_Cup (cálice da drupa)
  * Spike_Seed (caroço de espinhos sagrado móvel)
  * Root_L, Root_R, Root_Back (raízes no solo)
- Calcula proximidade e pesos de skinning para 100% dos vértices (sem vértices soltos)
- Limita a no máximo 4 influências por vértice
- Vincula o modificador Armature
- Salva pequi.blend
"""

import bpy
import bmesh
import math
from mathutils import Vector

bpy.ops.wm.open_mainfile(filepath="C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi.blend")

pequi_obj = bpy.data.objects.get("Pequi")
if not pequi_obj:
    raise RuntimeError("Objeto Pequi não encontrado no arquivo blend!")

# Remover armatures antigas se existirem
for a in [o for o in bpy.data.objects if o.type == 'ARMATURE']:
    bpy.data.objects.remove(a, do_unlink=True)
for ad in list(bpy.data.armatures):
    bpy.data.armatures.remove(ad, do_unlink=True)

# 1. Criar Armature
arm_data = bpy.data.armatures.new("Pequi_Armature_Data")
arm_obj = bpy.data.objects.new("Pequi_Armature", arm_data)
bpy.context.collection.objects.link(arm_obj)
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='EDIT')

# Definição dos ossos (nome, head, tail, parent_name)
bones_def = [
    # Raiz no solo
    ("Root",             Vector((0.00,  0.00, 0.00)), Vector((0.00,  0.00, 0.20)), None),
    # Raízes no chão
    ("Root_L",           Vector((0.00,  0.00, 0.08)), Vector((-0.45, 0.35, 0.00)), "Root"),
    ("Root_R",           Vector((0.00,  0.00, 0.08)), Vector((0.48, -0.38, 0.00)), "Root"),
    ("Root_Back",        Vector((0.00,  0.00, 0.08)), Vector((-0.38, -0.42, 0.00)), "Root"),
    # Coluna do tronco retorcido (acompanha o cotovelo da foto)
    ("Trunk_01",         Vector((0.00,  0.00, 0.15)), Vector((0.32, -0.02, 0.70)), "Root"),
    ("Trunk_02",         Vector((0.32, -0.02, 0.70)), Vector((0.15,  0.12, 1.25)), "Trunk_01"),
    ("Trunk_Forquilha",  Vector((0.15,  0.12, 1.25)), Vector((0.08,  0.12, 1.45)), "Trunk_02"),
    # Braço serpenteante esquerdo (horizontal e ondulado)
    ("Branch_Arm_L_01",  Vector((0.08,  0.12, 1.38)), Vector((-0.78, 0.10, 0.85)), "Trunk_Forquilha"),
    ("Branch_Arm_L_02",  Vector((-0.78, 0.10, 0.85)), Vector((-1.00, 0.55, 1.35)), "Branch_Arm_L_01"),
    # Galho direito
    ("Branch_R_01",      Vector((0.08,  0.12, 1.42)), Vector((0.65,  0.05, 1.70)), "Trunk_Forquilha"),
    ("Branch_R_02",      Vector((0.65,  0.05, 1.70)), Vector((0.65,  0.22, 2.40)), "Branch_R_01"),
    # Topo da copa
    ("Branch_Top",       Vector((0.08,  0.12, 1.42)), Vector((0.15, -0.08, 2.48)), "Trunk_Forquilha"),
    # Fruto (cálice e polpa)
    ("Fruit_Cup",        Vector((0.08,  0.12, 1.35)), Vector((0.08,  0.28, 1.35)), "Trunk_Forquilha"),
    # Caroço de espinhos móvel (o núcleo que vibra, arremessa e projeta poder)
    ("Spike_Seed",       Vector((0.08,  0.28, 1.35)), Vector((0.08,  0.52, 1.43)), "Fruit_Cup"),
]

edit_bones = {}
for name, head, tail, parent in bones_def:
    b = arm_data.edit_bones.new(name)
    b.head = head
    b.tail = tail
    edit_bones[name] = b

for name, head, tail, parent in bones_def:
    if parent and parent in edit_bones:
        edit_bones[name].parent = edit_bones[parent]

bpy.ops.object.mode_set(mode='OBJECT')
print(f"Armature criada com {len(arm_data.bones)} ossos.")

# 2. Skinning: Calcular pesos por proximidade com suporte a segmentos de ossos
# Limpar vertex groups antigos
pequi_obj.vertex_groups.clear()

bone_segments = []
for b in arm_obj.data.bones:
    pequi_obj.vertex_groups.new(name=b.name)
    bone_segments.append((b.name, b.head_local, b.tail_local))

def dist_to_segment(p, a, b):
    ab = b - a
    ab_len_sq = ab.length_squared
    if ab_len_sq < 1e-6:
        return (p - a).length
    t = max(0.0, min(1.0, (p - a).dot(ab) / ab_len_sq))
    proj = a + t * ab
    return (p - proj).length

verts = pequi_obj.data.vertices
total_verts = len(verts)
print(f"Calculando pesos de skinning para {total_verts} vértices...")

# Posições especiais para fixar pesos com precisão máxima
seed_loc = Vector((0.08, 0.52, 1.43))
fruit_loc = Vector((0.08, 0.28, 1.35))

for v in verts:
    pos = v.co
    weights = []
    
    # Se for vértice do caroço de espinhos
    if (pos - seed_loc).length < 0.28 and pos.y > 0.38:
        pequi_obj.vertex_groups["Spike_Seed"].add([v.index], 1.0, 'REPLACE')
        continue
    # Se for cálice/polpa do fruto
    elif (pos - fruit_loc).length < 0.38 and pos.y > 0.20 and pos.z > 1.15 and pos.z < 1.65:
        w_seed = max(0.0, 1.0 - (pos - seed_loc).length * 4.0)
        w_cup = 1.0 - w_seed
        pequi_obj.vertex_groups["Fruit_Cup"].add([v.index], w_cup, 'REPLACE')
        if w_seed > 0.05:
            pequi_obj.vertex_groups["Spike_Seed"].add([v.index], w_seed, 'REPLACE')
        continue
        
    for name, h, t in bone_segments:
        # Excluir Spike_Seed para o resto do corpo para manter o projétil limpo
        if name == "Spike_Seed":
            continue
        d = dist_to_segment(pos, h, t)
        # Atenuação gaussiana baseada na distância
        w = 1.0 / (d**2.8 + 0.02)
        weights.append((name, w))
        
    weights.sort(key=lambda x: x[1], reverse=True)
    # Pegar as 4 maiores influências
    top_4 = weights[:4]
    sum_w = sum(w for _, w in top_4)
    if sum_w > 0:
        for name, w in top_4:
            norm_w = w / sum_w
            if norm_w >= 0.02:
                pequi_obj.vertex_groups[name].add([v.index], norm_w, 'REPLACE')
    else:
        # Fallback de segurança para Root
        pequi_obj.vertex_groups["Root"].add([v.index], 1.0, 'REPLACE')

# Validar se 100% dos vértices têm pesos atribuídos
unweighted = []
for v in verts:
    total_v_w = sum(g.weight for g in v.groups)
    if total_v_w <= 1e-4:
        unweighted.append(v.index)

if unweighted:
    print(f"AVISO: {len(unweighted)} vértices sem peso. Corrigindo...")
    for idx in unweighted:
        pequi_obj.vertex_groups["Root"].add([idx], 1.0, 'REPLACE')
else:
    print(f"SUCESSO: 100% dos vértices ({total_verts}/{total_verts}) possuem pesos de deformação atribuídos!")

# 3. Vincular Modificador Armature
pequi_obj.parent = arm_obj
mod_arm = pequi_obj.modifiers.get("Armature")
if not mod_arm:
    mod_arm = pequi_obj.modifiers.new("Armature", type='ARMATURE')
mod_arm.object = arm_obj
mod_arm.use_vertex_groups = True

# Salvar o blend de produção
prod_blend = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi.blend"
bpy.ops.wm.save_as_mainfile(filepath=prod_blend)
print(f"Pequi riggado e salvo em: {prod_blend}")

