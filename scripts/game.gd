extends Node3D

enum Stage { TITLE, SEED, REVEAL, GARDEN, PATH, COMPLETE }
const ACTION_DURATION := 0.7
const THROW_RELEASE := 0.4
const DIALOGUE_READ_PAUSE := 3.0
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
var pitch := 0.45
const FOLLOW_DISTANCE := 12.0
var action_time := 0.0
var action_released := false
var throw_velocity := Vector3.ZERO
var orbiting := false
var testing := false
var test_tick := 0
var screenshot_mode := ""
var capturing := false
var pause := false
var restart_pending := false
var passage_side := 1.0
var first_door_pending := false
var first_door_clock := 0.0
var companion_parts: GardenCompanionParts
var recovery_parts: Array[GardenRecoveryPart] = []
var carried_part: GardenRecoveryPart
var throw_in_flight := false
var flight_time := 0.0
var missed_throws := 0
var dialogue_queue: Array[String] = []
var transitioning := false
var journey := GardenJourney.new()
var dust := GardenDust.new()
var friend_dust := GardenDust.new()
const LEMON_INSTRUCTION := "Khassek thazi limouna li 7dak"
const BASKET_INSTRUCTION := "O tlu7iha f ssela O"
var entrance_clock := -1.0
const ENTRANCE_DURATION := 2.4
var entrance_from := Transform3D.IDENTITY
var entrance_to := Transform3D.IDENTITY
var lemon_cue_seen := false
var camera_cue_hold := false
var basket_cue_seen := false
var basket_cue_clock := -1.0
var basket_cue_duration := 0.0
var basket_cue_return := Transform3D.IDENTITY
var camera_cue_target := Transform3D.IDENTITY
var camera_cue_lemon := Transform3D.IDENTITY
var showing_basket_tour := false
var passage_joke_clock := 0.0
var passage_joke_index := 0
var second_passage_joke_index := 0
var passage_dialogue_chapter := -1
const PASSAGE_JOKES: Array[String] = ["Had lpassage twil... b7al tri9 dyalk lkhadma!"]
const SECOND_PASSAGE_JOKES: Array[String] = ["Yak ssaliti l3cha!?", "Maghadich na3tik lmcha dyali... wa9ila /•᷅\u200e\u200e•᷄\\੭"]
var leg_cue_seen := false
var previous_ball_position := Vector3.ZERO
const INTRO: Array[String] = [
	"Salam Salma, labas? :)",
	"3arfek yala jaya men lkhadma, 3iyana o darek rassek o darak kerchek okulchi...",
	"M7tajek t3awnini l9a body parts dyawli :)",
	LEMON_INSTRUCTION,
	BASKET_INSTRUCTION
]
const MISS_JOKES: Array[String] = [
	"Zgaltiha... Yakma ydik kaydarouk? ¬_¬",
	"3awtani majbtihach :/ wa9ila fik n3ass...",
	"Ma3lich had lmara tjibiha, \"TALTA TABTA\"",
	"Salma Ez Zyry...",
	"B9iiiina hnaya"
]
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
	player.collision_layer = 4
	player.collision_mask = 5
	friend.collision_layer = 4
	friend.collision_mask = 5
	player.position = Vector3(0, 0.2, 5.7)
	add_child(player)
	friend.npc = true
	friend.position = Vector3(2.3, 0.02, 2.1)
	friend.rotation.y = -0.5
	add_child(friend)
	companion_parts = GardenCompanionParts.new(friend)
	for kind: StringName in [&"arm"]:
		var part := GardenRecoveryPart.new()
		part.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(part)
		part.setup(kind, companion_parts.loose_mesh(kind), companion_parts, player)
		part.returned.connect(part_returned)
		recovery_parts.append(part)
	add_child(sound)
	add_child(hud)
	dust.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(dust)
	dust.setup(player)
	friend_dust.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(friend_dust)
	friend_dust.setup(friend)
	journey.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(journey)
	journey.setup(player, friend, companion_parts, world, camera, hud.curtain)
	journey.dialogue_requested.connect(say_sequence)
	journey.transition_lock.connect(set_transition_locked)
	journey.reunion.glass_impact.connect(sound.glass_impact)
	hud.letter_spoken.connect(sound.murmur)
	player.jumped.connect(sound.jump)
	hud.begin.connect(start)
	hud.resumed.connect(func(): set_pause(false))
	hud.restarted.connect(restart_game)
	hud.mute_changed.connect(func(muted: bool): AudioServer.set_bus_mute(0, muted))
	var env_node := WorldEnvironment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color.BLACK
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
	var dot_mat := Shapes.material(Color("aaaaaa"))
	dot_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(20):
		var dot := Shapes.sphere(self, Vector3.ZERO, Vector3.ONE * 0.075, dot_mat)
		dot.visible = false
		aim_dots.append(dot)
	if testing or not screenshot_mode.is_empty():
		if screenshot_mode != "title": start()
		if screenshot_mode.begins_with("characters"):
			for part: StringName in [&"head", &"arm", &"leg"]: companion_parts.restore(part)
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
	Shapes.cylinder(seed_visual, Vector3(0, 0.31, 0), 0.025, 0.18, Shapes.material(Color("555555")))
	var leaf := Shapes.sphere(seed_visual, Vector3(0.1, 0.38, 0), Vector3(0.25, 0.08, 0.13), Shapes.material(Color("888888")))
	leaf.rotation.z = 0.4
	add_child(ball)
	ball.position = seed_home

