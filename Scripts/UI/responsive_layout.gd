extends Node

## A referência muda com a orientação; o canvas se expande sem deformar a arte.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.size_changed.connect(_update_reference)
	_update_reference()

func _update_reference() -> void:
	var window := get_tree().root
	var reference := Vector2i(800, 1280) if window.size.x < window.size.y else Vector2i(1600, 900)
	if window.content_scale_size != reference:
		window.content_scale_size = reference

static func battle_metrics(viewport_size: Vector2) -> Dictionary:
	var compact := viewport_size.x < 1100.0
	var shop_height := 232.0 if compact else 194.0
	var bench_height := 0.0
	var shop_top := viewport_size.y - shop_height - 12.0
	var bench_top := shop_top
	var top_height := 84.0 if compact else 60.0
	var field_top := top_height + 20.0
	var margin_x := 16.0 if compact else 40.0
	var board_width := maxf(viewport_size.x - margin_x * 2.0, 1.0)
	var field_left := margin_x
	return {
		"compact": compact, "shop_height": shop_height, "shop_top": shop_top,
		"bench_height": bench_height, "bench_top": bench_top, "top_height": top_height,
		"board_rect": Rect2(field_left, field_top, board_width, maxf(shop_top - field_top - 12.0, 1.0)),
	}

static func place(control: Control, rectangle: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rectangle.position
	control.size = rectangle.size

static func clamp_popup(control: Control, origin: Vector2, viewport_size: Vector2) -> void:
	control.global_position = Vector2(
		clampf(origin.x, 10.0, maxf(10.0, viewport_size.x - control.size.x - 10.0)),
		clampf(origin.y, 10.0, maxf(10.0, viewport_size.y - control.size.y - 10.0))
	)
