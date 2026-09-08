# Link-pin runbook

How a batch of creator links becomes catalog entries. Read this instead of
re-deriving it — the ID scheme alone has been reverse-engineered from the live
catalogue at least twice (sessions 145 and 148).

A **link pin** stands for someone else's public post (TikTok / Instagram /
YouTube). It appears everywhere a tour appears — map, rails, search, library —
and its detail page opens the platform instead of playing anything. Nothing is
downloaded but the thumbnail, and only because platform thumbnail URLs are
signed and expire.

---

## The whole flow

```bash
# 1. One line per pin:  <url> | <lat>,<lon> | <city> | <country>
#    Everything after the URL is optional; # and blank lines are notes.
cat > /tmp/links.txt <<'EOF'
https://www.instagram.com/reel/XXXX/ | 41.3803,2.0678 | Sant Just Desvern | Spain
EOF

# 2. Mint the pins. Redirect to a FILE — see § Keep the JSON out of the chat.
python3 scripts/make-link-pin.py --batch /tmp/links.txt \
    --out-dir /tmp/heroes --category architecture \
    --tags "Notable Building,Architecture" > /tmp/pins.json

# 3. Merge, disk to disk.
python3 scripts/merge-link-pins.py /tmp/pins.json

# 4. Prove it.
swift scripts/validate-tours.swift          # or validate-tours-mirror.py off-Mac
python3 scripts/check-image-duplicates.py --pins

# 5. Upload the heroes in /tmp/heroes to gh-pages under images/, then commit.
```

`--check` on step 3 reports what would change and writes nothing.

---

## 🔴 Keep the JSON out of the chat

`make-link-pin.py` prints entries to stdout. Letting a **batch** land in the
conversation costs about **1.9 KB per pin**, twice — once printed, once pasted
back to write it — and a conversation re-sends its whole history on every
request, so that block is paid again on every later turn. A batch of 20 is
~21,000 tokens the first time and again on each turn after.

Redirect to a file and merge from the file. The session sees six lines.

Print a pin to the chat only when you mean to read one — a single `--url` run,
or `python3 -c` pulling one field.

---

## 🔴 Pins go in `linkPins`, never in `tours`

A `kind: "link"` entry inside `tours` fails the **whole** catalog decode on
every build shipped before `TourKind.link`. `ToursData` decodes `tours` as one
array, the enum is closed, and `RemoteCatalogLoader` wraps the decode in
`try?` — so the throw becomes a nil, the loader reads that as a failed fetch,
keeps its last good copy, and logs nothing. No crash: the phone silently stops
receiving *all* new content. An unknown top-level *key* costs those builds
nothing, which is why the pins move rather than the enum widening.

`merge-link-pins.py` refuses a pins file carrying a `tours` array, and
`scripts/split-link-pins.py` repairs a catalog where pins leaked in — which a
content branch cut before the split reintroduces on every merge:

```bash
git checkout --theirs "TRAVEL GUIDED TOUR/Resources/Tours.json"
python3 scripts/split-link-pins.py
```

---

## The ID scheme

Deterministic `uuid5` over `NAMESPACE_URL`, uppercased. Re-running on the same
post yields the same entry instead of a duplicate.

| Row | Key hashed |
|---|---|
| pin | `atlas-tour:link:<sourceURL>` |
| its stop | `atlas-stop:link:<sourceURL>` |
| creator | `atlas-maker:<platform>:@<lowercased handle>` |

Verified against the live catalogue on 2026-09-08 — all three reproduce the
newest pin exactly. Re-prove it in one command rather than trusting this page:

```bash
python3 -c "
import uuid
u='https://www.instagram.com/reel/DFxyNa9xMSm/'
print(str(uuid.uuid5(uuid.NAMESPACE_URL,f'atlas-tour:link:{u}')).upper()=='6192A9EC-C601-5145-A600-5F7E8FF6940E')
print(str(uuid.uuid5(uuid.NAMESPACE_URL,f'atlas-stop:link:{u}')).upper()=='3C196CA4-53B3-5148-89F5-7089953B2501')
print(str(uuid.uuid5(uuid.NAMESPACE_URL,'atlas-maker:instagram:@rayisaplace')).upper()=='33756F34-2AC5-52F9-BDA6-6F525A06F056')"
```

Because the id is keyed on the URL, **URL normalisation is identity**. The tool
keeps only the parameters that identify a post — a whitelist, because the first
version blacklisted tracking parameters and immediately missed one, so the same
post shared twice hashed to two ids and landed as two pins. Across all three
platforms exactly one query parameter is ever identity: YouTube's `v`.

### One post, several pins

Three live posts carry more than one pin (10 pins in all) — a video naming
several places, each of which deserves its own map location. Those ids add a
**fragment to the hashed key**, and the fragment is the pin's **city, slugified**:

| Row | Key hashed |
|---|---|
| pin | `atlas-tour:link:<sourceURL>#<slug(city)>` |
| its stop | `atlas-stop:link:<sourceURL>#<slug(city)>` |

⚠️ **The fragment lives only in the key. `sourceURL` is stored clean** — no live
pin has a `#` in the stored field. Grepping `sourceURL` for `#` therefore finds
nothing and looks like proof the scheme does not exist. It is not; check the
ids instead, which is what `groups` of a shared `sourceURL` are for.

