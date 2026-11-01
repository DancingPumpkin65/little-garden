extends SceneTree

func _initialize() -> void:
 run.call_deferred()

func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 await physics_frame
 game.start()
 game.player.position = Vector3(-1.4, 0.1, 4.5)
 game.interact()
 assert(not game.held and game.player.action == "pickup", "pickup starts with a reach")
 for i in range(60): await physics_frame
 var skeleton: Skeleton3D = game.player.imported_skeleton
 var a = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("hand_L")).origin
 var b = skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone("hand_R")).origin
 assert(game.held and game.player.action.is_empty(), "reach finishes in carry")
 assert(game.ball.global_position.distance_to((a+b)*0.5) < 0.04, "fruit follows animated wrists")
 assert(absf(a.distance_to(b) - 0.52) < 0.03, "both hands grip the fruit")
 game.orbiting = true
 var motion := InputEventMouseMotion.new()
 motion.relative = Vector2(100, 50)
 game._input(motion)
 assert(game.yaw < 0 and game.pitch > 0.6, "mouse changes yaw and pitch")
 game.orbiting = false
 var carry_position: Vector3 = game.player.fruit_position()
 game.charging = true
 game.update_aim()
 assert(game.player.fruit_position().distance_to(carry_position) < 0.001, "trajectory preview preserves visible carry pose")
 game.throw_seed()
 assert(game.held and game.ball.freeze, "windup retains the fruit")
 for i in range(18): await physics_frame
 assert(game.held, "fruit is retained through windup")
 a = skeleton.get_bone_global_pose(skeleton.find_bone("hand_L")).origin
 b = skeleton.get_bone_global_pose(skeleton.find_bone("hand_R")).origin
 assert(absf(a.distance_to(b) - 0.52) < 0.03, "windup keeps the hands around the fruit")
 for i in range(12): await physics_frame
 assert(not game.held and not game.ball.freeze, "release keyframe starts rigid body flight")
 assert(game.ball.linear_velocity.length() > 1, "released fruit moves")
 for i in range(18): await physics_frame
 assert(game.player.action.is_empty() and not game.player.carrying, "follow-through returns to idle")
 assert(game.hud.dialogue.text.find("Ari:") == -1, "bubble has dialogue without a speaker prefix")
 game.sound.silence()
 print("INTERACTION_TEST_PASS reach, two-handed attachment, mouse orbit, windup, release and recovery")
 quit()
