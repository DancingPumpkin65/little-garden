"""A compact Blender-authored vegetation library with cohesive rounded silhouettes."""
import bpy, bmesh, math, sys, json
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[2];OUT=ROOT/'artifacts/vegetation-review';OUT.mkdir(parents=True,exist_ok=True)
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
def v(p):return Vector((p[0],-p[2],p[1]))
def mat(name,color):
 m=bpy.data.materials.new(name);m.diffuse_color=(*color,1);m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Base Color'].default_value=(*color,1);bs.inputs['Roughness'].default_value=1;bs.inputs['Specular IOR Level'].default_value=0
 return m
bark=mat('Matte warm bark',(.30,.18,.12));green=mat('Leaf green',(.22,.50,.28));pink=mat('Plum blossom pink',(.87,.43,.65));white=mat('Petal ivory',(.94,.94,.87))
def mesh(name,verts,faces,material):
 data=bpy.data.meshes.new(name);data.from_pydata([v(p) for p in verts],[],faces);data.update()
 obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);data.materials.append(material)
 bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
 for face in data.polygons:face.use_smooth=True
 return obj
def blob(name,center,size,material,seed=0):
 verts=[];faces=[];N=16;M=10
 for row in range(M+1):
  lat=-math.pi/2+row*math.pi/M
  for i in range(N):
   a=i*math.tau/N;w=1+.045*math.sin(a*3+seed)*math.cos(lat)+.025*math.sin(a*2+lat*3+seed)
   verts.append((center[0]+size[0]*.5*math.cos(lat)*math.cos(a)*w,center[1]+size[1]*.5*math.sin(lat),center[2]+size[2]*.5*math.cos(lat)*math.sin(a)*w))
 for row in range(M):
  for i in range(N):
   a=row*N+i;b=row*N+(i+1)%N;faces.append((a,b,b+N,a+N))
 return mesh(name,verts,faces,material)
