extends CanvasLayer

const Commands = preload("res://Scripts/Systems/debug_commands.gd")
const Style = preload("res://Scripts/UI/ui_style.gd")
const MAX_HISTORY := 100
const MAX_OUTPUT := 200

var game: Node
var is_open := false
var command_input: LineEdit
var output: RichTextLabel
var panel: Control
var launcher: Button
var _commands := Commands.new()
var _history: Array[String] = []
var _history_index := 0
var _draft := ""
var _output_lines: Array[String] = []
var _was_paused := false
var _original_time_scale := 1.0
var _previous_focus: Control

func _ready() -> void:
	name = "DebugConsole"
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_original_time_scale = Engine.time_scale
	_commands.game = game
	launcher = Button.new()
	launcher.text = "Debug · F8"
	launcher.focus_mode = Control.FOCUS_NONE
	launcher.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	launcher.offset_left = -340
	launcher.offset_right = -220
	launcher.offset_top = 16
	launcher.offset_bottom = 68
	Style.apply_button_skin(launcher, Style.BORDER_CYAN)
	launcher.pressed.connect(toggle)
	add_child(launcher)
	panel = ColorRect.new()
	panel.color = Color(0.01, 0.02, 0.04, 0.78)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var frame := PanelContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.anchor_left = 0.08
	frame.anchor_right = 0.92
	frame.anchor_top = 0.12
	frame.anchor_bottom = 0.88
	frame.add_theme_stylebox_override("panel", Style.make_panel_style(Style.BG_DARK, Style.BORDER_CYAN))
	panel.add_child(frame)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	frame.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	var title := Label.new()
	title.text = "CONSOLE DE DEBUG · PARTIDA PAUSADA"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_color_override("font_color", Style.TEXT_CYAN)
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "Fechar · Esc"
	close_button.pressed.connect(close)
	header.add_child(close_button)
	output = RichTextLabel.new()
	output.size_flags_vertical = Control.SIZE_EXPAND_FILL
	output.scroll_following = true
	output.selection_enabled = true
	output.bbcode_enabled = false
	output.add_theme_font_size_override("normal_font_size", 18)
	content.add_child(output)
	command_input = LineEdit.new()
	command_input.placeholder_text = "Digite ajuda ou um comando..."
	command_input.custom_minimum_size.y = 44
	command_input.max_length = 256
	command_input.text_submitted.connect(_submit)
	command_input.gui_input.connect(_on_command_input)
	content.add_child(command_input)
	var hint := Label.new()
	hint.text = "Enter executa · Cima/Baixo histórico · F8/Esc fecha · Alterações são salvas na campanha"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", Style.TEXT_MUTED)
	content.add_child(hint)
	panel.hide()
	_append_output(Commands.HELP)

func _exit_tree() -> void:
	Engine.time_scale = _original_time_scale
	if is_open and (not is_instance_valid(game) or not game._leaving):
		get_tree().paused = _was_paused

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F8:
			toggle()
			get_viewport().set_input_as_handled()
		elif is_open and event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()

func toggle() -> void:
	if is_open:
		close()
	else:
		open()

func open() -> void:
	if is_open or not is_instance_valid(game) or game._leaving:
		return
	if game.drag_handler and game.drag_handler.is_dragging:
		game.drag_handler.cancel_drag()
		game.dragging_unit = null
	if game.camera:
		game.camera.cancel_manual_orbit()
	_previous_focus = get_viewport().gui_get_focus_owner()
	_was_paused = get_tree().paused
	get_tree().paused = true
	is_open = true
	panel.show()
	launcher.hide()
	command_input.grab_focus()

func close() -> void:
	if not is_open:
		return
	is_open = false
	panel.hide()
	launcher.show()
	command_input.release_focus()
	get_tree().paused = _was_paused
	if is_instance_valid(_previous_focus) and _previous_focus.is_visible_in_tree():
		_previous_focus.grab_focus()

func _submit(text: String) -> void:
	var command := text.strip_edges()
	if command.is_empty():
		return
	if _history.is_empty() or _history.back() != command:
		_history.append(command)
		if _history.size() > MAX_HISTORY:
			_history.pop_front()
	_history_index = _history.size()
	_draft = ""
	command_input.clear()
	if command.to_lower() in ["limpar", "clear"]:
		_output_lines.clear()
		output.clear()
		return
	_append_output("> " + command)
	if command.to_lower() in ["fechar", "exit"]:
		close()
		return
	_append_output(_commands.execute(command))
	command_input.grab_focus()

func _append_output(text: String) -> void:
	for line in text.split("\n"):
		_output_lines.append(line)
	while _output_lines.size() > MAX_OUTPUT:
		_output_lines.pop_front()
	output.text = "\n".join(_output_lines)

func _on_command_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.keycode not in [KEY_UP, KEY_DOWN]:
		return
	if _history_index == _history.size():
		_draft = command_input.text
	_history_index = clampi(_history_index + (-1 if event.keycode == KEY_UP else 1), 0, _history.size())
	command_input.text = _draft if _history_index == _history.size() else _history[_history_index]
	command_input.caret_column = command_input.text.length()
	command_input.accept_event()
