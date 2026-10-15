"""Assemble Atlas Studio BOM (28 Mumbai singles) into Tours.json.

Adapted from drafts/hanoi-batch1/tools/wire_hanoi.py. Usage:
    python3 wire_mumbai.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders (numbered by the mumbai_NN_ prefix
of each folder's script), writes Tours.json, and copies audio/<slug>.mp3 and
images/<slug>_hero.webp, _2.webp … into the staging dir for one gh-pages commit.
Every slug carries a `bom-` prefix so no Mumbai file can land on an existing name.
Numbers 19, 20, 22, 25 and 27 were not in the drop.
"""
import json, uuid, re, os, sys, glob, shutil, mutagen

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/mumbai-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:bom')
DROP, OUT = sys.argv[1], sys.argv[2]

TITLE = {
    '01': 'ELCO Pani Puri Centre', '02': 'The Bombay Canteen', '03': 'Trishna', '04': 'Americano',
    '05': 'Café Madras', '06': "Ayub's", '07': 'Eau Bar, The Oberoi', '08': 'AER, Four Seasons Mumbai',
    '09': 'Slink & Bardot', '10': 'The Bombay Gymkhana', '11': 'Willingdon Sports Club',
    '12': 'Bastian At The Top', '13': 'The Taj Mahal Palace', '14': 'The Oberoi, Nariman Point',
    '15': 'The Royal Bombay Yacht Club', '16': 'InterContinental Marine Drive', '17': 'Colaba Causeway',
    '18': 'Kala Ghoda', '21': 'Chor Bazaar', '23': 'Gateway of India', '24': 'Marine Drive',
    '26': 'Chhatrapati Shivaji Maharaj Vastu Sangrahalaya', '28': 'Bandra–Worli Sea Link and the Coastal Road',
    '29': 'Dr Bhau Daji Lad Museum', '30': 'Girgaon Chowpatty', '31': "St. Mary's School, Mazagaon",
    '32': 'BMC Head Office', '33': 'David Sassoon Library and Reading Room',
}
M = 'Designed by a Master'
TAGS = {
    '01': ['Venue', 'Food', 'Immigration'],
    '02': ['Venue', 'Food'],
    '03': ['Venue', 'Food', 'Hidden Gem'],
    '04': ['Venue', 'Food'],
    '05': ['Venue', 'Food', 'Immigration'],
    '06': ['Venue', 'Food', 'After Dark'],
    '07': ['Venue', 'Food', 'Viewpoint', 'After Dark'],
    '08': ['Venue', 'Food', 'Viewpoint', 'After Dark'],
    '09': ['Venue', 'Food', 'After Dark', 'Colonial', 'Hidden Gem'],
    '10': ['Venue', 'History', 'Power', 'Colonial', M, 'Claude Batley'],
    '11': ['Venue', 'History', 'Power', 'Colonial', M, 'F. G. B. Hawkins'],
    '12': ['Venue', 'Food', 'Tower', 'Viewpoint', 'After Dark'],
    '13': ['Notable Building', 'Architecture', 'History', 'Remembrance', 'Colonial', 'Iconic Landmark', M,
           'Sitaram Khanderao Vaidya', 'D. N. Mirza'],
    '14': ['Notable Building', 'Waterfront', 'Engineering', 'Remembrance'],
    '15': ['Notable Building', 'Maritime', 'Gothic', 'Colonial', M, 'John Adams'],
    '16': ['Notable Building', 'Architecture', 'Waterfront', 'Art Deco', 'Contemporary'],
    '17': ['District', 'Market', 'Commerce', 'Engineering', 'Free to Visit'],
    '18': ['District', 'Art', 'Public Art', 'History', 'Free to Visit'],
    '21': ['Market', 'Commerce', 'Hidden Gem', 'Free to Visit'],
    '23': ['Monument', 'Maritime', 'Colonial', 'Iconic Landmark', 'Free to Visit', M, 'George Wittet'],
    '24': ['Waterfront', 'Architecture', 'Art Deco', 'Iconic Landmark', 'Free to Visit'],
    '26': ['Museum', 'History', 'Colonial', M, 'George Wittet'],
    '28': ['Bridge', 'Engineering', 'History', 'Viewpoint', 'Free to Visit'],
    '29': ['Museum', 'History', 'Victorian', 'Colonial'],
    '30': ['Waterfront', 'Food', 'Engineering', 'Free to Visit'],
    '31': ['Notable Building', 'Performance', 'Faith', 'Gothic'],
    '32': ['Civic', 'Power', 'Gothic', 'Colonial', 'Iconic Landmark', M, 'Frederick William Stevens'],
    '33': ['Library', 'Literature', 'Victorian', 'Gothic', M, 'J. Campbell', 'G. E. Gosling'],
}


