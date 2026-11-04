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
    if name=='TORSO':
        row,i=divmod(index,14);a=i*math.tau/14
        sections=[(1.09,.30,.19),(1.14,.35,.215),(1.32,.345,.23),(1.53,.345,.225),(1.64,.31,.20),(1.72,.21,.155),(1.75,.10,.10)]
        h,rx,rz=sections[row]
        return Vector((rx*math.cos(a)*(1+.012*math.sin(a*3+row)),h+.004*math.sin(a*2+row)*math.sin(row*math.pi/6),rz*math.sin(a)+.008*math.sin(row*math.pi/6)))
    if name.startswith('ARM_'):
        # Rings lie perpendicular to the limb, rather than horizontal ovals.
        row,i=divmod(index,12);a=i*math.tau/12
        sections=[(-.07,.055),(0,.128),(.12,.143),(.40,.136),(.70,.126),(.96,.112),(1.035,.09)]
        t,r=sections[row]
        shoulder=Vector((side*.285,1.69,0));wrist=Vector((side*.73,1.0,.02))
        axis=(wrist-shoulder).normalized();cross=Vector((0,0,1));across=cross.cross(axis).normalized()
        center=shoulder.lerp(wrist,t)+Vector((side*.009*math.sin(t*math.pi),0,.012*math.sin(t*math.pi)))
        radius=r*(1+.012*math.sin(a*3+row*.6))
        return center+radius*(across*math.cos(a)+cross*math.sin(a))
    row,i=divmod(index,14);a=i*math.tau/14
    if name.startswith('HAND_'):
        # Rounded palm in both front and oblique views, with a small thumb side.
        sections=[(-.19,.055,.05),(-.17,.13,.115),(-.115,.18,.155),(-.025,.195,.17),(.07,.18,.155),(.13,.135,.12),(.17,.10,.09),(.19,.075,.065)]
        h,rx,rz=sections[row];w=1+.025*math.sin(i*1.9+row*.7)
        x=rx*math.cos(a)*w;z=rz*math.sin(a)*(1+.02*math.cos(i*1.3+row))
        thumb=max(0,-side*math.cos(a))**5*math.exp(-((h-.025)/.065)**2)
        x-=side*.027*thumb;h+=.009*math.sin(a*2+.5)*math.sin(row*math.pi/7)
        angle=-side*.18
        return Vector((side*.745+x*math.cos(angle)-h*math.sin(angle),.973+x*math.sin(angle)+h*math.cos(angle),.025+z))
    if name.startswith('LEG_'):
        # Full-width roots enter the torso; the seam sits above the visible hem.
        sections=[(1.235,.115,.14,.145,0),(1.12,.158,.174,.155,.005),(.90,.176,.183,.187,.012),(.665,.165,.17,.198,.038),(.43,.17,.174,.195,.028),(.235,.145,.15,.203,.02),(.162,.122,.128,.205,.02)]
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
