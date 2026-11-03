class_name GardenReunion
extends Node3D
signal dialogue_requested(lines: Array[String])
signal glass_impact(broken: bool)
enum Phase { WAIT, INTRO, MERGE, READY, LEAD, DOOR, PASSAGE, CAKE }
const DOOR_Z := -52.0
const NEXT_ENTRY := DOOR_Z - 80.0
const CAKE_Z := NEXT_ENTRY - 16.0
var active := false
var phase := Phase.WAIT
var girl: GardenCharacter
var guy: GardenCharacter
var parts: GardenCompanionParts
var world_root: Node3D
var leg: MeshInstance3D
var clock := 0.0
var merge_start := Vector3.ZERO
var door: GardenStoryDoor
var passage: Node3D
var passage_material: ShaderMaterial
var glass: GardenGlass
var head: GardenRecoveryPart
var flowers: Array[Node3D] = []
var flower_scales: Array[float] = []
var near_line := false
var introduced := false
var destination: Node3D
var cake_floor: MeshInstance3D
var root: Node3D
var safe_position := Vector3(0,0.04,3)
func setup(player: GardenCharacter, companion: GardenCharacter, body_parts: GardenCompanionParts, world: Node3D) -> void:
	girl = player
	guy = companion
	parts = body_parts
	world_root = world
func activate(loose_leg: MeshInstance3D) -> void:
	active = true
	leg = loose_leg
	root = Node3D.new()
	world_root.add_child(root)
	guy.waiting_for_arm = true
	door = GardenStoryDoor.new()
	root.add_child(door)
	door.position.z = DOOR_Z
	for i in range(7):
		var flower := make_flower(Vector3((-1 if i%2==0 else 1)*2.2,0,-8-i*5.6))
		flowers.append(flower)
		flower_scales.append(0.0)
		flower.scale = Vector3.ONE*0.001
func make_flower(at: Vector3) -> Node3D:
	var flower := Node3D.new()
	root.add_child(flower)
	flower.position = at
	var stem := Shapes.material(Color("6a8a72"))
	Shapes.cylinder(flower,Vector3(0,0.2,0),0.016,0.4,stem)
	Shapes.sphere(flower,Vector3(0.07,0.16,0),Vector3(0.17,0.045,0.07),stem).rotation.z = 0.5
	var petal := Shapes.material(Color("eeeeee"))
	for i in range(5):
		var a := i*TAU/5
		Shapes.sphere(flower,Vector3(cos(a)*0.1,0.41,sin(a)*0.1),Vector3(0.15,0.035,0.11),petal)
	Shapes.sphere(flower,Vector3(0,0.43,0),Vector3(0.08,0.035,0.08),Shapes.material(Color("d7c888")))
	return flower
func dialogue_finished() -> void:
	if not active: return
	if phase == Phase.INTRO:
		phase = Phase.MERGE
		clock = 0
		merge_start = leg.global_position
	elif phase == Phase.READY:
		phase = Phase.LEAD
		guy.waiting_for_arm = false
		guy.directed_move = true
		guy.move_target = Vector3(1.3,0.02,DOOR_Z+4)
func build_destination() -> void:
	destination = Node3D.new()
	root.add_child(destination)
	passage = Node3D.new()
	root.add_child(passage)
	passage_material = ShaderMaterial.new()
	passage_material.shader = Shader.new()
	passage_material.shader.code = "shader_type spatial; uniform vec3 walker=vec3(0.0); varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){ALBEDO=vec3(1.0-smoothstep(16.0,38.0,length(world.xz-walker.xz)));ROUGHNESS=1.0;SPECULAR=0.0;}"
	Shapes.box(passage,Vector3(0,-0.07,DOOR_Z-40),Vector3(5,0.18,80),passage_material)
	Shapes.collider(passage,Vector3(0,-0.48,DOOR_Z-40),Vector3(5,1,80))
	cake_floor = Shapes.box(destination,Vector3(0,-0.48,NEXT_ENTRY-24),Vector3(70,1,48),passage_material)
	Shapes.collider(destination,Vector3(0,-0.48,NEXT_ENTRY-24),Vector3(70,1,48))
	build_cake()
	glass = GardenGlass.new()
	destination.add_child(glass)
	glass.position.z = CAKE_Z
	glass.impact.connect(func(broken: bool): glass_impact.emit(broken))
	head = GardenRecoveryPart.new()
	destination.add_child(head)
	head.setup(&"head",parts.loose_mesh(&"head"),parts,girl)
	head.hit_target = glass
	head.ground_center = Vector3(0,0,NEXT_ENTRY-24)
	head.ground_radius = 42
	head.ground_bounds = Rect2(Vector2(-35,NEXT_ENTRY-48),Vector2(70,48))
	head.home = Vector3(-3,0.7,CAKE_Z+3)
	head.return_home = head.home
	head.position = head.home
	head.state = GardenRecoveryPart.State.AVAILABLE
	head.show()
	destination.hide()
	for i in range(2):
		var flower := make_flower(Vector3(-1.5 if i==0 else 1.5,0,DOOR_Z-24-i*28))
		flowers.append(flower)
		flower_scales.append(0.0)
		flower.scale = Vector3.ONE*0.001
