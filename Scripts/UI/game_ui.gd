class_name GameUI
extends CanvasLayer

const UIStyle = preload("res://Scripts/UI/ui_style.gd")
const ResponsiveLayout = preload("res://Scripts/UI/responsive_layout.gd")
const UIAtlasCatalog = preload("res://Scripts/UI/ui_atlas_catalog.gd")
const BestiaryModal = preload("res://Scripts/UI/bestiary_modal.gd")
const SynergyPanelUI = preload("res://Scripts/UI/synergy_panel_ui.gd")
const RoundBannerUI = preload("res://Scripts/UI/round_banner_ui.gd")
const HUDAnimator = preload("res://Scripts/UI/hud_animator.gd")

signal hud_visibility_changed(is_visible: bool)
signal synergy_hover_started(synergy_name: String)
signal synergy_hover_ended()
signal start_battle_requested()

var start_battle_button: Button
var bestiary_modal: BestiaryModal
var bestiary_button: Button
var _inspected_unit_stats: UnitStats
var _inspected_unit_star_level: int = 1

@onready var hud: Control = $Control
@onready var top_bar: Control = $Control/TopBar
@onready var bottom_bar: Control = $Control/BottomBar
@onready var bench_panel: Control = $Control/BenchPanel
@onready var health_widget: Control = get_node_or_null("Control/HealthWidget")
@onready var right_bar: Control = $Control/RightBar
@onready var toggle_button: Button = $HUDToggleButton

# Elementos do TopBar (TFT)
@onready var round_label: Label = get_node_or_null("Control/TopBar/Content/RoundBox/RoundLabel")
@onready var phase_label: Label = get_node_or_null("Control/TopBar/Content/RoundBox/PhaseLabel")
@onready var timer_label: Label = get_node_or_null("Control/TopBar/Content/TimerBox/TimerLabel")
@onready var milestones_container: HBoxContainer = get_node_or_null("Control/TopBar/Content/MilestonesContainer")
@onready var enemy_level_label: Label = get_node_or_null("Control/TopBar/Content/EnemyBox/EnemyLevelLabel")
@onready var streak_box: HBoxContainer = get_node_or_null("Control/TopBar/Content/StreakBox")
@onready var streak_icon: TextureRect = get_node_or_null("Control/TopBar/Content/StreakBox/StreakIcon") as TextureRect
@onready var streak_label: Label = get_node_or_null("Control/TopBar/Content/StreakBox/StreakLabel") as Label

# Elementos de Status
@onready var board_count_label: Label = get_node_or_null("Control/BoardCountLabel")
@onready var region_label: Label = get_node_or_null("Control/RegionLabel")

# Elementos de Vida (HP - Canto Inferior Direito)
@onready var health_label: Label = get_node_or_null("Control/HealthWidget/Content/VBox/Header/HealthLabel")
@onready var health_bar: ProgressBar = get_node_or_null("Control/HealthWidget/Content/VBox/HealthProgressBar")

# Elementos de Loja e Banco
@onready var shop: ShopUI = get_node_or_null("Control/BottomBar/ShopContainer") as ShopUI
@onready var bench: BenchUI = get_node_or_null("Control/BenchPanel/BenchContent/BenchSlots") as BenchUI

# Componentes Modulares de UI
var round_banner_ui: RoundBannerUI
var synergy_panel_ui: SynergyPanelUI
var hud_animator: HUDAnimator

var sell_zone: PanelContainer
var _responsive_ready: bool = false
var _compact_layout: bool = false
var _inspector_tween: Tween
var _milestone_icons: Array[Control] = []

# Propriedades de retrocompatibilidade
var hud_visible: bool:
	get: return hud_animator.hud_visible if hud_animator else true
	set(val):
		if hud_animator: hud_animator.hud_visible = val
var visible_positions: Dictionary:
	get: return hud_animator.visible_positions if hud_animator else {}
var resolution_banner: Control:
	get: return round_banner_ui.resolution_banner if round_banner_ui else null
var synergy_button: Button:
	get: return synergy_panel_ui.synergy_button if synergy_panel_ui else null
var synergy_panel: Control:
	get: return synergy_panel_ui.synergy_panel if synergy_panel_ui else null
