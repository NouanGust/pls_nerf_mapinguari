class_name ItemInventoryUI
extends PanelContainer

## Interface da Bandeja de Itens do Jogador (Estilo TFT / Auto Battler)

const UIStyle = preload("res://Scripts/UI/ui_style.gd")

signal item_selected_for_equip(item: ItemData)
signal item_use_requested(item: ItemData)

const SLOT_COUNT := 8
const SLOT_SIZE := Vector2(48, 48)

var item_manager: ItemManager = null
var main_game: Node = null
var selected_item: ItemData = null
var selected_slot_index: int = -1

var slots: Array[PanelContainer] = []
var slot_labels: Array[Label] = []
var slot_icons: Array[TextureRect] = []
var status_label: Label = null

func setup(manager: ItemManager, p_main_game: Node = null) -> void:
	item_manager = manager
	main_game = p_main_game
	if item_manager:
		if not item_manager.inventory_changed.is_connected(refresh_display):
			item_manager.inventory_changed.connect(refresh_display)
		if not item_manager.notification_requested.is_connected(_on_manager_notification):
			item_manager.notification_requested.connect(_on_manager_notification)
	refresh_display()

func _ready() -> void:
	custom_minimum_size = Vector2(230, 130)
	_build_ui()
	refresh_display()

func _build_ui() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.08, 0.14, 0.92)
	style.border_color = Color("#475569")
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_top = 8
	style.content_margin_right = 10
	style.content_margin_bottom = 8
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 6
	add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_child(header)

	var title := Label.new()
	title.text = "BANDEJA DE ITENS"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color("#f59e0b"))
	header.add_child(title)

	var subtitle := Label.new()
	subtitle.text = " (2 itens por unidade)"
	subtitle.add_theme_font_size_override("font_size", 10)
	subtitle.add_theme_color_override("font_color", Color("#94a3b8"))
	header.add_child(subtitle)

	# Grid de 8 slots (2 linhas de 4)
	var grid := GridContainer.new()
	grid.name = "SlotsGrid"
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	slots.clear()
	slot_labels.clear()
	slot_icons.clear()

	for i in range(SLOT_COUNT):
		var slot := PanelContainer.new()
		slot.custom_minimum_size = SLOT_SIZE
		slot.mouse_filter = Control.MOUSE_FILTER_STOP
		slot.gui_input.connect(_on_slot_gui_input.bind(i))

		var s_style := StyleBoxFlat.new()
		s_style.bg_color = Color(0.08, 0.12, 0.20, 0.75)
		s_style.border_color = Color("#334155")
		s_style.set_border_width_all(1)
		s_style.set_corner_radius_all(6)
		slot.add_theme_stylebox_override("panel", s_style)

		var icon_rect := TextureRect.new()
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(icon_rect)
		slot_icons.append(icon_rect)

		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(label)
		slot_labels.append(label)

		grid.add_child(slot)
		slots.append(slot)

	status_label = Label.new()
	status_label.text = "Clique num item e na unidade para equipar"
	status_label.add_theme_font_size_override("font_size", 10)
	status_label.add_theme_color_override("font_color", Color("#cbd5e1"))
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(status_label)

func refresh_display() -> void:
	if not is_instance_valid(status_label):
		return

	var items: Array = item_manager.get_inventory_items() if item_manager else []

	for i in range(SLOT_COUNT):
		var slot := slots[i]
		var icon_rect := slot_icons[i]
		var lbl := slot_labels[i]

		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(6)

		if i < items.size():
			var it: ItemData = items[i]
			var is_selected := (it == selected_item and i == selected_slot_index)

			style.bg_color = Color("#1e293b")
			if is_selected:
				style.border_color = Color("#38bdf8")
				style.set_border_width_all(3)
			elif it.is_emblem() or it.category == ItemData.ItemCategory.MYTHIC_BASE:
				style.border_color = Color("#10b981") # Verde Jade / Icamiaba
				style.set_border_width_all(2)
			elif it.is_component():
				style.border_color = Color("#0ea5e9") # Ciano
				style.set_border_width_all(2)
			elif it.is_consumable():
				style.border_color = Color("#a855f7") # Roxo Utilitário
				style.set_border_width_all(2)
			else:
				style.border_color = Color("#f59e0b") # Dourado Completo
				style.set_border_width_all(2)

			if it.icon:
				icon_rect.texture = it.icon
				lbl.text = ""
			else:
				icon_rect.texture = null
				lbl.text = it.name.substr(0, 3).to_upper()

			var tt := "%s\n\n%s" % [it.name, it.description]
			var stats_t := it.get_formatted_stats_text()
			if not stats_t.is_empty():
				tt += "\n\n" + stats_t
			tt += "\n\n[Clique esquerdo: Selecionar para equipar]"
			if it.is_consumable() and it.consumable_action == &"reforger":
				tt += "\n[Clique direito: Reforjar]"
			slot.tooltip_text = tt
		else:
			style.bg_color = Color(0.06, 0.09, 0.14, 0.6)
			style.border_color = Color("#334155")
			style.set_border_width_all(1)
			icon_rect.texture = null
			lbl.text = ""
			slot.tooltip_text = "Espaço vazio da bandeja de itens"

		slot.add_theme_stylebox_override("panel", style)

func _on_slot_gui_input(event: InputEvent, slot_idx: int) -> void:
	if not item_manager:
		return
	var items := item_manager.get_inventory_items()
	if slot_idx >= items.size():
		return

	if event is InputEventMouseButton and event.pressed:
		var it := items[slot_idx]
		if event.button_index == MOUSE_BUTTON_LEFT:
			if selected_item == it and selected_slot_index == slot_idx:
				# Deseleciona
				clear_selection()
			else:
				select_item(it, slot_idx)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Se for a Pena da Mãe-d'Ouro (reforjador)
			if it.consumable_action == &"reforger":
				item_manager.reforge_inventory_item(it)
				clear_selection()

func select_item(item: ItemData, slot_idx: int) -> void:
	selected_item = item
	selected_slot_index = slot_idx
	refresh_display()
	status_label.text = "Item [%s] selecionado!\nClique numa unidade no campo ou no banco para equipar (máx 2)." % item.name
	emit_signal("item_selected_for_equip", item)

func clear_selection() -> void:
	selected_item = null
	selected_slot_index = -1
	refresh_display()
	status_label.text = "Clique num item e na unidade para equipar"

func try_equip_selected_to_unit(unit: BaseUnit3D) -> bool:
	if not selected_item or not is_instance_valid(unit):
		return false

	var success := item_manager.equip_item_to_unit(selected_item, unit)
	if success:
		clear_selection()
	return success

func _on_manager_notification(text: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = text
