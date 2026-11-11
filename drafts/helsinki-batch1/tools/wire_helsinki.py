"""Assemble Atlas Studio HEL (19 Helsinki singles) into Tours.json.

Adapted from drafts/belem-batch1/tools/wire_belem.py. Usage:
    python3 wire_helsinki.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders, matched to META by the folder's name (17 hold
`NN_<slug>_clean.txt`; Central Station and Kuurna hold `<slug>.txt` with the title on line 1). Takes each
coordinate from its folder name unless COORD_OVERRIDE says otherwise, writes Tours.json and
drafts/helsinki-batch1/coordinates.tsv, copies both script texts into drafts/helsinki-batch1/scripts/, and
copies audio/<slug>.mp3 and images/<slug>_hero.webp, _2.webp … into the staging dir for one gh-pages commit.
Every slug carries a `hel-` prefix so no Helsinki file can land on an existing name.
"""
import json, uuid, re, os, sys, glob, shutil, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/helsinki-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:hel')
DROP, OUT = sys.argv[1], sys.argv[2]
M = 'Designed by a Master'

# folder-name prefix: (num, slug, title, radius, category, caption, tags)
# English | Finnish where the two names genuinely differ; venues and names used as-is keep one name.
META = {
    'Artek 2nd cycle': ('01', 'hel-artek-2nd-cycle', 'Artek 2nd Cycle', 40, 'architecture',
        'On Pieni Roobertinkatu, a block south of the Esplanadi, at the shop window of stools and chairs.',
        ['Venue', 'Commerce', 'Architecture', 'Modernist', 'Hidden Gem', M, 'Alvar Aalto', 'Aino Aalto']),
    'Dance House Helsinki': ('02', 'hel-dance-house', 'Dance House Helsinki | Tanssin talo', 50,
        'musicAndPerformance',
        'On Kaapeliaukio, the square beside the old Cable Factory, facing the steel-clad Dance House.',
        ['Venue', 'Performance', 'Architecture', 'Contemporary', M, 'JKMM Architects', 'ILO Architects']),
    'Gallery Lemmetti': ('03', 'hel-gallery-lemmetti', 'Gallery Lemmetti', 40, 'visualArt',
        'At number eight Yrjönkatu, by the gallery window of Finnish glass, ceramics and lamps.',
        ['Venue', 'Art', 'Commerce', 'Modernist', 'Hidden Gem']),
    'Hakaniemi Market Square': ('04', 'hel-hakaniemi-market-square', 'Hakaniemi Market Square | Hakaniementori',
        60, 'culturalHeritage',
        'On the cobbled square, with the red-brick market hall along one edge and Paasitorni’s tower to the south-west.',
        ['Market', 'Public Square', 'Food', 'Commerce', 'History', 'Power', 'Free to Visit', M,
         'Einar Flinckenberg']),
    'Helsinki Central Station': ('CS', 'hel-central-station',
        'Helsinki Central Station | Helsingin päärautatieasema', 60, 'architecture',
        'On Kaivokatu, across from the main entrance, facing the granite Lantern Carriers and the clock tower.',
        ['Notable Building', 'Architecture', 'History', 'Public Art', 'Iconic Landmark', 'Free to Visit', M,
         'Eliel Saarinen']),
    'Katajanokka': ('05', 'hel-katajanokka', 'Katajanokka', 50, 'architecture',
        'On Luotsikatu, between the Tallberg House at number one and the Aeolus House across the street.',
        ['District', 'Architecture', 'History', 'Free to Visit', M, 'Herman Gesellius', 'Armas Lindgren',
         'Eliel Saarinen', 'Selim A. Lindqvist']),
    'Konditoria Hopia': ('06', 'hel-konditoria-hopia', 'Konditoria Hopia', 40, 'foodAndDrink',
        'At number nine Pohjoinen Hesperiankatu in Taka-Töölö, by the door of the little café.',
        ['Venue', 'Food', 'History', 'Hidden Gem']),
    'Kulttuurisauna': ('07', 'hel-kulttuurisauna', 'Culture Sauna | Kulttuurisauna', 40, 'architecture',
        'On the Hakaniemenranta shore path, by the low white sauna and its concrete pyramid.',
        ['Venue', 'Architecture', 'Waterfront', 'Contemporary', 'Hidden Gem', M, 'Tuomas Toivonen',
         'Nene Tsuboi']),
    'Lapuan Kankurit': ('08', 'hel-lapuan-kankurit', 'Lapuan Kankurit', 40, 'culturalHeritage',
        'At number two Katariinankatu, between the Market Square and Senate Square, by the linen window.',
        ['Venue', 'Commerce', 'Fashion', 'Hidden Gem']),
    'Lokal Gallery': ('09', 'hel-lokal', 'Lokal', 40, 'visualArt',
        'At number nine Annankatu in Punavuori, looking into the gallery’s two ground-floor rooms.',
        ['Venue', 'Art', 'Commerce', 'Contemporary', 'Hidden Gem']),
    'Majamaja': ('10', 'hel-majamaja', 'Majamaja', 60, 'architecture',
        'On the rocks of Vuorilahdenniemi in Laajasalo, by the row of small black cabins along the shore.',
        ['Notable Building', 'Architecture', 'Engineering', 'Waterfront', 'Contemporary', 'Green Escape',
         'Viewpoint', M, 'Pekka Littow']),
    'Pata#U00e4ss#U00e4': ('11', 'hel-pataassa', 'Pataässä', 40, 'musicAndPerformance',
        'At number thirteen Snellmaninkatu, a few doors from the House of the Estates.',
        ['Venue', 'Performance', 'After Dark', 'Hidden Gem']),
    'Ravintola Nolla': ('12', 'hel-nolla', 'Nolla', 40, 'foodAndDrink',
        'At number twenty-two Fredrikinkatu in Punavuori, outside the restaurant door.',
        ['Venue', 'Food', 'Contemporary', 'Hidden Gem']),
    'Restaurant BasBas Kulma': ('13', 'hel-basbas-kulma', 'BasBas Kulma', 40, 'foodAndDrink',
        'On the corner where Tehtaankatu meets Telakkakatu, outside the long bar counter.',
        ['Venue', 'Food', 'After Dark']),
    'Restaurant Kuurna': ('KU', 'hel-kuurna', 'Kuurna', 40, 'foodAndDrink',
        'At number six Meritullinkatu in Kruununhaka, by the modest street-level doorway.',
        ['Venue', 'Food', 'Hidden Gem']),
    'Restaurant Sea Horse': ('14', 'hel-sea-horse', 'Sea Horse', 40, 'foodAndDrink',
        'At number eleven Kapteeninkatu in Ullanlinna, outside the restaurant.',
        ['Venue', 'Food', 'History', 'Art']),
    'Savoy': ('15', 'hel-savoy', 'Savoy', 40, 'foodAndDrink',
        'In front of number fourteen on the South Esplanade; the restaurant fills the top two floors.',
        ['Venue', 'Food', 'Architecture', 'Modernist', 'Viewpoint', M, 'Alvar Aalto', 'Aino Aalto',
         'Ilse Crawford']),
    'Viinibaari Apotek': ('16', 'hel-apotek', 'Wine Bar Apotek | Viinibaari Apotek', 40, 'foodAndDrink',
        'Where Lapinlahdenkatu meets Eerikinkatu, at the corner windows of the old pharmacy.',
        ['Venue', 'Food', 'History', 'After Dark', 'Hidden Gem']),
    'Yrj#U00f6nkatu Swimming Hall': ('18', 'hel-yrjonkatu-swimming-hall',
        'Yrjönkatu Swimming Hall | Yrjönkadun uimahalli', 50, 'architecture',
        'At number twenty-one Yrjönkatu, by the entrance and its photographs printed on glass.',
        ['Venue', 'Architecture', 'Neoclassical', 'History', 'Hidden Gem', M, 'Väinö Vähäkallio']),
}

