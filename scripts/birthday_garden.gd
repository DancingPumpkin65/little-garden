class_name GardenBirthday
extends Node3D
var trail: Array[GardenBloom] = []
var last_step := Vector3.INF
var ground_plants: MultiMeshInstance3D
var plant_material: ShaderMaterial
var perimeter: Node3D
var sky_material: ShaderMaterial
var age := 0.0
var hero: GardenGrowingTree
var trees: Array[GardenGrowingTree] = []
var flowers: Array[GardenBloom] = []
var floor_material: ShaderMaterial
var walker: GardenCharacter
var cake: Node3D
var plinth: Node3D
var center := Vector3.ZERO
var petals: MultiMeshInstance3D
var morph_materials: Array[BaseMaterial3D] = []
var random := RandomNumberGenerator.new()
func setup(at: Vector3, player: GardenCharacter, ground: MeshInstance3D, ground_body: StaticBody3D, cake_visual: Node3D, plinth_visual: Node3D) -> void:
	center = at
	walker = player
	cake = cake_visual
	plinth = plinth_visual
	random.seed = 713
	ground.position = Vector3(0,-0.48,center.z)
	ground.scale = Vector3(110,1,96)
	ground_body.position = ground.position
	(ground_body.get_child(0).shape as BoxShape3D).size = Vector3(110,1,96)
	floor_material = ShaderMaterial.new()
	floor_material.shader = Shader.new()
	floor_material.shader.code = "shader_type spatial; uniform float bloom=0.0; uniform vec3 walker=vec3(0.0); varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float light=1.0-0.55*smoothstep(35.0,85.0,length(world.xz-walker.xz));vec3 grass=mix(vec3(1.0),vec3(0.24,0.65,0.33),bloom);ALBEDO=grass*light;ROUGHNESS=1.0;SPECULAR=0.0;}"
	ground.material_override = floor_material
	for parent in [cake,plinth]:
		for node: MeshInstance3D in parent.find_children("*","MeshInstance3D",true,false):
			var material := node.material_override as BaseMaterial3D
			if material!=null:
				var local := material.duplicate() as BaseMaterial3D
				local.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				node.material_override = local
				morph_materials.append(local)
	hero = add_tree(center,18.0,Color("e795c2"),0)
	var palette: Array[Color] = [Color("3b7944"),Color("245c43"),Color("76a94f"),Color("b98fc9"),Color("4d9466")]
	for i in range(17):
		var a := i*2.399963+0.42
		var radius := random.randf_range(17,37)
		var tree_at := center+Vector3(cos(a)*radius,0,sin(a)*radius*0.82)
		if absf(tree_at.x)<8 and tree_at.z>center.z: tree_at.x = -12 if tree_at.x<0 else 12
		add_tree(tree_at,random.randf_range(4.2,7.2),palette[i%palette.size()],1.2+i*0.42)
	var colors: Array[Color] = [Color("f6c7d5"),Color("f3d683"),Color("b09bdd"),Color("ec987e"),Color("a2dbe3"),Color("f6eded")]
	for i in range(160):
		var bed := i/10
		var a := bed*2.399963
		var radius := 8+(bed%4)*7.0
		var inner := (i%10)*2.399963
		var patch := Vector3(cos(inner),0,sin(inner))*sqrt((i%10)/10.0)*3.4
		var flower := GardenBloom.new()
		flower.position = center+Vector3(cos(a)*radius,0,sin(a)*radius*0.85)+patch
		flower.color = colors[i%colors.size()]
		flower.kind = bed%6
		flower.height = random.randf_range(1.6,2.2) if flower.kind==3 else random.randf_range(0.85,1.3) if flower.kind>=4 else random.randf_range(0.45,0.9)
		flower.delay = 1+radius*0.23+random.randf_range(0,2)
		add_child(flower)
		flower.start()
		flowers.append(flower)
	for i in range(18):
		var z := -34+i*4.0
		var x := sin(i*0.4)*5.5+(4 if absf(z)<8 else 0)
		Shapes.cylinder(self,center+Vector3(x,0.035,z),0.85,0.045,Shapes.material(Color("d9d8bb")))
	build_sky()
	build_perimeter()
	build_ground_plants()
	petals = MultiMeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radial_segments = 5
	mesh.rings = 2
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = 24
	petals.multimesh = multimesh
	petals.material_override = Shapes.material(Color("efb5d4"))
	petals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(petals)
	petals.hide()
func add_tree(at: Vector3, height: float, tint: Color, delay: float) -> GardenGrowingTree:
	var tree := GardenGrowingTree.new()
	tree.position = at
	tree.height = height
	tree.tint = tint
	tree.delay = delay
	tree.variation = trees.size()
	tree.species = 0 if trees.is_empty() else 1+trees.size()%3
	if tree.species==1: tree.tint = Color("366a47").lightened((trees.size()%3)*0.09)
	add_child(tree)
	trees.append(tree)
	return tree
