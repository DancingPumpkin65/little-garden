extends SceneTree
var frame := 0
var started := 0
var scene: Node3D
var draw_calls := 0.0
func _initialize() -> void:
	setup.call_deferred()
func setup() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	scene = load("res://main.tscn").instantiate()
	root.add_child(scene)
	scene.start()
	scene.player.set_physics_process(false)
	process_frame.connect(measure)
func measure() -> void:
	frame += 1
	if frame == 60: started = Time.get_ticks_usec()
	scene.player.gait = frame * 0.12
	scene.player.carrying = frame > 180
	scene.player.animate_pose(1.0 / 60.0, 1.0)
	if frame > 60: draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	if frame == 300:
		var milliseconds := (Time.get_ticks_usec() - started) / 1000.0 / 240
		var report := {"renderer": RenderingServer.get_video_adapter_name(), "scene": "full garden, two imported characters, player walking/carrying", "frames": 240, "average_frame_ms": milliseconds, "average_fps": 1000.0 / milliseconds, "average_scene_draw_calls": draw_calls / 240.0}
		var output := FileAccess.open("res://artifacts/character-performance.json", FileAccess.WRITE)
		output.store_string(JSON.stringify(report, "  "))
		print("CHARACTER_RENDER_BENCHMARK ", report)
		scene.sound.silence()
		quit()
