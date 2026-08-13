# HANDOFF — 2026-08-12 (session 90, web) — Cape Town launched: 30 tours + 30th maker Atlas Studio CPT

**One-line summary:** Cape Town goes live — 30 single-stop tours under new maker **Atlas Studio
CPT** 🇿🇦, the catalog's **first South African city** and Africa's second bureau after Marrakech,
wired the same day the owner's Dropbox drop arrived. Catalog **1320 → 1350 tours / 29 → 30
makers / 1666 → 1696 stops**. The catalog crosses **30 cities**.

Branch: `claude/new-tours-upload-6z1lsg`.

## ⚠️ Rebased mid-session onto three tag PRs

While Cape Town was being wired, **#491 (Museum Island hero swap), #492 (add 20 architect
tags; name 45 tours' designers) and #494 (add Karl Friedrich Schinkel)** all merged to `main`.
Handled the same way Sydney handled the concurrent Melbourne merge: reset the branch to the
new `origin/main`, re-ran the **idempotent** assembler from `cpt_entries.json`, re-confirmed
Tours.json byte-stability against the *new* upstream file, and re-validated.

Two things worth knowing from that:

- **The vocabulary grew 38 → 59 architects.** All 30 Cape Town tours' tags remained valid
  (the vocabulary only grew), and **Herbert Baker is still not in it** — so Rhodes Memorial
  correctly keeps `Designed by a Master`. **Baker is the name the next architect PR should
  carry.**
- **The mirror validator's cross-check independently confirmed #492/#494 kept `Tag.swift` and
  `scripts/validate-tours.swift` in sync** — it raises if the two disagree, and it did not.

## What shipped

- **New maker:** Atlas Studio CPT (`38456828-e395-5fd7-9525-a10329fabb15` = uuid5
  `atlas-maker:cpt`, 🇿🇦), the 30th — reverse-verified against 10 live makers **plus all 29
  SYD tour+stop pairs** before minting.
- **30 single-stop tours**, geofenced 30 m: Battery Park · Beau Constantia · Belly of the
  Beast · Between Us · Bo-Kaap / Schotsche Kloof · Boulders Beach · Cape Point · Chandler
  House · Clarke's Bookshop · Club Kloof · COY · District Six Museum · Dylan Lewis Studio &
  Sculpture Garden · Fyn Restaurant · Gigi Rooftop Restaurant & Bar · Hemelhuijs ·
  Kirstenbosch National Botanical Garden · Lion's Head · Maiden's Cove Tidal Pool · Mount
  Nelson High Tea · Muizenberg Beach · Norval Foundation Art Museum · Rhodes Memorial ·
  Rosetta Roastery Cafe · Southern Guild Cape Town · Table Mountain Aerial Cableway · The
  Company's Garden · The Gin Bar · Two Oceans Aquarium · Zeitz MOCAA.
- **30 MP3s, 4,367 s ≈ 1h12m47s** + 98 images to gh-pages (commit `5a4528f`, pure plumbing,
  exactly 128 additions / 0 deletions); Tours.json diff **1,341 insertions / 0 deletions**.
- **Category mix:** 11 foodAndDrink · 6 natureAndParks · 5 history · 4 visualArt ·
  2 culturalHeritage · 1 literature · 1 architecture.

## The delivery — ninth consecutive complete drop

Dropbox `/scl/fo/` link, 84 MB zip, first try with `dl=1`. MP3s **already 44.1 kHz/128 kbps**
(no transcode), all 98 images **already 1200×900**, 30 clean/`-tts-safe` script pairs 1:1,
scripts numbered **1–30 with no gaps**, everything byte-distinct. Zero audio work, zero image
work. The complete-drop shape has now held for nine cities straight.

Folder convention unchanged: `output <Name> <lat>, <long>`, `#UXXXX`-escaped (only
`Lion#U2019s Head` this time). Images numbered `01..NN`, `01` = hero.

## 🐛 Chandler House's coordinate was 423 m off — the silent-failure class

The supplied folder coordinate sat on **Morris Street in the Bo-Kaap**. The venue is the
OSM-named POI **"Chandler House, 53, Church Street"** in the CBD's old antiques quarter,
423 m away. **At the catalog's 30 m geofence the tour would never have fired** — and nothing
else would have caught it: the URL resolves, the validator passes, the image is right, the
tour just silently does nothing when you stand in front of the building.

