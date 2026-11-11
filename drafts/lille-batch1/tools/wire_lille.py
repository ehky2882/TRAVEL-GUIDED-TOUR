"""Assemble Atlas Studio LIL (19 Lille-area singles) into Tours.json.

Adapted from drafts/helsinki-batch1/tools/wire_helsinki.py. Usage:
    python3 wire_lille.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders, matched to META by the folder's name. Each holds
`NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt`; every clean script but Bienheureux opens with a title line.
Takes each coordinate from its folder name, writes Tours.json and drafts/lille-batch1/coordinates.tsv, copies
both script texts into drafts/lille-batch1/scripts/, and copies audio/<slug>.mp3 and images/<slug>_hero.webp,
_2.webp … into the staging dir for one gh-pages commit. Every slug carries a `lil-` prefix so no Lille file can
land on an existing name.
"""
import json, uuid, re, os, sys, glob, shutil, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/lille-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:lil')
DROP, OUT = sys.argv[1], sys.argv[2]
M = 'Designed by a Master'

# folder-name prefix: (num, slug, title, city, radius, category, caption, tags)
# English | French where the two names genuinely differ; venues and names used as-is keep one name.
META = {
    'ATELIER KUM#U00d8': ('01', 'lil-atelier-kumo', 'Atelier Kumø', 'Lille', 40, 'hiddenGems',
        "On Rue de l'Hôpital Militaire, between Atelier Kumø at number seven and Maison Kumø at number thirteen.",
        ['Venue', 'Commerce', 'Art', 'Contemporary', 'Hidden Gem']),
    'Bienheureux': ('02', 'lil-bienheureux', 'Bienheureux', 'Wasquehal', 40, 'foodAndDrink',
        'At number thirty-five Avenue de la Marne, facing the red-brick manor among the trees of the Parc du Verseau.',
        ['Venue', 'Food', 'Architecture', 'Green Escape', 'Hidden Gem']),
    'Clivia Nobili': ('03', 'lil-clivia-nobili', 'Clivia Nobili', 'Lille', 40, 'culturalHeritage',
        'At forty bis Rue Saint-André in the Vieux-Lille, by the window of workwear in deep French blue.',
        ['Venue', 'Fashion', 'Commerce', 'History', 'Hidden Gem']),
    'JaJa': ('04', 'lil-jaja', 'JaJa, Planches & Vins', 'Lille', 40, 'foodAndDrink',
        'On Rue Saint-André, between JaJa at number thirty-six and Petit JaJa across the road at thirty-seven.',
        ['Venue', 'Food', 'After Dark']),
    'La Vieille Bourse': ('05', 'lil-vieille-bourse', 'Old Stock Exchange | La Vieille Bourse', 'Lille', 50,
        'architecture',
        'In the arcaded inner courtyard, between the Grand Place and Place du Théâtre.',
        ['Notable Building', 'Architecture', 'Commerce', 'History', 'Baroque', 'Iconic Landmark', 'Free to Visit',
         M, 'Julien Destrée']),
    'Le Barboteur': ('06', 'lil-le-barboteur', 'Le Barboteur', 'Lille', 40, 'foodAndDrink',
        "At ninety-one Quai de l'Ouest in Bois-Blancs, back to the restaurant, facing the Gare d'eau and its barges.",
        ['Venue', 'Waterfront', 'Food', 'Maritime', 'After Dark']),
    'Le Braque': ('07', 'lil-le-braque', 'Le Braque', 'Lille', 40, 'foodAndDrink',
        'At number forty-five Rue de la Monnaie, by the shopfront painted Comptoir gourmand.',
        ['Venue', 'Food', 'Hidden Gem']),
    'Le Fresnoy': ('08', 'lil-le-fresnoy', 'Le Fresnoy', 'Tourcoing', 50, 'architecture',
        'Far enough back from the entrance on Rue du Fresnoy to take in the great metal roof over the old halls.',
        ['Museum', 'Art', 'Architecture', 'Contemporary', M, 'Bernard Tschumi']),
    'Le Restaurant du Cerisier': ('09', 'lil-le-cerisier', 'Le Restaurant du Cerisier', 'Lille', 40,
        'foodAndDrink',
        'At number fourteen Avenue du Peuple-Belge, facing the brasserie with the starred dining room above.',
        ['Venue', 'Food', 'Contemporary', 'History']),
    'Le Tripostal': ('10', 'lil-le-tripostal', 'Le Tripostal', 'Lille', 60, 'visualArt',
        'On Avenue Willy Brandt, facing the long concrete block between Lille Flandres and Lille Europe.',
        ['Museum', 'Art', 'History', 'Modernist']),
    'Lille Opera': ('11', 'lil-opera', 'Lille Opera | Opéra de Lille', 'Lille', 50, 'musicAndPerformance',
        'On Place du Théâtre, facing the pale stone front, with the Chamber of Commerce belfry to its left.',
        ['Venue', 'Performance', 'Architecture', 'Beaux-Arts', 'War', 'Iconic Landmark', M,
         'Louis-Marie Cordonnier']),
    'M#U00e9ert': ('12', 'lil-meert', 'Méert', 'Lille', 40, 'foodAndDrink',
        'At twenty-seven Rue Esquermoise, by the window displays of small golden boxes.',
        ['Venue', 'Food', 'Commerce', 'History', 'Iconic Landmark', M, 'Charles Benvignat']),
    'March#U00e9 de Wazemmes': ('13', 'lil-marche-de-wazemmes', 'Wazemmes Market | Marché de Wazemmes', 'Lille',
        60, 'foodAndDrink',
        'On Place de la Nouvelle Aventure, by the iron-and-glass market hall and the open-air stalls around it.',
        ['Market', 'Public Square', 'Food', 'Immigration', 'Commerce', 'History', 'Free to Visit', M,
         'César Joly']),
    'Notre-Dame-de-la-Treille': ('15', 'lil-notre-dame-de-la-treille',
        'Notre-Dame-de-la-Treille Cathedral | Cathédrale Notre-Dame-de-la-Treille', 'Lille', 50, 'sacredSites',
        'On the raised forecourt, facing the west front and its arch of translucent marble.',
        ['Religious Building', 'Faith', 'Architecture', 'Gothic', 'Contemporary', 'Engineering', 'Iconic Landmark',
         'Free to Visit', M, 'Charles Leroy', 'Pierre-Louis Carlier']),
    'Palais des Beaux-Arts': ('16', 'lil-palais-des-beaux-arts', 'Palace of Fine Arts | Palais des Beaux-Arts de Lille',
        'Lille', 60, 'visualArt',
        'On Place de la République, facing the museum on its southern side, with the prefecture behind you.',
        ['Museum', 'Art', 'History', 'War', 'Beaux-Arts', 'Contemporary', 'Iconic Landmark', M,
         'Édouard Bérard', 'Fernand Delmas', 'Jean-Marc Ibos', 'Myrto Vitart']),
    'Place aux Oignons': ('17', 'lil-place-aux-oignons', 'Place aux Oignons', 'Lille', 40, 'history',
        'In the small cobbled square in the Vieux-Lille, ringed by old weavers’ houses, near the cathedral.',
        ['Public Square', 'History', 'Architecture', 'Hidden Gem', 'Free to Visit']),
    'Restaurant S#U00e9bastopol': ('18', 'lil-restaurant-sebastopol', 'Restaurant Sébastopol', 'Lille', 40,
        'foodAndDrink',
        'On Place Sébastopol, with the theatre on one side and the little restaurant at number one across from it.',
        ['Venue', 'Food', 'Performance', 'History']),
    'Rue de la Clef': ('19', 'lil-rue-de-la-clef', 'Rue de la Clef', 'Lille', 60, 'history',
        'On the narrow cobbled lane between Boulevard Carnot and Place des Patiniers; look for the key mosaic.',
        ['District', 'History', 'Fashion', 'Commerce', 'Public Art', 'Hidden Gem', 'Free to Visit']),
    'Villa Cavrois': ('20', 'lil-villa-cavrois', 'Villa Cavrois', 'Croix', 60, 'architecture',
        'On the garden side, beside the long reflecting pool, with the whole yellow-brick house across the water.',
        ['Notable Building', 'Architecture', 'Modernist', 'War', 'Iconic Landmark', M, 'Robert Mallet-Stevens']),
}

