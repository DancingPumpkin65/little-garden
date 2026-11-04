"""Separate tailored low-poly garments fitted to the existing character and rig."""
import bpy, math, sys
from pathlib import Path
from mathutils import Vector
sys.path.insert(0,str(Path(__file__).resolve().parent))
from static_shapes import torso
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'artifacts'/'wardrobe';OUT.mkdir(parents=True,exist_ok=True)
def v(p):return Vector((p[0],-p[2],p[1]))
def material(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=1
 return m

def striped_knit():
 m=material('Pastel lilac and blue striped knit',(1,1,1))
 image=bpy.data.images.new('Pastel sweater bands',width=8,height=64)
 colors=[(.67,.81,.88,1),(.77,.65,.80,1)]
 image.pixels=[channel for y in range(64) for x in range(8) for channel in colors[0 if y<32 else 1]]
 image.pack()
 texture=m.node_tree.nodes.new('ShaderNodeTexImage');texture.image=image;texture.interpolation='Linear';texture.extension='REPEAT'
 m.node_tree.links.new(texture.outputs['Color'],m.node_tree.nodes.get('Principled BSDF').inputs['Base Color'])
 return m
def shell(name,profiles,mat,axis=None):
 verts=[];faces=[];N=12
 for row,(center,rx,rz) in enumerate(profiles):
  for i in range(N):
   a=i*math.tau/N;w=1+.018*math.sin(i*2.3+row*.8)
   p=Vector(center)
   if axis is None:p+=Vector((rx*math.cos(a)*w,0,rz*math.sin(a)*w))
   else:p+=axis[0]*rx*math.cos(a)*w+axis[1]*rz*math.sin(a)*w
   # Shallow compression folds break the cloth plane without inflating the body.
   if 'sleeve' in name or 'trouser' in name:
    p+=Vector((0,.008*math.sin(a*2+row*.7) if row not in (0,len(profiles)-1) else 0,.007*math.sin(row*2.1+i*.9)*math.sin(a)**2))
   verts.append(v(p))
 for row in range(len(profiles)-1):
  for i in range(N):
   a=row*N+i;b=row*N+(i+1)%N;c=b+N;d=a+N
   faces.append((a,b,c,d))
 # Rolled openings retain real thickness rather than a painted edge.
 for row,sign in [(0,1),(len(profiles)-1,-1)]:
  center=v(profiles[row][0]);start=len(verts)
  for i in range(N):verts.append(center+(verts[row*N+i]-center)*.88)
  for i in range(N):faces.append((row*N+i,start+i,start+(i+1)%N,row*N+(i+1)%N))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(verts,[],faces);mesh.update()
 obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj);mesh.materials.append(mat)
 return obj

