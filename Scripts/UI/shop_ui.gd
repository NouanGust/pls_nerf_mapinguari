class_name ShopUI
extends HBoxContainer

signal unit_selected(unit_stats: UnitStats, slot_index: int)
signal unit_drag_requested(unit_stats: UnitStats, slot_index: int)
signal reroll_requested()
signal lock_toggled(is_locked: bool)

var shop_system: ShopSystem
var unit_cards: Array[UnitCard] = []
var is_shop_visible: bool = true
var hidden_position_y: float = 0.0
var original_position_y: float = 0.0
var shop_tween: Tween
var owned_star_counts: Dictionary = {}
var upgrades_deferred: bool = false
var _tooltip_origin := Vector2.ZERO
@onready var stats_tooltip: PanelContainer = $"../StatsTooltip"
@onready var shop_toggle_button: Button = $"../ShopLabel"
@onready var lock_button: Button = $"../ControlsContainer/LockButton"

const UNIT_CARD_SCENE := preload("res://Scenes/UI/Unit_card.tscn")

func _ready() -> void:
	clip_contents = false
	await get_tree().process_frame
	original_position_y = position.y
	hidden_position_y = get_parent_control().size.y + 18.0
	setup_shop_slots()
	resized.connect(_fit_cards)
	get_viewport().size_changed.connect(_hide_tooltip)
	_fit_cards()
	if shop_system:
		_on_shop_refreshed(shop_system.current_units)
	stats_tooltip.hide()
	

func toogle_shop() -> void:
	is_shop_visible = !is_shop_visible
	var target_y = original_position_y if is_shop_visible else hidden_position_y
	shop_toggle_button.text = "− LOJA" if is_shop_visible else "+ LOJA"
	if shop_tween and shop_tween.is_running():
		shop_tween.kill()
	shop_tween = create_tween()
	shop_tween.set_ease(Tween.EASE_OUT)
	shop_tween.set_trans(Tween.TRANS_CUBIC)
	shop_tween.set_parallel(true)
	shop_tween.tween_property(self, "position:y", target_y, 0.3)
	shop_tween.tween_property(self, "modulate:a", 1.0 if is_shop_visible else 0.0, 0.3)

func setup_shop_slots() -> void:
	for i in 5:
		var card: UnitCard = UNIT_CARD_SCENE.instantiate()
		card.name = "UnitCard_%d" % i
		card.slot_index = i
		card.card_clicked.connect(_on_card_clicked)
		card.drag_started.connect(_on_drag_started)
		
		add_child(card)
		unit_cards.append(card)
		card.hover_started.connect(_on_card_hover_started)
		card.hover_ended.connect(_on_card_hover_ended)

func _fit_cards() -> void:
	custom_minimum_size.x = 0.0
	var card_width := maxf(100.0, (size.x - 40.0) / 5.0)
	for card in unit_cards:
		card.fit_card(card_width)

func fit_shop(rectangle: Rect2) -> void:
	if shop_tween and shop_tween.is_running():
		shop_tween.kill()
	original_position_y = rectangle.position.y
	hidden_position_y = get_parent_control().size.y + 18.0
	custom_minimum_size.x = 0.0
	for card in unit_cards:
		card.fit_card(maxf(100.0, (rectangle.size.x - 40.0) / 5.0))
	ResponsiveLayout.place(self, rectangle)
	_fit_cards()
	position.y = original_position_y if is_shop_visible else hidden_position_y
	modulate.a = 1.0 if is_shop_visible else 0.0

func _hide_tooltip() -> void:
	stats_tooltip.hide()

func set_shop_system(system: ShopSystem) -> void:
	shop_system = system
	
	if shop_system:
		shop_system.shop_refreshed.connect(_on_shop_refreshed)
		shop_system.shop_locked_changed.connect(_on_lock_changed)

func _on_shop_refreshed(units: Array[UnitStats]) -> void:
	for i in min(units.size(), unit_cards.size()):
		if units[i]:
			unit_cards[i].set_unit(units[i])
		else:
			unit_cards[i].clear()
	_refresh_upgrade_hints()

