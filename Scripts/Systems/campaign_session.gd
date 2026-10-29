class_name CampaignSession
extends RefCounted

## Gerenciador de Sessão, Persistência e Menu de Pausa da Campanha

const Regions = preload("res://Scripts/Systems/region_rosters.gd")
const CampaignStore = preload("res://Scripts/Systems/campaign_store.gd")
const GameOverlay = preload("res://Scripts/UI/game_overlay.gd")

var game: Node3D
var overlay: GameOverlay
var save_warning: Label

var leaving: bool = false
var load_failed: bool = false
var save_pending: bool = false
var campaign_state: String = "active"

func setup(p_game: Node3D) -> void:
	game = p_game

func setup_pause_menu() -> void:
	if not game or not game.ui:
		return
	overlay = GameOverlay.new()
	game.add_child(overlay)
	overlay.resume_requested.connect(resume_game)
	overlay.menu_requested.connect(leave_game.bind(false))
	overlay.quit_requested.connect(leave_game.bind(true))
	
	var pause_button := GameOverlay.button("Pausa", open_pause)
	pause_button.name = "PauseButton"
	pause_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	pause_button.offset_left = -210
	pause_button.offset_right = -80
	pause_button.offset_top = 16
	pause_button.offset_bottom = 68
	pause_button.tooltip_text = "Pausar (Esc)"
	pause_button.focus_mode = Control.FOCUS_NONE
	game.ui.add_child(pause_button)
	
	save_warning = GameOverlay.label("", 18, Color("#ffbba0"))
	save_warning.name = "SaveWarning"
	save_warning.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	save_warning.offset_top = 78
	save_warning.offset_bottom = 110
	game.ui.add_child(save_warning)
	if game.ui.has_method("_layout_extra_panels"):
		game.ui._layout_extra_panels.call_deferred()

func open_pause() -> void:
	if leaving or not overlay:
		return
	if game.drag_handler and game.drag_handler.is_dragging:
		game.drag_handler.cancel_drag()
		game.dragging_unit = null
	if game.camera:
		game.camera.cancel_manual_orbit()
	AudioManager.play_pause_music()
	game.get_tree().paused = true
	overlay.set_match_time(game.match_elapsed_seconds)
	overlay.open("pause", true)

func resume_game() -> void:
	if load_failed:
		overlay.open("pause", true)
		overlay.show_error("Esta campanha não pôde ser carregada. Volte ao menu para preservar o arquivo.")
		return
	AudioManager.resume_region_music()
	game.get_tree().paused = false
	game.get_viewport().gui_release_focus()

func leave_game(quit_application: bool) -> void:
	if leaving:
		return
	if game.drag_handler and game.drag_handler.is_dragging:
		game.drag_handler.cancel_drag()
		game.dragging_unit = null
	if game._run_ready and not save_campaign():
		open_pause()
		overlay.show_error("Não foi possível salvar. A partida continua aberta. Tente salvar novamente antes de sair.")
		return
	leaving = true
	if quit_application:
		game.get_tree().quit()
	else:
		return_to_menu.call_deferred()

func return_to_menu() -> void:
	game.get_tree().paused = false
	AudioManager.play_menu_music()
	game.get_tree().change_scene_to_file("res://Scenes/UI/Menu.tscn")

func schedule_save() -> void:
	if not game or not game._run_ready or leaving or save_pending:
		return
	save_pending = true
	flush_save.call_deferred()

func flush_save() -> void:
	save_pending = false
	if not game or not game.is_inside_tree() or leaving or not game._run_ready:
		return
	if game.drag_handler and game.drag_handler.is_dragging:
		return
	save_campaign()

func unit_save_data(unit: BaseUnit3D) -> Dictionary:
	var pos := unit.board_position
	if not unit.is_on_bench() and game.board:
		if pos.y < 4 or pos.y >= 8 or pos.x < 0 or pos.x >= 7:
			for r in range(4, 8):
				for c in range(7):
					var candidate := Vector2i(c, r)
					if not game.board.is_cell_occupied(candidate):
						pos = candidate
						unit.board_position = pos
						break
				if pos.y >= 4:
					break
	return {
		"id": unit.stats.unit_id,
		"stars": unit.star_level,
		"invested": unit.invested_gold,
		"cell": [pos.x, pos.y],
	}

