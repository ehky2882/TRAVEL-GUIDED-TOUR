"""Assemble Atlas Studio BEL (11 Belém singles) into Tours.json.

Adapted from drafts/belem-batch1/tools/wire_oslo.py. Usage:
    python3 wire_belem.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders (numbered by the NN_ prefix of each folder's
`NN_<slug>_clean.txt`, title on line 1), takes each coordinate from its folder name unless COORD_OVERRIDE
says otherwise, writes Tours.json and drafts/belem-batch1/coordinates.tsv, copies both script texts into
drafts/belem-batch1/scripts/, and copies audio/<slug>.mp3 and images/<slug>_hero.webp, _2.webp … into the
staging dir for one gh-pages commit. Every slug carries a `bel-` prefix so no Belém file can land on an
existing name.
"""
import json, uuid, re, os, sys, glob, shutil, mutagen

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/belem-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:bel')
DROP, OUT = sys.argv[1], sys.argv[2]
M = 'Designed by a Master'

# num: (slug, title, radius, category, caption, tags)
# English | Portuguese where the two names genuinely differ; venues and names used as-is keep one name.
META = {
    '01': ('bel-casa-do-saulo-onze-janelas', 'Casa do Saulo das Onze Janelas', 40, 'foodAndDrink',
           'On the riverside terrace of the Casa das Onze Janelas, beside the old fort in Cidade Velha.',
           ['Venue', 'Food', 'Waterfront', 'Colonial', 'History', M, 'Antonio Landi']),
    '02': ('bel-estacao-das-docas', 'Docks Station | Estação das Docas', 60, 'architecture',
           'On the riverfront promenade, between the old port cranes and the three iron warehouses.',
           ['Waterfront', 'Maritime', 'Engineering', 'Commerce', 'Food', 'After Dark', 'Free to Visit',
            'Iconic Landmark']),
    '03': ('bel-muamba', 'Muamba Bar e Coquetéis', 40, 'foodAndDrink',
           'At the small container bar with white tiled walls, where the recipes are written on the tiles.',
           ['Venue', 'Food', 'After Dark', 'Hidden Gem']),
    '04': ('bel-museu-das-amazonias', 'Museum of the Amazons | Museu das Amazônias', 50, 'culturalHeritage',
           'At Porto Futuro warehouse four, on the waterfront just north of Estação das Docas.',
           ['Museum', 'Waterfront', 'Art', 'History', 'Contemporary', 'Free to Visit']),
    '05': ('bel-palacete-bolonha', 'Bolonha Palace | Palacete Bolonha', 50, 'architecture',
           'Across Avenida Governador José Malcher, facing the Art Nouveau gate and the lookout on top.',
           ['Notable Building', 'Museum', 'Architecture', 'History', 'Free to Visit', M, 'Francisco Bolonha']),
    '06': ('bel-parque-linear-da-doca', 'Doca Linear Park | Parque Linear da Doca', 60, 'natureAndParks',
           'On a footbridge over the canal down the middle of Avenida Visconde de Souza Franco.',
           ['Park', 'Green Escape', 'Free to Visit', 'Contemporary', 'History', M, 'Natureza Urbana']),
    '07': ('bel-restaurante-rua-belem', 'Restaurante Rua Belém', 40, 'foodAndDrink',
           'Outside number 468 Avenida Generalíssimo Deodoro in Umarizal, by the neon-lit doorway.',
           ['Venue', 'Food', 'Immigration', 'After Dark']),
    '08': ('bel-theatro-da-paz', 'Theatro da Paz', 50, 'musicAndPerformance',
           'Under the mango trees of Praça da República, far enough back to take in the whole front.',
           ['Venue', 'Performance', 'Architecture', 'History', 'Neoclassical', 'Iconic Landmark']),
    '09': ('bel-ver-o-pesinho', 'Ver-o-Pesinho Casa & Café', 40, 'foodAndDrink',
           'Through the front door on Travessa Benjamin Constant in Nazaré, by the café counter.',
           ['Venue', 'Food', 'Commerce', 'Hidden Gem']),
    '10': ('bel-ver-o-peso', 'Ver-o-Peso Market | Mercado Ver-o-Peso', 60, 'culturalHeritage',
           'With your back to the city, facing the iron fish market at the water’s edge.',
           ['Market', 'Food', 'Commerce', 'Waterfront', 'Engineering', 'Colonial', 'History', 'Iconic Landmark',
            'Free to Visit']),
    '11': ('bel-vila-gale-amazonia', 'Vila Galé Collection Amazônia', 50, 'architecture',
           'On the Porto Futuro waterfront, facing warehouses seven, eight and eight A.',
           ['Notable Building', 'Architecture', 'History', 'Waterfront', 'Maritime']),
}