func _physics_process(delta: float) -> void:
	age += delta
	sky_material.set_shader_parameter("reveal",smoothstep(0,8,age))
	if age>4: grow_trail()
	plant_material.set_shader_parameter("grow",smoothstep(2,12,age))
	floor_material.set_shader_parameter("bloom",smoothstep(0,7,age))
	floor_material.set_shader_parameter("walker",walker.global_position)
	var morph := smoothstep(0,4.2,age)
	cake.position.y = morph*4.6
	for material in morph_materials: material.albedo_color.a = 1-smoothstep(1.0,4.2,age)
	if age>4.2:
		cake.hide()
		plinth.hide()
	petals.visible = age>8
	for i in range(24):
		var t := age+i*0.73
		var p := center+Vector3(sin(t*0.37+i)*4.5,8-fposmod(t*0.55,7.6),cos(t*0.29+i)*4)
		var basis := Basis.from_euler(Vector3(t*0.3,i,t*0.4)).scaled(Vector3(0.16,0.035,0.24))
		petals.multimesh.set_instance_transform(i,Transform3D(basis,p))

# Overlapping planted banks enclose all four edges. Their collision follows the bank.
func build_perimeter() -> void:
	perimeter = Node3D.new()
	perimeter.name = "Green perimeter"
	add_child(perimeter)
	for edge in range(4):
		for i in range(14):
			var along := -49.0+i*7.5
			var at := center+Vector3(along,0,-44 if edge==0 else 44)
			if edge>=2: at = center+Vector3(-51 if edge==2 else 51,0,along*0.85)
			var h := random.randf_range(7,12)
			var bank := StaticBody3D.new()
			bank.position = at
			perimeter.add_child(bank)
			var shape := BoxShape3D.new()
			shape.size = Vector3(8,h,7) if edge<2 else Vector3(7,h,8)
			var collision := CollisionShape3D.new()
			collision.shape = shape
			collision.position.y = h*0.5
			bank.add_child(collision)
			Shapes.mesh(bank,GardenVegetationAssets.mesh(&"Bush"),Vector3.ZERO,Shapes.material(Color("286638").lightened(random.randf_range(0,0.15))),Vector3(12,h*1.7,12))

# Distance sampling prevents stationary or airborne spawning; the oldest flowers recycle.
func grow_trail() -> void:
	var here := walker.global_position
	if not walker.is_on_floor():
		last_step = here
		return
	if not last_step.is_finite(): last_step = here
	if here.distance_to(last_step)<0.85: return
	var direction := (here-last_step).normalized()
	last_step = here
	var behind := here-direction*0.7
	if absf(behind.x-center.x)>45 or absf(behind.z-center.z)>38: return
	if trail.size()>=180:
		var old := trail.pop_front() as GardenBloom
		old.queue_free()
	var flower := GardenBloom.new()
	flower.position = behind+Vector3(random.randf_range(-0.22,0.22),0.02,random.randf_range(-0.22,0.22))
	flower.height = random.randf_range(0.28,0.65)
	flower.kind = [0,1,0,2,4,0,3,5][trail.size()%8]
	if flower.kind==3: flower.height = random.randf_range(1.1,1.65)
	elif flower.kind>=4: flower.height = random.randf_range(0.7,1.0)
	flower.color = [Color("fff2aa"),Color("f6b9d3"),Color("c5b4ed"),Color.WHITE][trail.size()%4]
	add_child(flower)
	flower.start()
	trail.append(flower)

func build_ground_plants() -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for blade in range(3):
		var angle := blade*2.399963
		var direction := Vector3(cos(angle)*0.45,0.8,sin(angle)*0.45).normalized()
		var basis := Basis(Quaternion(Vector3.RIGHT,direction)).scaled(Vector3(0.85,0.7,0.65))
		surface.append_from(GardenVegetationAssets.mesh(&"Leaf"),0,Transform3D(basis,direction*0.42))
	surface.generate_normals()
	var mesh := surface.commit()
	plant_material = ShaderMaterial.new()
	plant_material.shader = Shader.new()
	plant_material.shader.code = "shader_type spatial; render_mode cull_disabled; uniform float grow=0.0; void vertex(){VERTEX.y*=grow;} void fragment(){ALBEDO=vec3(0.12,0.46,0.25);ROUGHNESS=1.0;}"
	ground_plants = MultiMeshInstance3D.new()
	ground_plants.material_override = plant_material
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = 320
	ground_plants.multimesh = batch
	add_child(ground_plants)
	for i in range(batch.instance_count):
		var bed := i/20
		var angle := bed*2.399963
		var radius := 8.0+(bed%5)*7.0
		var offset := Vector3(random.randf_range(-4,4),0.03,random.randf_range(-4,4))
		var at := center+Vector3(cos(angle)*radius,0,sin(angle)*radius*0.85)+offset
		var size := random.randf_range(0.65,1.5)
		batch.set_instance_transform(i,Transform3D(Basis(Vector3.UP,random.randf()*TAU).scaled(Vector3.ONE*size),at))

func build_sky() -> void:
	var world_environment := walker.get_world_3d().environment
	if world_environment==null: return
	var sky := Sky.new()
	sky_material = ShaderMaterial.new()
	sky_material.shader = load("res://assets/shaders/birthday_sky.gdshader")
	sky.sky_material = sky_material
	world_environment.sky = sky
	world_environment.background_mode = Environment.BG_SKY