Re-geocoded to **`-33.9226820, 18.4181163`** (Camp Cove / Tokyo Hōrin-ji precedent) and
corroborated by the hero photograph, which carries both the "CHANDLER HOUSE" sign and the
number **53**.

⚠️ **The script says "You're on Church Street in the Bo-Kaap" — there is no Church Street in
the Bo-Kaap.** The audio is the audio, so `transcriptText` keeps it verbatim (the Melbourne
Siglo precedent) and the `longDescription` deliberately does not assert the neighbourhood.

## The other 29 coordinates — and why the check must end in a distance

All 29 verified against the streets their own scripts name. **Four reverse-geocode to a
cross-street and are correct anyway**, which is the reason a road-name comparison alone is
not a check:

| Tour | Nominatim road | Reality |
|---|---|---|
| Fyn Restaurant | Longmarket Street | **10 m** from the OSM POI at 37 Parliament Street — Speaker's Corner is the corner building |
| The Gin Bar | Bree Street | **23 m** from the OSM POI at 64A Wale Street |
| Gigi Rooftop | Saint George's Mall | exactly as scripted ("reached from St George's Mall") |
| Club Kloof | Camp Street | **70 m** from *Our Local*, the sibling restaurant its own script names as "just up the same street" |
| Bo-Kaap | Buitengracht Street | suburb reads literally "Bo-Kaap (Schotsche Kloof)" — the tour's own name |

⚠️ **Nominatim house-number lookups on Kloof Street are a street-centroid fallback** —
"84 Kloof Street" and "158 Kloof Street" return the *identical* point, so any distance derived
from them is meaningless. This nearly produced a false positive on Club Kloof. Corroborate
with a **named POI** instead.

⚠️ Also worth knowing: reverse-geocoding at **zoom 16 gave the wrong street for Between Us**
(New Church Street); at **zoom 18** it correctly reads Bree Street, and the forward geocode of
the restaurant is 15 m away. Use zoom 18 for venue-level checks.

## ✅ Second consecutive clean open-every-image audit

All 30 heroes opened and read against their scripts; all 98 images swept. Venue identity
confirmed **by signage in frame** for every ambiguous interior — Belly of the Beast (the two
chefs under their own sign), Clarke's (gold window lettering), Chandler House ("53"), Rosetta,
Southern Guild ("GUILD" on the Silo District concrete), Two Oceans, Between Us — and by
unmistakable subject for the rest.

The look-alike risks this city carries were checked deliberately:

- **Two penguin tours** — Boulders' wild colony vs the aquarium's, which the Boulders script
  explicitly cross-references. Both correct, neither borrowed from the other.
- **Three mountains** — Lion's Head's stratified dome, Table Mountain's plateau, Devil's Peak.
  Correct in every frame including the two cloud-inversion shots.
- **Two gardens** — Kirstenbosch (Boomslang walkway, 1898 camphor avenue) vs the Company's
  Garden (Delville Wood memorial, rose garden, fish pond).

No Thyssen-class error. Zeitz gallery image 6 is a **historical B&W archive photo** of the
working silo — deliberate and editorially the point (it shows what the building was), kept
despite the usual "modern colour photograph" gate, which applies to *sourced* PD imagery, not
owner-supplied assets.

## Tags, cities, sensitivity

- **✅ Thomas Heatherwick is in the vocabulary and used by name** on Zeitz MOCAA; per the
  Calatrava precedent the named architect tag implies `Designed by a Master` rather than
  sitting beside it. **⚠️ Herbert Baker is absent even after #492/#494 added 21 architects**
  (Rhodes Memorial ships `Designed by a Master`); DHK Architects likewise absent and left
  untagged rather than inflated. **Baker is the name the next architect PR should carry** —
  Utzon, Schinkel, Niemeyer and Bo Bardi have now all landed.
- **⚠️ Dylan Lewis ships `city: "Stellenbosch"`** (~45 km east, Cape Winelands District
  Municipality — a different municipality; the Aït Benhaddou / Healesville / Campinas
  convention). **Cape Point, Boulders Beach and Muizenberg are genuinely City of Cape Town**
  despite being far down the peninsula, and correctly keep `city: "Cape Town"` — don't
  "fix" them.
