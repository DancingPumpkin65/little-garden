class_name GardenJourney
extends Node3D

signal dialogue_requested(lines: Array[String])
signal transition_lock(locked: bool)
enum Chapter { FIRST, GAP, DESCENT, DARK }
enum Beat { INTRO, RUN, JUMP, FALLEN }
var chapter := Chapter.FIRST
var beat := Beat.INTRO
var player: GardenCharacter
var companion: GardenCharacter
var parts: GardenCompanionParts
var original_world: GardenWorld
var camera: Camera3D
var curtain: ColorRect
var scene_root := Node3D.new()
var far_platform: MeshInstance3D
var leg: MeshInstance3D
var far_dark := false
var crossing := false
var clock := 0.0
var dark_material: ShaderMaterial

func setup(girl: GardenCharacter, guy: GardenCharacter, body_parts: GardenCompanionParts, first_map: GardenWorld, view: Camera3D, overlay: ColorRect) -> void:
	player = girl
	companion = guy
	parts = body_parts
	original_world = first_map
	camera = view
	curtain = overlay
	add_child(scene_root)

func platform(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	Shapes.collider(scene_root, at, size)
	return Shapes.box(scene_root, at, size, material)

func fade_to_black() -> void:
	transition_lock.emit(true)
	player.set_physics_process(false)
	companion.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(curtain, "color:a", 1.0, 0.55)
	await tween.finished
	await get_tree().create_timer(0.2, false).timeout

func fade_in() -> void:
	player.set_physics_process(true)
	var tween := create_tween()
	tween.tween_property(curtain, "color:a", 0.0, 0.65)
	await tween.finished
	transition_lock.emit(false)

func enter_gap() -> void:
	if crossing or chapter != Chapter.FIRST: return
	crossing = true
	await fade_to_black()
	original_world.hide()
	for body: CollisionObject3D in original_world.find_children("*", "CollisionObject3D", true, false):
		body.collision_layer = 0
		body.collision_mask = 0
	chapter = Chapter.GAP
	beat = Beat.INTRO
	clock = 0
	var white := Shapes.material(Color.WHITE)
	platform(Vector3(0, -0.48, 2), Vector3(14, 1, 16), white)
	far_platform = platform(Vector3(0, -0.48, -25), Vector3(14, 1, 12), white)
	leg = MeshInstance3D.new()
	leg.mesh = parts.loose_mesh(&"leg")
	scene_root.add_child(leg)
	player.position = Vector3(0, 0.08, 4)
	player.velocity = Vector3.ZERO
	companion.position = Vector3(2.2, 0.02, 0.8)
	companion.velocity = Vector3.ZERO
	companion.celebration = 0
	companion.hop = GardenCharacter.Hop.REST
	companion.hop_clock = 0
	companion.follow_target = null
	companion.show()
	companion.set_physics_process(false)
	camera.position = Vector3(0, 11, 19)
	camera.look_at(Vector3(0, 0.7, -3))
	var lines: Array[String] = ["Hahiya yedi fjiha lakhra. Kighandiro nakhdoha?", "Ymkn khassna namchiw na9zo ltmak."]
	dialogue_requested.emit(lines)
	await fade_in()
	crossing = false

func dialogue_finished() -> void:
	if chapter == Chapter.GAP and beat == Beat.INTRO:
		beat = Beat.RUN
		clock = 0

func enter_dark() -> void:
	if crossing or chapter != Chapter.GAP: return
	crossing = true
	chapter = Chapter.DESCENT
	await fade_to_black()
	for child in scene_root.get_children():
		scene_root.remove_child(child)
		child.queue_free()
	dark_material = ShaderMaterial.new()
	dark_material.shader = Shader.new()
	dark_material.shader.code = "shader_type spatial; uniform vec3 light_center=vec3(0.0); varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float distance_to_light=length(world.xz-light_center.xz); ALBEDO=vec3(1.0-smoothstep(13.0,42.0,distance_to_light));ROUGHNESS=1.0;SPECULAR=0.0;}"
	platform(Vector3(0, -0.48, 0), Vector3(10000, 1, 10000), dark_material)
	player.position = Vector3(0, 12, 3)
	player.velocity = Vector3(0, -2, 0)
	companion.position = Vector3(2.3, 0.03, -0.6)
	companion.velocity = Vector3.ZERO
	companion.celebration = 0
	companion.hop = GardenCharacter.Hop.REST
	companion.hop_clock = 0
	companion.follow_target = player
	companion.follow_offset = Vector3(2, 0, -3)
	companion.show()
	companion.set_physics_process(true)
	leg = MeshInstance3D.new()
	leg.mesh = parts.loose_mesh(&"leg")
	scene_root.add_child(leg)
	chapter = Chapter.DARK
	clock = 0
	camera.position = player.position + Vector3(0, 8.5, 12.5)
	camera.look_at(player.position + Vector3(0, 0.7, -2))
	await fade_in()
	crossing = false

func _physics_process(delta: float) -> void:
	clock += delta
	if chapter == Chapter.GAP:
		if not far_dark:
			leg.position = Vector3(-1.4 + sin(clock * 1.5) * 0.65, 0.66 + absf(sin(clock * 4)) * 0.55, -23 + cos(clock) * 0.4)
			leg.rotation.z = sin(clock * 4) * 0.15
		if beat == Beat.RUN:
			companion.velocity = Vector3(0, -0.5, -3.8)
			companion.move_and_slide()
			companion.visual.rotation.y = PI
			companion.gait += delta * 8
			companion.animate_pose(delta, 1.0, true)
			if companion.position.z < -5:
				beat = Beat.JUMP
				companion.velocity = Vector3(0, 5.4, -5)
		elif beat == Beat.JUMP:
			companion.velocity.y -= delta * 18
			companion.move_and_slide()
			companion.animate_pose(delta, 0.0, false)
			if companion.position.y < -6:
				companion.hide()
				beat = Beat.FALLEN
				far_dark = true
				var black := Shapes.material(Color.BLACK)
				black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				far_platform.material_override = black
				leg.hide()
		if player.position.y < -6 and not crossing: enter_dark()
	elif chapter == Chapter.DARK:
		dark_material.set_shader_parameter("light_center", player.global_position)
		leg.position = Vector3(-1.7, 0.66 + absf(sin(clock * 3)) * 0.22, -3.2)
