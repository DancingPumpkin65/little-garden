extends SceneTree

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var character := GardenCharacter.new()
	root.add_child(character)
	character.set_physics_process(false)
	assert(character.imported_skeleton != null, "default player must instantiate the Blender armature")
	var skeleton := character.imported_skeleton
	assert(skeleton.get_bone_count() == 15, "export retains the full body/head/limb armature")
	var meshes := character.model_root.find_children("*", "MeshInstance3D", true, false)
	assert(meshes.size() == 1, "runtime combines source objects into one skinned mesh")
	var triangles := 0
	for node in meshes:
		var instance := node as MeshInstance3D
		assert(instance.skin != null, "runtime mesh must remain skinned")
		assert(instance.mesh.get_surface_count() == 2, "only the chalk and charcoal material surfaces are exported")
		for surface in range(instance.mesh.get_surface_count()):
			var arrays := instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var influences := weights.size() / vertices.size()
			triangles += instance.mesh.surface_get_array_index_len(surface) / 3
			for vertex in range(vertices.size()):
				assert(vertices[vertex].is_finite(), "exported vertices must be finite")
				var total := 0.0
				for influence in range(influences): total += weights[vertex * influences + influence]
				assert(absf(total - 1.0) < 0.001, "every vertex needs normalized skin weights")
	assert(triangles < 5000, "character remains within the low-poly geometry budget")
	character.animate_pose(1.0, 0.0)
	var hand := skeleton.find_bone("hand_L")
	skeleton.force_update_all_bone_transforms()
	var resting_hand := skeleton.get_bone_global_pose(hand).origin
	character.carrying = true
	character.animate_pose(1.0, 0.0)
	skeleton.force_update_all_bone_transforms()
	var raised_hand := skeleton.get_bone_global_pose(hand).origin
	assert(raised_hand.z > resting_hand.z + 0.2 and raised_hand.y > resting_hand.y, "existing carrying pose must raise the imported hand forward")
	character.carrying = false
	character.gait = PI * 1.5
	character.animate_pose(1.0, 1.0)
	assert(character.knees[0].rotation.x > 0.65 and character.knees[1].rotation.x < 0.01, "walk cycle retains alternating recovery")
	character.animate_pose(1.0, 0.0, false)
	assert(character.knees[0].rotation.x > 0.49, "jump pose reaches the imported rig")
	character.animate_pose(1.0, 0.0)
	skeleton.force_update_all_bone_transforms()
	assert(skeleton.get_bone_global_pose(hand).origin.distance_to(resting_hand) < 0.001, "carrying/walking/jumping return to the original idle proportions")
	print("IMPORTED_CHARACTER_PASS ", triangles, " triangles, normalized weights, 15 bones, idle/walk/jump/carry transitions")
	quit()
