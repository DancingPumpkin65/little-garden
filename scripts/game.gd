extends Node3D

enum Stage { TITLE, SEED, REVEAL, GARDEN }
const ACTION_DURATION := 0.7
const THROW_RELEASE := 0.4
var stage := Stage.TITLE
var world := GardenWorld.new()
var player := GardenCharacter.new()
var friend := GardenCharacter.new()
var camera := Camera3D.new()
var sound := GardenSound.new()
var hud := GardenInterface.new()
var ball := RigidBody3D.new()
var seed_visual := Node3D.new()
var environment := Environment.new()
var aim_dots: Array[MeshInstance3D] = []
var sun := DirectionalLight3D.new()
var charging := false
var power := 0.0
var held := false
var lost_time := 0.0
var bloom := 0.0
var elapsed := 0.0
var speech_time := 0.0
var yaw := 0.0
var pitch := 0.6
var action_time := 0.0
var action_released := false
var throw_velocity := Vector3.ZERO
var orbiting := false
var testing := false
var test_tick := 0
var screenshot_mode := ""
var capturing := false
var pause := false
var seed_home := Vector3(-1.4, 0.7, 3.7)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	testing = "--self-test" in args
	for arg in args:
		if arg.begins_with("--capture="): screenshot_mode = arg.trim_prefix("--capture=")
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	player.process_mode = Node.PROCESS_MODE_PAUSABLE
	friend.process_mode = Node.PROCESS_MODE_PAUSABLE
	ball.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	player.position = Vector3(0, 0.2, 5.7)
	add_child(player)
	friend.npc = true
	friend.position = Vector3(2.4, 0.05, -3.1)
	friend.rotation.y = -0.5
	add_child(friend)
	add_child(sound)
	add_child(hud)
	hud.begin.connect(start)
	hud.resumed.connect(func(): set_pause(false))
	hud.restarted.connect(func(): get_tree().reload_current_scene())
	hud.mute_changed.connect(func(muted: bool): AudioServer.set_bus_mute(0, muted))
	var env_node := WorldEnvironment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("20212b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.32
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env_node.environment = environment
	add_child(env_node)
	sun.rotation_degrees = Vector3(-48, -32, 0)
	sun.light_color = Color.WHITE
	sun.light_energy = 0.8
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45
	add_child(sun)
	camera.fov = 43
	camera.position = Vector3(0, 9, 16)
	camera.current = true
	camera.near = 0.1
	camera.far = 100
	add_child(camera)
	camera.look_at(Vector3(0, 0.5, 0))
	build_seed()
	var dot_mat := Shapes.material(Color("f4ce83"))
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(20):
		var dot := Shapes.sphere(self, Vector3.ZERO, Vector3.ONE * 0.075, dot_mat)
		dot.visible = false
		aim_dots.append(dot)
	if testing or not screenshot_mode.is_empty():
		if screenshot_mode != "title": start()
		if screenshot_mode.begins_with("characters"):
			world.hide()
			player.position = Vector3(-0.95, 0.05, 2.0)
			friend.position = Vector3(0.95, 0.05, 2.0)
			friend.rotation.y = 0
			if screenshot_mode == "characters-back":
				player.visual.rotation.y = PI
				friend.visual.rotation.y = PI
			if screenshot_mode == "characters-side":
				player.visual.rotation.y = -PI / 2
				friend.visual.rotation.y = -PI / 2
			hud.objective.text = ""
			hud.speech("")
			ball.hide()
		if screenshot_mode == "garden":
			stage = Stage.GARDEN
			bloom = 1.0
			world.reveal(1)
			ball.hide()
			hud.objective.text = "A little care goes a long way."
			hud.speech("")

func build_seed() -> void:
	ball.mass = 0.6
	ball.continuous_cd = true
	ball.contact_monitor = true
	ball.max_contacts_reported = 4
	ball.physics_material_override = PhysicsMaterial.new()
	ball.physics_material_override.bounce = 0.35
	ball.physics_material_override.friction = 0.8
	ball.linear_damp = 0.05
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.25
	col.shape = shape
	ball.add_child(col)
	ball.add_child(seed_visual)
	Shapes.sphere(seed_visual, Vector3.ZERO, Vector3.ONE * 0.5, Shapes.material(Color("e4b55c")))
	Shapes.cylinder(seed_visual, Vector3(0, 0.31, 0), 0.025, 0.18, Shapes.material(Color("729d68")))
	var leaf := Shapes.sphere(seed_visual, Vector3(0.1, 0.38, 0), Vector3(0.25, 0.08, 0.13), Shapes.material(Color("8db276")))
	leaf.rotation.z = 0.4
	add_child(ball)
	ball.position = seed_home

func start() -> void:
	stage = Stage.SEED
	hud.title_screen.hide()
	if not testing and screenshot_mode.is_empty(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	say("Ari: That little seed has been waiting for you.", 5)

func say(text: String, seconds: float = 4.0) -> void:
	hud.speech(text)
	speech_time = seconds

func set_pause(value: bool) -> void:
	pause = value
	get_tree().paused = value
	hud.pause_screen.visible = value
	charging = false
	orbiting = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and stage != Stage.TITLE: set_pause(not pause)
		if pause or stage == Stage.TITLE: return
		if event.keycode == KEY_E: interact()
		if event.keycode == KEY_SPACE and player.action.is_empty(): player.jump_requested = true
		if event.keycode == KEY_R and stage == Stage.SEED: recover()
	if pause or stage == Stage.TITLE: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT: orbiting = event.pressed
		if event.button_index == MOUSE_BUTTON_LEFT and held and player.action.is_empty():
			if event.pressed:
				charging = true
				power = 0
			elif charging: throw_seed()
	if event is InputEventMouseMotion and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or orbiting):
		yaw -= event.relative.x * 0.004
		pitch = clampf(pitch + event.relative.y * 0.003, 0.18, 1.15)

func interact() -> void:
	if not player.action.is_empty(): return
	if stage == Stage.SEED and not held and player.position.distance_to(ball.position) < 2.0:
		player.action = "pickup"
		player.action_phase = 0
		action_time = 0
		player.visual.rotation.y = atan2(ball.position.x - player.position.x, ball.position.z - player.position.z)
		ball.freeze = true
		ball.collision_layer = 0
		ball.collision_mask = 0
		sound.chime(392)
		say("Ari: Plant it in the bowl. Give it a gentle throw.")
	elif player.position.distance_to(friend.position) < 2.7:
		say("Ari: Look what you helped grow. Stay a while." if stage == Stage.GARDEN else "Ari: Stand a few steps from the bowl, then aim along the dotted line.", 5)

func forward() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw))

