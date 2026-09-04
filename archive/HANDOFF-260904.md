# HANDOFF 2026-09-04 (session 142, follow-up) — Barcelona Pavilion place + 36 architects

Branch `claude/new-tour-links-cytwc6`, **restarted clean off the merged `main` (`5763c137`)** —
its previous PR (#730) had merged, and a merged PR is finished. Owner instruction, verbatim:
**"ADD THE ARCHITECTS AND MAKE BARCELONA PAVILION A PLACE"**.

⚠️ **This is a CODE change** (`Models/Tag.swift` + `scripts/validate-tours.swift`), unlike the batch
before it. It wants a simulator look; CI is the compile check.

## First: #730 went live, and it was verified against the systems

The Supabase RPC — the source the app reads **first** — serves **1,151 linkPins / 114 places**, with
**0 pins wrongly inside `tours`**. The gh-pages mirror lagged at 1,047 for several minutes, which is
the documented CDN lag; the publish job's own verify step had already confirmed the committed blob.

⚠️ **The RPC returned HTTP 500 `57014 canceling statement due to statement timeout` on a cold call
and 200 on retry.** The payload is ~10 MB and a cold query can exceed the statement timeout. That is
the transient class `RemoteCatalogLoader`'s retry-with-backoff exists for — **do not read one 500 as
a broken deploy.**

## Barcelona Pavilion: 2 → 5 members, nothing moved

Its place held 2 members while three more pins sat on the same point — **one capsule plus three loose
pins against `TourSetMap.maxStacked = 3`**, past the cap, which puts a marker permanently out of
reach on a shared list.

All three were **already exactly on the place's coordinate**, so the identity rule held on its own
and nothing was relocated. Diff **4 insertions / 1 deletion**; `tours`, `makers`, `linkPins` and the
other 113 places byte-identical. All three **asserted `manual` before anything was written**, so no
geofence is disturbed, and every member is asserted to sit on the place's exact coordinate afterwards.

⚠️ **Swept 400 m rather than trusting the checker's group** (the session-131 lesson). The only other
marker in range is **MNAC at 372.9 m**, correctly excluded — a separate museum on the same hill, the
Great Ball Court rule.

🎉 `check-place-candidates.py` **12 EXACT → 11, NEAR unchanged at 50**, and diffing the two reports
proves it fell by **exactly the group resolved and gained nothing**.

## 36 architects: 383 → 419

**50 entries gained 58 tags.** The 36 names are listed in the commit; `Lund Hagem` is the one only
the sweep surfaced.

### The sweep is the valuable part — 9 real hits, 4 false positives

**False, and each would have shipped silently:**
- `Ellwood` ×3 → Toronto's **Trinity Bellwoods** park.
- `Elwood` → a **Melbourne suburb** (a Lune Croissanterie caption).
- `Vicens` → **Manel Vicens, the currency broker who commissioned Casa Vicens** — the client, and a
  different person from the Madrid practice Vicens + Ramos.
- **`Rudolph Schindler` at Hollyhock House** — the Sullivan rule at its most tempting: the caption
  calls it *"the job that brought Rudolph Schindler to LA"*, but that house is Wright's.

**Real, each stating authorship in its own text:** Gordon Bunshaft at Lever House · Kevin Roche +
John Dinkeloo at the Ford Foundation **twice** (an Atlas tour and a link pin) · Tod Williams + Billie
Tsien at the Obama Presidential Center · Coldefy & Associés at the older HKDI pin · George Wyman at
the Bradbury Building **and the Downtown LA walk that contains it** (the MVRDV / Álvaro Siza walk
precedent) · Greene & Greene at the Gamble House · Junya Ishigami at KAIT Plaza · Sachio Otani at the
Kyoto centre · Atelier Oslo at the older Deichman pin, **which also names `Lund Hagem`**.

### Four deliberate omissions a future session will want to "finish"

- **`Pierre Jeanneret` is NOT tagged on `Maison Pierre Jeanneret`** — the caption says the house was
  designed *for* him, so he is the client there. Session 141 had already left Le Corbusier off it for
  the mirror-image reason.
- **The Obama Presidential Center LINK PIN is NOT tagged** although the Atlas tour of the same
  building is. Its caption reads only *"Chicago needed more sculptural architecture like this"* and
  names nobody. **Tag what each entry's own source says.**
- **`Sumner Hunt` is tagged on the batch pin and NOT on the Atlas Bradbury tour** — that tour's own
  text says Hunt's design was **rejected** before Wyman got the job.
- **`Frank Lloyd Wright` is NOT tagged on the Unitarian Meeting House extension** — the subject is
  Kubala Washatko's addition; Wright's building is the enclosed earlier one (the Kolumba / Böhm
  precedent). ⚠️ **`Mortensrud Church` gains no architect at all**; its caption names none.

### Practice vs person — one rule, applied consistently

**Tag what the caption presents as the author.** A person named *"of"* a practice ships as the person
(**`Gordon Bunshaft`** of SOM, **`Ruben Payumo`** of Alfredo Luz and Associates); a caption naming
only a practice ships as the practice (`Austin Maynard Architects`, `Atelier Oslo`, `Hodgetts + Fung`,
`Department of Architecture Co`, `Slow Architects`, `Greene & Greene`, `Vicens + Ramos`).

⚠️ **The project has previously REJECTED `Foster + Partners` as a duplicate of `Norman Foster`**, so
this convention is not uniform; these are the entries to revisit if it is ever normalised.
⚠️ **`CAAU` ships as `Coldefy & Associés`** — an expansion of the creator's abbreviation, corroborated
by the older HKDI pin naming the firm in full. ⚠️ **The creator misspells `Craig Elwood`**; the
caption stays verbatim and the tag uses the published `Craig Ellwood` (the Schweizer convention).

## Verification

- Both vocabularies **parsed out of the Swift rather than retyped** and asserted **identical at 419
  names, 0 duplicates on either side**; brace/bracket/paren balance checked on both files with string
  literals stripped.
- Near-duplicates checked on **normalised token sets** (folding accents, stripping
  `Architects`/`Studio`/`Associates`/`Partners`/`+`/`&`) — **0 collisions, 0 exact matches.**
- **`Designed by a Master` kept on every tagged entry**, and two that gained a name had never carried
  it. Catalogue-wide after: **693 named-architect entries, 0 missing the shelf tag, 0 of 419 names
  unused.**
- Mirror **self-tested 22/22 with a clean control**, then **0 errors, 0 warnings across 1,552 tours +
  1,151 pins + 114 places** at **469 tags across 5 facets**.
- **18 faults injected against the CHANGED entries — 17 caught, control clean before and after.**
- `Tours.json` **byte-stable under a Python re-dump before AND after editing**;
  `seed_from_toursjson.py` clean at **305 / 2,703 / 3,075 / 114**; **0 `images//`** in the catalogue
  *or* the SQL.
- ⚠️ **Nothing compiled locally** — CI is the only compile check a Linux web session gets.

## 🔴 The fault harness lied twice, and both are worth carrying

1. **The first run reported 18/18 and it was a FALSE PASS.** `check()` returns an
   **`(errors, warnings)` tuple, not an exit code**, so `rc not in (0, None)` was true for *every*
   run — including the clean control. **The control reading DIRTY is the only thing that exposed it.**
   Always assert the control is clean *before* trusting a catch count.
2. **Two further "misses" were the session-141 harness bug repeating** — "no Place type" and "no
   Theme" are **warnings**, and the harness counted only errors.
3. **The last miss was a rule I invented.** The validator's URL check explicitly accepts
   `("http://", "https://")`, so a non-https hero is not a fault at all — the mirror-inventing-a-rule
   class from session 138, caught on myself. Asserted directly on the 50 touched entries instead.

## What is still open

- **Eleven EXACT coincident groups remain**, all inside the stack cap: ParkLife ×3, Yumebutai ×3,
  Equilateral House ×3, M+ ×3, Kyūkyodō ×2, Unitarian Meeting House ×2, ArtCenter ×2, plus
  Nishisando / HKDI / Tai Kwun / Serlachius forming with live content. None is urgent; none is
  manufactured.
- **The weak heroes are CLOSED** (owner, *"Don't worry about the heroes"*) — do not re-raise them.
