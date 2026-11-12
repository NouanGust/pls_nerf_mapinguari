"""
Etapa 4 — Animações de Gameplay da Unidade Pequi (6 Ações NLA)
1. Idle: Respiração rítmica da árvore, pulso da seiva, tronco balançando suavemente no vento do Cerrado.
2. Attack: Tronco inclina para trás tensionando como uma catapulta e estala para frente arremessando a semente com espinhos.
3. Ability: Galhos se abrem para o céu, tronco estica e a semente sobe e vibra liberando pulso de seiva curativa e espinhos.
4. Channel: Vibração concentrada e oscilação intensa dos ramos mantendo a aura de suporte ativa.
5. Stunned: Tronco arqueia enfraquecido para trás, galhos murcham e caem em direção ao chão.
6. Death: O tronco perde a força, desaba para a frente e os galhos se espalham pelo solo.
"""

import bpy
import math
from mathutils import Vector, Euler, Quaternion

bpy.ops.wm.open_mainfile(filepath="C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi.blend")

arm_obj = bpy.data.objects.get("Pequi_Armature")
if not arm_obj:
    raise RuntimeError("Pequi_Armature não encontrado!")

# Limpar ações antigas
for act in list(bpy.data.actions):
    bpy.data.actions.remove(act, do_unlink=True)

# Ativar Pose Mode
bpy.context.view_layer.objects.active = arm_obj
bpy.ops.object.mode_set(mode='POSE')

pose_bones = arm_obj.pose.bones

def reset_pose():
    for pb in pose_bones:
        pb.location = Vector((0, 0, 0))
        pb.rotation_euler = Euler((0, 0, 0), 'XYZ')
        pb.rotation_quaternion = Quaternion((1, 0, 0, 0))
        pb.scale = Vector((1, 1, 1))

def keyframe_all(frame):
    for pb in pose_bones:
        pb.keyframe_insert(data_path="location", frame=frame)
        pb.keyframe_insert(data_path="rotation_quaternion", frame=frame)
        pb.keyframe_insert(data_path="scale", frame=frame)

# ----------------------------------------------------
# 1. IDLE (Ciclo de 60 frames = 2.0s a 30fps)
# ----------------------------------------------------
act_idle = bpy.data.actions.new("Idle")
arm_obj.animation_data_create()
arm_obj.animation_data.action = act_idle

for f in [1, 30, 60]:
    reset_pose()
    if f == 30:
        # Tronco flexiona e respira
        pose_bones["Trunk_01"].rotation_quaternion = Euler((math.radians(2.0), 0, math.radians(-1.5)), 'XYZ').to_quaternion()
        pose_bones["Trunk_02"].rotation_quaternion = Euler((math.radians(-1.5), 0, math.radians(2.0)), 'XYZ').to_quaternion()
        # Galhos oscilam suavemente
        pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(3.0), math.radians(-2.0), 0), 'XYZ').to_quaternion()
        pose_bones["Branch_Arm_L_02"].rotation_quaternion = Euler((math.radians(4.0), 0, math.radians(2.0)), 'XYZ').to_quaternion()
        pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(-3.0), math.radians(2.0), 0), 'XYZ').to_quaternion()
        pose_bones["Branch_Top"].rotation_quaternion = Euler((math.radians(2.5), 0, math.radians(-1.5)), 'XYZ').to_quaternion()
        # Semente pulsa
        pose_bones["Spike_Seed"].location = Vector((0.0, 0.04, 0.02))
        pose_bones["Spike_Seed"].scale = Vector((1.08, 1.08, 1.08))
    keyframe_all(f)

# ----------------------------------------------------
# 2. ATTACK (40 frames = 1.33s)
# ----------------------------------------------------
act_attack = bpy.data.actions.new("Attack")
arm_obj.animation_data.action = act_attack

# Frame 1: Pouso neutro
reset_pose()
keyframe_all(1)

# Frame 12: Wind-up (tronco puxa para trás como estilingue orgânico)
reset_pose()
pose_bones["Trunk_01"].rotation_quaternion = Euler((math.radians(-12.0), 0, math.radians(6.0)), 'XYZ').to_quaternion()
pose_bones["Trunk_02"].rotation_quaternion = Euler((math.radians(-10.0), 0, math.radians(-4.0)), 'XYZ').to_quaternion()
pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(-15.0), math.radians(-8.0), 0), 'XYZ').to_quaternion()
pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(-14.0), math.radians(8.0), 0), 'XYZ').to_quaternion()
pose_bones["Spike_Seed"].location = Vector((0.0, -0.08, -0.04))
pose_bones["Spike_Seed"].scale = Vector((1.2, 1.2, 1.2))
keyframe_all(12)

