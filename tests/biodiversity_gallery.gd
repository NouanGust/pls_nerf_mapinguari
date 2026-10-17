extends SceneTree
## Prévia reproduzível: godot --path . --script res://tests/biodiversity_gallery.gd
const Models = preload("res://Scripts/Units/biodiversity_models.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1500, 1000)
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("#182435")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.8
	environment.environment.ambient_light_sky_contribution = 0.0
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 150, 0)
	light.light_energy = 1.2
	world.add_child(light)
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 20.5
	camera.position = Vector3(0, 19, 19)
	camera.look_at(Vector3.ZERO)
	camera.current = true
	var ids := Models.ANIMALS.keys() + Models.PLANTS.keys()
	for i in ids.size():
		var stats := UnitSpawner.load_unit_stats(ids[i])
		var model := Models.create_model(stats)
		world.add_child(model)
		model.position = Vector3((i % 5 - 2) * 3.7, 0, (i / 5 - 2) * 4.2)
		model.rotation.y += 0.45
		var label := Label3D.new()
		label.text = stats.unit_name
		label.font_size = 40
		label.pixel_size = 0.008
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		world.add_child(label)
		label.position = model.position + Vector3(0, 0, 1.5)
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://.godot/biodiversity-gallery.png")
	world.queue_free()
	await process_frame
	quit()
