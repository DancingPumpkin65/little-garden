extends SceneTree
func _initialize() -> void: run.call_deferred()
func run() -> void:
 var flower:=GardenBloom.new()
 flower.kind=4
 flower.delay=2
 root.add_child(flower)
 flower.start()
 assert(flower.parts.is_empty(),"delayed flowers defer mesh construction")
 flower._physics_process(1)
 assert(flower.parts.is_empty(),"waiting beds do not allocate geometry")
 flower._physics_process(1.5)
 assert(flower.progress>0 and not flower.parts.is_empty(),"geometry exists when emergence starts")
 flower._physics_process(3)
 assert(flower.progress==1 and not flower.batches.is_empty(),"finished petals batch")
 var visible:=0
 for part in flower.parts:
  if part.visible:visible+=1
 assert(visible+flower.batches.size()<flower.parts.size()/2,"mature flower uses fewer draws")
 for part in flower.parts:
  assert(part.material_override.get_shader_parameter("soil_height")==0,"soil setting is shared per material")
 flower.pose(.3)
 assert(flower.batches.is_empty(),"pose edits restore original articulated parts")
 print("FLOWER_BATCH_PASS delayed construction, unchanged emergence, mature batching and pose restore")
 quit()
