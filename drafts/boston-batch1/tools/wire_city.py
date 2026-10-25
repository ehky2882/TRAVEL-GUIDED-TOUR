import json,uuid,re,math,os,mutagen
ROOT='/home/user/TRAVEL-GUIDED-TOUR'; P=f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
B='https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'; U=lambda s:str(uuid.uuid5(uuid.NAMESPACE_URL,s))
MAKER=U('atlas-maker:bos'); D=f'{ROOT}/drafts/boston-batch1/'; WD=f'{ROOT}/drafts/boston-walks/'
d=json.load(open(P)); assert not any(m['id']==MAKER for m in d['makers'])
def body(f):
    t=open(f).read().split('\n---\n',1)[1]
    ps=[p.strip() for p in re.split(r'\n\s*\n',t) if p.strip() and p.strip()!='*[beat]*']
    return [re.sub(r'\n?\*\[beat\]\*\n?','\n',p).strip() for p in ps]
def sentences(p): return re.findall(r'.+?[.!?](?=\s|$)',p)
def standpoint(ps):
    for i,p in enumerate(ps):
        if re.match(r"(You should be|You're|You are)\b",p): return i
    return None
def cut(t,n=145):
    t=t.replace('\n',' ')
    if len(t)<=n: return t
    c=t[:n].rsplit(' ',1)[0].rstrip(',;:—-')
    return c+'…'
def dur(f): return round(mutagen.File(f).info.length)
TITLE={'01':'Massachusetts State House','02':'Boston Common','03':'Old State House','04':'Faneuil Hall','05':'Acorn Street and Louisburg Square','06':'Paul Revere House','07':'Old North Church','08':'Bunker Hill Monument','09':'USS Constitution and the Navy Yard','10':'The Public Garden','11':'Copley Square','12':'Fenway Park','13':'Granary Burying Ground','14':'Park Street Church','15':'Old South Meeting House','16':"King's Chapel",'17':'City Hall Plaza','18':'Quincy Market','19':'Shaw and 54th Regiment Memorial','20':'African Meeting House and Abiel Smith School','21':'Charles Street','22':'Hanover Street','23':"Copp's Hill Burying Ground",'24':'The Greenway at the North End','25':'Long Wharf','26':'Commonwealth Avenue Mall','27':'Boston Marathon Finish Line','28':'Christian Science Plaza','29':'Chinatown Gate','30':'Harvard Yard'}
TAGS={'01':['Civic','Notable Building','Power','History','Neoclassical','Iconic Landmark','Free to Visit'],'02':['Park','History','Green Escape','Free to Visit'],
'03':['Notable Building','Museum','History','Power','Colonial','Iconic Landmark'],'04':['Market','Notable Building','History','Commerce','Colonial','Iconic Landmark'],
'05':['District','Architecture','History','Hidden Gem','Free to Visit'],'06':['Museum','Notable Building','History','Colonial'],'07':['Religious Building','Faith','History','War','Colonial','Iconic Landmark'],
'08':['Monument','War','Remembrance','History','Iconic Landmark','Viewpoint','Free to Visit'],'09':['Waterfront','Maritime','War','History','Iconic Landmark','Free to Visit'],
'10':['Park','History','Victorian','Green Escape','Free to Visit'],'11':['Public Square','Architecture','Literature','Victorian','Designed by a Master','Free to Visit','McKim, Mead & White'],
'12':['Venue','History','Iconic Landmark'],'13':['Monument','Remembrance','History','Colonial','Free to Visit'],'14':['Religious Building','Faith','History','Iconic Landmark'],
'15':['Notable Building','Museum','History','Power','Colonial'],'16':['Religious Building','Faith','History','Colonial'],'17':['Civic','Public Square','Power','Architecture','Brutalist','Free to Visit'],
'18':['Market','Commerce','History','Neoclassical','Iconic Landmark','Free to Visit'],'19':['Monument','War','Remembrance','Art','Public Art','Free to Visit'],
'20':['Museum','Religious Building','History','Faith','Hidden Gem'],'21':['District','History','Commerce','Free to Visit'],'22':['District','Immigration','Food','History','Free to Visit'],
'23':['Monument','Remembrance','History','Colonial','Viewpoint','Free to Visit'],'24':['Park','Engineering','History','Contemporary','Green Escape','Free to Visit'],
'25':['Waterfront','Maritime','Commerce','History','Viewpoint','Free to Visit'],'26':['Park','Architecture','History','Victorian','Green Escape','Free to Visit'],
'27':['Public Square','Remembrance','History','Free to Visit'],'28':['Religious Building','Public Square','Faith','Architecture','Modernist','Designed by a Master','Free to Visit','I. M. Pei'],
'29':['Monument','Immigration','History','Public Art','Free to Visit'],'30':['Notable Building','Architecture','History','Colonial','Iconic Landmark','Free to Visit','McKim, Mead & White']}
# images per tour: picks in order, owner photo (if any) becomes hero
man=json.load(open(D+'image-manifest.json')); imgs={}
for m in man: imgs.setdefault(m['num'],[]).append(m)
def tour_images(n):
    L=imgs[n]; owner=[m['name'] for m in L if m['src']=='owner']; picks=[m['name'] for m in L if m['src']!='owner']
    order=owner+picks; return order[0],order[1:]
