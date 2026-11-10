class_name MaeDeOuroAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Relâmpagos Dourados & Bênção Áurea (Mãe d'Ouro)
## Invoca raios faiscantes do céu em cascata sobre múltiplos inimigos,
## além de conceder feixes celestiais restauradores nos aliados mais feridos.

const LightningEffect = preload("res://Scripts/Systems/lightning_effect.gd")

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if not is_instance_valid(unit) or not unit.stats:
		return false

	# 1. Animação de canalização da esfera mágica da Mãe d'Ouro
	_play_caster_animation(unit)

	var damage := unit.stats.ability_damage * unit.stats.get_star_multiplier(unit.star_level)
	var heal_val := unit.stats.ability_heal * unit.stats.get_star_multiplier(unit.star_level)
	var target_count := maxi(unit.stats.ability_targets, 2)

	# 2. Localizar alvos inimigos válidos mais próximos
	var tree := unit.get_tree() if unit.is_inside_tree() else Engine.get_main_loop() as SceneTree
	var enemies: Array = []
	if tree:
		var enemy_group := "enemy_units" if unit.team == 0 else "player_units"
		enemies = tree.get_nodes_in_group(enemy_group).filter(func(u):
			return is_instance_valid(u) and u is BaseUnit3D and u.current_state != BaseUnit3D.State.DEAD and u.visible and not u.is_on_bench()
		)
	enemies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		var da := Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(a.global_position.x, a.global_position.z))
		var db := Vector2(unit.global_position.x, unit.global_position.z).distance_to(Vector2(b.global_position.x, b.global_position.z))
		return da < db
	)
	# Priorizar o alvo atual que a Mãe d'Ouro está atacando diretamente
	if is_instance_valid(unit.current_target) and unit.current_target is BaseUnit3D and unit.current_target in enemies:
		enemies.erase(unit.current_target)
		enemies.insert(0, unit.current_target)

	var hit_count := mini(target_count, enemies.size())
	if hit_count > 0:
		for i in hit_count:
			var enemy: BaseUnit3D = enemies[i]
			var delay: float = 0.16 * float(i)
			_strike_enemy_with_lightning(unit, enemy, damage, delay)
	else:
		# Se não houver inimigos ativos (modo treino/teste solo), faz cair um raio à frente
		var forward_pt := unit.global_position + (-unit.transform.basis.z if unit.transform.basis.z != Vector3.ZERO else Vector3.FORWARD) * 2.5
		LightningEffect.create_strike(forward_pt, Color("#fbbf24"), 9.0)

	# 3. Feixes celestiais e cura em aliados feridos
	var allies: Array = []
	if tree:
		var ally_group := "player_units" if unit.team == 0 else "enemy_units"
		allies = tree.get_nodes_in_group(ally_group).filter(func(ally):
			return is_instance_valid(ally) and ally is BaseUnit3D and ally.current_state != BaseUnit3D.State.DEAD and ally.visible and not ally.is_on_bench() and ally.current_health < ally.get_max_health()
		)
	allies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		return (a.get_max_health() - a.current_health) > (b.get_max_health() - b.current_health)
	)

	var heal_count := mini(target_count, allies.size())
	for j in heal_count:
		var ally: BaseUnit3D = allies[j]
		var heal_delay: float = 0.12 * float(j)
		_bless_ally_with_celestial_beam(unit, ally, heal_val, heal_delay)

	return true

func _play_caster_animation(unit: BaseUnit3D) -> void:
	var ability_title: String = unit.stats.ability_name.to_upper() if not unit.stats.ability_name.is_empty() else "RELÂMPAGO ÁUREO"
	CombatFeedback.create_status_indicator(unit, ability_title, 1.4)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#f59e0b"))
	CombatFeedback.create_hit_particles(unit.global_position + Vector3.UP * 0.7, Color("#fbbf24"))

	if unit.model:
		var tw := unit.create_tween()
		tw.set_parallel(true)
		tw.tween_property(unit.model, "position:y", 0.6, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(unit.model, "rotation:y", TAU * 1.5, 0.45).from(0.0).set_trans(Tween.TRANS_CUBIC)
		tw.chain().tween_property(unit.model, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_BOUNCE)
		tw.tween_callback(func() -> void:
			if is_instance_valid(unit.model):
				unit.model.rotation.y = 0.0
				unit.model.position.y = 0.0
			if is_instance_valid(unit.current_target) and unit.current_target.current_state != BaseUnit3D.State.DEAD:
				var offset := unit.current_target.global_position - unit.global_position
				if offset.length_squared() > 0.001:
					unit.rotation.y = atan2(offset.x, offset.z)
		)

func _strike_enemy_with_lightning(caster: BaseUnit3D, target: BaseUnit3D, damage: float, delay: float) -> void:
	if delay > 0.0 and is_instance_valid(caster):
		var tree := caster.get_tree()
		if tree:
			await tree.create_timer(delay, false).timeout

	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD:
		return

	var impact_pos := target.global_position
	if target.model:
		impact_pos = target.model.global_position + Vector3(0.0, 0.65 * target.model.scale.y, 0.0)
	elif target.is_flying():
		impact_pos.y += target.FLYING_BASE_HEIGHT + 0.65
	else:
		impact_pos.y += 0.75

	# 1. Dispara o relâmpago físico 3D caindo do céu diretamente sobre o corpo do alvo
	LightningEffect.create_strike(impact_pos, Color("#fbbf24"), 9.5, 0.09)

	# 2. Aplica o dano mágico da habilidade
	target.take_damage(damage, caster if is_instance_valid(caster) else null, UnitStats.DamageType.MAGICAL)

	# 3. Se ainda vivo, aplica queimadura mágica dourada
	if is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD:
		target.apply_burn(2.0, caster if is_instance_valid(caster) else null, damage * 0.1)

	# 4. Partículas extras de faíscas áureas no inimigo
	CombatFeedback.create_hit_particles(impact_pos + Vector3.UP * 0.5, Color("#f59e0b"))
	CombatFeedback.create_hit_particles(impact_pos + Vector3.UP * 0.8, Color("#fef08a"))
	if is_instance_valid(caster):
		caster._trigger_camera_shake(0.35, 0.22)

func _bless_ally_with_celestial_beam(caster: BaseUnit3D, target: BaseUnit3D, heal_val: float, delay: float) -> void:
	if delay > 0.0 and is_instance_valid(caster):
		var tree := caster.get_tree()
		if tree:
			await tree.create_timer(delay, false).timeout

	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD:
		return

	# Feixe celestial descendo sobre o aliado
	LightningEffect.create_celestial_beam(target.global_position, Color("#facc15"), 7.5, 0.40, 0.50)

	var healed := target.heal(heal_val, caster if is_instance_valid(caster) else null)
	if healed > 0.0:
		CombatFeedback.create_status_indicator(target, "+%d HP" % int(healed), 1.2)
		CombatFeedback.create_hit_particles(target.global_position + Vector3.UP * 0.4, Color("#fde047"))
