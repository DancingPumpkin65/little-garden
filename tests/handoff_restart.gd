extends SceneTree
var game: Node3D
var failures := 0
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func shot(name: String) -> void:
	if not "--capture-handoff" in OS.get_cmdline_user_args(): return
	var nodes: Array[Node] = [game, game.journey, game.player, game.friend]
	var active: Array[bool] = []
	for node in nodes:
		active.append(node.is_physics_processing())
		node.set_physics_process(false)
	game.camera.position = game.friend.position + Vector3(4, 3, 7)
	game.camera.look_at(game.friend.position + Vector3.UP * 1.2)
	game.hud.bubble.hide()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/handoff-" + name + ".png")
	for i in range(nodes.size()): nodes[i].set_physics_process(active[i])
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.testing = true
	game.test_tick = -100000
	game.start()
	game.planted()
	await frames(100)
	var part: GardenRecoveryPart = game.recovery_parts[0]
	game.player.position = Vector3(part.home.x, 0.03, part.home.z + 0.8)
	game.interact()
	await frames(60)
	await shot("waiting")
	var waiting_at: Vector3 = game.friend.position
	game.player.drive = Vector3.RIGHT
	await frames(100)
	game.player.drive = Vector3.ZERO
	check(Vector2(game.friend.position.x - waiting_at.x, game.friend.position.z - waiting_at.z).length() < 0.1, "companion must wait in place while arm is being returned")
	game.player.position = game.friend.position + Vector3(0, 0, 0.8)
	game.interact()
	await frames(60)
	game.friend.celebration = 0
	game.friend.right_arm.rotation.x = 0
	game.player.position += Vector3(6, 0, -5)
	check(not game.companion_parts.missing[&"arm"], "returned arm is present in the rig")
	var arm_moved := false
	var captured := false
	for i in range(100):
		await physics_frame
		if game.friend.hop == GardenCharacter.Hop.AIR and absf(game.friend.right_arm.rotation.x) > 0.1:
			arm_moved = true
			if not captured and game.friend.hop_clock > 0.12:
				await shot("restored-hop")
				captured = true
	check(arm_moved, "restored right arm must participate in one-leg hop")
	game.set_pause(true)
	game.hud.restarted.emit()
	await frames(30)
	game = current_scene
	check(not paused, "Start again must clear SceneTree pause before reloading")
	check(game.stage == game.Stage.TITLE and not game.journey.prepared and game.companion_parts.missing[&"arm"], "restart resets title, quest and missing arm")
	game.testing = true
	game.test_tick = -100000
	game.start()
	var before: Vector3 = game.player.position
	game.player.drive = Vector3.RIGHT
	await frames(30)
	check(game.player.position.distance_to(before) > 0.4, "movement must work after restart and Start")
	paused = false
	game.sound.silence()
	if failures == 0: print("HANDOFF_RESTART_PASS stationary handoff, restored arm hop and playable restart")
	quit(1 if failures > 0 else 0)
