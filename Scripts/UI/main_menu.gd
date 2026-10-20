extends Control

const Regions = preload("res://Scripts/Systems/region_rosters.gd")
const Store = preload("res://Scripts/Systems/campaign_store.gd")
const Overlay = preload("res://Scripts/UI/game_overlay.gd")
const BattleTransition = preload("res://Scripts/UI/battle_transition.gd")
const BATTLE_SCENE: PackedScene = preload("res://Scenes/Main/main.tscn")
const PORTRAIT_SHADER: Shader = preload("res://Assets/Shaders/region_portrait.gdshader")
const REGION_ORDER := ["mata_atlantica", "cerrado", "pantanal", "amazonia", "caatinga", "litoral"]

var _selected_index: int = 1
var _starting: bool = false
var _selection: Control
var _home: PanelContainer
var _home_content: VBoxContainer
var _stage: Control
var _description: Label
var _status: Label
var _enter_button: Button
var _overlay: Overlay
var _background: TextureRect
var _next_background: TextureRect
var _background_tween: Tween
var _champions: Dictionary = {}
var _cards: Array[Panel] = []
var _portraits: Array[TextureRect] = []
var _previous: Button
var _next: Button

func _ready() -> void:
	get_tree().paused = false
	get_tree().auto_accept_quit = false
	AudioManager.play_menu_music()
	for id in REGION_ORDER:
		_champions[id] = Regions.get_champion(id)
	_build_interface()
	get_viewport().size_changed.connect(_fit_layout)
	_select_region(0)
	_show_home()

func _build_interface() -> void:
	var base := ColorRect.new()
	base.color = Color("#101e24")
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(base)
	_background = _make_background()
	_next_background = _make_background()
	_next_background.modulate.a = 0.0
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.03, 0.75)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	_home = PanelContainer.new()
	_home.add_theme_stylebox_override("panel", Overlay.frame())
	add_child(_home)
	var home_content := VBoxContainer.new()
	_home_content = home_content
	home_content.add_theme_constant_override("separation", 18)
	var home_scroll := ScrollContainer.new()
	home_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_home.add_child(home_scroll)
	home_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_scroll.add_child(home_content)
	home_content.add_child(Overlay.label("FOLCHESS", 48, Color("#e4c58a")))
	home_content.add_child(Overlay.label("As lendas esperam por você.", 20))
	home_content.add_child(Overlay.button("Jogar", _show_regions))
	home_content.add_child(Overlay.button("Como jogar", _open_overlay.bind("tutorial")))
	home_content.add_child(Overlay.button("Opções", _open_overlay.bind("options")))
	if not OS.has_feature("web"):
		home_content.add_child(Overlay.button("Sair", func() -> void: get_tree().quit()))
	_selection = Control.new()
	_selection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_selection.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_selection)
	var heading := Overlay.label("ESCOLHA SUA REGIÃO", 34, Color("#e4c58a"))
	heading.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	heading.offset_top = 32
	heading.offset_bottom = 82
	_selection.add_child(heading)
	_stage = Control.new()
	_stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_selection.add_child(_stage)
	_previous = Overlay.button("‹", _select_region.bind(-1))
	_previous.tooltip_text = "Região anterior (←)"
	_previous.add_theme_font_size_override("font_size", 40)
	_selection.add_child(_previous)
	_next = Overlay.button("›", _select_region.bind(1))
	_next.tooltip_text = "Próxima região (→)"
	_next.add_theme_font_size_override("font_size", 40)
	_selection.add_child(_next)
	for arrow in [_previous, _next]:
		for state in ["normal", "hover", "pressed", "focus"]:
			var arrow_style := arrow.get_theme_stylebox(state).duplicate() as StyleBoxFlat
			arrow_style.set_content_margin(SIDE_LEFT, 8.0)
			arrow_style.set_content_margin(SIDE_RIGHT, 8.0)
			arrow.add_theme_stylebox_override(state, arrow_style)
	var footer := VBoxContainer.new()
	footer.name = "Footer"
	footer.add_theme_constant_override("separation", 12)
	_selection.add_child(footer)
	_description = Overlay.label("", 22)
	_description.max_lines_visible = 2
	_description.clip_text = true
	footer.add_child(_description)
	_status = Overlay.label("", 18, Color("#d7c99e"))
	_status.max_lines_visible = 2
	_status.clip_text = true
	footer.add_child(_status)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 18)
	footer.add_child(actions)
	actions.add_child(Overlay.button("Voltar", _show_home))
	_enter_button = Overlay.button("Jogar", _start_selected_region)
	_enter_button.custom_minimum_size.x = 310
	actions.add_child(_enter_button)
	_overlay = Overlay.new()
	add_child(_overlay)
	_overlay.closed.connect(_focus_current)

