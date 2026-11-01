"""Edit the existing rigged Blender meshes; no body regeneration or subdivision."""
import bpy, bmesh, math, sys, json, shutil
from pathlib import Path
from mathutils import Vector
from mathutils.bvhtree import BVHTree
ROOT=Path(__file__).resolve().parents[2]
SOURCE=ROOT/'art'/'character'
BASE=SOURCE/'reference_character_base.blend'
OUT=ROOT/'artifacts'/'sculpt-review';OUT.mkdir(parents=True,exist_ok=True)
if not BASE.exists(): shutil.copyfile(SOURCE/'reference_character.blend',BASE)

def logical(v): return Vector((v.x,v.z,-v.y))
def blender(v): return Vector((v[0],-v[2],v[1]))
def smooth(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)));return t*t*(3-2*t)

def broaden_facets(obj,segments,rows):
    """Dissolve alternating ring edges, retaining the original vertices and deform layer."""
    bm=bmesh.new();bm.from_mesh(obj.data);bm.verts.ensure_lookup_table()
    candidates=[]
    for edge in bm.edges:
        a,b=sorted(v.index for v in edge.verts)
        if a//segments==b//segments and a//segments in rows and a%segments%2==1 and len(edge.link_faces)==2:
            candidates.append(edge)
    bmesh.ops.dissolve_edges(bm,edges=candidates,use_verts=False,use_face_split=False)
    bm.to_mesh(obj.data);bm.free();obj.data.update()

def sculpt_body():
    # Edit the original vertex rings; alternate angles and heights break the lathe-like bands.
    for obj in list(bpy.data.objects):
        if obj.type!='MESH': continue
        name=obj.name
        if name=='Head':
            sections=[(-.345,.025,.045),(-.315,.105,.11),(-.255,.205,.188),(-.145,.282,.245),(.012,.329,.292),(.155,.326,.285),(.26,.28,.255),(.325,.175,.17),(.35,.035,.05)]
            for v in obj.data.vertices:
                row,i=divmod(v.index,16);y,rx,rz=sections[row]
                a=i*math.tau/16+.035*math.sin(i*1.7+row*.6)
                front=max(0,math.sin(a));edge=math.sin(row*math.pi/8)
                x=rx*math.cos(a)*(1+.018*math.sin(i*2.3+row))
                h=y+.014*edge*math.cos(a*2+row*.7)
                z=rz*math.sin(a)+.027*front**3*edge
                v.co=blender((x,2.145+h,.015+z))
            broaden_facets(obj,16,{2,4,6})
        elif name=='Torso':
            for v in obj.data.vertices:
                p=logical(v.co);a=math.atan2(p.z,p.x);height=p.y
                waist=math.exp(-((height-1.32)/.13)**2)
                chest=math.exp(-((height-1.60)/.15)**2)
                p.x*=1-.095*waist+.035*chest
                p.z*=1+.075*chest-.035*waist
                p.z*=1-.18*(1-smooth(1.18,1.30,height))
                if 1.15<height<1.85:p.y+=.008*math.sin(a*2.3+height*4)+.004*math.cos(a*3.1-height*5)
                p.x+=.007*math.sin(height*9)*math.sin(a)
                v.co=blender(p)
        elif name.startswith('Arm '):
            side=-1 if name.endswith('L') else 1
            for v in obj.data.vertices:
                p=logical(v.co);row,i=divmod(v.index,12);a=i*math.tau/12
                if row not in (0,6):
                    p.y+=.008*math.sin(a*2+row*.9)
                    p.z+=.010*math.sin(a+row*.8)
                    p.x+=side*.007*math.cos(a*2+row)
                v.co=blender(p)
        elif name.startswith('Leg '):
            side=-1 if name.endswith('L') else 1
            for v in obj.data.vertices:
                p=logical(v.co);row,i=divmod(v.index,14);a=i*math.tau/14
                t=max(0,min(1,(1.205-p.y)/1.025))
                p.x+=side*.009*math.sin(t*math.pi)
                p.z+=.012*math.sin(t*math.pi*1.2)
                if row not in (0,6):p.y+=.008*math.sin(a*2.1+row*.8)
                v.co=blender(p)
        elif name.startswith('Mitten '):
            side=-1 if name.endswith('L') else 1;center=Vector((side*.58,1.075,.018));angle=-side*.30
            for v in obj.data.vertices:
                p=logical(v.co)-center
                x=p.x*math.cos(-angle)-p.y*math.sin(-angle);h=p.x*math.sin(-angle)+p.y*math.cos(-angle)
                x*=.98;h*=1.10;p.z*=.90
                row,i=divmod(v.index,14);a=i*math.tau/14
                if row not in (0,7):h+=.004*math.sin(a*2.4+row)
                p.x=x*math.cos(angle)-h*math.sin(angle);p.y=x*math.sin(angle)+h*math.cos(angle)
                v.co=blender(p+center)
        elif name.startswith('Foot '):
            side=-1 if name.endswith('L') else 1;center=Vector((side*.20,.115,.085))
            for v in obj.data.vertices:
                p=logical(v.co)-center;p.x*=1.04;p.z*=1.06;p.y*=1.04
                row,i=divmod(v.index,14)
                if row not in (0,7):p.y+=.003*math.sin(i*1.9+row)
                p+=center;p.y=max(.008,p.y);v.co=blender(p)
        for polygon in obj.data.polygons:polygon.use_smooth=False
        obj.data.update()

