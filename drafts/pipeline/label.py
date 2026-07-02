import os, json, sys
from PIL import Image, ImageDraw, ImageFont, ImageOps
OUT="/tmp/madrid_src"
def font(sz):
    for p in ["/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
              "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"]:
        if os.path.exists(p): return ImageFont.truetype(p,sz)
    return ImageFont.load_default()
SRCNAME={"Uns":"Unsplash","Pex":"Pexels","Pix":"Pixabay","Wik":"Wikimedia"}
def label_one(path,label,src,dst):
    im=ImageOps.exif_transpose(Image.open(path)).convert("RGB")
    w,h=im.size; tw=1000; th=int(h*tw/w); im=im.resize((tw,th))
    d=ImageDraw.Draw(im)
    # number badge top-left
    bf=font(74); tag=label
    d.rectangle([0,0,150,104],fill=(0,0,0)); d.text((18,8),tag,font=bf,fill=(255,220,60))
    # source tag bottom-left
    sf=font(30); s=SRCNAME.get(src,src)
    tb=d.textbbox((0,0),s,font=sf); sw=tb[2]-tb[0]
    d.rectangle([0,th-46,sw+24,th],fill=(0,0,0)); d.text((12,th-42),s,font=sf,fill=(255,255,255))
    im.save(dst,"JPEG",quality=88)
for slug in sys.argv[1:]:
    d=f"{OUT}/{slug}"; man=json.load(open(f"{d}/manifest.json"))
    os.makedirs(f"{d}/labeled",exist_ok=True); res=[]
    for it in man:
        dst=f"{d}/labeled/{it['label']}.jpg"
        label_one(it['path'],it['label'],it['src'],dst); res.append(dst)
    print(slug, len(res), "labeled")
