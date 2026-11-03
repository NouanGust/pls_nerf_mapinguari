class_name MboiGuacuAbility
extends "res://Scripts/Abilities/unit_ability.gd"

## Habilidade Bespoke: Constrição Mortal (M'Boi Guaçu)

func execute(unit: BaseUnit3D, _scale_multiplier: float = 1.0) -> bool:
	if not is_instance_valid(unit.current_target) or unit.current_target.current_state == BaseUnit3D.State.DEAD or unit.current_target.is_on_bench():
		unit.find_target()
	var target := unit.current_target
	if not is_instance_valid(target) or target.current_state == BaseUnit3D.State.DEAD or target.is_on_bench():
		return false

	if unit.model:
		var tw := unit.create_tween()
		tw.tween_property(unit.model, "scale", unit.model_base_scale * Vector3(1.3, 0.75, 1.3), 0.15).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(unit.model, "scale", unit.model_base_scale, 0.22).set_trans(Tween.TRANS_BOUNCE)

	CombatFeedback.create_status_indicator(unit, "CONSTRIÇÃO MORTAL", 1.2)
	CombatFeedback.create_hit_particles(unit.global_position, Color("#0284c7"))

	var duration: float = unit.stats.ability_duration if unit.stats.ability_duration > 0.0 else 4.0
	var tick_damage: float = (unit.stats.ability_damage if unit.stats.ability_damage > 0.0 else 40.0) * unit.stats.get_star_multiplier(unit.star_level)
	var shield_amount: float = (unit.stats.ability_shield if unit.stats.ability_shield > 0.0 else 160.0) * unit.stats.get_star_multiplier(unit.star_level)
	unit.current_shield = maxf(unit.current_shield, shield_amount)

	target.apply_stun(duration, "CONSTRITO")
	target.apply_armor_shred(duration, 25.0)
	_create_coil_element(target, duration)

	_run_ticks(unit, target, duration, tick_damage)
	return true

func _run_ticks(unit: BaseUnit3D, target: BaseUnit3D, duration: float, tick_damage: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and is_instance_valid(target) and target.current_state != BaseUnit3D.State.DEAD and is_instance_valid(unit) and unit.current_state != BaseUnit3D.State.DEAD:
		var target_pos := target.global_position
		target.take_damage(tick_damage, unit, UnitStats.DamageType.PHYSICAL)
		CombatFeedback.create_hit_particles(target_pos, Color("#0284c7"))
		CombatFeedback.create_hit_particles(target_pos + Vector3.UP * 0.4, Color("#166534"))
		await unit.get_tree().create_timer(1.0, false).timeout
		elapsed += 1.0

func _create_coil_element(target: BaseUnit3D, duration: float) -> void:
	if not is_instance_valid(target):
		return
	var coil := Node3D.new()
	coil.name = "MboiGuacuCoilVisual"
	target.add_child(coil)
	coil.position = Vector3.ZERO

	var coil_mat := StandardMaterial3D.new()
	coil_mat.albedo_color = Color("#0284c7")
	coil_mat.emission_enabled = true
	coil_mat.emission = Color("#38bdf8")
	coil_mat.emission_energy_multiplier = 2.2
	coil_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	for i in 3:
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 0.32
		torus.outer_radius = 0.44
		ring.mesh = torus
		ring.material_override = coil_mat
		ring.position = Vector3(0.0, 0.35 + float(i) * 0.35, 0.0)
		ring.rotation.x = 0.25 * (1.0 if i % 2 == 0 else -1.0)
		coil.add_child(ring)

	var tw := coil.create_tween()
	tw.set_parallel(true)
	tw.tween_property(coil, "rotation:y", TAU * 4.0, duration)

	var tw_seq := coil.create_tween()
	tw_seq.tween_interval(duration)
	tw_seq.tween_callback(func() -> void:
		if is_instance_valid(coil):
			coil.queue_free()
	)
