class_name GardenStoryDoor
extends Node3D
var hinge := Node3D.new()
var body: StaticBody3D
var opened := false
func _ready() -> void:
	var white := Shapes.material(Color("dedede"))
	var inset := Shapes.material(Color("969696"))
	for x in [-1.7, 1.7]: Shapes.box(self, Vector3(x, 2.5, 0), Vector3(0.2, 5, 0.3), white)
	Shapes.box(self, Vector3(0, 5, 0), Vector3(3.6, 0.2, 0.3), white)
	add_child(hinge)
	hinge.position.x = -1.6
	Shapes.box(hinge, Vector3(1.6, 2.5, 0), Vector3(3.2, 5, 0.16), white)
	for x in [0.83, 2.37]:
		for y in [1.3, 3.7]:
			Shapes.box(hinge, Vector3(x, y, 0.095), Vector3(1.25, 2, 0.035), inset)
	Shapes.sphere(hinge, Vector3(2.9, 2.5, 0.22), Vector3.ONE * 0.18, white)
	body = Shapes.collider(hinge, Vector3(1.6, 2.5, 0), Vector3(3.2, 5, 0.18))
func set_open(value: bool) -> void:
	opened = value
	body.collision_layer = 0 if value else 1
func _process(delta: float) -> void:
	hinge.rotation.y = lerp_angle(hinge.rotation.y, -PI * 0.53 if opened else 0.0, 1 - exp(-delta * 3))
