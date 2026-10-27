class_name ShopUI
extends HBoxContainer

const UIStyle = preload("res://Scripts/UI/ui_style.gd")
const UIAtlasCatalog = preload("res://Scripts/UI/ui_atlas_catalog.gd")
const ResponsiveLayout = preload("res://Scripts/UI/responsive_layout.gd")

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

@onready var stats_tooltip: PanelContainer = get_node_or_null("../StatsTooltip")
@onready var shop_toggle_button: Button = get_node_or_null("../ShopLabel")
@onready var lock_button: Button = (get_node_or_null("../LockButton") as Button) if get_node_or_null("../LockButton") else (get_node_or_null("../ControlsContainer/LockButton") as Button)
@onready var tier_odds_container: HBoxContainer = get_node_or_null("../ControlsContainer/TierOddsContainer")
@onready var level_label: Label = get_node_or_null("../ControlsContainer/LevelBox/VBox/Header/LevelLabel")
@onready var xp_progress_label: Label = get_node_or_null("../ControlsContainer/LevelBox/VBox/Header/XPProgressLabel")
@onready var xp_progress_bar: ProgressBar = get_node_or_null("../ControlsContainer/LevelBox/VBox/XPProgressBar")
@onready var board_space_label: Label = get_node_or_null("../ControlsContainer/LevelBox/VBox/BoardSpaceContainer/BoardSpaceLabel")
@onready var gold_label: Label = get_node_or_null("../GoldContainer/GoldBox/GoldLabel")

const UNIT_CARD_SCENE := preload("res://Scenes/UI/Unit_card.tscn")
var tier_odd_labels: Array[Label] = []

func _ready() -> void:
	clip_contents = false
	await get_tree().process_frame
	if get_parent_control():
		original_position_y = position.y
		hidden_position_y = get_parent_control().size.y + 18.0
	setup_shop_slots()
	_setup_tier_odds()
	_apply_button_styles()
	resized.connect(_fit_cards)
	get_viewport().size_changed.connect(_hide_tooltip)
	_fit_cards()
	if shop_system:
		_on_shop_refreshed(shop_system.current_units)
	if stats_tooltip:
		stats_tooltip.set_anchors_preset(Control.PRESET_TOP_LEFT)
		_prepare_tooltip_layout()
		stats_tooltip.hide()

func _apply_button_styles() -> void:
	if shop_toggle_button:
		UIStyle.apply_button_skin(shop_toggle_button, UIStyle.BORDER_SLATE)
	if lock_button:
		lock_button.icon = UIAtlasCatalog.get_icon_texture("padlock")
		lock_button.expand_icon = true
		UIStyle.apply_button_skin(lock_button, UIStyle.BORDER_GOLD)
	var buy_xp := get_node_or_null("../ControlsContainer/BuyXPButton") as Button
	if buy_xp:
		UIStyle.apply_button_skin(buy_xp, Color("#3498db"))
	var reroll := get_node_or_null("../ControlsContainer/RerollButton") as Button
	if reroll:
		UIStyle.apply_button_skin(reroll, UIStyle.BORDER_GOLD)

func _setup_tier_odds() -> void:
	if not tier_odds_container:
		return
	for child in tier_odds_container.get_children():
		child.queue_free()
	tier_odd_labels.clear()
	
	for tier in range(1, 6):
		var pill := HBoxContainer.new()
		pill.add_theme_constant_override("separation", 2)
		pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(8, 8)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		dot.color = UIStyle.TIER_COLORS.get(tier, Color.WHITE)
		pill.add_child(dot)
		
		var label := Label.new()
		label.text = "0%"
		label.add_theme_font_size_override("font_size", 10)
		label.add_theme_color_override("font_color", Color(0.85, 0.88, 0.92, 1))
		pill.add_child(label)
		
		tier_odds_container.add_child(pill)
		tier_odd_labels.append(label)
	
	update_tier_odds(1)

