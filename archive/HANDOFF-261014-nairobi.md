# HANDOFF 2026-10-14: Nairobi launches (Atlas Studio NBO, 13 singles) + 3 architect tags

**What shipped:** a new studio, **Atlas Studio NBO** 🇰🇪, the 43rd. 13 single-stop audio tours of Nairobi (one,
the Mbai Caves, in Kiambu just north), no walks.
- **Maker:** platform `dozent`, handle `atlas.nbo`, id uuid5 `atlas-maker:nbo` = `e4eb6e6a-d72b-5cd6-9ab4-980821a663ce`,
  inserted after Atlas Studio TAO. Tours `atlas-tour:nbo:<slug>`, stops `atlas-stop:nbo:<slug>:1`.
- Tours: Beit é Selam, Road House Grill (Kilimani), K'Osewe Ranalo Foods, Chronos (Lavington), Ololo Safari Lodge,
  Chester House, Maasai Market (City Centre), Nairobi City Market, Paradise Lost — the Mbai Caves, Karura Forest,
  Nairobi National Park, KICC Rooftop, Giraffe Centre.
- Catalogue: tours 1942 → 1955, makers 680 → 681, cities 981 → 982 (Kiambu). Countries unchanged: one creator pin
  (Britam Tower) already covered Nairobi and Kenya.
- **Creator name:** the contributor chose "Atlas Studio + city code", and said explicitly the studio has nothing
  to do with cave_bureau. ⚠️ **The narration itself names "the cave_bureau guide"** (the Nairobi architecture
  practice's city guide the scripts were researched from) in 12 of the 13 tours, and quotes it. That cannot be edited
  without re-recording; it is on Edward's board as `nairobi-cave-bureau-credit`, with the photo licences.
- **Architect tags (Job 5, contributor asked):** Karl Henrik Nøstvik and David Mutiso (KICC), Richard Hughes
  (Chester House, credited by the Museum of Kenyan Architecture per the script).
- **Dropped by the contributor:** tours 05, 06, 09 and 14 of the numbering. Not coming.

**Coordinates:** all 13 checked by reverse geocode. `check-coordinates.py` GROSS on Mbai Caves (the point is 5 m
from one OSM "Paradise Lost" node; the geocoder matched a second node 497 m away) and K'Osewe (on Kimathi Street as
scripted; the geocoder found the Upper Hill branch) are both false. **Nairobi National Park was MOVED** with the
contributor's OK: the supplied point (-1.3825, 36.8610) sat mid-park, 9.4 km from the main gate. It is the value
nairobipark.org gives for "the main gate", which is wrong. The tour now sits on the OSM node *Nairobi National Park
Main Gate*, Langata Road (-1.336773, 36.7798646), radius 100 m, so it plays as cars drive in. The script's own
ending ("head towards the main gate and find the Ivory Burning Site") still works on the way out.
⚠️ Karura Forest is pinned on the Mau Mau caves while its script opens "you're most likely at a gate"; left as
supplied, flagged to the contributor.

**Abandoned 2026-10-12 session** (session_01WjauYjJZupCsdvFJUezero) had pushed 13 photos for four of these tours to
gh-pages (`9a0813e4`) with no branch or PR. 11 are byte-identical to the drop; the two KICC files differ, so the
drop's KICC photos are published as `kicc-rooftop_hero-2.webp` / `_2-2.webp`, and the old two are orphans.
gh-pages commit `cb92dd5e`: 51 additions (13 MP3 + 38 photos), nothing modified.

**Checks:** validator 0 errors (warnings: Giraffe Centre has no place-type or theme tag, the Mbai Caves no place
type — nothing in the vocabulary fits). `check-place-candidates` and `join-places --max-move 100`: nothing in Kenya.
Spine lookups: 13 asked, 0 failed. Images and audio hash-checked live after the Pages deploy (see PR).

**Heads-up, not changed:** the Giraffe Centre hero (from the 12 Oct upload, identical in the drop) shows breakfast at
Giraffe Manor next door, not the Centre; the Maasai Market hero shows Maasai people, not the market.

**Follow-up, same day:**
- **Karura Forest moved** to the OSM node *Main Gate* on Limuru Road, beside Gate A (-1.2471606, 36.816451), at
  the contributor's request, matching the National Park. It was on the Mau Mau caves, 1.9 km inside; the script
  opens "you're most likely at a gate… off Kiambu Road or Limuru Road" and ends by sending you down to the caves.
- **The contributor answered the two board questions:** the cave_bureau mentions are fine, and the photos are
  royalty-free. Recorded on `status/owner/nairobi-cave-bureau-credit.md` as their answer, for Edward to clear.
