class_name GardenWorld
extends Node3D

var tinted: Array[StandardMaterial3D] = []
var colors: Array[Color] = []
var flowers := Node3D.new()
var bloom := 0.0
var rng := RandomNumberGenerator.new()
var bowl := Vector3(0, 0, -4.5)

func paint(hex: String) -> StandardMaterial3D:
	var mat := Shapes.material(Color("eeeae4"))
	tinted.append(mat)
	colors.append(Color(hex))
	return mat

func _ready() -> void:
	rng.seed = 37
	var grass := paint("9bbc78")
	var edge := paint("d9ccb1")
	var stone := Shapes.material(Color("e8dfce"))
	var wood := paint("98715a")
	var foliage := [paint("759d70"), paint("89ae78"), paint("aec58d")]
	Shapes.cylinder(self, Vector3(0, -0.56, 0), 11.5, 1.05, edge)
	Shapes.cylinder(self, Vector3(0, -0.04, 0), 11.45, 0.12, grass)
	var floor_body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 11.45
	shape.height = 1.1
	col.shape = shape
	floor_body.position.y = -0.53
	floor_body.add_child(col)
	add_child(floor_body)
	# Raised stones mark the route without adding a HUD arrow.
	for i in range(8):
		var at := Vector3(sin(i * 0.6) * 0.4, 0.05, 4.0 - i * 1.05)
		var step := Shapes.cylinder(self, at, 0.43, 0.07, stone)
		step.scale.z = 0.7
		step.rotation.y = rng.randf_range(-0.6, 0.6)
	for i in range(13):
		var angle := i * TAU / 13
		var radius := rng.randf_range(8.0, 10.1)
		var tree := Node3D.new()
		tree.position = Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		add_child(tree)
		var height := rng.randf_range(2.4, 4.4)
		Shapes.collider(tree, Vector3(0, 0.9, 0), Vector3(0.35, 1.8, 0.35))
		Shapes.cylinder(tree, Vector3(0, height * 0.35, 0), 0.16, height * 0.7, wood, 0.12)
		for j in range(3):
			Shapes.sphere(tree, Vector3(sin(j * 2.4) * 0.35, height * 0.68 + j * 0.3, cos(j * 2.4) * 0.25), Vector3(1.7, 1.7, 1.6), foliage[(i + j) % 3])
	for i in range(25):
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(7, 10.5)
		Shapes.sphere(self, Vector3(cos(angle) * radius, 0.25, sin(angle) * radius), Vector3(1.2, 0.8, 1.1), foliage[i % 3])
	# An open receiving bowl catches the seed. Detection is in the game controller.
	Shapes.cylinder(self, bowl + Vector3(0, 0.25, 0), 1.05, 0.45, stone, 0.88)
	Shapes.cylinder(self, bowl + Vector3(0, 0.49, 0), 0.8, 0.04, Shapes.material(Color("8b857f")))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.79
	ring.outer_radius = 1.05
	Shapes.mesh(self, ring, bowl + Vector3(0, 0.52, 0), stone).scale.y = 0.65
	# A bench and book give the companion a home in the scene.
	Shapes.box(self, Vector3(3.6, 0.58, -3.5), Vector3(2.3, 0.15, 0.65), wood)
	Shapes.box(self, Vector3(3.6, 1.0, -3.8), Vector3(2.3, 0.65, 0.12), wood)
	for x in [2.8, 4.4]:
		Shapes.box(self, Vector3(x, 0.28, -3.5), Vector3(0.12, 0.55, 0.5), wood)
	Shapes.collider(self, Vector3(3.6, 0.45, -3.5), Vector3(2.3, 0.9, 0.7))
	add_child(flowers)
	flowers.visible = false
	var petals := [Shapes.material(Color("f6d98a")), Shapes.material(Color("eab8b0")), Shapes.material(Color("e8e4d1")), Shapes.material(Color("bbb1d9"))]
	for i in range(150):
		var at := Vector3(rng.randf_range(-10, 10), 0.08, rng.randf_range(-9, 9))
		if Vector2(at.x, at.z).length() > 10.5 or absf(at.x) < 1.2: continue
		flower(at, petals[i % 4], foliage[0], rng.randf_range(0.6, 1.25))
	var arch := Node3D.new()
	arch.position = Vector3(0, 0, -7)
	add_child(arch)
	for x in [-1.35, 1.35]:
		Shapes.cylinder(arch, Vector3(x, 1.4, 0), 0.1, 2.8, wood)
	for i in range(13):
		var angle := float(i) / 12 * PI
		Shapes.sphere(arch, Vector3(cos(angle) * 1.35, 2.75 + sin(angle) * 1.2, 0), Vector3(0.36, 0.36, 0.36), foliage[i % 3])

func flower(at: Vector3, mat: Material, stem: Material, size: float) -> void:
	var plant := Node3D.new()
	flowers.add_child(plant)
	plant.position = at
	plant.scale = Vector3.ONE * size
	Shapes.cylinder(plant, Vector3(0, 0.22, 0), 0.025, 0.44, stem)
	Shapes.sphere(plant, Vector3(0.11, 0.15, 0), Vector3(0.26, 0.08, 0.12), stem).rotation.z = 0.5
	for petal in range(5):
		var a := petal * TAU / 5
		Shapes.sphere(plant, Vector3(cos(a) * 0.12, 0.45, sin(a) * 0.12), Vector3(0.2, 0.09, 0.19), mat)
	Shapes.sphere(plant, Vector3(0, 0.48, 0), Vector3(0.12, 0.08, 0.12), Shapes.material(Color("dfb764")))

func reveal(amount: float) -> void:
	bloom = amount
	for i in range(tinted.size()):
		tinted[i].albedo_color = Color("eeeae4").lerp(colors[i], amount)
	flowers.visible = amount > 0.05
	flowers.scale = Vector3.ONE * maxf(0.01, amount)
