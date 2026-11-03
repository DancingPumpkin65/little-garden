extends SceneTree
var game: Node3D
var gentleman_seen := false
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func shot(name: String, backwards := false) -> void:
	if not "--capture-doorway" in OS.get_cmdline_user_args(): return
	var nodes: Array[Node] = [game, game.journey, game.player, game.friend]
	var active: Array[bool] = []
	for node in nodes:
		active.append(node.is_physics_processing())
		node.set_physics_process(false)
	var direction := 1.0 if backwards else -1.0
	game.camera.position = game.player.position + Vector3(0, 5.3, -direction * 12)
	game.camera.look_at(game.player.position + Vector3(0, 0.8, direction * 4))
	game.update_hud()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/doorway-" + name + ".png")
	for i in range(nodes.size()): nodes[i].set_physics_process(active[i])
func walk_to(z: float) -> void:
	game.player.drive = Vector3.FORWARD
	var count := 0
	while game.player.position.z > z and count < 4000:
		var before: Vector3 = game.player.position
		await physics_frame
		if game.first_door_pending and game.friend.door_gesture>0.5: gentleman_seen = true
		assert(game.player.position.distance_to(before) < 0.2, "continuous walking without teleport")
		assert(game.player.position.y > -0.1, "passage and platform have continuous floor")
		assert(game.hud.curtain.color.a == 0 and not game.transitioning, "no fade or input lock through either door")
		count += 1
	assert(count < 4000, "walk reaches destination")
	game.player.drive = Vector3.ZERO
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.testing = true
	game.test_tick = -100000
	game.start()
	game.companion_parts.restore(&"arm")
	game.stage = game.Stage.PATH
	game.say("")
	assert(absf(GardenWorld.EXIT_Z + GardenWorld.MAP_RADIUS) < 0.2, "first door is at floor boundary without space behind it")
	game.player.position = Vector3(0, 0.04, GardenWorld.EXIT_Z + 4)
	game.friend.position = Vector3(0.4, 0.04, GardenWorld.EXIT_Z + 2)
	game.yaw = 0
	game.player.sprint = true
	await frames(30)
	await shot("first-door")
	await walk_to(GardenWorld.EXIT_Z - 4)
	assert(gentleman_seen,"first-stage companion also performs gentleman gesture")
	assert(game.world.door_open and game.journey.prepared, "first door opens onto connected passage")
	await walk_to(GardenJourney.ENTRY_Z + GardenWorld.PASSAGE_LENGTH / 2)
	assert(not game.journey.arrival_gate.visible and not game.journey.near_platform.visible, "long passage looks into darkness before destination appears")
	assert(absf(game.friend.position.x - game.player.position.x) > 1.0, "two running characters have separate lateral lanes")
	assert(absf(game.player.position.x) < 0.25 and game.friend.position.y > -0.1, "companion does not push player sideways or fall from passage")
	await shot("dark-passage")
	await walk_to(GardenJourney.ENTRY_Z + 20)
	assert(game.journey.arrival_gate.visible and not game.journey.arrival_open, "second closed door emerges from darkness")
	await shot("next-door")
	await walk_to(GardenJourney.ENTRY_Z + 5)
	await frames(70)
	assert(game.journey.arrival_open and game.journey.near_platform.visible, "second door opens on approach")
	await shot("next-door-open")
	await walk_to(GardenJourney.ENTRY_Z - 5)
	await frames(120)
	assert(game.journey.entry_sealed and not game.journey.arrival_open, "arrival door closes behind both characters")
	assert(not game.world.visible and not game.world.passage.is_visible_in_tree(), "old map and entire traversed passage disappear")
	for body: CollisionObject3D in game.world.find_children("*", "CollisionObject3D", true, false):
		assert(body.collision_layer == 0, "old floor and passage collisions removed")
	assert(absf(game.journey.arrival_hinge.rotation.y) < 0.05 and game.journey.arrival_body.collision_layer == 1, "closed arrival gate blocks return")
	await shot("closed-behind", true)
	await walk_to(GardenJourney.EDGE_Z + 11)
	await frames(30)
	await shot("large-platform")
	print("DOORWAY_PASS boundary door, long dark passage, second opening door, sealed arrival and retired first map without fades")
	game.sound.silence()
	quit()
