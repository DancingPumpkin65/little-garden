extends SceneTree
func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing=true
 game.test_tick=-100000
 game.start()
 game.set_physics_process(false)
 game.set_process(false)
 game.hud.hide()
 game.world.hide()
 Shapes.box(game,Vector3(0,-.05,0),Vector3(35,.1,35),Shapes.material(Color("949b96")))
 game.ball.hide()
 game.player.set_physics_process(false)
 game.player.position=Vector3(0,.02,0)
 game.friend.position=Vector3(2,.02,1)
 for part in [&"arm",&"leg"]: game.companion_parts.restore(part)
 game.friend.put_on_birthday_outfit()
 game.friend.follow_offset=Vector3(2,0,1)
 game.friend.celebrate_in_garden(game.player)
 game.friend.garden_random.seed=1234
 game.camera.position=Vector3(4.5,2.9,6)
 game.camera.look_at(Vector3(2,1.2,1))
 game.environment.background_color=Color("4c666d")
 DirAccess.make_dir_recursive_absolute("res://artifacts/companion-review")
 var capture := "--capture-companion" in OS.get_cmdline_user_args() and DisplayServer.get_name()!="headless"
 var first_arm: float = game.friend.left_arm.rotation.x
 for i in range(60):
  await frames(4)
  if capture:
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://artifacts/companion-review/dance-%03d.png"%i)
 assert(absf(game.friend.left_arm.rotation.x-first_arm)>.1,"dance articulates arms")
 game.set_pause(true)
 var paused_dance: float=game.friend.dance_remaining
 await frames(20)
 assert(game.friend.dance_remaining==paused_dance,"pause freezes dance")
 game.set_pause(false)
 if not capture:
  game.friend.garden_hop_interval=Vector2(.5,.7)
  game.friend.garden_hop_wait=.4
  game.friend.garden_style_interval=Vector2(.6,.8)
  game.friend.garden_run_chance=.5
 else:
  game.friend.garden_hop_wait=4
 var saw_run := false
 var saw_walk := false
 var saw_hop := false
 for i in range(720):
  game.player.position=Vector3(sin(i*.018)*7,.02,-cos(i*.018)*5)
  await physics_frame
  saw_run=saw_run or game.friend.sprint
  saw_walk=saw_walk or (not game.friend.sprint and game.friend.velocity.length()>.2)
  saw_hop=saw_hop or game.friend.velocity.y>1
  if capture and i%4==0:
   game.camera.position=game.friend.position+Vector3(4.5,2.7,6)
   game.camera.look_at(game.friend.position+Vector3.UP*1.2)
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://artifacts/companion-review/follow-%03d.png"%(i/4))
 assert(saw_run and saw_walk and saw_hop,"garden follow varies walks, runs and grounded hops")
 assert(game.friend.global_position.distance_to(game.player.global_position)<9,"companion keeps up")
 await frames(240)
 assert(Vector2(game.friend.velocity.x,game.friend.velocity.z).length()<.1,"companion settles beside stopped player")
 print("GARDEN_COMPANION_PASS dance, pause, varied following, catch-up and stopping")
 game.sound.silence()
 quit()
