"""Assemble Atlas Studio WAW (34 Warsaw singles) into Tours.json.

Adapted from drafts/vienna-batch1/tools/wire_vienna.py. Usage:
    python3 wire_warsaw.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders (numbered by the NN of each folder's
`warsaw_NN_<slug>.txt`), takes each coordinate from its folder name, writes Tours.json and
drafts/warsaw-batch1/coordinates.tsv, copies both script texts into drafts/warsaw-batch1/scripts/,
and copies audio/<slug>.mp3 and images/<slug>_hero.webp, _2.webp … into the staging dir for one
gh-pages commit. Every slug carries a `waw-` prefix so no Warsaw file can land on an existing name.
"""
import json, uuid, re, os, sys, glob, shutil, mutagen

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/warsaw-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:waw')
DROP, OUT = sys.argv[1], sys.argv[2]
M = 'Designed by a Master'

# num: (slug, title, radius, category, caption, tags)
# English | Polish where the two names genuinely differ; venues and names used as-is keep one name.
# Numbers 03, 10 and 27 are absent on purpose (already covered by SovMod, or cut by the contributor).
META = {
    '01': ('waw-raffles-europejski', 'Raffles Europejski Warsaw', 40, 'architecture',
           'On Krakowskie Przedmieście outside number thirteen, with the Bristol across the street.',
           ['Notable Building', 'Architecture', 'History', 'Neoclassical', M, 'Enrico Marconi']),
    '02': ('waw-hotel-bristol', 'Hotel Bristol', 40, 'architecture',
           'On Krakowskie Przedmieście at the corner of Karowa, facing the corner dome.',
           ['Notable Building', 'Architecture', 'History', M, 'Władysław Marconi']),
    '04': ('waw-bar-mleczny-prasowy', 'Prasowy Milk Bar | Bar Mleczny Prasowy', 40, 'foodAndDrink',
           'On Marszałkowska at numbers ten to sixteen, below the Prasowy neon.',
           ['Venue', 'Food', 'History', 'Hidden Gem']),
    '05': ('waw-bez-gwiazdek', 'Bez Gwiazdek', 40, 'foodAndDrink',
           'On Wiślana Street in Powiśle, a quiet side street running down to the river.',
           ['Venue', 'Food', 'Contemporary', 'Hidden Gem']),
    '06': ('waw-hala-koszyki', 'Koszyki Hall | Hala Koszyki', 50, 'foodAndDrink',
           'On Koszykowa Street, facing the arched brick gateway at number sixty-three.',
           ['Market', 'Food', 'Architecture', 'Commerce', M, 'Juliusz Dzierżanowski', 'JEMS Architekci']),
    '07': ('waw-elektrownia-powisle', 'Powiśle Power Station | Elektrownia Powiśle', 50, 'foodAndDrink',
           'On Dobra Street, in the square in front of the old boiler house.',
           ['Notable Building', 'Food', 'Engineering', 'War']),
    '08': ('waw-charlotte', 'Charlotte, Plac Zbawiciela', 40, 'foodAndDrink',
           'On the curved edge of Plac Zbawiciela, facing the church across the square.',
           ['Venue', 'Food', 'History']),
    '09': ('waw-kulturalna', 'Kulturalna', 40, 'foodAndDrink',
           'At the Teatr Dramatyczny entrance of the Palace of Culture, on the Plac Defilad side.',
           ['Venue', 'Food', 'Performance', 'After Dark', 'Hidden Gem']),
    '11': ('waw-pawilony-nowy-swiat', 'Nowy Świat Pavilions | Pawilony Nowy Świat', 40, 'foodAndDrink',
           'At the gateway into the courtyard behind Nowy Świat twenty-two to twenty-eight.',
           ['District', 'Food', 'After Dark', 'Hidden Gem']),
    '12': ('waw-plan-b', 'Plan B', 40, 'foodAndDrink',
           'On Plac Zbawiciela, on the pavement below the bar’s windows.',
           ['Venue', 'Food', 'After Dark']),
    '13': ('waw-kafka', 'Kafka', 40, 'foodAndDrink',
           'On Oboźna Street at number three, by the chairs set out in front.',
           ['Venue', 'Food', 'Literature']),
    '14': ('waw-rozbrat-20', 'Rozbrat 20', 40, 'foodAndDrink',
           'On the corner of Rozbrat Street at number twenty, in Powiśle’s Solec quarter.',
           ['Venue', 'Food', 'Hidden Gem']),
    '15': ('waw-pawilon-cepelii', 'Cepelia Pavilion | Pawilon Cepelii', 40, 'architecture',
           'On Marszałkowska at number ninety-nine, beside the Hotel Metropol.',
           ['Notable Building', 'Architecture', 'Commerce', 'Modernist', 'Public Art', M, 'Zygmunt Stępiński']),
    '16': ('waw-bec-zmiana', 'Bęc Zmiana', 40, 'visualArt',
           'On Mokotowska Street at number sixty-five, outside the bookshop and gallery.',
           ['Venue', 'Art', 'Commerce', 'Hidden Gem']),
    '17': ('waw-pan-tu-nie-stal', 'Pan Tu Nie Stał', 40, 'culturalHeritage',
           'On Koszykowa Street, in the arcade of the big fifties block off Plac Konstytucji.',
           ['Venue', 'Fashion', 'Commerce', 'Public Art']),
    '18': ('waw-hala-mirowska', 'Mirowska Hall | Hala Mirowska', 50, 'history',
           'On Plac Mirowski, beside the brick halls, facing the west hall.',
           ['Market', 'Commerce', 'War', 'Remembrance']),
    '19': ('waw-bazar-rozyckiego', 'Różycki Bazaar | Bazar Różyckiego', 50, 'history',
           'At the market’s gate on Targowa Street in Praga.',
           ['Market', 'Commerce', 'History', 'Hidden Gem']),
    '20': ('waw-palac-kultury-i-nauki', 'Palace of Culture and Science | Pałac Kultury i Nauki', 60, 'architecture',
           'On Plac Defilad, in front of the Palace’s main steps on the Marszałkowska side.',
           ['Tower', 'Architecture', 'Power', 'Iconic Landmark', 'Viewpoint', M, 'Lev Rudnev']),
    '21': ('waw-muzeum-neonow', 'Neon Museum | Muzeum Neonów', 40, 'visualArt',
           'Inside the Palace of Culture, on the fourth floor, up the side lifts from the cloakroom.',
           ['Museum', 'Art', 'History', 'After Dark']),
    '22': ('waw-muzeum-sztuki-nowoczesnej', 'Museum of Modern Art | Muzeum Sztuki Nowoczesnej', 50, 'visualArt',
           'On Plac Defilad, between Marszałkowska and the Palace of Culture.',
           ['Museum', 'Art', 'Architecture', 'Contemporary', M, 'Thomas Phifer']),
    '23': ('waw-zacheta', 'Zachęta National Gallery of Art | Zachęta — Narodowa Galeria Sztuki', 40, 'visualArt',
           'On Plac Małachowskiego, in front of the gallery’s columned portal.',
           ['Museum', 'Art', 'Architecture', 'Beaux-Arts', M, 'Stefan Szyller']),
    '24': ('waw-polin', 'POLIN Museum of the History of Polish Jews | Muzeum Historii Żydów Polskich POLIN', 50,
           'history',
           'On the square in Muranów, between the museum and the Monument to the Ghetto Heroes.',
           ['Museum', 'History', 'Remembrance', 'Faith', 'Contemporary', M, 'Lahdelma & Mahlamäki']),
    '25': ('waw-buw', 'University of Warsaw Library | Biblioteka Uniwersytecka w Warszawie', 50, 'architecture',
           'On Dobra Street, facing the library’s front of giant text panels.',
           ['Library', 'Architecture', 'Green Escape', 'Viewpoint', 'Contemporary', M,
            'Marek Budzyński', 'Zbigniew Badowski', 'Irena Bajerska']),
    '26': ('waw-sad-najwyzszy', 'Supreme Court | Sąd Najwyższy', 50, 'architecture',
           'On Plac Krasińskich, among the green-topped pillars of the colonnade.',
           ['Civic', 'Architecture', 'Power', 'Contemporary', M, 'Marek Budzyński', 'Zbigniew Badowski']),
    '28': ('waw-kosciol-wniebowstapienia', 'Church of the Ascension | Kościół Wniebowstąpienia Pańskiego', 50,
           'sacredSites',
           'In the park on Ursynów’s main avenue, facing the brick front and great cross.',
           ['Religious Building', 'Faith', 'Architecture', M, 'Marek Budzyński', 'Zbigniew Badowski', 'Piotr Wicha']),
    '29': ('waw-krolikarnia', 'Królikarnia Palace | Pałac Królikarnia', 50, 'visualArt',
           'On the terrace in front of the palace, above the sculpture park on the escarpment.',
           ['Museum', 'Art', 'Neoclassical', 'Green Escape', M, 'Domenico Merlini']),
    '30': ('waw-muzeum-polskiej-wodki', 'Polish Vodka Museum | Muzeum Polskiej Wódki', 50, 'foodAndDrink',
           'On Plac Konesera, at the heart of the old Koneser distillery in Praga.',
           ['Museum', 'Food', 'Commerce', 'History']),
    '31': ('waw-fotoplastikon', 'Warsaw Fotoplastikon | Fotoplastikon Warszawski', 40, 'hiddenGems',
           'In the courtyard entrance at Aleje Jerozolimskie fifty-one.',
           ['Museum', 'History', 'Art', 'Hidden Gem']),
    '32': ('waw-rynek-starego-miasta', 'Old Town Market Square | Rynek Starego Miasta', 50, 'culturalHeritage',
           'In the middle of the square, beside the mermaid statue.',
           ['Public Square', 'History', 'War', 'Iconic Landmark', 'Free to Visit']),
    '33': ('waw-plac-konstytucji', 'Constitution Square | Plac Konstytucji', 50, 'architecture',
           'On Plac Konstytucji, beside one of the giant lamp standards.',
           ['Public Square', 'Architecture', 'Power', 'Free to Visit', M,
            'Józef Sigalin', 'Stanisław Jankowski', 'Zygmunt Stępiński']),
    '34': ('waw-za-zelazna-brama', 'Za Żelazną Bramą Estate | Osiedle Za Żelazną Bramą', 75, 'architecture',
           'Among the sixteen-storey slabs, north-west of the Palace of Culture.',
           ['District', 'Architecture', 'Modernist', 'Free to Visit']),
    '35': ('waw-ulica-katowicka', 'Katowicka Street, Saska Kępa | Ulica Katowicka', 50, 'architecture',
           'On Katowicka Street, outside numbers nine to eleven, facing the white villa.',
           ['District', 'Architecture', 'Modernist', 'Hidden Gem', 'Free to Visit', M,
            'Bohdan Lachert', 'Józef Szanajca']),
    '36': ('waw-bulwary-wislane', 'Vistula Boulevards | Bulwary Wiślane', 75, 'natureAndParks',
           'On the left-bank riverside promenade, on the wide steps down to the water.',
           ['Waterfront', 'History', 'Green Escape', 'Free to Visit', 'After Dark']),
    '37': ('waw-zlota-44', 'Złota 44', 75, 'architecture',
           'Across Emilii Plater Street from the Palace of Culture, below the curving glass tower.',
           ['Tower', 'Architecture', 'Contemporary', M, 'Daniel Libeskind']),
}