def vantage(f):
    v = re.search(r'^Vantage:\s*(.+)$', open(f, encoding='utf-8').read(), re.M).group(1).strip()
    return v[0].upper() + v[1:].rstrip('.') + '.'

def paragraphs(f):
    body = open(f, encoding='utf-8').read().split('\n---\n', 1)[1]
    ps = [p.strip() for p in re.split(r'\n\s*\n', body) if p.strip()]
    return [p for p in ps if p != '[beat]']


def cut(t, n=145):
    t = re.sub(r'\s+', ' ', t)
    if len(t) <= n:
        return t
    return t[:n].rsplit(' ', 1)[0].rstrip(',;:—-') + '…'


folders = {}
for d in sorted(os.listdir(DROP)):
    txt = [f for f in glob.glob(os.path.join(DROP, d, 'mumbai_*.txt')) if not f.endswith('_TTS.txt')]
    if txt:
        folders[os.path.basename(txt[0])[7:9]] = (os.path.join(DROP, d), txt[0])

d = json.load(open(P))
assert not any(m['id'] == MAKER for m in d['makers'])
os.makedirs(f'{OUT}/audio', exist_ok=True)
os.makedirs(f'{OUT}/images', exist_ok=True)
new = []
for line in open(D + 'coordinates.tsv', encoding='utf-8'):
    n, slug, la, lo, r, cat, note = line.rstrip('\n').split('\t')
    src, script = folders[n]
    ps = paragraphs(script)
    txt = '\n\n'.join(ps)
    mp3 = glob.glob(f'{src}/*.mp3')[0]
    du = round(mutagen.File(mp3).info.length)
    shutil.copyfile(mp3, f'{OUT}/audio/{slug}.mp3')
    # the drop's own hero (named *_hero.webp) leads when there is one; otherwise numbered order
    imgs = sorted(glob.glob(f'{src}/*.webp'), key=lambda p: (not p.endswith('_hero.webp'), p))
    names = [f'{slug}_hero.webp'] + [f'{slug}_{i}.webp' for i in range(2, len(imgs) + 1)]
    for a, b in zip(imgs, names):
        shutil.copyfile(a, f'{OUT}/images/{b}')
    hero = B + 'images/' + names[0]
    stop = dict(id=U(f'atlas-stop:bom:{slug}:1'), order=0, title=TITLE[n], caption=vantage(script),
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=int(r),
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:bom:{slug}'), createdAt='2026-10-15', title=TITLE[n],
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city='Mumbai', country='India', relatedTourIds=[], primaryCategory=cat,
                    tags=TAGS[n], priceUSD=0))

maker = dict(id=MAKER, displayName='Atlas Studio BOM', platform='dozent', handle='atlas.bom', avatarURL=None,
             avatarEmoji='🇮🇳',
             bio="Atlas Studio's Mumbai bureau — audio tours of a city built on reclaimed islands: Gothic "
                 "offices and Art Deco seafronts, members' clubs and the clubs founded to answer them, kebab "
                 "counters, Udupi breakfasts and rooftop bars, and the stories the street names forgot.",
             websiteURL=None)
last = max(i for i, m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio'))
d['makers'].insert(last + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print(len(new), 'tours added; maker', MAKER)
for t in new:
    print(f"{t['title'][:30]:30} {t['stops'][0]['audioDurationSeconds']:4}s imgs={1 + len(t['additionalImageURLs'])} r={t['stops'][0]['triggerRadiusMeters']}")
