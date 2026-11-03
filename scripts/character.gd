class_name GardenCharacter
extends "res://scripts/legacy/procedural_character.gd"

const MODEL := preload("res://assets/characters/reference_character.glb")
const COMPANION_MODEL := preload("res://assets/characters/companion_character.glb")
enum Hop { REST, CROUCH, AIR, LAND }
var hop := Hop.REST
var hop_clock := 0.0
var follow_offset := Vector3.ZERO
var celebration := 0.0
var waiting_for_arm := false
var two_legs := false
var directed_move := false
var move_target := Vector3.ZERO
var door_gesture := 0.0
var birthday_outfit := false
var outfit_blend := 0.0
var outfit_materials: Array[ShaderMaterial] = []
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
	if birthday_outfit and outfit_blend<1:
		outfit_blend = minf(1,outfit_blend+delta*1.2)
		for material in outfit_materials: material.set_shader_parameter("reveal",smoothstep(0,1,outfit_blend))
	if npc and (follow_target != null or directed_move):
		if two_legs: update_companion_walk(delta)
		else: update_companion_hop(delta)
		return
	super._physics_process(delta)
	if npc and imported_skeleton != null: apply_joint_poses()

# After reunion the same controller drives a normal two-leg walk.
func update_companion_walk(delta: float) -> void:
	var target := move_target if directed_move else follow_target.global_position + follow_offset
	var offset := target - global_position
	offset.y = 0
	var direction := offset.normalized() if offset.length() > 0.25 and not waiting_for_arm else Vector3.ZERO
	var speed := 3.2 if directed_move else clampf(offset.length()*1.8,3.2,7.0)
	velocity.x = move_toward(velocity.x,direction.x*speed,delta*18)
	velocity.z = move_toward(velocity.z,direction.z*speed,delta*18)
	if not is_on_floor(): velocity.y -= 18*delta
	move_and_slide()
	var moving := Vector2(velocity.x,velocity.z).length()
	if moving > 0.1: visual.rotation.y = lerp_angle(visual.rotation.y,atan2(velocity.x,velocity.z),delta*9)
	gait += moving*delta*TAU/2.3
	animate_pose(delta,clampf(moving/3.2,0,1),is_on_floor())

# One supporting leg compresses, pushes off, tucks in flight, then absorbs landing.
func update_companion_hop(delta: float) -> void:
	hop_clock += delta
	var offset := (move_target if directed_move else follow_target.global_position + follow_offset) - global_position
	offset.y = 0
	var moving := not waiting_for_arm and offset.length() > (0.75 if follow_offset.length() > 0.1 else 2.4)
	if hop == Hop.REST and moving and is_on_floor():
		hop = Hop.CROUCH
		hop_clock = 0
	if hop == Hop.CROUCH and hop_clock >= 0.16:
		hop = Hop.AIR
		hop_clock = 0
		velocity.y = 4.1
	if not is_on_floor(): velocity.y -= 18 * delta
	var direction := offset.normalized() if moving and hop == Hop.AIR else Vector3.ZERO
	velocity.x = move_toward(velocity.x, direction.x * clampf(offset.length() * 2.5, 4.2, 14), delta * 32)
	velocity.z = move_toward(velocity.z, direction.z * clampf(offset.length() * 2.5, 4.2, 14), delta * 32)
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
		right_arm.rotation.x = -0.25 - 0.4 * sin(clampf(hop_clock / 0.46, 0, 1) * PI)
		right_arm.rotation.z = 0.95
		elbows[1].rotation.x = -0.35
	else:
		right_leg.rotation.x = -0.16 * bend
		knees[1].rotation.x = 0.42 * bend
		left_arm.rotation.x = 0.22 * bend
		left_arm.rotation.z = -0.55
		right_arm.rotation.x = 0.22 * bend
		right_arm.rotation.z = 0.55
	left_leg.rotation.x = 0
	knees[0].rotation.x = 0
	visual.position.y = -0.055 * bend
	visual.rotation.z = -0.065 if hop == Hop.AIR else -0.025
	if celebration > 0:
		celebration -= delta
		left_arm.rotation.x = -1.4 + sin(celebration * 10) * 0.65
		right_arm.rotation.x = left_arm.rotation.x
		left_arm.rotation.z = -0.6
		right_arm.rotation.z = 0.6
	apply_joint_poses()

