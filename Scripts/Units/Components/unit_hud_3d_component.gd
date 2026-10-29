class_name UnitHUD3DComponent
extends Node3D

## Componente de Interface e Feedback Visual 3D da Unidade (Barras TFT, Aura, Escudo 3D)

var unit: BaseUnit3D

# Elementos 3D Billboard
var ui_viewport: SubViewport = null
var ui_sprite: Sprite3D = null
var nameplate_container: PanelContainer = null
var name_label: Label = null
var hp_label: Label = null
var mana_label: Label = null
var tier_label: Label = null
var star_container: HBoxContainer = null
var bars_container: Control = null
var health_bar_3d: ProgressBar = null
var mana_bar_3d: ProgressBar = null
var shield_bar_3d: ProgressBar = null
var hp_ticks: Control = null

# Escudo esférico 3D
var shield_sphere: MeshInstance3D = null
var shield_sphere_tween: Tween = null

# Aura de Hexágonos
var aura_indicator: Node3D = null
var aura_center: Vector2i = Vector2i(-1, -1)
var aura_radius: int = -1

class HealthBarTicks extends Control:
	var max_hp: float = 500.0

	func _draw() -> void:
		if max_hp <= 0.0 or size.x <= 0.0:
			return
		var interval := 250.0
		var count := int(max_hp / interval)
		if count <= 1 or count > 24:
			return
		for i in range(1, count):
			var x := (float(i) * interval / max_hp) * size.x
			draw_line(Vector2(x, 1.0), Vector2(x, size.y - 1.0), Color(0.04, 0.06, 0.08, 0.9), 2.0)

func setup(p_unit: BaseUnit3D) -> void:
	unit = p_unit

