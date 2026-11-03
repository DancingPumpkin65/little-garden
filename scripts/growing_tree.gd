class_name GardenGrowingTree
extends Node3D
var tint := Color("e798bd")
var height := 7.8
var delay := 0.0
var age := 0.0
var progress := 0.0
var branches: Array[MeshInstance3D] = []
var starts: Array[Vector3] = []
var ends: Array[Vector3] = []
var crowns: Array[MeshInstance3D] = []
var crown_sizes: Array[Vector3] = []
var trunk_material: ShaderMaterial
var body: StaticBody3D
func _ready() -> void:
	body = StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = height*0.047
	shape.height = height*0.6
	collision.shape = shape
	collision.position.y = shape.height/2
	body.add_child(collision)
	add_child(body)
	body.collision_layer = 0
	trunk_material = ShaderMaterial.new()
	trunk_material.shader = Shader.new()
	trunk_material.shader.code = "shader_type spatial; uniform float grow=0.0; void vertex(){VERTEX.y*=grow;} void fragment(){ALBEDO=vec3(0.39,0.26,0.22);ROUGHNESS=1.0;SPECULAR=0.0;}"
	branch(Vector3.ZERO,Vector3(0.25,height*0.7,0),height*0.047)
	for i in range(7):
		var a := i*TAU/7
		var start := Vector3(0.14,height*(0.34+(i%3)*0.07),0)
		var tip := Vector3(cos(a)*height*0.31,height*(0.73+(i%3)*0.06),sin(a)*height*0.28)
		branch(start,tip,height*0.022)
		var crown := GardenBloom.lobe(self,tip,Vector3.ONE,tint.lightened((i%3)*0.06))
		crowns.append(crown)
		crown_sizes.append(Vector3(height*0.42,height*0.33,height*0.4))
		crown.hide()
func branch(start: Vector3, end: Vector3, radius: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.radial_segments = 7
	mesh.top_radius = radius*0.35
	mesh.bottom_radius = radius
	mesh.height = start.distance_to(end)
	# A bottom-pivoted branch grows along its own axis.
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	for i in range(vertices.size()): vertices[i].y += mesh.height/2
	arrays[Mesh.ARRAY_VERTEX] = vertices
	var geometry := ArrayMesh.new()
	geometry.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var node := Shapes.mesh(self,geometry,start,trunk_material)
	node.quaternion = Quaternion(Vector3.UP,(end-start).normalized())
	branches.append(node)
	starts.append(start)
	ends.append(end)
func _physics_process(delta: float) -> void:
	age += delta
	progress = clampf((age-delay)/9.0,0,1)
	var wood := smoothstep(0,0.7,progress)
	body.collision_layer = 1 if wood>0.15 else 0
	var collision := body.get_child(0) as CollisionShape3D
	(collision.shape as CylinderShape3D).height = maxf(0.01,height*0.6*wood)
	collision.position.y = height*0.3*wood
	trunk_material.set_shader_parameter("grow",wood)
	for i in range(branches.size()):
		branches[i].visible = progress>0.005
		branches[i].position = starts[i]*wood
	for i in range(crowns.size()):
		var bloom := smoothstep(0.37+(i%3)*0.045,1,progress)
		crowns[i].visible = bloom>0.001
		crowns[i].position = ends[i+1]*wood
		crowns[i].scale = crown_sizes[i]*maxf(0.001,bloom)
	if progress>=1: set_physics_process(false)