Reproduced against the live catalogue on 2026-09-08:

- **1333 / 1333** single-URL pins reproduce from the bare key. Exact.
- **7 / 10** shared-URL pins reproduce from the `#<slug(city)>` key, on the tour
  id *and* the stop id.

🔴 **The remaining 3 are a known gap, not noise.** Two of them (`DA_8t0NPsi8`,
the Charging Bull pair) are **both in New York** — city cannot disambiguate two
pins in the same city, so their ids follow no reproducible rule and were minted
ad hoc. The third (a Milan antiques-market pin) reproduces from nothing either,
most likely minted before its `city` was edited. **If a batch needs two pins from
one post in one city, there is no convention yet — pick one, write it here, and
say so in the PR.** Do not assume the ad-hoc ids encode a rule.

### ✅ The same-city convention, chosen 2026-09-08 (session 149)

A batch of 83 `@urbanistariel` links hit this gap: one post about the Edinburgh
places that inspired Harry Potter carried **two** Plus Codes, both in Edinburgh.
The convention taken, and the one to follow from now on:

| Row | Key hashed |
|---|---|
| pin | `atlas-tour:link:<sourceURL>#<slug(subject)>` |
| its stop | `atlas-stop:link:<sourceURL>#<slug(subject)>` |

where `slug(subject)` is the **venue**, not the city — `elephant-house` and
`george-heriots-school`. City stays the rule when the cities differ; the subject
slug is the tie-break when they do not, so **the city rule is a special case of
naming whatever distinguishes the pins**.

⚠️ This does **not** retro-fit the two ad-hoc Charging Bull ids. Re-minting them
would change ids that are already live, orphaning anything a phone has saved
against them. They stay as they are; the rule applies to new pins.

⚠️ The pins in such a group **share one hero file**, because one post has one
thumbnail — so a `len(files) == len(pins)` assertion is wrong for that batch.
Name the shared file for what the post is about (`harry-potter-edinburgh-…`),
not for either subject, since it serves both.

---

## Hero filenames

`<subject-up-to-6-words>-<handle>_hero.webp`, 1200×900.

The creator suffix is not decoration. Without it a pin's stem collides with the
Atlas *tour* of the same subject already on gh-pages, and writing it overwrites
that tour's hero. Since #567 a phone that has downloaded a tour reads its
photographs off its own disk and never asks the server again — so the wrong
picture would never be corrected.

**Correcting an image means a new filename** (`..._hero-2.webp`) plus a
`Tours.json` repoint. Never overwrite bytes at a live URL: a new filename is a
new address, so every phone fetches it automatically.

---

## Traps

- **A pin with no coordinate is the one defect nothing downstream catches.** It
  validates, it uploads, and it sits in the Gulf of Guinea. Both tools refuse
  it — `make-link-pin.py` rejects the whole batch, naming the lines.
- **Instagram withholds the media file for reels using licensed music.** Such a
  pin is fine except that tapping the video opens Instagram rather than playing
  inline. It is *reported, never refused* — the owner decides. Look for
  `PIN(S) WILL NOT PLAY INLINE` in the run's stderr.
- **A source title is not always the subject's name.** A channel formatting
  every upload to a house pattern gives you `"BRICK AWARD 26 Winner Category
  … - Dạo Mẫu (Mothergoddess) Museum & Temple, VN"`. Pass `--title` for the
  subject; the platform's own words are kept verbatim in `longDescription`
  either way. ⚠️ `--title` and `--slug` apply only to a single-`--url` run.
- **The maker line and the credit line must name the same person** — that is
  why the tool derives the handle once. Getting it wrong produced
  `sourceAuthor: "Blippi - Educational Videos for Kids"` beside the maker
  `YouTube @Blippi`.
- **`check-image-duplicates.py --maker <CODE>` is tours only, deliberately.** A
  pinned creator's handle collides with city codes as a substring (`STO` matches
  `@urbanstoriesyt`). Use `--pins` for a pin batch, `--all` for both (~7 min).
- **Content must also reach Supabase.** `get_catalog` is primary; the gh-pages
  mirror is a fallback. A merge to `main` republishes the mirror automatically,
  but the DB needs `backend/seed_from_toursjson.py` — otherwise the mirror is
  newer than the live source.

---

## Checking a check

Every script in `scripts/` prints `RUN <name> · rev <hash> · <UTC time>` as its
first line. **Confirm that stamp is from this run before believing anything
under it** — a stale output file once read exactly like a pass. Prefer a
checker's own `--out PATH` over shell redirection, and read exit codes
directly, never through a pipe (`$?` after a pipe is the *last* command's).

`validate-tours-mirror.py` injects 32 known faults into a copy of the catalog on
**every run** and refuses to give a verdict if it fails to catch them all
(`SELFTEST FAILED — verdict not trustworthy`, exit 2). That is the fault
harness; do not write another one. When you find a rule in
`validate-tours.swift` that the mirror does not mirror, add a `case(...)` to its
`selftest()` — sessions 143, 146 and 148 each found one that way.
