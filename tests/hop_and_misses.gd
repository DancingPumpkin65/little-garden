extends SceneTree
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func run() -> void:
	var game = load("res://main.tscn").instantiate()
	root.add_child(game)
	game.testing = true
	game.test_tick = -10000
	game.start()
	assert(game.world.MAP_RADIUS > 18, "map is larger")
	for node: MeshInstance3D in game.world.find_children("*", "MeshInstance3D", true, false):
		var at := node.global_position
		assert(at.y < 0.01 or Vector2(at.x - game.world.bowl.x, at.z - game.world.bowl.z).length() < 1.6 or absf(at.z - GardenWorld.EXIT_Z) < 0.4, "map contains only ground, basket and door")
	assert(game.recovery_parts.size() == 1 and game.recovery_parts[0].visual.mesh.get_aabb().size.y > 0.65, "reward is an entire arm")
	for joke in game.MISS_JOKES:
		for letter in joke: assert(letter.unicode_at(0) < 128, "Darija uses Latin letters")
	var phases := {}
	game.player.position = Vector3(-4, 0.1, 4)
	for i in range(110):
		await physics_frame
		phases[game.friend.hop] = true
	assert(phases.has(GardenCharacter.Hop.CROUCH) and phases.has(GardenCharacter.Hop.AIR) and phases.has(GardenCharacter.Hop.LAND), "one-leg hop includes preload, flight and landing")
	game.recover()
	assert(game.missed_throws == 0, "manual reset without a throw is not a miss")
	var last_line := ""
	for attempt in range(2):
		game.player.position = game.seed_home + Vector3(0, -0.6, 0.8)
		game.interact()
		await frames(60)
		assert(game.held, "fruit can be retried")
		game.player.position = Vector3(0, 0.1, 0)
		game.yaw = PI / 2
		game.power = 0
		game.throw_seed()
		await frames(160)
		assert(game.missed_throws == attempt + 1, "one joke per missed physics throw")
		assert(game.hud.dialogue.text != last_line and game.hud.dialogue.text in game.MISS_JOKES, "miss jokes rotate")
		last_line = game.hud.dialogue.text
		await frames(180)
		assert(game.missed_throws == attempt + 1, "bounces and recovery do not repeat a joke")
		game.recover()
	assert(not game.world.door_open, "misses do not unlock the door")
	print("HOP_AND_MISSES_PASS dedicated hop, minimal larger map, whole arm and one rotating joke per miss")
	game.sound.silence()
	quit()