# Katajanokka (contributor, 2026-10-22): the folder's point was on Linnankatu, ~330 m from the Luotsikatu houses
# the script describes; moved to Luotsikatu 1 (the Tallberg House), per OSM.
COORD_OVERRIDE = {'05': ('60.16800', '24.96315')}


def paragraphs(f, titled):
    t = open(f, encoding='utf-8').read()
    if titled:
        t = t.split('\n', 1)[1]  # first line is the title
    ps = [p.strip() for p in re.split(r'\n\s*\n', t) if p.strip()]
    return [p for p in ps if p != '[beat]']


def cut(t, n=145):
    t = re.sub(r'\s+', ' ', t)
    if len(t) <= n:
        return t
    return t[:n].rsplit(' ', 1)[0].rstrip(',;:—-') + '…'


def duration(f):
    return round(float(subprocess.check_output(
        ['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', f])))


folders = {}
for d in sorted(os.listdir(DROP)):
    m = re.match(r'output (.*) (-?\d+\.\d+), (-?\d+\.\d+)$', d)
    if not m:
        continue
    key = [k for k in META if m.group(1).startswith(k)]
    assert len(key) == 1, (d, key)
    folders[key[0]] = (os.path.join(DROP, d), m.group(2), m.group(3))
assert sorted(folders) == sorted(META), set(folders) ^ set(META)

