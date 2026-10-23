extends SceneTree

const ResponsiveLayout = preload("res://Scripts/UI/responsive_layout.gd")

var frame := 0
var game_ui: Node
var shop_ui: Node
var stats_tooltip: PanelContainer
var synergy_tooltip: PanelContainer

func _process(_delta: float) -> bool:
	frame += 1
	if frame == 1:
		var game_ui_scene = load("res://Scenes/UI/GameUI.tscn")
		game_ui = game_ui_scene.instantiate()
		root.add_child(game_ui)
		shop_ui = game_ui.find_child("ShopContainer", true, false)
		stats_tooltip = game_ui.find_child("StatsTooltip", true, false)
		return false
		
	if frame == 2:
		print("--- TEST 1: FIRST HOVER ON SHOP CARD ---")
		var stats = load("res://Resources/Units/caapora.tres")
		shop_ui._on_card_hover_started(stats, Vector2(1000, 700))
		return false
		
	if frame == 3:
		print("Shop tooltip size: ", stats_tooltip.size)
		print("Shop tooltip global_pos: ", stats_tooltip.global_position)
		assert(stats_tooltip.visible, "Stats tooltip must be visible")
		assert(stats_tooltip.size.y < 300.0, "Stats tooltip height should be < 300px, was %f" % stats_tooltip.size.y)
		assert(stats_tooltip.global_position.y > 400.0, "Stats tooltip should be positioned above card, not at top of screen!")
		shop_ui._on_card_hover_ended()
		assert(not stats_tooltip.visible, "Stats tooltip should hide on hover ended")
		print("Test 1 Passed!")
		
		print("\n--- TEST 2: FIRST HOVER ON SYNERGY ROW ---")
		var dummy_row = PanelContainer.new()
		dummy_row.size = Vector2(160, 30)
		dummy_row.global_position = Vector2(50, 150)
		root.add_child(dummy_row)
		
		var test_syn = {
			"name": "Amazônico",
			"category": "Origem",
			"count": 2,
			"threshold": 4,
			"thresholds": [2, 4],
			"active": true,
			"units": ["Alamoa", "Caapora", "Mapinguari"]
		}
		game_ui._on_synergy_row_hover_started(test_syn, dummy_row)
		synergy_tooltip = game_ui.find_child("SynergyTooltip", true, false)
		return false
		
	if frame == 4:
		print("Synergy tooltip size: ", synergy_tooltip.size)
		print("Synergy tooltip global_pos: ", synergy_tooltip.global_position)
		assert(synergy_tooltip.visible, "Synergy tooltip must be visible")
		assert(synergy_tooltip.size.y < 350.0, "Synergy tooltip height should be < 350px, was %f" % synergy_tooltip.size.y)
		assert(synergy_tooltip.size.x >= 240.0, "Synergy tooltip width should be >= 240px")
		game_ui._on_synergy_row_hover_ended()
		assert(not synergy_tooltip.visible, "Synergy tooltip should hide on hover ended")
		print("Test 2 Passed!")
		
		print("\n--- TEST 3: FIRST HOVER ON INSPECTOR TAG ---")
		var dummy_label = RichTextLabel.new()
		dummy_label.size = Vector2(200, 20)
		dummy_label.global_position = Vector2(1400, 300)
		root.add_child(dummy_label)
		
		game_ui._on_inspector_meta_hover_started("Amazônico", dummy_label)
		return false
		
	if frame == 5:
		print("Inspector tooltip size: ", synergy_tooltip.size)
		print("Inspector tooltip global_pos: ", synergy_tooltip.global_position)
		assert(synergy_tooltip.visible, "Synergy tooltip must be visible")
		assert(synergy_tooltip.size.y < 350.0, "Inspector tooltip height should be < 350px, was %f" % synergy_tooltip.size.y)
		game_ui._on_inspector_meta_hover_ended()
		assert(not synergy_tooltip.visible, "Synergy tooltip should hide on hover ended")
		print("Test 3 Passed!")
		
		print("\nALL HOVER TOOLTIP SIZING TESTS PASSED SUCCESSFULLY!")
		quit(0)
		return true
		
	return false
