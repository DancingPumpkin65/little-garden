class_name ProceduralGardenCharacter
extends CharacterBody3D

signal jumped

var visual := Node3D.new()
var left_arm := Node3D.new()
var right_arm := Node3D.new()
var left_leg := Node3D.new()
var right_leg := Node3D.new()
var head := Node3D.new()
var knees: Array[Node3D] = []
var elbows: Array[Node3D] = []
var arm_rigs: Array[Skeleton3D] = []
var leg_rigs: Array[Skeleton3D] = []
var gait := 0.0
var stride_blend := 0.0
var carrying := false
var drive := Vector3.ZERO
var jump_requested := false
var sprint := false
var npc := false

func _ready() -> void:
	safe_margin = 0.001
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 2.55
	collision.shape = capsule
	collision.position.y = 1.275
	add_child(collision)
	add_child(visual)
	var skin := Shapes.material(Color("eeeeee"), 1.0)
	var ink := Shapes.material(Color("17191a"), 1.0)
	var coat := skin
	var trouser := skin
	var boots := skin
	# One sparse, chunky shirt volume, without an anatomical waist or collar.
	Shapes.profile(visual, [Vector3(1.09, 0.001, 0.001), Vector3(1.09, 0.34, 0.23), Vector3(1.14, 0.40, 0.27), Vector3(1.55, 0.38, 0.26), Vector3(1.74, 0.34, 0.23), Vector3(1.84, 0.21, 0.16), Vector3(1.87, 0.001, 0.001)], coat, INF, 10, true)
	visual.add_child(head)
	head.position.y = 2.16
	head.scale = Vector3.ONE * 0.8
	Shapes.faceted(head, Vector3(0, -0.01, 0.02), Vector3(0.94, 0.94, 0.83), skin)
	if npc:
		Shapes.faceted(head, Vector3(0, 0.20, -0.10), Vector3(1.02, 0.68, 0.87), ink)
	else:
		build_hair(ink)
	for side in [-1.0, 1.0]:
		Shapes.faceted(head, Vector3(side * 0.19, 0.025, 0.426), Vector3(0.115, 0.115, 0.025), ink)
	if not npc:
		build_glasses(ink)
	else:
		for side in [-1.0, 1.0]:
			Shapes.faceted(head, Vector3(side * 0.085, -0.18, 0.42), Vector3(0.20, 0.075, 0.05), ink)
	for part in head.get_children():
		if part is MeshInstance3D:
			part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for pair in [[left_arm, -1.0], [right_arm, 1.0]]:
		var arm: Node3D = pair[0]
		var side: float = pair[1]
		visual.add_child(arm)
		arm.position = Vector3(side * 0.33, 1.73, 0)
		var arm_mesh := Shapes.profile(arm, [Vector3(-0.76, 0.001, 0.001), Vector3(-0.73, 0.14, 0.14), Vector3(-0.50, 0.155, 0.15), Vector3(-0.36, 0.166, 0.16), Vector3(-0.18, 0.18, 0.17), Vector3(0.0, 0.18, 0.17), Vector3(0.06, 0.001, 0.001)], coat, 0.36, 8, true)
		arm_rigs.append(arm_mesh.get_node(arm_mesh.skeleton) as Skeleton3D)
		var elbow := Node3D.new()
		arm.add_child(elbow)
		elbow.position.y = -0.36
		elbows.append(elbow)
		Shapes.faceted(elbow, Vector3(0, -0.38, 0.015), Vector3(0.47, 0.34, 0.40), skin)
	for pair in [[left_leg, -1.0], [right_leg, 1.0]]:
		var leg: Node3D = pair[0]
		var side: float = pair[1]
		visual.add_child(leg)
		leg.position = Vector3(side * 0.215, 1.14, 0)
		leg.rotation.z = side * 0.055
		leg.rotation.y = side * 0.04
		var leg_mesh := Shapes.profile(leg, [Vector3(-0.99, 0.001, 0.001), Vector3(-0.96, 0.155, 0.17), Vector3(-0.80, 0.17, 0.18), Vector3(-0.49, 0.19, 0.20), Vector3(-0.20, 0.205, 0.215), Vector3(0.03, 0.21, 0.22), Vector3(0.12, 0.001, 0.001)], trouser, 0.49, 10, true)
		leg_rigs.append(leg_mesh.get_node(leg_mesh.skeleton) as Skeleton3D)
		var knee := Node3D.new()
		leg.add_child(knee)
		knee.position.y = -0.49
		knees.append(knee)
		Shapes.faceted(knee, Vector3(0, -0.53, 0.09), Vector3(0.37, 0.24, 0.52), boots)
	left_arm.rotation.z = -0.45
	right_arm.rotation.z = 0.45

