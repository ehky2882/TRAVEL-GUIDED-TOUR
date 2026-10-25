"""Assemble Grands Ensembles batch 1 (8 singles) into Tours.json, under a new maker.

Adapted from drafts/sovmod-batch2/tools/wire_sovmod2.py. Usage:
    python3 wire_grands_ensembles.py <dir of per-slug source folders> <staging dir for gh-pages files>
Each source folder is named by the slug (the MP3's name without its `NN-` prefix) and holds the MP3,
the display script `NN-<slug>.txt`, the `_tts.txt` read to the voice, and `<slug>_hero.webp`, `_2.webp` …
coordinates.tsv is slug · lat · lon · radius · category · title · city · country · tags · note.
Writes Tours.json and copies audio/<slug>.mp3 and the images into the staging dir for one gh-pages commit.
Run once: it refuses to add the maker twice.

Six image filenames were already on gh-pages from an abandoned 2026-10-11 session (57fb673) holding an
OLDER version of these photographs, referenced by nothing. They are published under `-2` names instead of
being overwritten (CLAUDE.md § Image Pipeline step 9).
"""
import json, uuid, re, os, sys, glob, shutil, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/grands-ensembles-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MK = 'grands-ensembles'
MAKER_ID = U(f'atlas-maker:{MK}')
SOVMOD_ID = U('atlas-maker:sovmod')
CREATED = '2026-10-13'
TAKEN = {'tours-aillaud_hero.webp', 'tours-aillaud_2.webp', 'tours-aillaud_3.webp',
         'cite-de-la-muette-drancy_hero.webp', 'cite-de-la-muette-drancy_2.webp', 'la-grande-borne_2.webp'}
SRC, OUT = sys.argv[1], sys.argv[2]


def paragraphs(f):
    body = open(f, encoding='utf-8').read().strip().split('\n', 1)[1]
    ps = [p.strip() for p in re.split(r'\n\s*\n', body) if p.strip()]
    return [p for p in ps if p != '[beat]']


def caption(p):
    # the orientation line; a bare address ("Place Pablo-Picasso, Noisy-le-Grand.") takes the next sentence too
    ss = re.findall(r'.+?[.!?](?=\s|$)', p)
    out = ss[0]
    for s in ss[1:]:
        if len(out) >= 60:
            break
        out += ' ' + s.strip()
    return out


def cut(t, n=145):
    t = t.replace('\n', ' ')
    if len(t) <= n:
        return t
    return t[:n].rsplit(' ', 1)[0].rstrip(',;:—-') + '…'


def duration(mp3):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', mp3],
                         capture_output=True, text=True, check=True).stdout
    return round(float(out))


def published(name):
    return name[:-5] + '-2.webp' if name in TAKEN else name


d = json.load(open(P))
assert any(m['id'] == SOVMOD_ID for m in d['makers'])
assert not any(m['id'] == MAKER_ID for m in d['makers'])
os.makedirs(f'{OUT}/audio', exist_ok=True)
os.makedirs(f'{OUT}/images', exist_ok=True)
new = []
for line in open(D + 'coordinates.tsv', encoding='utf-8'):
    slug, la, lo, r, cat, title, city, country, tags, note = line.rstrip('\n').split('\t')
    src = os.path.join(SRC, slug)
    script = [f for f in glob.glob(f'{src}/*.txt') if not f.endswith('_tts.txt')]
    assert len(script) == 1, script
    ps = paragraphs(script[0])
    txt = '\n\n'.join(ps)
    mp3 = glob.glob(f'{src}/*.mp3')[0]
    du = duration(mp3)
    shutil.copyfile(mp3, f'{OUT}/audio/{slug}.mp3')
    order = [f'{slug}_hero.webp'] + sorted((os.path.basename(f) for f in glob.glob(f'{src}/{slug}_[0-9]*.webp')),
                                           key=lambda n: int(n.rsplit('_', 1)[1][:-5]))
    assert len(order) == len(glob.glob(f'{src}/*.webp')), (slug, order)
    names = [published(n) for n in order]
    for a, b in zip(order, names):
        shutil.copyfile(f'{src}/{a}', f'{OUT}/images/{b}')
    hero = B + 'images/' + names[0]
    stop = dict(id=U(f'atlas-stop:{MK}:{slug}:1'), order=0, title=title, caption=caption(ps[1]),
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=int(r),
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:{MK}:{slug}'), createdAt=CREATED, title=title,
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER_ID,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city=city, country=country, relatedTourIds=[], primaryCategory=cat,
                    tags=tags.split(','), priceUSD=0))

maker = dict(id=MAKER_ID, displayName='Grands Ensembles', platform='dozent', handle='grandsensembles',
             avatarURL=None, avatarEmoji='🏢',
             bio="Original audio guides to France's post-war housing estates: the towers, stars, cabbages and "
                 "palaces for the people that architects built around Paris, and what became of them.",
             websiteURL=None)
at = next(i for i, m in enumerate(d['makers']) if m['id'] == SOVMOD_ID)
d['makers'].insert(at + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print(len(new), 'tours added; maker', MAKER_ID)
for t in new:
    print(f"{t['title'][:32]:32} {t['stops'][0]['audioDurationSeconds']:4}s imgs={1 + len(t['additionalImageURLs'])} | {t['stops'][0]['caption'][:70]}")
