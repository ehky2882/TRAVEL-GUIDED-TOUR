"""Assemble Atlas Studio AKL (20 Auckland singles) into Tours.json.

Adapted from drafts/boston-batch1/tools/wire_city.py. Usage:
    python3 wire_auckland.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders (numbered by the NN_ prefix
of each folder's MP3), writes Tours.json, and copies audio/<slug>.mp3 and
images/<slug>_hero.webp, _2.webp … into the staging dir for one gh-pages commit.
"""
import json, uuid, re, os, sys, glob, shutil, mutagen

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/auckland-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:akl')
DROP, OUT = sys.argv[1], sys.argv[2]

TITLE = {'01': 'Bar Martin', '02': 'Blue', '03': 'Blue Rose Cafe & Catering', '04': 'Cafe Hanoi',
         '05': 'Gemmayze St', '06': 'Ghost Street', '07': 'Goblin', '09': 'HomeGround', '10': 'kingi',
         '11': 'Lamplight Books', '12': 'Metita', '13': 'Mr Morris', '14': 'OOH-FA', '15': 'Piha Beach',
         '16': 'Public Record', '17': 'Takutai Square', '18': 'Tala', '19': 'The Convent Boutique Hotel',
         '20': 'The Frog', '21': 'The Hotel Britomart'}
TAGS = {
    '01': ['Venue', 'Food', 'Hidden Gem', 'After Dark'],
    '02': ['Venue', 'Food', 'Hidden Gem'],
    '03': ['Venue', 'Food', 'Immigration', 'Hidden Gem'],
    '04': ['Venue', 'Food', 'Architecture', 'After Dark', 'Designed by a Master', 'Cheshire Architects'],
    '05': ['Venue', 'Food', 'Immigration', 'Art', 'Hidden Gem'],
    '06': ['Venue', 'Food', 'Victorian', 'Hidden Gem', 'After Dark'],
    '07': ['Venue', 'Food', 'After Dark', 'Hidden Gem'],
    '09': ['Notable Building', 'Architecture', 'Contemporary', 'Engineering', 'Free to Visit',
           'Designed by a Master', 'Stevens Lawson Architects'],
    '10': ['Venue', 'Food', 'Maritime', 'Victorian'],
    '11': ['Venue', 'Literature', 'Commerce', 'Contemporary', 'Free to Visit'],
    '12': ['Venue', 'Food', 'Immigration'],
    '13': ['Venue', 'Food', 'Victorian', 'Designed by a Master', 'Cheshire Architects'],
    '14': ['Venue', 'Food', 'Hidden Gem'],
    '15': ['Waterfront', 'History', 'Green Escape', 'Viewpoint', 'Iconic Landmark', 'Free to Visit'],
    '16': ['Venue', 'Art', 'Commerce', 'Fashion', 'Victorian', 'Free to Visit'],
    '17': ['Public Square', 'History', 'Maritime', 'Public Art', 'Free to Visit'],
    '18': ['Venue', 'Food', 'Immigration'],
    '19': ['Notable Building', 'Architecture', 'Faith', 'History'],
    '20': ['Venue', 'Food', 'Art', 'After Dark'],
    '21': ['Notable Building', 'Architecture', 'Contemporary', 'Designed by a Master', 'Cheshire Architects'],
}


def paragraphs(f):
    lines = open(f, encoding='utf-8').read().strip().split('\n', 1)
    ps = [p.strip() for p in re.split(r'\n\s*\n', lines[1]) if p.strip()]
    return [p for p in ps if p != '[beat]']


def first_sentence(p):
    return re.findall(r'.+?[.!?](?=\s|$)', p)[0]


def cut(t, n=145):
    t = t.replace('\n', ' ')
    if len(t) <= n:
        return t
    return t[:n].rsplit(' ', 1)[0].rstrip(',;:—-') + '…'


# folder number comes from its MP3's NN_ prefix; skip nested copies (a stray Metita sits inside Mr Morris)
folders = {}
for d in sorted(os.listdir(DROP)):
    mp3 = glob.glob(os.path.join(DROP, d, '*.mp3'))
    if mp3:
        folders[os.path.basename(mp3[0])[:2]] = os.path.join(DROP, d)

d = json.load(open(P))
assert not any(m['id'] == MAKER for m in d['makers'])
os.makedirs(f'{OUT}/audio', exist_ok=True)
os.makedirs(f'{OUT}/images', exist_ok=True)
new = []
for line in open(D + 'coordinates.tsv', encoding='utf-8'):
    n, slug, la, lo, r, cat, note = line.rstrip('\n').split('\t')
    src = folders[n]
    ps = paragraphs(glob.glob(f'{src}/*_clean.txt')[0])
    txt = '\n\n'.join(ps)
    mp3 = glob.glob(f'{src}/*.mp3')[0]
    du = round(mutagen.File(mp3).info.length)
    shutil.copyfile(mp3, f'{OUT}/audio/{slug}.mp3')
    imgs = sorted(glob.glob(f'{src}/*.webp'))
    names = [f'{slug}_hero.webp'] + [f'{slug}_{i}.webp' for i in range(2, len(imgs) + 1)]
    for a, b in zip(imgs, names):
        shutil.copyfile(a, f'{OUT}/images/{b}')
    hero = B + 'images/' + names[0]
    stop = dict(id=U(f'atlas-stop:akl:{slug}:1'), order=0, title=TITLE[n], caption=first_sentence(ps[1]),
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=int(r),
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:akl:{slug}'), createdAt='2026-10-07', title=TITLE[n],
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city='Auckland', country='New Zealand', relatedTourIds=[], primaryCategory=cat,
                    tags=TAGS[n], priceUSD=0))

maker = dict(id=MAKER, displayName='Atlas Studio AKL', platform='dozent', handle='atlas.akl', avatarURL=None,
             avatarEmoji='🇳🇿',
             bio="Atlas Studio's Auckland bureau — audio tours of a city built on reclaimed foreshore and volcanic "
                 "ground: a square laid over an old beach, a convent turned hotel, Pacific kitchens cooking at "
                 "the heart of town, and a black-sand beach on the wild west coast.",
             websiteURL=None)
last = max(i for i, m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio'))
d['makers'].insert(last + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print(len(new), 'tours added; maker', MAKER)
for t in new:
    print(f"{t['title'][:24]:24} {t['stops'][0]['audioDurationSeconds']:4}s imgs={1 + len(t['additionalImageURLs'])} | {t['stops'][0]['caption'][:70]}")
