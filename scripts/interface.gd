class_name GardenInterface
extends CanvasLayer

signal letter_spoken(letter: String)
signal begin
signal resumed
signal restarted
signal mute_changed(muted: bool)
var title_screen := Control.new()
var play_button: Button
var pause_screen := Control.new()
var objective: Label
var interaction_hint: Label
var dialogue: Label
var bubble := Panel.new()
var bubble_tail := Polygon2D.new()
var bubble_tail_shadow := Polygon2D.new()
var charge := ProgressBar.new()
var curtain := ColorRect.new()
var finish: Label
var typing_clock := 0.0
var spoken_letters := 0
const LETTER_INTERVAL := 0.070
const SENTENCE_END := [".", "!", "?", "\u061f"]
const CLAUSE_END := [",", ":", ";", "\u060c", "\u061b"]

func label(text: String, size: int, color := Color("faf5e9")) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.add_theme_color_override("font_shadow_color", Color(0.08, 0.08, 0.12, 0.65))
	node.add_theme_constant_override("shadow_offset_y", 2)
	return node

func button(text: String, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(240, 52)
	node.add_theme_font_size_override("font_size", 19)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("ededed")
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	node.add_theme_stylebox_override("normal", normal)
	for state in ["hover", "pressed", "hover_pressed", "disabled"]:
		var style := normal.duplicate() as StyleBoxFlat
		style.bg_color = Color("ffffff") if state=="hover" else Color("c9c9c9")
		node.add_theme_stylebox_override(state,style)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.set_border_width_all(3)
	focus.border_color = Color.WHITE
	focus.expand_margin_left = 5
	focus.expand_margin_right = 5
	focus.expand_margin_top = 5
	focus.expand_margin_bottom = 5
	focus.set_corner_radius_all(10)
	node.add_theme_stylebox_override("focus",focus)
	for state in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		node.add_theme_color_override(state, Color("323746"))
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(callback)
	return node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	objective = label("", 21)
	objective.position = Vector2(34, 30)
	root.add_child(objective)
	objective.hide()
	interaction_hint = label("",20,Color.WHITE)
	interaction_hint.add_theme_constant_override("outline_size",6)
	interaction_hint.add_theme_color_override("font_outline_color",Color("222222"))
	interaction_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	interaction_hint.position = Vector2(-300,-52)
	interaction_hint.size = Vector2(600,32)
	root.add_child(interaction_hint)
	dialogue = label("", 21, Color.BLACK)
	dialogue.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	dialogue.add_theme_constant_override("outline_size", 0)
	var speech_font := SystemFont.new()
	speech_font.font_names = PackedStringArray(["Arial"])
	speech_font.font_weight = 700
	var reaction_fonts: Array[Font] = []
	for family in ["Nirmala UI","Segoe UI Symbol","Euphemia"]:
		var fallback := SystemFont.new()
		fallback.font_names = PackedStringArray([family])
		reaction_fonts.append(fallback)
	speech_font.fallbacks = reaction_fonts
	dialogue.add_theme_font_override("font", speech_font)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	dialogue.custom_minimum_size = Vector2(300, 0)
	var bubble_style := StyleBoxFlat.new()
	bubble_style.bg_color = Color.WHITE
	bubble_style.set_corner_radius_all(28)
	bubble_style.set_border_width_all(2)
	bubble_style.border_color = Color("222222")
	bubble_style.content_margin_left = 22
	bubble_style.content_margin_right = 22
	bubble_style.content_margin_top = 15
	bubble_style.content_margin_bottom = 18
	bubble_style.shadow_color = Color.BLACK
	bubble_style.shadow_size = 1
	bubble_style.shadow_offset = Vector2(0, 8)
	bubble.add_theme_stylebox_override("panel", bubble_style)
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.add_child(dialogue)
	root.add_child(bubble)
	bubble_tail.polygon = PackedVector2Array([Vector2(-10, -2), Vector2(10, -2), Vector2(0, 14)])
	bubble_tail_shadow.polygon = bubble_tail.polygon
	bubble_tail_shadow.color = Color.BLACK
	bubble.add_child(bubble_tail_shadow)
	bubble_tail.color = Color.WHITE
	bubble.add_child(bubble_tail)
	bubble.hide()
	charge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	charge.position = Vector2(-90, -85)
	charge.size = Vector2(180, 6)
	charge.show_percentage = false
	charge.visible = false
	root.add_child(charge)
	finish = label("", 28)
	finish.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	finish.position = Vector2(-300, 82)
	finish.size = Vector2(600, 60)
	root.add_child(finish)
	finish.hide()
	root.add_child(title_screen)
	title_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := ColorRect.new()
	panel.color = Color.BLACK
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(panel)
	var preview := GardenTitleCharacter.new()
	preview.name = "Floating character"
	preview.anchor_left = 0.04
	preview.anchor_right = 0.56
	preview.anchor_top = 0.06
	preview.anchor_bottom = 0.94
	title_screen.add_child(preview)
	var right := CenterContainer.new()
	right.anchor_left = 0.57
	right.anchor_right = 0.94
	right.anchor_top = 0.12
	right.anchor_bottom = 0.88
	title_screen.add_child(right)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	right.add_child(column)
	var heading := label("A Little\nInterlude", 54, Color.WHITE)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 16
	column.add_child(spacer)
	play_button = button("Play", func(): begin.emit())
	play_button.custom_minimum_size = Vector2(260,64)
	play_button.add_theme_font_size_override("font_size",28)
	column.add_child(play_button)
	play_button.grab_focus()
	title_screen.visibility_changed.connect(func(): preview.set_process(title_screen.visible))
	root.add_child(pause_screen)
	pause_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.06, 0.08, 0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_screen.add_child(shade)
	var menu := VBoxContainer.new()
	menu.position = Vector2(520, 260)
	menu.add_theme_constant_override("separation", 18)
	pause_screen.add_child(menu)
	menu.add_child(label("Take your time.", 32))
	menu.add_child(button("Keep wandering", func(): resumed.emit()))
	menu.add_child(button("Start again", func(): restarted.emit()))
	var mute := CheckButton.new()
	mute.text = "Mute sound"
	mute.toggled.connect(func(value: bool): mute_changed.emit(value))
	menu.add_child(mute)
	pause_screen.hide()
	curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	curtain.color = Color(0, 0, 0, 0)
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(curtain)

func speech(text: String) -> void:
	dialogue.text = text.trim_prefix("Ari: ")
	dialogue.text_direction = Control.TEXT_DIRECTION_AUTO
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue.visible_characters = 0
	typing_clock = 0
	spoken_letters = 0
	bubble.visible = not text.is_empty()
	update_speech_size()

# Full-text wrapping stays fixed; the panel follows only revealed lines.
func update_speech_size() -> void:
	var font := dialogue.get_theme_font("font")
	var font_size := dialogue.get_theme_font_size("font_size")
	var width := minf(380,get_viewport().get_visible_rect().size.x-76)
	dialogue.custom_minimum_size = Vector2(width,0)
	dialogue.position = Vector2(22,15)
	dialogue.size = Vector2(width,font.get_multiline_string_size(dialogue.text,HORIZONTAL_ALIGNMENT_LEFT,width,font_size).y)
	var height := font.get_height(font_size)
	var count := dialogue.text.length() if dialogue.visible_characters<0 else dialogue.visible_characters
	for index in range(count-1,-1,-1):
		var bounds := dialogue.get_character_bounds(index)
		if bounds.has_area():
			height = maxf(height,ceilf(bounds.end.y))
			break
	bubble.custom_minimum_size = Vector2(width,height)+Vector2(44,33)
	bubble.size = bubble.custom_minimum_size
	bubble.reset_size()

# Projected every frame so speech stays attached while the camera or speaker moves.
func place_speech(camera: Camera3D, world_position: Vector3) -> void:
	if dialogue.text.is_empty():
		bubble.hide()
		return
	var point := camera.unproject_position(world_position)
	var viewport_size := get_viewport().get_visible_rect().size
	var on_screen := not camera.is_position_behind(world_position) and Rect2(Vector2(24,24),viewport_size-Vector2(48,48)).has_point(point)
	bubble.show()
	bubble_tail.visible = on_screen
	bubble_tail_shadow.visible = on_screen
	if not on_screen:
		bubble.position = Vector2((viewport_size.x-bubble.size.x)/2,maxf(16,viewport_size.y-bubble.size.y-104))
		return
	bubble.position = Vector2(clampf(point.x - bubble.size.x / 2, 16, viewport_size.x - bubble.size.x - 16), clampf(point.y - bubble.size.y - 22,16,maxf(16,viewport_size.y-bubble.size.y-24)))
	bubble_tail.position = Vector2(clampf(point.x - bubble.position.x, 24, bubble.size.x - 24), bubble.size.y)
	bubble_tail_shadow.position = bubble_tail.position+Vector2(0,8)

# Ease into punctuation, then leave a short reading pause after it.
func letter_delay(text: String, index: int) -> float:
	var delay := LETTER_INTERVAL
	for ahead in range(4):
		if index+ahead < text.length():
			var next := text[index+ahead]
			if next in SENTENCE_END or next in CLAUSE_END:
				delay *= [2.4, 1.9, 1.5, 1.2][ahead]
				break
	if index>0:
		var previous := text[index-1]
		if previous in SENTENCE_END:
			delay += 0.10 if index<text.length() and text[index] in SENTENCE_END else 0.38
		elif previous in CLAUSE_END:
			delay += 0.22
	return delay

func typing_duration(text: String) -> float:
	var seconds := 0.0
	for index in range(text.length()): seconds += letter_delay(text,index)
	return seconds

func _process(delta: float) -> void:
	if not dialogue.text.is_empty(): update_speech_size()
	if get_tree().paused or dialogue.visible_characters < 0 or dialogue.visible_characters >= dialogue.text.length(): return
	typing_clock += delta
	while dialogue.visible_characters < dialogue.text.length() and typing_clock >= letter_delay(dialogue.text,dialogue.visible_characters):
		typing_clock -= letter_delay(dialogue.text,dialogue.visible_characters)
		var letter := dialogue.text.substr(dialogue.visible_characters, 1)
		dialogue.visible_characters += 1
		if not letter.strip_edges().is_empty() and not letter in SENTENCE_END and not letter in CLAUSE_END:
			spoken_letters += 1
			if spoken_letters % 2 == 1: letter_spoken.emit(letter)

	update_speech_size()
