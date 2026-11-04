extends SceneTree
var game: Node3D
func _initialize() -> void: run.call_deferred()
func shot(label: String, focus := Vector3(0,1.4,0), angle := Vector3(0,0,8)) -> void:
 if DisplayServer.get_name()=="headless": return
 game.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
 game.camera.size = 4.8
 game.camera.position = focus+angle
 game.camera.look_at(focus)
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://artifacts/soft-review/godot-"+label+".png")
func run() -> void:
 game = load("res://main.tscn").instantiate()
 root.add_child(game)
 game.set_physics_process(false)
 game.world.hide()
 game.ball.hide()
 game.hud.hide()
 game.environment.background_color = Color("363e43")
 game.environment.ambient_light_energy = 0.32
 for part in [&"head",&"arm",&"leg"]: game.companion_parts.restore(part)
 for actor: GardenCharacter in [game.player,game.friend]:
  actor.set_physics_process(false)
  actor.rotation = Vector3.ZERO
  actor.visual.rotation = Vector3.ZERO
  actor.position = Vector3(-0.85 if actor==game.player else 0.85,0,0)
  actor.animate_pose(1,0,true)
 await shot("body-front")
 for actor: GardenCharacter in [game.player,game.friend]:
  actor.put_on_birthday_outfit()
  var wardrobe := actor.model_root.get_node("Birthday clothing")
  var garment_names := {}
  for cloth: MeshInstance3D in wardrobe.get_children(): garment_names[String(cloth.name)] = true
  for name in ["SWEATER_TORSO","SWEATER_SLEEVE_LEFT","SWEATER_SLEEVE_RIGHT","PANTS_LEFT","PANTS_RIGHT","SHOES_LEFT","SHOES_RIGHT"]:
   assert(garment_names.has(name),"independent garment module survives import: "+name)
  for cloth: MeshInstance3D in wardrobe.get_children():
   assert(cloth.get_node(cloth.skeleton)==actor.imported_skeleton,"clothes use the production skeleton")
   for surface in range(cloth.mesh.get_surface_count()):
    var arrays := cloth.mesh.surface_get_arrays(surface)
    var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var stride := weights.size()/vertices.size()
    for vertex in range(vertices.size()):
     var total := 0.0
     for slot in range(stride):
      var weight := weights[vertex*stride+slot]
      total+=weight
      if cloth.name in [&"SWEATER_TORSO",&"WAISTBAND",&"COLLAR"] and weight>0.001:
       var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
       assert(cloth.skin.get_bind_name(bones[vertex*stride+slot])==&"body","hands and thighs cannot drag the sweater torso")
     assert(absf(total-1)<0.001 and vertices[vertex].is_finite(),"new garment weights and geometry remain valid")
 await shot("outfit-front")
 await shot("outfit-back",Vector3(0,1.4,0),Vector3(0,0,-8))
 await shot("outfit-side",Vector3(0,1.4,0),Vector3(8,0,1))
 if "--static-only" in OS.get_cmdline_user_args():
  print("STATIC_RENDER_PASS independent body and garment modules, normalized weights, matching static views")
  game.sound.silence()
  quit()
  return
 for actor: GardenCharacter in [game.player,game.friend]:
  actor.gait = PI*1.5
  actor.animate_pose(1,1,true)
 await shot("outfit-walk")
 for actor: GardenCharacter in [game.player,game.friend]: actor.animate_pose(1,0,false)
 await shot("outfit-jump")
 for actor: GardenCharacter in [game.player,game.friend]:
  actor.action = "throw"
  actor.action_phase = 0.65
  actor.apply_joint_poses()
 await shot("outfit-throw")
 print("SOFT_VISUAL_PASS normalized garment skinning, shared skeleton, walk, jump and throw poses")
 game.sound.silence()
 quit()
