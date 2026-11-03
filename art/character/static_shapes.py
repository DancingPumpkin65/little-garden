"""Static control-cage shaping. No rig, topology, identity or animation changes."""
import math
from mathutils import Vector

def torso(point):
    p=point.copy();t=max(0,min(1,(p.y-1.12)/.62))
    angle=math.atan2(p.z/.24,p.x/.36)
    p.x*=1+.025*math.sin(math.pi*t*1.4)
    p.x+=.010*math.sin(t*math.pi)*math.cos(t*2.2)
    p.z*=.94-.025*t
    # A shallow, uneven hem reads as a little shirt rather than a capsule.
    p.y-=.035*(1-t)**3
    p.z+=.014*math.sin(t*math.pi)*(1-t)+.004*math.cos(angle*3+.7)*math.sin(t*math.pi)
    p.y+=.005*math.sin(angle*2+.4)*math.sin(t*math.pi)
    return p

def body_part(name,point,index):
    p=point.copy();side=-1 if name.endswith('LEFT') else 1
    if name=='TORSO':return torso(p)
    if name.startswith('ARM_'):
        t=max(0,min(1,(1.64-p.y)/.642));center=side*(.285+.445*t+.016*math.sin(t*math.pi))
        fullness=1+.13*math.exp(-((t-.16)/.19)**2)+.075*math.exp(-((t-.65)/.23)**2)
        p.x=center+(p.x-center)*fullness+side*.007*math.sin(t*math.pi*1.4)
        p.z=p.z*(1+.06*math.sin(t*math.pi))+.008*math.sin(t*math.pi*1.5)
        return p
    row,i=divmod(index,14);a=i*math.tau/14
    if name.startswith('HAND_'):
        # Broad palm, compressed underside and a small thumb-side bulge.
        # The reference's mitten is a flattened, angled volume, not an oval ball.
        sections=[(-.155,.095,.078),(-.143,.17,.105),(-.105,.205,.128),(-.025,.213,.14),(.055,.192,.135),(.105,.145,.113),(.135,.112,.095),(.145,.095,.078)]
        h,rx,rz=sections[row];w=1+.025*math.sin(i*1.9+row*.7)
        x=rx*math.cos(a)*w;z=rz*math.sin(a)*(1+.02*math.cos(i*1.3+row))
        thumb=max(0,-side*math.cos(a))**5*math.exp(-((h-.025)/.065)**2)
        x-=side*.027*thumb;h+=.009*math.sin(a*2+.5)*math.sin(row*math.pi/7)
        angle=-side*.38
        return Vector((side*.745+x*math.cos(angle)-h*math.sin(angle),.973+x*math.sin(angle)+h*math.cos(angle),.025+z))
    if name.startswith('LEG_'):
        sections=[(1.158,.145,.165,.185,0),(1.09,.172,.18,.185,.005),(.90,.177,.185,.191,.008),(.665,.166,.17,.199,.022),(.43,.171,.174,.196,.016),(.235,.145,.15,.204,.018),(.162,.122,.128,.205,.02)]
        h,rx,rz,cx,cz=sections[row];w=1+.02*math.sin(a*2.3+row*.65)
        h+=.005*math.sin(a*2+row*.7)*math.sin(row*math.pi/6)
        return Vector((side*cx+rx*math.cos(a)*w*(.99 if side<0 else 1.01),h,cz+rz*math.sin(a)*(1+.018*math.cos(a*3+row))))
    if name.startswith('FOOT_'):
        sections=[(.008,.13,.19,.135),(.018,.165,.225,.145),(.045,.179,.25,.145),(.085,.18,.255,.145),(.135,.164,.23,.12),(.18,.137,.17,.07),(.21,.115,.125,.04),(.22,.09,.08,.03)]
        h,rx,rz,cz=sections[row];front=max(0,math.sin(a));heel=max(0,-math.sin(a))
        x=rx*math.cos(a)*(1+.035*front-.11*heel)*(1+.018*math.sin(a*3+row))
        z=max(-.085,cz+rz*math.sin(a))
        return Vector((side*.20+x,h,z+(.006*front if side>0 else 0)))
    return p
