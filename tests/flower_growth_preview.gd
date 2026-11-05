extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	root.size = Vector2i(960,640)
	var stage := Node3D.new()
	root.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("9bcde9")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.65
	stage.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45,-25,0)
	light.light_energy = 1.1
	stage.add_child(light)
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = Vector3(12,0.15,8)
	Shapes.mesh(stage,floor_mesh,Vector3(0,-0.075,0),Shapes.material(Color("46be68")))
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.7
	camera.position = Vector3(2.5,3.2,8)
	camera.look_at(Vector3(0,0.8,0))
	camera.current = true
	var blooms: Array[GardenBloom] = []
	for kind in range(6):
		var bloom := GardenBloom.new()
		bloom.kind = kind
		bloom.color = [Color.WHITE,Color("edc1d4"),Color("efd277"),Color.YELLOW,Color("c5b2e8"),Color("edcf60")][kind]
		bloom.height = [0.65,0.6,0.5,1.8,1.0,1.0][kind]
		bloom.position = Vector3((kind-2.5)*1.15,0,0)
		stage.add_child(bloom)
		bloom.start()
		bloom.set_physics_process(false)
		blooms.append(bloom)
	for frame in range(37):
		for bloom in blooms:
			if frame>0: bloom._physics_process(GardenBloom.DURATION/36.0)
			assert(bloom.scale==Vector3.ONE and bloom.position.y==0,"flower roots stay fixed while stems emerge")
		await process_frame
		if DisplayServer.get_name()!="headless":
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://artifacts/outfits-flowers/growth-%02d.png"%frame)
	assert(blooms[0].progress>0.99,"flower growth finishes")
	print("FLOWER_GROWTH_PASS six species, fixed roots, complete emergence sequence")
	quit()
