extends SceneTree
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func capture(game: Node3D, name: String) -> void:
	if not "--capture-scenario" in OS.get_cmdline_user_args(): return
	game.set_physics_process(false)
	game.camera.position = game.player.position + Vector3(5, 4.3, 6)
	game.camera.look_at(game.player.position.lerp(game.friend.position, 0.45) + Vector3.UP * 1.2)
	if name == "start":
		game.camera.position = Vector3(14, 14, 22)
		game.camera.look_at(Vector3(0, 0, -4))
	game.hud.place_speech(game.camera, game.friend.global_position + Vector3.UP * 2.35)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/scenario-" + name + ".png")
	game.set_physics_process(true)

func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.testing = true
	game.test_tick = -10000
	game.start()
	assert(game.hud.objective.text.is_empty() and game.hud.finish.text.is_empty(), "no floating headings")
	assert(game.companion_parts.missing.values().all(func(value): return value), "head, whole right arm and left leg start missing")
	for part in game.recovery_parts: assert(part.visual.mesh.get_surface_count() > 0, "rewards use actual character meshes")
	await capture(game, "start")
	var before: Vector3 = game.friend.position
	game.player.position = Vector3(-4, 0.1, 4)
	var hopped := false
	for i in range(100):
		await physics_frame
		hopped = hopped or game.friend.position.y > 0.1
		if i == 35: await capture(game, "hop")
	assert(hopped and game.friend.position.x < before.x - 1, "companion follows by hopping")
	game.player.position = Vector3(-1.4, 0.1, 4.5)
	game.interact()
	await frames(60)
	assert(game.held, "fruit picked up")
	game.player.position = Vector3(0, 0.1, 0)
	game.power = 0
	game.throw_seed()
	await frames(170)
	assert(game.stage != game.Stage.SEED, "real throw activates the circle")
	assert(game.missed_throws == 0, "successful throw never gets a miss joke")
	await capture(game, "rewards")
	for part in game.recovery_parts:
		assert(part.state == GardenRecoveryPart.State.AVAILABLE, "reward emerges smoothly into collectible state")
		game.player.position = Vector3(part.home.x, 0.03, part.home.z + 0.8)
		game.interact()
		assert(game.carried_part == part and game.player.action == "pickup", "girl reaches for a body part")
		await frames(45)
		assert(game.player.carrying, "pickup finishes in carry pose")
		assert(part.global_position.distance_to(game.player.fruit_position()) < 0.04, "part stays in her hands")
		var stopped_clock: float = part.clock
		game.set_pause(true)
		await frames(6)
		assert(part.clock == stopped_clock, "pause freezes reward animation")
		game.set_pause(false)
		if part.kind == &"arm":
			game.player.position.y = -6
			await frames(3)
			assert(game.carried_part == null and part.state == GardenRecoveryPart.State.AVAILABLE, "fall returns the part without losing it")
			game.player.position = Vector3(part.home.x, 0.03, part.home.z + 0.8)
			game.interact()
			await frames(45)
			assert(game.carried_part == part and game.player.carrying, "fallen part can be collected again")
		await capture(game, "carrying-" + part.kind)
		game.player.position = game.friend.position + Vector3(0, 0, 0.9)
		game.interact()
		assert(part.state == GardenRecoveryPart.State.RETURNING, "part animates back to companion")
		await frames(55)
		assert(part.state == GardenRecoveryPart.State.RESTORED and not game.companion_parts.missing[part.kind], "correct mesh is restored")
	assert(game.stage == game.Stage.PATH and not game.world.door_open, "restoration unlocks approaching the door")
	assert(game.recovery_parts.size() == 1 and game.recovery_parts[0].kind == &"arm", "only a whole arm appears")
	assert(game.companion_parts.missing[&"head"], "head remains missing for a later stage")
	await frames(80)
	await capture(game, "path")
	assert(game.companion_parts.missing[&"leg"], "left leg remains missing for next scenario")
	game.player.position = Vector3(0, 0.03, GardenWorld.EXIT_Z + 0.8)
	game.interact()
	assert(game.world.door_open, "door can open after restoration")
	await frames(35)
	await capture(game, "door-open")
	game.player.position = Vector3(0, 0.03, GardenJourney.ENTRY_Z - 1)
	await frames(100)
	assert(game.stage == game.Stage.COMPLETE, "crossing door completes first scenario")
	print("SCENARIO_ONE_PASS missing meshes, hopping follow, physical throw, emerging rewards, pickup, whole arm restoration and door")
	game.sound.silence()
	quit()
