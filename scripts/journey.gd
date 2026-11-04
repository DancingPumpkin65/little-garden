class_name GardenJourney
extends Node3D

signal dialogue_requested(lines: Array[String])
signal transition_lock(locked: bool)
enum Chapter { FIRST, GAP, DESCENT, DARK }
enum Beat { INTRO, RUN, JUMP, FALLEN }
const ENTRY_Z := GardenWorld.EXIT_Z - GardenWorld.PASSAGE_LENGTH
const EDGE_Z := ENTRY_Z - 48.0
const FAR_Z := EDGE_Z - 40.0
const LEG_REVEAL_LINE := "Hahiya rajli fjiha lakhra"
var prepared := false
var dialogue_started := false
var chapter := Chapter.FIRST
var beat := Beat.INTRO
var player: GardenCharacter
var companion: GardenCharacter
var parts: GardenCompanionParts
var original_world: GardenWorld
var camera: Camera3D
var curtain: ColorRect
var scene_root := Node3D.new()
var near_platform: MeshInstance3D
var arrival_gate: Node3D
var arrival_hinge: Node3D
var arrival_body: StaticBody3D
var arrival_open := false
var entry_sealed := false
var retire_clock := 0.0
var far_platform: MeshInstance3D
var leg: MeshInstance3D
const FAR_FADE_DURATION := 1.4
var far_dark := false
var far_fade_started := false
var far_fade_clock := 0.0
var far_material: ShaderMaterial
var crossing := false
var clock := 0.0
var dark_material: ShaderMaterial
var quest_material: ShaderMaterial
var reunion: GardenReunion

func setup(girl: GardenCharacter, guy: GardenCharacter, body_parts: GardenCompanionParts, first_map: GardenWorld, view: Camera3D, overlay: ColorRect) -> void:
	player = girl
	companion = guy
	parts = body_parts
	original_world = first_map
	camera = view
	curtain = overlay
	add_child(scene_root)
	reunion = GardenReunion.new()
	add_child(reunion)
	reunion.setup(player,companion,parts,scene_root)
	reunion.dialogue_requested.connect(func(lines: Array[String]): dialogue_requested.emit(lines))

