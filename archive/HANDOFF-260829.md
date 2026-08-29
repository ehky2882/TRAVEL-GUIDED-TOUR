# HANDOFF 2026-08-29 — nineteen link pins from one creator, and four pulled pins still live

Session 121. Branch `claude/tour-links-260829`, cut clean off `origin/main` at `3f2e1640`.
Content only — no Swift, no SQL, no build. **[PR #638](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/638)
merged** (squash `ce6ec46b`); this is a local Mac session, so the content auto-merge class applies.

**linkPins 150 → 169 · makers 153 → 154 · tours unchanged at 1,552 · places unchanged at 37.**
gh-pages `10b75d06` (19 heroes). Austria is the catalogue's 33rd country.

---

## What arrived

Nineteen links — **12 TikTok, 7 Instagram — all from ONE creator**, `@about_buildings`
("About Buildings + Cities", an architecture podcast). Six carried a coordinate, two of
those also a subject name; thirteen were bare. **All nineteen were alive and pinnable** —
no dead posts, no `/photo/` carousels. Fourth fully intact batch running.

**This is the first batch that is one creator end to end**, which changed the shape of the
work: no per-creator avatar hunting, one maker row already existing, and a single editorial
voice to read the captions against.

---

## The things worth carrying forward

### 🔴 A CREATOR ON TWO PLATFORMS IS TWO MAKER ROWS, AND ONE OF THEM ALREADY EXISTED

`TikTok @about_buildings` has had a maker row since the Dulwich Picture Gallery pin
(`D6EC084F-2E18-5C16-BBE5-197D5170162C`). The uuid5 scheme is over
`atlas-maker:<platform>:@<handle>`, so the twelve TikToks **reproduced that id exactly** and
merged into it — verified by hand before writing (`uuid5(NAMESPACE_URL,
"atlas-maker:tiktok:@about_buildings")` → the same id, and neither of the two plausible
alternative strings does).

**That merge is also what kept the avatar safe.** `avatar-tiktok-about-buildings.webp` is
already live on gh-pages, so the tool regenerated it and it was **excluded from the upload**
rather than overwritten — the `@urbanistariel` case from session 120, now twice. **20 files
generated, 19 uploaded.** `Instagram @about_buildings` is the new row and ships
`avatarURL: null`, which is all Instagram's embed allows.

### 🔴 THE SAME CLIP CROSS-POSTED IS TWO PINS ON ONE COORDINATE — FLAGGED TO THE OWNER

Link #6 (TikTok) and #16 (Instagram) are **the same footage of Plečnik's Zacherlhaus**, and
therefore land on the identical coordinate with the identical title. Two independent checks
caught it: the two-stage perceptual check nominated the pair at Hamming 1 with pixel-diff
**2.1** (identical pictures score under 1), and **`check-place-candidates.py` reports the pair
as its only new EXACT group.** Both shipped, because both links were sent; **it is a one-line
removal if the owner wants one gone.** Its one useful side effect is that the checker's EXACT
tier now has a second live example beyond the pre-existing Barcelona deferral.

### 🔴 ONE POST HAD NO CAPTION AT ALL AND THE HERO IDENTIFIED IT

TikTok `7668424951552101654` returns an **empty** oEmbed title. The thumbnail settled it in one
look: a Gothic-crowned setback tower with *Chicago Tribune* lettering on the low pavilion beside
it, and the burned-in line *"Did you know that Chicago's iconic gothic skyscraper,"* — the
**Tribune Tower**, confirmed against OSM's `Tribune Tower` building node at 435 North Michigan
Avenue. Same move as session 120's Habitat 67, and the second time in two batches that the
picture has answered a question the metadata could not.

### ⚠️ ALL SIX SUPPLIED COORDINATES CHECKED OUT — the first batch where none moved

Every one reverse-verified at zoom 18, and five come back **named exactly**:
`Heilig-Geist-Kirche` (Klausgasse 18, Ottakring) · `N M Rothschild & Sons` (St Swithin's Lane —
which is New Court) · `Bank of England` (Threadneedle Street) · `Blenheim Palace` (The Great
Court) · `Orford Ness National Nature Reserve`.

The sixth, the **Royal Hospital Chelsea stable block**, returns `Royal Hospital Road` with no
building node — OSM maps no stable block. It sits **51 m from the National Army Museum** on the
hospital's own western frontage, which is where Soane's 1814 stable block stands, so it is kept
as supplied. The Marriage Skate Shop rule: when OSM has no node for the thing, the venue's own
context is the next authority, not the nearest addressable feature.

### ⚠️ THIRTEEN BARE COORDINATES, FORWARD THEN REVERSE

Each was forward-geocoded and then reverse-verified onto its subject by name. Two needed a
second query and both failures were the query, not the place:

- **Kirche am Steinhof** returns only an `information/board` node under that name. The church
  itself is OSM's **`Otto-Wagner-Kirche`**, 48.2106094, 16.2787645 — 250 m from the signboard.
- **St Alban the Martyr** is not findable as "St Alban the Martyr, Brooke Street"; it is
  `St Alban the Martyr, **Brooke's Court**`, which is exactly the street sign visible in the
  hero. **Re-query before concluding a place is unmapped.**

**Two reverse-geocodes land on something else and both are right:** the Zacherlhaus returns
*Hypo Vorarlberg, 6 Brandstätte* (the bank in its ground floor — road **and** number match) and
the Certosa returns *Pinacoteca della Certosa* (the picture gallery inside it).

### ⚠️ THE VERTICAL `--focus` GAP, SEVENTH BATCH RUNNING — two hand re-crops

`render_hero` crops at `centering=(focus, 0.5)`, so on a 9:16 phone video the square is
width-limited and **`--focus` does nothing at all**. Both re-crops went through a mirror of the
tool's own pipeline — same `trim_bars`, same blur-and-pad, **same filename**, so `Tours.json`
never learns about it:

- **Tomba Brion** at vertical **0.15**, recovering the creator's own on-screen title
  *"Carlo Scarpa's Tomba Brion, 1968–78"*, which the centred square sliced off entirely.
- **Fondazione Querini Stampalia** at vertical **0.62**, dropping a half-word of clipped
  lettering (*"Stampalia"* alone) that the centred square left floating at the top.

**Negozio Olivetti was deliberately left alone** — moving up to keep the whole title would cost
the campanile its belfry, and the pin's own title already names the shop (the California Academy
rule).

