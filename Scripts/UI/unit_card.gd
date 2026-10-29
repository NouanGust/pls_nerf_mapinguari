class_name UnitCard
extends PanelContainer

const UIStyle = preload("res://Scripts/UI/ui_style.gd")
const UPGRADE_HINT_SHADER: Shader = preload("res://Assets/Shaders/shop_upgrade_hint.gdshader")
const OWNED_HINT_SHADER: Shader = preload("res://Assets/Shaders/shop_owned_hint.gdshader")

signal card_clicked(slot_index: int)
signal drag_started(unit_stats: UnitStats, slot_index: int)
signal hover_started(stats: UnitStats, pos: Vector2)
signal hover_ended()

var unit_stats: UnitStats
var slot_index: int = 0
var is_sold: bool = false
var is_hovered: bool = false
var pointer_down: bool = false
var drag_was_requested: bool = false
var press_position: Vector2 = Vector2.ZERO

var upgrade_glow: ColorRect
var upgrade_material: ShaderMaterial
var owned_material: ShaderMaterial
var purchase_upgrade_star: int = 0
var is_unit_owned: bool = false
var base_tooltip_text: String = ""

# Referências dos nós da interface
@onready var icon_rect: TextureRect = $IconRect if has_node("IconRect") else $VBox/IconRect
@onready var name_label: Label = $Margin/CardLayout/BottomRow/NameLabel if has_node("Margin/CardLayout/BottomRow/NameLabel") else $VBox/NameLabel
@onready var tier_badge: Label = $Margin/CardLayout/TopRow/TierBadge if has_node("Margin/CardLayout/TopRow/TierBadge") else $VBox/TierBadge
@onready var traits_container: VBoxContainer = $Margin/CardLayout/TopRow/TraitsContainer if has_node("Margin/CardLayout/TopRow/TraitsContainer") else get_node_or_null("VBox/TraitsContainer")
@onready var origin_label: Label = $Margin/CardLayout/TopRow/TraitsContainer/OriginLabel if has_node("Margin/CardLayout/TopRow/TraitsContainer/OriginLabel") else get_node_or_null("VBox/TraitsContainer/OriginLabel")
@onready var class_label: Label = $Margin/CardLayout/TopRow/TraitsContainer/ClassLabel if has_node("Margin/CardLayout/TopRow/TraitsContainer/ClassLabel") else get_node_or_null("VBox/TraitsContainer/ClassLabel")
@onready var cost_label: Label = $Margin/CardLayout/BottomRow/CostContainer/CostLabel if has_node("Margin/CardLayout/BottomRow/CostContainer/CostLabel") else $VBox/CostLabel
@onready var sold_overlay: ColorRect = $SoldOutOverlay if has_node("SoldOutOverlay") else null

# Compatibilidade legada
@onready var hp_icon: Label = get_node_or_null("LegacyCompat/VBox/StatsContainer/HpIcon")
@onready var attack_icon: Label = get_node_or_null("LegacyCompat/VBox/StatsContainer/AttackIcon")
@onready var vbox: Control = get_node_or_null("Margin/CardLayout") if has_node("Margin/CardLayout") else get_node_or_null("VBox")

var default_style: StyleBoxFlat
var hover_style: StyleBoxFlat
var current_tier: int = 1

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	setup_styles()
	setup_signals()
	_setup_upgrade_glow()
	fit_card(136.0)

func fit_card(width: float) -> void:
	custom_minimum_size = Vector2(width, 172.0)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_FILL
	if name_label:
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.clip_text = true
	if origin_label:
		origin_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		origin_label.clip_text = true
	if class_label:
		class_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		class_label.clip_text = true

func _setup_upgrade_glow() -> void:
	upgrade_material = ShaderMaterial.new()
	upgrade_material.shader = UPGRADE_HINT_SHADER
	owned_material = ShaderMaterial.new()
	owned_material.shader = OWNED_HINT_SHADER
	upgrade_glow = ColorRect.new()
	upgrade_glow.name = "UpgradeGlow"
	upgrade_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	upgrade_glow.material = upgrade_material
	upgrade_glow.z_index = 2
	upgrade_glow.set_anchors_preset(Control.PRESET_FULL_RECT)
	upgrade_glow.hide()
	add_child(upgrade_glow)
	resized.connect(_resize_upgrade_glow)

