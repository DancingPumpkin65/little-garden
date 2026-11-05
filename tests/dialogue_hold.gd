extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing=true
 game.test_tick=-100000
 game.start()
 var lines: Array[String]=["Happy birthday!!!","Salam Salma, labas? :)"]
 game.say_sequence(lines)
 var elapsed:=0.0
 while game.hud.dialogue.visible_characters<lines[0].length():
  await process_frame
  elapsed+=1.0/60
  assert(elapsed<10,"first line must finish")
 for i in range(170): await physics_frame
 assert(game.hud.dialogue.text==lines[0],"completed line and sticker remain for three seconds")
 for i in range(20): await physics_frame
 assert(game.hud.dialogue.text==lines[1],"next line starts after the reading pause")
 game.say("Test",0)
 assert(game.speech_time>=game.hud.typing_duration("Test")+3,"standalone lines also get three seconds")
 game.sound.silence()
 print("DIALOGUE_HOLD_PASS completed phrase stays three seconds before next line")
 quit()
