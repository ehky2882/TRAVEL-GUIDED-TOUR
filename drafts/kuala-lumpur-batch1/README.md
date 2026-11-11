# Kuala Lumpur batch 1: Atlas Studio KUL (42 singles), wired 2026-11-10

Source: contributor drop (Dropbox, arthur.yung). 42 `output <Name> <lat>, <lon>` folders with scripts numbered 01–42.
Each folder holds `NN_<slug>_clean.txt` + `NN_<slug>_tts-safe.txt`, one MP3 (94–132 s) and 2–6 photos at 1200×900
WebP (174 delivered, 174 shipped, no byte duplicates). The contributor says the photos are royalty-free. The `é` in
KLoé arrived as a `#U00e9` escape, so the assembler matches folders by **script number**.

`scripts/` holds both texts as delivered. `coordinates.tsv` lists slug · lat · lon · radius · category · city, as wired.

`tools/wire_kuala_lumpur.py` is the assembler (`python3 -I wire_kuala_lumpur.py <unzipped drop> <stage dir>`), adapted
from `drafts/fukuoka-batch1/tools/wire_fukuoka.py`. Run it once only: it refuses colliding tour ids. Slugs carry a
**`kul-` prefix**: audio at `audio/kul-<slug>.mp3`, images at `images/kul-<slug>_hero.webp`, `_2.webp`, … in the drop's order.

- **Maker:** Atlas Studio KUL 🇲🇾, platform `dozent`, handle `atlas.kul`, uuid5 `atlas-maker:kul`
  = `70d7bfbd-188c-5712-b6d8-50c2a382d143`.
- **Ids:** `atlas-tour:kul:kul-<slug>`, stops `atlas-stop:kul:kul-<slug>:1`.

## Coordinates
All 42 folder-name coordinates were used as supplied; none moved.

`check-coordinates.py --drop`: **1 GROSS** (Pasar Seni, cleared by hand: the point sits on the Central Market
building; the geocoder matched the "Pasar Seni" area 367 m off), **4 UNVERIFIABLE** (Old KL Railway Station, RuMa,
KLoé, Heli Lounge; read by hand against their streets, all fine). Nasi Lemak Tanglin (4.2 km) and PS150 (1.2 km)
show large distances because the geocoder matched other venues; both points sit on the right street.

✅ **BIAS: 23/39 north, median +2.4 m, p = 0.34 — no significant directional bias.** First drop in a while where the
upstream northward offset is absent (Fukuoka, two days earlier, still had it).

## Wiring
- **City:** `Kuala Lumpur` for all 42 (Royal Selangor is in Setapak and APW in Bangsar, both inside KL). Country `Malaysia`.
- **Geofence:** 15–30 m for restaurants, bars, cafés and hotels; 30–50 m for museums, temples, towers and buildings;
  60 m for the National Mosque, Parliament, Merdeka Stadium and Saloma Link; 80 m for KLCC Park and KL Forest Eco Park.
- **Overlaps:** VCR and Pahit (43 m apart) were cut to 20 m each so they no longer overlap. **Ho Kow and Kwai Chai Hong
  sit 19 m apart, back to back** (the lane is directly behind the kopitiam), so they still overlap at 15 m each. That
  is the honest geography; both scripts refer to each other.
- **Bilingual titles — a deliberate mix, the contributor's choice:** Bahasa Malaysia on 13 national/civic sites
  (Masjid Negara, Muzium Negara, Tugu Negara, Pasar Seni, Parliament, …); **simplified Chinese** on the 6
  Chinese-community sites, each checked by search: Yut Kee | 镒记, Sek Yuen | 适苑, Ho Kow Hainam Kopitiam | 何九海南茶店,
  Sin Sze Si Ya Temple | 仙四师爷庙, Kwai Chai Hong | 鬼仔巷, Thean Hou Temple | 天后宫. The other 23 keep one name.
- **Text:** `longDescription` = hook + paragraph 3, `shortDescription` cut at 145 characters, `[beat]` stripped.
  Captions written by hand from each script's orientation paragraph.

## Architect tags (Job 5): 18 new names, one line in each list
Arthur Benison Hubback (Old Railway Station, Masjid Jamek) · Hijjas Kasturi (Menara Tabung Haji, Menara Tun Perak) ·
William Ivor Shipley (Parliament) · Ho Kok Hoe (Muzium Negara) · Stanley Jewkes (Stadium Merdeka) · T. Y. Lee
(Pasar Seni) · Baharuddin Abu Kassim, Hisham Albakri, Howard Ashley (Masjid Negara) · Kumpulan Akitek (National
Library) · Arkitek MAA, BEP Architects (Dayabumi) · Keys and Dowdeswell (Majestic) · James Robert Vethavanam (REXKL) ·
Domaine Architects (KLoé) · VERITAS Design Group (Saloma Link) · A. C. Norman, R. A. J. Bidwell (Sultan Abdul Samad
Building). Existing tags used: Norman Foster (ILHAM, in Foster + Partners' tower), Roberto Burle Marx (KLCC Park).
**Not** tagged: Felix de Weldon (Tugu Negara — a sculptor; tagged Public Art instead), César Pelli (KLCC Park script
mentions the towers, not the subject), Shin Chang and Shin Tseng (REXKL's 2019 conversion, named too loosely).

## Places — for Edward, nothing created or joined
| New Atlas tour | Existing entry | Distance | Found by |
|---|---|---|---|
| Sultan Abdul Samad Building \| Bangunan Sultan Abdul Samad | pin *Sultan Abdul Samad Building* | 88 m | check-place-candidates (NAME) |
| Dayabumi Complex \| Kompleks Dayabumi | pin *Dayabumi Complex* | 97 m | check-place-candidates (NAME) |
| ILHAM Gallery | pin *Ilham Tower* | 52 m | by hand — a gallery inside the tower, so a tenant; probably not a place |

Ho Kow / Kwai Chai Hong (19 m, TIGHT) are two different venues: co-location is not identity, not a place.
`join-places.py --max-move 100` raised nothing involving the 42.

## Content notes (audio already recorded)
Lines that will date: Menara Tun Perak "until July 2026 was called Menara Maybank"; Menara Tabung Haji calls it "the
old Maybank tower". Several hotel/restaurant scripts give opening details that may change.
