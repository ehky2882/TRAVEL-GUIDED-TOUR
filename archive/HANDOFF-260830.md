# HANDOFF — 2026-08-30 (session 120d)

Branch `claude/linked-tours-send-ahlhiy`, **restarted from `origin/main` at `6513cf1c`** — the
previous work on this branch name merged as #633/#634/#635/#636, and a merged PR is finished.

Two things happened: the owner ran the removal SQL, and the owner asked for five architects.

---

## 1. The `@nycunfilteredstories` pull reached Postgres

`backend/pull_nycunfilteredstories.sql` was run in the Supabase SQL Editor. **Verified against the
live `get_catalog` RPC, not the editor's success line:**

```
RPC: tours 1553 | linkPins 244 | makers 199 | places 41
gone  Verrazzano-Narrows Bridge · Empire Theatre · Brooklyn Bridge Caissons · The Octagon
gone  @nycunfilteredstories · @theironwil
pins wrongly inside tours: 0
```

**Nothing is owed here.** The numbers are far above the catalogue's own because `main` moved
**eighteen commits** while this was outstanding — three more link-pin batches and several places —
plus the long-standing `Zxxx` test tour and upsert-only maker accumulation from real signups.
**Assert on the specific ids, never on the totals.**

⚠️ The durable point, already in CLAUDE.md and now paid for: **a deletion in `Tours.json` reaches
the gh-pages mirror and the bundled seed and never reaches Postgres**, because
`seed_from_toursjson.py` is upsert-only by design so a content re-seed can never wipe maker-created
rows. The mirror going quiet is not the pin going away.

---

## 2. Five architects added to the controlled vocabulary

**Owner: *"add 5 architects to vocab."*** These are the five verified while wiring the 2026-08-28
batch and recorded there as absences.

| Name | Carried by |
|---|---|
| `Moshe Safdie` | Habitat 67 — Atlas tour **and** link pin |
| `John Augustus Roebling` | Brooklyn Bridge, Manhattan Side (Atlas tour) |
| `William Henry Barlow` | St Pancras & King's Cross (tour) **and** St Pancras International (pin) |
| `KieranTimberlake` | U.S. Embassy, Nine Elms (pin) |
| `José Ignacio Linazasoro` | Escuelas Pías de San Fernando (pin) |

**Vocabulary 329 → 334 architects; 379 → 384 tags total.** Both `Models/Tag.swift` and
`scripts/validate-tours.swift` edited and asserted identical. **0 near-duplicates** on normalised
token sets. **0 unused names** and **0 named-architect entries missing `Designed by a Master`**
(496 named entries; the shelf holds 548).

### What is worth remembering

- **The Brooklyn Bridge tour had no architect AND no shelf tag**, while its own narration says
  *"the bridge that killed its designer"* and *"John Roebling never lived to see his bridge open."*
  It gains both. This is the #493 mirror-image defect on one of the catalogue's most famous
  structures.
- **The tag is `John Augustus Roebling` though the tour says "John Roebling"** — the vocabulary
  follows published full names (cf. `James Gamble Rogers II`). Nothing in the narration changed.
  `Brooklyn Bridge Park` keeps `Michael Van Valkenburgh` and gains nothing; he made the park.
- **Where a subject exists as both a tour and a pin, both were tagged** so the pair shares shelves.
  St Pancras takes Barlow **alongside** the `George Gilbert Scott` both already carried — Scott
  built the hotel, Barlow the shed, and the tour's own description names both.
- **Two are judgements and are reversible.** Neither the Escuelas Pías nor the U.S. Embassy caption
  names its architect in text. Escuelas Pías already carried `Designed by a Master`, so a previous
  session had already read authorship as part of the point. **The Embassy pin carried no generic tag
  and now gains one**, on the reading that its post — *"America's Billion-Dollar Embassy Has Hidden
  Defenses"* — is entirely about the building's **designed** defences. Inside the Jules Dalou rule,
  but the one entry here a reasonable person could argue with.
- **⚠️ A correction to CLAUDE.md:** the 2026-08-28 entry said all five "ship the generic tag". The
  Embassy pin had none. Fixed in place, and that bullet is now marked superseded.
- **No other entry mentions any of the five** — a full-text sweep over every title, caption,
  description and transcript across 1,552 tours and 244 pins returns exactly three hits.

### Verification

- Validator mirror — vocabulary parsed from **both** Swift files, refusing to run if they disagree
  or either parse is empty (they agree at **384 tags across 5 facets**) — **self-tested against 44
  injected fault classes, 44/44 caught**, then **0 errors, 2 warnings** across 1,552 tours + 244
  pins + 41 places. Both warnings pre-existing (VIA 57 West's transcript gap, Bedrock Caverns'
  deliberate null `walkingDistanceMeters`).
- `Tours.json` **byte-stable under a Python re-dump at `indent=2`** before editing; diff **16
  insertions / 7 deletions, exactly seven tag arrays touched**.
- **⚠️ Nothing compiled locally** — no Swift toolchain in a Linux web session. **CI on the PR is the
  only compile check**, and this is a `Models/Tag.swift` change, so it **waits for owner OK + a
  simulator look**.

---

## Still open, none of it started

- **Two place names are judgements** — `Washington Square Park` (owner said "arch") and
  `St Pancras International` (the Atlas tour is *"St Pancras & King's Cross"*). One line each.
- **Three heroes weak but not wrong** — Handel Hendrix House (archive concert footage), the
  Guggenheim (a sketchbook and hands), the Met (a Twombly canvas under a cartoon sticker).
- **Habitat 67's pin thumbnail draws the real building as a ruin** — cracked windows, a
  spray-painted maple leaf, a storm sky. Genuine, correctly drawn, flagged.
- **Little Island** stays a NEAR pair at 89 m and no place, as instructed.
- **Tooling gaps, unchanged:** `check-image-duplicates.py` cannot scope to a link-pin batch
  (`--since <ref>` or `--pins` is the fix, sixth batch running); `render_hero` still has no vertical
  `--focus` lever; `check-place-candidates.py`'s title rule under-reports.
