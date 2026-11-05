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
@export var outfit_transition_duration := 0.9
var outfit_reveal_progress := 0.0
var outfit_original_overrides: Dictionary[MeshInstance3D,Array] = {}
var follow_target: Node3D
@export_group("Birthday companion")
@export var garden_walk_speed := 3.4
@export var garden_run_speed := 6.6
@export var garden_catchup_distance := 6.0
@export var garden_stop_distance := 0.65
@export var garden_hop_interval := Vector2(4.0,8.0)
@export var garden_hop_strength := 3.4
@export var garden_style_interval := Vector2(3.0,6.0)
@export_range(0.0,1.0) var garden_run_chance := 0.3
@export var birthday_dance_duration := 6.0
@export var garden_roam_radius := 4.5
@export var garden_goal_interval := Vector2(2.5,5.0)
var garden_roaming := false
var garden_camera: Camera3D
var garden_bounds := Rect2()
var garden_goal := Vector3.ZERO
var garden_goal_wait := 0.0
var garden_pause_remaining := 0.0
var garden_interest_position := Vector3.INF
var garden_mode := false
var dance_remaining := 0.0
var dance_clock := 0.0
var garden_hop_wait := 0.0
var garden_style_wait := 0.0
var garden_running := false
var garden_random := RandomNumberGenerator.new()
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
	if npc and garden_mode:
		update_garden_companion(delta)
		return
	if npc and (follow_target != null or directed_move):
		if two_legs: update_companion_walk(delta)
		else: update_companion_hop(delta)
		return
	super._physics_process(delta)
	if npc and imported_skeleton != null: apply_joint_poses()

func celebrate_in_garden(player: Node3D) -> void:
	garden_mode = true
	two_legs = true
	directed_move = false
	waiting_for_arm = false
	follow_target = player
	garden_random.randomize()
	dance_remaining = birthday_dance_duration
	dance_clock = 0
	garden_hop_wait = garden_random.randf_range(garden_hop_interval.x,garden_hop_interval.y)
	garden_style_wait = 0

