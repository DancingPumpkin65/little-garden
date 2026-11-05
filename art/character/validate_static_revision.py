"""Check a static shape revision against saved baseline Blender scenes."""
import bpy,json,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
BODY=['HEAD','TORSO','ARM_LEFT','ARM_RIGHT','HAND_LEFT','HAND_RIGHT','LEG_LEFT','LEG_RIGHT','FOOT_LEFT','FOOT_RIGHT']
def snapshot(path):
 bpy.ops.wm.open_mainfile(filepath=str(path))
 rig=bpy.data.objects['CharacterRig']
 return {
  'rig':{bone.name:tuple(value for row in bone.matrix_local for value in row) for bone in rig.data.bones},
  'identity':{obj.name:([tuple(vert.co) for vert in obj.data.vertices],tuple(value for row in obj.matrix_world for value in row)) for obj in bpy.context.scene.objects if obj.type=='MESH' and (obj.name=='HEAD' or obj.name not in BODY)},
  'body':{name:(len(bpy.data.objects[name].data.vertices),len(bpy.data.objects[name].data.polygons)) for name in BODY}
 }
report=[]
for variant,filename in [('girl','reference_character'),('guy','companion_character')]:
 before=snapshot(ROOT/'artifacts/final-static'/('baseline-'+filename+'.blend'))
 after=snapshot(ROOT/'art/character'/(filename+'.blend'))
 assert before['rig']==after['rig'],'Static refinement must not change bone rest transforms'
 assert before['identity']==after['identity'],'Head, hood/hair, face and glasses must be unchanged'
 assert before['body']==after['body'],'Static refinement must not add body polygons'
 objects=[bpy.data.objects[name] for name in BODY]
 assert len({obj.data.as_pointer() for obj in objects})==10
 for obj in objects:
  assert all(all(abs(c)<100 for c in vertex.co) for vertex in obj.data.vertices)
 report.append({'variant':variant,'identity_unchanged':True,'rig_unchanged':True,'body_topology_unchanged':True,'independent_body_meshes':10})
(ROOT/'artifacts/final-static/validation.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('STATIC_SHAPE_PASS',report)