### ⚠️ TWO HEROES ARE WEAK, ONE OF THEM BADLY — flagged, not resolved

- **🔴 Royal Hospital Chelsea Stable Block is a podcast talking head.** One of the hosts at a
  microphone, letterboxed, with a caption fragment across it. Right subject, **no view of the
  place at all** — the Hugo de Grootplein / Yonemoto Coffee shape, and the worst of them so far.
- **Tomba Brion** shows the municipal cemetery the memorial adjoins rather than Scarpa's
  concrete, though an `ALVISE BRION` headstone is legible in it and the re-crop now carries the
  title.
- **Negozio Olivetti** opens on Piazza San Marco rather than the shop, which is at least the
  right square — the showroom is under the Procuratie Vecchie.

A link pin re-hosts only the thumbnail, so **no other frame exists for any of them.**

### ⚠️ ARCHITECT TAGGING — two kept, five absent from the vocabulary

Caption-driven, per the documented rule. **Kept:** `Rem Koolhaas` (the caption reads *"OMA's New
Court, 2008–11, Rem KoolhaaS"*) and **`John Soane` twice** — the Bank of England post announces
*"our new series on John Soane"*, and the Chelsea reel is explicitly *"John Soane's work for the
Royal Hospital Chelsea"*. The neighbouring Atlas tour *Bank Junction* already carries Soane, so
the pin and the tour share shelves.

**Absent from the vocabulary, shipping the generic `Designed by a Master`:** **Carlo Scarpa**
(four pins — Tomba Brion, Castelvecchio, Querini Stampalia, Negozio Olivetti), **Jože Plečnik**
(three — Heilig-Geist, Zacherlhaus ×2), **Otto Wagner**, **William Butterfield**, **John
Vanbrugh**. **Scarpa and Plečnik are the two most conspicuous absences the catalogue now has**,
ahead of Safdie and Roebling, because each carries several pins on their own. Adding names is a
`Models/Tag.swift` change — code, owner OK — so it stayed out of a content PR.

⚠️ **Herbert Baker is in the vocabulary and was deliberately NOT tagged** on the Bank of England,
even though the facade in the frame is his rebuilding over Soane's screen wall. The caption makes
Soane the subject; the rule is what the source says, not what the pixels show.

### ⚠️ THE TRIBUNE TOWER PLACE CANDIDATE, FLAGGED NOT CREATED

`check-place-candidates.py` reports the pin **142 m** from the Atlas tour *The Wrigley Building &
Tribune Tower* (NEAR, never auto-created). Its tags were matched to that tour's exactly —
`Notable Building, Architecture, Gothic, Iconic Landmark`, **and no architect tag, because the
tour carries none either**.

---

## 🔴 FOUND WHILE VERIFYING, NOT PART OF THIS BATCH: the four pulled pins are still live

The owner asked on 2026-08-28 to pull *Empire Theatre*, *The Brooklyn Bridge Caissons*, *The
Octagon* and the creator `@nycunfilteredstories` (which took *Verrazzano-Narrows Bridge* with it).
PR #634 removed them from `Tours.json` and #635 committed
**`backend/pull_nycunfilteredstories.sql`** to remove them from Postgres.

**Diffing the live RPC against the catalogue file today shows all four pins and both creator rows
still being served.** That file has evidently never been pasted into the SQL Editor — and
`seed_from_toursjson.py` is upsert-only by design, so nothing else can remove them. **The app
reads Supabase first, so the four pins are on every phone right now.** The fix is the owner
pasting that one file into the Supabase SQL Editor; it is idempotent and its own header says so.

**⚠️ The diff that shows this is easy to get wrong, and I got it wrong first.**
`Tours.json` stores some UUIDs **uppercase** and Postgres returns them **lowercase**, so a naive
id comparison reports **173 pins missing and 133 makers missing** — the session-99 false alarm,
repeated exactly. **Compare ids case-insensitively.** The other twelve extra maker rows are
ordinary accounts (every signup auto-creates one) and the one extra tour is `Zxxx`, the known
test tour.

---

## Verification

- **`swift scripts/validate-tours.swift` itself** — a Mac session, so the authoritative validator
  rather than a Python mirror. **0 errors, 2 warnings across 1,552 tours + 169 pins**, and
  **both warnings are pre-existing**: the same binary against `main` with this branch stashed
  reports the identical pair (VIA 57 West's transcript gap; Bedrock Caverns' deliberate null
  `walkingDistanceMeters`). No pin of mine warns, so every one carries a Place type and a Theme.
- `make-link-pin.py --selftest` **71/71** with Pillow installed (62/62 without it is a false pass).
- **0** duplicate pin/stop/maker ids, **0** already-pinned sourceURLs, **0** filename collisions
  against all **5,939** gh-pages `images/` paths.
- **0 byte-duplicate heroes**; one perceptual nomination, which is the real Zacherlhaus pair above.
- `Tours.json` confirmed **byte-stable under a Python re-dump at `indent=2`** before editing.
- gh-pages: `git ls-remote` re-checked **in the same command as the push**; tree diff **exactly
  19 additions, 0 deletions, nothing outside `images/`**; deploy read **`in_progress`, not
  `cancelled`**, then **all 19 URLs hash-verified against the uploaded bytes**, not merely 200.
- **Live after merge, verified against the sources rather than the workflow's success line:**
  the Supabase RPC serves all 18 distinct new titles and both `@about_buildings` maker rows, with
  `places` still 37 and `priceTier` still on all 1,553 with 66 priced; the gh-pages mirror
  converged to 169 pins / 154 makers about eight minutes later.
- CI green on the PR (validator + iOS simulator build + unit tests).

---

## Owed / open

1. ~~The owner pastes the pull SQL~~ — **✅ DONE 2026-08-29.** `backend/pull_pins_260829.sql`
   was applied and the live RPC re-read afterwards: `linkPins` **168**, all five pins and both
   creator rows gone, the six kept pins intact, `places` still 37 and 66 tours still priced.
   **Nothing is owed here.**
2. **The Zacherlhaus pair** — keep both, or say which to pull.
3. ~~The Royal Hospital Chelsea hero~~ — **✅ CLOSED 2026-08-29.** Owner: *"keep chelsea, i'm
   fine with it"*. The pin stays with its talking-head thumbnail. **⚠️ A future open-every-hero
   audit will flag it again; it is settled** (the Ministry of Enterprise precedent).
4. **Carlo Scarpa and Jože Plečnik** for `Models/Tag.swift`, whenever an architect PR next runs.
5. **`check-image-duplicates.py` still cannot scope to a link-pin batch** (`--maker <CODE>` or
   `--all`; a pin batch has no maker code) — **sixth batch running**. Covered here by running the
   same two-stage check by hand. A `--since <ref>` or `--pins` flag remains the obvious fix.


---

## Owner pulled the Instagram Zacherlhaus (same day, after #638 merged)

Owner, shown the flagged pair: *"pull the instagram zacherlhaus one"*.

Removed: **`Zacherlhaus` (Instagram @about_buildings)**, `488AFBA8-…`, sourceURL
`https://www.instagram.com/reel/DNYqAvOMDt7/`. **linkPins 169 → 168.** The TikTok
post of the same building stays, so the subject keeps a pin.

- **⚠️ The creator row STAYS**, unlike the `@theironwil` case. `Instagram
  @about_buildings` still carries six pins (St Alban the Martyr, Blenheim Palace,
  Orford Ness, the Royal Hospital Chelsea stable block, the Florence Charterhouse,
  Assisi), and `tours.maker_id` is `ON DELETE RESTRICT`, so deleting it would fail
  anyway. The SQL asserts the survivor count rather than assuming it.
- **`images/zacherlhaus-reel-aboutbuildings_hero.webp` is LEFT ORPHANED on
  gh-pages**, matching what the 2026-08-28 pull did with its four heroes (all four
  are still there). Nothing references it.
- **`backend/pull_pins_260829.sql` is a SUPERSET of `pull_nycunfilteredstories.sql`**
  and repeats its deletions, because the live RPC still served all four of those
  pins and both creator rows on 2026-08-29 — eight days after they left
  `Tours.json`. **One paste now closes everything outstanding**; running the older
  file as well is harmless, since both are idempotent.
- `check-place-candidates.py` drops back to its single pre-existing EXACT group
  (the Barcelona deferral). Validator still 0 errors, 2 warnings, both pre-existing.


### ✅ The SQL was applied the same day, and verified against the RPC

`backend/pull_pins_260829.sql` ran clean. **Read back from the live catalogue rather than from
the success message:** `linkPins` **168** · all five pins gone · `Instagram @nycunfilteredstories`
and `Instagram @theironwil` gone · `Instagram @about_buildings` kept with exactly its six
remaining pins · `TikTok @about_buildings` keeping thirteen, the Zacherlhaus among them ·
`places` still 37 and `priceTier` still on all 1,553 with 66 priced, so the delete severed
nothing.

**🔴 The eight-day gap is the thing to carry forward, not the fix.** #634 removed four pins from
`Tours.json` on 2026-08-28 and #635 committed the SQL to remove them from Postgres — and the SQL
was never pasted, so the app, which reads Supabase first, went on serving all four. **A pull is
not done when the content PR merges.** The check that catches it is a case-insensitive id diff of
the live RPC against the catalogue file, and it costs one query.


### ✅ Both flagged heroes settled the same day

Owner on the Zacherlhaus pair: *"pull the instagram zacherlhaus one"*. Owner on the weakest hero
in the batch: **_"keep chelsea, i'm fine with it"_**.

So of the two things put to them, one pin came out and one stayed. **The Chelsea decision is the
one to record loudly**, because the evidence that flagged it — a thumbnail showing a person rather
than a place — is exactly what a future hero audit re-derives from scratch. It is closed, and the
Ministry of Enterprise / Casa Lleó Morera precedent applies: honour the decision rather than
"fixing" it.
