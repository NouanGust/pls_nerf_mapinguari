class_name BaseUnit3D
extends CharacterBody3D

const BattleClock = preload("res://Scripts/Systems/battle_clock.gd")
const AbilityRegistry = preload("res://Scripts/Abilities/ability_registry.gd")
const HealthComponent = preload("res://Scripts/Units/Components/health_component.gd")
const ManaComponent = preload("res://Scripts/Units/Components/mana_component.gd")
const StatusEffectComponent = preload("res://Scripts/Units/Components/status_effect_component.gd")
const CombatStatsComponent = preload("res://Scripts/Units/Components/combat_stats_component.gd")
const LocomotionComponent = preload("res://Scripts/Units/Components/locomotion_component.gd")
const UnitHUD3DComponent = preload("res://Scripts/Units/Components/unit_hud_3d_component.gd")
const TargetingComponent = preload("res://Scripts/Units/Components/targeting_component.gd")
const CombatActionComponent = preload("res://Scripts/Units/Components/combat_action_component.gd")

@export var use_navigation: bool = false # false = movimento direto (robusto para auto-chess)
@export var debug_movement: bool = false # prints de debug

# Signals
signal died(unit: BaseUnit3D)
signal health_changed(current: float, maximum: float)
signal mana_changed(current: float, maximum: float)
signal ability_cast(ability_name: String)
signal combat_metric_recorded(unit: BaseUnit3D, metric: StringName, amount: float)

# Stats
var stats: UnitStats
var current_health: float
var current_mana: float
var star_level: int = 1
var stars: int:
	get: return star_level

## Componentes desacoplados
var health_comp: HealthComponent
var mana_comp: ManaComponent
var status_comp: StatusEffectComponent
var combat_stats_comp: CombatStatsComponent
var locomotion_comp: LocomotionComponent
var hud_comp: UnitHUD3DComponent
var combat_action_comp: CombatActionComponent

# Estado de Combate
enum State {IDLE, MOVING, ATTACKING, CASTING, DEAD, ROOTED}
enum ShieldSource { CLASS, SELF, PLAYER, ENEMY }
const SHIELD_COLORS := {
	ShieldSource.CLASS: Color(1.0, 0.82, 0.22),    # Dourado / Âmbar (Sinergia/Classe)
	ShieldSource.SELF: Color(0.2, 0.82, 1.0),      # Ciano / Azul piscina (Próprio)
	ShieldSource.PLAYER: Color(0.25, 0.95, 0.55),  # Verde Esmeralda (Aliado/Jogador)
	ShieldSource.ENEMY: Color(0.95, 0.25, 0.35),   # Vermelho Carmesim (Inimigo)
}

var current_state: State = State.IDLE
var current_target: BaseUnit3D = null
var invested_gold: int = 0
var synergy_bonuses: Dictionary = {}
var current_shield_source: ShieldSource = ShieldSource.SELF
var shield_sphere: MeshInstance3D = null
var _shield_sphere_tween: Tween = null
var consecutive_attacks: int = 0
var current_shield: float = 0.0:
	set(value):
		current_shield = maxf(value, 0.0)
		if health_comp and health_comp.current_shield != current_shield:
			health_comp.current_shield = current_shield
			if current_shield <= 0.0:
				health_comp.current_shield_source = 0
		if current_shield <= 0.0 and hud_comp:
			hud_comp.clear_shield_visual()
		update_stats_display()
		_update_shield_sphere_visual()
const MAX_CERRADO_STACKS: int = 10
var enemies_defeated: int = 0
var is_synergy_highlighted: bool = false
var first_attack_used: bool = false
var first_hit_checked: bool = false
var slowed_until_msec: int = 0
var attack_weakened_until_msec: int = 0
var attack_damage_multiplier: float = 1.0
var marked_team: int = -1
var mark_expires_at_msec: int = 0
var _health_regen_accumulator: float = 0.0
var _burn_generation: int = 0
var _burn_expires_at_msec: int = 0
var _rooted_target_timer := 0.0
var _aura_indicator: Node3D
var _aura_center := Vector2i(-1, -1)
var _aura_radius: int = -1
var stunned_until_msec: int = 0
var strong_control_immune_until_msec: int = 0
var origin_runtime: OriginRuntime = null
var current_ability_scale: float = 1.0
var _was_stunned: bool = false
var in_combat: bool = false
var _idle_target_timer: float = 0.0
var immune_until_msec: int = 0
var reflect_until_msec: int = 0
var reflect_pct: float = 0.0
var armor_shred_until_msec: int = 0
var armor_shred_amount: float = 0.0
var speed_buff_until_msec: int = 0
var speed_buff_multiplier: float = 1.0
var _is_swooping: bool = false
const FLYING_BASE_HEIGHT: float = 0.55

## ========================================================
## SISTEMA DE ITENS & RELÍQUIAS (Máximo 2 itens por unidade)
## ========================================================
const MAX_ITEMS_PER_UNIT: int = 2
var equipped_items: Array[ItemData] = []
var _vaqueiro_attack_stacks: int = 0
var _fulozinha_hit_counter: int = 0
var _bonfim_nodes_remaining: int = 3
var _bonfim_damage_bonus: float = 0.0
var _has_muiraquita_saved: bool = false
var _first_cast_done: bool = false
var unselectable_until_msec: int = 0

## Posição no Board
var board_position: Vector2i = Vector2i(-1, -1)
var team: int = 0:
	set(value):
		team = value
		if not is_in_group("units"):
			add_to_group("units")
		if team == 0:
			remove_from_group("enemy_units")
			add_to_group("player_units")
		else:
			remove_from_group("player_units")
			add_to_group("enemy_units")
var cell_reference: GridCell3D = null
var combat_ground_height: float = 0.0

func is_on_bench() -> bool:
	return board_position.y < 0

func is_flying() -> bool:
	if not stats:
		return false
	if stats.can_fly:
		return true
	return stats.unit_id in [
		"sabia_laranjeira",
		"arara_azul_lear",
		"ararinha_azul",
		"mutum_de_alagoas",
		"cumacanga",
		"matinta_perera",
		"mae_de_ouro",
		"alamoa",
		"romaozinho"
	]


## Componentes 3D
var model: Node3D
var model_base_scale: Vector3 = Vector3.ONE
var animation_player: AnimationPlayer
var attack_timer: Timer
var unit_visual: UnitVisual
var _death_generation: int = 0
var _star_upgrade_effect_pending: bool = false

## UI 3D
var health_bar_3d: ProgressBar
var shield_bar_3d: ProgressBar
var mana_bar_3d: ProgressBar
var name_label: Label
var hp_label: Label
var mana_label: Label
var star_container: HBoxContainer
var nameplate_container: PanelContainer
var bars_container: Control
var tier_label: Label
var _hp_ticks: Control
var is_hovered: bool = false
var ui_sprite: Sprite3D
var ui_viewport: SubViewport

## VFX
var hit_particles: GPUParticles3D
var ability_particles: GPUParticles3D
var death_particles: GPUParticles3D

## Buffs/Debuffs
var active_buffs: Array[Dictionary] = []

## Navigation
var navigation_agent: NavigationAgent3D

@export var debug_navigation: bool = false

var _detour_dir: Vector3 = Vector3.ZERO
var _detour_timer: float = 0.0

const CombatFeedback = preload("res://Scripts/Systems/combat_feedback.gd")
const UNIT_LABEL_ATLAS: Texture2D = preload("res://Assets/UI/GUI_4x.png")
const UIAtlasCatalog = preload("res://Scripts/UI/ui_atlas_catalog.gd")
const UnitVisual = preload("res://Scripts/Units/unit_visual.gd")
const UNIT_VISUAL_SCENE: PackedScene = preload("res://Scenes/Units/unit_visual.tscn")

func _enter_tree() -> void:
	if not is_in_group("units"):
		add_to_group("units")
	if team == 0:
		if not is_in_group("player_units"):
			add_to_group("player_units")
	else:
		if not is_in_group("enemy_units"):
			add_to_group("enemy_units")

func _ready() -> void:
	if not is_in_group("units"):
		add_to_group("units")
	if team == 0:
		if not is_in_group("player_units"):
			add_to_group("player_units")
	else:
		if not is_in_group("enemy_units"):
			add_to_group("enemy_units")
		
	
	# IMPORTANTE: Configurar collision
	collision_layer = 1 # Layer 1 para unidades
	collision_mask = 1 # Detectar outras unidades
	input_ray_pickable = true
	mouse_entered.connect(func(): set_hovered(true))
	mouse_exited.connect(func(): set_hovered(false))
	
	_setup_components()
	setup_navigation()
	setup_timers()