func _resize_upgrade_glow() -> void:
	if upgrade_material:
		upgrade_material.set_shader_parameter("card_size", size)
	if owned_material:
		owned_material.set_shader_parameter("card_size", size)

func setup_styles() -> void:
	default_style = UIStyle.make_card_style(current_tier, false)
	hover_style = UIStyle.make_card_style(current_tier, true)
	add_theme_stylebox_override("panel", default_style)

func setup_signals() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func set_unit(stats: UnitStats) -> void:
	unit_stats = stats
	is_sold = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	if not unit_stats:
		clear()
		return
	
	current_tier = unit_stats.tier
	update_tier_style()
	
	# Nome e Custo
	if name_label:
		name_label.text = unit_stats.unit_name
	if cost_label:
		cost_label.text = "%d" % unit_stats.cost
	
	# Tier Badge
	if tier_badge:
		tier_badge.text = "T%d" % unit_stats.tier
		tier_badge.add_theme_color_override("font_color", UIStyle.TIER_COLORS.get(unit_stats.tier, Color.WHITE))
	
	# Origens e Classes (mostra todas as classes e origens)
	_update_traits_display(unit_stats.origins, unit_stats.classes)
	
	# Stats legados
	if hp_icon:
		hp_icon.text = "%d" % int(unit_stats.max_health)
	if attack_icon:
		attack_icon.text = "%d" % int(unit_stats.attack_damage)
	
	# Retrato da unidade
	if icon_rect:
		if unit_stats.icon:
			icon_rect.texture = unit_stats.icon
		else:
			create_tier_placeholder()
	
	# Tooltip padrao desabilitado: usamos exclusivamente o StatsTooltip estilizado
	tooltip_text = ""
	base_tooltip_text = ""
	
	set_purchase_upgrade(0)
	
	if sold_overlay:
		sold_overlay.hide()
	
	show()

func create_tier_placeholder() -> void:
	var color: Color = UIStyle.TIER_COLORS.get(current_tier, Color.WHITE)
	var gradient := Gradient.new()
	gradient.colors = [color.lightened(0.2), color.darkened(0.4)]
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 128
	gradient_texture.height = 128
	if icon_rect:
		icon_rect.texture = gradient_texture

func update_tier_style() -> void:
	default_style = UIStyle.make_card_style(current_tier, false)
	hover_style = UIStyle.make_card_style(current_tier, true)
	add_theme_stylebox_override("panel", hover_style if is_hovered else default_style)

func set_purchase_upgrade(stars: int, deferred_until_next_round: bool = false, unit_owned: bool = false) -> void:
	purchase_upgrade_star = clampi(stars, 2, 4) if stars >= 2 and unit_stats and not is_sold else 0
	is_unit_owned = unit_owned and unit_stats != null and not is_sold
	if not is_instance_valid(upgrade_glow):
		return
	tooltip_text = ""
	
	if purchase_upgrade_star > 0:
		upgrade_glow.material = upgrade_material
		upgrade_glow.visible = true
		var tint := Color("#ffd16b")
		if purchase_upgrade_star == 3:
			tint = Color("#dca1ff")
		elif purchase_upgrade_star == 4:
			tint = Color("#88f4ff")
		upgrade_material.set_shader_parameter("glow_color", tint)
		if tier_badge:
			tier_badge.text = "Nv.%d" % purchase_upgrade_star
			tier_badge.add_theme_color_override("font_color", tint)
	elif is_unit_owned:
		upgrade_glow.material = owned_material
		upgrade_glow.visible = true
		owned_material.set_shader_parameter("glow_color", Color(0.24, 0.82, 0.95, 0.85))
		if tier_badge and unit_stats:
			tier_badge.text = "T%d" % unit_stats.tier
			tier_badge.add_theme_color_override("font_color", Color(0.35, 0.88, 1.0))
	else:
		upgrade_glow.visible = false
		if tier_badge and unit_stats:
			tier_badge.text = "T%d" % unit_stats.tier
			tier_badge.add_theme_color_override("font_color", UIStyle.TIER_COLORS.get(unit_stats.tier, Color.WHITE))

