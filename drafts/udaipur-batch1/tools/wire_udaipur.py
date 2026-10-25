"""Assemble Atlas Studio UDR (23 Udaipur singles) into Tours.json.

Adapted from drafts/mumbai-batch1/tools/wire_mumbai.py. Usage:
    python3 wire_udaipur.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders (numbered by the udaipur_NN_ prefix
of each folder's script), writes Tours.json, and copies audio/<slug>.mp3 and
images/<slug>_hero.webp, _2.webp … into the staging dir for one gh-pages commit.
Every slug carries a `udr-` prefix so no Udaipur file can land on an existing name.
Number 19 was left out of the drop on purpose.
"""
import json, uuid, re, os, sys, glob, shutil, mutagen

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/udaipur-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:udr')
DROP, OUT = sys.argv[1], sys.argv[2]

# Hindi (Devanagari) for the landmarks, checked against Google Maps' Hindi labels; venues keep one name
TITLE = {
    '01': 'Syah', '02': 'Page Break at Manuscript', '03': 'Bougainvillea Terrace by the Lake',
    '04': 'Upri Manzil Rooftop', '05': 'The Lily Court', '06': 'Ninkasi', '07': "O'Brew", '08': 'Aosa Café',
    '09': 'Tapri Niwas', '10': 'RAAS Devigarh', '11': 'Kaladwas Lal Haveli', '12': 'The Oberoi Udaivilas',
    '13': 'Old City Market | मोचीवाडा', '14': 'Bougainvillaea Art Gallery', '15': 'Ganesh Emporium', '16': 'Ladu',
    '17': 'Third Space', '18': 'City Palace | सिटी पैलेस', '20': 'Gulab Bagh | गुलाब बाग',
    '21': 'Sunset on the Fateh Sagar Pal | फ़तेह सागर पाल', '22': 'Manjhi Ka Ghat | मांझी का घाट',
    '23': 'The Climb to Karni Mata | करणी माता', '24': 'Udaan Park | उड़ान पार्क',
}
CAPTION = {
    '01': 'At Kasotia Ji Farm, off the Kodiyat road, six kilometres west of the city.',
    '02': 'On the roof of Manuscript, off Bhatiyani Chohatta, facing the City Palace.',
    '03': 'On the roof of Hotel Lakend, on the eastern shore of Fateh Sagar.',
    '04': 'On the rooftop near Hanuman Ghat, facing east across Lake Pichola.',
    '05': 'At the edge of the lily pond, off the highway north of the city near Kavita.',
    '06': 'In Fatehpura, Panchwati, just off the junction near UIT Circle.',
    '07': 'On the roof terrace at Ambavgarh, above Swaroop Sagar.',
    '08': 'In Fatehpura, Panchwati, a short walk from UIT Circle.',
    '09': "On the main road in New Fatehpura, near St Mary's School.",
    '10': 'At the foot of the hill in Delwara village, looking up at the fort.',
    '11': 'On Ganesh Ghati, facing the old house across from the clock tower.',
    '12': 'On the western shore of Lake Pichola, facing the City Palace across the water.',
    '13': 'In the lanes of Mochiwada, east of the clock tower.',
    '14': 'On the highway near Kavita, on the northern edge of the city.',
    '15': 'On City Palace Road, between the Jagdish Temple and the palace gates.',
    '16': "At the Tapri Niwas site in New Fatehpura, near St Mary's School.",
    '17': 'At the entrance to Third Space, Pahada, facing the marble jali screens.',
    '18': 'In the great courtyard just inside the Tripolia gate.',
    '20': 'At a gate on Gulab Bagh Road, south-east of the City Palace.',
    '21': 'On the Pal, the embankment along the eastern side of Fateh Sagar.',
    '22': 'On the steps of Manjhi Ka Ghat, on the western shore of Lake Pichola.',
    '23': 'At the foot of Machla Magra, where the path up to the temple begins.',
    '24': 'At the gate of Udaan Park, on the western bank of Swaroop Sagar.',
}
M = 'Designed by a Master'
TAGS = {
    '01': ['Venue', 'Food', 'Green Escape', 'Hidden Gem'],
    '02': ['Venue', 'Food', 'Viewpoint', 'Architecture'],
    '03': ['Venue', 'Food', 'Viewpoint', 'Waterfront'],
    '04': ['Venue', 'Food', 'Viewpoint', 'Waterfront', 'After Dark'],
    '05': ['Venue', 'Food', 'Green Escape'],
    '06': ['Venue', 'Food', 'After Dark', 'Contemporary', M, 'Studio Rust'],
    '07': ['Venue', 'Food', 'Viewpoint', 'Hidden Gem'],
    '08': ['Venue', 'Food'],
    '09': ['Venue', 'Food', 'Hidden Gem'],
    '10': ['Notable Building', 'History', 'Power', 'Architecture', 'Contemporary'],
    '11': ['Notable Building', 'Architecture', 'History', 'Hidden Gem'],
    '12': ['Notable Building', 'Architecture', 'Waterfront', 'Viewpoint', 'Contemporary'],
    '13': ['Market', 'District', 'Commerce', 'Free to Visit'],
    '14': ['Venue', 'Art', 'Contemporary'],
    '15': ['Market', 'Commerce', 'Fashion', 'Architecture'],
    '16': ['Market', 'Commerce', 'Hidden Gem'],
    '17': ['Notable Building', 'Architecture', 'Engineering', 'Contemporary', M, 'Studio Saar'],
    '18': ['Notable Building', 'History', 'Power', 'Waterfront', 'Iconic Landmark'],
    '20': ['Park', 'Library', 'History', 'Victorian', 'Green Escape', 'Free to Visit'],
    '21': ['Waterfront', 'Engineering', 'Viewpoint', 'Free to Visit', 'After Dark'],
    '22': ['Waterfront', 'History', 'Viewpoint', 'Iconic Landmark', 'Free to Visit', 'After Dark'],
    '23': ['Religious Building', 'Faith', 'Viewpoint', 'Free to Visit'],
    '24': ['Park', 'Waterfront', 'Architecture', 'Public Art', 'Contemporary', 'Green Escape', 'Free to Visit', M, 'Studio Saar'],
}
CITY = {'10': 'Delwara'}


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
    txt = [f for f in glob.glob(os.path.join(DROP, d, 'udaipur_*.txt')) if not f.endswith('_TTS.txt')]
    if txt:
        folders[os.path.basename(txt[0])[8:10]] = (os.path.join(DROP, d), txt[0])

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
    mp3s = glob.glob(f'{src}/*.mp3')
    assert len(mp3s) == 1, (n, mp3s)
    du = round(mutagen.File(mp3s[0]).info.length)
    shutil.copyfile(mp3s[0], f'{OUT}/audio/{slug}.mp3')
    # the drop's own hero (named *_hero.webp) leads when there is one; otherwise numbered order
    imgs = sorted(glob.glob(f'{src}/*.webp'), key=lambda p: (not p.endswith('_hero.webp'), p))
    names = [f'{slug}_hero.webp'] + [f'{slug}_{i}.webp' for i in range(2, len(imgs) + 1)]
    for a, b in zip(imgs, names):
        shutil.copyfile(a, f'{OUT}/images/{b}')
    hero = B + 'images/' + names[0]
    stop = dict(id=U(f'atlas-stop:udr:{slug}:1'), order=0, title=TITLE[n], caption=CAPTION[n],
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=int(r),
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:udr:{slug}'), createdAt='2026-10-16', title=TITLE[n],
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city=CITY.get(n, 'Udaipur'), country='India', relatedTourIds=[], primaryCategory=cat,
                    tags=TAGS[n], priceUSD=0))

maker = dict(id=MAKER, displayName='Atlas Studio UDR', platform='dozent', handle='atlas.udr', avatarURL=None,
             avatarEmoji='🇮🇳',
             bio="Atlas Studio's Udaipur bureau — audio tours of the City of Lakes: the City Palace and the ghats "
                 "of Lake Pichola, havelis turned into hotels and shops, rooftops facing the palace, a hill fort "
                 "in the Aravallis, and new buildings that borrow the old city's jali and courtyards.",
             websiteURL=None)
last = max(i for i, m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio'))
d['makers'].insert(last + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print(len(new), 'tours added; maker', MAKER)
for t in new:
    print(f"{t['title'][:34]:34} {t['city']:8} {t['stops'][0]['audioDurationSeconds']:4}s imgs={1 + len(t['additionalImageURLs'])} r={t['stops'][0]['triggerRadiusMeters']}")
