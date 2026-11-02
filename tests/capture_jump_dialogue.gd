extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.start()
 game.player.position = Vector3(3, 0.1, 1.5)
 for i in range(20): await physics_frame
 game.player.jump_requested = true
 for i in range(12): await physics_frame
 game.camera.position = game.player.position + Vector3(4.5, 1.4, 4)
 game.camera.look_at(game.player.position + Vector3.UP * 1.3)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/jump-pose.png")
 for i in range(70): await physics_frame
 game.say("Had l-bab mkhebbi chi 7aja... jerrbi ttfa7a.")
 for i in range(16): await physics_frame
 game.set_physics_process(false)
 game.camera.position = Vector3(5, 4.2, 5)
 game.camera.look_at(Vector3(1.5, 1.3, -2))
 game.hud.place_speech(game.camera, game.friend.global_position + Vector3.UP * 2.9)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/typing-bubble.png")
 game.sound.voice_tone(148).save_to_wav("res://artifacts/murmur.wav")
 game.sound.jump_tone().save_to_wav("res://artifacts/jump.wav")
 game.sound.silence()
 quit()
