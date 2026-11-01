class_name GardenInterface
extends CanvasLayer

signal begin
signal resumed
signal restarted
signal mute_changed(muted: bool)
var title_screen := Control.new()
var pause_screen := Control.new()
var objective: Label
var prompt: Label
var dialogue: Label
var charge := ProgressBar.new()
var finish: Label

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
	objective = label("Bring the little seed to the stone bowl.", 21)
	objective.position = Vector2(34, 30)
	root.add_child(objective)
	var controls := label("WASD / arrows  move     Shift  run     Space  jump     E  pick up     Hold click  aim & throw     R  recover seed     Esc  pause", 14)
	controls.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	controls.position = Vector2(34, -40)
	root.add_child(controls)
	prompt = label("", 20)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	prompt.position = Vector2(-300, -120)
	prompt.size = Vector2(600, 40)
	root.add_child(prompt)
	dialogue = label("", 22)
	dialogue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	dialogue.position = Vector2(-420, -200)
	dialogue.size = Vector2(840, 60)
	root.add_child(dialogue)
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
	dialogue.text = text