func update_garden_companion(delta: float) -> void:
	if not is_instance_valid(follow_target): return
	if dance_remaining>0:
		# Let Salma leave the celebration without losing her companion.
		if global_position.distance_to(follow_target.global_position)>6 and dance_clock>1.5:
			dance_remaining = minf(dance_remaining,.4)
		dance_remaining = maxf(0,dance_remaining-delta)
		dance_clock += delta
		var facing_player := follow_target.global_position-global_position
		if Vector2(facing_player.x,facing_player.z).length()>.5:
			visual.rotation.y = lerp_angle(visual.rotation.y,atan2(facing_player.x,facing_player.z)-global_rotation.y,1-exp(-delta*6))
		velocity.x = move_toward(velocity.x,0,delta*20)
		velocity.z = move_toward(velocity.z,0,delta*20)
		if not is_on_floor(): velocity.y -= 18*delta
		move_and_slide()
		animate_pose(delta,0,true)
		var blend := smoothstep(0,.45,dance_clock)*smoothstep(0,.4,dance_remaining)
		var beat := dance_clock*TAU*1.35
		visual.rotation.z = sin(beat)*.07*blend
		visual.position.y = -.008*(1-cos(beat*2))*blend
		left_arm.rotation.x = (-.55+sin(beat)*.25)*blend
		right_arm.rotation.x = (-.55-sin(beat)*.25)*blend
		left_arm.rotation.z = -.45-.15*blend
		right_arm.rotation.z = .45+.15*blend
		elbows[0].rotation.x = (-.3-.1*cos(beat))*blend
		elbows[1].rotation.x = (-.3+.1*cos(beat))*blend
		for knee in knees: knee.rotation.x = .12*(1-cos(beat*2))*blend
		apply_joint_poses()
		return
	var target := follow_target.global_position+follow_offset
	if garden_roaming:
		if garden_bounds.has_area():
			target.x = clampf(target.x,garden_bounds.position.x,garden_bounds.end.x)
			target.z = clampf(target.z,garden_bounds.position.y,garden_bounds.end.y)
		garden_goal_wait -= delta
		if garden_goal_wait<=0 or garden_goal.distance_to(follow_target.global_position)>9 or not garden_point_visible(garden_goal):
			garden_goal_wait = garden_random.randf_range(garden_goal_interval.x,garden_goal_interval.y)
			garden_goal = target
			for attempt in range(8):
				var candidate := target+Vector3(garden_random.randf_range(-garden_roam_radius,garden_roam_radius),0,garden_random.randf_range(-garden_roam_radius,garden_roam_radius))
				if candidate.distance_to(follow_target.global_position)<1.8: continue
				if garden_bounds.has_area():
					candidate.x = clampf(candidate.x,garden_bounds.position.x,garden_bounds.end.x)
					candidate.z = clampf(candidate.z,garden_bounds.position.y,garden_bounds.end.y)
				if garden_point_visible(candidate):
					garden_goal = candidate
					break
			target = garden_goal
		else: target = garden_goal
	if garden_pause_remaining>0:
		if global_position.distance_to(follow_target.global_position)>9: garden_pause_remaining = 0
		garden_pause_remaining -= delta
		target = global_position
		if garden_interest_position.is_finite():
			var interest := garden_interest_position-global_position
			visual.rotation.y = lerp_angle(visual.rotation.y,atan2(interest.x,interest.z)-global_rotation.y,1-exp(-delta*5))
	var offset := target-global_position
	offset.y = 0
	var distance := offset.length()
	garden_hop_wait -= delta
	garden_style_wait -= delta
	if garden_style_wait<=0:
		garden_running = garden_random.randf()<garden_run_chance
		garden_style_wait = garden_random.randf_range(garden_style_interval.x,garden_style_interval.y)
	sprint = garden_running or distance>garden_catchup_distance
	var speed := garden_run_speed if sprint else garden_walk_speed
	speed = minf(speed,distance*3)
	var direction := offset.normalized() if distance>garden_stop_distance else Vector3.ZERO
	velocity.x = move_toward(velocity.x,direction.x*speed,delta*14)
	velocity.z = move_toward(velocity.z,direction.z*speed,delta*14)
	if not is_on_floor(): velocity.y -= 18*delta
	elif garden_hop_wait<=0 and distance>1.4:
		velocity.y = garden_hop_strength
		garden_hop_wait = garden_random.randf_range(garden_hop_interval.x,garden_hop_interval.y)
	move_and_slide()
	var moving := Vector2(velocity.x,velocity.z).length()
	if moving>.15: visual.rotation.y = lerp_angle(visual.rotation.y,atan2(velocity.x,velocity.z)-global_rotation.y,1-exp(-delta*9))
	gait += moving*delta*TAU/(2.8 if sprint else 2.3)
	animate_pose(delta,clampf(moving/garden_walk_speed,0,1),is_on_floor())

func garden_point_visible(point: Vector3) -> bool:
	if not is_instance_valid(garden_camera): return true
	if garden_camera.is_position_behind(point+Vector3.UP): return false
	var area := garden_camera.get_viewport().get_visible_rect()
	return area.grow(-minf(area.size.x,area.size.y)*.12).has_point(garden_camera.unproject_position(point+Vector3.UP))

# After reunion the same controller drives a normal two-leg walk.
func update_companion_walk(delta: float) -> void:
	var target := move_target if directed_move else follow_target.global_position + follow_offset
	var offset := target - global_position
	offset.y = 0
	var direction := offset.normalized() if offset.length() > 0.25 and not waiting_for_arm else Vector3.ZERO
	var speed := 4.8 if directed_move else clampf(offset.length()*1.8,3.2,7.0)
	speed = minf(speed,offset.length()*4.0)
	velocity.x = move_toward(velocity.x,direction.x*speed,delta*18)
	velocity.z = move_toward(velocity.z,direction.z*speed,delta*18)
	if not is_on_floor(): velocity.y -= 18*delta
	move_and_slide()
	var moving := Vector2(velocity.x,velocity.z).length()
	if moving > 0.1: visual.rotation.y = lerp_angle(visual.rotation.y,atan2(velocity.x,velocity.z)-global_rotation.y,delta*9)
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
	if moving: visual.rotation.y = lerp_angle(visual.rotation.y, atan2(offset.x, offset.z)-global_rotation.y, delta * 7)
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

