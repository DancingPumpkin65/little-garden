extends SceneTree
func _initialize() -> void: run.call_deferred()
func shot(hud: GardenInterface, label: String) -> void:
 if DisplayServer.get_name()=="headless": return
 hud.bubble.position=Vector2(420,280)
 hud.bubble_tail.hide()
 hud.bubble_tail_shadow.hide()
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/interlude-review/"+label+".png")
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://artifacts/interlude-review")
 var hud := GardenInterface.new()
 root.add_child(hud)
 hud.title_screen.hide()
 hud.set_process(false)
 hud.speech("3arfek yala jaya men lkhadma, 3iyana o darek rassek o darak kerchek okulchi... :(")
 await process_frame
 hud.update_speech_size()
 var first_height := hud.bubble.size.y
 await shot(hud,"empty")
 var previous_height := first_height
 var line_growth := 0
 for i in range(1,hud.dialogue.text.length()+1):
  hud.dialogue.visible_characters=i
  hud.update_speech_size()
  if hud.bubble.size.y>previous_height:
   line_growth+=1
   await shot(hud,"line-"+str(line_growth+1))
  previous_height=hud.bubble.size.y
 assert(line_growth>=2 and first_height<hud.bubble.size.y,"bubble grows only as later lines are revealed")
 hud.speech("WEEEEEEEEEEEE!!! (ദ്ദി˙ᗜ˙)")
 hud.dialogue.visible_characters=-1
 hud.update_speech_size()
 await shot(hud,"reaction")
 var preview := hud.title_screen.get_node("Floating character") as GardenTitleCharacter
 hud.title_screen.show()
 var angle := preview.actor.visual.rotation.y
 preview._process(20)
 assert(preview.actor.visual.rotation.y-angle>TAU,"entrance rotation continues past one full turn")
 assert(ProjectSettings.get_setting("application/config/name")=="A Little Interlude")
 hud.queue_free()
 await process_frame
 var game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing=true
 game.test_tick=-100000
 game.start()
 game.dialogue_queue.clear()
 game.hud.speech("")
 game.speech_time=0
 game.world.reveal_passage()
 game.player.position=Vector3(0,.02,GardenWorld.EXIT_Z-7)
 game.passage_dialogue_chapter=GardenJourney.Chapter.FIRST
 game.passage_joke_clock=2.9
 for i in range(20): await physics_frame
 assert(game.hud.dialogue.text==game.PASSAGE_JOKES[0],"quiet passage triggers a joke")
 for i in range(240): await physics_frame
 var focus: Vector3=game.player.position+Vector3(0,.7,-1)
 assert(absf(game.camera.position.distance_to(focus)-game.FOLLOW_DISTANCE)<.2,"passage uses shared follow distance")
 game.player.position=Vector3(0,.02,5)
 for i in range(240): await physics_frame
 focus=game.player.position+Vector3(0,.7,-1)
 assert(absf(game.camera.position.distance_to(focus)-game.FOLLOW_DISTANCE)<.2,"main map uses same follow distance")
 game.sound.silence()
 print("INTERLUDE_UI_PASS progressive bubble height, Unicode reactions, continuous title rotation and name")
 quit()