func _setup_components() -> void:
	if not health_comp:
		health_comp = HealthComponent.new()
		health_comp.name = "HealthComponent"
		add_child(health_comp)
	if not mana_comp:
		mana_comp = ManaComponent.new()
		mana_comp.name = "ManaComponent"
		add_child(mana_comp)
	if not status_comp:
		status_comp = StatusEffectComponent.new()
		status_comp.name = "StatusEffectComponent"
		add_child(status_comp)
	if not combat_stats_comp:
		combat_stats_comp = CombatStatsComponent.new()
		combat_stats_comp.name = "CombatStatsComponent"
		add_child(combat_stats_comp)
	if not locomotion_comp:
		locomotion_comp = LocomotionComponent.new()
		locomotion_comp.name = "LocomotionComponent"
		locomotion_comp.setup(self)
		add_child(locomotion_comp)
	if not hud_comp:
		hud_comp = UnitHUD3DComponent.new()
		hud_comp.name = "UnitHUD3DComponent"
		hud_comp.setup(self)
		add_child(hud_comp)
	if not combat_action_comp:
		combat_action_comp = CombatActionComponent.new()
		combat_action_comp.name = "CombatActionComponent"
		combat_action_comp.setup(self)
		add_child(combat_action_comp)
	

func move_direct_to_target(delta: float = 0.0166) -> void:
	_setup_components()
	locomotion_comp.move_direct_to_target(delta)

func initialize(unit_stats: UnitStats, star: int = 1) -> void:
	stats = unit_stats
	star_level = clampi(star, 1, 4)
	invested_gold = stats.cost
	
	if not is_in_group("units"):
		add_to_group("units")
	if team == 0:
		remove_from_group("enemy_units")
		add_to_group("player_units")
	else:
		remove_from_group("player_units")
		add_to_group("enemy_units")
	
	_setup_components()
	var star_multiplier: float = stats.get_star_multiplier(star_level)
	health_comp.initialize(stats.max_health * star_multiplier)
	mana_comp.initialize(stats.max_mana, stats.starting_mana, stats.mana_per_attack, stats.mana_when_hit)
	status_comp.reset_all()
	combat_stats_comp.reset_buffs()
	current_health = health_comp.current_health
	current_mana = mana_comp.current_mana
	
	current_state = State.IDLE
	origin_runtime = OriginRuntime.new(self)
	
	setup_model()
	setup_aura_indicator()
	setup_stats_display()
	update_stats_display()
	update_health_bar()
	update_mana_bar()

func promote_to_star(new_star_level: int) -> void:
	var previous_star_level := star_level
	star_level = clampi(new_star_level, 1, 4)
	if star_level <= previous_star_level:
		return
	current_health = get_max_health()
	if name_label:
		name_label.text = stats.unit_name
	_update_star_display()
	if health_bar_3d:
		health_bar_3d.max_value = get_max_health()
	update_health_bar()
	if visible:
		_play_star_upgrade_effect()
	else:
		_star_upgrade_effect_pending = true

func play_pending_star_upgrade_effect() -> void:
	if _star_upgrade_effect_pending and visible:
		_star_upgrade_effect_pending = false
		_play_star_upgrade_effect()

func setup_model() -> void:
	if has_node("Model"):
		model = get_node("Model")
		for child in model.get_children():
			model.remove_child(child)
			child.queue_free()
	else:
		model = Node3D.new()
		model.name = "Model"
		add_child(model)
	unit_visual = UNIT_VISUAL_SCENE.instantiate() as UnitVisual
	unit_visual.configure(get_team_display_color(), stats)
	model.add_child(unit_visual)
	animation_player = unit_visual.animation_player

	model_base_scale = Vector3.ONE
	model.scale = model_base_scale
	model.rotation = Vector3.ZERO
	if is_flying():
		model.position.y = FLYING_BASE_HEIGHT
	else:
		model.position.y = 0.0
	rotation.y = PI if team == 1 else 0.0
	setup_team_indicator()
	setup_aura_indicator()
	setup_shield_sphere()

func setup_aura_indicator() -> void:
	_setup_components()
	hud_comp.setup_aura_indicator()

func _update_aura_indicator() -> void:
	if hud_comp:
		hud_comp.update_aura_indicator()

func get_team_display_color() -> Color:
	var tier_color := stats.get_tier_color()
	if team != 1:
		return tier_color
	var saturated := Color.from_hsv(tier_color.h, maxf(tier_color.s, 0.78), maxf(tier_color.v, 0.92))
	return saturated.lerp(Color("#ff4b5f"), 0.28)

func _trigger_camera_shake(intensity: float = 0.5, duration: float = 0.55) -> void:
	var cam_3d := get_viewport().get_camera_3d() if get_viewport() else null
	if cam_3d and cam_3d.get_parent() is GameCamera:
		(cam_3d.get_parent() as GameCamera).shake(intensity, duration)

func _play_star_upgrade_effect() -> void:
	if unit_visual:
		unit_visual.flash_upgrade(Color("#ffe28a") if team == 0 else Color("#ff7588"))
	if star_level >= 3:
		_trigger_camera_shake(0.55, 0.65)

func setup_team_indicator() -> void:
	_setup_components()
	hud_comp.setup_team_indicator()

func setup_shield_sphere() -> void:
	_setup_components()
	hud_comp.setup_shield_sphere()

func set_shield_with_source(amount: float, source: ShieldSource = ShieldSource.SELF) -> void:
	_setup_components()
	current_shield_source = source
	health_comp.max_health = get_max_health()
	health_comp.set_shield(amount, source)
	current_shield = health_comp.current_shield

func clear_shield() -> void:
	if health_comp:
		health_comp.clear_shield()
	current_shield = 0.0
	current_shield_source = ShieldSource.SELF
	if hud_comp:
		hud_comp.clear_shield_visual()
	_update_shield_sphere_visual()
	update_stats_display()

func _update_shield_sphere_visual() -> void:
	if hud_comp:
		hud_comp.update_shield_sphere_visual()

func setup_stats_display() -> void:
	_setup_components()
	hud_comp.setup_stats_display()

func _update_star_display() -> void:
	if hud_comp:
		hud_comp.update_star_display()

func set_hovered(hovered: bool) -> void:
	if is_hovered == hovered:
		return
	is_hovered = hovered
	_update_status_visibility()

func set_synergy_highlighted(highlighted: bool) -> void:
	if is_synergy_highlighted == highlighted:
		return
	is_synergy_highlighted = highlighted
	_update_status_visibility()
	if is_instance_valid(ui_sprite):
		ui_sprite.modulate = Color(1.3, 1.25, 0.85, 1.0) if highlighted else Color.WHITE

func _update_status_visibility() -> void:
	if hud_comp:
		hud_comp.update_status_visibility()

func update_stats_display() -> void:
	if hud_comp:
		hud_comp.update_stats_display()

func setup_navigation() -> void:
	pass

func _setup_navigation_agent() -> void:
	pass

func setup_timers() -> void:
	if not has_node("AttackTimer"):
		attack_timer = Timer.new()
		attack_timer.name = "AttackTimer"
		add_child(attack_timer)
	else:
		attack_timer = get_node("AttackTimer")
	
	attack_timer.wait_time = 1.0 / get_effective_attack_speed()
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	

func get_equipped_items() -> Array[ItemData]:
	return equipped_items

func can_equip_more_items() -> bool:
	return equipped_items.size() < MAX_ITEMS_PER_UNIT

func equip_item(item: ItemData) -> bool:
	if not item or equipped_items.size() >= MAX_ITEMS_PER_UNIT:
		return false
	equipped_items.append(item)
	if is_inside_tree():
		update_stats_display()
		if health_bar_3d:
			health_bar_3d.max_value = get_max_health()
		update_health_bar()
		update_mana_bar()
	return true

func remove_equipped_item_at(index: int) -> ItemData:
	if index >= 0 and index < equipped_items.size():
		var it := equipped_items[index]
		equipped_items.remove_at(index)
		if is_inside_tree():
			update_stats_display()
			if health_bar_3d:
				health_bar_3d.max_value = get_max_health()
			update_health_bar()
		return it
	return null

func unequip_all_items() -> Array[ItemData]:
	var copy := equipped_items.duplicate()
	equipped_items.clear()
	if is_inside_tree():
		update_stats_display()
		if health_bar_3d:
			health_bar_3d.max_value = get_max_health()
		update_health_bar()
	return copy

func has_item_effect(effect_id: StringName) -> bool:
	for it in equipped_items:
		if it.unique_effect_id == effect_id:
			return true
	return false

func get_item_stat_bonus(stat_name: String) -> float:
	var sum := 0.0
	for it in equipped_items:
		if it.stat_modifiers.has(stat_name):
			sum += float(it.stat_modifiers[stat_name])
	return sum