# The short title drops the institution's full name, so the description carries it (contributor, 2026-10-23).
LONG_EXTRA = {'08': 'Its full name is Le Fresnoy – Studio national des arts contemporains.'}


def paragraphs(f):
    t = open(f, encoding='utf-8').read()
    ps = [p.strip() for p in re.split(r'\n\s*\n', t) if p.strip()]
    if '.' not in ps[0] and len(ps[0]) < 80:
        ps = ps[1:]  # title line (all but Bienheureux)
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
for key, (n, slug, title, city, r, cat, caption, tags) in sorted(META.items(), key=lambda kv: kv[1][0]):
    src, la, lo = folders[key]
    clean = glob.glob(f'{src}/*_clean.txt')
    assert len(clean) == 1, (n, clean)
    safe = clean[0][:-len('_clean.txt')] + '_tts-safe.txt'
    for f in (clean[0], safe):
        shutil.copyfile(f, D + 'scripts/' + os.path.basename(f))
    ps = paragraphs(clean[0])
    txt = '\n\n'.join(ps)
    mp3s = glob.glob(f'{src}/*.mp3')
    assert len(mp3s) == 1, (n, mp3s)
    du = duration(mp3s[0])
    shutil.copyfile(mp3s[0], f'{OUT}/audio/{slug}.mp3')
    # the drop's own *_hero leads (Place aux Oignons has a single unsuffixed photo); then name order
    imgs = sorted(glob.glob(f'{src}/*.webp'), key=lambda p: (not p.endswith('_hero.webp'), p))
    assert imgs and (imgs[0].endswith('_hero.webp') or len(imgs) == 1), (n, imgs)
    names = [f'{slug}_hero.webp'] + [f'{slug}_{i}.webp' for i in range(2, len(imgs) + 1)]
    for a, b in zip(imgs, names):
        shutil.copyfile(a, f'{OUT}/images/{b}')
    hero = B + 'images/' + names[0]
    stop = dict(id=U(f'atlas-stop:lil:{slug}:1'), order=0, title=title, caption=caption,
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=r,
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:lil:{slug}'), createdAt='2026-10-23', title=title,
                    shortDescription=cut(txt),
                    longDescription='\n\n'.join([ps[0], ps[2]] + ([LONG_EXTRA[n]] if n in LONG_EXTRA else [])), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city=city, country='France', relatedTourIds=[], primaryCategory=cat,
                    tags=tags, priceUSD=0))
    tsv.append('\t'.join([n, slug, la, lo, str(r), cat, os.path.basename(src)]))

maker = dict(id=MAKER, displayName='Atlas Studio LIL', platform='dozent', handle='atlas.lil', avatarURL=None,
             avatarEmoji='🇫🇷',
             bio="Atlas Studio's Lille bureau — the Flemish capital of France, where the merchants' Bourse and "
                 "the weavers' squares tell of a city built on cloth, old mills and sorting offices have become "
                 "art spaces, and the kitchens run from a gaufre counter of 1849 to wine bars facing each other "
                 "across the Vieux-Lille.",
             websiteURL=None)
last = max(i for i, m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio'))
d['makers'].insert(last + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
open(D + 'coordinates.tsv', 'w').write('\n'.join(tsv) + '\n')
print(len(new), 'tours added; maker', MAKER)
for t in new:
    print(f"{t['title'][:40]:40} {t['city']:10} {t['stops'][0]['audioDurationSeconds']:4}s "
          f"imgs={1 + len(t['additionalImageURLs'])} r={t['stops'][0]['triggerRadiusMeters']}")
