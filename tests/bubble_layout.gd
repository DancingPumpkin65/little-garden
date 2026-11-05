extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var hud := GardenInterface.new()
	root.add_child(hud)
	hud.speech("Salam")
	await process_frame
	var short_size := hud.bubble.size
	hud.speech("Kima kabrat had jerda, tantiya kberti o ba9i ghatkabri... Knatmana lik kul khir, odkhel 3lik sna jdida bachma tmaniti inchallah!")
	await process_frame
	var long_size := hud.bubble.size
	print("BUBBLE_DIMENSIONS short=",short_size," long=",long_size," label=",hud.dialogue.size)
	assert(long_size.y > short_size.y+20,"long message expands panel and its shadow")
	assert(hud.dialogue.get_minimum_size().y <= hud.bubble.size.y-25,"text stays inside panel padding")
	hud.dialogue.visible_characters = 5
	await process_frame
	assert(hud.bubble.size == long_size,"typing must not change the measured full-message layout")
	hud.speech("OK")
	await process_frame
	assert(hud.bubble.size.y < long_size.y,"short follow-up shrinks panel and shadow together")
	print("BUBBLE_LAYOUT_PASS stable typing and matching message/shadow bounds")
	quit()
