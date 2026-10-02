import json, uuid, re, math, mutagen
ROOT='/home/user/TRAVEL-GUIDED-TOUR'; P=f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
B='https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'; MAKER='aed488af-23d3-514f-90f1-035ca2285d0d'
d=json.load(open(P))
U=lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL,s))
rows={}
for line in open(f'{ROOT}/drafts/miami-walks/README.md'):
    m=re.match(r'\| (W\d)-(\d) \| ([^|]+) \| ([\d.]+) \| (-[\d.]+) \| \w+ \| ([^|]+) \| `([^`]+)`',line)
    if m: rows[(m[1],int(m[2]))]=dict(label=m[3].strip().replace(' (connective)',''),lat=float(m[4]),lon=float(m[5]),img=m[6].strip(),audio=m[7])
heroes={t['heroImageURL'].split('/')[-1].removesuffix('.webp'):t for t in d['tours'] if t['makerId']==MAKER and t['kind']=='single'}
W={
 'W1':dict(slug='miami-pitch-walk',img='miami-pitch',city='Miami',title='The Pitch — Downtown, River to Bay',cat='architecture',
  tags=['History','Architecture','Commerce','Notable Building','Free to Visit'],hero='freedom-tower_hero',
  short='River to bay through downtown, where every building on the route was built to sell something.',
  long="A little under two miles on flat ground from the Miami River to Biscayne Bay, by way of the old courthouse, Flagler Street and Biscayne Boulevard. Every stop on this route went up to convince somebody of something: winter visitors that a frontier town was a resort, a county that it would last, families that a boomtown was worth putting down roots in, moviegoers that the sky could be improved on, and readers that the land was worth buying. Allow about an hour and a half; the Metromover runs beside the first stop and the last. Start early or late, because the boulevard offers very little shade.",
  scripts=['00_intro','01_palm_cottage','02_courthouse','03_cultural_center','04_dupont','c_olympia','05_gesu','06_freedom_tower','07_bayfront'],
  intro='Fort Dallas Park, under the Metromover', w='w1'),
 'W2':dict(slug='miami-ocean-drive-walk',img='miami-ocean-drive',city='Miami Beach',title='Ocean Drive — South Pointe to Lincoln Road',cat='architecture',
  tags=['Art Deco','Architecture','History','Waterfront','District','Free to Visit'],hero='ocean-drive-art-deco_hero',
  short='North along the Art Deco row, and the question of why the low hotels are still standing.',
  long="About two miles of flat ground from the southern tip of Miami Beach: along the Art Deco row on Ocean Drive, a block inland to Collins Avenue, then through Española Way to Lincoln Road. The walk runs north and its story runs the other way, each stop an earlier chapter than the one before. The question is why the low hotels are still standing, and the answer involves three buildings you will not see, because each came down and each taught the city something. Shade is generous in South Pointe Park and scarce after it, so in the warm months carry water and walk early or late.",
  scripts=['00_intro','01_south_pointe','02_ocean_drive','03_casa_casuarina','c_senator','04_espanola_way','05_lincoln_road'],
  intro='South Pointe Park entrance', w='w2'),
 'W3':dict(slug='miami-calle-ocho-walk',img='miami-calle-ocho',city='Miami',title='Calle Ocho — The Seam',cat='culturalHeritage',
  tags=['Immigration','History','District','Remembrance','Free to Visit'],hero='tower-theater_hero',
  short="Little Havana's main street, read as the seam between two older neighborhoods, from the eternal flame to Woodlawn's gate.",
  long="For most of the years before 1960, Calle Ocho marked where Riverside ended and Shenandoah began: on one side apartment houses, synagogues and Jewish-owned shops, on the other the stucco houses of the 1920s boom. It is also the last stretch of the Tamiami Trail, the highway across the Everglades. Most of the walk lies within three blocks of the start: the memorial boulevard, the Walk of Fame stars, the Tower Theater and Domino Park. The last stop is about a mile and a half farther west, at the gate of Woodlawn Park Cemetery. County buses along Eighth Street cover that stretch in a few minutes; on foot it is about half an hour, and the shaded side of the street is worth crossing for.",
  scripts=['00_intro','01_memorial','c_walk_of_fame','02_tower_theater','03_domino_park','c_woodlawn'],
  intro='Calle Ocho at Thirteenth Avenue', w='w3'),
 'W4':dict(slug='miami-grove-walk',img='miami-grove',city='Miami',title='The Grove — Charles Avenue to Vizcaya',cat='history',
  tags=['History','Immigration','Architecture','Waterfront','Free to Visit'],hero='the-barnacle_hero',
  short='The road Bahamian settlers built for themselves, followed as a commute from Charles Avenue to the gates of Vizcaya.',
  long="In the late 1800s the Bahamian families of Coconut Grove asked the town for a road. When it refused, they quarried the local limestone and laid one themselves. This walk follows that road east along Charles Avenue, jogs south to a stone church, comes back past the Barnacle to Peacock Park, and then follows South Bayshore Drive for about two and a half miles to the gates of Vizcaya and the Metrorail station beside them. It is shaped as a commute: every stop is somewhere a person from this street went to work. The last leg is long and open, so walk it or ride it.",
  scripts=['00_intro','c1_charles_avenue','c2_plymouth','01_barnacle_peacock_park','c3_vizcaya_approach'],
  intro='The west end of Charles Avenue', w='w4'),
 'W5':dict(slug='miami-water-line-walk',img='miami-water-line',city='Miami Beach',title='The Water Line — Lincoln Road to Sunset Harbour',cat='history',
  tags=['Waterfront','Engineering','History','District','Free to Visit'],hero='miami-water-line_stop2',
  short='A flat mile along the bay side of Miami Beach, reading every curb and step for what it says about the ground.',
  long="A flat mile from the west end of Lincoln Road to Sunset Harbour, by way of the foot of the Venetian Causeway and a small park on the water. The subject is edges: the place where the mall's paving stops, curbs and steps, and one rise a good deal higher than the rest. Each says something about the ground underneath, much of which was made by people rather than found. Keep a tally of every step up or down as you go, and notice which way they trend. The city rebuilds this district in stages, so if fencing blocks a corner, use the nearest marked crossing.",
  scripts=['00_intro','01_lincoln_road_west','c1_venetian_causeway','c2_maurice_gibb_park','c4_sunset_harbour'],
  intro='Lincoln Road at Lenox Avenue', w='w5'),
}
def body(f):
    t=open(f).read().split('\n---\n',1)[1]
    paras=[p.strip() for p in re.split(r'\n\s*\n',t) if p.strip() and not re.fullmatch(r'\*\[beat\]\*',p.strip())]
    paras=[re.sub(r'\n?\*\[beat\]\*\n?','\n',p).strip() for p in paras]
    return '\n\n'.join(paras)