singles={}; new=[]
files=sorted(f for f in os.listdir(D) if re.match(r'boston_\d\d_.*\.txt$',f) and not f.endswith('_TTS.txt'))
for line,f in zip(open(D+'coordinates.tsv'),files):
    n,slug,la,lo,r,cat,note=line.rstrip('\n').split('\t'); assert f.startswith(f'boston_{n}_')
    ps=body(D+f); txt='\n\n'.join(ps); si=standpoint(ps)
    cap=sentences(ps[si])[0] if si is not None else sentences(ps[0])[0]
    lp=[ps[0]]+([ps[si+1]] if si is not None and si+1<len(ps) else ([ps[1]] if len(ps)>1 else []))
    if si==0: lp=[ps[1]] if len(ps)>1 else lp
    hero,gal=tour_images(n); a=f'/tmp/ghpages/audio/{slug}.mp3'; du=dur(a)
    stop=dict(id=U(f'atlas-stop:bos:{slug}:1'),order=0,title=TITLE[n],caption=cap,latitude=float(la),longitude=float(lo),audioURL=B+f'audio/{slug}.mp3',audioDurationSeconds=du,triggerMode='geofenced',triggerRadiusMeters=int(r),imageURL=B+'images/'+hero,transcriptText=txt)
    t=dict(id=U(f'atlas-tour:bos:{slug}'),createdAt='2026-10-02',title=TITLE[n],shortDescription=cut(txt),longDescription='\n\n'.join(lp),makerId=MAKER,heroImageURL=B+'images/'+hero,additionalImageURLs=[B+'images/'+g for g in gal],kind='single',stops=[stop],introAudioURL=None,totalDurationSeconds=du,walkingDistanceMeters=None,centroidLatitude=float(la),centroidLongitude=float(lo),city='Cambridge' if n=='30' else 'Boston',country='United States',relatedTourIds=[],primaryCategory=cat,tags=TAGS[n],priceUSD=0)
    new.append(t); singles[n]=t
# walks
WALK={'W1':('boston-downhill-walk','Downhill — State House to Copley Square','boston-public-garden','history',['History','Architecture','Engineering','Free to Visit'],'Boston Common, below the State House'),
'W2':('boston-second-revolution-walk','The Second Revolution — Old State House to Beacon Hill','old-state-house','history',['History','Power','Remembrance','Free to Visit'],'State Street, below the Old State House'),
'W3':('boston-under-the-artery-walk',"Under the Artery — City Hall Plaza to Copp's Hill",'boston-city-hall-plaza','history',['History','Engineering','Immigration','Free to Visit'],'City Hall Plaza, the Congress Street edge'),
'W4':('boston-the-other-bank-walk','The Other Bank — Charlestown','uss-constitution','history',['History','War','Maritime','Waterfront','Viewpoint','Free to Visit'],'Pier One, Charlestown Navy Yard'),
'W5':('boston-name-above-the-door-walk','The Name Above the Door — Smith Court to Faneuil Hall','faneuil-hall','culturalHeritage',['History','Remembrance','Power','Free to Visit'],'Smith Court, Beacon Hill')}
CONN={'W2-5':'charles-street-beacon-hill_hero.webp','W3-2':'boston-under-the-artery_stop2.webp','W4-3':'uss-constitution_2.webp','W4-4':'boston-the-other-bank_stop4.webp','W5-2':'charles-street-beacon-hill_2.webp','W5-3':'boston-name-above-the-door_stop3.webp'}
EXTRA={'W3':['boston-under-the-artery_stop2-2.webp'],'W4':['boston-the-other-bank_stop4-2.webp','boston-the-other-bank_stop4-3.webp','boston-the-other-bank_stop4-4.webp','boston-the-other-bank_stop4-5.webp']}
bynum={t['stops'][0]['latitude']:t for t in new}
rows=[l.rstrip('\n').split('\t') for l in open(WD+'coordinates.tsv')]
def hav(a,b):
    R=6371000;p1,p2=math.radians(a[0]),math.radians(b[0]);dl=math.radians(b[1]-a[1]);dp=p2-p1
    return 2*R*math.asin(math.sqrt(math.sin(dp/2)**2+math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2))