# Frame 20: Disparo frontal (Snap para frente arremessando a semente com espinhos)
reset_pose()
pose_bones["Trunk_01"].rotation_quaternion = Euler((math.radians(16.0), 0, math.radians(-8.0)), 'XYZ').to_quaternion()
pose_bones["Trunk_02"].rotation_quaternion = Euler((math.radians(14.0), 0, math.radians(6.0)), 'XYZ').to_quaternion()
pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(20.0), math.radians(10.0), 0), 'XYZ').to_quaternion()
pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(18.0), math.radians(-10.0), 0), 'XYZ').to_quaternion()
# Semente projeta para frente em velocidade máxima
pose_bones["Spike_Seed"].location = Vector((0.0, 0.45, 0.15))
keyframe_all(20)

# Frame 28: Recoil amortecido
reset_pose()
pose_bones["Trunk_01"].rotation_quaternion = Euler((math.radians(-4.0), 0, 0), 'XYZ').to_quaternion()
pose_bones["Spike_Seed"].location = Vector((0.0, 0.10, 0.05))
keyframe_all(28)

# Frame 40: Retorno ao repouso
reset_pose()
keyframe_all(40)

# ----------------------------------------------------
# 3. ABILITY (50 frames = 1.66s) — "Semente Espinhosa" / Cura e Explosão
# ----------------------------------------------------
act_ability = bpy.data.actions.new("Ability")
arm_obj.animation_data.action = act_ability

reset_pose()
keyframe_all(1)

# Frame 18: Tronco ergue-se, galhos abrem para os céus canalizando luz
reset_pose()
pose_bones["Trunk_01"].rotation_quaternion = Euler((math.radians(6.0), 0, 0), 'XYZ').to_quaternion()
pose_bones["Trunk_02"].rotation_quaternion = Euler((math.radians(8.0), 0, 0), 'XYZ').to_quaternion()
pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(-18.0), math.radians(-22.0), math.radians(15.0)), 'XYZ').to_quaternion()
pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(-18.0), math.radians(22.0), math.radians(-15.0)), 'XYZ').to_quaternion()
pose_bones["Branch_Top"].rotation_quaternion = Euler((math.radians(12.0), 0, 0), 'XYZ').to_quaternion()
pose_bones["Spike_Seed"].location = Vector((0.0, 0.15, 0.35))
pose_bones["Spike_Seed"].scale = Vector((1.35, 1.35, 1.35))
keyframe_all(18)

# Frame 30: Pulso máximo da habilidade (explosão de seiva e espinhos)
reset_pose()
pose_bones["Trunk_01"].rotation_quaternion = Euler((math.radians(10.0), 0, 0), 'XYZ').to_quaternion()
pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(-25.0), math.radians(-28.0), 0), 'XYZ').to_quaternion()
pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(-25.0), math.radians(28.0), 0), 'XYZ').to_quaternion()
pose_bones["Spike_Seed"].location = Vector((0.0, 0.25, 0.60))
pose_bones["Spike_Seed"].scale = Vector((1.5, 1.5, 1.5))
keyframe_all(30)

# Frame 50: Retorno suave
reset_pose()
keyframe_all(50)

# ----------------------------------------------------
# 4. CHANNEL (30 frames em loop) — Vibração contínua da aura de seiva
# ----------------------------------------------------
act_channel = bpy.data.actions.new("Channel")
arm_obj.animation_data.action = act_channel

for f in [1, 8, 15, 22, 30]:
    reset_pose()
    if f in [8, 22]:
        pose_bones["Trunk_02"].rotation_quaternion = Euler((0, math.radians(2.0), math.radians(-1.5)), 'XYZ').to_quaternion()
        pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(6.0), 0, math.radians(3.0)), 'XYZ').to_quaternion()
        pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(6.0), 0, math.radians(-3.0)), 'XYZ').to_quaternion()
        pose_bones["Spike_Seed"].location = Vector((0.0, 0.05, 0.08))
    elif f == 15:
        pose_bones["Trunk_02"].rotation_quaternion = Euler((0, math.radians(-2.0), math.radians(1.5)), 'XYZ').to_quaternion()
        pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(-6.0), 0, math.radians(-3.0)), 'XYZ').to_quaternion()
        pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(-6.0), 0, math.radians(3.0)), 'XYZ').to_quaternion()
        pose_bones["Spike_Seed"].location = Vector((0.0, 0.08, 0.12))
        pose_bones["Spike_Seed"].scale = Vector((1.15, 1.15, 1.15))
    keyframe_all(f)