func get_item_granted_origins() -> Array[String]:
	var list: Array[String] = []
	for it in equipped_items:
		if not it.origin_grant.is_empty() and not list.has(it.origin_grant):
			list.append(it.origin_grant)
	return list

func get_max_health() -> float:
	var star_multiplier: float = stats.get_star_multiplier(star_level) if stats else 1.0
	var base_hp: float = (stats.max_health * star_multiplier if stats else 500.0) + get_item_stat_bonus("max_health")
	return base_hp * (1.0 + float(synergy_bonuses.get("max_health_pct", 0.0)))

func _prune_expired_buffs() -> void:
	var now := BattleClock.now_msec()
	active_buffs = active_buffs.filter(func(buff):
		return not buff.has("expires_at_msec") or int(buff.expires_at_msec) > now
	)

func get_support_aura_value(effect_name: String, check_enemies: bool = false) -> float:
	if not is_inside_tree() or not visible or current_state in [State.IDLE, State.DEAD] or is_on_bench():
		return 0.0
	var board := _get_combat_board()
	if not board:
		return 0.0
	var target_cell := board.get_grid_position(board.to_local(global_position))
	if not board.get_cell(target_cell):
		return 0.0
	var group := ("enemy_units" if team == 0 else "player_units") if check_enemies else ("player_units" if team == 0 else "enemy_units")
	var max_val := 0.0
	for node in get_tree().get_nodes_in_group(group):
		var source: BaseUnit3D = node as BaseUnit3D
		if source == self or not is_instance_valid(source) or not source.visible or source.current_state in [State.IDLE, State.DEAD] or source.is_on_bench():
			continue
		if not source.stats or source.stats.passive_aura_effect != effect_name or source.stats.passive_aura_range <= 0:
			continue
		var source_cell := board.get_grid_position(board.to_local(source.global_position))
		if not board.get_cell(source_cell):
			continue
		
		var is_melee: bool = source.stats.get_attack_range_hexes() <= 1 or not source.stats.is_ranged
		if is_melee:
			var is_lateral: bool = (target_cell == source_cell + Vector2i(-1, 0)) or (target_cell == source_cell + Vector2i(1, 0))
			if not is_lateral:
				continue
		else:
			if board.get_hex_distance(source_cell, target_cell) > source.stats.passive_aura_range:
				continue
		
		var power := source.stats.passive_aura_power
		for buff in source.active_buffs:
			if buff.has("support_aura_boost"):
				power *= float(buff.support_aura_boost)
		max_val = maxf(max_val, power)
	return max_val

func get_attack_damage() -> float:
	var star_multiplier: float = stats.get_star_multiplier(star_level) if stats else 1.0
	var base_damage: float = (stats.attack_damage * star_multiplier if stats else 50.0) + get_item_stat_bonus("attack_damage")
	if BattleClock.now_msec() < attack_weakened_until_msec:
		base_damage *= attack_damage_multiplier
	
	for buff in active_buffs:
		if buff.has("attack_multiplier"):
			base_damage *= buff.attack_multiplier
	
	if origin_runtime:
		base_damage *= origin_runtime.get_attack_bonus_multiplier()

	var damage_multiplier := 1.0 + float(synergy_bonuses.get("damage_pct", 0.0)) + get_power_aura_bonus() + _bonfim_damage_bonus
	damage_multiplier *= (1.0 - clampf(get_support_aura_value("enemy_attack_weak", true), 0.0, 0.5))
	if stats and stats.is_atacante_role() and consecutive_attacks > 0:
		damage_multiplier += 0.05 * consecutive_attacks
	if is_instance_valid(current_target):
		if current_target.marked_team == team and BattleClock.now_msec() < current_target.mark_expires_at_msec:
			damage_multiplier += float(synergy_bonuses.get("marked_target_damage_pct", 0.0))
		if _has_ally_focusing_target(current_target):
			damage_multiplier += float(synergy_bonuses.get("focus_fire_damage_pct", 0.0))
	return base_damage * damage_multiplier

func get_power_aura_bonus() -> float:
	return get_support_aura_value("power", false)

func set_synergy_bonuses(bonuses: Dictionary) -> void:
	var old_health_ratio := current_health / maxf(get_max_health(), 1.0) if stats else 1.0
	synergy_bonuses = bonuses.duplicate(true)
	if stats and current_health > 0.0:
		current_health = minf(get_max_health(), get_max_health() * old_health_ratio)
	if navigation_agent:
		navigation_agent.max_speed = get_movement_speed()
	if attack_timer and stats:
		attack_timer.wait_time = 1.0 / get_effective_attack_speed()
	if health_bar_3d:
		health_bar_3d.max_value = get_max_health()
	update_health_bar()

func _has_ally_focusing_target(target: BaseUnit3D) -> bool:
	if float(synergy_bonuses.get("focus_fire_damage_pct", 0.0)) <= 0.0:
		return false
	var ally_group := "player_units" if team == 0 else "enemy_units"
	for ally in get_tree().get_nodes_in_group(ally_group):
		if ally != self and ally.current_state != State.DEAD and ally.current_target == target:
			return true
	return false

func get_effective_attack_speed() -> float:
	var item_as := get_item_stat_bonus("attack_speed_pct") + (float(_vaqueiro_attack_stacks) * 0.05)
	var speed := (stats.attack_speed if stats else 1.0) * (1.0 + float(synergy_bonuses.get("attack_speed_pct", 0.0)) + item_as + get_support_aura_value("attack_speed", false))
	speed *= (1.0 - clampf(get_support_aura_value("enemy_attack_speed_slow", true), 0.0, 0.5))
	if BattleClock.now_msec() < slowed_until_msec:
		speed *= 0.7
	if BattleClock.now_msec() < speed_buff_until_msec:
		speed *= speed_buff_multiplier
	return maxf(speed, 0.1)

func get_effective_armor() -> float:
	var total := stats.armor if stats else 0.0
	total += float(synergy_bonuses.get("armor_flat", 0.0))
	total += float(synergy_bonuses.get("bonus_armor", 0.0))
	total += get_item_stat_bonus("armor")
	total += get_support_aura_value("defense", false)
	for buff in active_buffs:
		if buff.has("armor_flat"):
			total += float(buff.armor_flat)
		if buff.has("bonus_armor"):
			total += float(buff.bonus_armor)
	if origin_runtime:
		total *= origin_runtime.get_defense_reduction_multiplier()
	return maxf(total, 0.0)

func get_effective_magic_resist() -> float:
	var total := stats.magic_resist if stats else 0.0
	total += float(synergy_bonuses.get("magic_resist_flat", 0.0))
	total += float(synergy_bonuses.get("bonus_magic_resist", 0.0))
	total += get_item_stat_bonus("magic_resist")
	total += get_support_aura_value("defense", false)
	for buff in active_buffs:
		if buff.has("magic_resist_flat"):
			total += float(buff.magic_resist_flat)
		if buff.has("bonus_magic_resist"):
			total += float(buff.bonus_magic_resist)
	if origin_runtime:
		total *= origin_runtime.get_defense_reduction_multiplier()
	return maxf(total, 0.0)

func apply_speed_buff(duration: float, multiplier: float = 1.35, label: String = "+VELOCIDADE") -> void:
	speed_buff_multiplier = multiplier
	speed_buff_until_msec = maxi(speed_buff_until_msec, BattleClock.now_msec() + int(duration * 1000.0))
	if attack_timer:
		attack_timer.wait_time = 1.0 / get_effective_attack_speed()
	CombatFeedback.create_status_indicator(self, label, duration)

func apply_slow(duration: float) -> void:
	var resistance := clampf(float(synergy_bonuses.get("control_resist_pct", 0.0)), 0.0, 0.9)
	var adjusted_duration := duration * (1.0 - resistance)
	slowed_until_msec = maxi(slowed_until_msec, BattleClock.now_msec() + int(adjusted_duration * 1000.0))
	if attack_timer:
		attack_timer.wait_time = 1.0 / get_effective_attack_speed()

func apply_attack_weakness(duration: float, damage_multiplier: float = 0.7) -> void:
	if current_state == State.DEAD or duration <= 0.0:
		return
	var now := BattleClock.now_msec()
	if now >= attack_weakened_until_msec:
		attack_damage_multiplier = 1.0
	attack_damage_multiplier = minf(attack_damage_multiplier, clampf(damage_multiplier, 0.0, 1.0))
	attack_weakened_until_msec = maxi(attack_weakened_until_msec, now + int(duration * 1000.0))
	CombatFeedback.create_status_indicator(self, "ENFRAQUECIDO", duration)

func is_stunned() -> bool:
	return BattleClock.now_msec() < stunned_until_msec

