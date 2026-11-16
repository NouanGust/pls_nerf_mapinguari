extends CanvasLayer

signal resume_requested
signal menu_requested
signal quit_requested
signal closed

const TUTORIAL := [
	["1 · Monte seu time", "Clique em uma carta da loja para comprar e enviar a unidade ao banco. Na preparação, você também pode arrastar a carta diretamente para um hex vazio do seu lado.\n\nR atualiza a loja por 2 de ouro. L trava as ofertas para o próximo round."],
	["2 · Posicione e venda", "Arraste as unidades do banco para os hexágonos do jogador. O destaque mostra o alcance de ataque durante o posicionamento. Cada nível permite uma peça no campo, até 9.\n\nPara vender, passe o mouse sobre a unidade e pressione S, ou arraste para a zona de venda. Durante o combate, só as unidades do banco podem ser vendidas; compras vão para o banco."],
	["3 · Evolua suas unidades", "Três cópias da mesma unidade e da mesma estrela se combinam em uma unidade da próxima estrela, até 4 estrelas. Ao alcançar 4 estrelas, essa unidade deixa de aparecer na loja enquanto você a possuir.\n\nTrios formados durante o combate evoluem na preparação seguinte. O brilho na loja indica uma compra que permite evoluir."],
	["4 · Origens e funções", "Cada unidade possui exatamente duas origens e uma função de combate. Combine unidades diferentes que compartilham a mesma origem para ativar seus patamares de sinergia (Seiva, Vigília, Correnteza, Vozes, Ferocidade, Travessia, Assombro, Encanto e Fulgor). As origens beneficiam seus próprios integrantes.\n\nPasse o mouse sobre a sinergia na lateral para conhecer seus integrantes e efeitos. Clique com o botão direito em uma unidade para inspecionar seus atributos e habilidades em tempo real.\n\nEscudos absorvem dano até o teto global de 40% da vida máxima."],
	["5 · Combata e ganhe experiência", "Pressione Espaço para começar o combate automático. Ao final, consulte o relatório de dano, cura e dano recebido. A batalha dura até 60 segundos: se ninguém vencer, ocorre empate, com metade do dano ao jogador e metade da recompensa de vitória.\n\nVocê recebe 2 XP por round. Q compra 4 XP por 4 de ouro. O nível máximo é 9.\n\nO inimigo cresce nos rounds 3, 5, 7, 9, 12, 15, 18 e 21, evolui estrelas e muda de formação a cada round. Vencer a formação de nível 9 conclui a região."],
	["6 · Câmera e pausa", "Segure o botão do meio do mouse para orbitar o tabuleiro e use a roda para aproximar ou afastar. O alterna a órbita automática e Home restaura a câmera. H esconde ou mostra a interface.\n\nEsc ou o botão Pausa abre o menu e congela a batalha. Em Opções, ajuste áudio, tela cheia e câmera. Se estiver arrastando uma peça, Esc primeiro cancela o arraste."],
	["7 · Conquiste as regiões", "Cada região tem sua própria campanha salva automaticamente. Você pode voltar ao menu e continuar outra região sem perder a anterior. Vença a formação inimiga de nível 9 para concluir a região.\n\nAo sair durante uma luta, você retorna à preparação desse mesmo round, mantendo compras, vendas e XP. Ao sair no relatório, o resultado já está salvo e a retomada começa no próximo round. No navegador, mantenha os dados do site para preservar suas campanhas."],
]

var is_open: bool = false
var _in_game: bool = false
var _mode: String = ""
var _page: int = 0
var _match_time: float = 0.0
var _options_tab: String = "graphics"
var _root: Control
var _panel: PanelContainer
var _content: VBoxContainer
var _error: Label

func set_match_time(seconds: float) -> void:
	_match_time = maxf(seconds, 0.0)

static func format_duration(total_seconds: float) -> String:
	var s := int(floor(maxf(total_seconds, 0.0)))
	var hours := s / 3600
	var minutes := (s % 3600) / 60
	var secs := s % 60
	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, secs]
	return "%02d:%02d" % [minutes, secs]

static func frame(color: Color = Color("#947c53")) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#152226")
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(18)
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_content_margin(side, 26.0)
	return style

static func label(text: String, font_size: int = 22, color: Color = Color("#e5e8dd")) -> Label:
	var result := Label.new()
	result.text = text
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

