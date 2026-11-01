class_name Shapes
extends RefCounted

static func material(color: Color, roughness: float = 0.85) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	return mat

static func mesh(parent: Node3D, shape: Mesh, at: Vector3, mat: Material, size: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = mat
	node.position = at
	node.scale = size
	parent.add_child(node)
	return node

static func sphere(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radial_segments = 24
	shape.rings = 12
	shape.radius = 0.5
	shape.height = 1.0
	return mesh(parent, shape, at, mat, size)

static func box(parent: Node3D, at: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	return mesh(parent, BoxMesh.new(), at, mat, size)

static func cylinder(parent: Node3D, at: Vector3, radius: float, height: float, mat: Material, top: float = -1.0) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = radius if top < 0 else top
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 24
	return mesh(parent, shape, at, mat)

static func collider(parent: Node3D, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.position = at
	body.add_child(collision)
	parent.add_child(body)
	return body

# Elliptical cross-sections form one connected surface instead of stacked balls.
static func profile(parent: Node3D, sections: Array[Vector3], mat: Material) -> MeshInstance3D:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 20
	for row in range(sections.size() - 1):
		var low := sections[row]
		var high := sections[row + 1]
		for i in range(segments):
			var a := i * TAU / segments
			var b := (i + 1) * TAU / segments
			var points := [Vector3(cos(a) * low.y, low.x, sin(a) * low.z), Vector3(cos(b) * low.y, low.x, sin(b) * low.z), Vector3(cos(b) * high.y, high.x, sin(b) * high.z), Vector3(cos(a) * high.y, high.x, sin(a) * high.z)]
			for index in [0, 1, 2, 0, 2, 3]:
				surface.set_smooth_group(0)
				surface.add_vertex(points[index])
	surface.index()
	surface.generate_normals()
	return mesh(parent, surface.commit(), Vector3.ZERO, mat)