# ----------------------------------------------------
# 5. STUNNED (40 frames) — Tronco curvado, galhos murchos
# ----------------------------------------------------
act_stunned = bpy.data.actions.new("Stunned")
arm_obj.animation_data.action = act_stunned

reset_pose()
keyframe_all(1)

reset_pose()
pose_bones["Trunk_01"].rotation_quaternion = Euler((math.radians(-16.0), 0, math.radians(8.0)), 'XYZ').to_quaternion()
pose_bones["Trunk_02"].rotation_quaternion = Euler((math.radians(-12.0), 0, math.radians(-6.0)), 'XYZ').to_quaternion()
pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(-20.0), 0, math.radians(-15.0)), 'XYZ').to_quaternion()
pose_bones["Branch_Arm_L_02"].rotation_quaternion = Euler((math.radians(-15.0), 0, 0), 'XYZ').to_quaternion()
pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(-18.0), 0, math.radians(12.0)), 'XYZ').to_quaternion()
pose_bones["Branch_Top"].rotation_quaternion = Euler((math.radians(-22.0), 0, 0), 'XYZ').to_quaternion()
pose_bones["Spike_Seed"].location = Vector((0.0, -0.08, -0.10))
pose_bones["Spike_Seed"].scale = Vector((0.85, 0.85, 0.85))
keyframe_all(15)
keyframe_all(40)

# ----------------------------------------------------
# 6. DEATH (45 frames) — Queda e desabamento sobre o solo
# ----------------------------------------------------
act_death = bpy.data.actions.new("Death")
arm_obj.animation_data.action = act_death

reset_pose()
keyframe_all(1)

# Frame 18: Impacto e inclinação severa
reset_pose()
pose_bones["Trunk_01"].rotation_quaternion = Euler((math.radians(35.0), 0, math.radians(-15.0)), 'XYZ').to_quaternion()
pose_bones["Trunk_02"].rotation_quaternion = Euler((math.radians(30.0), 0, math.radians(10.0)), 'XYZ').to_quaternion()
pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(25.0), 0, 0), 'XYZ').to_quaternion()
pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(25.0), 0, 0), 'XYZ').to_quaternion()
keyframe_all(18)

# Frame 35..45: Tombamento completo no solo, semente rola para fora
reset_pose()
pose_bones["Trunk_01"].rotation_quaternion = Euler((math.radians(65.0), 0, math.radians(-30.0)), 'XYZ').to_quaternion()
pose_bones["Trunk_02"].rotation_quaternion = Euler((math.radians(45.0), 0, math.radians(20.0)), 'XYZ').to_quaternion()
pose_bones["Branch_Arm_L_01"].rotation_quaternion = Euler((math.radians(40.0), math.radians(30.0), 0), 'XYZ').to_quaternion()
pose_bones["Branch_R_01"].rotation_quaternion = Euler((math.radians(40.0), math.radians(-30.0), 0), 'XYZ').to_quaternion()
pose_bones["Branch_Top"].rotation_quaternion = Euler((math.radians(50.0), 0, 0), 'XYZ').to_quaternion()
pose_bones["Spike_Seed"].location = Vector((0.15, 0.65, -0.45))
pose_bones["Spike_Seed"].scale = Vector((0.7, 0.7, 0.7))
keyframe_all(35)
keyframe_all(45)

# Converter todas as 6 ações em trilhas NLA para exportação limpa no GLTF/GLB
bpy.ops.object.mode_set(mode='OBJECT')

actions = [act_idle, act_attack, act_ability, act_channel, act_stunned, act_death]
nla_tracks = arm_obj.animation_data.nla_tracks
for t in list(nla_tracks):
    nla_tracks.remove(t)

for act in actions:
    track = nla_tracks.new()
    track.name = act.name
    strip = track.strips.new(act.name, 1, act)
    strip.action = act

arm_obj.animation_data.action = act_idle

# Salvar o blend
prod_blend = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi.blend"
bpy.ops.wm.save_as_mainfile(filepath=prod_blend)
print("Todas as 6 ações NLA criadas e integradas no pequi.blend!")

# Exportar modelo GLB oficial para a pasta models/pequi/pequi.glb
glb_path = "C:/Users/Professor/Documents/Nohan/mapinguari/pls_nerf_mapinguari/models/pequi/pequi.glb"
bpy.ops.export_scene.gltf(
    filepath=glb_path,
    export_format='GLB',
    use_selection=False,
    export_apply=False,
    export_animations=True,
    export_nla_strips=True,
    export_def_bones=True,
    export_materials='EXPORT',
    export_image_format='AUTO'
)
print(f"GLB exportado com sucesso: {glb_path}")

