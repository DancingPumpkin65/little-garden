class_name GardenBloom
extends Node3D
const DURATION := 2.3
static var petal_mesh: Mesh
static var materials: Dictionary[String,ShaderMaterial] = {}
const SOIL_SHADER := preload("res://shaders/flower_soil.gdshader")
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
var parts: Array[MeshInstance3D] = []
var batches: Array[MultiMeshInstance3D] = []
var batched_parts: Array[MeshInstance3D] = []
var built := false
static func material(tint: Color, soil_height: float = 0.0) -> ShaderMaterial:
	var key := tint.to_html()+":"+str(soil_height)
	if not materials.has(key):
		var surface := ShaderMaterial.new()
		surface.shader = SOIL_SHADER
		surface.set_shader_parameter("tint",tint)
		surface.set_shader_parameter("soil_height",soil_height)
		materials[key] = surface
	return materials[key]
static func lobe(parent: Node3D, at: Vector3, size: Vector3, tint: Color) -> MeshInstance3D:
	if petal_mesh == null: petal_mesh = GardenVegetationAssets.mesh(&"Lobe")
	return Shapes.mesh(parent,petal_mesh,at,material(tint),size)
func _ready() -> void:
	if delay<=0: build_parts()

# Delayed beds construct when they start emerging, spreading the garden's setup cost.
func build_parts() -> void:
	if built: return
	built = true
	stem = MeshInstance3D.new()
	stem.material_override = material(Color("259452"))
	stem.mesh = GardenVegetationAssets.mesh(&"Stem")
	add_child(stem)
	add_child(bud)
	for i in range(4 if kind==3 else 2):
		var leaf := Node3D.new()
		add_child(leaf)
		Shapes.mesh(leaf,GardenVegetationAssets.mesh(&"Leaf"),Vector3(0.16,0,0),material(Color("2eb66e")),Vector3(0.48,0.6,0.6) if kind==3 else Vector3(0.32,0.45,0.4))
		leaf.rotation.y = i*PI
		leaves.append(leaf)
	if kind==4 or kind==5:
		build_spike()
	else:
		var count := 9 if kind==3 else 6 if kind==0 else 5
		for i in range(count):
			var hinge := Node3D.new()
			bud.add_child(hinge)
			hinge.rotation.y = i*TAU/count
			var size := Vector3(0.16,0.045,0.32) if kind==0 else Vector3(0.17,0.07,0.24)
			if kind==3: size = Vector3(0.15,0.065,0.34)
			lobe(hinge,Vector3(0,0,0.20 if kind==3 else 0.17 if kind==0 else 0.13),size,Color("f7cc48") if kind==3 else color)
			petals.append(hinge)
		lobe(bud,Vector3(0,0.025,0),Vector3(0.28,0.11,0.28) if kind==3 else Vector3(0.12,0.08,0.12),Color("765032") if kind==3 else Color("e8c56b"))
		if kind==3:
			bud.rotation.x = PI/2
			for i in range(12):
				var angle := i*2.399963
				var radius := sqrt(i/12.0)*0.11
				lobe(bud,Vector3(cos(angle)*radius,0.08,sin(angle)*radius),Vector3.ONE*0.028,Color("bc8b43"))
	for mesh: MeshInstance3D in find_children("*","MeshInstance3D",true,false):
		var tint: Color = (mesh.material_override as ShaderMaterial).get_shader_parameter("tint")
		mesh.material_override = material(tint,global_position.y)
		parts.append(mesh)
	pose(0)
func start() -> void:
	started = true
func open_now() -> void:
	build_parts()
	started = true
	age = DURATION+delay
	progress = 1
	pose(1)
	batch_open_parts()
	set_physics_process(false)
# Only the stem extends; leaves and petals unfold around fixed pivots.
func pose(amount: float) -> void:
	if amount<1 and not batches.is_empty():
		for batch in batches: batch.queue_free()
		batches.clear()
		for part in batched_parts: part.show()
		batched_parts.clear()
	var length := height*smoothstep(0,0.67,amount)
	bud.visible = amount>0.005
	var buried := (0.95 if kind>=4 else 0.40)*(1-smoothstep(0.12,0.52,amount))
	bud.position = Vector3(sin(1.4)*0.07,length-buried,0)
	stem.scale.y = maxf(0.001,bud.position.y)
	stem.visible = bud.position.y>0.005
	for i in range(leaves.size()):
		var unfolded := smoothstep(0.12+i*0.09,0.65+i*0.06,amount)
		leaves[i].visible = amount>0.005
		leaves[i].position = Vector3(0,lerpf(-0.3,height*(0.25+i*0.15),unfolded),0)
		leaves[i].rotation.z = lerpf(1.45,0.20,unfolded)
	for petal in petals:
		petal.rotation.x = lerpf(-PI/2,-0.08 if kind==0 else -0.65 if kind==1 else 0.4,smoothstep(0.52,1,amount))
func _physics_process(delta: float) -> void:
	if not started: return
	age += delta
	progress = clampf((age-delay)/DURATION,0,1)
	if progress>0:
		build_parts()
		pose(progress)
	if progress>=1:
		batch_open_parts()
		set_physics_process(false)

# Once growth finishes, identical petals/leaves share a draw call. Pivots stay available.
func batch_open_parts() -> void:
	if not batches.is_empty(): return
	var groups: Dictionary[String,Array] = {}
	for part in parts:
		if not part.visible: continue
		var key := str(part.mesh.get_instance_id())+":"+str(part.material_override.get_instance_id())
		if not groups.has(key): groups[key] = []
		groups[key].append(part)
	for group: Array in groups.values():
		if group.size()<2: continue
		var first: MeshInstance3D = group[0]
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		instances.mesh = first.mesh
		instances.instance_count = group.size()
		var batch := MultiMeshInstance3D.new()
		batch.multimesh = instances
		batch.material_override = first.material_override
		add_child(batch)
		var inverse := global_transform.affine_inverse()
		for i in range(group.size()):
			var part: MeshInstance3D = group[i]
			instances.set_instance_transform(i,inverse*part.global_transform)
			part.hide()
			batched_parts.append(part)
		batches.append(batch)

func build_spike() -> void:
	var tiers := 7 if kind==4 else 5
	for tier in range(tiers):
		var count := 5 if kind==4 else 3
		var radius := 0.14*(1-tier/float(tiers)*0.55)
		for i in range(count):
			var angle := i*TAU/count+tier*0.7
			var hinge := Node3D.new()
			hinge.position = Vector3(cos(angle)*radius,tier*0.085,sin(angle)*radius)
			hinge.rotation.y = angle
			bud.add_child(hinge)
			lobe(hinge,Vector3.ZERO,Vector3(0.23,0.055,0.14) if kind==4 else Vector3(0.075,0.15,0.075),Color("c6b5e8").lightened(tier*0.025) if kind==4 else Color("edcf60"))
			petals.append(hinge)
