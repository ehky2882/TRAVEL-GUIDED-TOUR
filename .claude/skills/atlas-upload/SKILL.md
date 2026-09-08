---
name: atlas-upload
description: Add content to the Atlas/Dozent catalog — link pins (creator TikTok/Instagram/YouTube posts pinned to a map location), city audio drops, tour images, and staged tour scripts. Use whenever someone asks to add, upload, pin, or wire in tours, links, creators, audio, or photos for this repo. Written for a non-technical contributor: run the commands yourself, explain in plain English, never show raw JSON.
---

# Adding content to the Atlas catalog

## Who you are talking to

Assume the person is **not a developer**. They do not use a terminal, do not
read JSON, and did not write this codebase. They may be Edward's partner,
newly onboarded.

- **You run every command.** Never hand them a command to type.
- **Explain in plain English**, in one or two sentences, before and after each
  step. "I'm adding these 12 links to the catalog" — not "merging pins into the
  `linkPins` array via uuid5 keys".
- **Never print JSON, catalog entries, or file contents at them.** Summarise:
  "12 pins added, 12 heroes cropped, validator clean."
- **When something is ambiguous, ask them** — one plain question with options.
  Do not guess at catalog shape.
- **When something needs Edward** (the owner), say so plainly and stop that
  thread. Anything touching `*.swift`, the Xcode project, or app behaviour is
  his call, not theirs.

## Before anything else, every session

```bash
bash scripts/session-start.sh
```

