class_name GardenCompanionParts
extends RefCounted

const CENTERS := {&"head": Vector3(0, 2.145, 0.015), &"hand": Vector3(0.70, 1.075, 0.018)}
var missing := {&"head": true, &"hand": true, &"leg": true}
var instance: MeshInstance3D
var original: Mesh
var groups: Array[Array] = []
var actor: GardenCharacter
var legacy_nodes: Dictionary[StringName, Node3D] = {}

func _init(character: GardenCharacter) -> void:
	actor = character
	if actor.imported_skeleton == null:
		legacy_nodes[&"head"] = actor.head
		legacy_nodes[&"hand"] = actor.elbows[1].get_children()[0] as Node3D
		legacy_nodes[&"leg"] = actor.left_leg
		refresh()
		return
	instance = actor.model_root.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	original = instance.mesh
	for surface in range(original.get_surface_count()):
		var arrays := original.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var parts: Array[StringName] = []
		for triangle in range(indices.size() / 3):
			var part: StringName = &"body"
			for candidate: StringName in [&"head", &"hand", &"leg"]:
				var influence := 0.0
				for corner in range(3): influence += part_weight(arrays, indices[triangle * 3 + corner], candidate) / 3.0
				if influence > 0.48:
					part = candidate
					break
			parts.append(part)
		groups.append(parts)
	refresh()

func part_weight(arrays: Array, vertex: int, part: StringName) -> float:
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var influence_count := weights.size() / (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	var total := 0.0
	for i in range(influence_count):
		var bind := bones[vertex * influence_count + i]
		var bone := instance.skin.get_bind_bone(bind)
		var bind_name := instance.skin.get_bind_name(bind)
		var name: StringName = bind_name if not bind_name.is_empty() else actor.imported_skeleton.get_bone_name(bone)
		if (part == &"head" and name == &"head") or (part == &"hand" and name == &"hand_R") or (part == &"leg" and name in [&"thigh_L", &"calf_L", &"foot_L"]):
			total += weights[vertex * influence_count + i]
	return total

func refresh() -> void:
	if original == null:
		for part in legacy_nodes: legacy_nodes[part].visible = not missing[part]
		return
	var mesh := ArrayMesh.new()
	for surface in range(original.get_surface_count()):
		var arrays := original.surface_get_arrays(surface)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var kept := PackedInt32Array()
		for triangle in range(groups[surface].size()):
			if missing.get(groups[surface][triangle], false): continue
			for corner in range(3): kept.append(indices[triangle * 3 + corner])
		if kept.is_empty(): continue
		arrays[Mesh.ARRAY_INDEX] = kept
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		mesh.surface_set_material(mesh.get_surface_count() - 1, original.surface_get_material(surface))
	instance.mesh = mesh

func restore(part: StringName) -> void:
	missing[part] = false
	refresh()

# Recoverable meshes use the exact imported head/hand, with their original materials.
func loose_mesh(part: StringName) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	if original == null:
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var parent := legacy_nodes[part]
		var nodes := parent.find_children("*", "MeshInstance3D", true, false)
		if parent is MeshInstance3D: nodes.append(parent)
		for node: MeshInstance3D in nodes:
			var transform := actor.visual.global_transform.affine_inverse() * node.global_transform
			transform.origin -= CENTERS[part]
			for surface in range(node.mesh.get_surface_count()): builder.append_from(node.mesh, surface, transform)
		builder.set_material(Shapes.material(Color.WHITE))
		builder.commit(mesh)
		return mesh
	for surface in range(original.get_surface_count()):
		var arrays := original.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var builder := SurfaceTool.new()
		builder.begin(Mesh.PRIMITIVE_TRIANGLES)
		var count := 0
		for triangle in range(groups[surface].size()):
			if groups[surface][triangle] != part: continue
			for corner in range(3):
				var vertex := indices[triangle * 3 + corner]
				builder.set_normal(normals[vertex])
				builder.add_vertex(vertices[vertex] - CENTERS[part])
				count += 1
		if count > 0:
			builder.set_material(original.surface_get_material(surface))
			builder.commit(mesh)
	return mesh

func anchor(part: StringName) -> Vector3:
	var bone: StringName = &"head" if part == &"head" else &"hand_R"
	if actor.imported_skeleton == null: return legacy_nodes[part].global_position
	actor.imported_skeleton.force_update_all_bone_transforms()
	var index := actor.bone_ids[bone]
	var pose := actor.imported_skeleton.get_bone_global_pose(index)
	var rest := actor.imported_skeleton.get_bone_global_rest(index)
	return actor.imported_skeleton.global_transform * (pose * (rest.affine_inverse() * CENTERS[part]))
