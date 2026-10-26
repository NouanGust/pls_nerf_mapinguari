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
@export var sinergy_activated_sfx: AudioStream = preload("res://Assets/Audio/SFX/sinergy_activated.wav")
@export var player_level_up_sfx: AudioStream = preload("res://Assets/Audio/SFX/player_level_up.wav")
@export var melee_hit_sfx: AudioStream = preload("res://Assets/Audio/SFX/melee_hit.mp3")

@export_group("Streak SFX")
@export var win_streak_1_sfx: AudioStream = preload("res://Assets/Audio/SFX/win_streak1.mp3")
@export var win_streak_2_sfx: AudioStream = preload("res://Assets/Audio/SFX/win_streak2.mp3")
@export var win_streak_3_sfx: AudioStream = preload("res://Assets/Audio/SFX/win_streak_3.mp3")
@export var loss_streak_1_sfx: AudioStream = preload("res://Assets/Audio/SFX/Loss_streak1.mp3")

@export_group("Music")
@export var menu_music: AudioStream = preload("res://Assets/Audio/Music/Main_menu.wav")
@export var pause_music: AudioStream = preload("res://Assets/Audio/Music/pause_menu.wav")

var _evol_hint_player: AudioStreamPlayer
var _current_region_id: String = ""
var _paused_music_position: float = 0.0

const REGION_TRACKS := {
	"pantanal": preload("res://Assets/Audio/Music/Pantanal.mp3"),
	"mata_atlantica": preload("res://Assets/Audio/Music/Sudeste.mp3"),
	"sudeste": preload("res://Assets/Audio/Music/Sudeste.mp3"),
	"litoral": preload("res://Assets/Audio/Music/Sudeste.mp3"),
	"sul": preload("res://Assets/Audio/Music/Sul.mp3"),
	"cerrado": preload("res://Assets/Audio/Music/Pantanal.mp3"),
	"amazonia": preload("res://Assets/Audio/Music/Pantanal.mp3"),
	"caatinga": preload("res://Assets/Audio/Music/Sul.mp3"),
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_init_sfx_pool()
	_init_evol_hint_player()
	if menu_music_player == null:
		menu_music_player = AudioStreamPlayer.new()
		menu_music_player.name = "MenuMusicPlayer"
		menu_music_player.bus = &"Music"
		add_child(menu_music_player)
	if not menu_music_player.finished.is_connected(_on_music_finished):
		menu_music_player.finished.connect(_on_music_finished)
	if menu_music and menu_music_player.stream == null:
		_ensure_stream_loop(menu_music)
		menu_music_player.stream = menu_music

func _init_evol_hint_player() -> void:
	if _evol_hint_player == null:
		_evol_hint_player = AudioStreamPlayer.new()
		_evol_hint_player.name = "EvolHintPlayer"
		_evol_hint_player.bus = &"SFX"
		_evol_hint_player.stream = evol_hint_shop_sfx
		add_child(_evol_hint_player)

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
func _on_music_finished() -> void:
	if menu_music_player and menu_music_player.stream:
		menu_music_player.play()

func _ensure_stream_loop(stream: AudioStream) -> void:
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD

func play_menu_music() -> void:
	if menu_music_player:
		if menu_music:
			_ensure_stream_loop(menu_music)
		if menu_music_player.stream != menu_music:
			menu_music_player.stream = menu_music
		if not menu_music_player.playing:
			menu_music_player.play()

func play_region_music(region_id: String) -> void:
	_current_region_id = region_id.to_lower()
	var track: AudioStream = REGION_TRACKS.get(_current_region_id, REGION_TRACKS["pantanal"])
	if track:
		_ensure_stream_loop(track)
	if menu_music_player:
		if menu_music_player.stream == track and menu_music_player.playing:
			return
		menu_music_player.stop()
		menu_music_player.stream = track
		menu_music_player.play()

func play_pause_music() -> void:
	if menu_music_player:
		if menu_music_player.playing:
			_paused_music_position = menu_music_player.get_playback_position()
			menu_music_player.stop()
		if pause_music:
			_ensure_stream_loop(pause_music)
			menu_music_player.stream = pause_music
			menu_music_player.play()

func resume_region_music() -> void:
	if menu_music_player:
		var track: AudioStream = REGION_TRACKS.get(_current_region_id, menu_music)
		if track:
			_ensure_stream_loop(track)
		if menu_music_player.stream != track or not menu_music_player.playing:
			menu_music_player.stream = track
			menu_music_player.play(_paused_music_position)

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

func play_place_unit(tier: int) -> void:
	if move_unit_sfx == null:
		return
	if _sfx_pool.is_empty():
		_init_sfx_pool()
	var player: AudioStreamPlayer = null
	for p in _sfx_pool:
		if is_instance_valid(p) and not p.playing:
			player = p
			break
	if player == null:
		player = _sfx_pool[_sfx_pool_index]
		_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()
	
	player.stream = move_unit_sfx
	player.volume_db = -1.0 + (tier - 1) * 0.7
	player.pitch_scale = 0.95 + clampf(tier - 1, 0, 4) * 0.12
	player.play()
	if tier >= 5 and sinergy_activated_sfx:
		play_sfx(sinergy_activated_sfx, false, -4.0)

func play_evol_hint_shop() -> void:
	if _evol_hint_player == null:
		_init_evol_hint_player()
	if _evol_hint_player and not _evol_hint_player.playing:
		_evol_hint_player.play()

func stop_evol_hint_shop() -> void:
	if _evol_hint_player and _evol_hint_player.playing:
		_evol_hint_player.stop()

func play_2_star_up() -> void:
	var stream := star_up_2_sfx if randf() < 0.5 else star_up_2_alt_sfx
	if stream == null:
		stream = star_up_2_sfx
	play_sfx(stream, false)

func play_3_star_up() -> void:
	play_sfx(star_up_3_sfx, false, 3.5)
	if win_streak_3_sfx:
		play_sfx(win_streak_3_sfx, false, 1.0)

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

func play_player_level_up() -> void:
	play_sfx(player_level_up_sfx, false)

func play_melee_hit() -> void:
	play_sfx(melee_hit_sfx, true, -3.0)


## --- Pool e tocador genérico de SFX ---
const SFX_POOL_SIZE := 12
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

func _init_sfx_pool() -> void:
	if not _sfx_pool.is_empty():
		return
	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.name = "SfxPoolPlayer_%d" % i
		p.bus = &"SFX"
		add_child(p)
		_sfx_pool.append(p)

func play_sfx(stream: AudioStream, randomize_pitch: bool = false, volume_offset_db: float = 0.0) -> void:
	if stream == null:
		return
	if _sfx_pool.is_empty():
		_init_sfx_pool()
	
	var player: AudioStreamPlayer = null
	for p in _sfx_pool:
		if is_instance_valid(p) and not p.playing:
			player = p
			break
	if player == null:
		player = _sfx_pool[_sfx_pool_index]
		_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_pool.size()
	
	player.stream = stream
	player.volume_db = volume_offset_db
	player.pitch_scale = randf_range(0.92, 1.08) if randomize_pitch else 1.0
	player.play()
