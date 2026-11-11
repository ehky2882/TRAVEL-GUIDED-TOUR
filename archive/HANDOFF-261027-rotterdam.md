# HANDOFF 2026-10-27: Rotterdam launches (Atlas Studio RTM 🇳🇱, 28 singles) + Portugalia Tasca (AMS)

**What shipped:** a new studio, **Atlas Studio RTM**, the 53rd, with 28 single-stop audio tours of Rotterdam and no
walks, plus one Amsterdam single, Portugalia Tasca, under the existing **Atlas Studio AMS**.
- **Maker:** platform `dozent`, handle `atlas.rtm`, uuid5 `atlas-maker:rtm` = `27b0e3b7-f067-5907-bd1f-ecc08cef3718`.
- **Ids:** `atlas-tour:rtm:rtm-<slug>`, stops `atlas-stop:rtm:rtm-<slug>:1`; Portugalia `atlas-tour:ams:ams-portugalia-tasca`.
- **Catalogue:** tours 2168 → 2197, makers 718 → 719, stops 2627 → 2656. Cities (1004), countries (103) and places
  (507) did not move: creator pins already covered Rotterdam.

**Source:** a Dropbox drop from arthur.yung (the contributor, not the owner), 29 folders. Triage went to the contributor
first; they approved everything, sent Portugalia Tasca (Amsterdam) to AMS, replaced the Fotomuseum photos (the first set
showed the old Las Palmas building, not Pakhuis Santos), and asked for FENIX to use the existing creator pin's point.
- **Audio:** 105–125 s each. Not transcribed against the scripts.
- **Photos:** 119, no byte duplicates, all 1200×900 WebP; every photo looked at and on-subject. Five folders carried
  another venue's filenames (reused names, right content) and were renamed; `OX_3o.webp` is photo 3.
- **Text:** `longDescription` = hook + paragraph 3, as in Lille; `shortDescription` cut at 145 characters; `[beat]`
  stripped from the transcript. Captions written by hand from each script's orientation paragraph.
- **Bilingual `English | Dutch`** on 6: Donner Bookshop | Boekhandel Donner, Van Brienenoord Island | Eiland van
  Brienenoord, Schoonoord Historic Garden | Historische Tuin Schoonoord, Kralingen Lake | Kralingse Plas, Market Hall |
  Markthal, Dutch National Museum of Photography | Nederlands Fotomuseum.
- **Geofence:** 40 m for venues; 50 m for larger buildings; 60 m for the arboretum, the island, the lake and FENIX.

**Coordinates.** `check-coordinates.py --drop`: 1 GROSS (Bakehouse — a false hit on a different Bakehouse in
Kinderdijk; the supplied point is on the 2e Middellandstraat as scripted), 8 UNVERIFIABLE, all then checked by name or
address in OSM: every one within ~25 m except FENIX (135 m, on the wrong side of the Rijnhaven → moved onto the pin)
and Kralingse Plas (80 m from the lake's centroid, on the shore path, as scripted). Supernova had no coordinate; OSM's
node at 's-Gravendijkwal 68 used. Bias: 9/14 north, median +14.1 m, p = 0.42 — not callable on this sample.

**Architect tags (Job 5), 6 new names on one line in each list:** H. F. Mertens, Jo Vegter, Jo Coenen, Stok & Kanters,
Zondervan Architectuur, De Roos & Overeijnder. Existing tags used: MVRDV (Depot, Markthal), Marcel Breuer (Bijenkorf),
MAD Architects (FENIX), Rem Koolhaas (Timmerhuis, for HAY; the catalogue files OMA under Koolhaas). **Not** tagged
Willem Dudok on the Bijenkorf (his store was demolished) or on Dudok in het Park (named after the café chain). Not
tagged Zocher (script gives only a surname, ambiguous between father and son) or ZUS on OX (they converted the
Schieblock above; the tour is the basement restaurant).

**Places:** two, for the owner (`status/owner/rotterdam-launch.md`): the new Depot Boijmans tour → the existing place
(9 m, join-places), and FENIX tour + FENIX Migration Museum pin (0 m). Nothing created or joined.

**gh-pages:** `9ee7e50b`, one commit adding 148 files (29 audio, 119 images), built with plumbing. Diff was 148 A only.

**Checks:** `validate-tours-mirror` 0 errors, no warnings on the new tours · filenames align (148) ·
`spine-lookup` 29 answered, 0 failed.
