class_name UnitCard
extends PanelContainer

signal card_clicked(slot_index: int)
signal drag_started(unit_stats: UnitStats, slot_index: int)
signal hover_started(stats: UnitStats, pos: Vector2)
signal hover_ended()

var unit_stats: UnitStats
var slot_index: int = 0
var is_sold: bool = false
var is_hovered: bool = false

# Referências dos nodes
@onready var vbox: VBoxContainer = $VBox
@onready var tier_badge: Label = $VBox/TierBadge
@onready var icon_rect: TextureRect = $VBox/IconRect
@onready var name_label: Label = $VBox/NameLabel
@onready var hp_icon: Label = $VBox/StatsContainer/HpIcon
@onready var attack_icon: Label = $VBox/StatsContainer/AttackIcon
@onready var origin_label: Label = $VBox/TraitsContainer/OriginLabel
@onready var class_label: Label = $VBox/TraitsContainer/ClassLabel
@onready var cost_label: Label = $VBox/CostLabel
@onready var sold_overlay: ColorRect = $SoldOutOverlay if has_node("SoldOutOverlay") else null

# Estilos
var default_style: StyleBoxFlat
var hover_style: StyleBoxFlat
var tier_colors := {
	1: Color(0.6, 0.6, 0.6),
	2: Color(0.3, 0.8, 0.3),
	3: Color(0.3, 0.6, 1.0),
	4: Color(0.7, 0.3, 0.9),
	5: Color(1.0, 0.6, 0.2)
}

func _ready() -> void:
	custom_minimum_size = Vector2(140, 200)
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	setup_styles()
	setup_signals()

func setup_styles() -> void:
	# Estilo padrão
	default_style = StyleBoxFlat.new()
	default_style.bg_color = Color("#d9c5a0")
	
	var b_width = 3
	default_style.border_width_left = b_width
	default_style.border_width_right = b_width
	default_style.border_width_top = b_width
	default_style.border_width_bottom = b_width
	default_style.border_color = Color("#4a3222") 
	
	default_style.corner_radius_top_left = 2
	default_style.corner_radius_top_right = 2
	
	default_style.shadow_size = 5
	default_style.shadow_color = Color(0, 0, 0, 0.4)
	
	hover_style = default_style.duplicate()
	hover_style.shadow_color = Color("#e8c547", 0.3)
	hover_style.shadow_size = 8
	
	add_theme_stylebox_override("panel", default_style)

func setup_signals() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)

func set_unit(stats: UnitStats) -> void:
	unit_stats = stats
	is_sold = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	
	if default_style == null:
		setup_styles()
	
	if not unit_stats:
		clear()
		return
	
	# Nome
	name_label.text = unit_stats.unit_name
	name_label.add_theme_color_override("font-color", Color("#2d1d12"))
	
	# Tier
	tier_badge.text = "Tier %d" % unit_stats.tier
	tier_badge.add_theme_color_override("font_color", tier_colors.get(unit_stats.tier, Color.WHITE))
	
	# Stats
	hp_icon.text = "%d" % int(unit_stats.max_health)
	attack_icon.text = "%d" % int(unit_stats.attack_damage)
	
	# Origens e Classes
	var origins: Array[String] = unit_stats.origins
	var classes: Array[String] = unit_stats.classes
	
	origin_label.text = origins[0] if origins.size() > 0 else ""
	class_label.text = classes[0] if classes.size() > 0 else ""
	
	# Custo
	cost_label.text = "%d" % unit_stats.cost
	
	# Ícone (se houver)
	if unit_stats.icon:
		icon_rect.texture = unit_stats.icon
	else:
		# Placeholder colorido por tier
		create_tier_placeholder()
	
	# Atualizar estilo com cor do tier
	update_tier_style()
	
	# Esconder overlay de vendido
	if sold_overlay:
		sold_overlay.hide()
	
	show()

func create_tier_placeholder() -> void:
	# Criar uma textura colorida simples baseada no tier
	var color: Color = tier_colors.get(unit_stats.tier, Color.WHITE)
	
	# Criar gradiente
	var gradient := Gradient.new()
	gradient.colors = [color.lightened(0.3), color.darkened(0.3)]
	
	var gradient_texture := GradientTexture2D.new()
	gradient_texture.gradient = gradient
	gradient_texture.width = 128
	gradient_texture.height = 128
	gradient_texture.fill_from = Vector2(0, 0)
	gradient_texture.fill_to = Vector2(1, 1)
	
	icon_rect.texture = gradient_texture

func update_tier_style() -> void:
	if not unit_stats:
		return
	
	var tier_color: Color = tier_colors.get(unit_stats.tier, Color.WHITE)
	
	# Atualizar cor de borda
	default_style.border_color = tier_color
	hover_style.border_color = tier_color.lightened(0.3)
	
	# Aplicar estilo apropriado
	if is_hovered:
		add_theme_stylebox_override("panel", hover_style)
	else:
		add_theme_stylebox_override("panel", default_style)

func mark_as_sold() -> void:
	is_sold = true
	
	if sold_overlay:
		sold_overlay.show()
	
	# Desabilitar interação
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func clear() -> void:
	unit_stats = null
	is_sold = false
	
	name_label.text = "---"
	tier_badge.text = ""
	hp_icon.text = ""
	attack_icon.text = ""
	origin_label.text = ""
	class_label.text = ""
	cost_label.text = ""
	icon_rect.texture = null
	
	# Estilo vazio
	var empty_style := StyleBoxFlat.new()
	empty_style.bg_color = Color(0.1, 0.1, 0.1, 0.5)
	empty_style.border_color = Color(0.3, 0.3, 0.3, 0.5)
	empty_style.corner_radius_top_left = 8
	empty_style.corner_radius_top_right = 8
	empty_style.corner_radius_bottom_left = 8
	empty_style.corner_radius_bottom_right = 8
	add_theme_stylebox_override("panel", empty_style)
	
	if sold_overlay:
		sold_overlay.hide()
	
	mouse_filter = Control.MOUSE_FILTER_STOP

func _on_mouse_entered() -> void:
	if is_sold or not unit_stats:
		return
		
	if unit_stats:
		hover_started.emit(unit_stats, global_position)
	
	is_hovered = true
	add_theme_stylebox_override("panel", hover_style)
	
	# Animação de escala
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.1)

func _on_mouse_exited() -> void:
	is_hovered = false
	hover_ended.emit()
	add_theme_stylebox_override("panel", default_style)
	
	# Voltar escala normal
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _on_gui_input(event: InputEvent) -> void:
	if is_sold or not unit_stats:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			card_clicked.emit(slot_index)
			
			# Visual feedback
			var tween := create_tween()
			tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)
			tween.tween_property(self, "scale", Vector2(1.05, 1.05), 0.05)

func get_drag_data(_at_position: Vector2) -> Variant:
	#if is_sold or not unit_stats:
		#return null
	#
	## Criar preview visual para o drag
	#var preview := PanelContainer.new()
	#var label := Label.new()
	#label.text = unit_stats.unit_name
	#label.add_theme_font_size_override("font_size", 16)
	#preview.add_child(label)
	#
	#var preview_style := StyleBoxFlat.new()
	#preview_style.bg_color = tier_colors.get(unit_stats.tier, Color.WHITE)
	#preview_style.bg_color.a = 0.8
	#preview.add_theme_stylebox_override("panel", preview_style)
	#
	#set_drag_preview(preview)
	#
	#drag_started.emit(unit_stats, slot_index)
	#
	#return {
		#"unit_stats": unit_stats,
		#"slot_index": slot_index,
		#"source": "shop"
	#}
	return null