def body(f):
    """The script after its `---` header, as paragraphs, without [beat] markers."""
    t = open(f, encoding='utf-8').read().split('\n---\n', 1)[1]
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
    txt = [f for f in glob.glob(os.path.join(DROP, d, 'warsaw_*.txt')) if not f.endswith('_TTS.txt')]
    if m and txt:
        n = re.match(r'warsaw_(\d\d)_', os.path.basename(txt[0])).group(1)
        folders[n] = (os.path.join(DROP, d), txt[0], m.group(1), m.group(2))
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
    stem = os.path.basename(script)[:-4]
    shutil.copyfile(script, f'{D}scripts/{stem}.txt')
    shutil.copyfile(f'{src}/{stem}_TTS.txt', f'{D}scripts/{stem}_TTS.txt')
    ps = body(script)
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
    stop = dict(id=U(f'atlas-stop:waw:{slug}:1'), order=0, title=title, caption=caption,
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=r,
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:waw:{slug}'), createdAt='2026-10-20', title=title,
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city='Warsaw', country='Poland', relatedTourIds=[], primaryCategory=cat,
                    tags=tags, priceUSD=0))
    tsv.append('\t'.join([n, slug, la, lo, str(r), cat, os.path.basename(src)]))

maker = dict(id=MAKER, displayName='Atlas Studio WAW', platform='dozent', handle='atlas.waw', avatarURL=None,
             avatarEmoji='🇵🇱',
             bio="Atlas Studio's Warsaw bureau — an architect's guide to a city rebuilt from rubble: Stalin's "
                 "Palace and the museums that answer it, milk bars and market halls, interwar villas and "
                 "socialist estates, and the bars, shops and hotels where Warsaw lives now.",
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