func launch_velocity() -> Vector3:
	return forward() * lerpf(4.8, 10.0, power) + Vector3.UP * lerpf(2.5, 4.5, power)

func throw_seed() -> void:
	if not held or not player.action.is_empty(): return
	throw_velocity = launch_velocity()
	player.visual.rotation.y = atan2(forward().x, forward().z)
	charging = false
	player.action = "throw"
	player.action_phase = 0
	action_time = 0
	action_released = false

func update_action(delta: float) -> void:
	if player.action.is_empty(): return
	action_time += delta
	player.action_phase = minf(1, action_time / ACTION_DURATION)
	if player.action == "pickup" and action_time >= 0.3:
		held = true
		player.carrying = true
	player.apply_joint_poses()
	if player.action == "throw" and action_time >= THROW_RELEASE and not action_released:
		ball.global_position = player.fruit_position()
		ball.freeze = false
		ball.collision_layer = 2
		ball.collision_mask = 1
		ball.linear_velocity = throw_velocity
		ball.angular_velocity = Vector3(3, 1, 2)
		held = false
		player.carrying = false
		action_released = true
		lost_time = 0
		sound.chime(329.63)
	if action_time >= ACTION_DURATION:
		player.action = ""
		player.action_phase = 0

func recover() -> void:
	player.action = ""
	held = false
	charging = false
	player.carrying = false
	ball.freeze = true
	ball.position = seed_home
	ball.linear_velocity = Vector3.ZERO
	ball.angular_velocity = Vector3.ZERO
	ball.collision_layer = 2
	ball.collision_mask = 1
	ball.freeze = false
	lost_time = 0
	say("The little seed found its way home.", 2)

func planted() -> void:
	if stage != Stage.SEED: return
	stage = Stage.REVEAL
	ball.freeze = true
	ball.hide()
	held = false
	player.carrying = false
	charging = false
	hud.objective.text = "Watch what a little care can do."
	say("Ari: There you are. I knew you could bring it back.", 6)
	sound.chime(659.25)