var synergy_tooltip: PanelContainer:
	get: return synergy_panel_ui.synergy_tooltip if synergy_panel_ui else null
var spawned_synergy_rows: Array[Control]:
	get: return synergy_panel_ui.spawned_synergy_rows if synergy_panel_ui else []

class MilestoneIcon extends TextureRect:
	var text: String = ""

func _ready() -> void:
	_init_ui_subsystems()
	_apply_button_skins()
	_build_sell_zone()
	_setup_milestones()
	_setup_inspector()
	_setup_start_battle_button()
	_setup_bestiary_modal()
	_responsive_ready = true
	
	if toggle_button:
		toggle_button.pressed.connect(toggle_hud)
		UIStyle.apply_button_skin(toggle_button, UIStyle.BORDER_SLATE)
	
	get_viewport().size_changed.connect(_layout_extra_panels)
	await get_tree().process_frame
	_layout_extra_panels()
	_cache_panel_positions()
	_play_hud_transition(true, true)

func _init_ui_subsystems() -> void:
	round_banner_ui = RoundBannerUI.new()
	round_banner_ui.setup(hud)
	
	synergy_panel_ui = SynergyPanelUI.new()
	synergy_panel_ui.setup(self, hud)
	synergy_panel_ui.synergy_hover_started.connect(func(n: String) -> void: synergy_hover_started.emit(n))
	synergy_panel_ui.synergy_hover_ended.connect(func() -> void: synergy_hover_ended.emit())
	
	hud_animator = HUDAnimator.new()
	hud_animator.setup(self, hud, top_bar, bottom_bar, bench_panel, health_widget, right_bar, toggle_button)

func _setup_start_battle_button() -> void:
	if start_battle_button != null:
		return
	var content := get_node_or_null("Control/TopBar/Content") as HBoxContainer
	if content:
		start_battle_button = Button.new()
		start_battle_button.name = "StartBattleButton"
		start_battle_button.text = " INICIAR BATALHA"
		start_battle_button.icon = UIAtlasCatalog.get_icon_texture("sword")
		start_battle_button.expand_icon = true
		start_battle_button.custom_minimum_size = Vector2(160, 28)
		start_battle_button.tooltip_text = "Iniciar combate imediatamente (ou pressione Espaço)"
		UIStyle.apply_button_skin(start_battle_button, Color("#2ecc71"))
		content.add_child(start_battle_button)
		start_battle_button.pressed.connect(func() -> void:
			start_battle_requested.emit()
		)

func _setup_milestones() -> void:
	if not milestones_container:
		return
	for child in milestones_container.get_children():
		child.queue_free()
	_milestone_icons.clear()
	
	for i in 5:
		var marker := MilestoneIcon.new()
		marker.name = "Milestone_%d" % (i + 1)
		marker.custom_minimum_size = Vector2(20, 20)
		marker.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		marker.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		marker.mouse_filter = Control.MOUSE_FILTER_STOP
		var is_boss := (i == 4)
		marker.texture = UIAtlasCatalog.get_icon_texture("skull" if is_boss else "gem_orb")
		marker.modulate = Color(0.35, 0.45, 0.52, 0.45)
		marker.text = ""
		milestones_container.add_child(marker)
		_milestone_icons.append(marker)
	
	update_round_display(1, false, 0.0, false, {})

func update_enemy_level(level: int) -> void:
	if not enemy_level_label:
		enemy_level_label = get_node_or_null("Control/TopBar/Content/EnemyBox/EnemyLevelLabel")
	if enemy_level_label:
		enemy_level_label.text = "INIMIGO NV. %d" % level
		enemy_level_label.tooltip_text = "Nível da equipe inimiga: %d\nInimigos evoluem nos marcos regionais." % level

func update_board_capacity(units_on_board: int, board_limit: int) -> void:
	if shop:
		shop.update_board_capacity(units_on_board, board_limit)
	if board_count_label:
		var available := maxi(0, board_limit - units_on_board)
		if available > 0:
			board_count_label.text = "NO CAMPO · %d / %d (! %d VAGA%s LIVRE%s)" % [
				units_on_board, board_limit, available, "S" if available > 1 else "", "S" if available > 1 else ""
			]
			board_count_label.add_theme_color_override("font_color", Color("#f59e0b"))
		else:
			board_count_label.text = "NO CAMPO · %d / %d (CHEIO)" % [units_on_board, board_limit]
			board_count_label.add_theme_color_override("font_color", Color("#cbd5e1"))

