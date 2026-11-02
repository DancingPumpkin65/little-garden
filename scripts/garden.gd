class_name GardenWorld
extends Node3D

const EXIT_Z := -17.0
const MAP_RADIUS := 19.5
var bowl := Vector3(0, 0, -4.5)
var bloom := 0.0
var door := Node3D.new()
var door_body: StaticBody3D
var door_open := false
var ground_material: StandardMaterial3D
var passage: Node3D
var passage_revealed := false

func _ready() -> void:
	ground_material = Shapes.material(Color.WHITE)
	Shapes.cylinder(self, Vector3(0, -0.56, 0), MAP_RADIUS, 1.05, Shapes.material(Color("b5b5b5")))
	Shapes.cylinder(self, Vector3(0, -0.04, 0), MAP_RADIUS - 0.05, 0.12, ground_material)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = MAP_RADIUS - 0.05
	shape.height = 1.1
	collision.shape = shape
	floor_body.position.y = -0.53
	floor_body.add_child(collision)
	add_child(floor_body)
	var stone := Shapes.material(Color.WHITE)
	Shapes.cylinder(self, bowl + Vector3(0, 0.028, 0), 0.94, 0.012, Shapes.material(Color("333333")))
	var ring := TorusMesh.new()
	ring.inner_radius = 0.86
	ring.outer_radius = 1.08
	Shapes.mesh(self, ring, bowl + Vector3(0, 0.04, 0), stone).scale.y = 0.12
	build_exit()

func build_exit() -> void:
	var wood := Shapes.material(Color.WHITE)
	var frame := Shapes.material(Color("222222"))
	for x in [-1.65, 1.65]: Shapes.box(self, Vector3(x, 2.1, EXIT_Z), Vector3(0.25, 4.2, 0.3), frame)
	Shapes.box(self, Vector3(0, 4.2, EXIT_Z), Vector3(3.55, 0.25, 0.3), frame)
	add_child(door)
	door.position = Vector3(-1.5, 0.02, EXIT_Z)
	Shapes.box(door, Vector3(1.5, 2.0, 0), Vector3(3.0, 4.0, 0.18), wood)
	Shapes.sphere(door, Vector3(2.7, 1.8, 0.16), Vector3.ONE * 0.16, Shapes.material(Color("444444")))
	door_body = Shapes.collider(door, Vector3(1.5, 2.0, 0), Vector3(3.0, 4.0, 0.18))

func open_exit() -> void:
	door_open = true
	door_body.collision_layer = 0
	door_body.collision_mask = 0

func _process(delta: float) -> void:
	if door_open: door.rotation.y = lerp_angle(door.rotation.y, -PI * 0.52, 1 - exp(-delta * 3))

func reveal(amount: float) -> void:
	bloom = amount
	ground_material.albedo_color = Color.WHITE

func reveal_passage() -> void:
	if passage_revealed: return
	passage_revealed = true
	passage = Node3D.new()
	add_child(passage)
	var material := ShaderMaterial.new()
	material.shader = Shader.new()
	material.shader.code = "shader_type spatial; render_mode unshaded; varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float light=1.0-smoothstep(19.0,32.0,-world.z);ALBEDO=vec3(light);}"
	Shapes.box(passage, Vector3(0, -0.07, EXIT_Z - 8), Vector3(2.5, 0.18, 16), material)
	Shapes.collider(passage, Vector3(0, -0.48, EXIT_Z - 8), Vector3(2.5, 1, 16))
