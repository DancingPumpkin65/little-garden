extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 DirAccess.make_dir_recursive_absolute("res://artifacts")
 var viewport:=SubViewport.new()
 viewport.size=Vector2i(768,768)
 viewport.transparent_bg=true
 viewport.own_world_3d=true
 viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
 root.add_child(viewport)
 var stage:=Node3D.new()
 viewport.add_child(stage)
 var actor:=GardenCharacter.new()
 stage.add_child(actor)
 actor.set_physics_process(false)
 actor.animate_pose(1,0,true)
 actor.visual.rotation.y=-.08
 actor.put_on_birthday_outfit()
 var env:=WorldEnvironment.new()
 env.environment=Environment.new()
 env.environment.background_mode=Environment.BG_COLOR
 env.environment.background_color=Color(0,0,0,0)
 env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color=Color.WHITE
 env.environment.ambient_light_energy=.65
 stage.add_child(env)
 var light:=DirectionalLight3D.new()
 light.rotation_degrees=Vector3(-30,-25,0)
 light.light_energy=.85
 stage.add_child(light)
 var camera:=Camera3D.new()
 camera.projection=Camera3D.PROJECTION_ORTHOGONAL
 camera.size=2.15
 camera.position=Vector3(0,2.07,6)
 stage.add_child(camera)
 camera.look_at(Vector3(0,2.07,0))
 camera.current=true
 await create_timer(1.2).timeout
 await RenderingServer.frame_post_draw
 viewport.get_texture().get_image().save_png("res://artifacts/icon-portrait.png")
 print("ICON_PORTRAIT_RENDERED")
 quit()
