extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing=true
 game.test_tick=-100000
 game.start()
 game.journey.set_physics_process(false)
 game.journey.reunion.set_physics_process(false)
 game.dialogue_queue.clear()
 game.speech_time=0
 game.passage_joke_index=4
 game.passage_joke_clock=2.9
 game.passage_dialogue_chapter=GardenJourney.Chapter.DARK
 game.journey.chapter=GardenJourney.Chapter.DARK
 game.journey.reunion.phase=GardenReunion.Phase.PASSAGE
 game.player.position=Vector3(0,.02,game.journey.reunion.DOOR_Z-10)
 game.friend.position=game.player.position+Vector3(1,0,-2)
 for i in range(20): await physics_frame
 assert(game.hud.dialogue.text=="Yak ssaliti l3cha!?","second passage must speak even after first passage jokes are exhausted")
 game.speech_time=0
 game.dialogue_queue.clear()
 game.passage_joke_clock=2.9
 for i in range(20): await physics_frame
 assert(game.hud.dialogue.text==game.SECOND_PASSAGE_JOKES[1],"second passage follows with the cat joke")
 assert(game.second_passage_joke_index==2,"second passage owns its own progress")
 game.sound.silence()
 print("PASSAGE_DIALOGUE_PASS independent second passage lines")
 quit()

