class_name GardenInterface
extends CanvasLayer

signal letter_spoken(letter: String)
signal begin
signal resumed
signal restarted
signal mute_changed(muted: bool)
var title_screen := Control.new()
var pause_screen := Control.new()
var objective: Label
var dialogue: Label
var bubble := PanelContainer.new()
var bubble_tail := Polygon2D.new()
var charge := ProgressBar.new()
var finish: Label
var typing_clock := 0.0
var spoken_letters := 0
const LETTER_INTERVAL := 0.034

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
	normal.bg_color = Color("f0e7d7")
	normal.corner_radius_top_left = 8
	normal.corner_radius_top_right = 8
	normal.corner_radius_bottom_left = 8
	normal.corner_radius_bottom_right = 8
	node.add_theme_stylebox_override("normal", normal)
	for state in ["font_color", "font_focus_color", "font_hover_color", "font_pressed_color"]:
		node.add_theme_color_override(state, Color("323746"))
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
	dialogue = label("", 21, Color.BLACK)
	dialogue.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	dialogue.add_theme_constant_override("outline_size", 0)
	var speech_font := SystemFont.new()
	speech_font.font_names = PackedStringArray(["Arial"])
	speech_font.font_weight = 700
	dialogue.add_theme_font_override("font", speech_font)
	dialogue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue.custom_minimum_size = Vector2(300, 0)
	var bubble_style := StyleBoxFlat.new()
	bubble_style.bg_color = Color.WHITE
	bubble_style.set_corner_radius_all(28)
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
	panel.color = Color(0.055, 0.065, 0.085, 0.55)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	title_screen.add_child(panel)
	var column := VBoxContainer.new()
	column.position = Vector2(90, 235)
	column.add_theme_constant_override("separation", 18)
	title_screen.add_child(column)
	column.add_child(label("A little garden", 60))
	column.add_child(label("Some things only need a little care.", 23))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 16
	column.add_child(spacer)
	var start := button("Let's take a walk", func(): begin.emit())
	column.add_child(start)
	start.grab_focus()
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

func speech(text: String) -> void:
	dialogue.text = text.trim_prefix("Ari: ")
	dialogue.text_direction = Control.TEXT_DIRECTION_AUTO
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	dialogue.visible_characters = 0
	typing_clock = 0
	spoken_letters = 0
	bubble.visible = not text.is_empty()
	bubble.reset_size()

# Projected every frame so speech stays attached while the camera or speaker moves.
func place_speech(camera: Camera3D, world_position: Vector3) -> void:
	if dialogue.text.is_empty(): return
	bubble.visible = not camera.is_position_behind(world_position)
	var point := camera.unproject_position(world_position)
	var viewport_size := get_viewport().get_visible_rect().size
	bubble.visible = bubble.visible and Rect2(Vector2.ZERO, viewport_size).has_point(point)
	bubble.position = Vector2(clampf(point.x - bubble.size.x / 2, 16, viewport_size.x - bubble.size.x - 16), maxf(16, point.y - bubble.size.y - 22))
	bubble_tail.position = Vector2(clampf(point.x - bubble.position.x, 24, bubble.size.x - 24), bubble.size.y)

func _process(delta: float) -> void:
	if get_tree().paused or dialogue.visible_characters >= dialogue.text.length(): return
	typing_clock += delta
	while typing_clock >= LETTER_INTERVAL and dialogue.visible_characters < dialogue.text.length():
		typing_clock -= LETTER_INTERVAL
		var letter := dialogue.text.substr(dialogue.visible_characters, 1)
		dialogue.visible_characters += 1
		if letter in [".", "!", "?", "؟"]:
			typing_clock -= 0.17
		elif letter in [",", ":", ";", "،", "؛"]:
			typing_clock -= 0.07
		elif not letter.strip_edges().is_empty():
			spoken_letters += 1
			if spoken_letters % 2 == 1: letter_spoken.emit(letter)