func is_immune() -> bool:
	return BattleClock.now_msec() < immune_until_msec

func apply_stun(duration: float, label: String = "ATORDOADO") -> void:
	if current_state == State.DEAD or duration <= 0.0 or is_on_bench():
		return
	var now := BattleClock.now_msec()
	if now < strong_control_immune_until_msec:
		return
	duration = minf(duration, 1.0)
	var origin_cr := origin_runtime.get_control_resist_bonus() if origin_runtime else 0.0
	var aura_cr := get_support_aura_value("control_resist", false)
	var total_resist := float(synergy_bonuses.get("control_resist_pct", 0.0)) + (stats.stun_resist if stats else 0.0) + origin_cr + aura_cr
	var resist := clampf(total_resist, 0.0, 0.50)
	var final_duration := duration * (1.0 - resist)
	if final_duration <= 0.0:
		return
	stunned_until_msec = maxi(stunned_until_msec, now + int(final_duration * 1000.0))
	strong_control_immune_until_msec = now + int((final_duration + 0.75) * 1000.0)
	_was_stunned = true
	velocity = Vector3.ZERO
	if attack_timer:
		attack_timer.stop()
	if navigation_agent:
		navigation_agent.velocity = Vector3.ZERO
	if unit_visual:
		unit_visual.update_locomotion(false, 0.0, true)
		unit_visual.play_stun()
	if current_state in [State.ATTACKING, State.MOVING]:
		current_state = State.IDLE
	if is_inside_tree():
		CombatFeedback.create_status_indicator(self, label, final_duration)
		CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.8, Color("#fde047"))

func _recover_from_stun() -> void:
	if current_state == State.DEAD or is_on_bench():
		return
	if not in_combat:
		current_state = State.IDLE
		velocity = Vector3.ZERO
		current_target = null
		if attack_timer:
			attack_timer.stop()
		return
	if stats and stats.is_stationary:
		_wait_rooted()
		_rooted_target_timer = 0.0
		find_target()
		return
	
	current_state = State.IDLE
	velocity = Vector3.ZERO
	if is_instance_valid(current_target) and not current_target.is_queued_for_deletion() and current_target.current_state != State.DEAD and not current_target.is_on_bench() and current_target.visible:
		check_attack_or_move()
	else:
		current_target = null
		find_target()
	
	if current_mana >= stats.max_mana and stats.ability_name and current_state != State.IDLE and not is_stunned():
		cast_ability()

func apply_armor_shred(duration: float, amount: float) -> void:
	if current_state == State.DEAD or duration <= 0.0:
		return
	armor_shred_amount = maxf(armor_shred_amount, amount)
	armor_shred_until_msec = maxi(armor_shred_until_msec, BattleClock.now_msec() + int(duration * 1000.0))
	CombatFeedback.create_status_indicator(self, "ARMADURA REDUZIDA", duration)

func on_enemy_defeated() -> void:
	enemies_defeated = mini(enemies_defeated + 1, MAX_CERRADO_STACKS)
	if has_item_effect(&"capelobo_spur"):
		var enemy_grp := "enemy_units" if team == 0 else "player_units"
		for enemy in get_tree().get_nodes_in_group(enemy_grp):
			if enemy is BaseUnit3D and is_instance_valid(enemy) and enemy.current_state != State.DEAD:
				if global_position.distance_to(enemy.global_position) <= 3.5:
					enemy.apply_armor_shred(4.0, enemy.get_effective_armor() * 0.30)
		CombatFeedback.create_status_indicator(self, "UIVO DO CAPELOBO!", 1.2)

func start_combat() -> void:
	if is_on_bench():
		return
	in_combat = true
	stunned_until_msec = 0
	strong_control_immune_until_msec = 0
	_was_stunned = false
	_idle_target_timer = 0.0
	use_navigation = false
	_detour_dir = Vector3.ZERO
	_detour_timer = 0.0
	velocity = Vector3.ZERO
	combat_ground_height = global_position.y
	_prune_expired_buffs()

	# Resets de combate dos Itens
	_vaqueiro_attack_stacks = 0
	_fulozinha_hit_counter = 0
	_bonfim_nodes_remaining = 3
	_bonfim_damage_bonus = 0.0
	_has_muiraquita_saved = false
	_first_cast_done = false

	if origin_runtime:
		origin_runtime.reset_for_combat()
	var shield_multiplier := 1.0 + float(synergy_bonuses.get("shield_power_pct", 0.0))
	shield_multiplier *= 1.0 + float(synergy_bonuses.get("shield_received_pct", 0.0))
	var start_sh := get_max_health() * float(synergy_bonuses.get("start_shield_pct", 0.0)) * shield_multiplier
	if start_sh > 0.0:
		set_shield_with_source(start_sh, ShieldSource.CLASS)
	else:
		current_shield = 0.0

	# Passivas de Início de Combate de Itens
	var item_start_mana := get_item_stat_bonus("starting_mana")
	if item_start_mana > 0.0 and stats:
		current_mana = clampf(stats.starting_mana + item_start_mana, 0.0, stats.max_mana)
		update_mana_bar()

	if has_item_effect(&"sertanejo_horn"):
		var ally_group := "player_units" if team == 0 else "enemy_units"
		for ally in get_tree().get_nodes_in_group(ally_group):
			if ally is BaseUnit3D and is_instance_valid(ally) and ally != self and not ally.is_on_bench():
				if absf(ally.global_position.z - global_position.z) <= 2.5:
					ally.apply_speed_buff(5.0, 1.25, "+BERRANTE")
					ally.add_mana(15.0)
		CombatFeedback.create_status_indicator(self, "TOQUE DO BERRANTE!", 1.5)

	if has_item_effect(&"cachaca_offering"):
		unselectable_until_msec = BattleClock.now_msec() + 5000
		CombatFeedback.create_status_indicator(self, "OFERENDA NA MATA", 2.0)

	if has_item_effect(&"comigo_ninguem_pode"):
		set_shield_with_source(current_shield + 250.0, ShieldSource.SELF)
		var ally_grp := "player_units" if team == 0 else "enemy_units"
		for ally in get_tree().get_nodes_in_group(ally_grp):
			if ally is BaseUnit3D and is_instance_valid(ally) and ally != self and not ally.is_on_bench():
				if global_position.distance_to(ally.global_position) <= 3.0:
					ally.set_shield_with_source(ally.current_shield + 250.0, ShieldSource.PLAYER)

	first_attack_used = false
	first_hit_checked = false
	enemies_defeated = 0
	current_state = State.IDLE
	if attack_timer:
		attack_timer.stop()
		attack_timer.wait_time = 1.0 / get_effective_attack_speed()
	print("%s iniciando combate (Team %d)" % [stats.unit_name, team])
	current_target = TargetingComponent.find_target_for(self)
	if current_target:
		_face_target()
		var distance := Vector2(global_position.x, global_position.z).distance_to(
			Vector2(current_target.global_position.x, current_target.global_position.z)
		)
		if distance <= get_attack_range_meters():
			current_state = State.ATTACKING
			if attack_timer:
				attack_timer.start()
		else:
			current_state = State.MOVING

func find_target() -> void:
	current_target = TargetingComponent.find_target_for(self)
	if current_target:
		check_attack_or_move()

func get_frontline_enemy(enemies: Array) -> BaseUnit3D:
	return TargetingComponent.get_frontline_enemy(global_position, enemies)

func get_backline_enemy(enemies: Array) -> BaseUnit3D:
	return TargetingComponent.get_backline_enemy(global_position, enemies)

func get_closest_enemy(enemies: Array) -> BaseUnit3D:
	return TargetingComponent.get_closest_enemy(global_position, enemies)

func on_basic_attack_landed(target: BaseUnit3D) -> void:
	if not is_instance_valid(target) or target.current_state == State.DEAD:
		return
	
	# Chicote da Fulozinha: a cada 3 ataques enraíza o alvo por 1s
	if has_item_effect(&"fulozinha_whip"):
		_fulozinha_hit_counter += 1
		if _fulozinha_hit_counter >= 3:
			_fulozinha_hit_counter = 0
			target.apply_root(1.0)
			CombatFeedback.create_status_indicator(target, "ENRAIZADO!", 1.0)

	# Espora de Vaqueiro: +5% de velocidade de ataque a cada golpe (max 20)
	if has_item_effect(&"vaqueiro_spur"):
		if _vaqueiro_attack_stacks < 20:
			_vaqueiro_attack_stacks += 1
			if attack_timer:
				attack_timer.wait_time = 1.0 / get_effective_attack_speed()

	# Cachimbo do Saci: +4 de mana por golpe
	if has_item_effect(&"saci_pipe"):
		add_mana(4.0)

	# Foice do Corpo-Seco: dessecação com dano verdadeiro e redução de cura
	if has_item_effect(&"corpo_seco_scythe"):
		target.apply_burn(3.0, self, 18.0)
		CombatFeedback.create_status_indicator(target, "DESSECAÇÃO", 1.5)

	# Bala de Prata Benzida: bônus contra Metamorfo e Assombração
	if has_item_effect(&"silver_bullet") and target.stats:
		var is_supernatural: bool = target.stats.classes.has("Assombração") or target.stats.classes.has("Metamorfo") or target.stats.origins.has("Urbano")
		if is_supernatural:
			var bonus_dmg := get_attack_damage() * 0.25
			target.take_damage(bonus_dmg, self, UnitStats.DamageType.TRUE)
			CombatFeedback.create_damage_number(target.global_position, bonus_dmg, CombatFeedback.DamageType.CRITICAL)

