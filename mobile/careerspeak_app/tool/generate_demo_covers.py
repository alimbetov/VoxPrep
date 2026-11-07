"""Generate original geometric mock covers; no remote image dependencies."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
ROOT = Path(__file__).resolve().parents[1] / 'assets/demo'
font_path='/System/Library/Fonts/Supplemental/Arial.ttf'
font=lambda size: ImageFont.truetype(font_path,size)
for name,title,subtitle,bg,accent in [
 ('java','DEPENDENCY INJECTION','JAVA INTERVIEW / CONSTRUCTOR · SERVICE · REPOSITORY',(23,32,62),(124,179,255)),
 ('medical','CLEAR HANDOVERS','MEDICAL ENGLISH / SITUATION · BACKGROUND · NEXT STEP',(12,62,64),(103,226,201)),
 ('communication','MAKE YOUR POINT','PROFESSIONAL ENGLISH / EXPLAIN · EXAMPLE · OUTCOME',(53,28,73),(223,169,255))]:
 im=Image.new('RGB',(1200,600),bg); d=ImageDraw.Draw(im)
 d.ellipse((830,-160,1370,380),fill=tuple(min(255,v+16) for v in bg))
 d.text((65,48),'VOXPREP  /  DEMO LESSON',font=font(20),fill=accent)
 if name=='java':
  for x,label in [(80,'CONTROLLER'),(450,'SERVICE'),(820,'REPOSITORY')]:
   d.rounded_rectangle((x,160,x+290,290),24,fill=tuple(min(255,v+28) for v in bg),outline=accent,width=3)
   d.text((x+26,208),label,font=font(27),fill='white')
  for x in (385,755):
   d.line((x,225,x+48,225),fill=accent,width=5);d.polygon([(x+48,225),(x+34,215),(x+34,235)],fill=accent)
 elif name=='medical':
  d.rounded_rectangle((85,145,350,335),25,fill=accent)
  d.rectangle((190,178,242,298),fill=bg); d.rectangle((155,213,277,263),fill=bg)
  for y,w in [(170,570),(223,430),(276,510)]: d.rounded_rectangle((420,y,420+w,y+17),8,fill=accent)
 else:
  d.rounded_rectangle((95,140,730,315),28,fill=accent)
  d.polygon([(190,310),(190,355),(255,310)],fill=accent)
  for y,w in [(180,470),(226,370),(270,430)]:d.rounded_rectangle((145,y,145+w,y+12),5,fill=bg)
  d.rounded_rectangle((800,205,1090,330),24,outline=accent,width=4)
 d.text((65,405),title,font=font(47),fill='white')
 d.text((65,486),subtitle,font=font(21),fill=accent)
 im.save(ROOT/(name+'-cover.png'),optimize=True)
