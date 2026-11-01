extends SceneTree

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var character := GardenCharacter.new()
	root.add_child(character)
	for limb in [character.left_leg, character.left_arm]:
		var instance := limb.get_child(0) as MeshInstance3D
		assert(instance.mesh.surface_get_array_len(0) < 700, "limbs must remain sparse low-poly meshes")
		if limb == character.left_leg:
			assert(instance.mesh.get_aabb().size.x >= 0.38 and instance.mesh.get_aabb().size.y < 1.2, "reference legs are short and chunky")
		var vertices: PackedVector3Array = instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var radii: Dictionary[float, Vector2] = {}
		for vertex in vertices:
			var height := snappedf(vertex.y, 0.001)
			var radius := Vector2(absf(vertex.x), absf(vertex.z))
			radii[height] = radii.get(height, Vector2.ZERO).max(radius)
		var heights := radii.keys()
		heights.sort()
		assert(radii[heights[0]].length() < 0.01 and radii[heights[-1]].length() < 0.01, "limb ends must close with rounded caps instead of open cut edges")
		heights = heights.filter(func(height: float) -> bool: return height >= (-1.02 if limb == character.left_leg else -0.84) and height <= -0.10)
		for i in range(1, heights.size()):
			assert(radii[heights[i]].x >= radii[heights[i - 1]].x - 0.001, "limb width must taper steadily from hip/shoulder to ankle/wrist")
			assert(radii[heights[i]].y >= radii[heights[i - 1]].y - 0.001, "limb depth must taper steadily")
	assert(character.left_arm.position.x > -0.36 and character.right_arm.position.x < 0.36, "shoulder roots must sit inside the torso")
	assert(character.left_leg.rotation.z < -0.03 and character.right_leg.rotation.z > 0.03, "resting legs must have a slight outward stance")
	character.gait = PI * 0.5
	character.animate_pose(1.0, 1.0)
	assert(character.knees[0].rotation.x < 0.01 and character.knees[1].rotation.x > 0.65, "only the recovering knee folds")
	character.gait += PI
	character.animate_pose(1.0, 1.0)
	assert(character.knees[1].rotation.x < 0.01 and character.knees[0].rotation.x > 0.65, "recovery alternates between legs")
	character.animate_pose(1.0, 0.0)
	assert(absf(character.left_leg.rotation.x) < 0.01 and character.knees[0].rotation.x < 0.01, "stopping returns to a straight resting pose")
	character.animate_pose(1.0, 0.0, false)
	assert(character.knees[0].rotation.x > 0.49, "airborne pose remains supported by the resized rig")
	character.carrying = true
	character.animate_pose(1.0, 0.0)
	assert(character.left_arm.rotation.x < -0.94 and character.elbows[0].rotation.x < -0.59, "carrying still poses both arm bones")
	print("CHARACTER_TEST_PASS chunky low-poly mesh, taper, stance, alternating recovery knees and resting pose")
	quit()