func setup_stats_display() -> void:
	if not unit:
		return
	if is_instance_valid(ui_viewport):
		ui_viewport.queue_free()
	if is_instance_valid(ui_sprite):
		ui_sprite.queue_free()

	ui_viewport = SubViewport.new()
	ui_viewport.name = "UnitLabelViewport"
	ui_viewport.size = Vector2i(960, 320)
	ui_viewport.transparent_bg = true
	ui_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(ui_viewport)

	var root := Control.new()
	root.name = "UnitLabelRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_viewport.add_child(root)

	var nameplate_center := BoxContainer.new()
	nameplate_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	nameplate_center.alignment = BoxContainer.ALIGNMENT_CENTER
	nameplate_center.offset_top = 8
	nameplate_center.offset_bottom = 124
	nameplate_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(nameplate_center)

	nameplate_container = PanelContainer.new()
	nameplate_container.name = "NameplateContainer"
	nameplate_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_container.visible = false

	var nameplate_style := StyleBoxFlat.new()
	nameplate_style.bg_color = Color(0.04, 0.07, 0.12, 0.96)
	nameplate_style.border_color = Color("#f59e0b") if unit.team == 0 else Color("#ef4444")
	nameplate_style.set_border_width_all(3)
	nameplate_style.set_corner_radius_all(14)
	nameplate_style.content_margin_left = 24.0
	nameplate_style.content_margin_right = 24.0
	nameplate_style.content_margin_top = 8.0
	nameplate_style.content_margin_bottom = 8.0
	nameplate_style.shadow_color = Color(0, 0, 0, 0.85)
	nameplate_style.shadow_size = 12
	nameplate_container.add_theme_stylebox_override("panel", nameplate_style)
	nameplate_center.add_child(nameplate_container)

	var nameplate_row := HBoxContainer.new()
	nameplate_row.name = "NameplateRow"
	nameplate_row.alignment = BoxContainer.ALIGNMENT_CENTER
	nameplate_row.add_theme_constant_override("separation", 16)
	nameplate_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_container.add_child(nameplate_row)

	tier_label = Label.new()
	tier_label.name = "TierBadge"
	tier_label.text = "T%d" % unit.stats.tier
	tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tier_label.add_theme_font_size_override("font_size", 46)
	tier_label.add_theme_color_override("font_color", unit.stats.get_tier_color())
	tier_label.add_theme_color_override("font_outline_color", Color("#05080c"))
	tier_label.add_theme_constant_override("outline_size", 8)
	tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_row.add_child(tier_label)

	name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = unit.stats.unit_name
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 54)
	name_label.add_theme_color_override("font_color", Color("#ffffff") if unit.team == 0 else Color("#ffe4e0"))
	name_label.add_theme_color_override("font_outline_color", Color("#05080c"))
	name_label.add_theme_constant_override("outline_size", 9)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_row.add_child(name_label)

	hp_label = Label.new()
	hp_label.name = "HPLabel"
	hp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_label.add_theme_font_size_override("font_size", 44)
	hp_label.add_theme_color_override("font_color", Color("#a5f3fc") if unit.team == 0 else Color("#fca5a5"))
	hp_label.add_theme_color_override("font_outline_color", Color("#05080c"))
	hp_label.add_theme_constant_override("outline_size", 7)
	hp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	nameplate_row.add_child(hp_label)

	mana_label = Label.new()
	mana_label.name = "ManaLabel"
	mana_label.visible = false
	root.add_child(mana_label)

	var star_center := BoxContainer.new()
	star_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	star_center.alignment = BoxContainer.ALIGNMENT_CENTER
	star_center.offset_top = 132
	star_center.offset_bottom = 184
	star_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(star_center)

	star_container = HBoxContainer.new()
	star_container.name = "StarContainer"
	star_container.alignment = BoxContainer.ALIGNMENT_CENTER
	star_container.add_theme_constant_override("separation", 8)
	star_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	star_center.add_child(star_container)
	update_star_display()

	var bars_center := BoxContainer.new()
	bars_center.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	bars_center.alignment = BoxContainer.ALIGNMENT_CENTER
	bars_center.offset_top = 192
	bars_center.offset_bottom = 276
	bars_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bars_center)

	bars_container = Control.new()
	bars_container.name = "BarsContainer"
	bars_container.custom_minimum_size = Vector2(380, 68)
	bars_container.size = Vector2(380, 68)
	bars_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_center.add_child(bars_container)

	health_bar_3d = ProgressBar.new()
	health_bar_3d.name = "HealthBar"
	health_bar_3d.position = Vector2(0, 0)
	health_bar_3d.size = Vector2(380, 30)
	health_bar_3d.show_percentage = false
	health_bar_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color("#070d14")
	hp_bg.set_border_width_all(3)
	hp_bg.border_color = Color("#000000")
	hp_bg.set_corner_radius_all(4)

	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color("#22c55e") if unit.team == 0 else Color("#ef4444")
	hp_fill.set_corner_radius_all(4)

	health_bar_3d.add_theme_stylebox_override("background", hp_bg)
	health_bar_3d.add_theme_stylebox_override("fill", hp_fill)
	bars_container.add_child(health_bar_3d)

	hp_ticks = HealthBarTicks.new()
	hp_ticks.name = "HPTicks"
	hp_ticks.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hp_ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health_bar_3d.add_child(hp_ticks)

	shield_bar_3d = ProgressBar.new()
	shield_bar_3d.name = "ShieldBar"
	shield_bar_3d.position = Vector2(0, 0)
	shield_bar_3d.size = Vector2(380, 30)
	shield_bar_3d.show_percentage = false
	shield_bar_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shield_bar_3d.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	var shield_fill := StyleBoxFlat.new()
	shield_fill.bg_color = Color(0.22, 0.74, 0.97, 0.85)
	shield_fill.set_corner_radius_all(4)
	shield_bar_3d.add_theme_stylebox_override("fill", shield_fill)
	shield_bar_3d.visible = false
	bars_container.add_child(shield_bar_3d)

	mana_bar_3d = ProgressBar.new()
	mana_bar_3d.name = "ManaBar"
	mana_bar_3d.position = Vector2(0, 36)
	mana_bar_3d.size = Vector2(380, 16)
	mana_bar_3d.show_percentage = false
	mana_bar_3d.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var mp_bg := StyleBoxFlat.new()
	mp_bg.bg_color = Color("#050b12")
	mp_bg.set_border_width_all(2)
	mp_bg.border_color = Color("#000000")
	mp_bg.set_corner_radius_all(3)

	var mp_fill := StyleBoxFlat.new()
	mp_fill.bg_color = Color("#0ea5e9")
	mp_fill.set_corner_radius_all(3)

	mana_bar_3d.add_theme_stylebox_override("background", mp_bg)
	mana_bar_3d.add_theme_stylebox_override("fill", mp_fill)
	bars_container.add_child(mana_bar_3d)

	ui_sprite = Sprite3D.new()
	ui_sprite.name = "UnitLabelSprite"
	ui_sprite.texture = ui_viewport.get_texture()
	ui_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ui_sprite.no_depth_test = true
	ui_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	ui_sprite.pixel_size = 0.007
	var ui_height: float = 2.7
	if unit.is_flying():
		ui_height += BaseUnit3D.FLYING_BASE_HEIGHT
	ui_sprite.position = Vector3(0, ui_height, 0)
	add_child(ui_sprite)

	health_bar_3d.max_value = unit.get_max_health()
	mana_bar_3d.max_value = unit.stats.max_mana

	unit.health_bar_3d = health_bar_3d
	unit.shield_bar_3d = shield_bar_3d
	unit.mana_bar_3d = mana_bar_3d
	unit.ui_sprite = ui_sprite
	unit.ui_viewport = ui_viewport
	unit.nameplate_container = nameplate_container
	unit.name_label = name_label
	unit.hp_label = hp_label
	unit.mana_label = mana_label
	unit.tier_label = tier_label
	unit.star_container = star_container
	unit.bars_container = bars_container

	update_stats_display()

