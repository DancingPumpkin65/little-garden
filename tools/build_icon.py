from PIL import Image,ImageDraw
from pathlib import Path
portrait=Image.open('artifacts/icon-portrait.png').convert('RGBA')
Path('assets/icon').mkdir(parents=True,exist_ok=True)
size=768
background=Image.new('RGBA',(size,size))
pixels=background.load()
for y in range(size):
 t=y/(size-1)
 color=tuple(round(a+(b-a)*t) for a,b in zip((228,246,244),(121,186,203)))+(255,)
 for x in range(size):pixels[x,y]=color
mask=Image.new('L',(size,size))
ImageDraw.Draw(mask).rounded_rectangle((10,10,size-10,size-10),radius=150,fill=255)
background.putalpha(mask)
# The actual in-game model remains unchanged; only the icon background is composed.
background.alpha_composite(portrait)
background.putalpha(Image.composite(background.getchannel('A'),Image.new('L',(size,size)),mask))
icon=background.resize((512,512),Image.Resampling.LANCZOS)
icon.save('assets/icon/app.png')
icon.save('assets/icon/app.ico',sizes=[(16,16),(24,24),(32,32),(48,48),(64,64),(128,128),(256,256)])