func get_effective_attack_range_hexes() -> int:
	if not stats:
		return 1
	var r := stats.get_attack_range_hexes()
	if has_item_effect(&"fulozinha_whip") and r <= 1:
		r += 1
	return r

func get_attack_range_meters() -> float:
	return float(get_effective_attack_range_hexes()) * 2.0 + 0.5

func is_target_in_attack_range(target: BaseUnit3D) -> bool:
	if not is_instance_valid(target) or target.is_queued_for_deletion() or target.current_state == State.DEAD or not target.visible or target.is_on_bench():
		return false
	return Vector2(global_position.x, global_position.z).distance_to(
		Vector2(target.global_position.x, target.global_position.z)
	) <= get_attack_range_meters()

func has_pending_combat_effects() -> bool:
	return current_state == State.CASTING or BattleClock.now_msec() < _burn_expires_at_msec

func check_attack_or_move() -> void:
	if current_state == State.DEAD or current_state == State.CASTING or is_on_bench() or is_stunned():
		return
	if not is_instance_valid(current_target) or current_target.is_queued_for_deletion() or current_target.current_state == State.DEAD or current_target.is_on_bench():
		if debug_movement:
			print("%s: alvo invalidado" % stats.unit_name)
		current_target = null
		find_target()
		return
	
	var distance := Vector2(global_position.x, global_position.z).distance_to(
		Vector2(current_target.global_position.x, current_target.global_position.z)
	)
	var range_threshold := get_attack_range_meters()
	
	if debug_movement:
		print("%s: dist=%.2fm, range=%.2fm" % [
			stats.unit_name,
			distance,
			range_threshold
		])
	
	if distance <= range_threshold:
		if debug_movement:
			print("%s: ATACANDO!" % stats.unit_name)
		start_attacking()
	else:
		if attack_timer:
			attack_timer.stop()
		if debug_movement:
			print("%s: MOVENDO (modo: %s)" % [
				stats.unit_name,
				"Navigation" if use_navigation else "Direto"
			])
		move_towards_target()

func move_towards_target() -> void:
	_setup_components()
	locomotion_comp.move_towards_target()

func _physics_process(delta: float) -> void:
	if in_combat and current_state != State.DEAD and not is_on_bench() and has_active_shield():
		if health_comp:
			var loss := health_comp.decay_shield(delta)
			if loss > 0.0:
				current_shield = health_comp.current_shield
				_update_shield_sphere_visual()

	if not in_combat:
		if current_state in [State.MOVING, State.ATTACKING, State.ROOTED]:
			if attack_timer:
				attack_timer.stop()
			current_target = null
			velocity = Vector3.ZERO
			_detour_timer = 0.0
			_detour_dir = Vector3.ZERO
			current_state = State.IDLE
		return

	if is_stunned():
		_was_stunned = true
		velocity = Vector3.ZERO
		return

	if _was_stunned:
		_was_stunned = false
		_recover_from_stun()
		return

	if stats and stats.is_stationary:
		velocity = Vector3.ZERO
		if current_state == State.ROOTED:
			_rooted_target_timer -= delta
			if _rooted_target_timer <= 0.0:
				_rooted_target_timer = 0.25
				find_target()
		return

	if current_state == State.MOVING:
		if not is_instance_valid(current_target) or current_target.current_state == State.DEAD or current_target.is_on_bench():
			current_target = null
			current_state = State.IDLE
			velocity = Vector3.ZERO
			_detour_timer = 0.0
			_detour_dir = Vector3.ZERO
			find_target()
		else:
			move_direct_to_target(delta)
	elif current_state == State.ATTACKING:
		if attack_timer and attack_timer.is_stopped():
			attack_timer.start()
	elif current_state == State.IDLE and in_combat:
		_idle_target_timer -= delta
		if _idle_target_timer <= 0.0:
			_idle_target_timer = 0.25
			find_target()

func _on_velocity_computed(_safe_velocity: Vector3) -> void:
	pass

func get_movement_speed() -> float:
	_setup_components()
	return locomotion_comp.get_movement_speed()

func _wait_rooted() -> void:
	_setup_components()
	locomotion_comp.wait_rooted()

func start_attacking() -> void:
	_setup_components()
	combat_action_comp.start_attacking()

func _on_attack_timer_timeout() -> void:
	_setup_components()
	combat_action_comp.on_attack_timer_timeout()

func perform_attack() -> void:
	_setup_components()
	combat_action_comp.perform_attack()

func _face_target() -> void:
	if combat_action_comp:
		combat_action_comp.face_target()

func _show_plant_projectile(target_position: Vector3) -> void:
	_setup_components()
	combat_action_comp.show_plant_projectile(target_position)

func get_projectile_color() -> Color:
	_setup_components()
	return combat_action_comp.get_projectile_color()

func _spawn_ballistic_projectile(
	start_pos: Vector3,
	target: BaseUnit3D,
	impact_pos: Vector3,
	color: Color,
	arc_height: float = 1.2,
	duration: float = 0.35,
	on_impact: Callable = Callable(),
	projectile_name: String = "UnitProjectile",
	radius: float = 0.16,
	is_arrow_or_dart: bool = false
) -> Node3D:
	_setup_components()
	return combat_action_comp.spawn_ballistic_projectile(
		start_pos, target, impact_pos, color, arc_height, duration, on_impact, projectile_name, radius, is_arrow_or_dart
	)

