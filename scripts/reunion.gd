class_name GardenReunion
extends Node3D
signal dialogue_requested(lines: Array[String])
signal glass_impact(broken: bool)
enum Phase { WAIT, INTRO, MERGE, READY, LEAD, DOOR, PASSAGE, CAKE, BIRTHDAY }
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
var flowers: Array[GardenBloom] = []
var flower_growth: Array[float] = []
var near_line := false
var introduced := false
var destination: Node3D
var cake_floor: MeshInstance3D
var cake_floor_body: StaticBody3D
var cake_visual: Node3D
var plinth_visual: Node3D
var birthday: GardenBirthday
var birthday_clock := 0.0
var birthday_dialogue_started := false
var speech_from_head := false
var missed_shots := 0
enum HeadReunion { WAIT, APPROACH, LIFT, DONE }
var head_reunion := HeadReunion.WAIT
var head_lift_clock := 0.0
var ambient_enabled := false
@export var garden_comment_interval := Vector2(16.0,26.0)
var garden_comment_wait := 18.0
var last_garden_line := ""
const GARDEN_COMMENTS: Array[String] = [
	"Chufi! Fin kandouz kaytla3 lward",
	"Salma, had nhar dyalk. Khodi ra7tek"
]
const HIT_LINES: Array[String] = ["Aaaay, kunt 3arfek bghiti darbini mn ch7al hadi...", "Salmaaaaa ghatharssi rassi huwa lwal...", "WEEEEEEEEEEEE!!!"]
const BIRTHDAY_LINES: Array[String] = [
	"Happy birthday!!!",
	"Raki kbarti oweliti wa7ed l2inssana wa3ra •ᴗ•",
	"Kima kabrat had jerda, tantiya kberti o ba9i ghatkabri...",
	"Knatmana lik kul khir, odkhel 3lik sna jdida bachma tmaniti inchallah! ♡",
	"Tmachay fjarda tchufiha kidayra :3"
]
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
		flower_growth.append(0.0)

func make_flower(at: Vector3) -> GardenBloom:
	var flower := GardenBloom.new()
	flower.position = at
	flower.color = Color("eeeeee")
	root.add_child(flower)
	return flower

func head_missed() -> void:
	if phase != Phase.CAKE: return
	missed_shots += 1
	var lines: Array[String] = ["Darbi zaj machi lhwa" if missed_shots==1 else "Wa9ila ma3arfach tchayeri..."]
	dialogue_requested.emit(lines)

func on_glass_impact(broken: bool) -> void:
	glass_impact.emit(broken)
	var lines: Array[String] = [HIT_LINES[glass.hits-1]]
	dialogue_requested.emit(lines)
	if broken:
		phase = Phase.BIRTHDAY
		birthday_clock = 0
		girl.put_on_birthday_outfit()
		guy.put_on_birthday_outfit()
		guy.garden_mode = false
		guy.directed_move = false
		guy.follow_target = null
		guy.waiting_for_arm = true
		birthday = GardenBirthday.new()
		destination.add_child(birthday)
		birthday.setup(Vector3(0,0,CAKE_Z),girl,cake_floor,cake_floor_body,cake_visual,plinth_visual)
		birthday.companion = guy
		head.ground_bounds = Rect2(Vector2(-55,CAKE_Z-48),Vector2(110,96))

func dialogue_finished() -> void:
	if not active: return
	if phase==Phase.BIRTHDAY and birthday_dialogue_started: ambient_enabled = true
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
	cake_floor_body = Shapes.collider(destination,Vector3(0,-0.48,NEXT_ENTRY-24),Vector3(70,1,48))
	build_cake()
	glass = GardenGlass.new()
	destination.add_child(glass)
	glass.position.z = CAKE_Z
	glass.impact.connect(on_glass_impact)
	head = GardenRecoveryPart.new()
	destination.add_child(head)
	head.setup(&"head",parts.loose_mesh(&"head"),parts,girl)
	head.hit_target = glass
	head.missed.connect(head_missed)
	head.returned.connect(head_restored)
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
		flower_growth.append(0.0)

