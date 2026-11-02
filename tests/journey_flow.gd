extends SceneTree
var game: Node3D
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func until(condition: Callable, limit: int = 1800) -> void:
	for i in range(limit):
		if condition.call(): return
		await physics_frame
	assert(false, "timed out waiting for story beat")
func shot(name: String) -> void:
	if not "--capture-journey" in OS.get_cmdline_user_args(): return
	var nodes: Array[Node] = [game, game.journey, game.player, game.friend]
	var active: Array[bool] = []
	for node in nodes:
		active.append(node.is_physics_processing())
		node.set_physics_process(false)
	if game.journey.chapter == GardenJourney.Chapter.GAP:
		game.camera.position = Vector3(25, 26, GardenJourney.ENTRY_Z - 10)
		game.camera.look_at(Vector3(0, 0.7, GardenJourney.EDGE_Z - 12))
	elif game.journey.chapter == GardenJourney.Chapter.DARK:
		game.camera.position = Vector3(0, 5.5, 13)
		game.camera.look_at(Vector3(0, 1, -2))
	game.update_hud()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/journey-" + name + ".png")
	for i in range(nodes.size()): nodes[i].set_physics_process(active[i])
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.testing = true
	game.test_tick = -100000
	game.start()
	assert(game.hud.dialogue.text == "Salam Salma, labas?", "exact opening greeting")
	var intro_seen: Array[String] = []
	await frames(40)
	await shot("greeting")
	for i in range(950):
		if game.hud.dialogue.text in game.INTRO and not game.hud.dialogue.text in intro_seen: intro_seen.append(game.hud.dialogue.text)
		await physics_frame
	assert(intro_seen.size() == 4 and game.dialogue_queue.is_empty(), "all four opening lines play in order")
	assert(game.environment.background_color == Color.BLACK and game.world.ground_material.albedo_color == Color.WHITE, "white ground and black world")
	game.player.drive = Vector3.FORWARD
	await frames(100)
	game.player.drive = Vector3.ZERO
	await frames(30)
	assert(game.dust.emitted > 2, "walking emits gray dust")
	assert(game.friend.position.z < game.player.position.z and absf(game.friend.position.x - game.player.position.x) > 0.8, "companion stays ahead and beside player")
	for i in range(5):
		game.throw_in_flight = true
		game.missed_throw()
		assert(game.hud.dialogue.text == game.MISS_JOKES[i], "exact ordered miss line")
	assert(game.MISS_JOKES[2] == 'Ma3lich had lmara tjibiha, "TALTA TABTA"', "quote is preserved")
	game.missed_throws = 0
	game.player.position = game.seed_home + Vector3(0, -0.6, 0.8)
	game.interact()
	await frames(60)
	game.player.position = Vector3(0, 0.1, 0)
	game.yaw = 0
	game.power = 0
	game.throw_seed()
	await until(func(): return game.stage != game.Stage.SEED)
	assert(game.hud.dialogue.text == "Bravo! Makuntch 3aref rak sportif! :3", "one/two-try success line")
	var part: GardenRecoveryPart = game.recovery_parts[0]
	await until(func(): return part.state == GardenRecoveryPart.State.AVAILABLE)
	game.player.position = Vector3(part.home.x, 0.03, part.home.z + 0.8)
	game.interact()
	await frames(45)
	game.yaw = PI / 2
	game.throw_seed()
	await frames(28)
	assert(game.hud.dialogue.text == "Matb9ayech tla3bi biha -_-" and game.carried_part == null, "thrown hand gets requested reaction")
	await until(func(): return part.state == GardenRecoveryPart.State.AVAILABLE)
	game.player.position = Vector3(part.home.x, 0.03, part.home.z + 0.8)
	game.interact()
	await frames(45)
	game.player.position = game.friend.position + Vector3(0, 0, 0.8)
	game.interact()
	await frames(55)
	assert(game.hud.dialogue.text == "Nice! Db khassna l9aw rjel dyali" and game.friend.celebration > 0, "restoration dialogue and celebration")
	assert(not game.world.door_open, "door waits until player approaches")
	game.player.position = Vector3(0, 0.04, GardenWorld.EXIT_Z + 1.5)
	await frames(3)
	assert(game.world.passage_revealed and game.world.door_open, "approach reveals narrow passage")
	await frames(60)
	await shot("passage")
	game.yaw = 0
	game.player.position = Vector3(0, 0.04, GardenWorld.EXIT_Z - 3)
	game.player.drive = Vector3.FORWARD
	var walked := 0
	while game.player.position.z > GardenJourney.ENTRY_Z - 2 and walked < 4000:
		await physics_frame
		assert(game.hud.curtain.color.a == 0 and not game.transitioning, "passage remains seamless without fade or input lock")
		assert(game.player.position.y > -0.1, "continuous floor all the way along passage")
		walked += 1
	assert(walked < 4000, "walk reaches enlarged platform")
	game.player.drive = Vector3.ZERO
	await frames(60)
	assert(game.journey.chapter == GardenJourney.Chapter.GAP, "walk enters quest in same world")
	assert(game.journey.entry_sealed and not game.journey.arrival_open, "arrival door closes after both characters enter new area")
	assert(game.journey.far_platform.scale.x == 70, "wide quest platforms")
	game.player.drive = Vector3.FORWARD
	await until(func(): return game.player.position.z < GardenJourney.EDGE_Z + 10)
	game.player.drive = Vector3.ZERO
	await frames(2)
	assert(game.hud.dialogue.text == "Hahiya yedi fjiha lakhra. Kighandiro nakhdoha?", "exact gap opening dialogue")
	await frames(35)
	await shot("gap-leg")
	await until(func(): return game.journey.beat == GardenJourney.Beat.JUMP)
	await frames(14)
	await shot("failed-jump")
	await until(func(): return game.journey.beat == GardenJourney.Beat.FALLEN)
	assert(not game.friend.visible and game.journey.far_dark, "companion does not respawn and far platform goes black")
	await frames(90)
	assert(not game.friend.visible, "no normal fall recovery in gap chapter")
	await shot("hidden-exit")
	game.player.position = Vector3(0, 0.025, GardenJourney.EDGE_Z + 0.5)
	game.player.drive = Vector3.FORWARD
	game.player.jump_requested = true
	await until(func(): return game.journey.chapter == GardenJourney.Chapter.DESCENT)
	await until(func(): return game.hud.curtain.color.a > 0.99)
	await shot("fall-black")
	await until(func(): return game.journey.chapter == GardenJourney.Chapter.DARK and not game.journey.crossing)
	game.player.drive = Vector3.ZERO
	await frames(75)
	assert(game.player.is_on_floor() and game.friend.visible and game.journey.leg.visible, "player drops into vast floor with guy and leg")
	assert(game.journey.leg.position.z < game.player.position.z, "left leg is ahead at final stopping point")
	await shot("dark-arrival")
	print("JOURNEY_PASS exact dialogue, dust, front-side companion, hand throw, passage, failed jump, hidden fall and dark arrival")
	game.sound.silence()
	quit()
