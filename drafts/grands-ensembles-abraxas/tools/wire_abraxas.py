"""Add Les Espaces d'Abraxas to Tours.json under Grands Ensembles (single tour, 2026-10-13).

Same rules as drafts/grands-ensembles-batch1/tools/wire_grands_ensembles.py. Usage:
    python3 wire_abraxas.py <drop dir> <staging dir for gh-pages files>
The drop holds `09-espaces-dabraxas.txt`, `Espaces d'Abraxas.mp3` and `espaces-dabraxas_hero.webp`, `_2` … `_7`.
The coordinate is the one the contributor supplied (it reverse-geocodes to L'Arche, Place des Fédérés).
Run once: it refuses to add the tour twice.
"""
import json, uuid, re, os, sys, shutil, subprocess

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MK, SLUG = 'grands-ensembles', 'espaces-dabraxas'
MAKER_ID = U(f'atlas-maker:{MK}')
LAT, LON, RADIUS = 48.84018131090563, 2.542929727151812, 60
TAGS = ['Notable Building', 'Architecture', 'Public Square', 'Hidden Gem', 'Designed by a Master', 'Ricardo Bofill']
SRC, OUT = sys.argv[1], sys.argv[2]

body = open(f'{SRC}/09-{SLUG}.txt', encoding='utf-8').read().strip().split('\n', 1)
title = body[0].strip()
ps = [p.strip() for p in re.split(r'\n\s*\n', body[1]) if p.strip() and p.strip() != '[beat]']
txt = '\n\n'.join(ps)
ss = re.findall(r'.+?[.!?](?=\s|$)', ps[1])
caption = ss[0]
for s in ss[1:]:
    if len(caption) >= 60:
        break
    caption += ' ' + s.strip()
short = txt.replace('\n', ' ')
if len(short) > 145:
    short = short[:145].rsplit(' ', 1)[0].rstrip(',;:—-') + '…'
mp3 = f"{SRC}/Espaces d'Abraxas.mp3"
du = round(float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', mp3],
                                capture_output=True, text=True, check=True).stdout))
os.makedirs(f'{OUT}/audio', exist_ok=True)
os.makedirs(f'{OUT}/images', exist_ok=True)
shutil.copyfile(mp3, f'{OUT}/audio/{SLUG}.mp3')
names = [f'{SLUG}_hero.webp'] + [f'{SLUG}_{i}.webp' for i in range(2, 8)]
for n in names:
    shutil.copyfile(f'{SRC}/{n}', f'{OUT}/images/{n}')
hero = B + 'images/' + names[0]

d = json.load(open(P))
assert any(m['id'] == MAKER_ID for m in d['makers'])
tid = U(f'atlas-tour:{MK}:{SLUG}')
assert not any(t['id'] == tid for t in d['tours'])
stop = dict(id=U(f'atlas-stop:{MK}:{SLUG}:1'), order=0, title=title, caption=caption, latitude=LAT, longitude=LON,
            audioURL=B + f'audio/{SLUG}.mp3', audioDurationSeconds=du, triggerMode='geofenced',
            triggerRadiusMeters=RADIUS, imageURL=hero, transcriptText=txt)
d['tours'].append(dict(id=tid, createdAt='2026-10-13', title=title, shortDescription=short,
                       longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER_ID, heroImageURL=hero,
                       additionalImageURLs=[B + 'images/' + n for n in names[1:]], kind='single', stops=[stop],
                       introAudioURL=None, totalDurationSeconds=du, walkingDistanceMeters=None,
                       centroidLatitude=LAT, centroidLongitude=LON, city='Noisy-le-Grand', country='France',
                       relatedTourIds=[], primaryCategory='architecture', tags=TAGS, priceUSD=0))
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print(title, du, 's |', caption)