func take_damage(amount: float, attacker: BaseUnit3D, damage_type: UnitStats.DamageType = UnitStats.DamageType.PHYSICAL) -> void:
	if current_state == State.DEAD or is_on_bench():
		return
	if is_immune():
		CombatFeedback.create_status_indicator(self, "IMUNE", 0.5)
		return
	if not first_hit_checked:
		first_hit_checked = true
		var dodge_chance := float(synergy_bonuses.get("dodge_first_hit_chance", 0.0))
		if dodge_chance > 0.0 and randf() < dodge_chance:
			return

	if origin_runtime:
		origin_runtime.check_vigilia_trigger(amount)
	if is_instance_valid(attacker) and attacker.origin_runtime:
		amount *= attacker.origin_runtime.get_approach_damage_multiplier(self)

	_setup_components()
	var effective_armor := get_effective_armor()
	if BattleClock.now_msec() < armor_shred_until_msec:
		effective_armor = maxf(effective_armor - armor_shred_amount, 0.0)

	var effective_mr := get_effective_magic_resist()

	var extra_reduction := 0.0
	if damage_type != UnitStats.DamageType.TRUE:
		extra_reduction = float(synergy_bonuses.get("damage_reduction_pct", 0.0))
		extra_reduction += get_support_aura_value("damage_reduction", false)
		if current_health / maxf(get_max_health(), 1.0) <= 0.5:
			extra_reduction += float(synergy_bonuses.get("low_health_resistance_pct", 0.0))

	var actual_damage: float = combat_stats_comp.calculate_mitigated_damage(
		amount,
		damage_type,
		effective_armor,
		effective_mr,
		extra_reduction
	)

	# Efeito: Casco Ancestral de Jabuti (Redução plana de dano direto)
	if has_item_effect(&"jabuti_shell"):
		actual_damage = maxf(actual_damage - 20.0, 1.0)

	# Efeito: Caroço de Pequi Espinhoso (Retaliação a agressores corpo a corpo)
	if has_item_effect(&"pequi_spikes") and is_instance_valid(attacker) and attacker != self:
		if attacker.current_state != State.DEAD and not attacker.is_on_bench():
			var is_melee: bool = attacker.stats and attacker.stats.get_attack_range_hexes() <= 1
			if is_melee:
				var thorns_dmg: float = actual_damage * 0.20
				attacker.take_damage(thorns_dmg, self, UnitStats.DamageType.PHYSICAL)
				CombatFeedback.create_damage_number(attacker.global_position, thorns_dmg, CombatFeedback.DamageType.DAMAGE)
				CombatFeedback.create_hit_particles(attacker.global_position, Color("#f59e0b"))

	if BattleClock.now_msec() < reflect_until_msec:
		actual_damage *= 0.6
		if is_instance_valid(attacker) and attacker != self and attacker.current_state != State.DEAD and not attacker.is_on_bench():
			var reflected := actual_damage * reflect_pct
			attacker.take_damage(reflected, self, UnitStats.DamageType.PHYSICAL)
			CombatFeedback.create_damage_number(attacker.global_position, reflected, CombatFeedback.DamageType.CRITICAL)
			CombatFeedback.create_hit_particles(attacker.global_position, Color("#94a3b8"))

	if actual_damage <= 0.0:
		return

	var was_shielded := has_active_shield()
	health_comp.current_health = current_health
	health_comp.current_shield = current_shield
	health_comp.max_health = get_max_health()
	var dmg_res: Dictionary = health_comp.apply_damage(actual_damage)
	current_shield = health_comp.current_shield
	current_health = health_comp.current_health
	var shield_absorbed: float = dmg_res.absorbed_by_shield
	var health_damage: float = dmg_res.damage_to_health
	combat_metric_recorded.emit(self, &"damage_received", actual_damage)
	if is_instance_valid(attacker):
		attacker.combat_metric_recorded.emit(attacker, &"damage_dealt", actual_damage)
	update_health_bar()
	
	# FEEDBACK VISUAL DE DANO
	if is_inside_tree():
		if shield_absorbed > 0.0:
			CombatFeedback.create_damage_number(global_position + Vector3.UP * 0.35, shield_absorbed, CombatFeedback.DamageType.SHIELD)
			CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.25, Color("#38bdf8"))
		if health_damage > 0.0:
			CombatFeedback.create_damage_number(global_position, health_damage, CombatFeedback.DamageType.DAMAGE)
			CombatFeedback.create_hit_particles(global_position, Color.RED)
	
	flash_damage()

	# Salva-Vidas: Muiraquitã das Icamiabas (<25% Vida)
	if has_item_effect(&"muiraquita_lifesaver") and not _has_muiraquita_saved and current_health > 0.0:
		if (current_health / maxf(get_max_health(), 1.0)) <= 0.25:
			_has_muiraquita_saved = true
			immune_until_msec = BattleClock.now_msec() + 1500
			heal(get_max_health() * 0.30)
			CombatFeedback.create_status_indicator(self, "MUIRAQUITÃ SAGRADO!", 1.5)
			CombatFeedback.create_hit_particles(global_position, Color("#10b981"))

	# O golpe que quebra o escudo também não gera mana.
	if not was_shielded and current_health > 0.0:
		add_mana(stats.mana_when_hit)
	if float(synergy_bonuses.get("root_on_hit_chance", 0.0)) > 0.0 and is_instance_valid(attacker) and randf() < float(synergy_bonuses.get("root_on_hit_chance", 0.0)):
		attacker.apply_slow(1.0)
	
	if is_instance_valid(attacker) and float(attacker.synergy_bonuses.get("slow_on_hit_chance", 0.0)) > 0.0 and randf() < float(attacker.synergy_bonuses.get("slow_on_hit_chance", 0.0)):
		apply_slow(1.5)
	if current_health <= 0:
		if is_instance_valid(attacker):
			attacker.on_enemy_defeated()
		die()

func heal(amount: float, healer: BaseUnit3D = null) -> float:
	if current_state == State.DEAD or amount <= 0.0 or is_on_bench():
		return 0.0

	_setup_components()
	var heal_multiplier := 1.0 + float(synergy_bonuses.get("healing_received_pct", 0.0))
	heal_multiplier += get_support_aura_value("heal_received", false)
	if is_instance_valid(healer):
		heal_multiplier *= 1.0 + float(healer.synergy_bonuses.get("healing_power_pct", 0.0))
	if BattleClock.now_msec() < _burn_expires_at_msec:
		heal_multiplier *= 0.4

	health_comp.current_health = current_health
	health_comp.max_health = get_max_health()
	var healed_amount: float = health_comp.apply_heal(amount, heal_multiplier)
	current_health = health_comp.current_health

	if healed_amount > 0.0:
		update_health_bar()
		var source := healer if is_instance_valid(healer) else self
		source.combat_metric_recorded.emit(source, &"healing_done", healed_amount)

	return healed_amount

func _apply_ability_healing(scale_multiplier: float = 1.0) -> void:
	if not stats or stats.ability_heal <= 0.0 or current_state == State.DEAD or is_on_bench():
		return
	var eff_scale := scale_multiplier if not is_equal_approx(scale_multiplier, 1.0) else current_ability_scale
	var heal_amount := stats.ability_heal * stats.get_star_multiplier(star_level) * maxf(eff_scale, 0.01)
	if heal_amount <= 0.0:
		return

	var targets_count := maxi(stats.ability_targets, 1)
	var wounded_allies: Array[BaseUnit3D] = []
	if is_inside_tree() and get_tree():
		var ally_group := "player_units" if team == 0 else "enemy_units"
		for node in get_tree().get_nodes_in_group(ally_group):
			var ally := node as BaseUnit3D
			if is_instance_valid(ally) and ally.current_state != State.DEAD and not ally.is_on_bench() and ally.current_health < ally.get_max_health():
				wounded_allies.append(ally)

	if wounded_allies.is_empty():
		var self_healed := heal(heal_amount, self)
		if self_healed > 0.0 and is_inside_tree():
			CombatFeedback.create_damage_number(global_position, self_healed, CombatFeedback.DamageType.HEAL)
			CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.5, Color("#4ade80"))
		return

	wounded_allies.sort_custom(func(a: BaseUnit3D, b: BaseUnit3D) -> bool:
		var ratio_a := a.current_health / maxf(a.get_max_health(), 1.0)
		var ratio_b := b.current_health / maxf(b.get_max_health(), 1.0)
		if not is_equal_approx(ratio_a, ratio_b):
			return ratio_a < ratio_b
		return global_position.distance_to(a.global_position) < global_position.distance_to(b.global_position)
	)

	var count := mini(targets_count, wounded_allies.size())
	for i in range(count):
		var ally := wounded_allies[i]
		var healed := ally.heal(heal_amount, self)
		if healed > 0.0 and is_inside_tree():
			CombatFeedback.create_damage_number(ally.global_position, healed, CombatFeedback.DamageType.HEAL)
			CombatFeedback.create_hit_particles(ally.global_position + Vector3.UP * 0.5, Color("#4ade80"))

func flash_damage() -> void:
	if unit_visual:
		unit_visual.flash_damage()

func has_active_shield() -> bool:
	if health_comp:
		return health_comp.has_active_shield()
	return current_shield > 0.0

func add_mana(amount: float) -> void:
	# Centraliza o bloqueio para ataques, golpes recebidos, regeneração e aliados:
	# Unidades com escudo ativo não geram nem recebem mana.
	_setup_components()
	if not stats:
		return
	var is_busy := current_state in [State.IDLE, State.DEAD, State.CASTING]
	var gen_mult := 1.0 + float(synergy_bonuses.get("mana_generation_pct", 0.0))
	mana_comp.current_mana = current_mana
	mana_comp.max_mana = stats.max_mana
	if mana_comp.add_mana(amount, has_active_shield(), is_busy, gen_mult):
		current_mana = mana_comp.current_mana
		update_mana_bar()
	
	if current_mana >= stats.max_mana:
		cast_ability()

