"""Build the reference character. Run in Blender with -- --rig only after static QA."""
import bpy, math, json, sys
from pathlib import Path
from mathutils import Vector
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'artifacts' / 'blender-character'
OUT.mkdir(parents=True, exist_ok=True)
SOURCE = ROOT / 'art' / 'character'
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
PARTS = []
def xyz(p): return (p[0], -p[2], p[1])
def material(name, color):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    shader=m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Roughness'].default_value=1
    shader.inputs['Specular IOR Level'].default_value=0
    return m
WHITE=material('Matte chalk',(.79,.80,.80)); BLACK=material('Matte charcoal',(.018,.021,.023))
def mesh(name, verts, faces, mat, bone='body'):
    data=bpy.data.meshes.new(name); data.from_pydata([xyz(p) for p in verts],[],faces); data.update()
    obj=bpy.data.objects.new(name,data); bpy.context.collection.objects.link(obj); obj.data.materials.append(mat)
    # Recalculate outward normals consistently for custom rings and accessory tubes.
    bpy.context.view_layer.objects.active=obj; obj.select_set(True)
    bpy.ops.object.mode_set(mode='EDIT'); bpy.ops.mesh.select_all(action='SELECT'); bpy.ops.mesh.normals_make_consistent(inside=False); bpy.ops.object.mode_set(mode='OBJECT'); obj.select_set(False)
    obj['bind_bone']=bone; PARTS.append(obj); return obj

def rings(name, sections, mat, center=(0,0,0), segments=14, bone='body', irregular=.0):
    """Sections are height, x radius, depth radius, x drift, forward drift."""
    verts=[]; faces=[]
    for j,(y,rx,rz,dx,dz) in enumerate(sections):
        for i in range(segments):
            a=2*math.pi*i/segments
            wobble=1+irregular*math.sin(i*2.7+j*.9)
            verts.append((center[0]+dx+rx*math.cos(a)*wobble,center[1]+y,center[2]+dz+rz*math.sin(a)*wobble))
    for row in range(len(sections)-1):
        for i in range(segments):
            n=(i+1)%segments; k=row*segments
            faces.append((k+i,k+n,k+segments+n,k+segments+i))
    faces.extend([tuple(reversed(range(segments))),tuple((len(sections)-1)*segments+i for i in range(segments))])
    return mesh(name,verts,faces,mat,bone)

def ellipsoid(name,center,size,mat,bone='body',segments=14):
    sections=[]
    for y,rx in [(-.5,.06),(-.44,.27),(-.30,.43),(-.10,.495),(.16,.48),(.35,.37),(.47,.20),(.50,.035)]:
        sections.append((y*size[1],rx*size[0],rx*size[2],0,0))
    return rings(name,sections,mat,center,segments,bone,.015)

# Dimensions are in Godot coordinates: X sideways, Y up, +Z forward.
# The head and torso widths are close; the wide silhouette comes from diagonal arms and mittens.
HEAD=(0,2.145,.015)
head=rings('Head', [(-.34,.025,.045,-.012,.01),(-.315,.115,.115,-.012,.025),(-.265,.205,.185,-.009,.026),(-.17,.273,.237,-.006,.02),(-.025,.317,.277,0,.004),(.13,.325,.282,.006,-.004),(.245,.292,.257,.006,-.01),(.315,.20,.19,0,-.012),(.34,.055,.07,0,-.01)],WHITE,HEAD,16,'head',.025)
torso=rings('Torso',[(1.135,.265,.185,0,0),(1.165,.335,.215,-.008,0),(1.36,.348,.235,.009,.01),(1.60,.343,.225,-.006,0),(1.755,.295,.196,0,0),(1.855,.185,.14,.008,0),(1.88,.09,.09,0,0)],WHITE,segments=14,irregular=.018)

# A single continuous crown and curtain; its lower front is open for the face.
verts=[]; faces=[]; N=20
hairrows=[(-.54,.312,.305,-.115),(-.26,.34,.32,-.070),(.055,.355,.35,-.018),(.245,.322,.315,-.012),(.355,.205,.20,-.02),(.395,.055,.065,-.02)]
for j,(h,rx,rz,zoff) in enumerate(hairrows):
    for i in range(N):
        a=i*2*math.pi/N; front=max(0,math.sin(a))
        # Front row sits at an uneven brow; back row continues down to the shoulders.
        y=h
        if j==0 and front>.12: y=.175+.023*math.sin(i*1.9)+.014*math.cos(i*.8)
        if j==1 and front>.12: y=.20+.022*math.sin(i*1.9)
        if j==2 and front>.12: y=.235+.012*math.sin(i*1.9)
        if j==3 and front>.12: y=.285+.008*math.sin(i*1.9)
        if j==0 and front<=.12: y+=.022*math.sin(i*2.1)+.012*math.cos(i*.7)
        verts.append((HEAD[0]+rx*math.cos(a),HEAD[1]+y,HEAD[2]+zoff+rz*math.sin(a)))
