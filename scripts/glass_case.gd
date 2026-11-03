class_name GardenGlass
extends Node3D
signal impact(broken: bool)
var body: StaticBody3D
var hits := 0
var broken := false
var shell := Node3D.new()
var cracks := Node3D.new()
var shards: Array[MeshInstance3D] = []
var velocities: Array[Vector3] = []
var spins: Array[Vector3] = []
var shard_clock := 0.0
var shake := 0.0
var random := RandomNumberGenerator.new()
const RADIUS := 1.35
const BASE := 1.05
func _ready() -> void:
	random.seed = 181
	body = StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = BASE+3.65
	collision.shape = shape
	collision.position.y = shape.height/2
	body.add_child(collision)
	add_child(body)
	add_child(shell)
	shell.add_child(cracks)
	var glass := Shapes.material(Color(0.72, 0.8, 0.85, 0.13), 0.12)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings: Array[Vector2] = [Vector2(0,1.35),Vector2(2.3,1.35)]
	for i in range(1,11):
		var a := i*PI/20
		rings.append(Vector2(2.3+sin(a)*1.35,cos(a)*1.35))
	for row in range(rings.size()-1):
		for i in range(32):
			var a := i * TAU / 32
			var b := (i+1) * TAU / 32
			var low := rings[row]
			var high := rings[row+1]
			var points: Array[Vector3] = [Vector3(cos(a)*low.y, BASE+low.x, sin(a)*low.y), Vector3(cos(b)*low.y, BASE+low.x, sin(b)*low.y), Vector3(cos(b)*high.y, BASE+high.x, sin(b)*high.y), Vector3(cos(a)*high.y, BASE+high.x, sin(a)*high.y)]
			for index in [0,1,2,0,2,3]: surface.add_vertex(points[index])
	surface.generate_normals()
	surface.set_material(glass)
	Shapes.mesh(shell, surface.commit(), Vector3.ZERO, glass).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var edge := Shapes.material(Color("9ca4a9"))
	var rim := TorusMesh.new()
	rim.inner_radius = 1.32
	rim.outer_radius = 1.37
	Shapes.mesh(shell, rim, Vector3(0, BASE, 0), edge)
	for angle in [0.0, PI]:
		for row in range(rings.size()-1):
			var a := rings[row]
			var b := rings[row+1]
			stroke(shell, Vector3(cos(angle)*a.y,BASE+a.x,0),Vector3(cos(angle)*b.y,BASE+b.x,0),0.014,edge)
func stroke(parent: Node3D, a: Vector3, b: Vector3, width: float, material: Material) -> void:
	var piece := Shapes.cylinder(parent, (a+b)*0.5, width, a.distance_to(b), material)
	piece.quaternion = Quaternion(Vector3.UP, (b-a).normalized())
# Swept contact catches a fast thrown head and registers only once per flight.
func hit_head(from: Vector3, to: Vector3) -> bool:
	if broken: return false
	var a := from-global_position
	var b := to-global_position
	var segment := Vector2(b.x-a.x,b.z-a.z)
	var t := clampf(-Vector2(a.x,a.z).dot(segment)/maxf(segment.length_squared(),0.0001),0,1)
	var at := a.lerp(b,t)
	if Vector2(at.x,at.z).length() > RADIUS+0.34 or at.y < BASE-0.15 or at.y > BASE+3.65: return false
	hits += 1
	shake = 0.32
	if hits < 3: add_crack(hits)
	else: shatter()
	impact.emit(broken)
	return true
func add_crack(index: int) -> void:
	var dark := Shapes.material(Color("6b747b"))
	var points: Array[Vector3] = []
	for i in range(7):
		var x := (-0.45 if index == 1 else 0.45) + sin(i*2.7+index)*0.23
		points.append(Vector3(x,BASE+0.4+i*0.34,sqrt(RADIUS*RADIUS-x*x)+0.015))
	for i in range(points.size()-1):
		stroke(cracks,points[i],points[i+1],0.017,dark)
		if i % 2 == 1: stroke(cracks,points[i],points[i]+Vector3(0.25 if index==1 else -0.25,0.14,-0.02),0.012,dark)
func shatter() -> void:
	broken = true
	body.collision_layer = 0
	body.collision_mask = 0
	shell.hide()
	for i in range(30):
		var angle := i*TAU/30
		var height := random.randf_range(BASE+0.2,BASE+3.1)
		var material := Shapes.material(Color(0.74,0.83,0.9,0.55),0.15)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for point in [Vector3(-0.16,-0.2,0),Vector3(0.19,-0.13,0.03),Vector3(0.03,0.3,-0.02)]: surface.add_vertex(point)
		surface.generate_normals()
		var shard := Shapes.mesh(self,surface.commit(),Vector3(cos(angle)*RADIUS,height,sin(angle)*RADIUS),material)
		shards.append(shard)
		velocities.append(Vector3(cos(angle)*random.randf_range(1,3),random.randf_range(1,4),sin(angle)*random.randf_range(1,3)))
		spins.append(Vector3(random.randf_range(-6,6),random.randf_range(-6,6),random.randf_range(-6,6)))
func _physics_process(delta: float) -> void:
	if shake > 0:
		shake = maxf(0,shake-delta)
		shell.rotation.z = sin(shake*75)*shake*0.045
	if not broken: return
	shard_clock += delta
	for i in range(shards.size()):
		velocities[i].y -= 9.8*delta
		shards[i].position += velocities[i]*delta
		shards[i].rotation += spins[i]*delta
		if shards[i].position.y < 0.05:
			shards[i].position.y = 0.05
			velocities[i] *= Vector3(0.5,-0.25,0.5)
		var material := shards[i].material_override as StandardMaterial3D
		material.albedo_color.a = 0.55*(1-smoothstep(1.8,3.0,shard_clock))
	if shard_clock > 3:
		for shard in shards: shard.queue_free()
		shards.clear()
		velocities.clear()
		spins.clear()
