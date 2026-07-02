import sys, os, json, glob
from PIL import Image, ImageDraw, ImageFont
slug=sys.argv[1]; prefix=sys.argv[2] if len(sys.argv)>2 else "X"
d=f"/tmp/madrid_src/{slug}"
items=[]
mf=os.path.join(d,"manifest.json")
if os.path.exists(mf):
    try:
        for m in json.load(open(mf)):
            p=m.get("path") or os.path.join(d,m["label"]+".jpg")
            if os.path.exists(p): items.append((m["label"],p))
    except Exception as e: print("manifest err",e)
if not items:  # fallback: numeric sort of glob
    fs=[f for f in glob.glob(d+"/*.jpg") if not f.endswith("_m.jpg")]
    import re
    def kn(f):
        mm=re.search(r'(\d+)',os.path.basename(f)); return int(mm.group(1)) if mm else 0
    fs.sort(key=kn)
    items=[(f"{prefix}{i+1}",f) for i,f in enumerate(fs)]
cell=360; cols=4; rows=(len(items)+cols-1)//cols
canvas=Image.new("RGB",(cols*cell,rows*cell),(20,20,20))
try: font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",46)
except: font=ImageFont.load_default()
for i,(lbl,f) in enumerate(items):
    try: im=Image.open(f).convert("RGB")
    except: continue
    im.thumbnail((cell-8,cell-8))
    x=(i%cols)*cell; y=(i//cols)*cell
    canvas.paste(im,(x+4,y+4))
    dr=ImageDraw.Draw(canvas)
    dr.rectangle([x+4,y+4,x+130,y+58],fill=(0,0,0)); dr.text((x+12,y+8),lbl,fill=(255,220,0),font=font)
out=f"/tmp/madrid_src/{slug}_m.jpg"; canvas.save(out,quality=88)
print(f"{out} : {len(items)} imgs (label-accurate)")