def canopy(name,lobes,material):
 objects=[blob(name+str(i),at,size,material,i*.7) for i,(at,size) in enumerate(lobes)]
 bpy.ops.object.select_all(action='DESELECT')
 for obj in objects:obj.select_set(True)
 bpy.context.view_layer.objects.active=objects[0];bpy.ops.object.join();obj=bpy.context.object;obj.name=name
 remesh=obj.modifiers.new('Cohesive foliage mass','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.024
 bpy.ops.object.modifier_apply(modifier=remesh.name)
 smooth=obj.modifiers.new('Round canopy outline','SMOOTH');smooth.factor=.7;smooth.iterations=4
 bpy.ops.object.modifier_apply(modifier=smooth.name)
 total=sum(len(p.vertices)-2 for p in obj.data.polygons)
 dec=obj.modifiers.new('Simple canopy control surface','DECIMATE');dec.ratio=min(1,500/total)
 bpy.ops.object.modifier_apply(modifier=dec.name)
 sub=obj.modifiers.new('One level soft silhouette','SUBSURF');sub.levels=1
 bpy.ops.object.modifier_apply(modifier=sub.name)
 for face in obj.data.polygons:face.use_smooth=True
 return obj
def wood(name,twist=False):
 points=[(0,0,0),(-.025,.12,.015),(-.07 if twist else .015,.28,.01),(.035,.43,-.015),(.02,.60,0)]
 radii=[.055,.05,.04,.032,.019];edges=[(i,i+1) for i in range(4)]
 for i in range(0 if name.startswith("Evergreen") else 5):
  a=i*2.399963;start=2+i%2;index=len(points)
  points.extend([(math.cos(a)*.15,.55+i%2*.10,math.sin(a)*.15),(math.cos(a)*.30,.68+i%3*.04,math.sin(a)*.25)])
  edges.extend([(start,index),(index,index+1)]);radii.extend([.022,.008])
 data=bpy.data.meshes.new(name);data.from_pydata([v(p) for p in points],edges,[]);data.update()
 obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);data.materials.append(bark)
 bpy.context.view_layer.objects.active=obj;obj.select_set(True)
 skin=obj.modifiers.new('Organic branching junctions','SKIN')
 for i,r in enumerate(radii):data.skin_vertices[0].data[i].radius=(r,r*.9)
 data.skin_vertices[0].data[0].use_root=True
 sub=obj.modifiers.new('Rounded branching control cage','SUBSURF');sub.levels=2
 bpy.ops.object.modifier_apply(modifier=skin.name);bpy.ops.object.modifier_apply(modifier=sub.name)
 # Relax the branching surface so fork junctions read as one organic trunk.
 remesh=obj.modifiers.new('Connected branch junctions','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.012
 bpy.ops.object.modifier_apply(modifier=remesh.name)
 relax=obj.modifiers.new('Soften branch forks','SMOOTH');relax.factor=.65;relax.iterations=4
 bpy.ops.object.modifier_apply(modifier=relax.name)
 count=sum(len(face.vertices)-2 for face in obj.data.polygons)
 dec=obj.modifiers.new('Compact branch mesh','DECIMATE');dec.ratio=min(1,700/count)
 bpy.ops.object.modifier_apply(modifier=dec.name)
 sub=obj.modifiers.new('One level rounded branch outline','SUBSURF');sub.levels=1
 bpy.ops.object.modifier_apply(modifier=sub.name)
 for face in obj.data.polygons:face.use_smooth=True
 obj.select_set(False)
 return obj
assets=[]
for name,lobes in [
 ('Oak',[((-.18,.70,0),(.60,.43,.63)),((.16,.81,.04),(.67,.46,.62)),((.05,.67,-.17),(.65,.43,.55))]),
 ('Plum',[((-.25,.66,.02),(.68,.42,.67)),((.14,.80,-.04),(.75,.48,.69)),((.34,.63,.04),(.55,.42,.59)),((-.39,.53,.08),(.38,.38,.43))]),
 ('Willow',[((-.18,.65,0),(.57,.60,.64)),((.15,.71,.02),(.64,.58,.66)),((.03,.50,-.15),(.62,.46,.48))])]:
 assets.extend([wood(name+'Wood',name=='Plum'),canopy(name+'Crown',lobes,pink if name=='Plum' else green)])
# A rounded, gently stepped evergreen rather than stacked sharp cones.
verts=[];faces=[];profiles=[(.24,.03),(.29,.25),(.33,.28),(.39,.24),(.43,.19),(.46,.23),(.51,.22),(.58,.15),(.62,.19),(.68,.15),(.77,.10),(.87,.035),(.90,.008)]
for row,(y,r) in enumerate(profiles):
 for i in range(16):
  a=i*math.tau/16;radius=r*(1+.04*math.sin(a*3+row*.4));verts.append((math.cos(a)*radius,y,math.sin(a)*radius))
for row in range(len(profiles)-1):
 for i in range(16):a=row*16+i;b=row*16+(i+1)%16;faces.append((a,b,b+16,a+16))
faces.extend([tuple(reversed(range(16))),tuple((len(profiles)-1)*16+i for i in range(16))])
ever=mesh('EvergreenCrown',verts,faces,green);bpy.context.view_layer.objects.active=ever
sub=ever.modifiers.new('Round tier edges','SUBSURF');sub.levels=1;bpy.ops.object.modifier_apply(modifier=sub.name)
assets.extend([wood('EvergreenWood'),ever])
assets.append(canopy('Bush',[((-.20,.22,0),(.62,.46,.58)),((.12,.30,.02),(.72,.59,.64)),((.35,.20,.03),(.44,.39,.46))],green))
assets.append(blob('Lobe',(0,0,0),(1,1,1),white))
assets.append(blob('Petal',(0,0,0),(1,1,1),white,1.7))
# A broad leaf with tapered tips, a raised midrib and actual thickness.
verts=[];faces=[]
for row in range(9):
 t=row/8;w=max(.005,math.sin(t*math.pi)**.8)
 for i in range(12):
  a=i*math.tau/12;verts.append(((t-.5),math.sin(a)*w*.08+.05*math.sin(t*math.pi),math.cos(a)*w*.32))
for row in range(8):
 for i in range(12):a=row*12+i;b=row*12+(i+1)%12;faces.append((a,b,b+12,a+12))
assets.append(mesh('Leaf',verts,faces,green))
verts=[];faces=[]
for row in range(9):
 t=row/8
 for i in range(12):
  a=i*math.tau/12;verts.append((math.sin(t*1.4)*.07+math.cos(a)*.025,t,math.sin(a)*.025))
for row in range(8):
 for i in range(12):a=row*12+i;b=row*12+(i+1)%12;faces.append((a,b,b+12,a+12))
assets.append(mesh('Stem',verts,faces,green))
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=24;scene.render.resolution_x=760;scene.render.resolution_y=760;scene.render.resolution_percentage=100
scene.world.color=(.25,.25,.25)
for at,power,size in [((2,-3,4),450,4),((-3,-1,2),180,3)]:
 data=bpy.data.lights.new('Softbox','AREA');data.energy=power;data.shape='DISK';data.size=size
 obj=bpy.data.objects.new('Softbox',data);bpy.context.collection.objects.link(obj);obj.location=at;obj.rotation_euler=(Vector((0,0,.5))-obj.location).to_track_quat('-Z','Y').to_euler()
data=bpy.data.cameras.new('Review camera');camera=bpy.data.objects.new('Review camera',data);bpy.context.collection.objects.link(camera);scene.camera=camera;camera.data.type='ORTHO';camera.data.ortho_scale=1.25
camera.location=(1.4,-2.5,1.2);camera.rotation_euler=(Vector((0,0,.48))-camera.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.wm.save_as_mainfile(filepath=str(ROOT/'art/vegetation/rounded_library.blend'))
if '--export' not in sys.argv:
 for master in ['Oak','Plum','Willow','Evergreen','Bush','Leaf']:
  for obj in assets:obj.hide_render=not (obj.name.startswith(master))
  scene.render.filepath=str(OUT/(master+'.png'));bpy.ops.render.render(write_still=True)
else:
 bpy.ops.object.select_all(action='DESELECT')
 for obj in assets:obj.hide_render=False;obj.select_set(True)
 (ROOT/'assets/vegetation').mkdir(exist_ok=True)
 bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets/vegetation/rounded_library.glb'),use_selection=True,export_format='GLB',export_animations=False)
print('VEGETATION_LIBRARY',[(obj.name,sum(len(p.vertices)-2 for p in obj.data.polygons)) for obj in assets])
