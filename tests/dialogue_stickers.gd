extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var hud := GardenInterface.new()
 root.add_child(hud)
 hud.title_screen.hide()
 hud.set_process(false)
 var background := ColorRect.new()
 background.color=Color("617b78")
 background.size=Vector2(2000,1200)
 hud.get_child(0).add_child(background)
 hud.get_child(0).move_child(background,0)
 DirAccess.make_dir_recursive_absolute("res://artifacts/sticker-review")
 for line: String in GardenDialogueSticker.ASSIGNMENTS:
  hud.speech(line)
  assert(hud.sticker.clip!=null,"every assigned sticker exists")
  assert(not hud.sticker.visible,"sticker waits for the words")
  hud.dialogue.visible_characters=-1
  hud.update_speech_size()
  assert(hud.sticker.visible,"completed line reveals its sticker")
  assert(hud.bubble.get_rect().size.x>=hud.sticker.position.x+hud.sticker.size.x,"sticker fits horizontally")
  assert(hud.bubble.size.y>=hud.sticker.position.y+hud.sticker.size.y,"bubble contains the sticker")
 hud.speech("Had lpassage twil... b7al tri9 dyalk lkhadma!")
 hud.dialogue.visible_characters=-1
 hud.update_speech_size()
 hud.bubble.position=Vector2(180,260)
 hud.bubble_tail.hide()
 hud.bubble_tail_shadow.hide()
 var first := hud.sticker.frame
 hud.sticker.advance(.2)
 assert(hud.sticker.frame!=first,"animated WebP retains multiple timed frames")
 paused=true
 var stopped:=hud.sticker.frame
 hud.sticker.advance(.2)
 assert(hud.sticker.frame==stopped,"animation pauses with the game")
 paused=false
 for i in range(48):
  hud.sticker.advance(1.0/30)
  if DisplayServer.get_name()!="headless":
   await RenderingServer.frame_post_draw
   if i%2==0: root.get_texture().get_image().save_png("res://artifacts/sticker-review/walking-%02d.png"%i)
 hud.speech("Salaaaaam Salma, finally kanchufek!")
 assert(hud.sticker.frame==0 and not hud.sticker.visible,"new message resets and hides its sticker")
 hud.dialogue.visible_characters=-1
 hud.update_speech_size()
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://artifacts/sticker-review/head.png")
 hud.speech("Salam Salma, labas? :)")
 assert(hud.sticker.texture==null,"plain reactions have no stale sticker")
 print("DIALOGUE_STICKERS_PASS all 27 assignments, bubble bounds, animation timing, pause and message reset")
 quit()
