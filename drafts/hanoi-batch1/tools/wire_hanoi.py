"""Assemble Atlas Studio HAN (28 Hanoi singles) into Tours.json.

Adapted from drafts/auckland-batch1/tools/wire_auckland.py. Usage:
    python3 wire_hanoi.py <unzipped drop dir> <staging dir for gh-pages files>
Reads the drop's `output <Name> <lat>, <lon>` folders (numbered by the hanoi_NN_ prefix
of each folder's script), writes Tours.json, and copies audio/<slug>.mp3 and
images/<slug>_hero.webp, _2.webp … into the staging dir for one gh-pages commit.
Every slug carries a `han-` prefix: an abandoned earlier attempt left unreferenced
Hanoi files on gh-pages under the bare names, and live bytes are never overwritten.
"""
import json, uuid, re, os, sys, glob, shutil, mutagen

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../..'))
P = f'{ROOT}/TRAVEL GUIDED TOUR/Resources/Tours.json'
D = f'{ROOT}/drafts/hanoi-batch1/'
B = 'https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/'
U = lambda s: str(uuid.uuid5(uuid.NAMESPACE_URL, s))
MAKER = U('atlas-maker:han')
DROP, OUT = sys.argv[1], sys.argv[2]

TITLE = {
    '01': 'Gia', '02': 'T.U.N.G Dining', '03': 'Ngõ Trung Yên', '04': 'Long Waits Jazz',
    '05': 'Workshop14', '06': 'Mémoire 15', '07': 'Duy Trí Café | Cà Phê Duy Trí', '08': 'Loading T',
    '09': 'Sofitel Legend Metropole Hanoi', '10': 'JW Marriott Hanoi', '11': 'Silk Path Boutique Hanoi',
    '12': 'Jackfruit Village', '13': '54 Traditions', '14': 'Art Vietnam Gallery', '15': 'Manzi Art Space',
    '16': 'The Old Quarter | Phố Cổ Hà Nội', '17': 'The French Quarter | Khu Phố Pháp',
    '18': 'Ba Đình Square | Quảng trường Ba Đình',
    '19': 'Imperial Citadel of Thăng Long | Hoàng thành Thăng Long',
    '20': 'Vietnam Military History Museum | Bảo tàng Lịch sử Quân sự Việt Nam',
    '21': 'Long Biên Bridge | Cầu Long Biên', '22': 'Hồ Chí Minh Museum | Bảo tàng Hồ Chí Minh',
    '23': 'Ngọc Sơn Temple | Đền Ngọc Sơn', '24': 'Heritage House, 87 Mã Mây | Nhà cổ 87 Mã Mây',
    '25': 'Concrete Flakes', '26': 'Bát Tràng House', '27': 'Bát Tràng Museum | Bảo tàng Gốm Bát Tràng',
    '28': 'Vietnam Museum of Ethnology | Bảo tàng Dân tộc học Việt Nam',
}
# The script's own "Vantage" line, lightly trimmed.
CAPTION = {
    '01': "The pavement outside 61 Văn Miếu, the Temple of Literature's wall at your back.",
    '02': "Outside 2C Quang Trung, a short walk south of St Joseph's Cathedral.",
    '03': 'The mouth of the alley, by the small shrine and the old fig tree.',
    '04': 'The alley at 5 Nguyễn Quang Bích, at the foot of the stairs.',
    '05': 'The wooden gate at 6 Ngõ 5 Từ Hoa, Tây Hồ, beside Kim Liên Pagoda.',
    '06': 'The pavement outside 15 Hàng Đường, looking up at the roofline.',
    '07': 'The pavement outside the café on Yên Phụ Street, by the roaster at the door.',
    '08': "The gate of 8 Chân Cầm, a few metres from St Joseph's Cathedral.",
    '09': "Across Ngô Quyền Street from the hotel's white front, number 15.",
    '10': 'The lakeside in front of the hotel, 8 Đỗ Đức Dục, looking back at the curved façade.',
    '11': 'The pavement on Hàng Khay, opposite number 21, the lake behind you.',
    '12': 'Beside the meditation house at the centre of the site, Trại Lãng village, Sơn Tây.',
    '13': 'The shopfront at 44B Hàng Bún, Ba Đình, near Trúc Bạch Lake.',
    '14': 'The lane at 2 Ngõ 66 Yên Lạc, Vĩnh Tuy, outside the gallery house.',
    '15': 'The gate of 14 Phan Huy Ích, Ba Đình, looking into the front courtyard.',
    '16': 'Outside Bạch Mã Temple, 76 Hàng Buồm, in the middle of the Old Quarter.',
    '17': 'August Revolution Square, in front of the Hanoi Opera House, 1 Tràng Tiền.',
    '18': 'The edge of Ba Đình Square on Hùng Vương, facing the Mausoleum.',
    '19': 'In front of Đoan Môn, the south gate, inside the citadel grounds off Hoàng Diệu.',
    '20': 'The main approach, facing the Victory Tower, off Thăng Long Avenue, Xuân Phương.',
    '21': 'The pedestrian walkway at the Hanoi end, looking out over the Red River.',
    '22': 'The foot of the museum steps, 19 Ngọc Hà, with the One Pillar Pagoda close by.',
    '23': 'The lakeshore on Đinh Tiên Hoàng, by the Pen Tower, facing the red Thê Húc Bridge.',
    '24': 'The shopfront at 87 Mã Mây, Old Quarter.',
    '25': 'The lane at 21 Ngõ 2 Lê Văn Hưu, Hai Bà Trưng, looking up at the façade.',
    '26': 'The street outside 188 Bát Tràng, in the ceramics village, looking at the brick façade.',
    '27': 'The open ground floor at Số 1 Đường 1-5, Bát Tràng, looking up into the curved terracotta forms.',
    '28': 'In front of the main exhibition building, the Bronze Drum, Nguyễn Văn Huyên Street, Cầu Giấy.',
}
M = 'Designed by a Master'
TAGS = {
    '01': ['Venue', 'Food', 'Contemporary'],
    '02': ['Venue', 'Food', 'Contemporary'],
    '03': ['Market', 'Food', 'Hidden Gem', 'Free to Visit'],
    '04': ['Venue', 'Performance', 'After Dark', 'Hidden Gem'],
    '05': ['Venue', 'Food', 'After Dark', 'Hidden Gem', 'History'],
    '06': ['Notable Building', 'Food', 'Contemporary', 'Viewpoint', 'Hidden Gem'],
    '07': ['Venue', 'Food', 'History', 'Hidden Gem'],
    '08': ['Venue', 'Food', 'Colonial', 'History', 'Hidden Gem'],
    '09': ['Notable Building', 'History', 'War', 'Colonial', 'Iconic Landmark'],
    '10': ['Notable Building', 'Architecture', 'Contemporary', M, 'Carlos Zapata'],
    '11': ['Notable Building', 'Architecture', 'Colonial', 'Commerce'],
    '12': ['Notable Building', 'Architecture', 'Contemporary', 'Green Escape', M, '1+1>2 Architects'],
    '13': ['Museum', 'Art', 'Commerce', 'Hidden Gem'],
    '14': ['Notable Building', 'Art', 'Contemporary', 'Hidden Gem'],
    '15': ['Venue', 'Art', 'Contemporary', 'Colonial', 'Hidden Gem'],
    '16': ['District', 'History', 'Commerce', 'Free to Visit', 'Iconic Landmark'],
    '17': ['District', 'Architecture', 'History', 'Colonial', 'Power', 'Iconic Landmark'],
    '18': ['Public Square', 'Monument', 'Civic', 'Power', 'Remembrance', 'Free to Visit', 'Iconic Landmark',
           M, 'gmp Architekten', 'Garol Isakovich'],
    '19': ['Monument', 'History', 'Power', 'War', 'Iconic Landmark'],
    '20': ['Museum', 'War', 'History', 'Brutalist', 'Contemporary'],
    '21': ['Bridge', 'Engineering', 'War', 'Colonial', 'Iconic Landmark', 'Viewpoint', 'Free to Visit'],
    '22': ['Museum', 'Monument', 'History', 'Power', M, 'Garol Isakovich'],
    '23': ['Religious Building', 'Faith', 'Literature', 'Waterfront', 'Iconic Landmark'],
    '24': ['Notable Building', 'History', 'Commerce', 'Architecture'],
    '25': ['Notable Building', 'Architecture', 'Contemporary', 'Hidden Gem', M, 'G8A Architecture'],
    '26': ['Notable Building', 'Architecture', 'Contemporary', M, 'VTN Architects'],
    '27': ['Museum', 'Architecture', 'Art', 'Contemporary', M, '1+1>2 Architects'],
    '28': ['Museum', 'History', 'Architecture', 'Art', M, 'Hà Đức Lịnh'],
}