func restart_game() -> void:
	if restart_pending: return
	restart_pending = true
	get_tree().paused = false
	pause = false
	sound.silence()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().reload_current_scene.call_deferred()

func start() -> void:
	get_tree().paused = false
	pause = false
	hud.pause_screen.hide()
	stage = Stage.SEED
	hud.title_screen.hide()
	if not testing and screenshot_mode.is_empty(): Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	friend.follow_target = player if not screenshot_mode.begins_with("characters") else null
	var focus := player.position + Vector3(0,0.7,-1)
	entrance_to = Transform3D(Basis.IDENTITY,focus+Vector3(0,sin(pitch)*FOLLOW_DISTANCE,cos(pitch)*FOLLOW_DISTANCE)).looking_at(focus)
	entrance_from = Transform3D(Basis.IDENTITY,focus+Vector3(0,26,0.8)).looking_at(focus)
	entrance_clock = 0
	camera.transform = entrance_from
	say_sequence(INTRO)

func set_transition_locked(value: bool) -> void:
	transitioning = value
	if value:
		yaw = 0
		pitch = 0.45
		player.drive = Vector3.ZERO
		player.jump_requested = false
		charging = false
		dialogue_queue.clear()
		hud.speech("")
		speech_time = 0

func say(text: String, seconds: float = 4.0) -> void:
	dialogue_queue.clear()
	hud.speech(text)
	speech_time = maxf(seconds, hud.typing_duration(text) + DIALOGUE_READ_PAUSE)

func say_sequence(lines: Array[String]) -> void:
	dialogue_queue = lines.duplicate()
	next_dialogue()

func next_dialogue() -> void:
	if dialogue_queue.is_empty():
		hud.speech("")
		journey.dialogue_finished()
		return
	var line := dialogue_queue.pop_front() as String
	hud.speech(line)
	speech_time = hud.typing_duration(line) + DIALOGUE_READ_PAUSE
	var show_basket := line==BASKET_INSTRUCTION and not basket_cue_seen
	var show_lemon := line==LEMON_INSTRUCTION and not lemon_cue_seen
	var show_leg := line==GardenJourney.LEG_REVEAL_LINE and not leg_cue_seen
	if show_basket or show_lemon or show_leg:
		var continue_tour := show_basket and showing_basket_tour
		if show_basket: basket_cue_seen = true
		elif show_lemon: lemon_cue_seen = true
		else: leg_cue_seen = true
		var subject := ball.global_position if show_lemon else world.bowl+Vector3.UP*1.4 if show_basket else journey.leg.global_position+Vector3.UP*.4
		var offset := Vector3(-2,2,4) if show_lemon else Vector3(-3,3.1,7) if show_basket else Vector3(5,3,9)
		camera_cue_target = Transform3D(Basis.IDENTITY,subject+offset).looking_at(subject)
		showing_basket_tour = show_lemon or show_basket
		camera_cue_hold = show_lemon
		if show_lemon: camera_cue_lemon = camera_cue_target
		basket_cue_clock = 0
		basket_cue_duration = speech_time
		if not continue_tour: basket_cue_return = camera.transform
		charging = false
		orbiting = false
		player.drive = Vector3.ZERO
		player.jump_requested = false

