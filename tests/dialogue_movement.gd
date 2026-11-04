extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing = true
 game.test_tick = -10000
 game.start()
 game.player.position = Vector3(-1.4, 0.1, 4.5)
 game.interact()
 for i in range(65): await physics_frame
 game.player.drive = Vector3.RIGHT
 for i in range(60): await physics_frame
 print("CARRY_FACING_ERROR ", absf(angle_difference(game.player.visual.rotation.y, PI/2)))
 assert(absf(angle_difference(game.player.visual.rotation.y, PI/2)) < 0.1, "carrying must turn fully toward movement")
 game.player.drive = Vector3.ZERO
 for i in range(35): await physics_frame
 var meshes: Array[Node] = game.player.model_root.find_children("*", "MeshInstance3D", true, false)
 var soles := INF
 for mesh in meshes:
  var bounds: AABB = mesh.global_transform * mesh.get_aabb()
  soles = minf(soles, bounds.position.y)
 assert(absf(soles - 0.02) < 0.015, "visible soles rest on the visible ground")
 for i in range(150):
  if game.friend.is_on_floor() and game.friend.hop == GardenCharacter.Hop.REST: break
  await physics_frame
 assert(absf(game.friend.position.y - 0.02) < 0.015, "companion lands on the ground between hops")
 var jumps := [0]
 game.player.jumped.connect(func(): jumps[0] += 1)
 game.player.jump_requested = true
 for i in range(10): await physics_frame
 assert(jumps[0] == 1 and not game.player.is_on_floor(), "jump emits one takeoff sound event")
 assert(game.player.left_arm.rotation.x < -1.7 and game.player.right_arm.rotation.x < -1.7, "jump raises both hands")
 assert(game.player.left_leg.rotation.x < -0.4 and game.player.right_leg.rotation.x > 0.3, "jump splits legs forward and backward")
 for i in range(65): await physics_frame
 assert(game.player.is_on_floor(), "jump lands")
 game.hud.set_process(false)
 var syllables := [0]
 game.hud.letter_spoken.connect(func(_letter: String): syllables[0] += 1)
 game.hud.speech("Hello, garden.")
 assert(game.hud.dialogue.visible_characters == 0, "new message starts empty")
 game.hud._process(0.045)
 assert(game.hud.dialogue.visible_characters == 1 and syllables[0] == 1, "first letter reveals with a voice event")
 game.set_pause(true)
 game.hud._process(1.0)
 assert(game.hud.dialogue.visible_characters == 1, "pause stops typing")
 game.set_pause(false)
 for i in range(80): game.hud._process(0.034)
 assert(game.hud.dialogue.visible_characters == game.hud.dialogue.text.length(), "message completes")
 game.hud.speech("New line")
 assert(game.hud.dialogue.visible_characters == 0, "replacement restarts typing")
 game.hud.speech("ab,cd!e")
 game.hud._process(0.09)
 assert(game.hud.dialogue.visible_characters==1,"typing eases before nearby punctuation")
 game.hud._process(0.067)
 assert(game.hud.dialogue.visible_characters==3,"comma appears after the slowed approach")
 game.hud._process(0.12)
 assert(game.hud.dialogue.visible_characters==3,"comma leaves an extra reading pause")
 game.hud._process(0.04)
 assert(game.hud.dialogue.visible_characters==4,"typing resumes smoothly after punctuation")
 game.hud.dialogue.visible_characters = -1
 game.hud._process(0.1)
 assert(game.hud.dialogue.visible_characters==-1,"Godot's reveal-all state does not restart the typewriter")
 for clip in [game.sound.voice_tone(148), game.sound.jump_tone()]:
  assert(clip.data.size() > 2000, "voice and jump have PCM samples")
  assert(clip.data.decode_s16(1000) != 0, "generated sound is audible")
 print("DIALOGUE_MOVEMENT_PASS typing, murmur events, pause, grounded soles, carry steering, jump pose and sound")
 game.sound.silence()
 quit()

