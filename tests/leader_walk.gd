extends SceneTree
func _initialize():
 run.call_deferred()
func run():
 var floor_root := Node3D.new()
 root.add_child(floor_root)
 Shapes.collider(floor_root,Vector3(0,-0.5,45),Vector3(30,1,150))
 var guy := GardenCharacter.new()
 guy.npc=true
 guy.rotation.y=-0.5
 root.add_child(guy)
 guy.two_legs=true
 guy.directed_move=true
 guy.move_target=Vector3(0,0,100)
 for i in range(100): await physics_frame
 var direction := Vector3(guy.velocity.x,0,guy.velocity.z).normalized()
 var alignment := guy.visual.global_basis.z.normalized().dot(direction)
 print("LEADER_ALIGNMENT ",alignment," SPEED ",Vector2(guy.velocity.x,guy.velocity.z).length())
 assert(alignment>0.99,"leader must face world travel direction under rotated parent")
 assert(Vector2(guy.velocity.x,guy.velocity.z).length()>4.2,"leader must keep ahead of walking player")
 print("LEADER_PASS")
 quit()
