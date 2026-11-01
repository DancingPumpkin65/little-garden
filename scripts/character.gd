class_name GardenCharacter
extends CharacterBody3D

var visual := Node3D.new()
var left_arm := Node3D.new()
var right_arm := Node3D.new()
var left_leg := Node3D.new()
var right_leg := Node3D.new()
var head := Node3D.new()
var knees: Array[Node3D] = []
var elbows: Array[Node3D] = []
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
	capsule.height = 2.7
	collision.shape = capsule
	collision.position.y = 1.35
	add_child(collision)
	add_child(visual)
	var skin := Shapes.material(Color("eeece5") if npc else Color("efa95f"))
	var ink := Shapes.material(Color("29293a"))
	var coat := Shapes.material(Color("efad7c") if npc else Color("f2dfb8"))
	var trouser := Shapes.material(Color("506273") if npc else Color("655080"))
	var boots := Shapes.material(Color("815438"))
	# The torso has a shoulder line, waist and hem; the hip is a separate volume.
	Shapes.profile(visual, [Vector3(1.18, 0.01, 0.01), Vector3(1.22, 0.32, 0.19), Vector3(1.42, 0.28, 0.175), Vector3(1.66, 0.27, 0.18), Vector3(1.88, 0.35, 0.19), Vector3(1.98, 0.29, 0.16), Vector3(2.02, 0.13, 0.12)], coat)
	Shapes.profile(visual, [Vector3(1.12, 0.22, 0.15), Vector3(1.25, 0.29, 0.18), Vector3(1.35, 0.25, 0.16)], trouser)
	Shapes.cylinder(visual, Vector3(0, 2.06, 0), 0.105, 0.18, skin)
	visual.add_child(head)
	head.position.y = 2.39
	head.scale = Vector3.ONE * 0.7
	# Fixed head geometry keeps the same proportions through every animation.
	if npc:
		Shapes.sphere(head, Vector3.ZERO, Vector3(0.91, 0.94, 0.83), skin)
		Shapes.sphere(head, Vector3(0, 0.15, -0.1), Vector3(1.0, 0.84, 0.84), ink)
		Shapes.sphere(head, Vector3(0, -0.09, 0.17), Vector3(0.77, 0.63, 0.62), skin)
		var fringe := Shapes.sphere(head, Vector3(-0.07, 0.24, 0.29), Vector3(0.77, 0.34, 0.27), ink)
		fringe.rotation.z = 0.2
		Shapes.sphere(head, Vector3(0.36, 0.02, 0.19), Vector3(0.16, 0.41, 0.23), ink)
	else:
		build_hijab()
		Shapes.sphere(head, Vector3(0, -0.065, 0.17), Vector3(0.77, 0.76, 0.64), skin)
	for side in [-1.0, 1.0]:
		Shapes.sphere(head, Vector3(side * 0.18, -0.02, 0.477), Vector3(0.08, 0.11, 0.035), ink)
		Shapes.sphere(head, Vector3(side * 0.25, -0.15, 0.44), Vector3(0.1, 0.045, 0.025), Shapes.material(Color("e59c7d")))
	Shapes.sphere(head, Vector3(0, -0.13, 0.49), Vector3(0.09, 0.075, 0.08), skin)
	Shapes.sphere(head, Vector3(0, -0.24, 0.455), Vector3(0.09, 0.025, 0.025), Shapes.material(Color("a75f4f")))
	if not npc: build_glasses(ink)
	if npc:
		for side in [-1.0, 1.0]:
			var moustache := Shapes.sphere(head, Vector3(side * 0.09, -0.205, 0.491), Vector3(0.23, 0.08, 0.06), ink)
			moustache.rotation.z = side * 0.2
	for pair in [[left_arm, -1.0], [right_arm, 1.0]]:
		var arm: Node3D = pair[0]
		var side: float = pair[1]
		visual.add_child(arm)
		arm.position = Vector3(side * 0.35, 1.91, 0)
		Shapes.profile(arm, [Vector3(-0.46, 0.09, 0.095), Vector3(-0.23, 0.115, 0.11), Vector3(-0.05, 0.135, 0.12), Vector3(0.04, 0.025, 0.025)], coat)
		var elbow := Node3D.new()
		arm.add_child(elbow)
		elbow.position.y = -0.43
		elbows.append(elbow)
		Shapes.profile(elbow, [Vector3(-0.4, 0.072, 0.072), Vector3(-0.22, 0.088, 0.085), Vector3(0.02, 0.09, 0.095)], coat)
		Shapes.sphere(elbow, Vector3(0, -0.44, 0.015), Vector3(0.17, 0.23, 0.15), skin)
	for pair in [[left_leg, -1.0], [right_leg, 1.0]]:
		var leg: Node3D = pair[0]
		var side: float = pair[1]
		visual.add_child(leg)
		leg.position = Vector3(side * 0.18, 1.27, 0)
		Shapes.profile(leg, [Vector3(-0.58, 0.085, 0.09), Vector3(-0.3, 0.105, 0.12), Vector3(-0.04, 0.13, 0.14), Vector3(0.06, 0.075, 0.08)], trouser)
		var knee := Node3D.new()
		leg.add_child(knee)
		knee.position.y = -0.55
		knees.append(knee)
		Shapes.profile(knee, [Vector3(-0.54, 0.068, 0.07), Vector3(-0.31, 0.088, 0.1), Vector3(-0.12, 0.094, 0.11), Vector3(0.03, 0.085, 0.09)], trouser)
		Shapes.sphere(knee, Vector3(0, -0.6, 0.065), Vector3(0.22, 0.19, 0.37), boots)
	left_arm.rotation.z = 0.08
	right_arm.rotation.z = -0.08