func build_cake() -> void:
	var white := Shapes.material(Color("ededed"))
	for i in range(3):
		Shapes.cylinder(destination,Vector3(0,0.16+i*0.32,CAKE_Z),2.15-i*0.3,0.32,white)
	var pink := Shapes.material(Color("d6a2bf"))
	Shapes.cylinder(destination,Vector3(0,1.6,CAKE_Z),0.6,0.45,pink)
	Shapes.cylinder(destination,Vector3(0,1.86,CAKE_Z),0.61,0.09,white)
	for i in range(8):
		var a := i*TAU/8
		Shapes.sphere(destination,Vector3(cos(a)*0.54,1.79,CAKE_Z+sin(a)*0.54),Vector3(0.17,0.21,0.17),white)
	var decoration := make_flower(Vector3(0,1.91,CAKE_Z))
	decoration.scale = Vector3.ONE*0.7
	decoration.reparent(destination)
func lead_to(target: Vector3) -> void:
	guy.directed_move = true
	guy.move_target = target
	guy.waiting_for_arm = guy.global_position.distance_to(girl.global_position) > 9
func _physics_process(delta: float) -> void:
	if not active: return
	clock += delta
	if girl.is_on_floor(): safe_position = girl.position
	for i in range(flowers.size()):
		if phase >= Phase.LEAD and guy.position.z < flowers[i].position.z+4:
			flower_scales[i] = minf(1,flower_scales[i]+delta*1.5)
			flowers[i].scale = Vector3.ONE*maxf(0.001,smoothstep(0,1,flower_scales[i]))
	if passage_material != null: passage_material.set_shader_parameter("walker",girl.global_position)
	if destination != null and girl.position.z < NEXT_ENTRY+22: destination.show()
	if phase == Phase.WAIT:
		leg.position = Vector3(-1.7,0.66+absf(sin(clock*3))*0.22,-3.2)
		if girl.is_on_floor() and girl.position.distance_to(guy.position)<6:
			phase = Phase.INTRO
			var lines: Array[String] = ["Wow n9azti 3endi :')", "Chufi chkoun l9it mna9ez m3aya... Rajli"]
			dialogue_requested.emit(lines)
	elif phase == Phase.INTRO:
		leg.position.y = 0.66+absf(sin(clock*3))*0.22
	elif phase == Phase.MERGE:
		var progress := minf(1,clock/1.2)
		leg.global_position = merge_start.lerp(parts.anchor(&"leg"),smoothstep(0,1,progress))+Vector3.UP*sin(progress*PI)*0.4
		leg.rotation.y = lerp_angle(leg.rotation.y,guy.visual.global_rotation.y,delta*8)
		if progress >= 1:
			leg.hide()
			parts.restore(&"leg")
			guy.two_legs = true
			phase = Phase.READY
			var lines: Array[String] = ["Db yala l9aw rass dyali :?", "Tab3ini n9albo 3lih"]
			dialogue_requested.emit(lines)
	elif phase == Phase.LEAD:
		lead_to(Vector3(1.3,0.02,DOOR_Z+4))
		if guy.position.z < -30 and not near_line:
			near_line = true
			var lines: Array[String] = ["9rabna nwasslo, mab9a walo"]
			dialogue_requested.emit(lines)
		if guy.position.distance_to(Vector3(1.3,0.02,DOOR_Z+4))<0.7 and girl.position.z < DOOR_Z+9:
			phase = Phase.DOOR
			clock = 0
			guy.move_target = Vector3(1.1,0.02,DOOR_Z+1.2)
			var lines: Array[String] = ["Khalini n7al lik lbab ;)"]
			dialogue_requested.emit(lines)
	elif phase == Phase.DOOR:
		guy.waiting_for_arm = false
		if guy.position.distance_to(guy.move_target)>0.5:
			clock = 0
		else:
			guy.door_gesture = smoothstep(0,0.7,clock)
			if clock > 0.8 and not door.opened:
				door.set_open(true)
				build_destination()
			if clock > 2:
				guy.door_gesture = 0
				phase = Phase.PASSAGE
	elif phase == Phase.PASSAGE:
		lead_to(Vector3(1.1,0.02,NEXT_ENTRY-8))
		if girl.position.z < NEXT_ENTRY-3 and guy.position.z < NEXT_ENTRY-3:
			phase = Phase.CAKE
			guy.directed_move = true
			guy.move_target = Vector3(2.7,0.02,CAKE_Z+2.5)
	elif phase == Phase.CAKE:
		guy.waiting_for_arm = false
		if not introduced and girl.position.distance_to(Vector3(0,0,CAKE_Z))<10:
			introduced = true
			var lines: Array[String] = ["Khasski tharssi zaj bach takhdi lcadeau dyalk..."]
			dialogue_requested.emit(lines)