func update_star_display() -> void:
	if not is_instance_valid(star_container) or not unit:
		return
	for child in star_container.get_children():
		child.queue_free()
	var stars: int = clampi(unit.star_level, 1, 4)
	var star_color: Color
	if stars >= 3:
		star_color = Color("#fbbf24")
	elif stars == 2:
		star_color = Color("#e2e8f0")
	else:
		star_color = Color("#cd7f32")
	for i in range(stars):
		var star_icon := UIAtlasCatalog.create_icon_rect("star", Vector2(40, 40))
		star_icon.modulate = star_color
		star_container.add_child(star_icon)

func update_status_visibility() -> void:
	if not is_instance_valid(ui_sprite) or not unit:
		return
	if unit.current_state == BaseUnit3D.State.DEAD:
		ui_sprite.visible = false
		return

	var show_nameplate: bool = unit.is_hovered or unit.is_synergy_highlighted
	var on_bench: bool = unit.is_on_bench()
	if on_bench:
		if is_instance_valid(bars_container):
			bars_container.visible = false
		if is_instance_valid(star_container):
			star_container.visible = false
		if is_instance_valid(nameplate_container):
			nameplate_container.visible = show_nameplate
		ui_sprite.visible = show_nameplate
	else:
		if is_instance_valid(bars_container):
			bars_container.visible = true
		if is_instance_valid(star_container):
			star_container.visible = true
		if is_instance_valid(nameplate_container):
			nameplate_container.visible = show_nameplate
		ui_sprite.visible = true