func mark_as_sold() -> void:
	is_sold = true
	set_purchase_upgrade(0)
	if sold_overlay:
		sold_overlay.show()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _update_traits_display(origins: Array[String], classes: Array[String]) -> void:
	if not traits_container:
		if origin_label:
			origin_label.text = origins[0] if not origins.is_empty() else "—"
			origin_label.visible = not origins.is_empty()
		if class_label:
			class_label.text = classes[0] if not classes.is_empty() else "—"
			class_label.visible = not classes.is_empty()
		return

	# Ocultar os labels estáticos de fallback
	if origin_label:
		origin_label.visible = false
	if class_label:
		class_label.visible = false

	# Limpar badges dinâmicos anteriores
	for child in traits_container.get_children():
		if child != origin_label and child != class_label:
			child.queue_free()

	var base_style: StyleBox = origin_label.get_theme_stylebox("normal") if origin_label else null

	for o in origins:
		var lbl := Label.new()
		lbl.text = o
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.85, 0.93, 0.98, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.clip_text = true
		if base_style:
			lbl.add_theme_stylebox_override("normal", base_style)
		traits_container.add_child(lbl)

	for c in classes:
		var lbl := Label.new()
		lbl.text = c
		lbl.add_theme_font_size_override("font_size", 9)
		lbl.add_theme_color_override("font_color", Color(0.98, 0.92, 0.78, 1))
		lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		lbl.add_theme_constant_override("outline_size", 2)
		lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		lbl.clip_text = true
		if base_style:
			lbl.add_theme_stylebox_override("normal", base_style)
		traits_container.add_child(lbl)

	if classes.is_empty() and unit_stats:
		var role := unit_stats.get_combat_role()
		if not role.is_empty():
			var lbl := Label.new()
			lbl.text = role
			lbl.add_theme_font_size_override("font_size", 9)
			lbl.add_theme_color_override("font_color", Color(0.85, 0.7, 1.0, 1))
			lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
			lbl.add_theme_constant_override("outline_size", 2)
			lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			lbl.clip_text = true
			if base_style:
				lbl.add_theme_stylebox_override("normal", base_style)
			traits_container.add_child(lbl)

func clear() -> void:
	unit_stats = null
	is_sold = false
	base_tooltip_text = ""
	set_purchase_upgrade(0)
	tooltip_text = ""
	if name_label:
		name_label.text = "---"
	if tier_badge:
		tier_badge.text = ""
	if origin_label:
		origin_label.text = ""
		origin_label.visible = false
	if class_label:
		class_label.text = ""
		class_label.visible = false
	if traits_container:
		for child in traits_container.get_children():
			if child != origin_label and child != class_label:
				child.queue_free()
	if cost_label:
		cost_label.text = ""
	if icon_rect:
		icon_rect.texture = null
	var empty_style := StyleBoxFlat.new()
	empty_style.bg_color = Color(0.06, 0.08, 0.11, 0.6)
	empty_style.border_color = Color(0.2, 0.25, 0.3, 0.5)
	empty_style.set_border_width_all(1)
	empty_style.set_corner_radius_all(5)
	add_theme_stylebox_override("panel", empty_style)
	if sold_overlay:
		sold_overlay.hide()
	mouse_filter = Control.MOUSE_FILTER_STOP


func _on_mouse_entered() -> void:
	if is_sold or not unit_stats:
		return
	is_hovered = true
	hover_started.emit(unit_stats, global_position)
	add_theme_stylebox_override("panel", hover_style)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.04, 1.04), 0.12)

func _on_mouse_exited() -> void:
	is_hovered = false
	hover_ended.emit()
	add_theme_stylebox_override("panel", default_style)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12)

func _on_gui_input(event: InputEvent) -> void:
	if is_sold or not unit_stats:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			pointer_down = true
			drag_was_requested = false
			press_position = event.position
		else:
			if pointer_down and not drag_was_requested:
				card_clicked.emit(slot_index)
			pointer_down = false
	elif event is InputEventMouseMotion and pointer_down and not drag_was_requested:
		if press_position.distance_to(event.position) >= 8.0:
			drag_was_requested = true
			drag_started.emit(unit_stats, slot_index)

func get_drag_data(_at_position: Vector2) -> Variant:
	return null