func set_pause(value: bool) -> void:
	pause = value
	get_tree().paused = value
	hud.pause_screen.visible = value
	charging = false
	orbiting = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if value else Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and stage != Stage.TITLE and not transitioning: set_pause(not pause)
		if pause or transitioning or stage == Stage.TITLE or basket_cue_clock>=0 or entrance_clock>=0: return
		if event.keycode == KEY_E: interact()
		if event.keycode == KEY_SPACE and player.action.is_empty(): player.jump_requested = true
		if event.keycode == KEY_R and stage == Stage.SEED: recover()
	if pause or transitioning or stage == Stage.TITLE or basket_cue_clock>=0 or entrance_clock>=0: return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT: orbiting = event.pressed
		if event.button_index == MOUSE_BUTTON_LEFT and (held or carried_part != null) and player.action.is_empty():
			if event.pressed:
				charging = true
				power = 0
			elif charging: throw_seed()
	if event is InputEventMouseMotion and (Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or orbiting):
		yaw -= event.relative.x * 0.004
		pitch = clampf(pitch + event.relative.y * 0.003, 0.18, 1.15)

func pickup_part(part: GardenRecoveryPart) -> void:
	part.state = GardenRecoveryPart.State.PICKING
	carried_part = part
	player.action = "pickup"
	player.action_phase = 0
	action_time = 0
	player.visual.rotation.y = atan2(part.position.x-player.position.x,part.position.z-player.position.z)

func request_first_door() -> void:
	if first_door_pending or world.door_open: return
	first_door_pending = true
	first_door_clock = 0
	friend.waiting_for_arm = false
	friend.directed_move = true
	friend.move_target = Vector3(1.7,0.02,GardenWorld.EXIT_Z+1.2)
	say("Khalini n7el lik lbab",4)

func update_first_door(delta: float) -> void:
	if not first_door_pending: return
	if friend.position.distance_to(friend.move_target)<0.9 and friend.is_on_floor():
		first_door_clock += delta
		friend.door_gesture = smoothstep(0,0.7,first_door_clock)
		if first_door_clock > 0.8 and not world.door_open:
			world.open_exit()
			world.reveal_passage()
			journey.prepare_gap()
		if first_door_clock > 2:
			friend.door_gesture = 0
			friend.directed_move = false
			first_door_pending = false

func interact() -> void:
	if transitioning or not player.action.is_empty(): return
	if journey.chapter == GardenJourney.Chapter.DARK:
		var head := journey.reunion.head
		if journey.reunion.phase==GardenReunion.Phase.CAKE and carried_part == null and head != null and head.state == GardenRecoveryPart.State.AVAILABLE and player.position.distance_to(head.position)<2:
			pickup_part(head)
		return
	if journey.chapter != GardenJourney.Chapter.FIRST: return
	if carried_part != null:
		if player.position.distance_to(friend.position) < 3:
			charging = false
			carried_part.put_back()
			carried_part = null
		return
	for part in recovery_parts:
		if part.state == GardenRecoveryPart.State.AVAILABLE and player.global_position.distance_to(part.global_position) < 2:
			pickup_part(part)
			friend.waiting_for_arm = true
			return
	if stage == Stage.PATH and player.position.distance_to(Vector3(0, 0, GardenWorld.EXIT_Z)) < 2.2:
		request_first_door()
		return
	if stage == Stage.SEED and not held and player.position.distance_to(ball.position) < 2.0:
		if throw_in_flight: missed_throw()
		player.action = "pickup"
		player.action_phase = 0
		action_time = 0
		player.visual.rotation.y = atan2(ball.position.x - player.position.x, ball.position.z - player.position.z)
		ball.freeze = true
		ball.collision_layer = 0
		ball.collision_mask = 0
		sound.chime(392)
	elif player.position.distance_to(friend.position) < 3:
		if stage == Stage.PATH: say("Yala namchiw 3end lbab")
		elif stage in [Stage.REVEAL, Stage.GARDEN]: say("Jibi liya lyed dyali o3tiha liya... 3afaak")
		else: say_sequence(INTRO)

