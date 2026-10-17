extends Node3D
## Apresentação compartilhada das unidades; o combate continua em BaseUnit3D.

const IDLE := &"Idle"
const WALK := &"Walk"
const ATTACK := &"Punch_Jab"
const RANGED_ATTACK := &"Spell_Simple_Shoot"
const CAST := &"Spell_Simple_Shoot"
const DEATH := &"Death01"
const STAR_SHADER: Shader = preload("res://Assets/Shaders/star_evolution.gdshader")

var animation_player: AnimationPlayer
var _meshes: Array[MeshInstance3D] = []
var _body_materials: Array[StandardMaterial3D] = []
var _team_color := Color.WHITE
var _action: StringName = &""
var _moving := false
var _movement_speed := 1.0
var _dead := false
var _flash_tween: Tween
var _upgrade_tween: Tween


func configure(color: Color) -> void:
	_team_color = color
	animation_player = find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert(animation_player != null, "UAL1_Standard precisa de AnimationPlayer")
	animation_player.animation_finished.connect(_on_animation_finished)
	# As animações são compartilhadas entre instâncias; os loops são definidos
	# na importação. Somente materiais que recebem efeitos são duplicados.
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		_meshes.append(mesh)
		for surface in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(surface) as StandardMaterial3D
			if original and original.resource_name == "M_Main":
				var material := original.duplicate() as StandardMaterial3D
				material.albedo_color = color
				mesh.set_surface_override_material(surface, material)
				_body_materials.append(material)


func _ready() -> void:
	if not animation_player:
		configure(Color.WHITE)
	reset_pose()


func reset_pose() -> void:
	_dead = false
	_action = &""
	_moving = false
	animation_player.stop()
	_play(IDLE)
	animation_player.advance(0.0)


func update_locomotion(moving: bool, movement_speed: float, interrupt_action: bool = false) -> void:
	_moving = moving
	_movement_speed = clampf(movement_speed / 2.0, 0.4, 2.0)
	if _dead:
		return
	if interrupt_action or moving:
		_action = &""
	if _action == &"":
		_play(WALK if moving else IDLE, _movement_speed if moving else 1.0)


func play_attack(ranged: bool, interval: float) -> void:
	if _dead:
		return
	_action = RANGED_ATTACK if ranged else ATTACK
	# Completa o gesto dentro do intervalo, sem alterar o dano ou o timer.
	var duration := animation_player.get_animation(_action).length
	_play(_action, duration / maxf(minf(interval * 0.85, duration), 0.05), true)


func play_cast() -> void:
	if _dead:
		return
	_action = CAST
	_play(CAST, animation_player.get_animation(CAST).length / 0.5, true)


func play_death() -> float:
	_dead = true
	_action = DEATH
	_play(DEATH, 1.0, true)
	return animation_player.get_animation(DEATH).length


func _play(animation: StringName, speed: float = 1.0, restart: bool = false) -> void:
	animation_player.speed_scale = speed
	if restart or animation_player.current_animation != animation:
		if restart:
			animation_player.stop()
		animation_player.play(animation, 0.12)


func _on_animation_finished(animation: StringName) -> void:
	if _dead or animation != _action:
		return
	_action = &""
	update_locomotion(_moving, _movement_speed * 2.0)


func flash_damage() -> void:
	if _flash_tween and _flash_tween.is_running():
		_flash_tween.kill()
	for material in _body_materials:
		material.albedo_color = _team_color.lerp(Color.RED, 0.8)
	_flash_tween = create_tween().set_parallel(true)
	for material in _body_materials:
		_flash_tween.tween_property(material, "albedo_color", _team_color, 0.15)


func flash_upgrade(burst_color: Color) -> void:
	if _upgrade_tween and _upgrade_tween.is_running():
		_upgrade_tween.kill()
	var material := ShaderMaterial.new()
	material.shader = STAR_SHADER
	material.set_shader_parameter("base_color", _team_color)
	material.set_shader_parameter("burst_color", burst_color)
	material.set_shader_parameter("flash_strength", 0.0)
	for mesh in _meshes:
		mesh.material_overlay = material
	_upgrade_tween = create_tween()
	_upgrade_tween.tween_property(material, "shader_parameter/flash_strength", 1.0, 0.16)
	_upgrade_tween.tween_property(material, "shader_parameter/flash_strength", 0.0, 0.72)
	_upgrade_tween.tween_callback(func() -> void:
		for mesh in _meshes:
			mesh.material_overlay = null
	)
