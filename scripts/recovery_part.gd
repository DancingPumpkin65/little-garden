class_name GardenRecoveryPart
extends Node3D

signal returned(kind: StringName)
enum State { HIDDEN, EMERGING, AVAILABLE, PICKING, CARRIED, RETURNING, RESTORED }
var state := State.HIDDEN
var kind: StringName
var clock := 0.0
var home := Vector3.ZERO
var start := Vector3.ZERO
var girl: GardenCharacter
var companion: GardenCompanionParts
var visual := MeshInstance3D.new()

func setup(part: StringName, mesh: Mesh, owner_parts: GardenCompanionParts, player: GardenCharacter) -> void:
	kind = part
	companion = owner_parts
	girl = player
	visual.mesh = mesh
	add_child(visual)
	hide()

func emerge(origin: Vector3, destination: Vector3) -> void:
	start = origin
	home = destination
	global_position = origin
	clock = 0
	state = State.EMERGING
	scale = Vector3.ONE * 0.05
	show()

func pick_up() -> void:
	state = State.CARRIED
	scale = Vector3.ONE
	girl.carrying = true

func put_back() -> void:
	start = global_position
	clock = 0
	state = State.RETURNING
	girl.carrying = false

func _physics_process(delta: float) -> void:
	clock += delta
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
	elif state == State.RETURNING:
		var progress := minf(1, clock / 0.8)
		global_position = start.lerp(companion.anchor(kind), smoothstep(0, 1, progress)) + Vector3.UP * sin(progress * PI) * 0.3
		global_rotation.y = lerp_angle(global_rotation.y, companion.actor.visual.global_rotation.y, delta * 10)
		if progress >= 1:
			companion.restore(kind)
			state = State.RESTORED
			hide()
			returned.emit(kind)