func cast_ability() -> void:
	if not stats or not stats.ability_name or current_state in [State.DEAD, State.CASTING] or is_stunned():
		return
	
	# IMPORTANTE: Não usar habilidade se não estiver em combate
	if current_state == State.IDLE and not in_combat:
		return
	
	current_state = State.CASTING
	_face_target()
	unit_visual.play_cast()
	current_mana = 0.0
	update_mana_bar()
	
	ability_cast.emit(stats.ability_name)
	
	# FEEDBACK VISUAL DE HABILIDADE E CANALIZAÇÃO
	CombatFeedback.create_ability_effect(global_position, stats.ability_name, stats.get_tier_color())
	CombatFeedback.create_hit_particles(global_position, stats.get_tier_color())
	
	var channel_dur: float = 0.40
	_play_channel_buildup(channel_dur, stats.get_tier_color())
	
	print("%s começou a canalizar %s!" % [stats.unit_name, stats.ability_name])
	
	var scale_mult := 1.0
	if origin_runtime:
		scale_mult = origin_runtime.on_ability_start()
	current_ability_scale = scale_mult
	
	# Espera o clímax da canalização antes de liberar o efeito/projétil da habilidade
	await get_tree().create_timer(channel_dur * 0.65, false).timeout
	if current_state != State.CASTING:
		return
	
	apply_ability_effect(scale_mult)
	
	# Efeitos de Itens na Conjuração de Habilidade
	if has_item_effect(&"saci_pipe") and not _first_cast_done:
		_first_cast_done = true
		var enemy_grp := "enemy_units" if team == 0 else "player_units"
		for enemy in get_tree().get_nodes_in_group(enemy_grp):
			if enemy is BaseUnit3D and is_instance_valid(enemy) and enemy.current_state != State.DEAD:
				if global_position.distance_to(enemy.global_position) <= 3.0:
					enemy.apply_slow(3.5)
		CombatFeedback.create_status_indicator(self, "FUMAÇA DO SACI!", 1.5)

	if has_item_effect(&"rape_piripiri"):
		var ally_grp := "player_units" if team == 0 else "enemy_units"
		var count := 0
		for ally in get_tree().get_nodes_in_group(ally_grp):
			if ally is BaseUnit3D and is_instance_valid(ally) and ally != self and ally.current_state != State.DEAD:
				if global_position.distance_to(ally.global_position) <= 4.0:
					ally.add_mana(20.0)
					count += 1
					if count >= 2:
						break
		CombatFeedback.create_status_indicator(self, "RAPÉ SAGRADO!", 1.2)

	if has_item_effect(&"lampiao_boitata") and is_instance_valid(current_target) and current_target.current_state != State.DEAD:
		current_target.apply_burn(5.0, self, current_target.get_max_health() * 0.03)
		CombatFeedback.create_status_indicator(current_target, "FOGO DO BOITATÁ", 1.5)

	if has_item_effect(&"loira_mirror"):
		var enemies: Array = get_tree().get_nodes_in_group("enemy_units" if team == 0 else "player_units")
		var sorted_by_dist := enemies.filter(func(e): return is_instance_valid(e) and e.current_state != State.DEAD)
		sorted_by_dist.sort_custom(func(a, b): return global_position.distance_to(a.global_position) > global_position.distance_to(b.global_position))
		for i in range(mini(2, sorted_by_dist.size())):
			var target_e: BaseUnit3D = sorted_by_dist[i]
			target_e.take_damage(150.0, self, UnitStats.DamageType.MAGICAL)
			CombatFeedback.create_damage_number(target_e.global_position, 150.0, CombatFeedback.DamageType.CRITICAL)
	
	if origin_runtime:
		origin_runtime.on_ability_concluded()
	current_ability_scale = 1.0
	
	await get_tree().create_timer(0.65, false).timeout
	# O ataque pode ter retomado (ou a unidade pode ter morrido) enquanto a
	# habilidade aguardava. Só encerra o estado se ainda for esta conjuração.
	if current_state == State.CASTING:
		current_state = State.IDLE
		if in_combat:
			find_target()