func build_glasses(frame_material: Material) -> void:
	for side in [-1.0, 1.0]:
		var rim := TorusMesh.new()
		rim.inner_radius = 0.12
		rim.outer_radius = 0.137
		rim.rings = 20
		rim.ring_segments = 6
		var lens := Shapes.mesh(head, rim, Vector3(side * 0.19, 0.025, 0.45), frame_material)
		lens.rotation.x = PI / 2
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	Shapes.box(head, Vector3(0, 0.025, 0.452), Vector3(0.12, 0.02, 0.02), frame_material).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func build_hair(ink: Material) -> void:
	# One connected cap and back curtain, with the lower front left open for the face.
	var rings := [Vector3(-0.72, 0.46, 0.39), Vector3(0.13, 0.53, 0.50), Vector3(0.35, 0.43, 0.42), Vector3(0.51, 0.25, 0.24), Vector3(0.57, 0.001, 0.001)]
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(rings.size() - 1):
		var low: Vector3 = rings[row]
		var high: Vector3 = rings[row + 1]
		for i in range(12):
			var a := i * TAU / 12
			var b := (i + 1) * TAU / 12
			if row == 0 and sin((a + b) * 0.5) > 0: continue
			var points := [Vector3(cos(a) * low.y, low.x, sin(a) * low.z - 0.06), Vector3(cos(b) * low.y, low.x, sin(b) * low.z - 0.06), Vector3(cos(b) * high.y, high.x, sin(b) * high.z - 0.06), Vector3(cos(a) * high.y, high.x, sin(a) * high.z - 0.06)]
			for index in [0, 1, 2, 0, 2, 3]:
				surface.set_smooth_group(-1)
				var point: Vector3 = points[index]
				if row == 0 and index < 2:
					point.z -= 0.12
					point.y += 0.035 * sin((a if index == 0 else b) * 3.0)
				surface.add_vertex(point)
	surface.generate_normals()
	Shapes.mesh(head, surface.commit(), Vector3.ZERO, ink)
	for side in [-1.0, 1.0]:
		Shapes.box(head, Vector3(side * 0.43, -0.02, 0.15), Vector3(0.10, 0.44, 0.20), ink)

func _physics_process(delta: float) -> void:
	if npc:
		gait += delta
		head.rotation.z = sin(gait * 1.4) * 0.025
		visual.position.y = 0
		return
	var speed := 5.4 if sprint else 3.5
	velocity.x = move_toward(velocity.x, drive.x * speed, delta * 18)
	velocity.z = move_toward(velocity.z, drive.z * speed, delta * 18)
	if not is_on_floor(): velocity.y -= 18 * delta
	if jump_requested and is_on_floor():
		velocity.y = 6.4
		jumped.emit()
	jump_requested = false
	move_and_slide()
	var planar_speed := Vector2(velocity.x, velocity.z).length()
	if planar_speed > 0.1:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(velocity.x, velocity.z), delta * 12)
	# Advance by distance, so footsteps slow with the controller instead of sliding.
	stride_blend = lerpf(stride_blend, clampf(planar_speed / 3.5, 0, 1), 1.0 - exp(-delta * 10))
	gait += planar_speed * delta * TAU / (2.8 if sprint else 2.3)
	animate_pose(delta, stride_blend, is_on_floor())

# The knee folds during recovery, half a cycle apart for the two legs.
func animate_pose(delta: float, stride: float, grounded: bool = true) -> void:
	var blend := 1.0 - exp(-delta * 14)
	var amplitude := 0.65 if sprint else 0.48
	for i in range(2):
		var phase := gait + i * PI
		var leg := left_leg if i == 0 else right_leg
		var hip := -cos(phase) * amplitude * stride if grounded else (-0.65 if i == 0 else 0.55)
		var knee := pow(maxf(0, -sin(phase)), 1.5) * (1.05 if sprint else 0.7) * stride if grounded else (0.55 if i == 0 else 0.85)
		leg.rotation.x = lerpf(leg.rotation.x, hip, blend)
		knees[i].rotation.x = lerpf(knees[i].rotation.x, knee, blend)
		elbows[i].rotation.x = lerpf(elbows[i].rotation.x, -0.6 if carrying else -0.16 - stride * 0.12, blend)
	left_arm.rotation.x = lerpf(left_arm.rotation.x, (-0.95 if carrying else cos(gait) * 0.38 * stride) if grounded else -2.25, blend)
	right_arm.rotation.x = lerpf(right_arm.rotation.x, (-0.95 if carrying else -cos(gait) * 0.38 * stride) if grounded else (-2.25 if carrying else -2.05), blend)
	left_arm.rotation.z = -0.13 if carrying else -0.45
	right_arm.rotation.z = 0.13 if carrying else 0.45
	if not grounded:
		left_arm.rotation.z = -0.25
		right_arm.rotation.z = 0.25
	visual.position.y = lerpf(visual.position.y, (1.0 - cos(gait * 2)) * 0.018 * stride if grounded else 0.0, blend)
	visual.rotation.z = lerpf(visual.rotation.z, sin(gait) * 0.018 * stride, blend)
	head.rotation.z = sin(gait) * 0.01 * stride
	apply_joint_poses()

func facing() -> Vector3:
	return Vector3(sin(visual.rotation.y), 0, cos(visual.rotation.y))

# Imported visuals override this seam while retaining the same controller/pose logic.
func apply_joint_poses() -> void:
	for i in range(2):
		leg_rigs[i].set_bone_pose_rotation(1, Quaternion(Vector3.RIGHT, knees[i].rotation.x))
		arm_rigs[i].set_bone_pose_rotation(1, Quaternion(Vector3.RIGHT, elbows[i].rotation.x))