func update_tier_odds(player_level: int) -> void:
	if tier_odd_labels.is_empty():
		return
	var chances: Array = [100, 0, 0, 0, 0]
	if shop_system and shop_system.tier_chances.has(player_level):
		chances = shop_system.tier_chances[player_level]
	elif player_level in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
		# Fallback se shop_system ainda não foi injetado
		var defaults := {
			1: [100, 0, 0, 0, 0],
			2: [85, 15, 0, 0, 0],
			3: [75, 25, 0, 0, 0],
			4: [55, 30, 15, 0, 0],
			5: [45, 33, 20, 2, 0],
			6: [30, 40, 25, 5, 0],
			7: [19, 35, 35, 10, 1],
			8: [16, 25, 35, 20, 4],
			9: [9, 15, 30, 30, 16],
		}
		chances = defaults.get(player_level, [100, 0, 0, 0, 0])
	
	for i in min(tier_odd_labels.size(), chances.size()):
		var pct: int = int(chances[i])
		tier_odd_labels[i].text = "%d%%" % pct
		tier_odd_labels[i].add_theme_color_override(
			"font_color",
			Color(0.9, 0.92, 0.95, 1) if pct > 0 else Color(0.4, 0.45, 0.5, 0.5)
		)

func update_player_info(gold: int, level: int, current_xp: int, required_xp: int, is_max_level: bool) -> void:
	if gold_label:
		gold_label.text = "%d" % gold
		var interest := mini(5, floori(float(gold) / 10.0))
		var economy_tip := (
			"Ouro Atual: %d moedas\n\n" +
			"Rendimento por Round:\n" +
			"• Vitória: +2g base (+ bônus de sequência até +5g)\n" +
			"• Empate: +1g fixo\n" +
			"• Derrota: +1g base (+ bônus de sequência até +5g)\n" +
			"• Juros previstos: +%dg (+1g a cada 10g guardados, máx 5g)\n" +
			"• Renda básica de turno: +5g"
		) % [gold, interest]
		gold_label.tooltip_text = economy_tip
		var parent_box := gold_label.get_parent() as Control
		if parent_box:
			parent_box.tooltip_text = economy_tip
	if level_label:
		level_label.text = "NÍVEL %d" % level if not is_max_level else "NÍVEL 9 · MÁX"
	if xp_progress_label:
		xp_progress_label.text = "MÁX" if is_max_level else "XP %d/%d" % [current_xp, required_xp]
	if xp_progress_bar:
		xp_progress_bar.max_value = maxi(required_xp, 1)
		xp_progress_bar.value = required_xp if is_max_level else current_xp
	update_tier_odds(level)

func update_board_capacity(units_on_board: int, board_limit: int) -> void:
	if not board_space_label:
		board_space_label = get_node_or_null("../ControlsContainer/LevelBox/VBox/BoardSpaceContainer/BoardSpaceLabel")
	if board_space_label:
		var available := maxi(0, board_limit - units_on_board)
		if available > 0:
			board_space_label.text = "CAMPO: %d/%d (! %d vaga%s)" % [
				units_on_board, board_limit, available, "s" if available > 1 else ""
			]
			board_space_label.add_theme_color_override("font_color", Color("#f59e0b"))
		else:
			board_space_label.text = "CAMPO: %d/%d (Completo)" % [units_on_board, board_limit]
			board_space_label.add_theme_color_override("font_color", Color("#94a3b8"))
		board_space_label.tooltip_text = "Unidades no campo: %d/%d\nEspaços disponíveis no tabuleiro: %d\nArraste unidades do banco para posicionar." % [
			units_on_board, board_limit, available
		]

func toogle_shop() -> void:
	is_shop_visible = not is_shop_visible
	var parent_ctrl := get_parent_control()
	var target_y = original_position_y if is_shop_visible else (parent_ctrl.size.y + 18.0 if parent_ctrl else 300.0)
	if shop_toggle_button:
		shop_toggle_button.text = "LOJA" if is_shop_visible else "+ LOJA"
	if shop_tween and shop_tween.is_running():
		shop_tween.kill()
	shop_tween = create_tween()
	shop_tween.set_ease(Tween.EASE_OUT)
	shop_tween.set_trans(Tween.TRANS_CUBIC)
	shop_tween.set_parallel(true)
	shop_tween.tween_property(self, "position:y", target_y, 0.28)
	shop_tween.tween_property(self, "modulate:a", 1.0 if is_shop_visible else 0.0, 0.28)

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
	var available_w: float = maxf(size.x - 32.0, 500.0)
	var card_w := clampf((available_w - 4.0 * 8.0) / 5.0, 100.0, 170.0)
	for card in unit_cards:
		card.fit_card(card_w)

