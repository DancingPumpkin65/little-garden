class_name GardenBasket
extends Node3D

const RIM_HEIGHT := 1.6
const SCORE_RADIUS := 0.65

func _ready() -> void:
 var dark := Shapes.material(Color("242424"))
 var white := Shapes.material(Color.WHITE)
 Shapes.box(self,Vector3(0,.06,-.85),Vector3(2.2,.12,1.2),dark)
 Shapes.cylinder(self,Vector3(0,1.15,-.9),.07,2.3,dark)
 Shapes.box(self,Vector3(0,2.25,-.85),Vector3(2.4,1.25,.12),dark)
 Shapes.box(self,Vector3(0,2.25,-.77),Vector3(2.22,1.08,.04),white)
 Shapes.box(self,Vector3(0,2.05,-.73),Vector3(.9,.65,.03),dark)
 Shapes.box(self,Vector3(0,2.08,-.70),Vector3(.76,.51,.03),white)
 Shapes.collider(self,Vector3(0,2.25,-.85),Vector3(2.4,1.25,.12))
 var ring := TorusMesh.new()
 ring.inner_radius = .84
 ring.outer_radius = .96
 Shapes.mesh(self,ring,Vector3(0,RIM_HEIGHT,0),dark)
 # Tapered open net, with diagonal cords rather than a solid bucket.
 for row in range(3):
  for i in range(16):
   var a := TAU*i/16.0
   var top_angle := a+(row%2)*PI/16
   var top := Vector3(cos(top_angle)*(.90-row*.13),RIM_HEIGHT-row*.22,sin(top_angle)*(.90-row*.13))
   for side in [-1,1]:
    var b: float = top_angle+side*PI/16
    var bottom := Vector3(cos(b)*(.77-row*.13),RIM_HEIGHT-(row+1)*.22,sin(b)*(.77-row*.13))
    var cord := Shapes.cylinder(self,(top+bottom)/2,.012,top.distance_to(bottom),dark)
    cord.quaternion = Quaternion(Vector3.UP,(top-bottom).normalized())

func scored(previous: Vector3, current: Vector3) -> bool:
 var plane := global_position.y+RIM_HEIGHT
 if previous.y<=plane or current.y>plane: return false
 var crossing := previous.lerp(current,(previous.y-plane)/(previous.y-current.y))
 return Vector2(crossing.x-global_position.x,crossing.z-global_position.z).length()<SCORE_RADIUS