func part_returned(_kind: StringName) -> void:
	friend.waiting_for_arm = false
	sound.chime(783.99)
	stage = Stage.PATH
	friend.celebration = 3.5
	var lines: Array[String] = ["Nice! Db khassna l9aw rjel dyali :/", "Yala namchiw 3end lbab"]
	say_sequence(lines)

func forward() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw))

func launch_velocity() -> Vector3:
	return forward() * lerpf(4.8, 10.0, power) + Vector3.UP * lerpf(2.5, 4.5, power)

func throw_seed() -> void:
	if (not held and carried_part == null) or not player.action.is_empty(): return
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
		if carried_part != null:
			if carried_part.state == GardenRecoveryPart.State.PICKING: carried_part.pick_up()
		else:
			held = true
			player.carrying = true
	player.apply_joint_poses()
	if player.action == "throw" and action_time >= THROW_RELEASE and not action_released:
		if carried_part != null:
			var arm := carried_part.kind == &"arm"
			carried_part.throw_part(throw_velocity)
			carried_part = null
			if arm: say("Matb9ayech tla3bi biha -_-", 4)
		else:
			ball.global_position = player.fruit_position()
			ball.freeze = false
			ball.collision_layer = 2
			ball.collision_mask = 1
			ball.linear_velocity = throw_velocity
			ball.angular_velocity = Vector3(3, 1, 2)
			held = false
			throw_in_flight = true
			flight_time = 0
		player.carrying = false
		action_released = true
		lost_time = 0
		sound.chime(329.63)
	if action_time >= ACTION_DURATION:
		player.action = ""
		player.action_phase = 0

func recover() -> void:
	if throw_in_flight: missed_throw()
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
	# Keep the miss punchline visible while returning the fruit.

func missed_throw() -> void:
	if not throw_in_flight: return
	throw_in_flight = false
	say(MISS_JOKES[mini(missed_throws, MISS_JOKES.size() - 1)], 5)
	missed_throws += 1

func planted() -> void:
	if stage != Stage.SEED: return
	throw_in_flight = false
	stage = Stage.REVEAL
	ball.freeze = true
	ball.hide()
	held = false
	player.carrying = false
	charging = false
	for i in range(recovery_parts.size()):
		recovery_parts[i].emerge(world.bowl + Vector3(0, 1.6, 0), world.bowl + Vector3(-1.7, 0.85, 0.8))
	var lines: Array[String] = ["Bravo! Makuntch 3aref rak sportif!" if missed_throws <= 1 else "3la slama... Bravo 3lik!", "Jibi liya lyed dyali o3tiha liya... 3afaak"]
	say_sequence(lines)
	sound.chime(659.25)

