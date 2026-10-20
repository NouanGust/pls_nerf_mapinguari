class_name BenchUI
extends HBoxContainer

const UIStyle = preload("res://Scripts/UI/ui_style.gd")

signal unit_drag_started(slot_index: int)

const SLOT_COUNT := 9
const SLOT_SIZE := Vector2(82, 64)

var slots: Array[PanelContainer] = []
var slot_icons: Array[TextureRect] = []
var slot_labels: Array[Label] = []
var slot_stars: Array[Label] = []
var unit_count: int = 0
@onready var title_label: Label = get_node_or_null("../BenchTitle") as Label

func _ready() -> void:
	custom_minimum_size.y = 64.0
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 6)
	_build_slots()
	resized.connect(_fit_slots)
	_fit_slots.call_deferred()
	set_units([])

func _build_slots() -> void:
	for i in SLOT_COUNT:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.tooltip_text = "Espaço vazio do banco"
		slot.gui_input.connect(_on_slot_gui_input.bind(i))

		var style := UIStyle.make_pedestal_style(UIStyle.BORDER_SLATE, false)
		slot.add_theme_stylebox_override("panel", style)

		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 1)
		slot.add_child(content)

		# Indicador de Estrelas (★ / ★★ / ★★★)
		var star_label := Label.new()
		star_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		star_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		star_label.add_theme_font_size_override("font_size", 10)
		star_label.add_theme_color_override("font_color", UIStyle.TEXT_GOLD_BRIGHT)
		star_label.add_theme_color_override("font_outline_color", Color.BLACK)
		star_label.add_theme_constant_override("outline_size", 3)
		star_label.text = ""
		star_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(star_label)

		# Retrato do personagem
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(36, 32)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)

		# Nome do personagem
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", UIStyle.TEXT_MUTED)
		label.text = "—"
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.clip_text = true
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)

		add_child(slot)
		slots.append(slot)
		slot_icons.append(icon)
		slot_labels.append(label)
		slot_stars.append(star_label)

func _fit_slots() -> void:
	if get_parent_control():
		fit_available_width(get_parent_control().size.x)

func fit_available_width(available_width: float) -> void:
	var slot_width := clampf((available_width - 16.0 - 8.0 * 6.0) / float(SLOT_COUNT), 44.0, 96.0)
	for slot in slots:
		slot.custom_minimum_size = Vector2(slot_width, 64.0)
	if title_label:
		title_label.clip_text = true
		title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func set_units(units: Array, combat_active: bool = false) -> void:
	unit_count = units.size()
	if title_label:
		title_label.text = "BANCO · %d / %d" % [units.size(), SLOT_COUNT]
		title_label.add_theme_color_override("font_color", UIStyle.TEXT_GOLD)
	
	for i in SLOT_COUNT:
		var unit: BaseUnit3D = units[i] if i < units.size() else null
		var slot := slots[i]
		
		if not unit or not unit.stats:
			slot_icons[i].texture = null
			slot_labels[i].text = "—"
			slot_labels[i].add_theme_color_override("font_color", Color(0.4, 0.48, 0.55, 0.6))
			slot_stars[i].text = ""
			slot.tooltip_text = "Pedestal vazio do banco"
			slot.add_theme_stylebox_override("panel", UIStyle.make_pedestal_style(UIStyle.BORDER_SLATE, false))
			continue

		var stats: UnitStats = unit.stats
		var tier_color: Color = stats.get_tier_color()
		slot_icons[i].texture = stats.icon
		slot_labels[i].text = stats.unit_name
		slot_labels[i].add_theme_color_override("font_color", UIStyle.TEXT_WHITE)
		
		# Exibir estrelas
		var stars := maxi(unit.star_level, 1)
		slot_stars[i].text = "★".repeat(stars)
		if stars >= 3:
			slot_stars[i].add_theme_color_override("font_color", Color("#ffd700"))
		elif stars == 2:
			slot_stars[i].add_theme_color_override("font_color", Color("#c0c0c0"))
		else:
			slot_stars[i].add_theme_color_override("font_color", Color("#cd7f32"))
		
		slot.tooltip_text = "%s · %d★ · Tier %d (%d ouro)\nArraste para o campo ou pressione S com o mouse sobre para vender" % [
			stats.unit_name, stars, stats.tier, unit.invested_gold
		]
		if combat_active:
			slot.tooltip_text += "\n(Combate em andamento)"
		
		slot.add_theme_stylebox_override("panel", UIStyle.make_pedestal_style(tier_color, true))

func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if slot_index < slots.size() and slot_labels[slot_index].text != "—":
			unit_drag_started.emit(slot_index)
			accept_event()

func get_unit_index_at(screen_position: Vector2) -> int:
	for i in min(unit_count, slots.size()):
		if slots[i].get_global_rect().has_point(screen_position):
			return i
	return -1
