extends SceneTree

func _initialize() -> void:
	check.call_deferred()

func check() -> void:
	var character := GardenCharacter.new()
	root.add_child(character)
	for limb in [character.left_leg, character.left_arm]:
		var instance := limb.get_child(0) as MeshInstance3D
		var vertices: PackedVector3Array = instance.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var radii: Dictionary[float, Vector2] = {}
		for vertex in vertices:
			var height := snappedf(vertex.y, 0.001)
			var radius := Vector2(absf(vertex.x), absf(vertex.z))
			radii[height] = radii.get(height, Vector2.ZERO).max(radius)
		var heights := radii.keys()
		heights.sort()
		for i in range(1, heights.size()):
			assert(radii[heights[i]].x >= radii[heights[i - 1]].x - 0.001, "limb width must taper steadily from hip/shoulder to ankle/wrist")
			assert(radii[heights[i]].y >= radii[heights[i - 1]].y - 0.001, "limb depth must taper steadily")
	character.gait = PI * 0.5
	character.animate_pose(1.0, 1.0)
	assert(character.knees[0].rotation.x < 0.01 and character.knees[1].rotation.x > 0.65, "only the recovering knee folds")
	character.gait += PI
	character.animate_pose(1.0, 1.0)
	assert(character.knees[1].rotation.x < 0.01 and character.knees[0].rotation.x > 0.65, "recovery alternates between legs")
	character.animate_pose(1.0, 0.0)
	assert(absf(character.left_leg.rotation.x) < 0.01 and character.knees[0].rotation.x < 0.01, "stopping returns to a straight resting pose")
	print("CHARACTER_TEST_PASS mesh taper, alternating recovery knees and resting pose")
	quit()
