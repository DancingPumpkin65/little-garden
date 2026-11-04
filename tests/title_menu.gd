extends SceneTree

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 var hud: GardenInterface = game.hud
 var preview := hud.title_screen.get_node("Floating character") as GardenTitleCharacter
 for i in range(12): await process_frame
 assert(game.stage==game.Stage.TITLE and preview.actor.imported_skeleton!=null)
 var before := preview.actor.visual.position.y
 for i in range(15): await process_frame
 assert(not is_equal_approx(before,preview.actor.visual.position.y),"title character floats")
 for state in ["normal","hover","pressed","hover_pressed"]:
  var style := hud.play_button.get_theme_stylebox(state) as StyleBoxFlat
  assert(style.bg_color.get_luminance()>.5,"all button surfaces stay light")
 for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color","font_hover_pressed_color"]:
  assert(hud.play_button.get_theme_color(state).srgb_to_linear().get_luminance()<.1,"button text stays dark")
 if DisplayServer.get_name()!="headless":
  DirAccess.make_dir_recursive_absolute("res://artifacts/title-review")
  for dimensions in [Vector2i(1280,800),Vector2i(960,600),Vector2i(1600,900)]:
   root.size = dimensions
   for i in range(4): await process_frame
   await RenderingServer.frame_post_draw
   root.get_texture().get_image().save_png("res://artifacts/title-review/menu-%dx%d.png"%[dimensions.x,dimensions.y])
  var motion := InputEventMouseMotion.new()
  motion.position = hud.play_button.get_global_rect().get_center()
  root.push_input(motion,true)
  for i in range(4): await process_frame
  assert(hud.play_button.is_hovered(),"pointer reaches the visible Play button")
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/title-review/menu-hover.png")
 assert(hud.play_button.has_focus(),"Play is reachable immediately by keyboard")
 hud.play_button.pressed.emit()
 for i in range(3): await process_frame
 assert(game.stage==game.Stage.SEED and not hud.title_screen.visible,"Play enters gameplay")
 assert(not preview.is_processing(),"hidden title stops animating")
 assert(preview.get_child(0).render_target_update_mode==SubViewport.UPDATE_DISABLED,"hidden title stops rendering")
 print("TITLE_MENU_PASS floating preview, button contrast, hover, keyboard focus and Play")
 game.sound.silence()
 quit()