func _physics_process(delta: float) -> void:
	if pause: return
	elapsed += delta
	if speech_time > 0:
		speech_time -= delta
		if speech_time <= 0: next_dialogue()
	if stage != Stage.TITLE and not testing and not transitioning and basket_cue_clock<0 and entrance_clock<0:
		var input := Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		player.drive = Vector3(input.x, 0, input.y).rotated(Vector3.UP, yaw).limit_length()
		player.sprint = Input.is_physical_key_pressed(KEY_SHIFT)
	if stage == Stage.TITLE: player.drive = Vector3.ZERO
	if basket_cue_clock>=0 or entrance_clock>=0: player.drive = Vector3.ZERO
	if journey.chapter == GardenJourney.Chapter.FIRST and friend.position.y < -4:
		friend.position = player.position + Vector3(-1, 0.2, 1)
		friend.velocity = Vector3.ZERO
	if journey.chapter == GardenJourney.Chapter.FIRST and not transitioning and player.position.y < -5:
		player.position = Vector3(0, 0.2, 5.7)
		player.velocity = Vector3.ZERO
		if held: recover()
		if carried_part != null:
			carried_part.state = GardenRecoveryPart.State.AVAILABLE
			carried_part = null
			player.carrying = false
			player.action = ""
	if journey.chapter == GardenJourney.Chapter.DARK and not transitioning and player.position.y < -5:
		player.position = journey.reunion.safe_position + Vector3.UP*0.2
		player.velocity = Vector3.ZERO
		if carried_part != null:
			carried_part.state = GardenRecoveryPart.State.AVAILABLE
			carried_part = null
			player.carrying = false
			player.action = ""
	if not player.action.is_empty() or transitioning: player.drive = Vector3.ZERO
	update_action(delta)
	if held:
		if charging:
			player.visual.rotation.y = lerp_angle(player.visual.rotation.y, atan2(forward().x, forward().z), delta * 10)
		ball.global_position = player.fruit_position()
		ball.rotation = Vector3(0, elapsed * 0.5, 0)
		if charging: power = minf(1.0, power + delta * 0.65)
	if journey.chapter == GardenJourney.Chapter.FIRST and stage == Stage.SEED and not held and player.action != "pickup":
		lost_time += delta
		if throw_in_flight: flight_time += delta
		if throw_in_flight and world.basket.scored(previous_ball_position,ball.position): planted()
		elif throw_in_flight and flight_time > 0.55 and ball.position.y < 0.36:
			missed_throw()
		elif ball.position.y < -4 or (lost_time > 5 and ball.position.distance_to(seed_home) > 1): recover()
	if journey.chapter == GardenJourney.Chapter.FIRST and stage in [Stage.REVEAL, Stage.GARDEN, Stage.PATH, Stage.COMPLETE] and bloom < 1:
		bloom = minf(1, bloom + delta / 4.0)
		world.reveal(smoothstep(0, 1, bloom))
		if bloom >= 1:
			if stage == Stage.REVEAL: stage = Stage.GARDEN
			sound.chime(783.99)
	if journey.chapter == GardenJourney.Chapter.FIRST:
		if stage == Stage.PATH and player.position.distance_to(Vector3(0, 0, GardenWorld.EXIT_Z)) < 5:
			request_first_door()
		update_first_door(delta)
		if stage == Stage.PATH and world.door_open and player.position.z < GardenJourney.ENTRY_Z-2 and absf(player.position.x) < GardenWorld.PASSAGE_WIDTH / 2:
			stage = Stage.COMPLETE
			ball.hide()
			journey.enter_gap()
	previous_ball_position = ball.position
	environment.background_color = Color.BLACK
	if friend.follow_target != null:
		var on_passage := world.passage_revealed and player.position.z < GardenWorld.EXIT_Z + 6 and player.position.z > GardenJourney.ENTRY_Z
		if on_passage:
			# Keep distinct running lanes, independent of camera orbit.
			if player.position.x > 0.8: passage_side = -1.0
			elif player.position.x < -0.8: passage_side = 1.0
			var lane_x := clampf(player.position.x + passage_side * 1.6, -1.8, 1.8)
			friend.follow_offset = Vector3(lane_x - player.position.x, 0, -2.5)
		else:
			friend.follow_offset = Vector3(2.3, 0, -3.6).rotated(Vector3.UP, yaw)
		if journey.chapter == GardenJourney.Chapter.FIRST and not (world.passage_revealed and player.position.z < GardenWorld.EXIT_Z + 1):
			var goal := player.position + friend.follow_offset
			var planar := Vector2(goal.x, goal.z).limit_length(GardenWorld.MAP_RADIUS - 0.8)
			friend.follow_offset = Vector3(planar.x, 0, planar.y) - Vector3(player.position.x, 0, player.position.z)
	var focus := player.position + Vector3(0, 0.7, -1)
	var offset := Vector3(0, sin(pitch) * FOLLOW_DISTANCE, cos(pitch) * FOLLOW_DISTANCE).rotated(Vector3.UP, yaw)
	camera.position = camera.position.lerp(focus + offset, 1.0 - exp(-delta * 4))
	camera.look_at(focus)
	if entrance_clock>=0:
		entrance_clock += delta
		camera.transform = entrance_from.interpolate_with(entrance_to,smoothstep(0,ENTRANCE_DURATION,entrance_clock))
		if entrance_clock>=ENTRANCE_DURATION: entrance_clock = -1
	if basket_cue_clock>=0:
		basket_cue_clock += delta
		var cue_from := camera_cue_lemon if showing_basket_tour and not camera_cue_hold and lemon_cue_seen else basket_cue_return
		var cue := cue_from.interpolate_with(camera_cue_target,smoothstep(0,1,basket_cue_clock))
		camera.transform = cue if camera_cue_hold else basket_cue_return.interpolate_with(cue,smoothstep(0,1,basket_cue_duration-basket_cue_clock))
		if basket_cue_clock>=basket_cue_duration: basket_cue_clock = -1
	if screenshot_mode.begins_with("characters"):
		camera.position = Vector3(0, 2.9, 7.6)
		camera.look_at(Vector3(0, 1.4, 2))
	update_hud()
	update_aim()
	var in_passage := (world.passage_revealed and journey.chapter==GardenJourney.Chapter.FIRST and player.position.z<GardenWorld.EXIT_Z-5) or (journey.chapter==GardenJourney.Chapter.DARK and journey.reunion.phase==GardenReunion.Phase.PASSAGE)
	if in_passage:
		if passage_dialogue_chapter != journey.chapter:
			passage_dialogue_chapter = journey.chapter
			passage_joke_clock = 0
		if speech_time<=0 and dialogue_queue.is_empty():
			passage_joke_clock += delta
			var second := journey.chapter == GardenJourney.Chapter.DARK
			var lines := SECOND_PASSAGE_JOKES if second else PASSAGE_JOKES
			var index := second_passage_joke_index if second else passage_joke_index
			if passage_joke_clock>3 and index<lines.size():
				say(lines[index])
				if second: second_passage_joke_index += 1
				else: passage_joke_index += 1
				passage_joke_clock = 0
	if testing: self_test()
	if not screenshot_mode.is_empty() and not capturing and elapsed > 1.5:
		capturing = true
		capture.call_deferred(screenshot_mode)