func set_owned_star_counts(counts: Dictionary, in_combat: bool) -> void:
	owned_star_counts = counts.duplicate(true)
	upgrades_deferred = in_combat
	_refresh_upgrade_hints()

func _refresh_upgrade_hints() -> void:
	for card in unit_cards:
		var stars := 0
		if card.unit_stats and not card.is_sold:
			stars = _get_purchase_upgrade_star(card.unit_stats.unit_id)
		card.set_purchase_upgrade(stars, upgrades_deferred)
		if card.is_hovered:
			if card.unit_stats and not card.is_sold:
				update_tooltip_labels(card.unit_stats)
			else:
				stats_tooltip.hide()

func _get_purchase_upgrade_star(unit_id: String) -> int:
	if not owned_star_counts.has(unit_id):
		return 0
	var counts: Array = owned_star_counts[unit_id].duplicate()
	# Primeiro resolve trios já pendentes, para não atribuir à próxima compra
	# uma evolução que já ocorreria sem ela no fim do combate.
	for star in range(1, 4):
		counts[star + 1] += floori(float(counts[star]) / 3.0)
		counts[star] = int(counts[star]) % 3
	if int(counts[4]) > 0 or int(counts[1]) != 2:
		return 0
	var result := 2
	while result < 4 and int(counts[result]) == 2:
		result += 1
	return result

func _on_card_clicked(slot_index: int) -> void:
	if shop_system and slot_index < shop_system.current_units.size():
		var unit: UnitStats = shop_system.current_units[slot_index]
		if unit:
			unit_selected.emit(unit, slot_index)

func _on_drag_started(unit_stats: UnitStats, slot_index: int) -> void:
	unit_drag_requested.emit(unit_stats, slot_index)

func _on_lock_changed(is_locked: bool) -> void:
	lock_button.text = "Destravar" if is_locked else "Travar loja"
	print("Loja %s" % ("travada" if is_locked else "destravada"))

func _on_card_hover_started(stats: UnitStats, card_pos: Vector2) -> void:
	update_tooltip_labels(stats)
	_tooltip_origin = card_pos
	stats_tooltip.show()
	_fit_tooltip.call_deferred()

func _fit_tooltip() -> void:
	var viewport_size := get_viewport_rect().size
	stats_tooltip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stats_tooltip.custom_minimum_size.x = minf(320.0, viewport_size.x - 24.0)
	stats_tooltip.get_node("VBoxContainer").size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_tooltip.reset_size()
	ResponsiveLayout.clamp_popup(stats_tooltip, _tooltip_origin - Vector2(0, stats_tooltip.size.y + 12.0), viewport_size)

func _on_card_hover_ended() -> void:
	stats_tooltip.hide()

func update_tooltip_labels(stats: UnitStats) -> void:
	var v_box = stats_tooltip.get_node("VBoxContainer")
	
	v_box.get_node("Tooltip_name").text = stats.unit_name
	var upgrade_star := _get_purchase_upgrade_star(stats.unit_id)
	if upgrade_star > 0:
		v_box.get_node("Tooltip_name").text += "\nEvolui para %d★%s" % [upgrade_star, " no próximo round" if upgrades_deferred else " ao comprar"]
	v_box.get_node("Tooltip_hp").text = "Vida: %s" %[str(stats.max_health)]
	
	var attack_range := stats.get_attack_range_hexes()
	var attack_type := "Distância" if attack_range > 1 else "Corpo a corpo"
	v_box.get_node("Tooltip_range").text = "%s · alcance %d" % [attack_type, attack_range]
	if stats.is_stationary:
		v_box.get_node("Tooltip_range").text = "Planta imóvel · %s · alcance %d" % [attack_type, attack_range]
	
	var dmg_text = "Físico" if stats.ability_damage_type == 0 else "Mágico"
	v_box.get_node("Tooltip_type").text = "Dano: %s" %[dmg_text]
	if stats.passive_aura_effect == "power":
		v_box.get_node("Tooltip_type").text += "\nAura: +%d%% ataque · raio de %d hexes" % [roundi(stats.passive_aura_power * 100.0), stats.passive_aura_range]

func mark_slot_as_sold(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < unit_cards.size():
		unit_cards[slot_index].mark_as_sold()