func platform(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	Shapes.collider(scene_root, at, size)
	return Shapes.box(scene_root, at, size, material)

func fade_to_black() -> void:
	transition_lock.emit(true)
	player.set_physics_process(false)
	companion.set_physics_process(false)
	var tween := create_tween()
	tween.tween_property(curtain, "color:a", 1.0, 0.55)
	await tween.finished
	await get_tree().create_timer(0.2, false).timeout

func fade_in() -> void:
	player.set_physics_process(true)
	var tween := create_tween()
	tween.tween_property(curtain, "color:a", 0.0, 0.65)
	await tween.finished
	transition_lock.emit(false)

# Build the next area in world space before the player walks down the passage.
func prepare_gap() -> void:
	if prepared: return
	prepared = true
	quest_material = ShaderMaterial.new()
	quest_material.shader = Shader.new()
	quest_material.shader.code = "shader_type spatial; uniform vec3 walker=vec3(0.0); uniform float fade=1.0; varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float light=1.0-0.8*smoothstep(12.0,85.0,length(world.xz-walker.xz));ALBEDO=vec3(light * fade);ROUGHNESS=1.0;SPECULAR=0.0;}"
	near_platform = platform(Vector3(0, -0.48, ENTRY_Z - 24), Vector3(70, 1, 48), quest_material)
	far_material = quest_material.duplicate() as ShaderMaterial
	far_platform = platform(Vector3(0, -0.48, FAR_Z), Vector3(70, 1, 40), far_material)
	leg = MeshInstance3D.new()
	leg.mesh = parts.loose_mesh(&"leg")
	leg.material_override = far_material
	scene_root.add_child(leg)
	leg.position = Vector3(-1.4, 0.66, FAR_Z + 5)
	build_arrival_gate()
	near_platform.hide()
	far_platform.hide()
	leg.hide()

func build_arrival_gate() -> void:
	arrival_gate = Node3D.new()
	scene_root.add_child(arrival_gate)
	arrival_gate.position.z = ENTRY_Z
	var white := Shapes.material(Color.WHITE)
	for x in [-(GardenWorld.DOOR_WIDTH / 2 + 0.15), GardenWorld.DOOR_WIDTH / 2 + 0.15]: Shapes.box(arrival_gate, Vector3(x, 2.1, 0), Vector3(0.25, 4.2, 0.3), white)
	Shapes.box(arrival_gate, Vector3(0, 4.2, 0), Vector3(GardenWorld.DOOR_WIDTH + 0.55, 0.25, 0.3), white)
	arrival_hinge = Node3D.new()
	arrival_gate.add_child(arrival_hinge)
	arrival_hinge.position = Vector3(-GardenWorld.DOOR_WIDTH / 2, 0.02, 0)
	Shapes.box(arrival_hinge, Vector3(GardenWorld.DOOR_WIDTH / 2, 2.0, 0), Vector3(GardenWorld.DOOR_WIDTH, 4, 0.18), white)
	arrival_body = Shapes.collider(arrival_hinge, Vector3(GardenWorld.DOOR_WIDTH / 2, 2, 0), Vector3(GardenWorld.DOOR_WIDTH, 4, 0.18))
	arrival_gate.hide()

# The old world remains walkable until both characters pass the second door.
func update_passage(delta: float) -> void:
	original_world.passage_material.set_shader_parameter("walker", player.global_position)
	quest_material.set_shader_parameter("walker", player.global_position)
	far_material.set_shader_parameter("walker", player.global_position)
	if not entry_sealed:
		var approaching := player.position.z < ENTRY_Z + 26
		arrival_gate.visible = approaching
		if player.position.z < ENTRY_Z + 12:
			near_platform.show()
			far_platform.show()
			leg.show()
			arrival_open = true
			arrival_body.collision_layer = 0
		if chapter == Chapter.GAP and player.position.z < ENTRY_Z - 2 and companion.position.z < ENTRY_Z - 2:
			entry_sealed = true
			arrival_open = false
			arrival_body.collision_layer = 1
	else:
		retire_clock += delta
		if retire_clock > 1.2 and original_world.visible: original_world.retire()
	arrival_hinge.rotation.y = lerp_angle(arrival_hinge.rotation.y, -PI * 0.52 if arrival_open else 0.0, 1 - exp(-delta * 3))

func enter_gap() -> void:
	if chapter != Chapter.FIRST: return
	prepare_gap()
	chapter = Chapter.GAP
	beat = Beat.INTRO
	clock = 0

func start_gap_dialogue() -> void:
	dialogue_started = true
	companion.celebration = 0
	var lines: Array[String] = [LEG_REVEAL_LINE, "Ymkn khassna namchiw na9zo ltmak."]
	dialogue_requested.emit(lines)

func dialogue_finished() -> void:
	if chapter == Chapter.DARK: reunion.dialogue_finished()
	if chapter == Chapter.GAP and beat == Beat.INTRO and dialogue_started:
		companion.follow_target = null
		companion.set_physics_process(false)
		beat = Beat.RUN
		clock = 0

func enter_dark() -> void:
	if crossing or chapter != Chapter.GAP: return
	crossing = true
	chapter = Chapter.DESCENT
	await fade_to_black()
	original_world.retire()
	for child in scene_root.get_children():
		scene_root.remove_child(child)
		child.queue_free()
	dark_material = ShaderMaterial.new()
	dark_material.shader = Shader.new()
	dark_material.shader.code = "shader_type spatial; uniform vec3 light_center=vec3(0.0); varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float distance_to_light=length(world.xz-light_center.xz); ALBEDO=vec3(1.0-smoothstep(13.0,42.0,distance_to_light));ROUGHNESS=1.0;SPECULAR=0.0;}"
	platform(Vector3(0, -0.48, 4), Vector3(120, 1, 112), dark_material)
	player.position = Vector3(0, 12, 3)
	player.velocity = Vector3(0, -2, 0)
	companion.position = Vector3(2.3, 0.03, -0.6)
	companion.velocity = Vector3.ZERO
	companion.celebration = 0
	companion.hop = GardenCharacter.Hop.REST
	companion.hop_clock = 0
	companion.follow_target = player
	companion.follow_offset = Vector3(2, 0, -3)
	companion.show()
	companion.set_physics_process(true)
	leg = MeshInstance3D.new()
	leg.mesh = parts.loose_mesh(&"leg")
	scene_root.add_child(leg)
	chapter = Chapter.DARK
	reunion.activate(leg)
	clock = 0
	camera.position = player.position + Vector3(0, 8.5, 12.5)
	camera.look_at(player.position + Vector3(0, 0.7, -2))
	await fade_in()
	crossing = false

func _physics_process(delta: float) -> void:
	clock += delta
	if prepared and chapter in [Chapter.FIRST, Chapter.GAP]: update_passage(delta)
	if prepared and chapter in [Chapter.FIRST, Chapter.GAP] and not far_dark:
		leg.position = Vector3(-1.4 + sin(clock * 1.5) * 0.65, 0.66 + absf(sin(clock * 4)) * 0.55, FAR_Z + 5 + cos(clock) * 0.4)
		leg.rotation.z = sin(clock * 4) * 0.15
	if chapter == Chapter.GAP:
		if not dialogue_started and player.position.z < EDGE_Z + 12:
			start_gap_dialogue()
		if beat == Beat.RUN:
			companion.velocity = Vector3(0, -0.5, -3.8)
			companion.move_and_slide()
			companion.visual.rotation.y = PI
			companion.gait += delta * 8
			companion.animate_pose(delta, 1.0, true)
			if companion.position.z < EDGE_Z + 1:
				beat = Beat.JUMP
				companion.velocity = Vector3(0, 5.4, -5)
		elif beat == Beat.JUMP:
			companion.velocity.y -= delta * 18
			companion.move_and_slide()
			companion.animate_pose(delta, 0.0, false)
			if companion.position.y < -6:
				companion.hide()
				beat = Beat.FALLEN
				far_fade_started = true
		if far_fade_started and not far_dark:
			far_fade_clock = minf(far_fade_clock + delta, FAR_FADE_DURATION)
			far_material.set_shader_parameter("fade", 1.0 - smoothstep(0.0, FAR_FADE_DURATION, far_fade_clock))
			if far_fade_clock >= FAR_FADE_DURATION:
				far_dark = true
				leg.hide()
		if player.position.y < -6 and not crossing: enter_dark()
	elif chapter == Chapter.DARK:
		dark_material.set_shader_parameter("light_center", player.global_position)
