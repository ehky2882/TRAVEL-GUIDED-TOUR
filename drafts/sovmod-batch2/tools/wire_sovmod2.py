"""Assemble SovMod batch 2 (53 singles) and Atlas Studio TAO (Qingdao, 1 single) into Tours.json.

Adapted from drafts/auckland-batch1/tools/wire_auckland.py. Usage:
    python3 wire_sovmod2.py <dir of per-slug source folders> <staging dir for gh-pages files>
Each source folder is named by the source script's slug (underscores) and holds the MP3,
`_clean.txt` and the numbered webps from the drop. coordinates.tsv is
slug · lat · lon · radius · category · maker · title · city · country · tags · note.
Writes Tours.json and copies audio/<slug>.mp3 and images/<slug>_hero.webp, _2.webp …
into the staging dir for one gh-pages commit. Run once: it refuses to add twice.
"""
import json, uuid, re, os, sys, glob, shutil, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/sovmod-batch2/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKERS = {'sovmod': U('atlas-maker:sovmod'), 'tao': U('atlas-maker:tao')}
SRC, OUT = sys.argv[1], sys.argv[2]


def paragraphs(f):
    lines = open(f, encoding='utf-8').read().strip().split('\n', 1)
    ps = [p.strip() for p in re.split(r'\n\s*\n', lines[1]) if p.strip()]
    ps = [p for p in ps if p != '[beat]']
    # the second header line (address · coordinate) is not narration
    if re.search(r'·\s*-?\d+\.\d+,\s*-?\d+\.\d+\s*$', ps[0].split('\n')[0]):
        ps[0] = ps[0].split('\n', 1)[1].strip() if '\n' in ps[0] else None
    return [p for p in ps if p]


def first_sentence(p):
    return re.findall(r'.+?[.!?](?=\s|$)', p)[0]


def cut(t, n=145):
    t = t.replace('\n', ' ')
    if len(t) <= n:
        return t
    return t[:n].rsplit(' ', 1)[0].rstrip(',;:—-') + '…'


def duration(mp3):
    out = subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', mp3],
                         capture_output=True, text=True, check=True).stdout
    return round(float(out))


d = json.load(open(P))
assert any(m['id'] == MAKERS['sovmod'] for m in d['makers'])
assert not any(m['id'] == MAKERS['tao'] for m in d['makers'])
os.makedirs(f'{OUT}/audio', exist_ok=True)
os.makedirs(f'{OUT}/images', exist_ok=True)
new = []
for line in open(D + 'coordinates.tsv', encoding='utf-8'):
    slug, la, lo, r, cat, mk, title, city, country, tags, note = line.rstrip('\n').split('\t')
    src = os.path.join(SRC, slug.replace('-', '_'))
    ps = paragraphs(glob.glob(f'{src}/*_clean.txt')[0])
    txt = '\n\n'.join(ps)
    mp3 = glob.glob(f'{src}/*.mp3')[0]
    du = duration(mp3)
    shutil.copyfile(mp3, f'{OUT}/audio/{slug}.mp3')
    imgs = sorted(glob.glob(f'{src}/*.webp'))
    names = [f'{slug}_hero.webp'] + [f'{slug}_{i}.webp' for i in range(2, len(imgs) + 1)]
    for a, b in zip(imgs, names):
        shutil.copyfile(a, f'{OUT}/images/{b}')
    hero = B + 'images/' + names[0]
    stop = dict(id=U(f'atlas-stop:{mk}:{slug}:1'), order=0, title=title, caption=first_sentence(ps[1]),
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=int(r),
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:{mk}:{slug}'), createdAt='2026-10-10', title=title,
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKERS[mk],
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city=city, country=country, relatedTourIds=[], primaryCategory=cat,
                    tags=tags.split(','), priceUSD=0))

maker = dict(id=MAKERS['tao'], displayName='Atlas Studio TAO', platform='dozent', handle='atlas.tao', avatarURL=None,
             avatarEmoji='🇨🇳',
             bio="Atlas Studio's Qingdao bureau — audio tours of a port city that spent sixteen years as a German "
                 "leased territory and kept the stone, the red roofs and the science it left behind.",
             websiteURL=None)
last = max(i for i, m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio'))
d['makers'].insert(last + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print(len(new), 'tours added; TAO maker', MAKERS['tao'])
for t in new:
    print(f"{t['title'][:30]:30} {t['stops'][0]['audioDurationSeconds']:4}s imgs={1 + len(t['additionalImageURLs'])} | {t['stops'][0]['caption'][:70]}")