# Blender bones use different local axes; convert the existing body-space rotations.
func pose_bone(name: StringName, axis: Vector3, angle: float, spread_delta: float = 0.0) -> void:
	var local_axis := (bone_bases[name].inverse() * axis).normalized()
	var spread_axis := (bone_bases[name].inverse() * Vector3.BACK).normalized()
	imported_skeleton.set_bone_pose_rotation(bone_ids[name], rest_rotations[name] * Quaternion(spread_axis, spread_delta) * Quaternion(local_axis, angle))

func apply_joint_poses() -> void:
	visual.rotation.x = 0
	if npc and door_gesture > 0:
		visual.rotation.x = 0.13 * door_gesture
		right_arm.rotation.x = -1.25 * door_gesture
		right_arm.rotation.z = 0.45 - 0.65 * door_gesture
		elbows[1].rotation.x = -0.4 * door_gesture
		left_arm.rotation.x = -0.25 * door_gesture
		left_arm.rotation.z = -0.45 - 0.4 * door_gesture
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

# Rest-pose bone weights mark clothing without recoloring the face, hands or hijab.
func put_on_birthday_outfit() -> void:
	if birthday_outfit: return
	birthday_outfit = true
	if imported_skeleton == null:
		var sweater := Shapes.material(Color("4272ca") if npc else Color("5ed6e3"))
		var pants := Shapes.material(Color("20242c") if npc else Color("8be4eb"))
		for child in visual.get_children():
			if child is MeshInstance3D: child.material_override = sweater
		for limb in [left_arm,right_arm,left_leg,right_leg]:
			for child in limb.get_children():
				if child is MeshInstance3D: child.material_override = pants if limb in [left_leg,right_leg] else sweater
		return
	for node in model_root.find_children("*","MeshInstance3D",true,false):
		var instance := node as MeshInstance3D
		if instance.skin == null: continue
		var source := instance.mesh
		var colored := ArrayMesh.new()
		for surface in range(source.get_surface_count()):
			var arrays := source.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences := weights.size()/vertices.size()
			var colors := PackedColorArray()
			for vertex in range(vertices.size()):
				var pants := 0.0
				var sweater := 0.0
				for i in range(influences):
					var bind := bones[vertex*influences+i]
					var name := instance.skin.get_bind_name(bind)
					if name.is_empty(): name = imported_skeleton.get_bone_name(instance.skin.get_bind_bone(bind))
					var weight := weights[vertex*influences+i]
					if name in [&"thigh_L",&"thigh_R",&"calf_L",&"calf_R"]: pants += weight
					elif name in [&"arm_L",&"arm_R",&"forearm_L",&"forearm_R",&"spine",&"body",&"pelvis",&"root"]: sweater += weight
				colors.append(Color(pants,sweater,0,1))
			arrays[Mesh.ARRAY_COLOR] = colors
			colored.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			var material := ShaderMaterial.new()
			material.shader = Shader.new()
			material.shader.code = "shader_type spatial; uniform vec4 base_color:source_color=vec4(1.0); uniform vec4 sweater:source_color; uniform vec4 pants:source_color; uniform float reveal=0.0; void fragment(){vec3 cloth=mix(base_color.rgb,pants.rgb,COLOR.r);cloth=mix(cloth,sweater.rgb,COLOR.g);ALBEDO=mix(base_color.rgb,cloth,reveal);ROUGHNESS=1.0;SPECULAR=0.0;}"
			var original := source.surface_get_material(surface) as BaseMaterial3D
			material.set_shader_parameter("base_color",original.albedo_color if original!=null else Color.WHITE)
			material.set_shader_parameter("sweater",Color("4272ca") if npc else Color("5ed6e3"))
			material.set_shader_parameter("pants",Color("20242c") if npc else Color("8be4eb"))
			colored.surface_set_material(surface,material)
			outfit_materials.append(material)
		instance.mesh = colored
	if not npc:
		for bone: StringName in [&"foot_L",&"foot_R"]:
			var cuff := BoneAttachment3D.new()
			cuff.bone_name = bone
			imported_skeleton.add_child(cuff)
			# A small scalloped fleece edge follows the ankle bone.
			for i in range(7):
				var a := i*TAU/7
				GardenBloom.lobe(cuff,Vector3(cos(a)*0.14,0.03,sin(a)*0.14),Vector3.ONE*0.11,Color("8be4eb"))
