class_name GardenBirthday
extends Node3D
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
	floor_material.shader.code = "shader_type spatial; uniform float bloom=0.0; uniform vec3 walker=vec3(0.0); varying vec3 world; void vertex(){world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;} void fragment(){float light=1.0-0.55*smoothstep(35.0,85.0,length(world.xz-walker.xz));vec3 grass=mix(vec3(1.0),vec3(0.42,0.69,0.46),bloom);ALBEDO=grass*light;ROUGHNESS=1.0;SPECULAR=0.0;}"
	ground.material_override = floor_material
	for parent in [cake,plinth]:
		for node: MeshInstance3D in parent.find_children("*","MeshInstance3D",true,false):
			var material := node.material_override as BaseMaterial3D
			if material!=null:
				var local := material.duplicate() as BaseMaterial3D
				local.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				node.material_override = local
				morph_materials.append(local)
	hero = add_tree(center,11.5,Color("e795c2"),0)
	var palette: Array[Color] = [Color("85b794"),Color("c4a6df"),Color("f0b0b7"),Color("b4c98a"),Color("81bec0")]
	for i in range(17):
		var a := i*TAU/17
		var radius := 18.0+(i%3)*8.0
		var tree_at := center+Vector3(cos(a)*radius,0,sin(a)*radius*0.82)
		if absf(tree_at.x)<8 and tree_at.z>center.z: tree_at.x = -12 if tree_at.x<0 else 12
		add_tree(tree_at,random.randf_range(4.2,7.2),palette[i%palette.size()],1.2+i*0.42)
	var colors: Array[Color] = [Color("f6c7d5"),Color("f3d683"),Color("b09bdd"),Color("ec987e"),Color("a2dbe3"),Color("f6eded")]
	for i in range(96):
		var bed := i/8
		var a := bed*TAU/12
		var radius := 9+(bed%3)*8.0
		var inner := (i%8)*2.399963
		var patch := Vector3(cos(inner),0,sin(inner))*sqrt((i%8)/8.0)*2.5
		var flower := GardenBloom.new()
		flower.position = center+Vector3(cos(a)*radius,0,sin(a)*radius*0.85)+patch
		flower.color = colors[i%colors.size()]
		flower.kind = i%3
		flower.height = random.randf_range(0.65,1.1)
		flower.delay = 1+radius*0.23+random.randf_range(0,2)
		add_child(flower)
		flower.start()
		flowers.append(flower)
	for i in range(18):
		var z := -34+i*4.0
		var x := sin(i*0.4)*5.5+(4 if absf(z)<8 else 0)
		Shapes.cylinder(self,center+Vector3(x,0.035,z),0.85,0.045,Shapes.material(Color("d9d8bb")))
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
	add_child(tree)
	trees.append(tree)
	return tree
func _physics_process(delta: float) -> void:
	age += delta
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
