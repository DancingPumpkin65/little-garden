"""Static pose/camera studies. Never save these poses into the production rig."""
import bpy, math, sys
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts/round-hand-review'
OUT.mkdir(parents=True,exist_ok=True)
before='--before' in sys.argv
source=OUT/'before-girl.blend' if before else ROOT/'art/character/reference_character.blend'
bpy.ops.wm.open_mainfile(filepath=str(source))
scene=bpy.context.scene
scene.cycles.samples=24
scene.render.resolution_x=700
scene.render.resolution_y=850
camera=scene.camera
camera.data.ortho_scale=2.9
rig=bpy.data.objects['CharacterRig']

def render(label,angle):
    focus=Vector((0,0,1.28))
    camera.location=focus+Vector((7*math.sin(angle),-7*math.cos(angle),.10))
    camera.rotation_euler=(focus-camera.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath=str(OUT/(('before-' if before else '')+label+'.png'))
    bpy.ops.render.render(write_still=True)

render('neutral-front',0)
render('neutral-oblique-side',math.radians(75))
render('neutral-back',math.pi)
# Separate evidence of relaxed suspended legs from the neutral control cage.
for name,angle in [('thigh_L',-.07),('thigh_R',.035),('calf_L',.20),('calf_R',.13),('foot_L',-.07),('foot_R',-.04)]:
    bone=rig.pose.bones[name]
    bone.rotation_mode='XYZ'
    bone.rotation_euler.x=angle
render('floating-front',0)
render('floating-oblique-side',math.radians(75))
render('floating-back',math.pi)
print('REFERENCE_POSE_RENDERED neutral and floating studies; production rig not saved')