for row in range(len(hairrows)-1):
    for i in range(N):
        k=row*N; n=(i+1)%N;faces.append((k+i,k+n,k+N+n,k+N+i))
faces.append(tuple((len(hairrows)-1)*N+i for i in range(N)))
hair=mesh('Hair crown and curtain',verts,faces,BLACK,'head')
# Small side locks are tapered polygons following the face, not rectangular slabs.
for side in (-1,1):
    rings('Temple lock '+str(side),[(-.19,.025,.028,0,0),(-.10,.04,.055,0,0),(.15,.047,.066,0,0),(.21,.025,.04,0,0)],BLACK,(side*.303,HEAD[1],.16),10,'head')

for side,label in [(-1,'L'),(1,'R')]:
    shoulder=(side*.285,1.77,0)
    # Hand/arm centerline travels diagonally outward; a gentle depth shift avoids a ruler-straight side view.
    arm=rings('Arm '+label,[(.025,.025,.03,0,0),(-.025,.095,.10,side*.01,0),(-.07,.125,.125,side*.025,0),(-.29,.115,.118,side*.115,.008),(-.49,.103,.106,side*.205,.012),(-.67,.088,.095,side*.275,.018),(-.72,.065,.07,side*.29,.018)],WHITE,shoulder,12,'arm_'+label,.02)
    wrist=(side*.58,1.075,.018)
    mitten=ellipsoid('Mitten '+label,wrist,(.43,.27,.36),WHITE,'hand_'+label,14)
    # Rotate vertices about the wrist, keeping object transforms clean for skinning.
    for vertex in mitten.data.vertices:
        px=vertex.co.x-wrist[0]; pz=vertex.co.z-wrist[1]; angle=-side*.30
        vertex.co.x=wrist[0]+px*math.cos(angle)-pz*math.sin(angle)
        vertex.co.z=wrist[1]+px*math.sin(angle)+pz*math.cos(angle)
    hip=(side*.18,1.205,0)
    leg=rings('Leg '+label,[(.04,.12,.14,0,0),(-.035,.165,.172,0,0),(-.24,.16,.165,side*.004,.005),(-.49,.148,.155,side*.009,.007),(-.74,.133,.143,side*.014,.01),(-.95,.119,.128,side*.018,.015),(-1.025,.098,.11,side*.02,.019)],WHITE,hip,14,'thigh_'+label,.01)
    ellipsoid('Foot '+label,(side*.20,.115,.085),(.30,.22,.43),WHITE,'foot_'+label,14)
    # Tiny dot eyes, with thin black round frames fitted to the rounded face.
    eye=(side*.143,2.165,.292)
    ellipsoid('Eye '+label,eye,(.094,.094,.018),BLACK,'head',14)
    verts=[]; faces=[]
    for i in range(32):
        a=i*math.tau/32
        for j in range(6):
            b=j*math.tau/6; r=.103+.009*math.cos(b)
            verts.append((side*.143+r*math.cos(a),2.165+r*math.sin(a),.309+.009*math.sin(b)))
    for i in range(32):
        for j in range(6): faces.append((i*6+j,i*6+(j+1)%6,((i+1)%32)*6+(j+1)%6,((i+1)%32)*6+j))
    mesh('Glasses rim '+label,verts,faces,BLACK,'head')
# The bridge uses custom vertices; it sits above the eyes rather than obscuring them.
mesh('Glasses bridge',[(-.041,2.166,.308),(.041,2.166,.308),(.041,2.182,.308),(-.041,2.182,.308),(-.041,2.166,.321),(.041,2.166,.321),(.041,2.182,.321),(-.041,2.182,.321)],[(0,1,2,3),(4,7,6,5),(0,4,5,1),(3,2,6,7),(0,3,7,4),(1,5,6,2)],BLACK,'head')

# Static validation scene, excluded from the runtime export.
scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=16
scene.render.resolution_x=650;scene.render.resolution_y=800;scene.render.resolution_percentage=100
scene.world.color=(.16,.16,.16)
scene.view_settings.view_transform='Standard';scene.view_settings.look='None'
scene.view_settings.exposure=0;scene.view_settings.gamma=1
scene.render.image_settings.file_format='PNG';scene.render.film_transparent=True
scene.world.use_nodes=True;scene.world.node_tree.nodes['Background'].inputs[0].default_value=(.075,.082,.09,1);scene.world.node_tree.nodes['Background'].inputs[1].default_value=.6
for name,location,power,size in [('Key',(-3,-4,6),350,5),('Fill',(3,-1,4),200,5),('Back fill',(0,4,5),300,5)]:
    light=bpy.data.lights.new(name,'AREA');light.energy=power;light.shape='DISK';light.size=size
    obj=bpy.data.objects.new(name,light);bpy.context.collection.objects.link(obj);obj.location=location;obj.rotation_euler=(Vector(xyz((0,1.3,0)))-obj.location).to_track_quat('-Z','Y').to_euler()