func update_stats_display() -> void:
	if not unit or not is_instance_valid(health_bar_3d) or not is_instance_valid(mana_bar_3d):
		return
	var max_hp := maxf(unit.get_max_health(), 1.0)
	var hp_percent := unit.current_health / max_hp
	var max_mp := maxf(unit.stats.max_mana, 1.0)
	var mana_percent := unit.current_mana / max_mp

	if is_instance_valid(hp_label):
		if unit.has_active_shield():
			hp_label.text = "%d / %d (+%d ESC)" % [int(unit.current_health), int(max_hp), ceili(unit.current_shield)]
		else:
			hp_label.text = "%d / %d" % [int(unit.current_health), int(max_hp)]
	if is_instance_valid(mana_label):
		if unit.has_active_shield():
			mana_label.text = "ESC %d  |  MP %d%%" % [ceili(unit.current_shield), int(mana_percent * 100.0)]
		else:
			mana_label.text = "%d / %d" % [int(unit.current_mana), int(max_mp)]

	if is_instance_valid(shield_bar_3d):
		shield_bar_3d.visible = unit.has_active_shield()
		shield_bar_3d.max_value = max_hp
		shield_bar_3d.value = unit.current_shield

	health_bar_3d.max_value = max_hp
	health_bar_3d.value = unit.current_health
	mana_bar_3d.max_value = max_mp
	mana_bar_3d.value = unit.current_mana

	if is_instance_valid(hp_ticks):
		hp_ticks.max_hp = max_hp
		hp_ticks.queue_redraw()

	var health_fill := health_bar_3d.get_theme_stylebox("fill") as StyleBoxFlat
	if is_instance_valid(health_fill):
		if unit.team == 0:
			if hp_percent > 0.6:
				health_fill.bg_color = Color("#22c55e")
			elif hp_percent > 0.3:
				health_fill.bg_color = Color("#facc15")
			else:
				health_fill.bg_color = Color("#ef4444")
		else:
			health_fill.bg_color = Color("#ef4444")

	var mana_fill := mana_bar_3d.get_theme_stylebox("fill") as StyleBoxFlat
	if is_instance_valid(mana_fill):
		if mana_percent >= 1.0:
			mana_fill.bg_color = Color("#38e1ff")
		else:
			mana_fill.bg_color = Color("#0ea5e9")

	update_status_visibility()

const SHIELD_COLORS := {
	0: Color(1.0, 0.82, 0.22), # CLASS
	1: Color(0.2, 0.82, 1.0),  # SELF
	2: Color(0.25, 0.95, 0.55), # PLAYER
	3: Color(0.95, 0.25, 0.35), # ENEMY
}

func setup_shield_sphere() -> void:
	if is_instance_valid(shield_sphere):
		shield_sphere.queue_free()
		shield_sphere = null
	
	shield_sphere = MeshInstance3D.new()
	shield_sphere.name = "ShieldSphereVisual"
	
	var sphere := SphereMesh.new()
	sphere.radius = 0.85
	sphere.height = 1.7
	sphere.radial_segments = 24
	sphere.rings = 16
	shield_sphere.mesh = sphere
	shield_sphere.position = Vector3(0.0, 0.8, 0.0)
	
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.1
	mat.metallic = 0.05
	mat.rim_enabled = true
	mat.rim = 0.95
	mat.rim_tint = 0.8
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.65
	
	var base_col: Color = SHIELD_COLORS.get(int(unit.current_shield_source), Color(0.2, 0.82, 1.0))
	mat.albedo_color = Color(base_col.r, base_col.g, base_col.b, 0.28)
	mat.emission = base_col
	shield_sphere.material_override = mat
	
	shield_sphere.visible = false
	shield_sphere.scale = Vector3.ZERO
	add_child(shield_sphere)
	unit.shield_sphere = shield_sphere

func clear_shield_visual() -> void:
	if shield_sphere_tween and shield_sphere_tween.is_running():
		shield_sphere_tween.kill()
	if is_instance_valid(shield_sphere):
		shield_sphere.scale = Vector3.ZERO
		shield_sphere.visible = false

