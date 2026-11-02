class_name GardenCharacter
extends "res://scripts/legacy/procedural_character.gd"

const MODEL := preload("res://assets/characters/reference_character.glb")
const COMPANION_MODEL := preload("res://assets/characters/companion_character.glb")
enum Hop { REST, CROUCH, AIR, LAND }
var hop := Hop.REST
var hop_clock := 0.0
var follow_target: Node3D
var imported_skeleton: Skeleton3D
var action := ""
var action_phase := 0.0
var model_root: Node3D
var bone_ids: Dictionary[StringName, int] = {}
var bone_bases: Dictionary[StringName, Basis] = {}
var rest_rotations: Dictionary[StringName, Quaternion] = {}

func _ready() -> void:
	# Explicit fallback keeps the previous complete implementation.
	if "--procedural-character" in OS.get_cmdline_user_args():
		super._ready()
		if not npc: add_head_flower()
		return
	safe_margin = 0.001
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 2.55
	collision.shape = capsule
	collision.position.y = 1.275
	add_child(collision)
	add_child(visual)
	model_root = (COMPANION_MODEL if npc else MODEL).instantiate()
	visual.add_child(model_root)
	var skeletons := model_root.find_children("*", "Skeleton3D", true, false)
	assert(skeletons.size() == 1, "character GLB must contain one armature")
	imported_skeleton = skeletons[0] as Skeleton3D
	for name: StringName in [&"head", &"arm_L", &"arm_R", &"forearm_L", &"forearm_R", &"thigh_L", &"thigh_R", &"calf_L", &"calf_R", &"hand_L", &"hand_R", &"foot_L", &"foot_R"]:
		var index := imported_skeleton.find_bone(name)
		assert(index >= 0, "missing imported bone: " + name)
		bone_ids[name] = index
		bone_bases[name] = imported_skeleton.get_bone_global_rest(index).basis.orthonormalized()
		rest_rotations[name] = imported_skeleton.get_bone_pose_rotation(index)
	var sole_height := INF
	for node in model_root.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		var bounds: AABB = (model_root.global_transform.affine_inverse() * instance.global_transform) * instance.get_aabb()
		sole_height = minf(sole_height, bounds.position.y)
		for surface in range(instance.mesh.get_surface_count()):
			var material := instance.mesh.surface_get_material(surface) as BaseMaterial3D
			material.disable_receive_shadows = true
	# Mesh soles and capsule bottom share the same origin.
	model_root.position.y = -sole_height
	# Empty pose nodes retain the controller's existing animation state contract.
	visual.add_child(head)
	for limb in [left_arm, right_arm, left_leg, right_leg]: visual.add_child(limb)
	for i in range(2):
		var elbow := Node3D.new()
		(left_arm if i == 0 else right_arm).add_child(elbow)
		elbows.append(elbow)
		var knee := Node3D.new()
		(left_leg if i == 0 else right_leg).add_child(knee)
		knees.append(knee)
	left_arm.rotation.z = -0.45
	right_arm.rotation.z = 0.45
	apply_joint_poses()
	if not npc: add_head_flower()

func _physics_process(delta: float) -> void:
	if npc and follow_target != null:
		update_companion_hop(delta)
		return
	super._physics_process(delta)
	if npc and imported_skeleton != null: apply_joint_poses()

