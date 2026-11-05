extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing=true
 game.test_tick=-100000
 game.start()
 game.set_physics_process(false)
 game.hud.set_process(false)
 game.dialogue_queue.clear()
 game.hud.speech(game.BASKET_INSTRUCTION)
 game.hud.dialogue.visible_characters=12
 game.hud.typing_clock=.03
 game.player.position=game.seed_home+Vector3(0,-.6,.8)
 game.interact()
 assert(game.hud.dialogue.visible_characters==12 and game.hud.typing_clock==.03,"picking lemon cannot restart the instruction")
 print("LEMON_PICKUP_PASS instruction is not repeated or reset")
 game.player.action=""
 game.held=false
 game.player.carrying=false
 game.stage=game.Stage.GARDEN
 var arm=game.recovery_parts[0]
 arm.state=GardenRecoveryPart.State.AVAILABLE
 arm.position=game.player.position
 game.hud.speech("Jibi liya lyed dyali o3tiha liya... 3afaak")
 game.hud.dialogue.visible_characters=12
 game.hud.typing_clock=.03
 var pending: Array[String]=["Next line"]
 game.dialogue_queue=pending.duplicate()
 game.interact()
 assert(game.carried_part==arm,"arm was picked up")
 assert(game.hud.dialogue.visible_characters==12 and game.hud.typing_clock==.03 and game.dialogue_queue==pending,"arm pickup cannot replay dialogue or clear its queue")
 print("ARM_PICKUP_PASS instruction and queue stay intact")
 game.carried_part=null
 game.hud.hide()
 game.world.hide()
 game.ball.hide()
 for part in [&"head",&"arm",&"leg"]: game.companion_parts.restore(part)
 game.player.set_physics_process(false)
 game.friend.set_physics_process(false)
 game.player.position=Vector3(-.9,0,0)
 game.friend.position=Vector3(.9,0,0)
 game.player.action=""
 game.camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 game.camera.size=4.8
 game.camera.position=Vector3(0,1.4,8)
 game.camera.look_at(Vector3(0,1.4,0))
 game.environment.background_color=Color("363e43")
 DirAccess.make_dir_recursive_absolute("res://artifacts/cyan-review")
 var capture := "--capture-outfit" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
 for actor in [game.player,game.friend]:
  actor.visual.rotation.y=0
  actor.animate_pose(1,0,true)
  actor.put_on_birthday_outfit()
 var sweater: MeshInstance3D=game.player.model_root.get_node("Birthday clothing/SWEATER_TORSO")
 var material := sweater.mesh.surface_get_material(0) as BaseMaterial3D
 assert(material.albedo_texture==null and material.albedo_color.g>material.albedo_color.r*2,"sweater is cyan with no stripe texture")
 assert(game.player.outfit_reveal_progress==0,"outfit begins transparent")
 for i in range(65):
  await process_frame
  if i==20:
   assert(game.player.outfit_reveal_progress>0 and game.player.outfit_reveal_progress<1,"clothing fades smoothly rather than popping")
   game.set_pause(true)
   var stopped: float = game.player.outfit_reveal_progress
   for j in range(10): await process_frame
   assert(game.player.outfit_reveal_progress==stopped,"pause freezes outfit transition")
   game.set_pause(false)
  if capture and i%3==0:
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://artifacts/cyan-review/outfit-%03d.png"%i)
 assert(game.player.outfit_reveal_progress==1,"outfit finishes opaque")
 for body in game.companion_parts.modules:
  if body.name==&"TORSO":assert(not body.visible and body.transparency==0,"covered body retires cleanly")
 print("CYAN_OUTFIT_PASS solid material, dissolve, pause and body cleanup")
 game.sound.silence()
 quit()