cam_data=bpy.data.cameras.new('Three-view camera');cam=bpy.data.objects.new('Three-view camera',cam_data);bpy.context.collection.objects.link(cam);scene.camera=cam;cam_data.type='ORTHO';cam_data.ortho_scale=2.85
cam.location=(0,-7,1.28);cam.rotation_euler=(Vector((0,0,1.28))-cam.location).to_track_quat('-Z','Y').to_euler()
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'reference_character.blend'))
if '--skip-render' not in sys.argv:
    for name,location in [('front',(0,-7,1.28)),('side',(7,0,1.28)),('back',(0,7,1.28))]:
        cam.location=location;cam.rotation_euler=(Vector((0,0,1.28))-cam.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(OUT/(name+'.png'));bpy.ops.render.render(write_still=True)
# Static GLB is only a review artifact. It is not integrated into the game.
bpy.ops.object.select_all(action='DESELECT')
for obj in PARTS: obj.select_set(True)
bpy.ops.export_scene.gltf(filepath=str(OUT/'static_character.glb'),use_selection=True,export_format='GLB',export_animations=False)
triangles=sum(sum(len(p.vertices)-2 for p in obj.data.polygons) for obj in PARTS)
(OUT/'model-report.json').write_text(json.dumps({'stage':'static','mesh_objects':len(PARTS),'triangles':triangles,'height':2.54},indent=2),encoding='utf-8')
print('STATIC_CHARACTER_READY',triangles,'triangles')


if '--rig' in sys.argv:
    # The static review is deliberately separate from rigging/export.
    if not (SOURCE/'STATIC_REVIEW.md').exists():
        raise RuntimeError('Review the three static renders before rigging.')
    bpy.ops.object.select_all(action='DESELECT')
    armature=bpy.data.armatures.new('Reference character armature')
    rig=bpy.data.objects.new('CharacterRig',armature);bpy.context.collection.objects.link(rig)
    bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
    def bone(name,head,tail,parent=None):
        b=armature.edit_bones.new(name);b.head=xyz(head);b.tail=xyz(tail)
        if parent: b.parent=armature.edit_bones[parent]
        b.use_deform=True
    bone('root',(0,0,0),(0,.2,0))
    bone('body',(0,1.14,0),(0,1.80,0),'root')
    bone('head',HEAD,(0,2.48,.015),'body')
    for side,label in [(-1,'L'),(1,'R')]:
        shoulder=(side*.285,1.77,0);elbow=(side*.425,1.425,.008);wrist=(side*.58,1.075,.018)
        bone('arm_'+label,shoulder,elbow,'body')
        bone('forearm_'+label,elbow,wrist,'arm_'+label)
        bone('hand_'+label,wrist,(side*.58,.95,.018),'forearm_'+label)
        hip=(side*.18,1.205,0);knee=(side*.189,.715,.007);ankle=(side*.20,.18,.019)
        bone('thigh_'+label,hip,knee,'root')
        bone('calf_'+label,knee,ankle,'thigh_'+label)
        bone('foot_'+label,ankle,(side*.20,.10,.26),'calf_'+label)
    bpy.ops.object.mode_set(mode='OBJECT');rig.select_set(False)
    def smooth(a,b,x):
        t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)
    for obj in PARTS:
        target=obj['bind_bone'];groups={target:obj.vertex_groups.new(name=target)}
        lower=None;joint=0
        if target.startswith('arm_'): lower=target.replace('arm_','forearm_');joint=1.425
        if target.startswith('thigh_'): lower=target.replace('thigh_','calf_');joint=.715
        if lower: groups[lower]=obj.vertex_groups.new(name=lower)
        for v in obj.data.vertices:
            weight=1-smooth(joint-.10,joint+.10,v.co.z) if lower else 0
            if weight<1:groups[target].add([v.index],1-weight,'REPLACE')
            if weight>0:groups[lower].add([v.index],weight,'REPLACE')
        mod=obj.modifiers.new('Character skin','ARMATURE');mod.object=rig
        obj.parent=rig
    bpy.context.view_layer.objects.active=rig
    bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/'reference_character.blend'))
    # Join copies for runtime; editable source objects stay separate in the .blend.
    copies=[]
    bpy.ops.object.select_all(action='DESELECT')
    for obj in PARTS:
        duplicate=obj.copy();duplicate.data=obj.data.copy();bpy.context.collection.objects.link(duplicate)
        duplicate.select_set(True);copies.append(duplicate)
    bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();runtime=bpy.context.object;runtime.name='CharacterMesh'
    rig.select_set(True)
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets'/'characters'/'reference_character.glb'),use_selection=True,export_format='GLB',export_animations=False,export_skins=True,export_materials='EXPORT')
    report={'stage':'rigged','bones':len(armature.bones),'triangles':triangles,'materials':2,'textures':0}
    (SOURCE/'model-report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('RIGGED_CHARACTER_EXPORTED',report)