func _make_background() -> TextureRect:
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(picture)
	return picture

func _select_region(direction: int) -> void:
	if _starting:
		return
	if direction != 0:
		AudioManager.play_ui_choose()
	_selected_index = posmod(_selected_index + direction, REGION_ORDER.size())
	var id: String = REGION_ORDER[_selected_index]
	var region: Dictionary = Regions.get_region(id)
	var champion: UnitStats = _champions[id]
	_change_background(champion.icon if champion else null)
	for card in _cards:
		_stage.remove_child(card)
		card.queue_free()
	_cards.clear()
	_portraits.clear()
	for offset in [-1, 0, 1]:
		_add_card(posmod(_selected_index + offset, REGION_ORDER.size()), offset)
	_description.text = region["description"]
	var slot := Store.read_slot(id)
	var state: String = slot.get("state", "new")
	_enter_button.disabled = slot.has("error")
	if slot.has("error"):
		_enter_button.text = "Campanha indisponível"
		_status.text = slot["error"]
	elif state == "active":
		_enter_button.text = "Continuar · Round %d" % int(slot["run"].get("round", 1))
		_status.text = "Progresso salvo nesta região. As outras campanhas permanecem guardadas."
	else:
		_enter_button.text = "Jogar novamente" if state == "won" else ("Tentar novamente" if state == "lost" else "Iniciar campanha")
		_status.text = "Vença a formação inimiga de nível 9 para concluir a região."
	_fit_layout()

func _add_card(index: int, offset: int) -> void:
	var id: String = REGION_ORDER[index]
	var region: Dictionary = Regions.get_region(id)
	var champion: UnitStats = _champions[id]
	# A moldura tem dimensões próprias. Textos ainda sem largura definida não
	# podem aumentar a altura mínima do cartão durante a troca de região.
	var card := Panel.new()
	card.clip_contents = true
	card.add_theme_stylebox_override("panel", Overlay.frame(region["color"]))
	card.modulate = Color.WHITE if offset == 0 else Color(0.77, 0.8, 0.8, 0.96)
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if offset != 0 else Control.CURSOR_ARROW
	card.gui_input.connect(func(event: InputEvent) -> void:
		if offset != 0 and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_select_region(offset)
	)
	_stage.add_child(card)
	_cards.append(card)
	var portrait := TextureRect.new()
	portrait.texture = champion.icon if champion else null
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var portrait_material := ShaderMaterial.new()
	portrait_material.shader = PORTRAIT_SHADER
	portrait_material.set_shader_parameter("ring_color", region["color"])
	portrait.material = portrait_material
	card.add_child(portrait)
	_portraits.append(portrait)
	_add_card_label(card, "RegionName", region["name"], 30 if offset == 0 else 25, region["color"])
	_add_card_label(card, "ChampionName", champion.unit_name if champion else "", 20)
	var slot := Store.read_slot(id)
	var badge := "NOVA CAMPANHA"
	var completed := bool(slot.get("completed", false))
	if completed:
		badge = "✓ REGIÃO CONCLUÍDA"
	if slot.get("state", "") == "active":
		badge = (badge + "\n") if completed else ""
		badge += "EM ANDAMENTO · R%d\n%d HP · Nível %d" % [int(slot["run"].get("round", 1)), int(slot["run"].get("health", 100)), int(slot["run"].get("level", 1))]
	elif slot.get("state", "") == "lost":
		badge = (badge + "\n") if completed else ""
		badge += "ÚLTIMA CAMPANHA ENCERRADA"
	if slot.has("error"):
		badge = "ERRO AO LER CAMPANHA"
	_add_card_label(card, "CampaignStatus", badge, 18, Color("#e6d5a9"))

func _add_card_label(card: Panel, node_name: String, text: String, font_size: int, color: Color = Color("#e5e8dd")) -> void:
	var label := Overlay.label(text, font_size, color)
	label.name = node_name
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(label)
	# O cartão recebe o hover; todos os textos completos ficam disponíveis nele.
	card.tooltip_text += ("\n" if not card.tooltip_text.is_empty() else "") + text

