extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing=true
 game.test_tick=-100000
 game.start()
 game.set_physics_process(false)
 game.set_process(false)
 game.dialogue_queue.clear()
 game.hud.speech("")
 game.journey.chapter=GardenJourney.Chapter.DARK
 game.journey.set_physics_process(false)
 var story: GardenReunion=game.journey.reunion
 story.active=true
 story.root=Node3D.new()
 game.world.add_child(story.root)
 story.build_destination()
 story.destination.show()
 game.player.position=Vector3(0,.02,GardenReunion.CAKE_Z+8)
 game.player.set_physics_process(false)
 game.friend.position=Vector3(2.7,.02,GardenReunion.CAKE_Z+2.5)
 game.friend.follow_offset=Vector3(2,0,-3)
 for part in [&"arm",&"leg"]: game.companion_parts.restore(part)
 game.friend.two_legs=true
 story.glass.hits=3
 story.glass.hide()
 story.glass.body.collision_layer=0
 story.on_glass_impact(true)
 game.camera.position=Vector3(6,4,GardenReunion.CAKE_Z+13)
 game.camera.look_at(Vector3(-1,1,GardenReunion.CAKE_Z+3))
 var capture := "--capture-soul" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
 DirAccess.make_dir_recursive_absolute("res://artifacts/soul-review")
 var saw_reach := false
 for i in range(420):
  await physics_frame
  saw_reach=saw_reach or game.friend.action=="pickup"
  game.update_hud()
  if capture and i%6==0:
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://artifacts/soul-review/reunion-%03d.png"%(i/6))
 assert(saw_reach and story.head_reunion==GardenReunion.HeadReunion.DONE,"body approaches, reaches and attaches head")
 assert(not game.companion_parts.missing[&"head"] and not story.head.visible and not story.speech_from_head,"speech and head move to restored body")
 for module in game.companion_parts.modules:
  if module.name in [&"TORSO",&"ARM_LEFT",&"ARM_RIGHT",&"LEG_LEFT",&"LEG_RIGHT",&"FOOT_LEFT",&"FOOT_RIGHT"]:
   assert(not module.visible,"restoring the head cannot expose body meshes through clothing")
 game.friend.dance_remaining=0
 game.friend.garden_random.seed=712
 var visible_frames := 0
 for i in range(600):
  game.player.position.x=sin(i*.006)*8
  game.camera.position=game.player.position+Vector3(0,8,14)
  game.camera.look_at(game.player.position+Vector3(0,1,-1))
  await physics_frame
  if game.friend.garden_point_visible(game.friend.position):visible_frames+=1
 assert(visible_frames>420,"roaming companion stays in view most of the time")
 assert(story.birthday.companion_trail_count>3,"companion leaves growing flowers")
 var flower := GardenBloom.new()
 story.birthday.add_child(flower)
 flower.global_position=game.friend.global_position+Vector3(0,0,1)
 flower.open_now()
 story.birthday.flowers.push_front(flower)
 game.friend.velocity=Vector3.ZERO
 story.ambient_enabled=true
 story.garden_comment_wait=0
 story.update_garden_comments(.016)
 assert(game.hud.dialogue.text=="Had lwarda zwina b7al Salma! :P","flower comment requires a flower nearby")
 assert(game.friend.garden_pause_remaining>0,"companion pauses to admire flower")
 story.garden_comment_wait=0
 story.update_garden_comments(.016)
 assert(game.hud.dialogue.text!="Had lwarda zwina b7al Salma! :P","ambient comments do not repeat consecutively")
 print("GARDEN_SOUL_PASS head reunion, speech anchor, visible roaming, companion flowers and flower comment")
 game.sound.silence()
 quit()
