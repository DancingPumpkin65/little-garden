class_name GardenBloom
extends Node3D
const DURATION := 2.3
static var petal_mesh: SphereMesh
static var materials: Dictionary[Color,StandardMaterial3D] = {}
var color := Color("f4c5d8")
var kind := 0
var height := 0.65
var delay := 0.0
var age := 0.0
var started := false
var progress := 0.0
var stem: MeshInstance3D
var bud := Node3D.new()
var leaves: Array[Node3D] = []
var petals: Array[Node3D] = []
static func material(tint: Color) -> StandardMaterial3D:
	if not materials.has(tint): materials[tint] = Shapes.material(tint)
	return materials[tint]
static func lobe(parent: Node3D, at: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
	if petal_mesh == null:
		petal_mesh = SphereMesh.new()
		petal_mesh.radial_segments = 8
		petal_mesh.rings = 3
		petal_mesh.radius = 0.5
		petal_mesh.height = 1
	return Shapes.mesh(parent,petal_mesh,at,material(tint),size)
func _ready() -> void:
	stem = MeshInstance3D.new()
	stem.material_override = material(Color("43835b"))
	add_child(stem)
	add_child(bud)
	for i in range(2):
		var leaf := Node3D.new()
		add_child(leaf)
		lobe(leaf,Vector3(0.1,0,0),Vector3(0.24,0.035,0.1),Color("519365"))
		leaf.rotation.y = i*PI
		leaves.append(leaf)
	var count := 7 if kind==0 else 5
	for i in range(count):
		var hinge := Node3D.new()
		bud.add_child(hinge)
		hinge.rotation.y = i*TAU/count
		lobe(hinge,Vector3(0,0,0.13),Vector3(0.13,0.045,0.28) if kind==0 else Vector3(0.17,0.07,0.24),color)
		petals.append(hinge)
	lobe(bud,Vector3.ZERO,Vector3(0.12,0.08,0.12),Color("e8c56b"))
	pose(0)
func start() -> void:
	started = true
func open_now() -> void:
	started = true
	age = DURATION+delay
	progress = 1
	pose(1)
	set_physics_process(false)
# Only the stem extends; leaves and petals unfold around fixed pivots.
func pose(amount: float) -> void:
	var length := height*smoothstep(0,0.67,amount)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(4):
		for i in range(6):
			var points: Array[Vector3] = []
			for ring: int in [row,row+1]:
				var t := ring/4.0
				for side: int in [i,i+1]:
					var a := side*TAU/6
					points.append(Vector3(sin(t*1.4)*0.07+cos(a)*0.018,length*t,sin(a)*0.018))
			for index in [0,1,3,0,3,2]: surface.add_vertex(points[index])
	surface.generate_normals()
	stem.mesh = surface.commit()
	stem.visible = amount>0.005
	bud.visible = amount>0.25
	bud.position = Vector3(sin(1.4)*0.07,length,0)
	for i in range(leaves.size()):
		leaves[i].visible = amount>0.2
		leaves[i].position = Vector3(0,length*(0.35+i*0.2),0)
		leaves[i].rotation.z = lerpf(1.45,0.25,smoothstep(0.2,0.75,amount))
	for petal in petals:
		petal.rotation.x = lerpf(-PI/2,-0.08 if kind==0 else -0.65 if kind==1 else 0.4,smoothstep(0.52,1,amount))
func _physics_process(delta: float) -> void:
	if not started: return
	age += delta
	progress = clampf((age-delay)/DURATION,0,1)
	if progress>0: pose(progress)
	if progress>=1: set_physics_process(false)
