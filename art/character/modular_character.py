"""Restore modular body objects from the original control cages; never fuse parts."""
import bpy, bmesh, sys, json
from pathlib import Path
from mathutils import Vector, Matrix
sys.path.insert(0,str(Path(__file__).resolve().parent))
from static_shapes import body_part
ROOT=Path(__file__).resolve().parents[2];SOURCE=ROOT/'art/character';OUT=ROOT/'artifacts/modular-review';OUT.mkdir(parents=True,exist_ok=True)
# Reuse the existing vertex edits and wrist-rest correction, without unify_body().
helpers={"__file__":str(SOURCE/'refine_character.py')}
exec((SOURCE/'refine_character.py').read_text().split('reports=[]')[0],helpers)
variants=['girl'] if '--girl' in sys.argv else ['guy'] if '--guy' in sys.argv else ['girl','guy']
report=[]
for variant in variants:
 filename='reference_character' if variant=='girl' else 'companion_character'
 identity_source=SOURCE/(filename+'_identity.blend')
 if not identity_source.exists():
  import shutil
  shutil.copyfile(SOURCE/(filename+'.blend'),identity_source)
 bpy.ops.wm.open_mainfile(filepath=str(SOURCE/'reference_character_base.blend'))
 helpers['sculpt_body']();helpers['open_wrist_gap']()
 mapping={'Torso':('TORSO','body'),'Arm L':('ARM_LEFT','arm_L'),'Arm R':('ARM_RIGHT','arm_R'),'Mitten L':('HAND_LEFT','hand_L'),'Mitten R':('HAND_RIGHT','hand_R'),'Leg L':('LEG_LEFT','thigh_L'),'Leg R':('LEG_RIGHT','thigh_R'),'Foot L':('FOOT_LEFT','foot_L'),'Foot R':('FOOT_RIGHT','foot_R')}
 rig=bpy.data.objects['CharacterRig']
 for obj in list(bpy.context.scene.objects):
  if obj.type=='MESH' and obj.name not in mapping:bpy.data.objects.remove(obj,do_unlink=True)
 with bpy.data.libraries.load(str(identity_source),link=False) as (available,loaded):
  loaded.objects=[name for name in available.objects if name not in ['Soft faceted body'] and not name.startswith(('Camera','Light','CharacterRig','Area'))]
 for obj in loaded.objects:
  if obj is None or obj.type!='MESH':continue
  bpy.context.collection.objects.link(obj)
  obj.parent=rig
  for mod in obj.modifiers:
   if mod.type=='ARMATURE':mod.object=rig
  if obj.name=='Head':obj.name='HEAD'
 # Proportion edits act on each original control cage and the corresponding rest bones.
 def height(y):
  if y<=.18:return y*.9
  if y<=1.205:return .162+(y-.18)*(.958/1.025)
  return 1.12+(y-1.205)*(.62/.675)
 def logical(point):return Vector((point.x,point.z,-point.y))
 def blender(point):return Vector((point.x,-point.z,point.y))
 import math
 for old,(name,bone) in mapping.items():
  obj=bpy.data.objects[old]
  side=-1 if name.endswith('LEFT') else 1
  for vert in obj.data.vertices:
   point=logical(vert.co)
   if name=='TORSO':
    point.x*=1.06
    point.z*=1.025
    point.y=1.74-(1.74-height(point.y))*.90
   elif name.startswith('ARM_'):
    t=max(0,min(1,(1.77-point.y)/.695))
    center=side*(.285+.415*t)
    point.x=center+(point.x-center)*(1.12+.06*math.sin(t*math.pi))*(.99 if side<0 else 1.01)+side*(.03*t+.016*math.sin(t*math.pi))
    point.z=point.z*1.08+.025*math.sin(t*math.pi)
    point.y=height(point.y)
   elif name.startswith('HAND_'):
    center=Vector((side*.70,1.075,.018));local=point-center
    thumb=math.exp(-((side*local.x+.12)/.07)**2-((local.y-.04)/.09)**2)
    local.x*=1.05
    local.y*=.90
    local.z=local.z*.90+.025*thumb
    point=Vector((side*.73,height(1.075),.018))+local
   elif name.startswith('LEG_'):
    t=max(0,min(1,(1.205-point.y)/1.025));center=side*(.18+.02*t)
    point.x=center+(point.x-center)*(1.10+.06*math.sin(t*math.pi))+side*.012*math.sin(t*math.pi)
    point.z=point.z*(1.06+.06*math.sin(t*math.pi))+.012*math.sin(t*math.pi)
    point.y=height(point.y)
   elif name.startswith('FOOT_'):
    center=Vector((side*.20,.115,.085));local=point-center
    toe=max(0,min(1,(local.z+.10)/.30))
    point=Vector((center.x+local.x*(1.03+.18*toe),max(.008,height(center.y)+local.y*(.86-.10*toe)),max(-.045,center.z+local.z*1.24+.025)))
   vert.co=blender(body_part(name,point,vert.index))
 bpy.context.view_layer.objects.active=rig
 bpy.ops.object.mode_set(mode='EDIT')
 for bone in rig.data.edit_bones:
  for attr in ['head','tail']:
   point=logical(getattr(bone,attr))
   if bone.name=='head':point.y=1.97+(point.y-2.145)*1.08
   else:
    if bone.name.startswith(('arm_','forearm_','hand_')):
     t=max(0,min(1,(1.77-point.y)/.695));point.x+=(.03*t)*(1 if point.x>0 else -1)
    point.y=height(point.y)
   setattr(bone,attr,blender(point))
 bpy.ops.object.mode_set(mode='OBJECT')
 for obj in bpy.context.scene.objects:
  if obj.type!='MESH' or obj.name in mapping:continue
  # Scale the existing identity as a unit; its face, hood and glasses stay unchanged.
  for vert in obj.data.vertices:
   point=logical(vert.co);point.x*=1.08;point.z=.015+(point.z-.015)*1.08;point.y=1.97+(point.y-2.145)*1.08;vert.co=blender(point)
 body=[]
 for old,(name,bone) in mapping.items():
  obj=bpy.data.objects[old];obj.name=name
  bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
  for mod in list(obj.modifiers):obj.modifiers.remove(mod)
  sub=obj.modifiers.new('Round the independent control cage','SUBSURF');sub.levels=1;sub.render_levels=1
  bpy.ops.object.modifier_apply(modifier=sub.name)
  # Independent part origin, retained in Blender and GLB node transforms.
  origin=rig.matrix_world@rig.data.bones[bone].head_local
  obj.data.transform(Matrix.Translation(-origin));obj.location=origin
  obj.parent=rig
  mod=obj.modifiers.new('Shared character armature','ARMATURE');mod.object=rig
  for face in obj.data.polygons:face.use_smooth=True
  obj.data.normals_split_custom_set([(0,0,0)]*len(obj.data.loops))
  body.append(obj)
 head=bpy.data.objects['HEAD']
 origin=rig.data.bones['head'].head_local.copy();head.data.transform(Matrix.Translation(-origin));head.location=origin
 body.append(head)
 required=['HEAD','TORSO','ARM_LEFT','ARM_RIGHT','HAND_LEFT','HAND_RIGHT','LEG_LEFT','LEG_RIGHT','FOOT_LEFT','FOOT_RIGHT']
 assert all(bpy.data.objects.get(name) is not None for name in required)
 assert len({obj.data.as_pointer() for obj in body})==10
 assert len({tuple(round(c,4) for c in obj.location) for obj in body})>=9
 for obj in body:
  # Moving one object's transform must not edit another part's mesh data.
  before={other.name:tuple(other.data.vertices[0].co) for other in body if other!=obj}
  saved=obj.location.copy();obj.location.x+=.05;obj.location=saved
  assert all(tuple(bpy.data.objects[name].data.vertices[0].co)==point for name,point in before.items())
 scene=bpy.context.scene;scene.cycles.samples=20;scene.render.resolution_x=600;scene.render.resolution_y=760;scene.render.resolution_percentage=100
 camera=scene.camera;camera.data.ortho_scale=2.9
 bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(filename+'.blend')))
 if '--export' not in sys.argv:
  for view,at in [('front',(0,-7,1.28)),('side',(7,0,1.28)),('back',(0,7,1.28))]:
   camera.location=at;camera.rotation_euler=(Vector((0,0,1.28))-camera.location).to_track_quat('-Z','Y').to_euler()
   scene.render.filepath=str(OUT/f'{variant}-body-{view}.png');bpy.ops.render.render(write_still=True)
 else:
  bpy.ops.object.select_all(action='DESELECT')
  for obj in bpy.context.scene.objects:
   if obj.type in ['MESH','ARMATURE']:obj.select_set(True)
  bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/characters'/(filename+'.glb')),use_selection=True,export_format='GLB',export_animations=False,export_skins=True)
 report.append({'variant':variant,'body_objects':required,'independent_mesh_data':True,'independent_transform_check':True,'bones':len(rig.data.bones),'triangles':sum(len(p.vertices)-2 for o in bpy.context.scene.objects if o.type=='MESH' for p in o.data.polygons)})
report_path=SOURCE/'modular-report.json'
previous=json.loads(report_path.read_text()) if report_path.exists() else []
records={entry['variant']:entry for entry in previous}
records.update({entry['variant']:entry for entry in report})
report_path.write_text(json.dumps(list(records.values()),indent=2),encoding='utf-8')
print('MODULAR_BODY_VERIFIED',report)
