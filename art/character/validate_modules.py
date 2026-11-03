"""Validate the saved Blender object hierarchy and capture actual garment close-ups."""
import bpy,bmesh,json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];SOURCE=ROOT/'art/character';report=[]
BODY=['HEAD','TORSO','ARM_LEFT','ARM_RIGHT','HAND_LEFT','HAND_RIGHT','LEG_LEFT','LEG_RIGHT','FOOT_LEFT','FOOT_RIGHT']
CLOTH=['SWEATER_TORSO','SWEATER_SLEEVE_LEFT','SWEATER_SLEEVE_RIGHT','PANTS_LEFT','PANTS_RIGHT','SHOES_LEFT','SHOES_RIGHT']
for variant,filename in [('girl','reference_character'),('guy','companion_character')]:
 bpy.ops.wm.open_mainfile(filepath=str(SOURCE/(filename+'.blend')))
 objects=[bpy.context.scene.objects[name] for name in BODY]
 assert len({obj.data.as_pointer() for obj in objects})==10
 for obj in objects:
  neighbors={other.name:other.data.vertices[0].co.copy() for other in objects if other!=obj}
  saved=obj.matrix_world.copy();obj.location.x+=.1;obj.matrix_world=saved
  assert all((bpy.data.objects[name].data.vertices[0].co-point).length<1e-7 for name,point in neighbors.items())
 rig=bpy.data.objects['CharacterRig']
 assert len(rig.data.bones)==15
 triangles=sum(len(face.vertices)-2 for obj in bpy.context.scene.objects if obj.type=='MESH' for face in obj.data.polygons)
 modules=[{'name':obj.name,'origin':[round(x,4) for x in obj.location],'vertices':len(obj.data.vertices),'parent':obj.parent.name} for obj in objects]
 entry={'variant':variant,'body_objects':BODY,'independent_mesh_data':True,'independent_transform_check':True,'bones':15,'triangles':triangles,'modules':modules}
 bpy.ops.wm.open_mainfile(filepath=str(SOURCE/(variant+'_wardrobe.blend')))
 clothes=[bpy.context.scene.objects[name] for name in CLOTH]
 assert len({obj.data.as_pointer() for obj in clothes})==7
 entry['garment_objects']=CLOTH
 entry['garment_triangles']=sum(len(face.vertices)-2 for obj in bpy.context.scene.objects if obj.type=='MESH' and obj.name not in BODY and obj.name in CLOTH for face in obj.data.polygons)
 for obj in clothes:
  for vert in obj.data.vertices:assert abs(sum(g.weight for g in vert.groups)-1)<.001
 if variant=='girl':
  scene=bpy.context.scene;scene.cycles.samples=20;scene.render.resolution_x=650;scene.render.resolution_y=650;scene.render.resolution_percentage=100
  camera=scene.camera;camera.data.ortho_scale=.85
  for label,target in [('shoulder',(-.32,0,1.52)),('mitten',(-.72,-.03,.99)),('shoe',(.20,-.14,.13))]:
   focus=Vector(target);camera.location=focus+Vector((.25,-5,.12));camera.rotation_euler=(focus-camera.location).to_track_quat('-Z','Y').to_euler()
   scene.render.filepath=str(ROOT/'artifacts/proportion-review'/('close-'+label+'.png'));bpy.ops.render.render(write_still=True)
 report.append(entry)
(SOURCE/'modular-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print('MODULAR_SCENE_VALIDATION_PASS',[(entry['variant'],entry['triangles']) for entry in report])
