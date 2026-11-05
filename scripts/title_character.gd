class_name GardenTitleCharacter
extends SubViewportContainer

var actor := GardenCharacter.new()
var clock := 0.0
@export var rotation_speed := 0.45

func _ready() -> void:
 mouse_filter = Control.MOUSE_FILTER_IGNORE
 stretch = true
 var viewport := SubViewport.new()
 viewport.own_world_3d = true
 viewport.transparent_bg = true
 viewport.size = Vector2i(640,800)
 viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
 add_child(viewport)
 visibility_changed.connect(func(): viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS if is_visible_in_tree() else SubViewport.UPDATE_DISABLED)
 var scene := Node3D.new()
 viewport.add_child(scene)
 scene.add_child(actor)
 actor.set_physics_process(false)
 var environment := WorldEnvironment.new()
 environment.environment = Environment.new()
 environment.environment.background_mode = Environment.BG_COLOR
 environment.environment.background_color = Color.BLACK
 environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 environment.environment.ambient_light_color = Color.WHITE
 environment.environment.ambient_light_energy = 0.45
 scene.add_child(environment)
 var light := DirectionalLight3D.new()
 light.rotation_degrees = Vector3(-35,-25,0)
 light.light_energy = 0.75
 scene.add_child(light)
 var camera := Camera3D.new()
 camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 camera.size = 3.8
 camera.position = Vector3(0,1.6,7)
 scene.add_child(camera)
 camera.look_at(Vector3(0,1.45,0))
 camera.current = true

func _process(delta: float) -> void:
 if not is_visible_in_tree(): return
 clock += delta
 actor.animate_pose(1,0,true)
 actor.visual.position.y = 0.08+sin(clock*1.4)*0.065
 actor.visual.rotation.y = -0.25+clock*rotation_speed
 actor.left_leg.rotation.x = -0.12
 actor.right_leg.rotation.x = 0.05
 actor.knees[0].rotation.x = 0.25
 actor.knees[1].rotation.x = 0.14
 actor.apply_joint_poses()