func _fit_card_content(index: int, card_size: Vector2) -> void:
	var card := _cards[index]
	var small := card_size.y < 420.0
	var name_height := 38.0 if not small else 32.0
	var champion_height := 28.0
	var status_height := 72.0
	var gap := 16.0 if not small else 10.0
	var text_height := name_height + champion_height + status_height + gap * 3.0
	var portrait_size := maxf(32.0, minf(card_size.x - 56.0, minf(card_size.y * 0.38, card_size.y - text_height - 32.0)))
	var content_height := portrait_size + text_height
	var top := maxf(16.0, (card_size.y - content_height) * 0.5)
	var portrait := _portraits[index]
	portrait.custom_minimum_size = Vector2.ZERO
	portrait.size = Vector2.ONE * portrait_size
	portrait.position = Vector2((card_size.x - portrait_size) * 0.5, top)
	var text_top := top + portrait_size + gap
	var region_name := card.get_node("RegionName") as Label
	region_name.add_theme_font_size_override("font_size", 26 if small else (30 if index == 1 else 25))
	ResponsiveLayout.place(region_name, Rect2(18, text_top, card_size.x - 36.0, name_height))
	text_top += name_height + gap
	ResponsiveLayout.place(card.get_node("ChampionName") as Label, Rect2(18, text_top, card_size.x - 36.0, champion_height))
	text_top += champion_height + gap
	ResponsiveLayout.place(card.get_node("CampaignStatus") as Label, Rect2(18, text_top, card_size.x - 36.0, status_height))

func _change_background(texture: Texture2D) -> void:
	if _background_tween and _background_tween.is_valid():
		_background_tween.kill()
		_background.texture = _next_background.texture
	if not _background.texture:
		_background.texture = texture
	_next_background.texture = texture
	_next_background.modulate.a = 0.0
	_background_tween = create_tween()
	_background_tween.tween_property(_next_background, "modulate:a", 1.0, 0.45)
	_background_tween.tween_callback(func() -> void:
		_background.texture = texture
		_next_background.modulate.a = 0.0
	)

func _fit_layout() -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var compact := viewport_size.x < 1100.0
	_home.size = Vector2(minf(500.0, viewport_size.x - 32.0), minf(520.0, viewport_size.y - 32.0))
	_home.position = (viewport_size - _home.size) * 0.5
	var footer := _selection.get_node("Footer") as VBoxContainer
	footer.position = Vector2(24.0, viewport_size.y - 202.0)
	footer.size = Vector2(viewport_size.x - 48.0, 178.0)
	_stage.position = Vector2(80.0, 110.0)
	_stage.size = Vector2(maxf(viewport_size.x - 160.0, 200.0), maxf(viewport_size.y - 330.0, 200.0))
	var width := minf(440.0, _stage.size.x if compact else _stage.size.x / 2.85)
	var height := minf(650.0, _stage.size.y)
	for i in _cards.size():
		var side := i != 1
		_cards[i].visible = not compact or not side
		var card_size := Vector2(width * (0.8 if side else 1.0), height * (0.82 if side else 1.0))
		var center_x := _stage.size.x * 0.5 + float(i - 1) * (width * 0.95 + 24.0)
		_cards[i].size = card_size
		_cards[i].position = Vector2(center_x - card_size.x * 0.5, (_stage.size.y - card_size.y) * 0.5)
		_fit_card_content(i, card_size)
	_previous.position = Vector2(18.0, 110.0 + _stage.size.y * 0.5 - 34.0)
	_next.position = Vector2(viewport_size.x - 78.0, _previous.position.y)
	_previous.size = Vector2(60.0, 68.0)
	_next.size = _previous.size

func _show_regions() -> void:
	_home.hide()
	_selection.show()
	_select_region(0)
	_enter_button.grab_focus()

func _show_home() -> void:
	if _selection.visible:
		AudioManager.play_ui_cancel()
	_selection.hide()
	_home.show()
	_fit_layout()
	_focus_current()

func _focus_current() -> void:
	if _selection.visible:
		_enter_button.grab_focus()
	else:
		_home_content.get_child(2).grab_focus()

func _open_overlay(mode: String) -> void:
	_overlay.open(mode)

func _input(event: InputEvent) -> void:
	if _overlay.is_open or _starting or not _selection.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT: _select_region(-1)
			KEY_RIGHT: _select_region(1)
			KEY_ESCAPE: _show_home()
			_: return
		get_viewport().set_input_as_handled()

func _start_selected_region() -> void:
	if _starting:
		return
	_starting = true
	_enter_button.disabled = true
	_enter_button.text = "Carregando…"
	_enter_region.call_deferred(REGION_ORDER[_selected_index])

func _enter_region(id: String) -> void:
	AudioManager.stop_music()
	var transition := BattleTransition.new()
	get_tree().root.add_child(transition)
	await transition.fade_to_black()
	var battle := BATTLE_SCENE.instantiate()
	battle.set("region_id", id)
	battle.set("entry_transition", transition)
	var tree := get_tree()
	tree.root.add_child(battle)
	transition.reparent(battle)
	tree.current_scene = battle
	queue_free()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