func update_round_display(current_round: int, in_combat: bool, time_remaining: float, is_pending: bool, round_outcomes: Dictionary = {}) -> void:
	var stage_index := floori(float(current_round - 1) / 5.0) + 1
	var stage_sub := ((current_round - 1) % 5) + 1
	var stage_text := "%d-%d" % [stage_index, stage_sub]
	
	if round_label:
		round_label.text = stage_text
		round_label.tooltip_text = "Estágio %s · Round total: %d" % [stage_text, current_round]
	
	var legacy_round := get_node_or_null("Control/TopBar/LegacyNodes/RoundLabel") as Label
	if legacy_round:
		legacy_round.text = "Round: %d" % current_round
	
	if phase_label:
		if in_combat:
			phase_label.text = "COMBATE"
			phase_label.add_theme_color_override("font_color", Color("#ff6b6b"))
		elif is_pending:
			phase_label.text = "RESULTADO"
			phase_label.add_theme_color_override("font_color", UIStyle.TEXT_GOLD_BRIGHT)
		else:
			phase_label.text = "PREP"
			phase_label.add_theme_color_override("font_color", UIStyle.TEXT_CYAN)
	
	if timer_label:
		if in_combat:
			timer_label.text = "%02ds" % ceili(time_remaining)
			timer_label.add_theme_color_override("font_color", UIStyle.TEXT_CYAN)
		elif is_pending:
			timer_label.text = "FIM"
			timer_label.add_theme_color_override("font_color", UIStyle.TEXT_GOLD_BRIGHT)
		else:
			timer_label.text = "PREP"
			timer_label.add_theme_color_override("font_color", UIStyle.TEXT_GOLD)

	if start_battle_button:
		if in_combat or is_pending:
			start_battle_button.visible = false
			start_battle_button.disabled = true
		else:
			start_battle_button.visible = true
			start_battle_button.disabled = false
			start_battle_button.text = " INICIAR BATALHA"
			start_battle_button.icon = UIAtlasCatalog.get_icon_texture("sword")
			start_battle_button.expand_icon = true

	if not _milestone_icons.is_empty():
		var active_step := ((current_round - 1) % 5)
		for i in _milestone_icons.size():
			var icon := _milestone_icons[i] as MilestoneIcon
			var is_boss := (i == 4)
			var round_for_step := (stage_index - 1) * 5 + 1 + i
			if i < active_step:
				var won: bool = round_outcomes.get(round_for_step, true)
				icon.text = ""
				if is_boss:
					icon.texture = UIAtlasCatalog.get_icon_texture("star" if won else "skull")
				else:
					icon.texture = UIAtlasCatalog.get_button_texture("check" if won else "cross")
				var col := Color("#2ecc71") if won else Color("#e74c3c")
				icon.modulate = col
				icon.add_theme_color_override("font_color", col)
				icon.tooltip_text = "Round %d: %s" % [round_for_step, "Vitória" if won else "Derrota"]
			elif i == active_step:
				icon.text = ""
				icon.texture = UIAtlasCatalog.get_icon_texture("skull" if is_boss else "gem_orb")
				var col := UIStyle.BORDER_CYAN if in_combat else UIStyle.TEXT_GOLD_BRIGHT
				icon.modulate = col
				icon.add_theme_color_override("font_color", col)
				icon.tooltip_text = "Round %d: Em andamento (%s)" % [round_for_step, "Combate" if in_combat else "Preparação"]
			else:
				icon.text = ""
				icon.texture = UIAtlasCatalog.get_icon_texture("skull" if is_boss else "gem_orb")
				var col := Color(0.35, 0.45, 0.52, 0.45)
				icon.modulate = col
				icon.add_theme_color_override("font_color", col)
				icon.tooltip_text = "Round %d: %s" % [round_for_step, "Chefe Regional" if is_boss else "Próximo Combate"]