static func button(text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 52
	result.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style := frame(Color("#d7b97d") if state != "normal" else Color("#50645e"))
		style.bg_color = Color("#304441") if state == "hover" else Color("#1b3033")
		style.set_content_margin(SIDE_TOP, 8.0)
		style.set_content_margin(SIDE_BOTTOM, 8.0)
		result.add_theme_stylebox_override(state, style)
	result.pressed.connect(func() -> void:
		var am = result.get_node_or_null("/root/AudioManager")
		if am:
			am.play_ui_click()
		action.call()
	)
	result.mouse_entered.connect(func() -> void:
		var am = result.get_node_or_null("/root/AudioManager")
		if am:
			am.play_ui_hover()
	)
	return result

static func tab_button(text: String, action: Callable, is_active: bool) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 48
	result.add_theme_font_size_override("font_size", 20)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal", "hover", "pressed", "focus"]:
		var border := Color("#f59e0b") if is_active else (Color("#d7b97d") if state == "hover" else Color("#475569"))
		var style := frame(border)
		style.bg_color = Color("#223940") if is_active else (Color("#203338") if state == "hover" else Color("#152226"))
		style.set_content_margin(SIDE_TOP, 8.0)
		style.set_content_margin(SIDE_BOTTOM, 8.0)
		style.set_content_margin(SIDE_LEFT, 12.0)
		style.set_content_margin(SIDE_RIGHT, 12.0)
		result.add_theme_stylebox_override(state, style)
	result.pressed.connect(func() -> void:
		var am = result.get_node_or_null("/root/AudioManager")
		if am:
			am.play_ui_click()
		action.call()
	)
	result.mouse_entered.connect(func() -> void:
		var am = result.get_node_or_null("/root/AudioManager")
		if am:
			am.play_ui_hover()
	)
	return result

static func preset_button(text: String, action: Callable, is_active: bool) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 44
	result.add_theme_font_size_override("font_size", 16)
	result.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for state in ["normal", "hover", "pressed", "focus"]:
		var border := Color("#38bdf8") if is_active else (Color("#7dd3fc") if state == "hover" else Color("#475569"))
		var style := frame(border)
		style.bg_color = Color("#18353f") if is_active else (Color("#1e363e") if state == "hover" else Color("#111f24"))
		style.set_content_margin(SIDE_TOP, 6.0)
		style.set_content_margin(SIDE_BOTTOM, 6.0)
		style.set_content_margin(SIDE_LEFT, 8.0)
		style.set_content_margin(SIDE_RIGHT, 8.0)
		result.add_theme_stylebox_override(state, style)
	result.pressed.connect(func() -> void:
		var am = result.get_node_or_null("/root/AudioManager")
		if am:
			am.play_ui_click()
		action.call()
	)
	result.mouse_entered.connect(func() -> void:
		var am = result.get_node_or_null("/root/AudioManager")
		if am:
			am.play_ui_hover()
	)
	return result

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)
	var shade := ColorRect.new()
	shade.color = Color(0.01, 0.025, 0.03, 0.86)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(shade)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", frame())
	_root.add_child(_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_panel.add_child(scroll)
	_content = VBoxContainer.new()
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.add_theme_constant_override("separation", 18)
	scroll.add_child(_content)
	get_viewport().size_changed.connect(_fit)
	_fit()
	_root.hide()

func _fit() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_panel.size = Vector2(minf(780.0, viewport_size.x - 40.0), minf(780.0, viewport_size.y - 48.0))
	_panel.position = (viewport_size - _panel.size) * 0.5
	# Conteúdo pode rolar; os limites do painel nunca dependem da página aberta.
	for child in _content.get_children():
		if child is Button:
			child.clip_text = true
			child.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

func open(mode: String, in_game: bool = false) -> void:
	_in_game = in_game
	_mode = mode
	is_open = true
	_root.show()
	_render()

func close() -> void:
	is_open = false
	_root.hide()
	closed.emit()

func _clear() -> void:
	for child in _content.get_children():
		_content.remove_child(child)
		child.queue_free()

func _render() -> void:
	_clear()
	match _mode:
		"pause":
			_content.add_child(label("PAUSADO", 36, Color("#e4c58a")))
			var timer_box := PanelContainer.new()
			var timer_style := frame(Color("#38bdf8"))
			timer_style.bg_color = Color("#0e2026")
			for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
				timer_style.set_content_margin(side, 12.0)
			timer_box.add_theme_stylebox_override("panel", timer_style)
			var timer_label := label("TEMPO DE PARTIDA: %s" % format_duration(_match_time), 22, Color("#7dd3fc"))
			timer_box.add_child(timer_label)
			_content.add_child(timer_box)
			_content.add_child(button("Continuar", _resume))
			_content.add_child(button("Opções", open.bind("options", true)))
			_content.add_child(button("Como jogar", open.bind("tutorial", true)))
			_content.add_child(button("Salvar e voltar ao menu", func() -> void: menu_requested.emit()))
			if not OS.has_feature("web"):
				_content.add_child(button("Salvar e sair", func() -> void: quit_requested.emit()))
			_content.add_child(label("Ao retornar de uma luta interrompida, você recomeça a preparação do mesmo round com suas compras preservadas.", 18))
		"options":
			_content.add_child(label("OPÇÕES", 36, Color("#e4c58a")))
			var gs: Node = get_node_or_null("/root/GameSettings")
			
			# Seletor de Abas
			var tab_row := HBoxContainer.new()
			tab_row.add_theme_constant_override("separation", 12)
			_content.add_child(tab_row)
			
			var tab_gfx := tab_button("🖥️ Gráficos & Desempenho", func() -> void:
				_options_tab = "graphics"
				_render()
			, _options_tab == "graphics")
			tab_row.add_child(tab_gfx)
			
			var tab_audio := tab_button("🔊 Áudio & Controles", func() -> void:
				_options_tab = "audio"
				_render()
			, _options_tab == "audio")
			tab_row.add_child(tab_audio)
			
			if _options_tab == "graphics":
				var preset: String = str(gs.get("graphics_preset")) if gs else "balanced"
				var max_fps_val: int = int(gs.get("max_fps")) if gs else 30
				var r_scale: float = float(gs.get("render_scale")) if gs else 0.85
				var shadows: bool = bool(gs.get("shadows_enabled")) if gs else true
				var vsync_val: bool = bool(gs.get("vsync")) if gs else true
				var show_fps_val: bool = bool(gs.get("show_fps")) if gs else false
				var fs_val: bool = bool(gs.get("fullscreen")) if gs else false
				
				# Título de Presets
				var preset_title := label("PRESETS DE DESEMPENHO", 20, Color("#fcd68a"))
				preset_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				_content.add_child(preset_title)
				
				var presets_row := HBoxContainer.new()
				presets_row.add_theme_constant_override("separation", 8)
				_content.add_child(presets_row)
				
				presets_row.add_child(preset_button("⚡ Desempenho", func() -> void:
					_change_setting("graphics_preset", "low")
					_render()
				, preset == "low"))
				
				presets_row.add_child(preset_button("⚖️ Balanceado (30 FPS)", func() -> void:
					_change_setting("graphics_preset", "balanced")
					_render()
				, preset == "balanced"))
				
				presets_row.add_child(preset_button("✨ Alta Qualidade (60 FPS)", func() -> void:
					_change_setting("graphics_preset", "high")
					_render()
				, preset == "high"))
				
				var desc_text := ""
				match preset:
					"low":
						desc_text = "Modo Desempenho: 30 FPS travados, resolução 3D em 65% (FSR) e sem sombras. Máxima fluidez para PCs fracos ou placas integradas."
					"balanced":
						desc_text = "Modo Balanceado: 30 FPS estáveis, resolução 3D em 85% (FSR) e sombras suaves. Recomendado para o hardware atual."
					"high":
						desc_text = "Modo Alta Qualidade: 60 FPS, resolução 3D nativa (100%) e sombras completas. Para máquinas mais potentes."
					_:
						desc_text = "Modo Personalizado: Configurações manuais ativas."
				
				var desc_lbl := label(desc_text, 16, Color("#94a3b8"))
				desc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				_content.add_child(desc_lbl)
				
				# Separador de Ajustes Detalhados
				var manual_title := label("AJUSTES DETALHADOS", 20, Color("#fcd68a"))
				manual_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				_content.add_child(manual_title)
				
				# Slider de Resolução 3D
				_slider_scale("Escala de Resolução 3D (FSR)", "render_scale", r_scale, 0.5, 1.0, 0.05)
				var scale_note := label("Menor resolução 3D alivia a placa de vídeo. Textos, cartas e a interface continuam 100% nítidos.", 15, Color("#64748b"))
				scale_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				_content.add_child(scale_note)
				
				# Limite de FPS
				var fps_title := label("Limite de Quadros (FPS Target)", 20, Color("#e5e8dd"))
				fps_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
				_content.add_child(fps_title)
				
				var fps_row := HBoxContainer.new()
				fps_row.add_theme_constant_override("separation", 8)
				_content.add_child(fps_row)
				
				fps_row.add_child(preset_button("30 FPS (Recomendado)", func() -> void:
					_change_setting("max_fps", 30)
					_render()
				, max_fps_val == 30))
				
				fps_row.add_child(preset_button("60 FPS", func() -> void:
					_change_setting("max_fps", 60)
					_render()
				, max_fps_val == 60))
				
				fps_row.add_child(preset_button("Ilimitado", func() -> void:
					_change_setting("max_fps", 0)
					_render()
				, max_fps_val == 0))
				
				# Toggles
				_check("Sombras 3D do Tabuleiro", "shadows_enabled", shadows)
				_check("Sincronização Vertical (V-Sync)", "vsync", vsync_val)
				_check("Exibir Contador de FPS no Canto Superior (F7)", "show_fps", show_fps_val)
				_check("Tela cheia", "fullscreen", fs_val, OS.has_feature("web"))
				
			else:
				var vol: float = float(gs.get("volume")) if gs else 0.8
				var m_vol: float = float(gs.get("music_volume")) if gs else 0.8
				var s_vol: float = float(gs.get("sfx_volume")) if gs else 0.8
				var ao: bool = bool(gs.get("auto_orbit")) if gs else false
				var sens: float = float(gs.get("mouse_sensitivity")) if gs else 0.25
				var caatinga_real: bool = (str(gs.get("caatinga_board_variant")) == "realista") if gs else false
				
				_slider("Volume geral", "volume", vol, 0.0, 1.0, 0.01)
				_slider("Música", "music_volume", m_vol, 0.0, 1.0, 0.01)
				_slider("Efeitos sonoros", "sfx_volume", s_vol, 0.0, 1.0, 0.01)
				_check("Orbitar câmera automaticamente", "auto_orbit", ao)
				_slider("Sensibilidade da câmera", "mouse_sensitivity", sens, 0.05, 1.0, 0.05)
				_check("Tabuleiro da Caatinga: Versão Realista", "caatinga_board_variant", caatinga_real)
			
			_content.add_child(button("Voltar", _back))
		"tutorial":
			_content.add_child(label("COMO JOGAR", 34, Color("#e4c58a")))
			_content.add_child(label(TUTORIAL[_page][0], 26))
			var body := label(TUTORIAL[_page][1], 22)
			body.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			_content.add_child(body)
			_content.add_child(label("%d / %d" % [_page + 1, TUTORIAL.size()], 18))
			var navigation := HBoxContainer.new()
			navigation.add_theme_constant_override("separation", 12)
			_content.add_child(navigation)
			var previous := button("Anterior", _turn_page.bind(-1))
			previous.disabled = _page == 0
			previous.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			navigation.add_child(previous)
			var next := button("Próximo", _turn_page.bind(1))
			next.disabled = _page == TUTORIAL.size() - 1
			next.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			navigation.add_child(next)
			_content.add_child(button("Voltar", _back))
	_error = label("", 18, Color("#ffbba0"))
	_content.add_child(_error)
	_fit()
	for child in _content.get_children():
		if child is Button:
			child.grab_focus()
			break

func _slider(title: String, key: String, value: float, minimum: float, maximum: float, step: float) -> void:
	var caption := label("%s · %.0f%%" % [title, value * 100.0], 22)
	_content.add_child(caption)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.custom_minimum_size.y = 36
	slider.value_changed.connect(func(amount: float) -> void:
		caption.text = "%s · %.0f%%" % [title, amount * 100.0]
		_change_setting(key, amount)
	)
	_content.add_child(slider)

func _slider_scale(title: String, key: String, value: float, minimum: float, maximum: float, step: float) -> void:
	var caption := label("%s · %.0f%%" % [title, value * 100.0], 20, Color("#7dd3fc"))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_content.add_child(caption)
	var slider := HSlider.new()
	slider.min_value = minimum
	slider.max_value = maximum
	slider.step = step
	slider.value = value
	slider.custom_minimum_size.y = 36
	slider.value_changed.connect(func(amount: float) -> void:
		caption.text = "%s · %.0f%%" % [title, amount * 100.0]
		_change_setting(key, amount)
	)
	_content.add_child(slider)

func _check(title: String, key: String, value: bool, disabled: bool = false) -> void:
	var check := CheckButton.new()
	check.text = title
	check.button_pressed = value
	check.disabled = disabled
	check.custom_minimum_size.y = 48
	check.add_theme_font_size_override("font_size", 22)
	check.toggled.connect(func(enabled: bool) -> void: _change_setting(key, enabled))
	_content.add_child(check)

func _change_setting(key: String, value: Variant) -> void:
	var gs: Node = get_node_or_null("/root/GameSettings")
	if gs and gs.has_method("update_setting"):
		gs.update_setting(key, value)
		_error.text = "Não foi possível gravar as opções neste dispositivo." if gs.get("last_error") != OK else ""

func show_error(message: String) -> void:
	if not is_open:
		open("pause", true)
	_error.text = message

func _turn_page(direction: int) -> void:
	_page = clampi(_page + direction, 0, TUTORIAL.size() - 1)
	_render()

func _resume() -> void:
	close()
	resume_requested.emit()

func _back() -> void:
	var am = get_node_or_null("/root/AudioManager")
	if am:
		am.play_ui_cancel()
	if _in_game:
		open("pause", true)
	else:
		close()

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if _mode == "pause":
			_resume()
		else:
			_back()
