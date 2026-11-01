class_name GardenCharacter
extends "res://scripts/legacy/procedural_character.gd"

const MODEL := preload("res://assets/characters/reference_character.glb")
const COMPANION_MODEL := preload("res://assets/characters/companion_character.glb")
var imported_skeleton: Skeleton3D
var model_root: Node3D
var bone_ids: Dictionary[StringName, int] = {}
var bone_bases: Dictionary[StringName, Basis] = {}
var rest_rotations: Dictionary[StringName, Quaternion] = {}

func _ready() -> void:
	# Explicit fallback keeps the previous complete implementation.
	if "--procedural-character" in OS.get_cmdline_user_args():
		super._ready()
		return
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
	for node in model_root.find_children("*", "MeshInstance3D", true, false):
		var instance := node as MeshInstance3D
		for surface in range(instance.mesh.get_surface_count()):
			var material := instance.mesh.surface_get_material(surface) as BaseMaterial3D
			material.disable_receive_shadows = true
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

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if npc and imported_skeleton != null: apply_joint_poses()

# Blender bones use different local axes; convert the existing body-space rotations.
func pose_bone(name: StringName, axis: Vector3, angle: float, spread_delta: float = 0.0) -> void:
	var local_axis := (bone_bases[name].inverse() * axis).normalized()
	var spread_axis := (bone_bases[name].inverse() * Vector3.BACK).normalized()
	imported_skeleton.set_bone_pose_rotation(bone_ids[name], rest_rotations[name] * Quaternion(spread_axis, spread_delta) * Quaternion(local_axis, angle))

func apply_joint_poses() -> void:
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