# One supporting leg compresses, pushes off, tucks in flight, then absorbs landing.
func update_companion_hop(delta: float) -> void:
	hop_clock += delta
	var offset := follow_target.global_position - global_position
	offset.y = 0
	var moving := offset.length() > 2.4
	if hop == Hop.REST and moving and is_on_floor():
		hop = Hop.CROUCH
		hop_clock = 0
	if hop == Hop.CROUCH and hop_clock >= 0.16:
		hop = Hop.AIR
		hop_clock = 0
		velocity.y = 4.1
	if not is_on_floor(): velocity.y -= 18 * delta
	var direction := offset.normalized() if moving and hop == Hop.AIR else Vector3.ZERO
	velocity.x = move_toward(velocity.x, direction.x * 2.6, delta * 14)
	velocity.z = move_toward(velocity.z, direction.z * 2.6, delta * 14)
	move_and_slide()
	if hop == Hop.AIR and is_on_floor():
		hop = Hop.LAND
		hop_clock = 0
	if hop == Hop.LAND and hop_clock >= 0.13:
		hop = Hop.REST
		hop_clock = 0
	if moving: visual.rotation.y = lerp_angle(visual.rotation.y, atan2(offset.x, offset.z), delta * 7)
	animate_pose(delta, 0.0, true)
	var bend := 0.0
	if hop == Hop.CROUCH: bend = smoothstep(0, 0.16, hop_clock)
	if hop == Hop.LAND: bend = 1 - smoothstep(0, 0.13, hop_clock)
	if hop == Hop.AIR:
		right_leg.rotation.x = -0.24 + 0.24 * clampf(-velocity.y / 4.1, -1, 1)
		knees[1].rotation.x = 0.35 + 0.65 * sin(clampf(hop_clock / 0.46, 0, 1) * PI)
		left_arm.rotation.x = -0.25
		left_arm.rotation.z = -0.95
		elbows[0].rotation.x = -0.35
	else:
		right_leg.rotation.x = -0.16 * bend
		knees[1].rotation.x = 0.42 * bend
		left_arm.rotation.x = 0.22 * bend
		left_arm.rotation.z = -0.55
	left_leg.rotation.x = 0
	knees[0].rotation.x = 0
	visual.position.y = -0.055 * bend
	visual.rotation.z = -0.065 if hop == Hop.AIR else -0.025
	apply_joint_poses()

# Blender bones use different local axes; convert the existing body-space rotations.
func pose_bone(name: StringName, axis: Vector3, angle: float, spread_delta: float = 0.0) -> void:
	var local_axis := (bone_bases[name].inverse() * axis).normalized()
	var spread_axis := (bone_bases[name].inverse() * Vector3.BACK).normalized()
	imported_skeleton.set_bone_pose_rotation(bone_ids[name], rest_rotations[name] * Quaternion(spread_axis, spread_delta) * Quaternion(local_axis, angle))

func apply_joint_poses() -> void:
	visual.rotation.x = 0
	if carrying and imported_skeleton != null:
		left_arm.rotation.z = 0.6
		right_arm.rotation.z = -0.6
	if not action.is_empty():
		var shoulder := -0.95
		var elbow := -0.6
		if action == "pickup":
			var reach := sin(action_phase * PI)
			visual.position.y = -0.42 * reach
			visual.rotation.x = -0.22 * reach
			left_leg.rotation.x = -0.28 * reach
			right_leg.rotation.x = -0.28 * reach
			for joint in knees: joint.rotation.x = 0.56 * reach
			shoulder = lerpf(-0.45, -0.95, smoothstep(0.25, 1.0, action_phase))
			elbow = lerpf(-0.1, -0.6, smoothstep(0.25, 1.0, action_phase))
		elif action == "throw":
			if action_phase < 0.45:
				shoulder = lerpf(-0.95, -2.35, smoothstep(0.0, 0.45, action_phase))
				elbow = lerpf(-0.6, -1.05, smoothstep(0.0, 0.45, action_phase))
			else:
				shoulder = lerpf(-2.35, -0.25, smoothstep(0.45, 1.0, action_phase))
				elbow = lerpf(-1.05, -0.12, smoothstep(0.45, 0.75, action_phase))
		left_arm.rotation.x = shoulder
		right_arm.rotation.x = shoulder
		left_arm.rotation.z = 0.6 if imported_skeleton != null else -0.13
		right_arm.rotation.z = -left_arm.rotation.z
		for joint in elbows: joint.rotation.x = elbow
	if imported_skeleton == null:
		super.apply_joint_poses()
		return
	pose_bone(&"arm_L", Vector3.RIGHT, left_arm.rotation.x, left_arm.rotation.z + 0.45)
	pose_bone(&"arm_R", Vector3.RIGHT, right_arm.rotation.x, right_arm.rotation.z - 0.45)
	pose_bone(&"forearm_L", Vector3.RIGHT, elbows[0].rotation.x)
	pose_bone(&"forearm_R", Vector3.RIGHT, elbows[1].rotation.x)
	pose_bone(&"thigh_L", Vector3.RIGHT, left_leg.rotation.x)
	pose_bone(&"thigh_R", Vector3.RIGHT, right_leg.rotation.x)
	pose_bone(&"calf_L", Vector3.RIGHT, knees[0].rotation.x)
	pose_bone(&"calf_R", Vector3.RIGHT, knees[1].rotation.x)
	pose_bone(&"head", Vector3.BACK, head.rotation.z)
	if carrying or action == "pickup":
		# Wrist x is sinusoidal around the shoulder. Solve that arc to keep
		# both mittens on the fruit throughout the reach and overhand windup.
		var samples: Array[float] = []
		for spread in [0.0, PI / 2, PI]:
			pose_bone(&"arm_L", Vector3.RIGHT, left_arm.rotation.x, spread)
			imported_skeleton.force_update_all_bone_transforms()
			samples.append(imported_skeleton.get_bone_global_pose(bone_ids[&"hand_L"]).origin.x)
		var center := (samples[0] + samples[2]) * 0.5
		var a := samples[0] - center
		var b := samples[1] - center
		var radius := Vector2(a, b).length()
		var phase := atan2(b, a)
		var arc := acos(clampf((-0.26 - center) / maxf(radius, 0.001), -1, 1))
		var first := wrapf(phase + arc, -PI, PI)
		var second := wrapf(phase - arc, -PI, PI)
		var spread := first if absf(first) < absf(second) else second
		pose_bone(&"arm_L", Vector3.RIGHT, left_arm.rotation.x, spread)
		pose_bone(&"arm_R", Vector3.RIGHT, right_arm.rotation.x, -spread)

