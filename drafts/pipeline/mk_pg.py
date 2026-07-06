import sys, json, os
from PIL import Image, ImageDraw, ImageFont
slug=sys.argv[1]; per=20  # 4 rows x 5 cols -> ~1100x880, safe
m=json.load(open(f"{slug}/manifest.json"))
f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',26)
cell=220; cols=5
pages=[]
for pg in range((len(m)+per-1)//per):
    chunk=m[pg*per:(pg+1)*per]; rows=(len(chunk)+cols-1)//cols
    canvas=Image.new('RGB',(cols*cell,rows*cell),(20,20,20))
    for i,x in enumerate(chunk):
        try: im=Image.open(x['path']).convert('RGB')
        except: continue
        im.thumbnail((cell-6,cell-6)); px=(i%cols)*cell; py=(i//cols)*cell; canvas.paste(im,(px+3,py+3))
        d=ImageDraw.Draw(canvas); lbl=x['label']; d.rectangle([px+3,py+3,px+8+len(lbl)*15,py+30],fill=(0,0,0)); d.text((px+7,py+5),lbl,font=f,fill=(255,220,0))
    o=f"/tmp/madrid_src/{slug}_p{pg+1}.jpg"; canvas.save(o,quality=72); pages.append(o)
    print(o, os.path.getsize(o)//1024,'KB', canvas.size)