def paragraphs(f):
    body = open(f, encoding='utf-8').read().split('\n---\n', 1)[1]
    ps = [p.strip() for p in re.split(r'\n\s*\n', body) if p.strip()]
    return [p for p in ps if p != '[beat]']


def cut(t, n=145):
    t = t.replace('\n', ' ')
    if len(t) <= n:
        return t
    return t[:n].rsplit(' ', 1)[0].rstrip(',;:—-') + '…'


folders = {}
for d in sorted(os.listdir(DROP)):
    txt = [f for f in glob.glob(os.path.join(DROP, d, 'hanoi_*.txt')) if not f.endswith('_TTS.txt')]
    if txt:
        folders[os.path.basename(txt[0])[6:8]] = (os.path.join(DROP, d), txt[0])

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
    stop = dict(id=U(f'atlas-stop:han:{slug}:1'), order=0, title=TITLE[n], caption=CAPTION[n],
                latitude=float(la), longitude=float(lo), audioURL=B + f'audio/{slug}.mp3',
                audioDurationSeconds=du, triggerMode='geofenced', triggerRadiusMeters=int(r),
                imageURL=hero, transcriptText=txt)
    new.append(dict(id=U(f'atlas-tour:han:{slug}'), createdAt='2026-10-14', title=TITLE[n],
                    shortDescription=cut(txt), longDescription='\n\n'.join([ps[0], ps[2]]), makerId=MAKER,
                    heroImageURL=hero, additionalImageURLs=[B + 'images/' + x for x in names[1:]],
                    kind='single', stops=[stop], introAudioURL=None, totalDurationSeconds=du,
                    walkingDistanceMeters=None, centroidLatitude=float(la), centroidLongitude=float(lo),
                    city='Hanoi', country='Vietnam', relatedTourIds=[], primaryCategory=cat,
                    tags=TAGS[n], priceUSD=0))

maker = dict(id=MAKER, displayName='Atlas Studio HAN', platform='dozent', handle='atlas.han', avatarURL=None,
             avatarEmoji='🇻🇳',
             bio="Atlas Studio's Hanoi bureau — audio tours of a thousand-year-old capital: the citadel and the "
                 "tube houses of the Old Quarter, French villas divided into flats and turned into cafés, a "
                 "bridge kept standing through the bombing, and the architects building the city now.",
             websiteURL=None)
last = max(i for i, m in enumerate(d['makers']) if m['displayName'].startswith('Atlas Studio'))
d['makers'].insert(last + 1, maker)
assert not {t['id'] for t in d['tours']} & {t['id'] for t in new}
d['tours'].extend(new)
open(P, 'w').write(json.dumps(d, indent=2, ensure_ascii=False) + '\n')
print(len(new), 'tours added; maker', MAKER)
for t in new:
    print(f"{t['title'][:30]:30} {t['stops'][0]['audioDurationSeconds']:4}s imgs={1 + len(t['additionalImageURLs'])} r={t['stops'][0]['triggerRadiusMeters']}")