func capture_campaign() -> Dictionary:
	var saved_bench: Array[Dictionary] = []
	var saved_field: Array[Dictionary] = []
	var saved_shop: Array[String] = []
	
	for unit in game.bench_units:
		if is_instance_valid(unit) and not unit.is_queued_for_deletion():
			saved_bench.append(unit_save_data(unit))
			
	var field_positions: Array[Vector2i] = []
	for unit in game.get_tree().get_nodes_in_group("player_units"):
		if unit is BaseUnit3D and unit not in game.bench_units and not unit.is_queued_for_deletion():
			var data := unit_save_data(unit)
			var cell := Vector2i(int(data["cell"][0]), int(data["cell"][1]))
			if cell in field_positions or cell.y < 4 or cell.y >= 8 or cell.x < 0 or cell.x >= 7:
				if game.board:
					for r in range(4, 8):
						for c in range(7):
							var candidate := Vector2i(c, r)
							if candidate not in field_positions:
								cell = candidate
								data["cell"] = [cell.x, cell.y]
								unit.board_position = cell
								break
						if cell not in field_positions:
							break
			field_positions.append(cell)
			saved_field.append(data)
			
	if game.shop_system and game.shop_system.current_units:
		for stats in game.shop_system.current_units:
			saved_shop.append(stats.unit_id if stats else "")
	while saved_shop.size() < 5:
		saved_shop.append("")
	if saved_shop.size() > 5:
		saved_shop.resize(5)
	
	var effective_level: int = clampi(maxi(game.player_level, saved_field.size()), 1, 9)
	return {
		"gold": game.player_gold,
		"health": game.player_health,
		"level": effective_level,
		"xp": game.player_xp,
		"enemy_level": int(Regions.get_enemy_stage(game.current_round)["level"]),
		"enemy_xp": 0,
		"round": game.current_round,
		"win_streak": game.win_streak,
		"loss_streak": game.loss_streak,
		"phase": "combat" if game.combat_active else ("resolved" if game.round_resolution_pending else "prep"),
		"bench": saved_bench,
		"field": saved_field,
		"shop": saved_shop,
		"locked": game.shop_system.is_shop_locked if game.shop_system else false,
		"match_time": game.match_elapsed_seconds,
	}

func save_campaign() -> bool:
	if not game or not game._run_ready or load_failed:
		return false
	if game.drag_handler and game.drag_handler.is_dragging:
		return false
	var result := CampaignStore.write_slot(game.region_id, capture_campaign(), campaign_state)
	if save_warning:
		save_warning.text = "" if result == OK else "Não foi possível salvar a campanha. Use Pausa para tentar novamente antes de sair."
	if result != OK:
		push_warning("Falha ao salvar campanha %s: %s" % [game.region_id, error_string(result)])
	return result == OK

func restore_campaign(run: Dictionary) -> bool:
	game.player_gold = int(run["gold"])
	game.player_health = int(run["health"])
	game.player_level = int(run["level"])
	game.player_xp = int(run["xp"])
	game.current_round = int(run["round"])
	game.enemy_level = int(Regions.get_enemy_stage(game.current_round)["level"])
	game.win_streak = int(run["win_streak"])
	game.loss_streak = int(run["loss_streak"])
	game.match_elapsed_seconds = float(run.get("match_time", 0.0))
	
	for zone in ["field", "bench"]:
		for entry in run[zone]:
			var unit := UnitSpawner.spawn_unit(str(entry["id"]), int(entry["stars"]), 0)
			if not unit:
				return false
			unit.use_navigation = false
			unit.debug_movement = false
			game.add_child(unit)
			unit.invested_gold = int(entry["invested"])
			if zone == "bench":
				if not game.add_unit_to_bench(unit):
					return false
			else:
				var cell := Vector2i(int(entry["cell"][0]), int(entry["cell"][1]))
				if not game.board.place_unit(unit, cell, false):
					return false
					
	if game.shop_system:
		game.shop_system.current_units.clear()
		for id in run["shop"]:
			game.shop_system.current_units.append(UnitSpawner.load_unit_stats(id) if id != "" else null)
		game.shop_system.lock_shop(bool(run["locked"]))
		game.shop_system.shop_refreshed.emit(game.shop_system.current_units)
		
	if run["phase"] == "resolved":
		game.prepare_next_round()
	else:
		game._resolve_unit_merges()
		game.spawn_enemy_team()
		
	game._realign_bench_units(false)
	return true
