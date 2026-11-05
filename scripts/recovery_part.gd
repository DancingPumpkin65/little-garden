class_name GardenRecoveryPart
extends Node3D

signal returned(kind: StringName)
signal missed
enum State { HIDDEN, EMERGING, AVAILABLE, PICKING, CARRIED, THROWN, RETURNING, RESTORED }
var state := State.HIDDEN
var kind: StringName
var clock := 0.0
var home := Vector3.ZERO
var start := Vector3.ZERO
var girl: GardenCharacter
var companion: GardenCompanionParts
var velocity := Vector3.ZERO
var hit_target: GardenGlass
var hit_this_throw := false
var ground_center := Vector3.ZERO
var ground_radius := GardenWorld.MAP_RADIUS
var ground_bounds := Rect2()
var return_home := Vector3.ZERO
var visual := MeshInstance3D.new()
var highlight := Node3D.new()

func setup(part: StringName, mesh: Mesh, owner_parts: GardenCompanionParts, player: GardenCharacter) -> void:
	kind = part
	companion = owner_parts
	girl = player
	visual.mesh = mesh
	add_child(visual)
	add_child(highlight)
	if kind==&"arm":
		var outline := MeshInstance3D.new()
		outline.mesh = mesh
		var ink := ShaderMaterial.new()
		ink.shader = Shader.new()
		ink.shader.code = "shader_type spatial; render_mode unshaded,cull_front; void vertex(){VERTEX+=NORMAL*0.025;} void fragment(){ALBEDO=vec3(0.12,0.10,0.06);}"
		outline.material_override = ink
		visual.add_child(outline)
		var gold := Shapes.material(Color("e7b54a"))
		gold.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var ring := TorusMesh.new()
		ring.inner_radius = .44
		ring.outer_radius = .49
		Shapes.mesh(highlight,ring,Vector3(0,.6,0),gold)
	hide()

func emerge(origin: Vector3, destination: Vector3) -> void:
	start = origin
	home = destination
	return_home = destination
	global_position = origin
	clock = 0
	state = State.EMERGING
	scale = Vector3.ONE * 0.05
	show()

func pick_up() -> void:
	state = State.CARRIED
	scale = Vector3.ONE
	girl.carrying = true

func throw_part(impulse: Vector3) -> void:
	state = State.THROWN
	hit_this_throw = false
	velocity = impulse
	clock = 0
	girl.carrying = false

func put_back() -> void:
	start = global_position
	clock = 0
	state = State.RETURNING
	girl.carrying = false

func _physics_process(delta: float) -> void:
	clock += delta
	highlight.visible = kind==&"arm" and state in [State.EMERGING,State.AVAILABLE]
	if highlight.visible: highlight.rotation.y += delta
	if state == State.EMERGING:
		var progress := minf(1, clock / 1.25)
		global_position = start.lerp(home, smoothstep(0, 1, progress)) + Vector3.UP * sin(progress * PI) * 0.65
		scale = Vector3.ONE * lerpf(0.05, 1, smoothstep(0, 0.65, progress))
		if progress >= 1: state = State.AVAILABLE
	elif state == State.AVAILABLE:
		global_position = home + Vector3.UP * sin(clock * 2.3) * 0.06
		visual.rotation.y = sin(clock) * 0.15
	elif state == State.CARRIED:
		global_position = girl.fruit_position()
		global_rotation.y = girl.visual.global_rotation.y
	elif state == State.THROWN:
		velocity.y -= delta * 9.8
		var previous := global_position
		global_position += velocity * delta
		if hit_target != null and not hit_this_throw and hit_target.hit_head(previous,global_position):
			hit_this_throw = true
			var away := global_position-hit_target.global_position
			away.y = 0
			velocity = away.normalized()*2.5+Vector3.UP*2.5
		visual.rotation.x += delta * 5
		if global_position.y < -5:
			home = return_home
			state = State.AVAILABLE
			if not hit_this_throw: missed.emit()
		elif global_position.y < 0.55 and over_ground():
			home = Vector3(global_position.x, 0.55, global_position.z)
			visual.rotation.x = 0
			state = State.AVAILABLE
			if not hit_this_throw: missed.emit()
	elif state == State.RETURNING:
		var progress := minf(1, clock / 0.8)
		global_position = start.lerp(companion.anchor(kind), smoothstep(0, 1, progress)) + Vector3.UP * sin(progress * PI) * 0.3
		global_rotation.y = lerp_angle(global_rotation.y, companion.actor.visual.global_rotation.y, delta * 10)
		if progress >= 1:
			companion.restore(kind)
			state = State.RESTORED
			hide()
			returned.emit(kind)

func over_ground() -> bool:
	var point := Vector2(global_position.x,global_position.z)
	if ground_bounds.has_area(): return ground_bounds.has_point(point)
	return point.distance_to(Vector2(ground_center.x,ground_center.z)) < ground_radius-0.3
