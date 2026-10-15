class_name BenchUI
extends HBoxContainer

signal unit_drag_started(slot_index: int)

const SLOT_COUNT := 9
const SLOT_SIZE := Vector2(86, 58)

var slots: Array[PanelContainer] = []
var slot_icons: Array[TextureRect] = []
var slot_labels: Array[Label] = []
var unit_count: int = 0
@onready var title_label: Label = get_node_or_null("../BenchTitle") as Label

func _ready() -> void:
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_theme_constant_override("separation", 7)
	_build_slots()
	set_units([])

func _build_slots() -> void:
	for i in SLOT_COUNT:
		var slot := PanelContainer.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.tooltip_text = "Espaço vazio do banco"
		slot.gui_input.connect(_on_slot_gui_input.bind(i))

		var style := StyleBoxFlat.new()
		style.bg_color = Color("#24231f")
		style.border_color = Color("#625844")
		style.set_border_width_all(2)
		style.set_corner_radius_all(5)
		style.content_margin_left = 5
		style.content_margin_right = 5
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		slot.add_theme_stylebox_override("panel", style)

		var content := VBoxContainer.new()
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		content.add_theme_constant_override("separation", 2)
		slot.add_child(content)

		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(32, 30)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(icon)

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color("#f4ead5"))
		label.text = "Vazio"
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(label)

		add_child(slot)
		slots.append(slot)
		slot_icons.append(icon)
		slot_labels.append(label)

func set_units(units: Array, combat_active: bool = false) -> void:
	unit_count = units.size()
	if title_label:
		var hint := "vendas liberadas · evolução no próximo round" if combat_active else "arraste unidades para o tabuleiro"
		title_label.text = "BANCO %d/%d · %s" % [units.size(), SLOT_COUNT, hint]
	for i in SLOT_COUNT:
		var unit: BaseUnit3D = units[i] if i < units.size() else null
		var style := slots[i].get_theme_stylebox("panel") as StyleBoxFlat
		if not unit or not unit.stats:
			slot_icons[i].texture = null
			slot_labels[i].text = "Vazio"
			slots[i].tooltip_text = "Espaço vazio do banco"
			style.border_color = Color("#625844")
			continue

		var stats: UnitStats = unit.stats
		slot_icons[i].texture = stats.icon
		slot_labels[i].text = stats.unit_name
		slots[i].tooltip_text = "%s · Tier %d · %d ouro\nArraste para o tabuleiro ou passe o mouse e aperte S para vender" % [stats.unit_name, stats.tier, unit.invested_gold]
		if combat_active:
			slots[i].tooltip_text = "%s · %d estrela(s) · %d ouro\nS ou arraste à zona de venda. Evoluções no início do próximo round." % [stats.unit_name, unit.star_level, unit.invested_gold]
		style.border_color = stats.get_tier_color()

func _on_slot_gui_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if slot_index < slots.size() and slots[slot_index].tooltip_text != "Espaço vazio do banco":
			unit_drag_started.emit(slot_index)
			accept_event()

func get_unit_index_at(screen_position: Vector2) -> int:
	for i in min(unit_count, slots.size()):
		if slots[i].get_global_rect().has_point(screen_position):
			return i
	return -1
