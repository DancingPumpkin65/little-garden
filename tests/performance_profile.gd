extends SceneTree
var game: Node3D
var results: Array[Dictionary]=[]
var tag:="baseline"
func _initialize() -> void: run.call_deferred()
func settle(n: int=40) -> void:
 for i in range(n):await process_frame
func sample(label: String,n: int=180) -> void:
 await settle()
 var times: Array[float]=[]
 var draws: Array[float]=[]
 var primitives: Array[float]=[]
 var previous:=Time.get_ticks_usec()
 for i in range(n):
  await process_frame
  var now:=Time.get_ticks_usec()
  times.append((now-previous)/1000.0)
  previous=now
  draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
  primitives.append(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
 times.sort()
 var row: Dictionary={"scene":label,"p50_ms":snappedf(times[n/2],.01),"p95_ms":snappedf(times[int(n*.95)],.01),"max_ms":snappedf(times[-1],.01),"draw_calls":draws.reduce(func(a:float,b:float)->float:return a+b,0.0)/n,"primitives":primitives.reduce(func(a:float,b:float)->float:return a+b,0.0)/n,"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"static_mb":snappedf(Performance.get_monitor(Performance.MEMORY_STATIC)/1048576,.1),"video_mb":snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)/1048576,.1)}
 results.append(row)
 print("PROFILE ",JSON.stringify(row))
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/performance/"+tag+"-"+label+".png")
func run() -> void:
 if DisplayServer.get_name()=="headless":push_error("performance measurements require native renderer");quit(1);return
 root.mode=Window.MODE_WINDOWED
 root.size=Vector2i(1280,800)
 DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
 Engine.max_fps=0
 for arg in OS.get_cmdline_user_args():
  if arg.begins_with("--profile-tag="):tag=arg.trim_prefix("--profile-tag=")
 DirAccess.make_dir_recursive_absolute("res://artifacts/performance")
 var start:=Time.get_ticks_usec()
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 game.testing=true
 game.test_tick=-100000
 var startup_ms:=(Time.get_ticks_usec()-start)/1000.0
 await sample("title",120)
 game.start()
 await get_tree_timer(2.5)
 game.dialogue_queue.clear()
 game.speech_time=0
 game.hud.speech("Salma, had nhar dyalk. Khodi ra7tek")
 await sample("first-stage")
 game.world.reveal_passage()
 game.player.position=Vector3(0,.03,GardenWorld.EXIT_Z-30)
 await sample("passage")
 game.player.position=Vector3(0,.03,GardenJourney.ENTRY_Z-3)
 game.friend.position=game.player.position+Vector3(1.5,0,-2)
 game.journey.enter_gap()
 game.dialogue_queue.clear()
 game.speech_time=0
 game.basket_cue_clock=-1
 game.journey.set_physics_process(false)
 await sample("gap")
 game.set_physics_process(false)
 game.set_process(false)
 game.world.retire()
 game.journey.scene_root.hide()
 game.journey.chapter=GardenJourney.Chapter.DARK
 var story: GardenReunion=game.journey.reunion
 story.active=true
 story.root=Node3D.new()
 game.add_child(story.root)
 story.build_destination()
 story.destination.show()
 game.player.position=Vector3(0,.03,GardenReunion.CAKE_Z+8)
 game.friend.follow_target=null
 game.friend.position=Vector3(2.7,.03,GardenReunion.CAKE_Z+2.5)
 game.camera.position=Vector3(6,4,GardenReunion.CAKE_Z+13)
 game.camera.look_at(Vector3(-1,1,GardenReunion.CAKE_Z+3))
 story.set_physics_process(false)
 await sample("glass")
 for part in [&"head",&"arm",&"leg"]:game.companion_parts.restore(part)
 story.glass.hits=3
 story.glass.hide()
 story.glass.body.collision_layer=0
 start=Time.get_ticks_usec()
 story.on_glass_impact(true)
 var garden_build_ms:=(Time.get_ticks_usec()-start)/1000.0
 await sample("garden-growing")
 for tree in story.birthday.trees:tree._physics_process(30)
 for flower in story.birthday.flowers:flower._physics_process(30)
 story.birthday.age=30
 await sample("garden-grown")
 for i in range(180):
  var flower:=GardenBloom.new()
  flower.kind=i%6
  flower.color=Color("f6b9d3")
  flower.position=Vector3((i%15-7)*1.1,.02,GardenReunion.CAKE_Z+((i/15)%12-6)*1.1)
  story.birthday.add_child(flower)
  flower.open_now()
  story.birthday.trail.append(flower)
 await sample("garden-max-trail")
 var output:Dictionary={"tag":tag,"startup_ms":startup_ms,"garden_build_ms":garden_build_ms,"renderer":RenderingServer.get_video_adapter_name(),"resolution":str(root.size),"vsync":false,"results":results}
 var file:=FileAccess.open("res://artifacts/performance/"+tag+".json",FileAccess.WRITE)
 file.store_string(JSON.stringify(output,"\t"))
 print("PROFILE_COMPLETE startup_ms=",startup_ms," garden_build_ms=",garden_build_ms)
 game.sound.silence()
 quit()
func get_tree_timer(seconds: float) -> void:
 await create_timer(seconds).timeout
