extends SceneTree
var game: Node3D
var seen: Array[String] = []
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
	for i in range(count): await physics_frame
func until(condition: Callable, limit := 2500) -> void:
	for i in range(limit):
		if condition.call(): return
		if not game.hud.dialogue.text.is_empty() and not game.hud.dialogue.text in seen: seen.append(game.hud.dialogue.text)
		await physics_frame
	assert(false,"timed out in reunion/cake story")
func shot(name: String, focus: Vector3) -> void:
	if not "--capture-reunion" in OS.get_cmdline_user_args(): return
	var nodes: Array[Node] = [game,game.journey,game.journey.reunion,game.player,game.friend]
	var states: Array[bool] = []
	for node in nodes:
		states.append(node.is_physics_processing())
		node.set_physics_process(false)
	game.camera.position = focus+Vector3(3,5.8,17)
	game.camera.look_at(focus+Vector3.UP*1.8)
	game.update_hud()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://artifacts/reunion-"+name+".png")
	for i in range(nodes.size()): nodes[i].set_physics_process(states[i])
func run() -> void:
	game = load("res://main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.testing = true
	game.test_tick = -100000
	game.start()
	game.companion_parts.restore(&"arm")
	game.journey.chapter = GardenJourney.Chapter.GAP
	game.journey.enter_dark()
	await until(func(): return game.journey.chapter == GardenJourney.Chapter.DARK and not game.journey.crossing)
	var story: GardenReunion = game.journey.reunion
	await until(func(): return story.phase == GardenReunion.Phase.INTRO)
	assert(game.hud.dialogue.text == "Wow n9azti 3endi :')","exact reunion greeting")
	await shot("greeting",Vector3(0,0,-1))
	await until(func(): return story.phase == GardenReunion.Phase.MERGE)
	assert("Chufi chkoun l9it mna9ez m3aya... Rajli" in seen,"second reunion line")
	await frames(35)
	await shot("leg-merging",Vector3(0,0,-1))
	await until(func(): return story.phase == GardenReunion.Phase.READY)
	assert(game.friend.two_legs and not game.companion_parts.missing[&"leg"] and not story.leg.visible,"leg merges and restores two-leg controller")
	await until(func(): return story.phase == GardenReunion.Phase.LEAD)
	assert("Db yala l9aw rass dyali :?" in seen and "Tab3ini n9albo 3lih" in seen,"exact search dialogue")
	await frames(150)
	assert(game.friend.position.z < -4,"companion now leads using a walk")
	var waited_at: Vector3 = game.friend.position
	await frames(150)
	assert(game.friend.position.distance_to(game.player.position)<11,"leader waits for player")
	var door_pose_seen := false
	var passage_shot := false
	for i in range(5000):
		if not game.hud.dialogue.text.is_empty() and not game.hud.dialogue.text in seen: seen.append(game.hud.dialogue.text)
		var target: Vector3 = game.friend.position+Vector3(-1.0,0,3)
		var offset: Vector3 = target-game.player.position
		offset.y = 0
		game.player.drive = offset.normalized() if offset.length()>0.6 else Vector3.ZERO
		await physics_frame
		if story.phase == GardenReunion.Phase.DOOR and game.friend.door_gesture>0.8 and not door_pose_seen:
			door_pose_seen = true
			await shot("gentleman-door",Vector3(0,0,GardenReunion.DOOR_Z+2))
		if story.phase == GardenReunion.Phase.PASSAGE and game.player.position.z < GardenReunion.DOOR_Z-25 and not passage_shot:
			passage_shot = true
			await shot("flower-passage",game.player.position)
		if story.phase == GardenReunion.Phase.CAKE and story.introduced: break
	game.player.drive = Vector3.ZERO
	assert(story.phase == GardenReunion.Phase.CAKE and story.introduced,"both arrive at cake map")
	assert(door_pose_seen and story.door.opened,"companion performs reach/bow and opens door")
	assert(story.flowers.size()==9 and story.flower_scales[4]>0.9,"only a few flowers emerge along route")
	assert("9rabna nwasslo, mab9a walo" in seen and "Khalini n7al lik lbab ;)" in seen,"route and gentleman dialogue")
	assert(game.hud.dialogue.text == "Khasski tharssi zaj bach takhdi lcadeau dyalk...","exact cake instruction")
	await frames(100)
	await shot("glass-cake",Vector3(0,0,GardenReunion.CAKE_Z+2))
	game.player.position = Vector3(0,0.03,GardenReunion.CAKE_Z+3)
	game.player.drive = Vector3.FORWARD
	await frames(60)
	game.player.drive = Vector3.ZERO
	assert(game.player.position.z > GardenReunion.CAKE_Z+1.6,"unbroken glass physically blocks walking into the cake")
	for hit in range(1,4):
		await until(func(): return story.head.state == GardenRecoveryPart.State.AVAILABLE)
		game.player.position = story.head.position+Vector3(0,-story.head.position.y+0.03,0.8)
		game.interact()
		await frames(45)
		assert(game.carried_part==story.head and game.player.carrying,"head pickup uses reach and carried attachment")
		if hit==1: await shot("holding-head",game.player.position+Vector3(0,0,-2))
		game.player.position = Vector3(0,0.03,GardenReunion.CAKE_Z+5)
		game.yaw = 0
		game.power = 0
		game.throw_seed()
		await until(func(): return story.glass.hits == hit,240)
		assert(story.head.hit_this_throw,"actual physical head flight hits glass once")
		assert(story.glass.broken == (hit==3),"glass breaks only on third hit")
		if hit < 3:
			assert(story.glass.cracks.get_child_count()>0,"hits add visible cracks")
			await shot("crack-"+str(hit),Vector3(0,0,GardenReunion.CAKE_Z+1))
		else:
			assert(story.glass.shards.size()==30 and not story.glass.shell.visible and story.glass.body.collision_layer==0,"third hit emits shards and removes shell")
			await frames(12)
			await shot("shattered",Vector3(0,0,GardenReunion.CAKE_Z+1))
		await frames(100)
		assert(story.glass.hits==hit,"one throw cannot register repeated hits")
	await frames(100)
	assert(story.glass.shards.is_empty(),"shards clean up after animation")
	assert(game.companion_parts.missing[&"head"],"throwing head does not incorrectly restore it")
	story.head.state = GardenRecoveryPart.State.THROWN
	story.head.position = Vector3(-2,2,GardenReunion.NEXT_ENTRY-55)
	story.head.velocity = Vector3(0,0,-3)
	await frames(180)
	assert(story.head.state == GardenRecoveryPart.State.AVAILABLE and story.head.home == story.head.return_home,"missed head outside map returns instead of hovering over void")
	game.set_pause(true)
	game.hud.restarted.emit()
	await frames(30)
	game = current_scene
	assert(not paused and game.stage==game.Stage.TITLE and not game.journey.reunion.active,"restart also resets the cake chapter without freezing")
	print("REUNION_CAKE_PASS exact dialogue, leg merge, walking leader, sparse flowers, gentleman door, head pickup, three physical glass hits and chapter restart")
	game.sound.silence()
	quit()