func update_player_stats(gold: int, health: int, level: int, xp: int, required_xp: int) -> void:
	var is_max_level := level >= 9
	if shop:
		shop.update_player_info(gold, level, xp, required_xp, is_max_level)
	
	if health_label:
		health_label.text = "%d" % health
		if health >= 60:
			health_label.add_theme_color_override("font_color", UIStyle.TEXT_HEALTH)
		elif health >= 30:
			health_label.add_theme_color_override("font_color", Color("#f39c12"))
		else:
			health_label.add_theme_color_override("font_color", Color("#e74c3c"))
	
	if health_bar:
		health_bar.max_value = 100
		health_bar.value = clampi(health, 0, 100)
		var fill_style := health_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if fill_style:
			if health >= 60:
				fill_style.bg_color = UIStyle.TEXT_HEALTH
			elif health >= 30:
				fill_style.bg_color = Color("#f39c12")
			else:
				fill_style.bg_color = Color("#e74c3c")
	
	var leg_gold := get_node_or_null("Control/TopBar/LegacyNodes/GoldLabel") as Label
	if leg_gold: leg_gold.text = "Ouro: %d" % gold
	var leg_hp := get_node_or_null("Control/TopBar/LegacyNodes/HealthLabel") as Label
	if leg_hp: leg_hp.text = "HP: %d" % health
	var leg_lvl := get_node_or_null("Control/TopBar/LegacyNodes/LevelLabel") as Label
	if leg_lvl: leg_lvl.text = "Nível %d" % level

func update_streak(win_streak: int, loss_streak: int) -> void:
	if not streak_label:
		streak_label = get_node_or_null("Control/TopBar/Content/StreakBox/StreakLabel") as Label
	if not streak_icon:
		streak_icon = get_node_or_null("Control/TopBar/Content/StreakBox/StreakIcon") as TextureRect
	if not streak_label:
		return
	
	if win_streak > 0:
		var bonus := _calc_streak_bonus(win_streak)
		streak_label.text = "%dV (+%dg)" % [win_streak, bonus]
		streak_label.add_theme_color_override("font_color", Color("#2ecc71"))
		if streak_icon: streak_icon.texture = UIAtlasCatalog.get_icon_texture("lightning")
		streak_label.tooltip_text = "Sequência de Vitórias: %d consecutivas (+%dg)" % [win_streak, bonus]
	elif loss_streak > 0:
		var bonus := _calc_streak_bonus(loss_streak)
		streak_label.text = "%dD (+%dg)" % [loss_streak, bonus]
		streak_label.add_theme_color_override("font_color", Color("#e74c3c"))
		if streak_icon: streak_icon.texture = UIAtlasCatalog.get_icon_texture("skull")
		streak_label.tooltip_text = "Sequência de Derrotas: %d consecutivas (+%dg)" % [loss_streak, bonus]
	else:
		streak_label.text = "0 STREAK"
		streak_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 1))
		if streak_icon: streak_icon.texture = UIAtlasCatalog.get_icon_texture("lightning")
		streak_label.tooltip_text = "Sequência de Rounds: Nenhuma ativa"

func _calc_streak_bonus(s: int) -> int:
	if s >= 5: return 3
	elif s >= 3: return 2
	elif s >= 1: return 1
	return 0

func show_round_resolution_banner(outcome_title: String, earned_gold: int, is_draw: bool, player_won: bool, round_gold: int = 0, streak_gold: int = 0, interest_gold: int = 0) -> void:
	if round_banner_ui:
		round_banner_ui.show_banner(earned_gold, is_draw, player_won, round_gold, streak_gold, interest_gold)

func toggle_hud() -> void:
	if hud_animator:
		var is_vis: bool = hud_animator.toggle_hud(func() -> void:
			if synergy_panel_ui: synergy_panel_ui.hide_tooltip()
		)
		hud_visibility_changed.emit(is_vis)

func _cache_panel_positions() -> void:
	if hud_animator:
		hud_animator.cache_panel_positions()

func _play_hud_transition(show_hud: bool, initial: bool = false) -> void:
	if hud_animator:
		hud_animator.play_hud_transition(show_hud, initial)