func _physics_process(delta: float) -> void:
	if pause: return
	elapsed += delta
	if speech_time > 0:
		speech_time -= delta
		if speech_time <= 0: hud.speech("")
	if stage != Stage.TITLE and not testing:
		var input := Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		player.drive = Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw).limit_length()
		player.sprint = Input.is_physical_key_pressed(KEY_SHIFT)
	if stage == Stage.TITLE: player.drive = Vector3.ZERO
	if player.position.y < -5:
		player.position = Vector3(0, 0.2, 5.7)
		player.velocity = Vector3.ZERO
		if held: recover()
	if not player.action.is_empty(): player.drive = Vector3.ZERO
	update_action(delta)
	if held:
		if player.action != "throw":
			player.visual.rotation.y = lerp_angle(player.visual.rotation.y, atan2(forward().x, forward().z), delta * 10)
		ball.global_position = player.fruit_position()
		ball.rotation = Vector3(0, elapsed * 0.5, 0)
		if charging: power = minf(1.0, power + delta * 0.65)
	if stage == Stage.SEED and not held and player.action != "pickup":
		lost_time += delta
		var near_bowl := Vector2(ball.position.x - world.bowl.x, ball.position.z - world.bowl.z).length() < 0.8
		if near_bowl and ball.position.y > 0.3 and ball.position.y < 1.2: planted()
		elif ball.position.y < -4 or (lost_time > 12 and ball.position.distance_to(seed_home) > 1): recover()
	if stage == Stage.REVEAL:
		bloom = minf(1, bloom + delta / 4.0)
		world.reveal(smoothstep(0, 1, bloom))
		if bloom >= 1:
			stage = Stage.GARDEN
			hud.objective.text = "Your garden is growing. Explore, or talk to Ari."
			hud.finish.text = "You made room for something good."
			sound.chime(783.99)
	environment.background_color = Color("20212b").lerp(Color("b9d2d1"), bloom)
	var focus := player.position + Vector3(0, 0.7, -1)
	var offset := Vector3(0, sin(pitch) * 15.1, cos(pitch) * 15.1).rotated(Vector3.UP, yaw)
	camera.position = camera.position.lerp(focus + offset, 1.0 - exp(-delta * 4))
	camera.look_at(focus)
	if screenshot_mode.begins_with("characters"):
		camera.position = Vector3(0, 2.9, 7.6)
		camera.look_at(Vector3(0, 1.4, 2))
	update_hud()
	update_aim()
	if testing: self_test()
	if not screenshot_mode.is_empty() and not capturing and elapsed > 1.5:
		capturing = true
		capture.call_deferred(screenshot_mode)

func _process(_delta: float) -> void:
	if held and not pause: ball.global_position = player.fruit_position()
	if not pause and stage != Stage.TITLE: update_hud()

func update_hud() -> void:
	if screenshot_mode.begins_with("characters"): return
	if stage == Stage.TITLE: return
	hud.place_speech(camera, friend.global_position + Vector3.UP * 2.9)
	hud.charge.visible = charging
	hud.charge.value = power * 100

func update_aim() -> void:
	var origin := player.throw_origin(THROW_RELEASE / ACTION_DURATION) if held and charging else ball.position
	for i in range(aim_dots.size()):
		var dot := aim_dots[i]
		dot.visible = held and charging
		if dot.visible:
			var t := (i + 1) * 0.08
			dot.position = origin + launch_velocity() * t + Vector3.DOWN * 4.9 * t * t
			if dot.position.y < 0.1: dot.visible = false

func capture(view: String) -> void:
	if view == "characters-motion":
		player.set_physics_process(false)
		for frame in range(24):
			player.gait = frame * TAU / 24
			player.animate_pose(1.0, 1.0)
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://artifacts/stride-%s.png" % frame)
	if view == "characters-jump" or view == "characters-carry":
		player.set_physics_process(false)
		player.carrying = view == "characters-carry"
		player.animate_pose(1.0, 0.0, view != "characters-jump")
	if view == "characters-walk":
		player.set_physics_process(false)
		player.gait = PI * 1.5
		player.animate_pose(1.0, 1.0)
	await RenderingServer.frame_post_draw
	var path := "res://artifacts/" + view + ".png"
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURE_SAVED ", ProjectSettings.globalize_path(path))
	finish_run()

# Runs the actual controller and rigid-body simulation, without a renderer.
func self_test() -> void:
	test_tick += 1
	if test_tick == 1: player.drive = Vector3.RIGHT
	if test_tick == 10:
		assert(player.position.x > 0.1, "character accelerates from movement input")
		player.drive = Vector3.ZERO
		player.position = Vector3(-1.4, 0.1, 4.5)
	if test_tick == 20:
		interact()
	if test_tick == 65:
		assert(held and player.action.is_empty(), "pickup reaches carry pose")
		player.position = Vector3(0, 0.1, 0.0)
	if test_tick == 75:
		power = 0
		throw_seed()
		assert(held and ball.freeze, "fruit stays held during windup")
	if test_tick == 103:
		assert(not held and not ball.freeze, "throw keyframe releases actual rigid body")
	if test_tick == 170:
		assert(stage != Stage.SEED, "physics throw reaches the receiving bowl")
	if test_tick == 440:
		assert(stage == Stage.GARDEN and world.bloom == 1, "puzzle completes the full garden reveal")
		player.position.y = -6
	if test_tick == 442:
		assert(player.position.y > -1, "fall recovery restores the player")
		print("SELF_TEST_PASS pickup, timed physical throw, bowl trigger, reveal and fall recovery")
		finish_run()

func finish_run() -> void:
	sound.silence()
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()