def first_sentence(t):
    m=re.match(r'(.+?[.!?])(\s|$)',t.split('\n')[0]); return m[1] if m else t[:200]
def hav(a,b):
    R=6371000;p1,p2=math.radians(a[0]),math.radians(b[0]);dl=math.radians(b[1]-a[1]);dp=p2-p1
    return 2*R*math.asin(math.sqrt(math.sin(dp/2)**2+math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2))
new=[]
for k,w in W.items():
    stops=[]; n=sum(1 for kk in rows if kk[0]==k and not (k=='W5' and kk[1]==4))
    orders=[o for (kk,o) in sorted(rows) if kk==k and not (k=='W5' and o==4)]
    assert len(orders)==len(w['scripts']),(k,orders)
    for i,(o,sc) in enumerate(zip(orders,w['scripts'])):
        r=rows[(k,o)]; lat,lon=r['lat'],r['lon']
        im=r['img'].strip('`* ')
        if im=='new': im=None if i==0 else f"{w['img']}_stop{i}"
        if im and im in heroes:
            s0=heroes[im]['stops'][0]
            if (s0['latitude'],s0['longitude'])!=(lat,lon) and 'reuses single' in open(f'{ROOT}/drafts/miami-walks/README.md').read().split(f'| {k}-{o} |')[1].split('\n')[0]:
                print('  snap',k,i,(lat,lon),'->',(s0['latitude'],s0['longitude'])); lat,lon=s0['latitude'],s0['longitude']
        txt=body(f"{ROOT}/drafts/miami-walks/scripts/miami_{w['w']}_{sc}.txt")
        af=f"/tmp/ghpages/audio/{r['audio']}"; dur=round(mutagen.File(af).info.length)
        stops.append(dict(id=U(f"atlas-stop:mia:{w['slug']}:{i}"),order=i,title=w['intro'] if i==0 else r['label'],caption=first_sentence(txt),
            latitude=lat,longitude=lon,audioURL=B+'audio/'+r['audio'],audioDurationSeconds=dur,triggerMode='geofenced',triggerRadiusMeters=40,
            imageURL=(B+'images/'+im+'.webp') if im else None,transcriptText=txt))
    imgs=[s['imageURL'] for s in stops if s['imageURL']]
    hero=B+'images/'+w['hero']+'.webp'; assert hero in imgs,(k,hero)
    gal=[]; [gal.append(x) for x in imgs if x!=hero and x not in gal]
    dist=sum(hav((a['latitude'],a['longitude']),(b['latitude'],b['longitude'])) for a,b in zip(stops,stops[1:]))
    t=dict(id=U(f"atlas-tour:mia:{w['slug']}"),createdAt='2026-10-01',title=w['title'],shortDescription=w['short'],longDescription=w['long'],makerId=MAKER,
        heroImageURL=hero,additionalImageURLs=gal,kind='multiStop',introAudioURL=None,totalDurationSeconds=sum(s['audioDurationSeconds'] for s in stops),
        walkingDistanceMeters=int(round(dist*1.25/100)*100),centroidLatitude=round(sum(s['latitude'] for s in stops)/len(stops),6),
        centroidLongitude=round(sum(s['longitude'] for s in stops)/len(stops),6),city=w['city'],country='United States',relatedTourIds=[],
        primaryCategory=w['cat'],tags=w['tags'],priceUSD=0)
    order=['id','createdAt','title','shortDescription','longDescription','makerId','heroImageURL','additionalImageURLs','kind','stops','introAudioURL','totalDurationSeconds','walkingDistanceMeters','centroidLatitude','centroidLongitude','city','country','relatedTourIds','primaryCategory','tags','priceUSD']
    t['stops']=stops; t={k2:t[k2] for k2 in order}
    print(k,len(stops),'stops',t['totalDurationSeconds'],'s',t['walkingDistanceMeters'],'m', [s['title'] for s in stops])
    new.append(t)
ids={t['id'] for t in d['tours']}; assert not ids & {t['id'] for t in new}
last=max(i for i,t in enumerate(d['tours']) if t['makerId']==MAKER)
d['tours'][last+1:last+1]=new
open(P,'w').write(json.dumps(d,indent=2,ensure_ascii=False)+'\n')