- **Sensitivity was needed in six places** and the scripts' factual, unflinching register is
  carried into the descriptions rather than softened or dramatised: District Six's forced
  removals under the Group Areas Act; Rhodes's contested legacy at **both** the memorial and
  Kirstenbosch (which he owned); apartheid beach segregation at Maiden's Cove; the Iziko Slave
  Lodge at the Company's Garden; the convict labour behind Battery Park's stone; Bo-Kaap's
  origins in slavery and exile. **No mortality figure anywhere.** All images owner-supplied →
  **no CREDITS rows**.

## Scripts

One-line header (`TITLE — ATLAS AUDIO TOUR`), uniform across all 30. The `-tts-safe` twin
proves the header is not narrated while the **closing recommendation line is** — it stays in
`transcriptText`. Exactly one `[beat]` per script (30 total), all stripped; no other bracketed
direction anywhere in the batch. Captions extend across sentences until they clear 60 chars;
**shortest shipped is 76**, and the two one-word openers ("Two penguins." / "Feral pigs.")
correctly absorb their next sentence.

## Verification

- **0 errors, 0 warnings across all 1350 tours** — Python mirror of `validate-tours.swift`
  (no Swift toolchain in a Linux web session). Vocabulary parsed from **both**
  `Models/Tag.swift` and the Swift validator, raising on disagreement or an empty parse.
  **Self-tested against 43 injected fault classes — 43/43 caught**, now including orphan
  `makerId`, bad `triggerMode`, negative `walkingDistanceMeters`, and near-identical sibling
  transcripts.
- uuid5 reverse-verified **10/10 live makers + 29/29 SYD tour+stop pairs** before minting CPT.
- 0 duplicate tour / stop / maker ids across 1350 / 1696 / 30.
- **98 uploaded = 98 referenced, 0 orphaned.**
- All **128 asset URLs hash-verified against the uploaded git blob SHAs** (not by 200s).
  Pages deploy lagged and served 404; the Actions API showed **`in_progress`, not
  `cancelled`** — the documented distinction.
- gh-pages via **pure plumbing** (blobless fetch → temp `GIT_INDEX_FILE` → `hash-object -w` →
  `update-index --cacheinfo` → `write-tree --missing-ok` → `commit-tree`): 0 of 128 target
  paths pre-existed (checked against all **6,425** existing gh-pages paths), tree diff
  **exactly 128 additions, 0 deletions, nothing outside `audio/` + `images/`**.
- Tours.json confirmed **byte-stable under a Python re-dump before editing** (indent=2,
  `ensure_ascii=False`, trailing newline) → diff is a clean append.

## Open for the owner

1. **Maiden's Cove Tidal Pool ships hero-only** — only one image was supplied. Backfillable
   without touching audio.
2. **Gigi Rooftop's hero is the indoor dining room**, not the emerald pool its script opens
   on. Venue is correct and the pool-side rooftop is **gallery image 2** — a one-line swap if
   wanted. The owner's `01` = hero pick order was honoured rather than overridden.
3. **Chandler House's script says "Bo-Kaap"** while the venue is on Church Street in the CBD.
   The coordinate now points at the real building; the narration is unchanged.

## Notes for the next session

- **The audio-pending queue is still EMPTY.** Nothing is staged anywhere — the next city needs
  a fresh drop.
- **⚠️ PR #493 (`claude/new-tours-upload-nxezi4`) is still open and also touches `Tours.json`**
  — "add 39 architects to the controlled vocabulary, and tag the 95 tours". Note its sibling
  PRs #492/#494 already merged, so #493 may now be partly redundant; it *modifies* tags on
  existing tours while this PR *appends* 30 new ones, so they should merge cleanly, but
  whichever lands second needs a rebase check. **If #493 adds Herbert Baker**, re-tag Rhodes
  Memorial from `Designed by a Master` to the named tag.
- **⚠️ gh-pages is busy.** A `publish-catalog` run committed on top of the Cape Town asset
  commit minutes after the push. The assets were unaffected (verified `5a4528f` is still an
  ancestor of the head and the paths are in the live tree) — but on a day with concurrent
  sessions, **confirm ancestry rather than assuming your push is the head**.
- Standing code work, unchanged: Paid tours Phase 3 (PR #469), launch-runbook Step 1 (cut one
  TestFlight build the fastlane way), an architect PR carrying Herbert Baker, PR #475 closeout.