func fit_shop(rectangle: Rect2) -> void:
	if shop_tween and shop_tween.is_running():
		shop_tween.kill()
	original_position_y = rectangle.position.y
	var parent_ctrl := get_parent_control()
	hidden_position_y = parent_ctrl.size.y + 18.0 if parent_ctrl else 300.0
	custom_minimum_size.x = 0.0
	var card_w := clampf((rectangle.size.x - 32.0 - 4.0 * 8.0) / 5.0, 100.0, 170.0)
	for card in unit_cards:
		card.fit_card(card_w)
	ResponsiveLayout.place(self, rectangle)
	_fit_cards()
	position.y = original_position_y if is_shop_visible else hidden_position_y
	modulate.a = 1.0 if is_shop_visible else 0.0

func _hide_tooltip() -> void:
	if stats_tooltip:
		stats_tooltip.hide()

func set_shop_system(system: ShopSystem) -> void:
	shop_system = system
	if shop_system:
		shop_system.shop_refreshed.connect(_on_shop_refreshed)
		shop_system.shop_locked_changed.connect(_on_lock_changed)
		update_tier_odds(1)

func _on_shop_refreshed(units: Array[UnitStats]) -> void:
	for i in min(units.size(), unit_cards.size()):
		if units[i]:
			unit_cards[i].set_unit(units[i])
		else:
			unit_cards[i].clear()
	_refresh_upgrade_hints()
	var has_upgrade_hint := false
	for card in unit_cards:
		if card.unit_stats and not card.is_sold and _get_purchase_upgrade_star(card.unit_stats.unit_id) > 0:
			has_upgrade_hint = true
			break
	if has_upgrade_hint:
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("play_evol_hint_shop"):
			am.play_evol_hint_shop()
	else:
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("stop_evol_hint_shop"):
			am.stop_evol_hint_shop()

func set_owned_star_counts(counts: Dictionary, in_combat: bool) -> void:
	owned_star_counts = counts.duplicate(true)
	upgrades_deferred = in_combat
	_refresh_upgrade_hints()

func _refresh_upgrade_hints() -> void:
	for card in unit_cards:
		var stars := 0
		var is_owned := false
		if card.unit_stats and not card.is_sold:
			stars = _get_purchase_upgrade_star(card.unit_stats.unit_id)
			is_owned = _is_unit_owned(card.unit_stats.unit_id)
		card.set_purchase_upgrade(stars, upgrades_deferred, is_owned)
		if card.is_hovered:
			if card.unit_stats and not card.is_sold:
				update_tooltip_labels(card.unit_stats)
			elif stats_tooltip:
				stats_tooltip.hide()

func _is_unit_owned(unit_id: String) -> bool:
	if not owned_star_counts.has(unit_id):
		return false
	var counts: Array = owned_star_counts[unit_id]
	for s in range(1, counts.size()):
		if int(counts[s]) > 0:
			return true
	return false

func _get_purchase_upgrade_star(unit_id: String) -> int:
	if not owned_star_counts.has(unit_id):
		return 0
	var counts: Array = owned_star_counts[unit_id].duplicate()
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
	if lock_button:
		lock_button.icon = UIAtlasCatalog.get_icon_texture("padlock")
		lock_button.expand_icon = true
		lock_button.text = "Destravar" if is_locked else "Travar"
		UIStyle.apply_button_skin(lock_button, UIStyle.BORDER_CYAN if is_locked else UIStyle.BORDER_GOLD)

func _prepare_tooltip_layout(target_width: float = 360.0) -> void:
	if not stats_tooltip:
		return
	var viewport_size := get_viewport_rect().size
	var target_w := clampf(target_width, 240.0, maxf(viewport_size.x - 24.0, 240.0))
	var inner_w := maxf(target_w - 24.0, 100.0)
	stats_tooltip.set_anchors_preset(Control.PRESET_TOP_LEFT)
	stats_tooltip.custom_minimum_size = Vector2(target_w, 0.0)
	stats_tooltip.size = Vector2(target_w, 0.0)
	var vbox_node := stats_tooltip.get_node_or_null("VBoxContainer") as VBoxContainer
	if vbox_node:
		vbox_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox_node.custom_minimum_size = Vector2(inner_w, 0.0)
		vbox_node.size = Vector2(inner_w, 0.0)
		for child in vbox_node.get_children():
			if child is Control:
				child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				child.custom_minimum_size = Vector2(inner_w, 0.0)
				child.size = Vector2(inner_w, 0.0)
				if child is RichTextLabel:
					child.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					child.fit_content = true
		vbox_node.reset_size()
	stats_tooltip.reset_size()

