class_name GardenVegetationAssets
extends RefCounted
const LIBRARY := preload("res://assets/vegetation/rounded_library.glb")
static var meshes: Dictionary[StringName,Mesh] = {}
static func mesh(label: StringName) -> Mesh:
 if meshes.is_empty():
  var source := LIBRARY.instantiate()
  for node: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false): meshes[node.name] = node.mesh
  source.free()
 assert(meshes.has(label),"missing Blender vegetation module: "+label)
 return meshes[label]