d = json.load(open(P))
assert not any(m['id'] == MAKER for m in d['makers'])
os.makedirs(f'{OUT}/audio', exist_ok=True)
os.makedirs(f'{OUT}/images', exist_ok=True)
os.makedirs(D + 'scripts', exist_ok=True)
new, tsv = [], []
for key, (n, slug, title, r, cat, caption, tags) in sorted(META.items(), key=lambda kv: kv[1][0]):
    src, la, lo = folders[key]
    la, lo = COORD_OVERRIDE.get(n, (la, lo))
    txts = sorted(glob.glob(f'{src}/*.txt'))
    clean = [t for t in txts if t.endswith('_clean.txt')]
    if clean:
        script, titled = clean[0], False
        safe = clean[0][:-len('_clean.txt')] + '_tts-safe.txt'
    else:
        script = [t for t in txts if not t.endswith('-tts.txt')][0]
        safe, titled = script[:-4] + '-tts.txt', True
    for f in (script, safe):
        shutil.copyfile(f, D + 'scripts/' + os.path.basename(f))
    ps = paragraphs(script, titled)
    txt = '\n\n'.join(ps)
    mp3s = glob.glob(f'{src}/*.mp3')
    assert len(mp3s) == 1, (n, mp3s)
    du = duration(mp3s[0])
    shutil.copyfile(mp3s[0], f'{OUT}/audio/{slug}.mp3')
    # the drop's own *_hero leads, or a numbered 01; then name order (all photos arrive as 1200x900 WebP;
    # Apotek's lost their .webp extension to a colon in the name, so match every non-audio, non-text file)
    imgs = [p for p in glob.glob(f'{src}/*') if not p.endswith(('.mp3', '.txt'))]
    imgs = sorted(imgs, key=lambda p: (not p.endswith('_hero.webp'), p))
    assert imgs and (imgs[0].endswith('_hero.webp') or os.path.basename(imgs[0]).startswith('01 ')), (n, imgs)
    names = [f'{slug}_hero.webp'] + [f'{slug}_{i}.webp' for i in range(2, len(imgs) + 1)]
    for a, b in zip(imgs, names):
        shutil.copyfile(a, f'{OUT}/images/{b}')
    hero = B + 'images/' + names[0]
    stop = dict(id=U(f'atlas-stop:hel:{slug}:1'), order=0, title=title, caption=caption,
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=r,
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:hel:{slug}'), createdAt='2026-10-22', title=title,
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city='Helsinki', country='Finland', relatedTourIds=[], primaryCategory=cat,
                    tags=tags, priceUSD=0))
    tsv.append('\t'.join([n, slug, la, lo, str(r), cat, os.path.basename(src)]))

maker = dict(id=MAKER, displayName='Atlas Studio HEL', platform='dozent', handle='atlas.hel', avatarURL=None,
             avatarEmoji='🇫🇮',
             bio="Atlas Studio's Helsinki bureau — the granite capital on the Baltic, where Saarinen's station "
                 "and the Aaltos' furniture set the tone, the saunas and swimming halls keep their own rules, and "
                 "the kitchens bake Karelian pies and cook as close to zero waste as they can.",
             websiteURL=None)
last = max(i for i, m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio'))
d['makers'].insert(last + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
open(D + 'coordinates.tsv', 'w').write('\n'.join(tsv) + '\n')
print(len(new), 'tours added; maker', MAKER)
for t in new:
    print(f"{t['title'][:40]:40} {t['stops'][0]['audioDurationSeconds']:4}s imgs={1 + len(t['additionalImageURLs'])} r={t['stops'][0]['triggerRadiusMeters']}")