variants=['girl'] if '--girl' in sys.argv else ['guy'] if '--guy' in sys.argv else ['girl','guy']
for variant in variants:
 bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/character'/('reference_character.blend' if variant=='girl' else 'companion_character.blend')))
 rig=bpy.data.objects['CharacterRig']
 required=['HEAD','TORSO','ARM_LEFT','ARM_RIGHT','HAND_LEFT','HAND_RIGHT','LEG_LEFT','LEG_RIGHT','FOOT_LEFT','FOOT_RIGHT']
 assert all(bpy.data.objects.get(name) is not None for name in required), 'Verify ten independent body objects before adding garments'
 body_parts=[bpy.data.objects[name] for name in required if name!='HEAD']
 top=striped_knit() if variant=='girl' else material('Sunflower yellow cotton',(.88,.60,.075))
 trim=material('Soft knitted cuffs',(.48,.61,.73) if variant=='girl' else (.80,.50,.05))
 pants=material('Charcoal loose trousers' if variant=='girl' else 'Lavender blue trousers',(.022,.026,.034) if variant=='girl' else (.34,.44,.68))
 garments=[]
 # Compact torso, soft shoulders and fuller forearms follow the supplied sweater references.
 garments.append(shell('Sweater',[( (0,y,0),rx,rz) for y,rx,rz in [(1.02,.32,.225),(1.045,.33,.235),(1.11,.335,.24),(1.31,.325,.238),(1.52,.35,.25),(1.70,.345,.245),(1.76,.29,.22),(1.79,.155,.14)]],top))
 garments.append(shell('Sweater hem',[( (0,y,0),rx,rz) for y,rx,rz in [(1.025,.325,.228),(1.05,.331,.237),(1.085,.334,.242)]],trim))
 garments.append(shell('Collar',[( (0,y,0),.157,.14) for y in [1.81,1.85,1.875]],trim))
 for side,label in [(-1,'L'),(1,'R')]:
  shoulder=Vector((side*.285,1.77,0));wrist=Vector((side*.70,1.075,.018));direction=(wrist-shoulder).normalized()
  cross=Vector((0,0,1));other=direction.cross(cross).normalized()
  profiles=[]
  sleeve_profile=[(-.13,.11),(0,.16),(.15,.177),(.34,.182),(.53,.188),(.68,.185),(.82,.164),(.93,.126),(1,.112)] if variant=='girl' else [(-.13,.11),(0,.16),(.12,.18),(.29,.183),(.43,.184),(.46,.183)]
  for t,r in sleeve_profile:profiles.append((shoulder.lerp(wrist,t),r,r*.95))
  garments.append(shell('Puffed sleeve '+label,profiles,top,(other,cross)))
  cuff_profile=[(shoulder.lerp(wrist,t),.125,.12) for t in [.94,1,1.025]] if variant=='girl' else [(shoulder.lerp(wrist,t),.184,.175) for t in [.425,.45,.47]]
  garments.append(shell('Sleeve cuff '+label,cuff_profile,trim,(other,cross)))
  profiles=[]
  for y,rx,rz in [(.19,.123,.135),(.26,.153,.17),(.43,.167,.19),(.61,.17,.195),(.77,.162,.19),(.94,.164,.20),(1.1,.12,.14),(1.20,.10,.10)]:
   profiles.append(((side*(.20-(y-.19)*.020),y,0),rx,rz))
  garments.append(shell('Baggy trouser '+label,profiles,pants))
  garments.append(shell('Trouser cuff '+label,[((side*.20,y,0),.132,.145) for y in [.185,.22,.26]],pants if variant=='girl' else material('Red shoe collar '+label,(.76,.10,.12))))
 # Match the body design changes on each garment control cage before subdivision.
 def height(y):
  if y<=.18:return y*.9
  if y<=1.205:return .162+(y-.18)*(.958/1.025)
  return 1.12+(y-1.205)*(.62/.675)
 for obj in garments:
  for vert in obj.data.vertices:
   point=Vector((vert.co.x,vert.co.z,-vert.co.y))
   if obj.name in ['Sweater','Sweater hem','Collar']:
    point.x*=1.06;point.z*=1.025;point.y=1.74-(1.74-height(point.y))*.90
    if obj.name=='Collar':point.y-=.13
   elif 'sleeve' in obj.name or 'Sleeve cuff' in obj.name:
    side=-1 if obj.name.endswith('L') else 1;t=max(0,min(1,(1.77-point.y)/.695));center=side*(.285+.415*t)
    point.x=center+(point.x-center)*1.035+side*(.03*t+.016*math.sin(t*math.pi));point.z+=.025*math.sin(t*math.pi);point.y=height(point.y)
   else:
    side=-1 if obj.name.endswith('L') else 1;t=max(0,min(1,(1.205-point.y)/1.025));center=side*(.18+.02*t)
    point.x=center+(point.x-center)*1.06+side*.012*math.sin(t*math.pi);point.z*=1.05;point.y=height(point.y)
   if obj.name in ['Sweater','Sweater hem']:point=torso(point)
   vert.co=v(point)
 # UV bands wrap the real sweater surfaces and remain attached during skinning.
 if variant=='girl':
  for obj in garments:
   if obj.name=='Sweater' or obj.name.startswith('Puffed sleeve'):
    uv=obj.data.uv_layers.new(name='Knit bands')
    for loop in obj.data.loops:
     point=obj.data.vertices[loop.vertex_index].co
     uv.data[loop.index].uv=(.5,(point.z-1.02)/.27)
 # Keep every garment independent. One subdivision level shapes the actual silhouette.
 for obj in garments:
  bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
  sub=obj.modifiers.new('Round independent garment control cage','SUBSURF');sub.levels=1;sub.render_levels=1
  bpy.ops.object.modifier_apply(modifier=sub.name)
 names={'Sweater':'SWEATER_TORSO','Puffed sleeve L':'SWEATER_SLEEVE_LEFT','Puffed sleeve R':'SWEATER_SLEEVE_RIGHT','Baggy trouser L':'PANTS_LEFT','Baggy trouser R':'PANTS_RIGHT','Sweater hem':'WAISTBAND','Collar':'COLLAR','Sleeve cuff L':'CUFF_LEFT','Sleeve cuff R':'CUFF_RIGHT','Trouser cuff L':'PANTS_CUFF_LEFT','Trouser cuff R':'PANTS_CUFF_RIGHT'}
 for obj in garments:obj.name=names.get(obj.name,obj.name)
 for side,label in [(-1,'LEFT'),(1,'RIGHT')]:
  source=bpy.data.objects['FOOT_'+label]
  center=sum((source.matrix_world@vertex.co for vertex in source.data.vertices),Vector())/len(source.data.vertices);verts=[]
  for vertex in source.data.vertices:
   point=source.matrix_world@vertex.co
   point=center+Vector(((point-center).x*1.035,(point-center).y*1.035,(point-center).z*1.04))
   point.z=max(.008,point.z)
   verts.append(point)
  data=bpy.data.meshes.new('SHOES_'+label);data.from_pydata(verts,[],[tuple(face.vertices) for face in source.data.polygons]);data.update()
  shoe=bpy.data.objects.new('SHOES_'+label,data);bpy.context.collection.objects.link(shoe)
  data.materials.append(material('Shoe upper '+label,(.045,.05,.06) if variant=='girl' else (.76,.10,.12)))
  data.materials.append(material('Shoe sole and toe '+label,(.10,.12,.14) if variant=='girl' else (.88,.88,.86)))
  for face in data.polygons:
   sole=sum(data.vertices[index].co.z for index in face.vertices)/len(face.vertices)<.055
   toe=-sum(data.vertices[index].co.y for index in face.vertices)/len(face.vertices)>.22
   if sole or (variant=='guy' and toe):face.material_index=1
  garments.append(shoe)
 if variant=='guy':
  # Only the exposed forearm is part of this short-sleeved outfit. Keeping the
  # whole upper arm visible would poke through the sleeve at the shoulder.
  for side,label in [(-1,'LEFT'),(1,'RIGHT')]:
   source=bpy.data.objects['ARM_'+label]
   verts=[source.matrix_world@vertex.co for vertex in source.data.vertices]
   faces=[tuple(face.vertices) for face in source.data.polygons if sum(verts[i].z for i in face.vertices)/len(face.vertices)<1.43]
   data=bpy.data.meshes.new('BARE_FOREARM_'+label);data.from_pydata(verts,[],faces);data.update()
   forearm=bpy.data.objects.new('BARE_FOREARM_'+label,data);bpy.context.collection.objects.link(forearm)
   data.materials.append(source.data.materials[0]);garments.append(forearm)
 # Per-module weights prevent hands or thighs from dragging the sweater's torso.
 for obj in garments:
  groups={name:obj.vertex_groups.new(name=name) for name in rig.data.bones.keys()}
  for vert in obj.data.vertices:
   y=vert.co.z;label='L' if 'LEFT' in obj.name else 'R'
   if obj.name.startswith('SWEATER_SLEEVE') or obj.name.startswith('CUFF_') or obj.name.startswith('BARE_FOREARM'):
    joint=rig.data.bones['forearm_'+label].head_local.z
    t=max(0,min(1,(joint+.12-y)/.24));t=t*t*(3-2*t)
    weights={'arm_'+label:1-t,'forearm_'+label:t}
   elif obj.name.startswith('PANTS'):
    joint=rig.data.bones['calf_'+label].head_local.z
    t=max(0,min(1,(joint+.12-y)/.24));t=t*t*(3-2*t)
    weights={'thigh_'+label:1-t,'calf_'+label:t}
   elif obj.name.startswith('SHOES'):weights={'foot_'+label:1}
   else:weights={'body':1}
   for name,value in weights.items():
    if value>0:groups[name].add([vert.index],value,'REPLACE')
  obj.parent=rig;mod=obj.modifiers.new('Existing character armature','ARMATURE');mod.object=rig
  for face in obj.data.polygons:face.use_smooth=True
  obj.data.update()
  normals=[None]*len(obj.data.loops)
  for face in obj.data.polygons:
   for loop in face.loop_indices:
    normal=obj.data.vertices[obj.data.loops[loop].vertex_index].normal
    normals[loop]=(normal*.65+face.normal*.35).normalized()
  obj.data.normals_split_custom_set(normals)
 # Hide complete covered modules, preserving the editable reusable body in this source.
 for obj in body_parts:
  if obj.name.startswith(('TORSO','ARM_','LEG_','FOOT_')):obj.hide_render=True
 # Store a local origin for independently editable garment transforms.
 for obj in garments:
  bone='body'
  if 'SLEEVE_LEFT' in obj.name or obj.name in ['CUFF_LEFT','BARE_FOREARM_LEFT']:bone='arm_L'
  elif 'SLEEVE_RIGHT' in obj.name or obj.name in ['CUFF_RIGHT','BARE_FOREARM_RIGHT']:bone='arm_R'
  elif obj.name.startswith('PANTS') and 'LEFT' in obj.name:bone='thigh_L'
  elif obj.name.startswith('PANTS') and 'RIGHT' in obj.name:bone='thigh_R'
  elif obj.name=='SHOES_LEFT':bone='foot_L'
  elif obj.name=='SHOES_RIGHT':bone='foot_R'
  origin=rig.data.bones[bone].head_local.copy()
  from mathutils import Matrix
  obj.data.transform(Matrix.Translation(-origin));obj.location=origin
 assert all(bpy.data.objects.get(name) is not None for name in ['SWEATER_TORSO','SWEATER_SLEEVE_LEFT','SWEATER_SLEEVE_RIGHT','PANTS_LEFT','PANTS_RIGHT','SHOES_LEFT','SHOES_RIGHT'])
 camera=bpy.context.scene.camera;scene=bpy.context.scene;scene.cycles.samples=12;scene.render.resolution_x=550;scene.render.resolution_y=700;scene.render.resolution_percentage=100
 bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/character'/f'{variant}_wardrobe.blend'))
 if '--export' not in sys.argv:
  for view,at in [('front',(0,-7,1.3)),('side',(7,0,1.3)),('back',(0,7,1.3))]:
   camera.location=at;camera.rotation_euler=(Vector((0,0,1.3))-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=3.1
   scene.render.filepath=str(OUT/f'{variant}-{view}.png');bpy.ops.render.render(write_still=True)
 else:
  bpy.ops.object.select_all(action='DESELECT')
  for obj in garments:obj.select_set(True)
  rig.select_set(True)
  bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/characters'/f'{variant}_wardrobe.glb'),use_selection=True,export_format='GLB',export_animations=False,export_skins=True)
 print('WARDROBE',variant,sum(len(p.vertices)-2 for o in garments for p in o.data.polygons))
