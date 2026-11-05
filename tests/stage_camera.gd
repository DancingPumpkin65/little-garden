extends SceneTree
var game: Node3D
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func shot(name: String) -> void:
 if DisplayServer.get_name()=="headless":return
 var running:=game.is_physics_processing()
 game.set_physics_process(false)
 if name.begins_with("leap-"):
  var focus:=Vector3(1.5,.8,GardenJourney.EDGE_Z+1)
  game.camera.position=focus+Vector3(7,4,8)
  game.camera.look_at(focus)
  game.update_hud()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/stage-camera/"+name+".png")
 game.set_physics_process(running)
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://artifacts/stage-camera")
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing=true
 game.test_tick=-100000
 game.start()
 assert(game.camera.position.y>20,"start camera is overhead")
 await shot("entrance-overhead")
 await frames(75)
 await shot("entrance-mid")
 await frames(85)
 assert(game.entrance_clock<0 and game.camera.position.y<10,"entrance settles into player view")
 await shot("entrance-player")
 var sequence: Array[String]=[game.LEMON_INSTRUCTION,game.BASKET_INSTRUCTION]
 game.say_sequence(sequence)
 await frames(90)
 assert(game.hud.dialogue.text==game.LEMON_INSTRUCTION,"lemon shot has its own instruction")
 assert(game.camera.position.distance_to(game.camera_cue_lemon.origin)<.1,"lemon camera frames lemon")
 await shot("lemon")
 for i in range(1000):
  if game.hud.dialogue.text==game.BASKET_INSTRUCTION:break
  await physics_frame
 await frames(90)
 assert(game.camera.position.distance_to(game.camera_cue_target.origin)<.1,"basket shot frames basket")
 assert(game.hud.sticker.sticker_name=="ok","basket uses ok sticker")
 game.hud.dialogue.visible_characters=-1
 await shot("basket")
 for i in range(1000):
  if game.basket_cue_clock<0:break
  await physics_frame
 assert(game.basket_cue_clock<0,"camera returns after both instructions")
 game.world.reveal_passage()
 game.companion_parts.restore(&"arm")
 game.friend.follow_target=null
 game.player.position=Vector3(0,.03,GardenJourney.ENTRY_Z-3)
 game.friend.position=Vector3(1.5,.03,GardenJourney.ENTRY_Z-5)
 game.journey.enter_gap()
 assert(game.journey.dialogue_started and game.leg_cue_seen,"leg camera starts at doorway entry")
 assert(game.player.position.z>GardenJourney.EDGE_Z+30,"player need not approach the gap")
 await frames(90)
 await shot("leg-entry")
 for i in range(1600):
  if game.journey.beat==GardenJourney.Beat.RUN:break
  await physics_frame
 assert(game.journey.beat==GardenJourney.Beat.RUN,"leg dialogue completes before approach")
 game.player.position=Vector3(0,.03,GardenJourney.EDGE_Z+8)
 game.friend.position=Vector3(1.5,.03,GardenJourney.EDGE_Z+4)
 game.friend.velocity=Vector3.ZERO
 var saw_crouch:=false
 var saw_air:=false
 for i in range(240):
  await physics_frame
  if game.journey.beat==GardenJourney.Beat.TAKEOFF:
   saw_crouch=true
  if game.journey.beat==GardenJourney.Beat.JUMP:
   saw_air=true
   if game.friend.velocity.y>0: assert(game.friend.knees[1].rotation.x>.3,"visible knee bends during flight")
  if DisplayServer.get_name()!="headless" and i%3==0:await shot("leap-%03d"%i)
  if game.journey.beat==GardenJourney.Beat.FALLEN:break
 assert(saw_crouch and saw_air and game.journey.beat==GardenJourney.Beat.FALLEN,"one-leg anticipation, leap and fall all execute")
 assert(not game.friend.visible,"companion stays fallen")
 print("STAGE_CAMERA_PASS overhead entrance, separate lemon/basket shots, doorway leg cue and one-leg crouch/leap/fall")
 game.sound.silence()
 quit()