for w,(slug,title,herobase,cat,tags,intro) in WALK.items():
    stops=[]
    for k,label,la,lo,r,sc,note in [x for x in rows if x[0].startswith(w+'-')]:
        i=int(k.split('-')[1]); ps=body(WD+'scripts/'+sc); txt='\n\n'.join(ps)
        m=re.search(r'reuses single (\d\d)',note)
        img=None if i==0 else (singles[m.group(1)]['heroImageURL'] if m else B+'images/'+CONN[k])
        a=f'/tmp/ghpages/audio/{slug}_stop{i}.mp3'
        stops.append(dict(id=U(f'atlas-stop:bos:{slug}:{i}'),order=i,title=intro if i==0 else label.replace(' (connective)',''),caption=sentences(ps[0])[0],latitude=float(la),longitude=float(lo),audioURL=B+f'audio/{slug}_stop{i}.mp3',audioDurationSeconds=dur(a),triggerMode='geofenced',triggerRadiusMeters=int(r),imageURL=img,transcriptText=txt))
    hero=singles[[n for n,t in singles.items() if herobase+'_hero' in t['heroImageURL']][0]]['heroImageURL']
    ims=[s['imageURL'] for s in stops if s['imageURL']]+[B+'images/'+e for e in EXTRA.get(w,[])]
    assert hero in ims,(w,hero)
    gal=[]; [gal.append(x) for x in ims if x!=hero and x not in gal]
    ip=body(WD+'scripts/'+[x for x in rows if x[0]==w+'-0'][0][5])
    dist=sum(hav((a['latitude'],a['longitude']),(b['latitude'],b['longitude'])) for a,b in zip(stops,stops[1:]))
    t=dict(id=U(f'atlas-tour:bos:{slug}'),createdAt='2026-10-02',title=title,shortDescription=cut(ip[0]),longDescription='\n\n'.join(ip[:2]),makerId=MAKER,heroImageURL=hero,additionalImageURLs=gal,kind='multiStop',stops=stops,introAudioURL=None,totalDurationSeconds=sum(s['audioDurationSeconds'] for s in stops),walkingDistanceMeters=int(round(dist*1.25/100)*100),centroidLatitude=round(sum(s['latitude'] for s in stops)/len(stops),6),centroidLongitude=round(sum(s['longitude'] for s in stops)/len(stops),6),city='Boston',country='United States',relatedTourIds=[],primaryCategory=cat,tags=tags,priceUSD=0)
    new.append(t); print(w,title,len(stops),'stops',t['totalDurationSeconds'],'s',t['walkingDistanceMeters'],'m')
maker=dict(id=MAKER,displayName='Atlas Studio BOS',platform='dozent',handle='atlas.bos',avatarURL=None,avatarEmoji='🇺🇸',bio="Atlas Studio's Boston bureau — audio tours of a city that keeps rebuilding its own ground: a hill cut down to fill a bay, a market built on the town dock, a highway buried under a park, and two meeting halls a mile apart whose names are still being argued over.",websiteURL=None)
last=max(i for i,m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio')); d['makers'].insert(last+1,maker)
ids={t['id'] for t in d['tours']}; assert not ids & {t['id'] for t in new}
d['tours'].extend(new)
open(P,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
print(len(new),'tours added; maker',MAKER)
for n in ['01','08','12','30']: t=singles[n]; print(n,t['title'],'|',t['stops'][0]['caption'][:90],'|',t['shortDescription'][:60])