# Both from Google Maps pins the contributor supplied on 2026-10-21, replacing the folder-name points.
COORD_OVERRIDE = {'03': ('-1.4463218155965005', '-48.498597975460996'),
                  '09': ('-1.4572820020680872', '-48.487694251577324')}


def paragraphs(f):
    t = open(f, encoding='utf-8').read().split('\n', 1)[1]  # first line is the title
    ps = [p.strip() for p in re.split(r'\n\s*\n', t) if p.strip()]
    return [p for p in ps if p != '[beat]']


def cut(t, n=145):
    t = re.sub(r'\s+', ' ', t)
    if len(t) <= n:
        return t
    return t[:n].rsplit(' ', 1)[0].rstrip(',;:—-') + '…'


folders = {}
for d in sorted(os.listdir(DROP)):
    m = re.match(r'output .* (-?\d+\.\d+), (-?\d+\.\d+)$', d)
    txt = glob.glob(os.path.join(DROP, d, '*_clean.txt'))
    if m and txt:
        folders[os.path.basename(txt[0])[:2]] = (os.path.join(DROP, d), txt[0], m.group(1), m.group(2))
assert sorted(folders) == sorted(META), set(folders) ^ set(META)

d = json.load(open(P))
assert not any(m['id'] == MAKER for m in d['makers'])
os.makedirs(f'{OUT}/audio', exist_ok=True)
os.makedirs(f'{OUT}/images', exist_ok=True)
os.makedirs(D + 'scripts', exist_ok=True)
new, tsv = [], []
for n in sorted(META):
    slug, title, r, cat, caption, tags = META[n]
    src, script, la, lo = folders[n]
    la, lo = COORD_OVERRIDE.get(n, (la, lo))
    stem = os.path.basename(script)[:-len('_clean.txt')]
    shutil.copyfile(script, f'{D}scripts/{stem}_clean.txt')
    shutil.copyfile(f'{src}/{stem}_tts-safe.txt', f'{D}scripts/{stem}_tts-safe.txt')
    ps = paragraphs(script)
    txt = '\n\n'.join(ps)
    mp3s = glob.glob(f'{src}/*.mp3')
    assert len(mp3s) == 1, (n, mp3s)
    du = round(mutagen.File(mp3s[0]).info.length)
    shutil.copyfile(mp3s[0], f'{OUT}/audio/{slug}.mp3')
    # the drop's own *_hero leads, or a numbered 01; then name order (all photos arrive as 1200x900 WebP)
    imgs = sorted(glob.glob(f'{src}/*.webp'), key=lambda p: (not p.endswith('_hero.webp'), p))
    assert imgs and (imgs[0].endswith('_hero.webp') or os.path.basename(imgs[0]).startswith('01 ')), (n, imgs)
    names = [f'{slug}_hero.webp'] + [f'{slug}_{i}.webp' for i in range(2, len(imgs) + 1)]
    for a, b in zip(imgs, names):
        shutil.copyfile(a, f'{OUT}/images/{b}')
    hero = B + 'images/' + names[0]
    stop = dict(id=U(f'atlas-stop:bel:{slug}:1'), order=0, title=title, caption=caption,
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=r,
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:bel:{slug}'), createdAt='2026-10-21', title=title,
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city='Belém', country='Brazil', relatedTourIds=[], primaryCategory=cat,
                    tags=tags, priceUSD=0))
    tsv.append('\t'.join([n, slug, la, lo, str(r), cat, os.path.basename(src)]))

maker = dict(id=MAKER, displayName='Atlas Studio BEL', platform='dozent', handle='atlas.bel', avatarURL=None,
             avatarEmoji='🇧🇷',
             bio="Atlas Studio's Belém bureau — the city at the mouth of the Amazon, where rubber money built an opera "
                 "house and iron markets, the old port has been handed back to the river, and the kitchens and bars "
                 "cook with jambu, açaí and fish from upstream.",
             websiteURL=None)
last = max(i for i, m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio'))
d['makers'].insert(last + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
open(D + 'coordinates.tsv', 'w').write('\n'.join(tsv) + '\n')
print(len(new), 'tours added; maker', MAKER)
for t in new:
    print(f"{t['title'][:34]:34} {t['stops'][0]['audioDurationSeconds']:4}s imgs={1 + len(t['additionalImageURLs'])} r={t['stops'][0]['triggerRadiusMeters']}")