func _set_hidden_positions() -> void:
	if hud_animator:
		hud_animator.set_hidden_positions()

func _apply_button_skins() -> void:
	var btn := hud.get_node_or_null("SynergyToggleButton") as Button
	if btn:
		UIStyle.apply_button_skin(btn, UIStyle.BORDER_GOLD)

func get_sell_zone() -> Control:
	return sell_zone

func set_sell_zone_visible(p_visible: bool) -> void:
	if is_instance_valid(sell_zone):
		sell_zone.visible = p_visible

func update_synergies(synergies: Array) -> void:
	if synergy_panel_ui:
		synergy_panel_ui.update_synergies(synergies)

func _on_synergy_row_hover_started(synergy: Dictionary, row: Control) -> void:
	if synergy_panel_ui:
		synergy_panel_ui._on_synergy_row_hover_started(synergy, row)

func _on_synergy_row_hover_ended() -> void:
	if synergy_panel_ui:
		synergy_panel_ui._on_synergy_row_hover_ended()

func _fit_synergy_height() -> void:
	if synergy_panel_ui:
		synergy_panel_ui.fit_height()

func _build_sell_zone() -> void:
	sell_zone = PanelContainer.new()
	sell_zone.name = "SellDropZone"
	sell_zone.mouse_filter = Control.MOUSE_FILTER_STOP
	sell_zone.custom_minimum_size = Vector2(260, 56)
	sell_zone.size = sell_zone.custom_minimum_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#4a1b1b", 0.96)
	style.border_color = Color("#e74c3c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.shadow_color = Color(0, 0, 0, 0.4)
	style.shadow_size = 6
	sell_zone.add_theme_stylebox_override("panel", style)
	var label := _make_info_label("VENDER UNIDADE\nSolte aqui ou pressione S", 13, Color("#ffe6ca"))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sell_zone.add_child(label)
	hud.add_child(sell_zone)
	sell_zone.hide()

func _make_info_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("#0a0f14"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func _layout_extra_panels() -> void:
	if not is_instance_valid(hud) or not _responsive_ready:
		return
	if hud_animator and hud_animator.hud_tween and hud_animator.hud_tween.is_running():
		hud_animator.hud_tween.kill()
	if _inspector_tween and _inspector_tween.is_running():
		_inspector_tween.kill()
	
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var metrics := ResponsiveLayout.battle_metrics(viewport_size)
	var compact: bool = metrics["compact"]
	
	var top_w := minf(640.0, viewport_size.x - 40.0)
	ResponsiveLayout.place(top_bar, Rect2((viewport_size.x - top_w) * 0.5, 12.0, top_w, 56.0))
	
	if is_instance_valid(resolution_banner):
		var banner_w := minf(340.0, viewport_size.x - 40.0)
		ResponsiveLayout.place(resolution_banner, Rect2((viewport_size.x - banner_w) * 0.5, 74.0, banner_w, 54.0))
	
	if is_instance_valid(synergy_button):
		ResponsiveLayout.place(synergy_button, Rect2(14.0, 12.0, 140.0, 36.0))
	if is_instance_valid(synergy_panel):
		ResponsiveLayout.place(synergy_panel, Rect2(14.0, 54.0, 240.0, 70.0))
		if compact != _compact_layout:
			synergy_panel.visible = not compact
	_compact_layout = compact
	_fit_synergy_height()
	
	ResponsiveLayout.place(toggle_button, Rect2(viewport_size.x - 68.0, 12.0, 54.0, 36.0))
	var pause := get_node_or_null("PauseButton") as Button
	if pause:
		pause.custom_minimum_size.y = 36.0
		ResponsiveLayout.place(pause, Rect2(viewport_size.x - 180.0, 12.0, 106.0, 36.0))
		UIStyle.apply_button_skin(pause, UIStyle.BORDER_SLATE)
	
	if bench_panel:
		bench_panel.visible = false
		bench_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var bar_margin_x := 18.0 if not compact else 8.0
	var bar_margin_bottom := 10.0
	var shop_h: float = metrics["shop_height"]
	var shop_top: float = viewport_size.y - shop_h - bar_margin_bottom
	var bar_w := viewport_size.x - (bar_margin_x * 2.0)
	ResponsiveLayout.place(bottom_bar, Rect2(bar_margin_x, shop_top, bar_w, shop_h))
	
	var controls := bottom_bar.get_node_or_null("ControlsContainer") as Control
	var gold_cont := bottom_bar.get_node_or_null("GoldContainer") as Control
	var shop_btn := bottom_bar.get_node_or_null("ShopLabel") as Control
	var lock_btn := bottom_bar.get_node_or_null("LockButton") as Button
	if not lock_btn and controls:
		lock_btn = controls.get_node_or_null("LockButton") as Button
	
	var controls_w := 216.0
	if controls: ResponsiveLayout.place(controls, Rect2(16.0, 46.0, controls_w, shop_h - 54.0))
	if gold_cont: ResponsiveLayout.place(gold_cont, Rect2(16.0, 10.0, 104.0, 32.0))
	if lock_btn: ResponsiveLayout.place(lock_btn, Rect2(126.0, 10.0, 106.0, 32.0))
	if shop_btn: ResponsiveLayout.place(shop_btn, Rect2(bar_w - 78.0, shop_h - 40.0, 68.0, 30.0))
	
	var shop_left := controls_w + 26.0 if not compact else 14.0
	var shop_right_margin := 88.0 if not compact else 14.0
	var shop_w := maxf(480.0, bar_w - shop_left - shop_right_margin)
	if shop: shop.fit_shop(Rect2(shop_left, 8.0, shop_w, shop_h - 16.0))
	
	if health_widget:
		var hp_w := 160.0
		var hp_h := 54.0
		var hp_x := viewport_size.x - hp_w - 20.0
		var hp_y := shop_top - hp_h - 12.0
		ResponsiveLayout.place(health_widget, Rect2(hp_x, hp_y, hp_w, hp_h))
	
	if is_instance_valid(sell_zone):
		ResponsiveLayout.place(sell_zone, Rect2((viewport_size.x - 280.0) * 0.5, shop_top - 68.0, 280.0, 56.0))
	
	var inspector_w := minf(310.0, viewport_size.x - 20.0)
	ResponsiveLayout.place(right_bar, Rect2(viewport_size.x - inspector_w - 10.0, 70.0, inspector_w, maxf(shop_top - 80.0, 100.0)))
	var close_btn := right_bar.get_node_or_null("CloseButton") as Button
	if close_btn:
		close_btn.position = Vector2(right_bar.size.x - 34.0, 8.0)
	
	_cache_panel_positions()
	if not hud_visible:
		_set_hidden_positions()
	hud.visible = hud_visible
	hud.modulate.a = 1.0 if hud_visible else 0.0

func _setup_inspector() -> void:
	if not right_bar:
		return
	var panel_style := UIStyle.make_panel_style(UIStyle.BG_DARK, UIStyle.BORDER_GOLD, 2, 6)
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 8
	right_bar.add_theme_stylebox_override("panel", panel_style)
	
	var frame := right_bar.get_node_or_null("PanelFrame") as CanvasItem
	if frame: frame.visible = false
	var vbox := right_bar.find_child("VBoxContainer", true, false) as Control
	if vbox:
		vbox.grow_vertical = Control.GROW_DIRECTION_END
		vbox.offset_left = 14.0
		vbox.offset_top = 14.0
		vbox.offset_right = -14.0
		vbox.offset_bottom = -14.0
		
		bestiary_button = right_bar.find_child("BestiaryButton", true, false) as Button
		if not bestiary_button:
			bestiary_button = Button.new()
			bestiary_button.name = "BestiaryButton"
			bestiary_button.text = " Ver no Bestiário"
			bestiary_button.icon = UIAtlasCatalog.get_icon_texture("scroll_horn")
			bestiary_button.expand_icon = true
			bestiary_button.custom_minimum_size = Vector2(0, 36)
			UIStyle.apply_button_skin(bestiary_button, UIStyle.BORDER_GOLD)
			bestiary_button.pressed.connect(open_bestiary_inspected)
			vbox.add_child(bestiary_button)
			vbox.move_child(bestiary_button, -1)
	
	var close_btn := right_bar.get_node_or_null("CloseButton") as Button
	if not close_btn:
		close_btn = Button.new()
		close_btn.name = "CloseButton"
		close_btn.icon = UIAtlasCatalog.get_button_texture("cross")
		close_btn.expand_icon = true
		close_btn.text = ""
		close_btn.custom_minimum_size = Vector2(26.0, 26.0)
		close_btn.size = Vector2(26.0, 26.0)
		close_btn.position = Vector2(right_bar.size.x - 34.0, 8.0)
		UIStyle.apply_button_skin(close_btn, UIStyle.BORDER_SLATE)
		close_btn.pressed.connect(hide_inspector)
		right_bar.add_child(close_btn)
	else:
		close_btn.icon = UIAtlasCatalog.get_button_texture("cross")
		close_btn.expand_icon = true
		close_btn.text = ""
	close_btn.z_index = 5
	right_bar.move_child(close_btn, -1)

	var origins_lbl := right_bar.find_child("Origins_label", true, false) as RichTextLabel
	if origins_lbl and not origins_lbl.meta_hover_started.is_connected(_on_inspector_meta_hover_started):
		origins_lbl.meta_hover_started.connect(_on_inspector_meta_hover_started.bind(origins_lbl))
		origins_lbl.meta_hover_ended.connect(_on_inspector_meta_hover_ended)

	var classes_lbl := right_bar.find_child("Classes_label", true, false) as RichTextLabel
	if classes_lbl and not classes_lbl.meta_hover_started.is_connected(_on_inspector_meta_hover_started):
		classes_lbl.meta_hover_started.connect(_on_inspector_meta_hover_started.bind(classes_lbl))
		classes_lbl.meta_hover_ended.connect(_on_inspector_meta_hover_ended)

func _on_inspector_meta_hover_started(meta: Variant, source_label: Control) -> void:
	if synergy_panel_ui:
		synergy_panel_ui.show_inspector_tooltip(str(meta), source_label, right_bar)

func _on_inspector_meta_hover_ended(_meta: Variant = null) -> void:
	if synergy_panel_ui:
		synergy_panel_ui.hide_tooltip()

func show_inspector() -> void:
	if not right_bar:
		return
	_layout_extra_panels()
	right_bar.show()
	var destination: Vector2 = visible_positions.get(right_bar, right_bar.position)
	right_bar.position.x = get_viewport().get_visible_rect().size.x
	if _inspector_tween and _inspector_tween.is_running():
		_inspector_tween.kill()
	_inspector_tween = create_tween()
	_inspector_tween.set_trans(Tween.TRANS_CUBIC)
	_inspector_tween.set_ease(Tween.EASE_OUT)
	_inspector_tween.tween_property(right_bar, "position", destination, 0.25)

func hide_inspector(immediate: bool = false) -> void:
	if synergy_panel_ui:
		synergy_panel_ui.hide_tooltip()
	if not right_bar or not right_bar.visible:
		return
	if _inspector_tween and _inspector_tween.is_running():
		_inspector_tween.kill()
	if immediate:
		right_bar.hide()
		return
	var viewport_w := get_viewport().get_visible_rect().size.x
	_inspector_tween = create_tween()
	_inspector_tween.set_trans(Tween.TRANS_CUBIC)
	_inspector_tween.set_ease(Tween.EASE_IN)
	_inspector_tween.tween_property(right_bar, "position:x", viewport_w + 20.0, 0.2)
	_inspector_tween.tween_callback(right_bar.hide)

func _setup_bestiary_modal() -> void:
	if not is_instance_valid(bestiary_modal):
		bestiary_modal = BestiaryModal.new()
		add_child(bestiary_modal)

func set_inspected_unit_data(stats: UnitStats, star_level: int = 1) -> void:
	_inspected_unit_stats = stats
	_inspected_unit_star_level = star_level

func open_bestiary_inspected() -> void:
	if _inspected_unit_stats:
		open_bestiary(_inspected_unit_stats, _inspected_unit_star_level)

func open_bestiary(stats: UnitStats, star_level: int = 1) -> void:
	if not is_instance_valid(bestiary_modal):
		_setup_bestiary_modal()
	if is_instance_valid(bestiary_modal):
		bestiary_modal.open_for_unit(stats, star_level)
