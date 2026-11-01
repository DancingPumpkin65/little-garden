extends SceneTree
var game: Node3D
func _initialize() -> void:
 run.call_deferred()
func shot(name: String) -> void:
 game.camera.position = game.player.position + Vector3(-3.7, 2.5, -4.5)
 game.camera.look_at(game.player.position + Vector3(0, 1.35, 0))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/interaction-" + name + ".png")
func frames(count: int) -> void:
 for i in range(count): await physics_frame
func run() -> void:
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing = false
 game.set_physics_process(false)
 game.start()
 game.world.hide()
 game.player.position = Vector3(-1.4, 0.1, 4.5)
 await frames(3)
 game.interact()
 for i in range(48):
  game._physics_process(1.0/60)
  await physics_frame
  if i == 14: await shot("reach")
  if i == 42: await shot("carry")
 game.throw_seed()
 for i in range(44):
  game._physics_process(1.0/60)
  await physics_frame
  if i == 17: await shot("windup")
  if i == 27: await shot("release")
  if i == 40: await shot("follow-through")
 game.world.show()
 game.player.position = Vector3(1, 0.1, -1)
 game.say("That little seed has been waiting for you.")
 game.camera.position = Vector3(5, 4.2, 5)
 game.camera.look_at(Vector3(1.5, 1.3, -2))
 game.hud.place_speech(game.camera, game.friend.global_position + Vector3.UP * 2.9)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/interaction-bubble.png")
 game.sound.silence()
 quit()