func fruit_position() -> Vector3:
	if imported_skeleton != null:
		imported_skeleton.force_update_all_bone_transforms()
		var left := imported_skeleton.get_bone_global_pose(bone_ids[&"hand_L"]).origin
		var right := imported_skeleton.get_bone_global_pose(bone_ids[&"hand_R"]).origin
		return imported_skeleton.global_transform * ((left + right) * 0.5)
	return global_position + Vector3.UP * 1.38 + facing() * 0.67

# Preview the release pose without changing the visible carry pose.
func throw_origin(phase: float) -> Vector3:
	var saved_action := action
	var saved_phase := action_phase
	var arm_angles := [left_arm.rotation, right_arm.rotation]
	var elbow_angles := [elbows[0].rotation, elbows[1].rotation]
	action = "throw"
	action_phase = phase
	apply_joint_poses()
	var point := fruit_position()
	action = saved_action
	action_phase = saved_phase
	left_arm.rotation = arm_angles[0]
	right_arm.rotation = arm_angles[1]
	elbows[0].rotation = elbow_angles[0]
	elbows[1].rotation = elbow_angles[1]
	apply_joint_poses()
	return point

func add_head_flower() -> void:
	var attachment: Node3D
	if imported_skeleton == null:
		attachment = Node3D.new()
		head.add_child(attachment)
	else:
		var bone_attachment := BoneAttachment3D.new()
		bone_attachment.bone_name = "head"
		imported_skeleton.add_child(bone_attachment)
		attachment = bone_attachment
	var stem := Shapes.material(Color("45865a"))
	var petals := Shapes.material(Color("fff9eb"))
	var center := Shapes.material(Color("e6c35d"))
	Shapes.cylinder(attachment, Vector3(0, 0.49, 0), 0.018, 0.34, stem)
	flower_lobe(attachment, Vector3(0.075, 0.45, 0), Vector3(0.15, 0.05, 0.07), stem).rotation.z = 0.5
	for i in range(5):
		var angle := i * TAU / 5
		flower_lobe(attachment, Vector3(cos(angle) * 0.11, 0.66 + sin(angle) * 0.11, 0), Vector3(0.18, 0.10, 0.07), petals).rotation.z = angle
	flower_lobe(attachment, Vector3(0, 0.66, 0.025), Vector3(0.11, 0.11, 0.07), center)

func flower_lobe(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radial_segments = 8
	mesh.rings = 3
	mesh.radius = 0.5
	mesh.height = 1
	return Shapes.mesh(parent, mesh, at, material, size)
