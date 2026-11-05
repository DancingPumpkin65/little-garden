"""Matched static design-sheet views; never persist review poses to the rig."""
import bpy, math, sys
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts/design-sheet-review'
OUT.mkdir(parents=True,exist_ok=True)
before='--before' in sys.argv
for variant in ['girl','guy']:
    filename=variant+'_wardrobe.blend'
    path=OUT/('before-'+filename) if before else ROOT/'art/character'/filename
    bpy.ops.wm.open_mainfile(filepath=str(path))
    scene=bpy.context.scene
    scene.cycles.samples=20
    scene.render.resolution_x=650
    scene.render.resolution_y=800
    camera=scene.camera
    camera.data.ortho_scale=2.95
    focus=Vector((0,0,1.28))
    prefix=('before-' if before else 'after-')+variant
    def render(label,angle):
        camera.location=focus+Vector((7*math.sin(angle),-7*math.cos(angle),0))
        camera.rotation_euler=(focus-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(OUT/(prefix+'-'+label+'.png'))
        bpy.ops.render.render(write_still=True)
    for label,degrees in [('front',0),('three-quarter',40),('side',90),('back',180)]:
        render(label,math.radians(degrees))
    rig=bpy.data.objects['CharacterRig']
    for name,angle in [('thigh_L',-.4),('calf_L',.8),('arm_R',.35),('forearm_R',-.45)]:
        bone=rig.pose.bones[name]
        bone.rotation_mode='XYZ'
        bone.rotation_euler.x=angle
    render('bent',math.radians(40))
print('DESIGN_TURNAROUND_RENDERED matching four views and bent-pose inspection')
