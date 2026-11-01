"""Compose equal-height three-view study renders. Reference images stay local."""
import argparse
from pathlib import Path
from PIL import Image, ImageChops, ImageDraw
p=argparse.ArgumentParser();p.add_argument('--front',required=True);p.add_argument('--side',required=True);p.add_argument('--back',required=True);p.add_argument('--renders',required=True);p.add_argument('--output',required=True);a=p.parse_args()
c=Image.new('RGB',(1080,930),'#24272b');d=ImageDraw.Draw(c)
# These supplied screenshots include the decorative flower above the hair; exclude it from height normalization.
rects=[(8,210,575,1054),(100,230,460,1080),(20,210,600,1030)]
for i,name in enumerate(['front','side','back']):
 ref=Image.open(getattr(a,name)).convert('RGB').crop(rects[i]);ref=ref.resize((int(ref.width*400/ref.height),400));x=i*360;c.paste(ref,(x+(360-ref.width)//2,40));d.text((x+15,15),name+' reference',fill='white')
 source=Image.open(Path(a.renders)/(name+'.png')).convert('RGBA');box=source.getchannel('A').getbbox();background=Image.new('RGBA',source.size,'#24272b');background.alpha_composite(source);im=background.convert('RGB').crop(box);im=im.resize((int(im.width*400/im.height),400));c.paste(im,(x+(360-im.width)//2,510));d.text((x+15,480),name+' Blender model',fill='white')
c.save(a.output)