func update_shield_sphere_visual() -> void:
	if not unit:
		return
	if not is_instance_valid(shield_sphere):
		setup_shield_sphere()
	if not is_instance_valid(shield_sphere):
		return
	
	var has_shield := unit.has_active_shield() and unit.current_state != BaseUnit3D.State.DEAD and unit.visible
	
	if has_shield:
		var effective_source: int = int(unit.current_shield_source)
		if unit.team == 1 and effective_source != 0:
			effective_source = 3 # ENEMY
		
		var col: Color = SHIELD_COLORS.get(effective_source, Color(0.2, 0.82, 1.0))
		var mat: StandardMaterial3D = shield_sphere.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(col.r, col.g, col.b, 0.28)
			mat.emission = col
		
		if not shield_sphere.visible or shield_sphere.scale.length_squared() < 0.1:
			shield_sphere.visible = true
			if shield_sphere_tween and shield_sphere_tween.is_running():
				shield_sphere_tween.kill()
			shield_sphere_tween = create_tween()
			shield_sphere_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			shield_sphere_tween.tween_property(shield_sphere, "scale", Vector3.ONE, 0.25)
	else:
		if is_instance_valid(shield_sphere):
			if not shield_sphere.visible or shield_sphere.scale.length_squared() < 0.05:
				shield_sphere.scale = Vector3.ZERO
				shield_sphere.visible = false
			elif shield_sphere.visible:
				if shield_sphere_tween and shield_sphere_tween.is_running():
					shield_sphere_tween.kill()
				shield_sphere_tween = create_tween()
				shield_sphere_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				shield_sphere_tween.tween_property(shield_sphere, "scale", Vector3.ZERO, 0.15)
				shield_sphere_tween.tween_callback(func():
					if is_instance_valid(shield_sphere) and not unit.has_active_shield():
						shield_sphere.visible = false
						shield_sphere.scale = Vector3.ZERO
				)

func setup_aura_indicator() -> void:
	if not unit:
		return
	if is_instance_valid(aura_indicator):
		aura_indicator.queue_free()
		aura_indicator = null
	aura_center = Vector2i(-1, -1)
	aura_radius = -1
	if not unit.stats or unit.stats.passive_aura_power <= 0.0 or unit.stats.passive_aura_range <= 0:
		return
	aura_indicator = Node3D.new()
	aura_indicator.name = "HexPowerAura"
	aura_indicator.top_level = true
	aura_indicator.visible = false
	add_child(aura_indicator)

func update_aura_indicator() -> void:
	if not is_instance_valid(aura_indicator) or not unit:
		return
	aura_indicator.visible = unit.visible and unit.current_state != BaseUnit3D.State.DEAD
	if not aura_indicator.visible:
		return
	var board: Node = unit._get_combat_board()
	if not board:
		aura_indicator.hide()
		return
	var center: Vector2i = board.get_grid_position(board.to_local(unit.global_position))
	if not board.get_cell(center):
		aura_indicator.hide()
		return
	aura_indicator.global_transform = Transform3D.IDENTITY
	if center == aura_center and aura_radius == unit.stats.passive_aura_range:
		return
	aura_center = center
	aura_radius = unit.stats.passive_aura_range
	for child in aura_indicator.get_children():
		aura_indicator.remove_child(child)
		child.queue_free()
	var outline := _make_aura_hex_outline(board.get_hex_radius() * 0.9)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.35, 0.9, 0.55, 0.5) if unit.team == 0 else Color(1.0, 0.4, 0.45, 0.5)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for cell in board.get_cells_in_hex_radius(center, unit.stats.passive_aura_range):
		var marker := MeshInstance3D.new()
		marker.mesh = outline
		marker.material_override = material
		marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		aura_indicator.add_child(marker)
		marker.position = board.get_cell_world_position(cell) + Vector3.UP * 0.11

func _make_aura_hex_outline(radius: float) -> ImmediateMesh:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var inner_radius := maxf(0.0, radius - 0.04)
	for side in 6:
		var a := TAU * float(side) / 6.0
		var b := TAU * float(side + 1) / 6.0
		var direction_a := Vector3(sin(a), 0.0, cos(a))
		var direction_b := Vector3(sin(b), 0.0, cos(b))
		for vertex in [direction_a * radius, direction_a * inner_radius, direction_b * radius,
				direction_b * radius, direction_a * inner_radius, direction_b * inner_radius]:
			mesh.surface_add_vertex(vertex)
	mesh.surface_end()
	return mesh

func setup_team_indicator() -> void:
	if not unit or unit.team != 1:
		return
	var indicator := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.45
	torus.outer_radius = 0.5
	torus.ring_segments = 32
	
	indicator.mesh = torus
	indicator.position.y = 0.01
	indicator.scale = Vector3(1, 0.1, 1)
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("#ff4b5f")
	mat.emission_enabled = true
	mat.emission = Color("#ff334f")
	mat.emission_energy_multiplier = 2.0
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	indicator.material_override = mat
	add_child(indicator)
