"""Assemble Atlas Studio VIE (35 Vienna singles) into Tours.json.

Adapted from drafts/udaipur-batch1/tools/wire_udaipur.py. Usage:
    python3 wire_vienna.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders (numbered by the NN_ prefix of each
folder's `NN_<slug>_clean.txt`), writes Tours.json, and copies audio/<slug>.mp3 and
images/<slug>_hero.webp, _2.webp … into the staging dir for one gh-pages commit.
Every slug carries a `vie-` prefix so no Vienna file can land on an existing name.
"""
import json, uuid, re, os, sys, glob, shutil, mutagen
from PIL import Image

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/vienna-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:vie')
DROP, OUT = sys.argv[1], sys.argv[2]

# English | German where the two names genuinely differ; venues and names used as-is keep one name
TITLE = {
    '01': 'Hotel Altstadt Vienna', '02': 'The Guesthouse Vienna', '03': 'Grand Ferdinand',
    '04': 'Hotel Daniel Vienna', '05': 'Steirereck', '06': 'Café Prückel', '07': 'Zum Schwarzen Kameel',
    '08': 'Gasthaus Pöschl', '09': 'Mayer am Pfarrplatz', '10': 'Kleines Café', '11': 'Das LOFT',
    '12': 'Café Sperl', '13': 'Café Museum', '14': 'Strandbar Herrmann', '15': 'J. & L. Lobmeyr',
    '16': 'Knize', '17': 'Mühlbauer', '18': 'Augarten Wien',
    '19': 'Austrian Postal Savings Bank | Österreichische Postsparkasse', '20': 'Looshaus',
    '21': 'Secession', '22': 'Otto Wagner Pavilion Karlsplatz', '23': 'Kirche am Steinhof',
    '24': 'Wittgenstein House | Haus Wittgenstein',
    '25': 'Church of the Most Holy Trinity | Wotrubakirche', '26': 'Karl-Marx-Hof',
    '27': 'Vienna Werkbund Estate | Werkbundsiedlung', '28': 'Library & Learning Center',
    '29': 'State Hall of the Austrian National Library | Prunksaal der Österreichischen Nationalbibliothek',
    '30': 'Furniture Museum Vienna | Hofmobiliendepot', '31': 'Haas-Haus',
    '32': 'Augarten Flak Tower | Flakturm Augarten',
    '33': 'Yppenplatz',
    '34': 'Church of St Charles Borromeo | Friedhofskirche zum Heiligen Karl Borromäus',
    '35': 'Kahlenberg',
}
CAPTION = {
    '01': 'On Kirchengasse, on the slope of Spittelberg, facing the hotel’s plain front door.',
    '02': 'On Führichgasse, with the Albertina on its terrace directly opposite.',
    '03': 'On the far side of the Schubertring, looking back across the tram lines.',
    '04': 'On the Landstraßer Gürtel, looking up at the boat on the roof.',
    '05': 'On the river path in the Stadtpark, beside the Wien river embankment.',
    '06': 'On the corner of the Stubenring and Dr-Karl-Lueger-Platz, opposite the MAK.',
    '07': 'On Bognergasse, a narrow street just off the Graben.',
    '08': 'On Weihburggasse, a step from the corner of Franziskanerplatz.',
    '09': 'On Pfarrplatz in Heiligenstadt, beside the little church of St Jakob.',
    '10': 'On Franziskanerplatz, by the Moses fountain, facing number three.',
    '11': 'On Praterstraße at the foot of the bridge, below the dark glass tower.',
    '12': 'On Gumpendorfer Straße, at the corner of Lehárgasse.',
    '13': 'At the corner of Operngasse and Friedrichstraße, facing the Secession.',
    '14': 'On the Danube Canal, where the Wien river flows in, opposite the Urania.',
    '15': 'On Kärntner Straße, between the Opera and St Stephen’s.',
    '16': 'On the Graben, with the Plague Column behind you.',
    '17': 'On Seilergasse, between Stephansplatz and the Neuer Markt.',
    '18': 'On Spiegelgasse, a narrow lane between the Graben and the Albertina.',
    '19': 'On Georg-Coch-Platz, just off the Ringstraße.',
    '20': 'On Michaelerplatz, with the gateway of the Hofburg behind you.',
    '21': 'On Friedrichstraße, a few steps from the Naschmarkt.',
    '22': 'On Karlsplatz, between the two pavilions, with the Karlskirche beyond.',
    '23': 'At the top of the Steinhof grounds, on the Baumgartner Höhe.',
    '24': 'On Kundmanngasse, at the garden wall of number nineteen.',
    '25': 'On the Georgenberg in Mauer, at the foot of the slope below the church.',
    '26': 'On Zwölfter-Februar-Platz, facing the great arches of the central block.',
    '27': 'In the lanes of the estate in Hietzing, at the foot of the Roter Berg.',
    '28': 'On the WU campus plaza, beneath the library’s leaning front.',
    '29': 'On Josefsplatz, by the statue of Joseph the Second, facing the old court library.',
    '30': 'On Andreasgasse, just off Mariahilfer Straße.',
    '31': 'On Stephansplatz, with your back to the cathedral’s west front.',
    '32': 'On the main chestnut avenue of the Augarten, looking up at the round tower.',
    '33': 'On Yppenplatz, at the upper end of the Brunnenmarkt.',
    '34': 'At the foot of the steps up to the church, at the end of the cemetery’s central avenue.',
    '35': 'On the viewing terrace at the summit, looking down over the vineyards to the city.',
}
M = 'Designed by a Master'
TAGS = {
    '01': ['Notable Building', 'Art', 'Architecture', 'Hidden Gem'],
    '02': ['Notable Building', 'Architecture', 'Food', 'Contemporary', M, 'Conran and Partners'],
    '03': ['Notable Building', 'Architecture', 'Modernist', 'Viewpoint', M, 'Atelier Heiss'],
    '04': ['Notable Building', 'Architecture', 'Modernist', 'Public Art', M, 'Georg Lippert', 'Atelier Heiss'],
    '05': ['Venue', 'Food', 'Contemporary', 'Green Escape', M, 'PPAG architects'],
    '06': ['Venue', 'Food', 'Performance', 'Modernist', M, 'Oswald Haerdtl'],
    '07': ['Venue', 'Food', 'Commerce', 'History'],
    '08': ['Venue', 'Food', 'Hidden Gem', M, 'Hermann Czech'],
    '09': ['Venue', 'Food', 'History', 'Performance', 'Green Escape'],
    '10': ['Venue', 'Food', 'Hidden Gem', M, 'Hermann Czech'],
    '11': ['Venue', 'Food', 'Tower', 'Viewpoint', 'After Dark', 'Public Art', 'Contemporary', M, 'Jean Nouvel'],
    '12': ['Venue', 'Food', 'History', 'Art'],
    '13': ['Venue', 'Food', 'Art', 'Modernist', M, 'Adolf Loos'],
    '14': ['Venue', 'Waterfront', 'Food', 'After Dark'],
    '15': ['Venue', 'Commerce', 'Art', 'History', 'Hidden Gem'],
    '16': ['Notable Building', 'Fashion', 'Commerce', 'Modernist', M, 'Adolf Loos'],
    '17': ['Venue', 'Fashion', 'Commerce', 'Contemporary', M, 'Kühn Malvezzi'],
    '18': ['Venue', 'Commerce', 'Art', 'History'],
    '19': ['Notable Building', 'Architecture', 'Engineering', 'Modernist', 'Iconic Landmark', M, 'Otto Wagner'],
    '20': ['Notable Building', 'Architecture', 'Power', 'Modernist', 'Iconic Landmark', 'Free to Visit', M, 'Adolf Loos'],
    '21': ['Museum', 'Art', 'Architecture', 'Iconic Landmark', M, 'Joseph Maria Olbrich'],
    '22': ['Notable Building', 'Architecture', 'Engineering', 'Museum', 'Free to Visit', M, 'Otto Wagner'],
    '23': ['Religious Building', 'Faith', 'Architecture', 'Viewpoint', 'Iconic Landmark', M, 'Otto Wagner'],
    '24': ['Notable Building', 'Architecture', 'Literature', 'Modernist', 'Hidden Gem', M, 'Paul Engelmann', 'Ludwig Wittgenstein'],
    '25': ['Religious Building', 'Faith', 'Brutalist', 'Hidden Gem', M, 'Fritz Wotruba'],
    '26': ['Notable Building', 'Architecture', 'Power', 'War', 'Modernist', 'Iconic Landmark', 'Free to Visit', M, 'Karl Ehn'],
    '27': ['District', 'Architecture', 'Modernist', 'Hidden Gem', 'Free to Visit', M, 'Josef Frank', 'Adolf Loos', 'Josef Hoffmann', 'Gerrit Rietveld', 'Richard Neutra'],
    '28': ['Library', 'Architecture', 'Engineering', 'Contemporary', M, 'Zaha Hadid'],
    '29': ['Library', 'History', 'Power', 'Baroque', 'Iconic Landmark', M, 'Johann Bernhard Fischer von Erlach'],
    '30': ['Museum', 'History', 'Power', 'Hidden Gem'],
    '31': ['Notable Building', 'Architecture', 'Contemporary', 'Viewpoint', M, 'Hans Hollein'],
    '32': ['Tower', 'Park', 'War', 'Remembrance', 'Free to Visit'],
    '33': ['Public Square', 'Market', 'Food', 'Immigration', 'Commerce', 'Free to Visit'],
    '34': ['Religious Building', 'Faith', 'Remembrance', 'Performance', M, 'Max Hegele'],
    '35': ['Park', 'Viewpoint', 'History', 'War', 'Green Escape', 'Free to Visit'],
}
# Werkbundsiedlung's hero arrived under a hash-like name rather than *_hero
HERO_OVERRIDE = {'27': 'iqpxkuo1jxi8npecbwq4.webp'}


