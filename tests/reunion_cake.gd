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
	if name=="birthday-outfits":
		game.camera.position = focus+Vector3(3,2.9,7)
	if name=="flower-sprout" or name=="flower-open":
		game.camera.position = focus+Vector3(0.8,1.0,2.1)
	if name=="birthday-garden":
		game.camera.position = focus+Vector3(28,22,34)

	game.camera.look_at(focus+Vector3.UP*(0.45 if name.begins_with("flower-") and name!="flower-passage" else 1.2 if name=="birthday-outfits" else 1.8))
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
	assert(story.flowers.size()==9 and story.flower_growth[4]>0.9,"only a few flowers emerge along route")
	assert("9rabna nwasslo, mab9a walo" in seen and "Khalini n7al lik lbab ;)" in seen,"route and gentleman dialogue")
	assert(game.hud.dialogue.text == "Khasski tharssi zaj bach takhdi lcadeau dyalk...","exact cake instruction")
	await frames(100)
	await shot("glass-cake",Vector3(0,0,GardenReunion.CAKE_Z+2))
	game.player.position = Vector3(0,0.03,GardenReunion.CAKE_Z+3)
	game.player.drive = Vector3.FORWARD
	await frames(60)
	game.player.drive = Vector3.ZERO
	assert(game.player.position.z > GardenReunion.CAKE_Z+1.6,"unbroken glass physically blocks walking into the cake")
	# Two real missed throws select the exact head reactions once each.
	for miss in range(2):
		await until(func(): return story.head.state == GardenRecoveryPart.State.AVAILABLE)
		game.player.position = story.head.position+Vector3(0,-story.head.position.y+0.03,0.8)
		game.interact()
		await frames(45)
		game.update_hud()
		var projected: Vector2 = game.camera.unproject_position(story.head.global_position+Vector3.UP*0.75)
		assert(absf(game.hud.bubble_tail.global_position.x-projected.x)<2,"carried head is the speech anchor")
		game.player.position = Vector3(0,0.03,GardenReunion.CAKE_Z+5)
		game.yaw = PI/2
		game.throw_seed()
		await until(func(): return story.head.state == GardenRecoveryPart.State.AVAILABLE,300)
		assert(game.hud.dialogue.text == ("Darbi zaj machi lhwa" if miss==0 else "Wa9ila ma3afach tchayeri..."),"exact ordered miss reaction")
		assert(story.glass.hits==0,"missed head does not damage glass")
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
		assert(game.hud.dialogue.text==story.HIT_LINES[hit-1],"exact glass hit reaction")
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
	await until(func(): return story.birthday.flowers[0].progress>0.25)
	var flower: GardenBloom = story.birthday.flowers[0]
	await shot("flower-sprout",flower.global_position)
	var stem_height := flower.stem.get_aabb().size.y
	assert(flower.scale == Vector3.ONE,"sprouting flower does not expand its root scale")
	game.set_pause(true)
	var paused_age: float = story.birthday.age
	await frames(15)
	assert(story.birthday.age==paused_age,"pause freezes garden transformation")
	game.set_pause(false)
	await frames(90)
	assert(flower.stem.get_aabb().size.y>stem_height and flower.scale==Vector3.ONE,"stem grows before petals finish unfolding")
	await until(func(): return game.hud.dialogue.text==story.BIRTHDAY_LINES[3],2400)
	await frames(100)
	assert(game.hud.bubble.size.y>80,"long birthday line expands its panel and attached shadow")
	await shot("birthday-long-message",game.player.position)
	await until(func(): return game.hud.dialogue.text==story.BIRTHDAY_LINES[-1],2400)
	for line in story.BIRTHDAY_LINES.slice(0,4): assert(line in seen,"birthday greeting sequence is complete")
	assert(game.player.birthday_outfit and game.friend.birthday_outfit,"both outfits switch after third hit")
	if game.player.imported_skeleton != null:
		assert(game.player.outfit_materials.size()>0 and game.friend.outfit_materials.size()>0,"rigged meshes receive clothing materials")
		assert(game.player.outfit_materials[0].get_shader_parameter("sweater")==Color("5ed6e3"),"girl cyan sweater")
		assert(game.friend.outfit_materials[0].get_shader_parameter("pants")==Color("20242c"),"guy black pants")
		var instance := game.player.model_root.find_children("*","MeshInstance3D",true,false)[0] as MeshInstance3D
		var torso := 0
		for surface in range(instance.mesh.get_surface_count()):
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences := weights.size()/vertices.size()
			for vertex in range(vertices.size()):
				for i in range(influences):
					var bind := bones[vertex*influences+i]
					if instance.skin.get_bind_name(bind)==&"body" and weights[vertex*influences+i]>0.95:
						torso += 1
						assert(colors[vertex].g>0.9,"sweater covers torso as well as sleeves")
		assert(torso>20,"torso clothing samples exist")
	assert(story.birthday.hero.progress==1 and story.birthday.trees.size()==18 and story.birthday.flowers.size()==96,"large blossom tree and varied garden finish growing")
	assert(not story.cake_visual.visible and not story.plinth_visual.visible,"cake morphs away into blossom tree")
	await frames(140)
	await shot("flower-open",flower.global_position)
	await shot("birthday-outfits",(game.player.position+game.friend.position)*0.5)
	if DisplayServer.get_name()!="headless": print("GARDEN_RENDER_FPS ",Engine.get_frames_per_second())
	await shot("birthday-garden",Vector3(0,0,GardenReunion.CAKE_Z))
	assert(story.glass.shards.is_empty(),"shards clean up after animation")
	assert(game.companion_parts.missing[&"head"],"throwing head does not incorrectly restore it")
	story.head.state = GardenRecoveryPart.State.THROWN
	story.head.position = Vector3(-2,2,GardenReunion.CAKE_Z-60)
	story.head.velocity = Vector3(0,0,-3)
	await frames(180)
	assert(story.head.state == GardenRecoveryPart.State.AVAILABLE and story.head.home == story.head.return_home,"missed head outside map returns instead of hovering over void")
	game.set_pause(true)
	game.hud.restarted.emit()
	await frames(30)
	game = current_scene
	assert(not paused and game.stage==game.Stage.TITLE and not game.journey.reunion.active,"restart also resets the cake chapter without freezing")
	print("REUNION_CAKE_PASS exact dialogue, leg merge, walking leader, sparse flowers, gentleman door, head pickup, head reactions, birthday garden, growing flowers, clothing and chapter restart")
	game.sound.silence()
	quit()
