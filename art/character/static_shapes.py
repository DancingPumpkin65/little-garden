"""Static control-cage shaping. No rig, topology, identity or animation changes."""
import math
from mathutils import Vector

def torso(point):
    p=point.copy();t=max(0,min(1,(p.y-1.12)/.62))
    angle=math.atan2(p.z/.24,p.x/.36)
    p.x*=1.07+.045*math.sin(math.pi*t*1.4)
    p.x+=.010*math.sin(t*math.pi)*math.cos(t*2.2)
    p.z*=1.02-.11*t**3+.025*math.sin(math.pi*t)
    # A shallow, uneven hem reads as a little shirt rather than a capsule.
    p.y-=.045*(1-t)**2
    p.z+=.014*math.sin(t*math.pi)*(1-t)+.004*math.cos(angle*3+.7)*math.sin(t*math.pi)
    p.z+=.055*max(0,math.sin(angle))**2*math.exp(-((t-.35)/.30)**2)
    p.y+=.005*math.sin(angle*2+.4)*math.sin(t*math.pi)
    return p

def body_part(name,point,index):
    p=point.copy();side=-1 if name.endswith('LEFT') else 1
    if name=='TORSO':
        row,i=divmod(index,14);a=i*math.tau/14
        sections=[(1.145,.33,.225),(1.18,.385,.25),(1.35,.38,.255),(1.54,.355,.24),(1.65,.32,.21),(1.73,.21,.155),(1.75,.10,.10)]
        h,rx,rz=sections[row]
        belly=.045*max(0,math.sin(a))**2*math.exp(-((h-1.35)/.20)**2)
        return Vector((rx*math.cos(a)*(1+.012*math.sin(a*3+row)),h+.004*math.sin(a*2+row)*math.sin(row*math.pi/6),rz*math.sin(a)+.008*math.sin(row*math.pi/6)+belly))
    if name.startswith('ARM_'):
        # Rings lie perpendicular to the limb, rather than horizontal ovals.
        row,i=divmod(index,12);a=i*math.tau/12
        sections=[(-.07,.055),(0,.128),(.12,.143),(.40,.136),(.70,.126),(.96,.112),(1.035,.09)]
        t,r=sections[row]
        shoulder=Vector((side*.285,1.69,0));wrist=Vector((side*.63,1.0,.02))
        axis=(wrist-shoulder).normalized();cross=Vector((0,0,1));across=cross.cross(axis).normalized()
        center=shoulder.lerp(wrist,t)+Vector((side*.009*math.sin(t*math.pi),0,.012*math.sin(t*math.pi)))
        radius=r*1.05*(1+.012*math.sin(a*3+row*.6))
        return center+radius*(across*math.cos(a)+cross*math.sin(a))
    row,i=divmod(index,14);a=i*math.tau/14
    if name.startswith('HAND_'):
        # Rounded palm in both front and oblique views, with a small thumb side.
        sections=[(-.19,.055,.05),(-.17,.13,.115),(-.115,.18,.155),(-.025,.195,.17),(.07,.18,.155),(.13,.135,.12),(.17,.10,.09),(.19,.075,.065)]
        h,rx,rz=sections[row];h=.15+(h-.15)*1.14;rx*=1.13;rz*=1.12
        w=1+.025*math.sin(i*1.9+row*.7)
        x=rx*math.cos(a)*w;z=rz*math.sin(a)*(1+.02*math.cos(i*1.3+row))
        thumb=max(0,-side*math.cos(a))**5*math.exp(-((h-.025)/.065)**2)
        x-=side*.045*thumb;h+=.009*math.sin(a*2+.5)*math.sin(row*math.pi/7)
        angle=-side*.18
        return Vector((side*.645+x*math.cos(angle)-h*math.sin(angle),.973+x*math.sin(angle)+h*math.cos(angle),.025+z))
    if name.startswith('LEG_'):
        # Full-width roots enter the torso; the seam sits above the visible hem.
        sections=[(1.235,.115,.14,.145,0),(1.12,.17,.18,.17,.005),(.90,.19,.205,.205,.012),(.665,.21,.218,.235,.038),(.43,.212,.22,.23,.028),(.28,.16,.17,.215,.02),(.24,.13,.14,.21,.02)]
        h,rx,rz,cx,cz=sections[row];w=1+.02*math.sin(a*2.3+row*.65)
        h+=.005*math.sin(a*2+row*.7)*math.sin(row*math.pi/6)
        return Vector((side*cx+rx*math.cos(a)*w*(.99 if side<0 else 1.01),h,cz+rz*math.sin(a)*(1+.018*math.cos(a*3+row))))
    if name.startswith('FOOT_'):
        sections=[(.008,.14,.20,.145),(.023,.185,.24,.15),(.075,.205,.27,.15),(.135,.21,.27,.15),(.20,.20,.25,.13),(.255,.175,.20,.09),(.29,.135,.145,.05),(.30,.10,.095,.03)]
        h,rx,rz,cz=sections[row];front=max(0,math.sin(a));heel=max(0,-math.sin(a))
        x=rx*math.cos(a)*(1+.035*front-.11*heel)*(1+.018*math.sin(a*3+row))
        z=max(-.085,cz+rz*math.sin(a))
        return Vector((side*.20+x,h,z+(.006*front if side>0 else 0)))
    return p
