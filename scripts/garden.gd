class_name GardenWorld
extends Node3D

const MAP_RADIUS := 19.5
const EXIT_Z := -19.4
const PASSAGE_LENGTH := 80.0
const PASSAGE_WIDTH := 5.0
const DOOR_WIDTH := 4.5
var bowl := Vector3(0, 0, -4.5)
var bloom := 0.0
var door := Node3D.new()
var door_body: StaticBody3D
var door_open := false
var ground_material: StandardMaterial3D
var passage: Node3D
var passage_revealed := false
var passage_material: ShaderMaterial

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
	for x in [-(DOOR_WIDTH / 2 + 0.15), DOOR_WIDTH / 2 + 0.15]: Shapes.box(self, Vector3(x, 2.1, EXIT_Z), Vector3(0.25, 4.2, 0.3), frame)
	Shapes.box(self, Vector3(0, 4.2, EXIT_Z), Vector3(DOOR_WIDTH + 0.55, 0.25, 0.3), frame)
	add_child(door)
	door.position = Vector3(-DOOR_WIDTH / 2, 0.02, EXIT_Z)
	Shapes.box(door, Vector3(DOOR_WIDTH / 2, 2.0, 0), Vector3(DOOR_WIDTH, 4.0, 0.18), wood)
	Shapes.sphere(door, Vector3(DOOR_WIDTH - 0.3, 1.8, 0.16), Vector3.ONE * 0.16, Shapes.material(Color("444444")))
	door_body = Shapes.collider(door, Vector3(DOOR_WIDTH / 2, 2.0, 0), Vector3(DOOR_WIDTH, 4.0, 0.18))

func open_exit() -> void:
	door_open = true
	door_body.collision_layer = 0
	door_body.collision_mask = 0

func close_exit() -> void:
	door_open = false
	door_body.collision_layer = 1
	door_body.collision_mask = 1

func _process(delta: float) -> void:
	door.rotation.y = lerp_angle(door.rotation.y, -PI * 0.52 if door_open else 0.0, 1 - exp(-delta * 3))

func reveal(amount: float) -> void:
	bloom = amount
	ground_material.albedo_color = Color.WHITE

func reveal_passage() -> void:
	if passage_revealed: return
	passage_revealed = true
	passage = Node3D.new()
	add_child(passage)
	passage_material = ShaderMaterial.new()
	passage_material.shader = Shader.new()
	passage_material.shader.code = "shader_type spatial; uniform vec3 walker=vec3(0.0); varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float light=1.0-smoothstep(16.0,38.0,length(world.xz-walker.xz));ALBEDO=vec3(light);ROUGHNESS=1.0;SPECULAR=0.0;}"
	var center_z := EXIT_Z - PASSAGE_LENGTH / 2
	Shapes.box(passage, Vector3(0, -0.07, center_z), Vector3(PASSAGE_WIDTH, 0.18, PASSAGE_LENGTH), passage_material)
	Shapes.collider(passage, Vector3(0, -0.48, center_z), Vector3(PASSAGE_WIDTH, 1, PASSAGE_LENGTH))

func retire() -> void:
	hide()
	for body: CollisionObject3D in find_children("*", "CollisionObject3D", true, false):
		body.collision_layer = 0
		body.collision_mask = 0