def unify_body():
    # Existing disconnected shells cannot form organic joints through vertex offsets alone.
    # Retopologize only those edited surfaces, then transfer their existing bone weights.
    parts=[o for o in bpy.data.objects if o.type=='MESH' and (o.name=='Torso' or o.name.startswith(('Arm ','Leg ','Mitten ','Foot ')))]
    bpy.ops.object.select_all(action='DESELECT')
    for obj in parts:obj.select_set(True)
    bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join();source=bpy.context.object;source.name='Weight transfer source'
    source.data.calc_loop_triangles()
    triangles=[tuple(t.vertices) for t in source.data.loop_triangles]
    positions=[v.co.copy() for v in source.data.vertices]
    tree=BVHTree.FromPolygons(positions,triangles,all_triangles=True)
    names=[g.name for g in source.vertex_groups]
    source_weights=[{names[g.group]:g.weight for g in v.groups} for v in source.data.vertices]
    target=source.copy();target.data=source.data.copy();bpy.context.collection.objects.link(target);target.name='Soft faceted body'
    for mod in list(target.modifiers):target.modifiers.remove(mod)
    bpy.ops.object.select_all(action='DESELECT');target.select_set(True);bpy.context.view_layer.objects.active=target
    remesh=target.modifiers.new('Unify existing body surfaces','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.027;remesh.use_smooth_shade=False
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    smoothing=target.modifiers.new('Soften physical junctions','SMOOTH');smoothing.factor=.65;smoothing.iterations=9
    bpy.ops.object.modifier_apply(modifier=smoothing.name)
    for vertex in target.data.vertices:
        p=logical(vertex.co);center=(1-smooth(.04,.15,abs(p.x)))*math.exp(-((p.y-1.13)/.085)**2)
        p.z-=.012*center*smooth(.02,.14,p.z)
        vertex.co=blender(p)
    decimate=target.modifiers.new('Broad uneven low-poly facets','DECIMATE');decimate.ratio=.11;decimate.use_collapse_triangulate=True
    bpy.ops.object.modifier_apply(modifier=decimate.name)
    def normalize(weights):
        pairs=sorted(weights.items(),key=lambda p:p[1],reverse=True)[:4];total=sum(w for _,w in pairs)
        return {name:w/total for name,w in pairs if w>1e-6}
    weights=[]
    for v in target.data.vertices:
        point,_,index,_=tree.find_nearest(v.co)
        ids=triangles[index];a,b,c=[positions[i] for i in ids]
        u=b-a;w=c-a;q=point-a;uu=u.dot(u);uw=u.dot(w);ww=w.dot(w);qu=q.dot(u);qw=q.dot(w);den=uu*ww-uw*uw
        if abs(den)<1e-12:factors=[1,0,0]
        else:
            vb=(ww*qu-uw*qw)/den;vc=(uu*qw-uw*qu)/den;factors=[max(0,1-vb-vc),max(0,vb),max(0,vc)]
        combined={}
        for i,factor in zip(ids,factors):
            for name,value in source_weights[i].items():combined[name]=combined.get(name,0)+value*factor
        weights.append(normalize(combined))
    neighbors=[set() for _ in weights]
    for edge in target.data.edges:
        a,b=edge.vertices;neighbors[a].add(b);neighbors[b].add(a)
    # A small physical-width blend prevents a hard weight seam at the welded shoulders/hips.
    for _ in range(2):
        result=[]
        for i,current in enumerate(weights):
            combined={name:value*.75 for name,value in current.items()}
            for adjacent in neighbors[i]:
                for name,value in weights[adjacent].items():combined[name]=combined.get(name,0)+value*.25/max(1,len(neighbors[i]))
            result.append(normalize(combined))
        weights=result
    target.vertex_groups.clear();groups={name:target.vertex_groups.new(name=name) for name in names}
    for i,values in enumerate(weights):
        for name,value in values.items():groups[name].add([i],value,'REPLACE')
    for polygon in target.data.polygons:polygon.use_smooth=False
    rig=bpy.data.objects['CharacterRig'];target.parent=rig;mod=target.modifiers.new('Character skin','ARMATURE');mod.object=rig
    bpy.data.objects.remove(source,do_unlink=True)

def refine_head():
    head=bpy.data.objects['Head'];bpy.ops.object.select_all(action='DESELECT');head.select_set(True);bpy.context.view_layer.objects.active=head
    for modifier in list(head.modifiers):head.modifiers.remove(modifier)
    remesh=head.modifiers.new('Round existing skull surface','REMESH');remesh.mode='VOXEL';remesh.voxel_size=.018
    bpy.ops.object.modifier_apply(modifier=remesh.name)
    soften=head.modifiers.new('Soften jaw and cheeks','SMOOTH');soften.factor=.6;soften.iterations=5
    bpy.ops.object.modifier_apply(modifier=soften.name)
    reduce=head.modifiers.new('Sparse organic head facets','DECIMATE');reduce.ratio=.075;reduce.use_collapse_triangulate=True
    bpy.ops.object.modifier_apply(modifier=reduce.name)
    head.vertex_groups.clear();group=head.vertex_groups.new(name='head');group.add(list(range(len(head.data.vertices))),1,'REPLACE')
    for polygon in head.data.polygons:polygon.use_smooth=False
    mod=head.modifiers.new('Character skin','ARMATURE');mod.object=bpy.data.objects['CharacterRig']
    head.data.update()
    # The skull geometry is already rounded. Blend only its corner normals to keep
    # a plain face; body and cloth retain their broad flat facets.
    for polygon in head.data.polygons:polygon.use_smooth=True
    head.data.update();normals=[None]*len(head.data.loops)
    for polygon in head.data.polygons:
        for loop in polygon.loop_indices:
            normal=head.data.vertices[head.data.loops[loop].vertex_index].normal
            normals[loop]=(normal*.75+polygon.normal*.25).normalized()
    head.data.normals_split_custom_set(normals)

def delete_accessories():
    for obj in list(bpy.data.objects):
        if obj.type=='MESH' and (obj.name.startswith('Temple lock') or obj.name.startswith('Glasses') or obj.name.startswith('Eye ')):
            bpy.data.objects.remove(obj,do_unlink=True)

def face_point(x,y,offset=.008):
    head=bpy.data.objects['Head']
    found,point,normal,index=head.ray_cast(Vector((x,-2,y)),Vector((0,1,0)))
    if found:return (x,y,-point.y+offset)
    return (x,y,.10+offset)

def new_mesh(name,verts,faces,mat):
    data=bpy.data.meshes.new(name);data.from_pydata([blender(v) for v in verts],[],faces);data.update()
    obj=bpy.data.objects.new(name,data);bpy.context.collection.objects.link(obj);data.materials.append(mat)
    group=obj.vertex_groups.new(name='head');group.add(list(range(len(verts))),1,'REPLACE')
    rig=bpy.data.objects['CharacterRig'];obj.parent=rig;mod=obj.modifiers.new('Character skin','ARMATURE');mod.object=rig
    bm=bmesh.new();bm.from_mesh(data);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
    return obj

def face_features(variant,black):
    for side,label in [(-1,'L'),(1,'R')]:
        cx=side*.143;cy=2.168
        verts=[face_point(cx,cy,.026)];faces=[]
        for i in range(16):
            a=i*math.tau/16;verts.append(face_point(cx+.041*math.cos(a),cy+.043*math.sin(a),.026))
        for i in range(16):faces.append((0,i+1,(i+1)%16+1))
        new_mesh('Eye '+label,verts,faces,black)
        verts=[];faces=[]
        for i in range(32):
            a=i*math.tau/32
            ex=math.cos(a);ey=math.sin(a)
            if variant=='girl':ex=math.copysign(abs(ex)**.74,ex);ey=math.copysign(abs(ey)**.74,ey)
            for j in range(6):
                b=j*math.tau/6;r=.104+.008*math.cos(b)
                x=cx+r*ex;y=cy+r*ey*(.94 if variant=='girl' else 1)
                verts.append(face_point(x,y,.024+.008*math.sin(b)))
        for i in range(32):
            for j in range(6):faces.append((i*6+j,i*6+(j+1)%6,((i+1)%32)*6+(j+1)%6,((i+1)%32)*6+j))
        new_mesh('Glasses '+label,verts,faces,black)
    pts=[face_point(x,y,.026) for x,y in [(-.041,2.172),(.041,2.172),(.041,2.185),(-.041,2.185)]]
    new_mesh('Glasses bridge',pts,[(0,1,2,3)],black)
    if variant=='guy':
        # Two simple mustache lobes and one small goatee patch, without realistic face detail.
        for side in (-1,1):
            points=[(side*x,y) for x,y in [(0,2.035),(.055,2.053),(.108,2.025),(.13,1.996),(.080,2.001),(.025,2.012)]]
            verts=[face_point(x,y,.024) for x,y in points];center=(sum(x for x,y in points)/len(points),sum(y for x,y in points)/len(points));verts.append(face_point(*center,.025))
            new_mesh('Mustache '+str(side),verts,[(len(points),i,(i+1)%len(points)) for i in range(len(points))],black)
        points=[(-.041,1.951),(-.036,1.916),(0,1.890),(.037,1.917),(.043,1.951),(0,1.942)]
        verts=[face_point(x,y,.024) for x,y in points];verts.append(face_point(0,1.926,.026));new_mesh('Goatee',verts,[(len(points),i,(i+1)%len(points)) for i in range(len(points))],black)

def head_cover(variant,black):
    hair=bpy.data.objects.get('Hair crown and curtain')
    if variant=='guy':
        # Reposition the existing crown/curtain vertices into short, softly waved hair.
        heights=[-.105,.035,.16,.265,.355,.405]
        widths=[.30,.34,.35,.32,.235,.055];depths=[.27,.31,.325,.29,.22,.06]
        for v in hair.data.vertices:
            row,i=divmod(v.index,20);a=i*math.tau/20;front=max(0,math.sin(a))
            h=heights[row]
            if front>.12:h=max(h,.16+.024*math.sin(i*1.7)+.011*math.cos(i*.8)+row*.023)
            wobble=1+.035*math.sin(i*2.1+row*.7)+.015*math.cos(i*3.3)
            v.co=blender((widths[row]*math.cos(a)*wobble,2.145+h,.005+depths[row]*math.sin(a)*wobble))
        broaden_facets(hair,20,{1,3})
        hair.name='Short waved hair'
    else:
        bpy.data.objects.remove(hair,do_unlink=True)
        verts=[];faces=[];N=32
        # Face-opening rim, outer fold, hood volume and back converge into one cloth shell.
        for row in range(5):
            for i in range(N):
                a=i*math.tau/N;c=math.cos(a);s=math.sin(a)
                if row==0:
                    x=.282*c;y=2.145+(.320 if s>=0 else .285)*s;z=face_point(x,y,.018)[2]
                elif row==1:
                    x=.313*c;y=2.145+(.350 if s>=0 else .315)*s;z=face_point(.282*c,2.145+(.320 if s>=0 else .285)*s,.040)[2]
                else:
                    rx,ry,zoff=[(.374,.408,.180),(.347,.385,-.225),(.255,.290,-.345)][row-2]
                    x=rx*c*(1+.012*math.sin(i*1.6));drape=max(0,-s)**3
                    y=2.145+ry*s+.009*math.sin(i*2.2)-.11*drape
                    z=zoff+(.065*drape if row==2 else -.02*drape)
                verts.append((x,y,z))
        for row in range(4):
            for i in range(N):k=row*N;n=(i+1)%N;faces.append((k+i,k+n,k+N+n,k+N+i))
        center=len(verts);verts.append((0,2.145,-.395))
        for i in range(N):faces.append((4*N+i,4*N+(i+1)%N,center))
        new_mesh('Hijab shell',verts,faces,black)

def export_runtime(variant,parts,rig):
    bpy.ops.object.select_all(action='DESELECT');copies=[]
    for obj in parts:
        copy=obj.copy();copy.data=obj.data.copy();bpy.context.collection.objects.link(copy);copy.select_set(True);copies.append(copy)
    bpy.context.view_layer.objects.active=copies[0];bpy.ops.object.join();bpy.context.object.name='CharacterMesh';rig.select_set(True)
    filename='reference_character.glb' if variant=='girl' else 'companion_character.glb'
    bpy.ops.export_scene.gltf(filepath=str(ROOT/'assets'/'characters'/filename),use_selection=True,export_format='GLB',export_animations=False,export_skins=True)

reports=[]
for variant in ['girl','guy']:
    bpy.ops.wm.open_mainfile(filepath=str(BASE))
    sculpt_body();unify_body();refine_head();delete_accessories()
    black=bpy.data.materials['Matte charcoal'];head_cover(variant,black);face_features(variant,black)
    parts=[o for o in bpy.data.objects if o.type=='MESH'];rig=bpy.data.objects['CharacterRig']
    scene=bpy.context.scene;scene.cycles.samples=16;scene.render.film_transparent=True
    camera=scene.camera;camera.data.ortho_scale=2.85
    # Save original editable objects and armature, not the joined runtime copies.
    path=SOURCE/('reference_character.blend' if variant=='girl' else 'companion_character.blend')
    camera.location=(0,-7,1.28);camera.rotation_euler=(Vector((0,0,1.28))-camera.location).to_track_quat('-Z','Y').to_euler()
    bpy.ops.wm.save_as_mainfile(filepath=str(path))
    if '--skip-render' not in sys.argv:
        for view,location in [('front',(0,-7,1.28)),('side',(7,0,1.28)),('back',(0,7,1.28))]:
            camera.location=location;camera.rotation_euler=(Vector((0,0,1.28))-camera.location).to_track_quat('-Z','Y').to_euler()
            scene.render.filepath=str(OUT/f'{variant}-{view}.png');bpy.ops.render.render(write_still=True)
    count=sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in parts)
    body=bpy.data.objects['Soft faceted body'];bm=bmesh.new();bm.from_mesh(body.data)
    remaining=set(bm.verts);components=0
    while remaining:
        components+=1;stack=[remaining.pop()]
        while stack:
            for edge in stack.pop().link_edges:
                for vertex in edge.verts:
                    if vertex in remaining:remaining.remove(vertex);stack.append(vertex)
    nonmanifold=sum(not edge.is_manifold for edge in bm.edges);bm.free()
    assert components==1 and nonmanifold==0, 'Body must be a single closed connected surface'
    assert all(abs(sum(g.weight for g in v.groups)-1)<.001 for v in body.data.vertices), 'Transferred body weights must remain normalized'
    reports.append({'variant':variant,'triangles':count,'bones':len(rig.data.bones),'materials':2,'textures':0,'body_components':components,'body_nonmanifold_edges':nonmanifold})
    if '--export' in sys.argv:export_runtime(variant,parts,rig)
(SOURCE/'model-report.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
print('SCULPT_REVIEW_READY',reports)