func build_cake() -> void:
	var white := Shapes.material(Color("ededed"))
	plinth_visual = Node3D.new()
	destination.add_child(plinth_visual)
	for i in range(3):
		Shapes.cylinder(plinth_visual,Vector3(0,0.16+i*0.32,CAKE_Z),2.15-i*0.3,0.32,white)
	cake_visual = Node3D.new()
	destination.add_child(cake_visual)
	cake_visual.position.z = CAKE_Z
	var pink := Shapes.material(Color("d6a2bf"))
	Shapes.cylinder(cake_visual,Vector3(0,1.6,0),0.6,0.45,pink)
	Shapes.cylinder(cake_visual,Vector3(0,1.86,0),0.61,0.09,white)
	for i in range(8):
		var a := i*TAU/8
		Shapes.sphere(cake_visual,Vector3(cos(a)*0.54,1.79,sin(a)*0.54),Vector3(0.17,0.21,0.17),white)
	var decoration := make_flower(Vector3(0,1.91,CAKE_Z))
	decoration.open_now()
	decoration.reparent(cake_visual)

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
			flowers[i].start()
			flower_growth[i] = flowers[i].progress
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
			var lines: Array[String] = ["Khalini n7el lik lbab"]
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
			speech_from_head = true
			var lines: Array[String] = ["Salaaaaam Salma, finally kanchufek!", "Happy birthdaaaaay!", "Khasski tharssi zaj bach takhdi lcadeau dyalk...", "Ach ban lik thazi rass dyali otharssi bih zaj..."]
			dialogue_requested.emit(lines)

	elif phase == Phase.BIRTHDAY:
		birthday_clock += delta
		update_head_reunion(delta)
		update_garden_comments(delta)
		if birthday_clock>3.5 and not birthday_dialogue_started:
			birthday_dialogue_started = true
			dialogue_requested.emit(BIRTHDAY_LINES)

func update_head_reunion(delta: float) -> void:
	if head_reunion==HeadReunion.WAIT and birthday_clock>2 and head.state==GardenRecoveryPart.State.AVAILABLE:
		head.state = GardenRecoveryPart.State.PICKING
		guy.directed_move = true
		guy.waiting_for_arm = false
		guy.move_target = Vector3(head.global_position.x,.02,head.global_position.z+1.0)
		head_reunion = HeadReunion.APPROACH
	elif head_reunion==HeadReunion.APPROACH and guy.position.distance_to(guy.move_target)<.5:
		guy.waiting_for_arm = true
		guy.action = "pickup"
		head_lift_clock = 0
		head_reunion = HeadReunion.LIFT
	elif head_reunion==HeadReunion.LIFT:
		head_lift_clock += delta
		guy.action_phase = minf(1,head_lift_clock/.8)
		if head_lift_clock>.45 and head.state==GardenRecoveryPart.State.PICKING: head.put_back()

func head_restored(kind: StringName) -> void:
	if kind!=&"head": return
	head_reunion = HeadReunion.DONE
	speech_from_head = false
	guy.action = ""
	guy.celebrate_in_garden(girl)
	guy.garden_roaming = true
	guy.garden_bounds = Rect2(Vector2(-43,CAKE_Z-36),Vector2(86,72))
	guy.garden_camera = get_viewport().get_camera_3d()

func update_garden_comments(delta: float) -> void:
	if not ambient_enabled or head_reunion!=HeadReunion.DONE or guy.dance_remaining>0: return
	garden_comment_wait -= delta
	if garden_comment_wait>0 or not guy.garden_point_visible(guy.global_position) or guy.position.distance_to(girl.position)>9: return
	var line := ""
	if guy.velocity.length()<.35:
		for flower in birthday.flowers+birthday.trail:
			if flower.progress>.7 and flower.global_position.distance_to(guy.global_position)<2.3:
				line = "Had lwarda zwina b7al Salma! :3"
				guy.garden_interest_position = flower.global_position
				break
	if line.is_empty() or line==last_garden_line:
		var choices: Array[String] = []
		for comment in GARDEN_COMMENTS:
			if comment!=last_garden_line: choices.append(comment)
		line = choices[guy.garden_random.randi_range(0,choices.size()-1)]
		guy.garden_interest_position = girl.global_position
	last_garden_line = line
	guy.garden_pause_remaining = clampf(line.length()*.11+1.5,4,7)
	garden_comment_wait = guy.garden_random.randf_range(garden_comment_interval.x,garden_comment_interval.y)
	var lines: Array[String] = [line]
	dialogue_requested.emit(lines)
