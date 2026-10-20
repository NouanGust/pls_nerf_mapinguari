extends Node

## Gerenciador de Áudio Global do Folchess

@onready var menu_music_player: AudioStreamPlayer = get_node_or_null("MenuMusicPlayer")

@export_group("UI SFX")
@export var ui_click_sfx: AudioStream = preload("res://Assets/Audio/SFX/UI_click.mp3")
@export var ui_hover_sfx: AudioStream = preload("res://Assets/Audio/SFX/UI_hover.mp3")
@export var ui_cancel_sfx: AudioStream = preload("res://Assets/Audio/SFX/UI_cancel.wav")
@export var ui_choose_sfx: AudioStream = preload("res://Assets/Audio/SFX/UI_choose.wav")

@export_group("Gameplay SFX")
@export var buy_sfx: AudioStream = preload("res://Assets/Audio/SFX/buy.mp3")
@export var fail_sfx: AudioStream = preload("res://Assets/Audio/SFX/Fail.mp3")
@export var move_unit_sfx: AudioStream = preload("res://Assets/Audio/SFX/move_unit.mp3")
@export var evol_hint_shop_sfx: AudioStream = preload("res://Assets/Audio/SFX/evol_hint_shop.mp3")
@export var star_up_2_sfx: AudioStream = preload("res://Assets/Audio/SFX/2_star_up.mp3")
@export var star_up_2_alt_sfx: AudioStream = preload("res://Assets/Audio/SFX/2_star_up1.mp3")
@export var star_up_3_sfx: AudioStream = preload("res://Assets/Audio/SFX/3_star_up.mp3")
@export var sinergy_activated_sfx: AudioStream = preload("res://Assets/Audio/SFX/sinergy_activated.mp3")

@export_group("Streak SFX")
@export var win_streak_1_sfx: AudioStream = preload("res://Assets/Audio/SFX/win_streak1.mp3")
@export var win_streak_2_sfx: AudioStream = preload("res://Assets/Audio/SFX/win_streak2.mp3")
@export var win_streak_3_sfx: AudioStream = preload("res://Assets/Audio/SFX/win_streak_3.mp3")
@export var loss_streak_1_sfx: AudioStream = preload("res://Assets/Audio/SFX/Loss_streak1.mp3")

@export_group("Music")
@export var menu_music: AudioStream

var _last_evol_hint_played_round: int = -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	if menu_music_player == null:
		menu_music_player = AudioStreamPlayer.new()
		menu_music_player.name = "MenuMusicPlayer"
		menu_music_player.bus = &"Music"
		add_child(menu_music_player)
	if menu_music and menu_music_player.stream == null:
		menu_music_player.stream = menu_music

func _ensure_audio_buses() -> void:
	if AudioServer.get_bus_index("Music") == -1:
		var music_idx := AudioServer.bus_count
		AudioServer.add_bus(music_idx)
		AudioServer.set_bus_name(music_idx, "Music")
		AudioServer.set_bus_send(music_idx, "Master")
	if AudioServer.get_bus_index("SFX") == -1:
		var sfx_idx := AudioServer.bus_count
		AudioServer.add_bus(sfx_idx)
		AudioServer.set_bus_name(sfx_idx, "SFX")
		AudioServer.set_bus_send(sfx_idx, "Master")

## --- Música ---
func play_menu_music() -> void:
	if menu_music_player and menu_music_player.stream and not menu_music_player.playing:
		menu_music_player.play()

func stop_music() -> void:
	if menu_music_player and menu_music_player.playing:
		menu_music_player.stop()

## --- UI ---
func play_ui_click() -> void:
	play_sfx(ui_click_sfx, false)

func play_ui_hover() -> void:
	play_sfx(ui_hover_sfx, false)

func play_ui_cancel() -> void:
	play_sfx(ui_cancel_sfx, false)

func play_ui_choose() -> void:
	play_sfx(ui_choose_sfx, false)

## --- Gameplay ---
func play_buy() -> void:
	play_sfx(buy_sfx, false)

func play_fail() -> void:
	play_sfx(fail_sfx, false)

func play_move_unit() -> void:
	play_sfx(move_unit_sfx, true)

func play_evol_hint_shop() -> void:
	play_sfx(evol_hint_shop_sfx, false)

func play_2_star_up() -> void:
	var stream := star_up_2_sfx if randf() < 0.5 else star_up_2_alt_sfx
	if stream == null:
		stream = star_up_2_sfx
	play_sfx(stream, false)

func play_3_star_up() -> void:
	play_sfx(star_up_3_sfx, false)

func play_sinergy_activated() -> void:
	play_sfx(sinergy_activated_sfx, false)

func play_win_streak(streak: int) -> void:
	if streak <= 1:
		play_sfx(win_streak_1_sfx, false)
	elif streak == 2:
		play_sfx(win_streak_2_sfx, false)
	else:
		play_sfx(win_streak_3_sfx, false)

func play_loss_streak(_streak: int = 1) -> void:
	play_sfx(loss_streak_1_sfx, false)

## --- Tocador genérico de SFX ---
func play_sfx(stream: AudioStream, randomize_pitch: bool = false, volume_offset_db: float = 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"SFX"
	player.volume_db = volume_offset_db
	if randomize_pitch:
		player.pitch_scale = randf_range(0.92, 1.08)
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
