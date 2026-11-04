extends SceneTree
var game: Node3D

func _initialize() -> void: run.call_deferred()
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func shot(label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/basket-review/"+label+".png")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://artifacts/basket-review")
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing=true
 game.test_tick=-10000
 game.start()
 await frames(12)
 var basket: GardenBasket=game.world.basket
 var at: Vector3=game.world.bowl
 assert(at.x>5,"basket is on the right")
 assert(basket.scored(at+Vector3(0,2,0),at+Vector3(0,1,0)),"downward crossing scores")
 assert(not basket.scored(at+Vector3(0,1,0),at+Vector3(0,2,0)),"upward crossing cannot score")
 assert(not basket.scored(at+Vector3(1.5,2,0),at+Vector3(1.5,1,0)),"wide miss cannot score")
 game.dialogue_queue.assign([game.BASKET_INSTRUCTION])
 game.next_dialogue()
 var original: Transform3D=game.camera.transform
 await frames(90)
 assert(game.camera.position.distance_to(original.origin)>1,"instruction shows the basket")
 assert(game.hud.bubble.visible,"instruction stays visible away from its speaker")
 await shot("basket-instruction")
 for i in range(1200):
  if game.basket_cue_clock<0: break
  await physics_frame
 assert(game.basket_cue_clock<0 and game.camera.position.distance_to(original.origin)<.2,"camera returns after instruction")
 game.hud.set_process(false)
 game.set_physics_process(false)
 game.set_process(false)
 game.hud.speech(game.INTRO[1])
 game.hud.dialogue.visible_characters=-1
 game.hud.place_speech(game.camera,game.camera.global_position+game.camera.global_basis.z*5)
 assert(game.hud.bubble.visible and not game.hud.bubble_tail.visible,"offscreen speaker gets a readable panel")
 var bounds: Rect2=game.hud.bubble.get_global_rect()
 assert(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(bounds),"long speech fits on screen")
 await shot("offscreen-dialogue")
 game.planted()
 game.player.position=at+Vector3(-3,.02,-1)
 await frames(85)
 game.camera.position=at+Vector3(-4,4,6)
 game.camera.look_at(at+Vector3(-.6,1,0))
 var arm: GardenRecoveryPart=game.recovery_parts[0]
 assert(arm.state==GardenRecoveryPart.State.AVAILABLE and arm.highlight.visible,"available arm has a beacon")
 game.hud.speech("Jibi liya lyed dyali o3tiha liya... 3afaak")
 game.hud.dialogue.visible_characters=-1
 game.update_hud()
 await shot("highlighted-arm")
 print("BASKET_EXPERIENCE_PASS downward scoring, camera cue/return, offscreen speech and arm highlight")
 game.sound.silence()
 quit()