It takes a couple of minutes. It prints live state — the branch, what other
sessions have in flight, whether the site and catalog are up. **Never quote
project docs for anything that can change without a commit** (what's merged,
what's live, App Store status). If you could not check something, say you could
not check it. This rule has cost the owner real trust; see `CLAUDE.md`
§ READ FIRST.

Then read the newest `archive/HANDOFF-*.md` the script names.

## How work ships

Always: **new branch → commit → open a PR → CI green → merge.** Never push to
`main` directly.

| Kind of change | Merges how |
|---|---|
| `Resources/Tours.json`, docs, `scripts/`, images and audio on `gh-pages` | Auto-merge once CI is green — no approval needed |
| Anything in `*.swift`, `*.xcodeproj`, `Assets.xcassets/`, `Info.plist` | **Stop.** Owner reviews on a simulator or TestFlight first |

A content contributor should essentially never be in the second row. If a task
drifts there, say so and hand it to Edward.

---

# Job 1 — Link pins (the usual job)

A **link pin** is someone else's public post (TikTok / Instagram / YouTube)
pinned to a map location. It shows up everywhere a tour does; tapping it opens
the platform. Nothing is downloaded but the thumbnail.

**Read `docs/link-pin-runbook.md` before a batch.** It is the source of truth;
this section is the short form.

## What to collect from the person

One line per pin. Only the URL is strictly required, but a pin with no
coordinate is the one defect nothing downstream catches — it validates, it
uploads, and it sits in the ocean off West Africa. Ask for locations.

```
<url> | <lat>,<lon> | <city> | <country>
```

If they give you a place name instead of coordinates, look the coordinates up
and **read the result back to them for confirmation** before minting.
If they paste a Plus Code, `scripts/decode-plus-code.py` converts it.

## The flow

```bash
# 1. Write the batch to a FILE (never into the conversation)
cat > /tmp/links.txt <<'EOF'
https://www.instagram.com/reel/XXXX/ | 41.3803,2.0678 | Sant Just Desvern | Spain
EOF

# 2. Mint the pins — redirect to a file, see the token rule below
python3 scripts/make-link-pin.py --batch /tmp/links.txt \
    --out-dir /tmp/heroes --category architecture \
    --tags "Notable Building,Architecture" > /tmp/pins.json

# 3. Merge, disk to disk  (--check first reports without writing)
python3 scripts/merge-link-pins.py /tmp/pins.json

# 4. Prove it
python3 scripts/validate-tours-mirror.py      # swift scripts/validate-tours.swift on a Mac
python3 scripts/check-image-duplicates.py --pins

# 5. Upload the heroes in ONE commit
python3 scripts/upload-images.py --dir /tmp/heroes --message "Heroes for <creator> pins" --verify
```

Then commit `Tours.json` on a branch, open the PR, let CI go green, merge.

## The five things that bite

1. **🔴 Keep the JSON out of the chat.** `make-link-pin.py` prints ~1.9 KB per
   pin to stdout, and a conversation re-sends its whole history every turn — a
   batch of 20 pasted into chat costs ~21,000 tokens *on every later turn*.
   Always redirect to a file and merge from the file. Print a pin only when you
   mean to read one.
2. **🔴 Pins go in `linkPins`, never in `tours`.** A `kind: "link"` entry inside
   `tours` fails the whole catalog decode on every build shipped before
   `TourKind.link` — silently. The phone stops receiving *all* new content and
   logs nothing. `merge-link-pins.py` refuses it; `scripts/split-link-pins.py`
   repairs a catalog where pins leaked in (a content branch cut before the split
   reintroduces them on every merge).
3. **Hero filenames carry the creator's handle** —
   `<subject-up-to-6-words>-<handle>_hero.webp`, 1200×900. Without the suffix a
   pin's filename collides with the Atlas *tour* of the same subject and
   overwrites its hero.
4. **🔴 Correcting an image means a NEW filename** (`..._hero-2.webp`) plus a
   `Tours.json` repoint. Never overwrite bytes at a live URL: a phone that has
   downloaded a tour reads photographs off its own disk and would keep the wrong
   one forever. A new filename is a new address, so every phone re-fetches.
5. **`check-image-duplicates.py --pins` for pins, `--maker <CODE>` for a city.**
   Not interchangeable — a creator handle collides with city codes as a
   substring (`STO` matches `@urbanstoriesyt`).

Also worth knowing: Instagram withholds the media file for reels using licensed
music. Those pins are fine but open Instagram instead of playing inline — the
tool *reports* it (`PIN(S) WILL NOT PLAY INLINE` in stderr), never refuses.
Mention it to the person; it is the owner's call.

Two pins from one post: the id key takes a fragment — `#<slug(subject)>` when
the pins share a city, `#<slug(city)>` when they don't. Runbook § One post,
several pins.

---

# Job 2 — A city audio drop

A folder (usually Dropbox/WeTransfer) with MP3s + scripts + images for a city.

**🔴 Before wiring anything, check the coordinates:**

```bash
python3 scripts/check-coordinates.py --drop "<folder>" --city "<City>, <Country>"
```

A wrong coordinate is invisible to every other check — the validator passes, CI
compiles, every URL returns 200, and the tour simply never fires. It has shipped
twice from the same upstream pipeline, always displaced north. Fix every GROSS
before wiring, read every UNVERIFIABLE by hand, and **read the BIAS line**: if
the northward offset is gone, upstream is fixed; if it's still ~+10 m it is not,
however clean the gross list looks.

Then: `docs/authoring-tours.md` for the field-by-field data model, and
`drafts/<city>-*/README.md` for the wire-in spec if the city was staged.
After merging, add a row to `drafts/AUDIO-PENDING-SURVEY.md` **on `origin/main`**
and run `swift scripts/validate-tours.swift`.

This is a bigger job than link pins. Walk the person through it slowly, and
check in with Edward before the first one.

---

# Job 3 — Images for a tour

Full process in `CLAUDE.md` § Image Pipeline. The short version:

- Sources in order: Openverse (`license=cc0,pdm`) → Wikimedia Commons direct →
  Unsplash. **Public-domain only** — the app has no attribution UI.
- **Verify with two separate Gemini calls, never one combined question.**
  Gate A: is this a modern colour photograph (not an engraving or book scan)?
  Gate B: is this the required subject, with the look-alikes named explicitly?
  A single compound prompt gets answered on subject match only, and once shipped
  a set of 19th-century prints to the owner as "photos".
- Present candidates as **individual full-size images with a number burned in**,
  sent inline — never a small contact-sheet grid. The owner picks by number.
- Finish with `python3 scripts/check-image-duplicates.py --maker <CODE>`.

---

# Job 4 — Writing tour scripts

Use the `atlas-audio-tour` skill if it is available in the session. Scripts stage
on a branch under `drafts/<city>-batch1/`; only the README pick-map goes to
`main`. Add the row to `drafts/AUDIO-PENDING-SURVEY.md` on `main` as soon as the
batch is staged, not at the end of the city.

---

# Reading a check's result

**A check that cannot run must not be able to return a pass.** Three ways that
has already happened here:

- **The stale output file.** Every script in `scripts/` prints
  `RUN <name> · rev <hash> · <UTC time>` first. **Confirm that stamp is from
  this run before believing anything under it.** Prefer a checker's own
  `--out PATH` over shell redirection. A stamped file with no verdict under it
  is a run that *died*, not a run that passed.
- **`PIPESTATUS`.** `$?` after a pipe is the *last* command's status. Read exit
  codes directly, or use `${PIPESTATUS[0]}`.
- **The checker that fetched nothing.** `check-image-duplicates.py` once printed
  "OK — no suspicious duplicates" having failed every fetch with an SSL error. A
  checker that cannot reach the network exits 2 — COULD NOT VERIFY. Read the
  counts it prints, not only the verdict: 161 images reported where 173 were
  uploaded is a finding.

# After a content merge

`get_catalog` (Supabase) is the app's primary source; the gh-pages
`Tours.json` mirror is a fallback. A merge to `main` republishes the mirror
automatically, **but the database needs `backend/seed_from_toursjson.py`** or
the mirror ends up newer than the live source. If you hand-edit catalog data in
the Supabase SQL Editor, finish with `select public.refresh_catalog_snapshot();`.

# At the end of a session

Write `archive/HANDOFF-YYMMDD.md`, add a **one-line** row to
`archive/README.md`, and update `STATUS.md` if anything is in flight.
**Do not append a session narrative to `CLAUDE.md`** — that is what grew it to
1.5 MB. A durable *rule* change is edited into `CLAUDE.md` in place; a durable
*lesson* goes in `docs/lessons.md`; everything else is the handoff's job.