func _process(_delta: float) -> void:
	if held and not pause: ball.global_position = player.fruit_position()
	if carried_part != null and carried_part.state == GardenRecoveryPart.State.CARRIED and not pause: carried_part.global_position = player.fruit_position()
	if not pause and stage != Stage.TITLE: update_hud()

func update_hud() -> void:
	if screenshot_mode.begins_with("characters"): return
	if stage == Stage.TITLE: return
	hud.interaction_hint.text = ""
	if not transitioning and basket_cue_clock<0 and player.action.is_empty():
		if carried_part!=null:
			hud.interaction_hint.text = "E  •  3ti lyed l sa7bek" if carried_part.kind==&"arm" and player.position.distance_to(friend.position)<3 else "Hold click • aim   /   Release • throw"
		elif held:
			hud.interaction_hint.text = "Hold click • aim   /   Release • throw"
		elif stage==Stage.SEED and player.position.distance_to(ball.position)<2:
			hud.interaction_hint.text = "E  •  Hez limouna"
		else:
			for part in recovery_parts:
				if part.state==GardenRecoveryPart.State.AVAILABLE and player.position.distance_to(part.position)<2:
					hud.interaction_hint.text = "E  •  Hez lyed"
			var head := journey.reunion.head
			if head!=null and head.state==GardenRecoveryPart.State.AVAILABLE and player.position.distance_to(head.position)<2:
				hud.interaction_hint.text = "E  •  Hez rass"
	if friend.visible and not transitioning:
		var speaker := friend.global_position + Vector3.UP * 2.35
		var story := journey.reunion
		if story.speech_from_head and is_instance_valid(story.head):
			speaker = story.head.global_position+Vector3.UP*0.75
		hud.place_speech(camera,speaker)
	else: hud.bubble.hide()
	hud.charge.visible = charging
	hud.charge.value = power * 100

func update_aim() -> void:
	var aiming := (held or carried_part != null) and charging
	var origin := player.throw_origin(THROW_RELEASE / ACTION_DURATION) if aiming else ball.position
	for i in range(aim_dots.size()):
		var dot := aim_dots[i]
		dot.visible = aiming
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
	if entrance_clock>=0: return
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
		player.position = world.bowl+Vector3(0,0.1,3.6)
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