def paragraphs(f):
    lines = open(f, encoding='utf-8').read().split('\n', 1)[1]  # first line is the title
    ps = [p.strip() for p in re.split(r'\n\s*\n', lines) if p.strip()]
    return [p for p in ps if p != '[beat]']


def cut(t, n=145):
    t = re.sub(r'\s+', ' ', t)
    if len(t) <= n:
        return t
    return t[:n].rsplit(' ', 1)[0].rstrip(',;:—-') + '…'


def to_webp(src, dst):
    """Centre-crop to 4:3 and resize to 1200x900 (only the Prunksaal PNG hero needs it)."""
    im = Image.open(src).convert('RGB')
    w, h = im.size
    if w * 3 > h * 4:
        nw = h * 4 // 3
        im = im.crop(((w - nw) // 2, 0, (w - nw) // 2 + nw, h))
    else:
        nh = w * 3 // 4
        im = im.crop((0, (h - nh) // 2, w, (h - nh) // 2 + nh))
    im.resize((1200, 900), Image.LANCZOS).save(dst, 'WEBP', quality=85)


folders = {}
for d in sorted(os.listdir(DROP)):
    txt = glob.glob(os.path.join(DROP, d, '*_clean.txt'))
    if txt:
        folders[os.path.basename(txt[0])[:2]] = (os.path.join(DROP, d), txt[0])
assert len(folders) == 35, len(folders)

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
    # the drop's own hero leads when there is one (an override, *_hero.*, or a numbered 01); then name order
    imgs = sorted(glob.glob(f'{src}/*.webp') + glob.glob(f'{src}/*.png'),
                  key=lambda p: (os.path.basename(p) != HERO_OVERRIDE.get(n),
                                 not re.search(r'_hero\.(webp|png)$', p), p))
    names = [f'{slug}_hero.webp'] + [f'{slug}_{i}.webp' for i in range(2, len(imgs) + 1)]
    for a, b in zip(imgs, names):
        if a.endswith('.png'):
            to_webp(a, f'{OUT}/images/{b}')
        else:
            shutil.copyfile(a, f'{OUT}/images/{b}')
    hero = B + 'images/' + names[0]
    stop = dict(id=U(f'atlas-stop:vie:{slug}:1'), order=0, title=TITLE[n], caption=CAPTION[n],
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=int(r),
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:vie:{slug}'), createdAt='2026-10-18', title=TITLE[n],
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city='Vienna', country='Austria', relatedTourIds=[], primaryCategory=cat,
                    tags=TAGS[n], priceUSD=0))

maker = dict(id=MAKER, displayName='Atlas Studio VIE', platform='dozent', handle='atlas.vie', avatarURL=None,
             avatarEmoji='🇦🇹',
             bio="Atlas Studio's Vienna bureau — an architect's guide to the city: Otto Wagner and Adolf Loos, "
                 "coffee houses and Heurigen, Red Vienna's housing, baroque libraries and post-war hotels, and "
                 "the shops and workshops that have made the city's things for two hundred years.",
             websiteURL=None)
last = max(i for i, m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio'))
d['makers'].insert(last + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print(len(new), 'tours added; maker', MAKER)
for t in new:
    print(f"{t['title'][:34]:34} {t['stops'][0]['audioDurationSeconds']:4}s imgs={1 + len(t['additionalImageURLs'])} r={t['stops'][0]['triggerRadiusMeters']}")