func _play_channel_buildup(duration: float = 0.40, color: Color = Color.WHITE) -> void:
	if not model:
		return
	var tw := create_tween()
	tw.set_parallel(true)
	# Leve elevação e retração com pulso de carga
	tw.tween_property(model, "scale", model_base_scale * Vector3(1.28, 1.35, 1.28), duration * 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(model, "position:y", (FLYING_BASE_HEIGHT if is_flying() else 0.0) + 0.35, duration * 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	# Liberação e impacto no retorno
	tw.chain().tween_property(model, "scale", model_base_scale, duration * 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(model, "position:y", (FLYING_BASE_HEIGHT if is_flying() else 0.0), duration * 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	CombatFeedback.create_hit_particles(global_position + Vector3.UP * 0.8, color)
	_trigger_camera_shake(0.2, 0.15)

func apply_ability_effect(scale_multiplier: float = 1.0) -> void:
	if name_label:
		var tween: Tween = create_tween()
		tween.tween_property(name_label, "modulate", Color.YELLOW, 0.2)
		tween.tween_property(name_label, "modulate", Color.WHITE, 0.2)
	if AbilityRegistry.execute_ability(self, scale_multiplier):
		return
	GenericAbilities.execute_ability(self, scale_multiplier)

func _create_araucaria_canopy_element(center_pos: Vector3, radius: float = 1.5, duration: float = 4.0) -> void:
	AbilityRegistry._ensure_registered()
	var ability = AbilityRegistry._abilities.get("araucaria")
	if ability and ability.has_method("_create_canopy_element"):
		ability._create_canopy_element(self, center_pos, radius, duration)

func _create_sumauma_roots_element(center_pos: Vector3, radius: float = 1.4, duration: float = 3.5) -> void:
	AbilityRegistry._ensure_registered()
	var ability = AbilityRegistry._abilities.get("sumauma")
	if ability and ability.has_method("_create_roots_element"):
		ability._create_roots_element(self, center_pos, radius, duration)

func _create_pau_brasil_bloom_element(center_pos: Vector3, radius: float = 1.6, duration: float = 4.0) -> void:
	AbilityRegistry._ensure_registered()
	var ability = AbilityRegistry._abilities.get("pau_brasil")
	if ability and ability.has_method("_create_bloom_element"):
		ability._create_bloom_element(self, center_pos, radius, duration)

func _create_minhocao_crater_element(center_pos: Vector3, radius: float = 1.6, duration: float = 2.5) -> void:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return
	
	var crater := Node3D.new()
	crater.name = "MinhocaoCraterVisual"
	scene_root.add_child(crater)
	crater.global_position = center_pos + Vector3.UP * 0.02
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#78350f")
	mat.emission_enabled = true
	mat.emission = Color("#b45309")
	mat.emission_energy_multiplier = 0.8
	
	var mesh_inst := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius * 0.7
	cyl.height = 0.05
	mesh_inst.mesh = cyl
	mesh_inst.material_override = mat
	crater.add_child(mesh_inst)
	
	var tw := crater.create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(crater.queue_free)

func _create_mboi_guacu_coil_element(target: BaseUnit3D, duration: float = 2.5) -> void:
	AbilityRegistry._ensure_registered()
	var ability = AbilityRegistry._abilities.get("mboi_guacu")
	if ability and ability.has_method("_create_coil_element"):
		ability._create_coil_element(target, duration)

func _execute_swoop_advance_and_return(target_pos: Vector3, trail_color: Color, _action_label: String, on_apex_hit: Callable = Callable()) -> void:
	if not model:
		if on_apex_hit.is_valid():
			on_apex_hit.call()
		return
	_is_swooping = true
	var origin_global: Vector3 = global_position
	var to_target: Vector3 = target_pos - origin_global
	to_target.y = 0.0
	var dist: float = to_target.length()
	var advance_dir: Vector3 = to_target.normalized() if dist > 0.001 else Vector3.FORWARD
	var attack_spot_global: Vector3 = origin_global + advance_dir * maxf(dist - 0.7, 0.0)
	
	if dist > 0.001:
		rotation.y = atan2(advance_dir.x, advance_dir.z)
	
	var tw: Tween = create_tween()
	tw.tween_method(func(prog: float) -> void:
		if is_instance_valid(self) and current_state != State.DEAD:
			global_position = origin_global.lerp(attack_spot_global, prog)
			if model:
				model.position.y = (FLYING_BASE_HEIGHT if is_flying() else 0.0) + sin(prog * PI) * 0.4
	, 0.0, 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	tw.tween_callback(func() -> void:
		if is_instance_valid(self):
			CombatFeedback.create_hit_particles(attack_spot_global + Vector3.UP * 0.5, trail_color)
			if model:
				var strike_tw := create_tween()
				strike_tw.tween_property(model, "rotation:x", 0.4, 0.06)
				strike_tw.tween_property(model, "rotation:x", 0.0, 0.06)
		if on_apex_hit.is_valid():
			on_apex_hit.call()
	)
	tw.tween_interval(0.12)
	
	tw.tween_method(func(prog: float) -> void:
		if is_instance_valid(self) and current_state != State.DEAD:
			global_position = attack_spot_global.lerp(origin_global, prog)
			if model:
				model.position.y = (FLYING_BASE_HEIGHT if is_flying() else 0.0) + sin(prog * PI) * 0.35
	, 0.0, 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	tw.tween_callback(func() -> void:
		if is_instance_valid(self):
			global_position = origin_global
			_is_swooping = false
			if is_flying() and model:
				model.position.y = FLYING_BASE_HEIGHT
	)

func _get_combat_board() -> Board3D:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if scene_root:
		return scene_root.get_node_or_null("board") as Board3D
	return null

func apply_burn(duration: float, source: BaseUnit3D, damage_per_tick: float) -> void:
	if current_state == State.DEAD or duration <= 0.0 or damage_per_tick <= 0.0:
		return
	_burn_generation += 1
	var generation := _burn_generation
	_burn_expires_at_msec = BattleClock.now_msec() + int(duration * 1000.0)
	CombatFeedback.create_status_indicator(self, "QUEIMADO", duration)
	_run_burn_ticks(generation, duration, source, damage_per_tick)

func _run_burn_ticks(generation: int, duration: float, source: BaseUnit3D, damage_per_tick: float) -> void:
	var elapsed := 0.0
	while elapsed < duration and current_state != State.DEAD:
		await get_tree().create_timer(0.5, false).timeout
		if generation != _burn_generation or current_state == State.DEAD:
			return
		elapsed += 0.5
		take_damage(damage_per_tick, source if is_instance_valid(source) else null, UnitStats.DamageType.MAGICAL)

func die() -> void:
	if current_state == State.DEAD:
		return
	in_combat = false
	_was_stunned = false
	stunned_until_msec = 0
	current_state = State.DEAD
	current_health = 0
	clear_shield()
	consecutive_attacks = 0
	if attack_timer:
		attack_timer.stop()
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	if navigation_agent:
		navigation_agent.set_velocity(Vector3.ZERO)
		navigation_agent.avoidance_enabled = false
	set_hovered(false)
	if ui_sprite:
		ui_sprite.hide()
	_death_generation += 1
	var generation := _death_generation
	var death_duration: float = unit_visual.play_death() if unit_visual else 0.0
	current_target = null
	if is_inside_tree():
		for unit in get_tree().get_nodes_in_group("units"):
			if unit is BaseUnit3D and unit.current_target == self:
				unit.current_target = null
	# A morte lógica é imediata; apenas o corpo espera a animação terminar.
	died.emit(self)
	if is_inside_tree():
		var ally_group := "player_units" if team == 0 else "enemy_units"
		for ally in get_tree().get_nodes_in_group(ally_group):
			if ally is BaseUnit3D and is_instance_valid(ally) and ally != self and ally.current_state != State.DEAD:
				if ally.has_method("notify_ally_death"):
					ally.notify_ally_death()
	if death_duration > 0.0 and is_inside_tree():
		await get_tree().create_timer(death_duration, false).timeout
	# O fim da rodada pode reviver a unidade antes de a animação terminar.
	if generation != _death_generation or current_state != State.DEAD:
		return
	if team == 0:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED
	else:
		queue_free()

func notify_ally_death() -> void:
	if has_item_effect(&"bonfim_ribbon") and _bonfim_nodes_remaining > 0:
		_bonfim_nodes_remaining -= 1
		_bonfim_damage_bonus += 0.15
		set_shield_with_source(current_shield + 160.0, ShieldSource.SELF)
		CombatFeedback.create_status_indicator(self, "NÓ DO BONFIM!", 1.2)

func revive_at_position(world_pos: Vector3) -> void:
	_death_generation += 1
	use_navigation = false
	_detour_dir = Vector3.ZERO
	_detour_timer = 0.0
	in_combat = false
	_was_stunned = false
	current_state = State.IDLE
	if attack_timer:
		attack_timer.stop()
	current_health = get_max_health()
	current_mana = stats.starting_mana + get_item_stat_bonus("starting_mana")
	clear_shield()
	current_target = null
	velocity = Vector3.ZERO
	stunned_until_msec = 0
	immune_until_msec = 0
	reflect_until_msec = 0
	reflect_pct = 0.0
	armor_shred_until_msec = 0
	armor_shred_amount = 0.0
	
	visible = true
	is_hovered = false
	process_mode = Node.PROCESS_MODE_INHERIT
	collision_layer = 1
	collision_mask = 1
	global_position = world_pos
	combat_ground_height = world_pos.y
	if ui_sprite:
		ui_sprite.show()
	if unit_visual:
		unit_visual.reset_pose()
	
	if model:
		model.scale = model_base_scale
		if is_flying():
			model.position.y = FLYING_BASE_HEIGHT
		else:
			model.position.y = 0.0
	
	update_health_bar()
	update_mana_bar()

func update_health_bar() -> void:
	update_stats_display() # Atualizar labels ao invés de barras
	health_changed.emit(current_health, get_max_health())

func update_mana_bar() -> void:
	update_stats_display() # Atualizar labels ao invés de barras
	mana_changed.emit(current_mana, stats.max_mana)

func _process(delta: float) -> void:
	_update_aura_indicator()
	if unit_visual:
		unit_visual.update_locomotion(current_state == State.MOVING, get_movement_speed(), current_state == State.IDLE)
	if is_flying() and model and current_state != State.DEAD and not _is_swooping:
		var hover: float = sin(float(Time.get_ticks_msec()) * 0.003 + float(get_instance_id() % 100)) * 0.07
		model.position.y = FLYING_BASE_HEIGHT + hover
		if has_active_shield() and hud_comp:
			hud_comp.update_shield_sphere_visual()
	if current_state == State.DEAD or current_state == State.IDLE:
		_health_regen_accumulator = 0.0
		return
	_prune_expired_buffs()
	if origin_runtime:
		origin_runtime.on_tick(delta)
	if stats.mana_per_second > 0.0:
		add_mana(stats.mana_per_second * delta)
	var regen_per_second := stats.health_regen + float(synergy_bonuses.get("health_regen", 0.0))
	# Aura de regeneração do Suporte: fração da vida máxima por segundo.
	regen_per_second += get_support_aura_value("regen", false) * get_max_health()
	if regen_per_second > 0.0:
		_health_regen_accumulator += delta
		if _health_regen_accumulator >= 1.0:
			var elapsed_seconds := floorf(_health_regen_accumulator)
			_health_regen_accumulator -= elapsed_seconds
			heal(regen_per_second * elapsed_seconds, self)

# ==============================================================================
# ELEMENTOS VISUAIS DE COMBATE NO TABULEIRO
# ==============================================================================

func _create_mandacaru_thorn_element(center_pos: Vector3, duration: float) -> void:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return
	
	var fence := Node3D.new()
	fence.name = "MandacaruThornFenceVisual"
	scene_root.add_child(fence)
	fence.global_position = center_pos
	
	var cactus_mat := StandardMaterial3D.new()
	cactus_mat.albedo_color = Color("#15803d")
	cactus_mat.emission_enabled = true
	cactus_mat.emission = Color("#22c55e")
	cactus_mat.emission_energy_multiplier = 0.8
	
	for i in 6:
		var angle := (TAU / 6.0) * float(i)
		var column := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.14
		cyl.height = 0.95
		column.mesh = cyl
		column.material_override = cactus_mat
		column.position = Vector3(cos(angle) * 0.9, -0.6, sin(angle) * 0.9)
		fence.add_child(column)
		
		var tw_col := fence.create_tween()
		tw_col.tween_property(column, "position:y", 0.45, 0.22 + float(i) * 0.03).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_col.tween_interval(maxf(duration - 0.5, 0.1))
		tw_col.tween_property(column, "position:y", -0.7, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	var lifetime := fence.create_tween()
	lifetime.tween_interval(duration + 0.3)
	lifetime.tween_callback(fence.queue_free)

func _create_water_sanctuary_element(center_pos: Vector3, duration: float) -> void:
	var scene_root: Node = get_tree().current_scene if get_tree() else null
	if not scene_root:
		scene_root = get_parent()
	if not scene_root:
		return
	
	var pad := Node3D.new()
	pad.name = "WaterLilySanctuaryVisual"
	scene_root.add_child(pad)
	pad.global_position = center_pos + Vector3.UP * 0.03
	
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color("#15803d")
	leaf_mat.emission_enabled = true
	leaf_mat.emission = Color("#22c55e")
	leaf_mat.emission_energy_multiplier = 0.6
	
	var water_mat := StandardMaterial3D.new()
	water_mat.albedo_color = Color(0.1, 0.6, 0.9, 0.7)
	water_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water_mat.emission_enabled = true
	water_mat.emission = Color("#06b6d4")
	water_mat.emission_energy_multiplier = 1.2
	water_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	var leaf_mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.85
	cyl.bottom_radius = 0.85
	cyl.height = 0.04
	leaf_mesh.mesh = cyl
	leaf_mesh.material_override = leaf_mat
	pad.add_child(leaf_mesh)
	
	var water_ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.95
	torus.outer_radius = 1.15
	water_ring.mesh = torus
	water_ring.material_override = water_mat
	pad.add_child(water_ring)
	
	pad.scale = Vector3(0.01, 0.01, 0.01)
	var tw := pad.create_tween()
	tw.tween_property(pad, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(maxf(duration - 0.4, 0.1))
	tw.tween_property(pad, "scale", Vector3(0.01, 0.01, 0.01), 0.25).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(pad.queue_free)
