class_name GardenGrowingTree
extends Node3D
var tint := Color("e798bd")
var height := 7.8
var species := 0
var variation := 0
var delay := 0.0
var age := 0.0
var progress := 0.0
var crowns: Array[MeshInstance3D] = []
var trunk_material: ShaderMaterial
var crown_material: ShaderMaterial
var body: StaticBody3D
func _ready() -> void:
 var style: String = ["Plum","Evergreen","Willow","Oak"][species]
 var wood := GardenVegetationAssets.mesh(StringName(style+"Wood"))
 var crown := GardenVegetationAssets.mesh(StringName(style+"Crown"))
 trunk_material = ShaderMaterial.new()
 trunk_material.shader = Shader.new()
 trunk_material.shader.code = "shader_type spatial; uniform float grow=0.0; void vertex(){VERTEX.y*=grow;} void fragment(){ALBEDO=vec3(0.34,0.22,0.15);ROUGHNESS=1.0;SPECULAR=0.0;}"
 Shapes.mesh(self,wood,Vector3.ZERO,trunk_material,Vector3.ONE*height)
 crown_material = ShaderMaterial.new()
 crown_material.shader = Shader.new()
 crown_material.shader.code = "shader_type spatial; uniform float wood=0.0; uniform float bloom=0.0; uniform vec4 tint:source_color; void vertex(){vec3 pivot=vec3(0.0,0.65,0.0);VERTEX=pivot*wood+(VERTEX-pivot)*bloom;} void fragment(){ALBEDO=tint.rgb;ROUGHNESS=1.0;SPECULAR=0.0;}"
 crown_material.set_shader_parameter("tint",tint)
 var canopy := Shapes.mesh(self,crown,Vector3.ZERO,crown_material,Vector3(height*(1.0+(variation%3)*0.04),height,height*(0.96+(variation%4)*0.035)))
 canopy.rotation.y = (variation%5)*0.16
 crowns.append(canopy)
 body = StaticBody3D.new()
 var collision := CollisionShape3D.new()
 var shape := CylinderShape3D.new()
 shape.radius = height*0.055
 shape.height = height*0.55
 collision.shape = shape
 collision.position.y = shape.height*0.5
 body.add_child(collision)
 add_child(body)
 body.collision_layer = 0
func _physics_process(delta: float) -> void:
 age += delta
 progress = clampf((age-delay)/9.0,0,1)
 var wood := smoothstep(0,0.7,progress)
 var bloom := smoothstep(0.32,1,progress)
 trunk_material.set_shader_parameter("grow",wood)
 crown_material.set_shader_parameter("wood",wood)
 crown_material.set_shader_parameter("bloom",bloom)
 for canopy in crowns: canopy.visible = bloom>0.001
 body.collision_layer = 1 if wood>0.2 else 0
 var collision := body.get_child(0) as CollisionShape3D
 (collision.shape as CylinderShape3D).height = maxf(0.01,height*0.55*wood)
 collision.position.y = height*0.275*wood
 if progress>=1: set_physics_process(false)