func _on_card_hover_started(stats: UnitStats, card_pos: Vector2) -> void:
	if not stats_tooltip:
		return
	_prepare_tooltip_layout()
	update_tooltip_labels(stats)
	_prepare_tooltip_layout()
	_tooltip_origin = card_pos
	_fit_tooltip()
	stats_tooltip.show()
	_fit_tooltip.call_deferred()

func _fit_tooltip() -> void:
	if not stats_tooltip:
		return
	var viewport_size := get_viewport_rect().size
	_prepare_tooltip_layout()
	ResponsiveLayout.clamp_popup(stats_tooltip, _tooltip_origin - Vector2(0, stats_tooltip.size.y + 12.0), viewport_size)

func _on_card_hover_ended() -> void:
	if stats_tooltip:
		stats_tooltip.hide()

func update_tooltip_labels(stats: UnitStats) -> void:
	if not stats_tooltip:
		return
	stats_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v_box := stats_tooltip.get_node_or_null("VBoxContainer")
	if not v_box:
		return
	v_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var name_lbl := v_box.get_node_or_null("Tooltip_name") as RichTextLabel
	if name_lbl:
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_lbl.text = "[b]%s[/b] (Tier %d · %dg)" % [stats.unit_name, stats.tier, stats.cost]
		var upgrade_star := _get_purchase_upgrade_star(stats.unit_id)
		var is_owned := _is_unit_owned(stats.unit_id)
		if upgrade_star > 0:
			name_lbl.text += " [color=#ffd16b]• Evolui para Nível %d%s[/color]" % [
				upgrade_star,
				" no próximo round" if upgrades_deferred else " ao comprar"
			]
		elif is_owned:
			name_lbl.text += " [color=#42d1e8]• Já possui no time[/color]"
	
	var hp_lbl := v_box.get_node_or_null("Tooltip_hp") as RichTextLabel
	if hp_lbl:
		hp_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hp_lbl.text = "Vida: [b]%d[/b] | Mana: [b]%d/%d[/b]" % [int(stats.max_health), int(stats.starting_mana), int(stats.max_mana)]
	
	var range_lbl := v_box.get_node_or_null("Tooltip_range") as RichTextLabel
	if range_lbl:
		range_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var attack_range := stats.get_attack_range_hexes()
		var attack_type := "Distância" if attack_range > 1 else "Corpo a corpo"
		range_lbl.text = "%s (Alcance %d)" % [attack_type, attack_range]
		if stats.is_stationary:
			range_lbl.text = "Planta imóvel · " + range_lbl.text
	
	var type_lbl := v_box.get_node_or_null("Tooltip_type") as RichTextLabel
	if type_lbl:
		type_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var dmg_text := "Físico" if stats.ability_damage_type == 0 else "Mágico"
		type_lbl.text = "Dano: [b]%s[/b] · Poder %d  ·  Defesa: [b]%d[/b] Arm / [b]%d[/b] RM" % [
			dmg_text, int(stats.attack_damage), int(stats.armor), int(stats.magic_resist)
		]
		var traits_text: Array[String] = []
		if not stats.origins.is_empty():
			traits_text.append("[color=#74e6f5]Origens:[/color] %s" % ", ".join(stats.origins))
		if not stats.classes.is_empty():
			traits_text.append("[color=#ffd16b]Classes:[/color] %s" % ", ".join(stats.classes))
		traits_text.append("[color=#fbbf24]Função:[/color] %s" % stats.get_combat_role())
		if not traits_text.is_empty():
			type_lbl.text += "\n" + "  ·  ".join(traits_text)
		if not stats.ability_name.is_empty():
			type_lbl.text += "\nHabilidade: [b]%s[/b] - %s" % [stats.ability_name, stats.ability_description]

func mark_slot_as_sold(slot_index: int) -> void:
	if slot_index >= 0 and slot_index < unit_cards.size():
		unit_cards[slot_index].mark_as_sold()
	_refresh_upgrade_hints()
	var has_upgrade_hint := false
	for card in unit_cards:
		if card.unit_stats and not card.is_sold and _get_purchase_upgrade_star(card.unit_stats.unit_id) > 0:
			has_upgrade_hint = true
			break
	if not has_upgrade_hint:
		var am = get_node_or_null("/root/AudioManager")
		if am and am.has_method("stop_evol_hint_shop"):
			am.stop_evol_hint_shop()
