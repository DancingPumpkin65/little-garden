class_name GardenDust
extends Node3D

var actor: GardenCharacter
var clock := 0.0
var emitted := 0
var puffs: Array[MeshInstance3D] = []
var ages: Array[float] = []

func setup(character: GardenCharacter) -> void:
	actor = character
	var sphere := SphereMesh.new()
	sphere.radial_segments = 6
	sphere.rings = 3
	sphere.radius = 0.5
	sphere.height = 1
	for i in range(18):
		var material := Shapes.material(Color(0.55, 0.55, 0.55, 0))
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var puff := Shapes.mesh(self, sphere, Vector3.ZERO, material)
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puff.hide()
		puffs.append(puff)
		ages.append(1.0)

func _physics_process(delta: float) -> void:
	clock += delta
	for i in range(puffs.size()):
		if ages[i] >= 0.55: continue
		ages[i] += delta
		var progress := ages[i] / 0.55
		puffs[i].position.y += delta * 0.19
		puffs[i].scale = Vector3.ONE * lerpf(0.08, 0.29, progress)
		(puffs[i].material_override as StandardMaterial3D).albedo_color.a = 0.3 * (1 - progress)
		puffs[i].visible = progress < 1
	if actor.visible and actor.is_on_floor() and Vector2(actor.velocity.x, actor.velocity.z).length() > 0.4 and clock >= 0.11:
		clock = 0
		var index := emitted % puffs.size()
		var side := -0.15 if emitted % 2 == 0 else 0.15
		puffs[index].global_position = actor.global_position + Vector3(side, 0.06, 0).rotated(Vector3.UP, actor.visual.rotation.y)
		ages[index] = 0
		puffs[index].show()
		emitted += 1