# Garments are separate Blender meshes sharing the existing skeleton and pose controller.
func put_on_birthday_outfit() -> void:
	if birthday_outfit: return
	birthday_outfit = true
	if imported_skeleton == null: return
	var packed := load("res://assets/characters/"+("guy" if npc else "girl")+"_wardrobe.glb") as PackedScene
	var source := packed.instantiate()
	add_child(source)
	source.hide()
	var wardrobe := Node3D.new()
	wardrobe.name = "Birthday clothing"
	model_root.add_child(wardrobe)
	var reveal := create_tween()
	var appearing_materials: Array[ShaderMaterial] = []
	var retiring_materials: Array[ShaderMaterial] = []
	var retiring: Array[MeshInstance3D] = []
	for child: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
		if child.skin==null: continue
		var garment := MeshInstance3D.new()
		garment.name = child.name
		garment.mesh = child.mesh
		garment.skin = child.skin
		wardrobe.add_child(garment)
		garment.transform = source.global_transform.affine_inverse()*child.global_transform
		garment.skeleton = garment.get_path_to(imported_skeleton)
		appearing_materials.append_array(prepare_outfit_fade(garment,true))
	source.free()
	# Remove only covered body triangles. Face, mittens, shoes and identity accessories stay.
	for child: MeshInstance3D in model_root.find_children("*","MeshInstance3D",true,false):
		if child.skin==null or wardrobe.is_ancestor_of(child): continue
		if child.name in [&"TORSO",&"ARM_LEFT",&"ARM_RIGHT",&"LEG_LEFT",&"LEG_RIGHT",&"FOOT_LEFT",&"FOOT_RIGHT"]:
			if child.visible:
				retiring.append(child)
				retiring_materials.append_array(prepare_outfit_fade(child,false))
			continue
		var covered := ArrayMesh.new()
		for surface in range(child.mesh.get_surface_count()):
			var arrays := child.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			var keep := PackedInt32Array()
			var influences := weights.size()/vertices.size()
			for triangle in range(0,indices.size(),3):
				var dressed := 0.0
				for corner in range(3):
					var vertex := indices[triangle+corner]
					for influence in range(influences):
						var bind := bones[vertex*influences+influence]
						var bone := child.skin.get_bind_name(bind)
						if bone in [&"body",&"root",&"arm_L",&"arm_R",&"forearm_L",&"forearm_R",&"thigh_L",&"thigh_R",&"calf_L",&"calf_R"]:
							dressed += weights[vertex*influences+influence]
				if dressed<1.5:
					keep.append_array(indices.slice(triangle,triangle+3))
			if keep.is_empty(): continue
			arrays[Mesh.ARRAY_INDEX] = keep
			covered.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			covered.surface_set_material(covered.get_surface_count()-1,child.mesh.surface_get_material(surface))
		child.mesh = covered

	reveal.tween_method(func(progress: float):
		outfit_reveal_progress = progress
		for material in appearing_materials: material.set_shader_parameter("reveal",progress)
		for material in retiring_materials: material.set_shader_parameter("reveal",progress)
	,0.0,1.0,outfit_transition_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	reveal.tween_callback(func():
		for mesh in outfit_original_overrides:
			for surface in range(mesh.mesh.get_surface_count()):
				mesh.set_surface_override_material(surface,outfit_original_overrides[mesh][surface])
		outfit_original_overrides.clear()
		for body in retiring:
			body.hide()
	)

# Complementary opaque dithering avoids see-through limbs during the outfit change.
func prepare_outfit_fade(mesh: MeshInstance3D, incoming: bool) -> Array[ShaderMaterial]:
	var materials: Array[ShaderMaterial] = []
	var originals: Array = []
	for surface in range(mesh.mesh.get_surface_count()):
		originals.append(mesh.get_surface_override_material(surface))
		var original := mesh.get_active_material(surface) as BaseMaterial3D
		if original==null: continue
		var material := ShaderMaterial.new()
		material.shader = preload("res://shaders/outfit_reveal.gdshader")
		material.set_shader_parameter("cloth_color",original.albedo_color)
		material.set_shader_parameter("incoming",incoming)
		material.set_shader_parameter("reveal",0.0)
		mesh.set_surface_override_material(surface,material)
		materials.append(material)
	outfit_original_overrides[mesh] = originals
	return materials
