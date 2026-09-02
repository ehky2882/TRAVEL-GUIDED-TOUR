#!/usr/bin/env python3
"""Labelled contact sheets for the hero audit.

⚠️ Tiles are keyed by SHORTCODE (which is what the thumbnail file is named
   after, i.e. derived from heroImageURL) — never by slug prefix. That is the
   session-121b bug: slug-prefix matching rendered one pin's photo under
   another pin's number and nearly became a false alarm.
"""
import json, os
from PIL import Image, ImageDraw, ImageFont
TILE=420; COLS=3; ROWS=3; PAD=6; LABEL=34
ven=json.load(open("venues.json"))
have=[v for v in ven if os.path.exists(f"thumbs/{v['code']}.jpg")]
try: font=ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", 24)
except Exception: font=ImageFont.load_default()
os.makedirs("sheets", exist_ok=True)
per=COLS*ROWS
index=[]
for s in range((len(have)+per-1)//per):
    grp=have[s*per:(s+1)*per]
    W=COLS*(TILE+PAD)+PAD; H=ROWS*(TILE+LABEL+PAD)+PAD
    sheet=Image.new("RGB",(W,H),(24,24,26)); d=ImageDraw.Draw(sheet)
    for k,v in enumerate(grp):
        r,c=divmod(k,COLS)
        x=PAD+c*(TILE+PAD); y=PAD+r*(TILE+LABEL+PAD)
        im=Image.open(f"thumbs/{v['code']}.jpg").convert("RGB")
        im.thumbnail((TILE,TILE))
        ox=x+(TILE-im.width)//2; oy=y+LABEL+(TILE-im.height)//2
        sheet.paste(im,(ox,oy))
        n=s*per+k+1
        d.text((x+4,y+4), f"{n}. {v['code']}", fill=(230,200,110), font=font)
        index.append({"n":n,"sheet":s+1,"code":v["code"],"venue":v["venue"]})
    sheet.save(f"sheets/sheet{s+1:02d}.jpg", quality=88)
json.dump(index, open("sheet_index.json","w"), ensure_ascii=False, indent=1)
print(f"{len(have)} thumbs -> {(len(have)+per-1)//per} sheets")
