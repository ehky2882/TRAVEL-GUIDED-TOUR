"""Assemble Atlas Studio OSL (17 Oslo singles) into Tours.json.

Adapted from drafts/warsaw-batch1/tools/wire_warsaw.py. Usage:
    python3 wire_oslo.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders (numbered by the NN_ prefix of each folder's
`NN_<slug>_clean.txt`, title on line 1), takes each coordinate from its folder name unless COORD_OVERRIDE
says otherwise, writes Tours.json and drafts/oslo-batch1/coordinates.tsv, copies both script texts into
drafts/oslo-batch1/scripts/, and copies audio/<slug>.mp3 and images/<slug>_hero.webp, _2.webp … into the
staging dir for one gh-pages commit. Every slug carries an `osl-` prefix so no Oslo file can land on an
existing name.
"""
import json, uuid, re, os, sys, glob, shutil, mutagen

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/oslo-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:osl')
DROP, OUT = sys.argv[1], sys.argv[2]
M = 'Designed by a Master'

# num: (slug, title, radius, category, caption, tags)
# English | Norwegian where the two names genuinely differ; venues and names used as-is keep one name.
# Number 16 is absent on purpose (skipped by the contributor).
META = {
    '01': ('osl-aesop-prinsens-gate', 'Aesop Prinsens gate', 40, 'architecture',
           'At Prinsens gate twenty-one in Kvadraturen, by the counter under the domed ceiling.',
           ['Venue', 'Commerce', 'Architecture', 'Contemporary', 'Hidden Gem', M, 'Snøhetta']),
    '02': ('osl-amerikalinjen', 'Amerikalinjen', 40, 'history',
           'On Jernbanetorget by Oslo Central Station, facing the tritons over the door.',
           ['Notable Building', 'Immigration', 'Maritime', 'Architecture', M, 'Bjercke & Eliassen']),
    '03': ('osl-astrup-fearnley-museum', 'Astrup Fearnley Museum of Modern Art | Astrup Fearnley Museet', 50,
           'visualArt',
           'Halfway across the footbridge over the canal on Tjuvholmen, under the glass sail.',
           ['Museum', 'Art', 'Architecture', 'Waterfront', 'Public Art', 'Contemporary', M,
            'Renzo Piano', 'Narud Stokke Wiig']),
    '04': ('osl-deichman-bjorvika', 'Deichman Bjørvika', 50, 'architecture',
           'On the square between Oslo Central Station and the water, below the overhanging top floor.',
           ['Library', 'Architecture', 'Literature', 'Contemporary', 'Free to Visit', M,
            'Atelier Oslo', 'Lundhagem']),
    '05': ('osl-eff-eff', 'Eff Eff Oyster and Wine Bar', 40, 'foodAndDrink',
           'On Fredensborgveien at number twenty-two A, by the small street-level bar.',
           ['Venue', 'Food', 'Maritime', 'Hidden Gem']),
    '06': ('osl-elan', 'élan', 40, 'foodAndDrink',
           'At Kirkegata seven in Kvadraturen, by the round oak counter under the turquoise ring.',
           ['Venue', 'Food', 'Architecture', 'Contemporary', M, 'Snøhetta']),
    '07': ('osl-holmenkollen-ski-museum', 'Holmenkollen Ski Museum | Holmenkollen skimuseum', 60,
           'culturalHeritage',
           'At the foot of the Holmenkollen jump tower, where the museum is built into the hill.',
           ['Museum', 'History', 'Engineering', 'Iconic Landmark', 'Viewpoint', M, 'Snøhetta', 'Julien De Smedt']),
    '08': ('osl-kafeteria-august', 'Kafeteria August', 40, 'foodAndDrink',
           'In the courtyard through the gateway at Universitetsgata nine, near Tullinløkka.',
           ['Venue', 'Food', 'After Dark', 'Hidden Gem']),
    '09': ('osl-havnelageret', 'Harbour Warehouse | Havnelageret', 50, 'architecture',
           'On the quayside along Langkaia, below the warehouse’s long front and tower.',
           ['Notable Building', 'Architecture', 'Engineering', 'Maritime', 'War', 'Waterfront', M,
            'Bredo Henrik Berntsen']),
    '10': ('osl-moniker', 'Moniker Oslo', 40, 'architecture',
           'On Valkyrie plass in Majorstuen, just inside the door at Valkyriegata three.',
           ['Venue', 'Fashion', 'Commerce', 'Contemporary', M, 'Snøhetta']),
    '11': ('osl-munch', 'MUNCH', 50, 'visualArt',
           'On the open quayside at the museum’s foot, far enough back to see all thirteen storeys.',
           ['Museum', 'Art', 'Architecture', 'Waterfront', 'Contemporary', 'Iconic Landmark', 'Viewpoint', M,
            'Juan Herreros']),
    '12': ('osl-oslo-city-hall', 'Oslo City Hall | Oslo rådhus', 50, 'architecture',
           'In the courtyard facing Fridtjof Nansens plass, among the carved Yggdrasil reliefs.',
           ['Civic', 'Architecture', 'Power', 'Public Art', 'Iconic Landmark', 'Free to Visit', M,
            'Arnstein Arneberg', 'Magnus Poulsson']),
    '13': ('osl-oslo-opera-house', 'Oslo Opera House | Operahuset', 50, 'architecture',
           'At the foot of the white marble ramp that rises to the roof, by the waterfront.',
           ['Venue', 'Performance', 'Architecture', 'Waterfront', 'Contemporary', 'Iconic Landmark', 'Viewpoint',
            'Free to Visit', 'Public Art', M, 'Snøhetta']),
    '14': ('osl-sommerro', 'Sommerro', 40, 'architecture',
           'On Sommerrogata near Solli plass, facing the long block of the old electricity company.',
           ['Notable Building', 'Architecture', 'Art', 'History', M, 'Bjercke & Eliassen']),
    '15': ('osl-summit-bar', 'Summit Bar', 40, 'foodAndDrink',
           'Twenty-one storeys up, at the top of the Radisson Blu Scandinavia on Holbergs gate.',
           ['Venue', 'Food', 'Viewpoint', 'After Dark', 'Contemporary', M, 'Snøhetta']),
    '17': ('osl-vigeland-park', 'Vigeland Park | Vigelandsparken', 50, 'visualArt',
           'On the stepped platform at the park’s highest point, below the Monolith.',
           ['Park', 'Art', 'Public Art', 'Green Escape', 'Iconic Landmark', 'Free to Visit', M,
            'Gustav Vigeland']),
    '18': ('osl-tim-wendelboe', 'Tim Wendelboe', 40, 'foodAndDrink',
           'At Grüners gate one in Grünerløkka, by the small, plain shopfront.',
           ['Venue', 'Food', 'Commerce', 'Hidden Gem']),
}

# The folder's point sits on MUNCH's north tip; the script stands the listener on the quay at its foot,
# so this is the west quay facing the Opera House (from the OSM footprint, way "Munchmuseet").
COORD_OVERRIDE = {'11': ('59.905800', '10.754600')}


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
    stop = dict(id=U(f'atlas-stop:osl:{slug}:1'), order=0, title=title, caption=caption,
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=r,
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:osl:{slug}'), createdAt='2026-10-21', title=title,
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city='Oslo', country='Norway', relatedTourIds=[], primaryCategory=cat,
                    tags=tags, priceUSD=0))
    tsv.append('\t'.join([n, slug, la, lo, str(r), cat, os.path.basename(src)]))

maker = dict(id=MAKER, displayName='Atlas Studio OSL', platform='dozent', handle='atlas.osl', avatarURL=None,
             avatarEmoji='🇳🇴',
             bio="Atlas Studio's Oslo bureau — an architect's guide to a city that rebuilt its harbour as a "
                 "stage: Snøhetta's marble roof and the museums lined up beside it, the City Hall and Vigeland's "
                 "granite, and the coffee bars, shops and hotels where Oslo lives now.",
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
