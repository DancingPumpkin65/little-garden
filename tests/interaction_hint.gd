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
 game.basket_cue_clock=-1
 game.player.position=game.ball.position
 game.update_hud()
 assert(game.hud.interaction_hint.text=="E  •  Hez limouna","pickup separator must be a bullet, not corrupted UTF-8")
 game.held=true
 game.update_hud()
 assert(game.hud.interaction_hint.text=="Hold click • aim   /   Release • throw")
 game.held=false
 game.stage=game.Stage.GARDEN
 var arm=game.recovery_parts[0]
 arm.state=GardenRecoveryPart.State.AVAILABLE
 arm.position=game.player.position
 game.update_hud()
 assert(game.hud.interaction_hint.text=="E  •  Hez lyed")
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/hint-fixed.png")
 game.sound.silence()
 print("INTERACTION_HINT_PASS lemon, throwing and hand separators")
 quit()