func build_glasses(frame_material: Material) -> void:
	for side in [-1.0, 1.0]:
		var rim := TorusMesh.new()
		rim.inner_radius = 0.125
		rim.outer_radius = 0.16
		rim.rings = 32
		rim.ring_segments = 12
		var lens := Shapes.mesh(head, rim, Vector3(side * 0.18, -0.02, 0.5), frame_material)
		lens.rotation.x = PI / 2
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		Shapes.box(head, Vector3(side * 0.35, -0.01, 0.36), Vector3(0.035, 0.035, 0.3), frame_material).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Shapes.box(head, Vector3(0, 0.0, 0.505), Vector3(0.1, 0.035, 0.035), frame_material).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func build_hijab() -> void:
	var cloth := Shapes.material(Color("9166b1"))
	var folds := Shapes.material(Color("7f569e"))
	Shapes.sphere(head, Vector3(0, 0.05, -0.08), Vector3(1.04, 1.07, 0.94), cloth)
	# One continuous hood silhouette, with a diagonal fold above the forehead.
	var fold := Shapes.sphere(head, Vector3(-0.18, 0.28, 0.2), Vector3(0.6, 0.19, 0.27), cloth)
	fold.rotation.z = 0.38
	var collar := TorusMesh.new()
	collar.inner_radius = 0.18
	collar.outer_radius = 0.37
	collar.rings = 32
	collar.ring_segments = 12
	Shapes.mesh(head, collar, Vector3(0, -0.43, 0.02), folds, Vector3(1, 0.72, 1))
	var tail := Shapes.sphere(head, Vector3(-0.31, -0.42, -0.31), Vector3(0.3, 0.53, 0.16), cloth)
	tail.rotation.z = -0.4

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
	knees[0].rotation.x = maxf(0, -cos(gait)) * 0.8 * stride
	knees[1].rotation.x = maxf(0, cos(gait)) * 0.8 * stride
	for elbow in elbows:
		elbow.rotation.x = lerpf(elbow.rotation.x, -0.6 if carrying else -0.12 - stride * 0.15, delta * 12)
	left_arm.rotation.x = lerpf(left_arm.rotation.x, -0.95 if carrying else -sin(gait) * 0.5 * stride, delta * 14)
	right_arm.rotation.x = lerpf(right_arm.rotation.x, -0.95 if carrying else sin(gait) * 0.5 * stride, delta * 14)
	left_arm.rotation.z = -0.13 if carrying else 0.08
	right_arm.rotation.z = 0.13 if carrying else -0.08
	visual.position.y = absf(sin(gait)) * 0.06 * stride + sin(Time.get_ticks_msec() * 0.002) * 0.012
	head.rotation.z = sin(gait * 0.5) * 0.015

func facing() -> Vector3:
	return Vector3(sin(visual.rotation.y), 0, cos(visual.rotation.y))
