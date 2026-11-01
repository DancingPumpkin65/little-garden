class_name GardenCharacter
extends CharacterBody3D

var visual := Node3D.new()
var left_arm := Node3D.new()
var right_arm := Node3D.new()
var left_leg := Node3D.new()
var right_leg := Node3D.new()
var head := Node3D.new()
var gait := 0.0
var carrying := false
var drive := Vector3.ZERO
var jump_requested := false
var sprint := false
var npc := false

func _ready() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)
	add_child(visual)
	var skin := Shapes.material(Color("f3cfaf"))
	var ink := Shapes.material(Color("29293a"))
	var coat := Shapes.material(Color("efad7c") if npc else Color("b6b3e6"))
	var trouser := Shapes.material(Color("506273") if npc else Color("42445c"))
	var boots := Shapes.material(Color("a67454"))
	Shapes.sphere(visual, Vector3(0, 1.02, 0), Vector3(0.74, 0.85, 0.49), coat)
	visual.add_child(head)
	head.position.y = 1.67
	Shapes.sphere(head, Vector3.ZERO, Vector3(0.91, 0.94, 0.83), skin)
	Shapes.sphere(head, Vector3(0, 0.14, -0.09), Vector3(1.0, 0.86, 0.85), ink)
	# The face looks along +Z. The hair cap leaves the lower face visible.
	Shapes.sphere(head, Vector3(0, -0.09, 0.17), Vector3(0.77, 0.63, 0.62), skin)
	for side in [-1.0, 1.0]:
		Shapes.sphere(head, Vector3(side * 0.17, -0.03, 0.448), Vector3(0.075, 0.105, 0.04), ink)
		Shapes.sphere(head, Vector3(side * 0.24, -0.13, 0.434), Vector3(0.12, 0.055, 0.025), Shapes.material(Color("eab3a3")))
	Shapes.sphere(head, Vector3(0, -0.15, 0.47), Vector3(0.085, 0.07, 0.08), skin)
	Shapes.sphere(head, Vector3(0, -0.23, 0.439), Vector3(0.09, 0.025, 0.02), ink)
	if not npc:
		Shapes.sphere(head, Vector3(0, -0.03, -0.29), Vector3(0.94, 1.03, 0.42), ink)
	else:
		Shapes.sphere(head, Vector3(0, -0.2, 0.46), Vector3(0.23, 0.045, 0.035), ink)
	for pair in [[left_arm, -1.0], [right_arm, 1.0]]:
		var arm: Node3D = pair[0]
		var side: float = pair[1]
		visual.add_child(arm)
		arm.position = Vector3(side * 0.4, 1.23, 0)
		Shapes.sphere(arm, Vector3(0, -0.18, 0), Vector3(0.29, 0.52, 0.3), coat)
		Shapes.sphere(arm, Vector3(0, -0.43, 0.02), Vector3(0.24, 0.25, 0.24), skin)
	for pair in [[left_leg, -1.0], [right_leg, 1.0]]:
		var leg: Node3D = pair[0]
		var side: float = pair[1]
		visual.add_child(leg)
		leg.position = Vector3(side * 0.19, 0.72, 0)
		Shapes.sphere(leg, Vector3(0, -0.23, 0), Vector3(0.29, 0.62, 0.29), trouser)
		Shapes.sphere(leg, Vector3(0, -0.58, 0.07), Vector3(0.31, 0.23, 0.44), boots)

func _physics_process(delta: float) -> void:
	if npc:
		gait += delta
		head.rotation.z = sin(gait * 1.4) * 0.025
		visual.position.y = sin(gait * 2) * 0.015
		return
	var speed := 5.4 if sprint else 3.5
	velocity.x = move_toward(velocity.x, drive.x * speed, delta * 18)
	velocity.z = move_toward(velocity.z, drive.z * speed, delta * 18)
	if not is_on_floor(): velocity.y -= 18 * delta
	if jump_requested and is_on_floor(): velocity.y = 6.4
	jump_requested = false
	move_and_slide()
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	if planar_speed > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(velocity.x, velocity.z), delta * 12)
	gait += delta * (planar_speed * 3.7 + 1)
	var stride := clampf(planar_speed / 4.0, 0, 1)
	left_leg.rotation.x = sin(gait) * 0.6 * stride
	right_leg.rotation.x = -sin(gait) * 0.6 * stride
	left_arm.rotation.x = lerpf(left_arm.rotation.x, -0.95 if carrying else -sin(gait) * 0.5 * stride, delta * 14)
	right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.95 if carrying else sin(gait) * 0.5 * stride, delta * 14)
	left_arm.rotation.z = -0.13 if carrying else 0.08
	right_arm.rotation.z = 0.13 if carrying else -0.08
	visual.position.y = absf(sin(gait)) * 0.06 * stride + sin(Time.get_ticks_msec() * 0.002) * 0.012
	head.rotation.z = sin(gait * 0.5) * 0.015

func facing() -> Vector3:
	return Vector3(sin(visual.rotation.y), 0, cos(visual.rotation.y))
