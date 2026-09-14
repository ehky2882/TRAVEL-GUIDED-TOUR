# HANDOFF 2026-09-14 — Atlanta launches as the 35th city

**Outcome:** Atlanta is live. 30 single-stop tours under new maker **Atlas Studio ATL**
(`ccaab715-2f29-597e-8b3a-0d38e8d370da` = uuid5 `atlas-maker:atl`), geofenced at 30 m, 30 MP3s
totalling 4,049 s (67m29s). Catalogue **1552 → 1582 tours / 424 → 425 makers / 1924 → 1954
stops**. [PR #900](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/900), squash `18ea33b2`.
**The audio-pending queue is empty again** — Atlanta was the last staged city.

Earlier in the same session, [PR #889](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/889)
corrected the tracker's Atlanta row, which still said "21 of 30 image-complete" three weeks after
the images were finished.

---

## 🔴 The finding: eleven coordinates were wrong

At the 30 m geofence **not one of these tours would ever have fired** — no error, no dead link,
just silence in front of the building.

| tour | off by | the supplied point sat on |
|---|---:|---|
| The Temple | 719 m | 16th Street NE |
| APEX Museum | 566 m | a building on Hilliard Street |
| Jackson Street Bridge | 512 m | Howard Middle School |
| The Flatiron | 431 m | a tobacco shop on Gilmer Street |
| Student Movement Blvd | 358 m | a house on Mildred Street |
| Historic Fourth Ward Park | 202 m | the Iris O4W apartments |
| Zero Mile Post | 195 m | a car park on Lower Wall Street |
| Candler Building | 147 m | the British Consulate |
| MLK Birth Home | 142 m | the Legacy Nursing Center |
| Woodruff Park | 119 m | bicycle parking on Gilmer Street |
| Oakland Cemetery | 62 m | a Boulevard SE street centroid |

**These were NOT the upstream drop-pipeline fault.** The Atlanta scripts carry a prose
`Position:` line and no coordinates at all, so the batch README's coordinates were *derived by a
session* — and eleven of the thirty were derived wrong. ✅ **The systematic northward bias is
statistically absent**: 12/22 north, median +9.1 m, p = 0.83, indistinguishable from the
hand-sourced NYC/London baseline (Barcelona + Milan were 41/50 north at p = 5.6e-06). The errors
scatter in direction, which is the signature of transcription rather than the pipeline.

**Lesson for any city whose scripts carry prose positions rather than coordinates: the
coordinates are authored, so they need the same audit as a supplied drop — arguably more.**

---

## Two checks returned a non-answer first, and neither was read as a pass

1. **`check-coordinates.py` exited 2 — COULD NOT VERIFY**, 29 of 82 Nominatim calls failing at
   its built-in `SLEEP = 1.1` through the session proxy. Re-running at **2.6 s** produced the
   real result above. **Raise `SLEEP` when running it from a web session.**
2. **The Python validator's first real run reported 206 errors that were all its own fault** — a
   lowercase-only UUID pattern rejecting 103 pre-existing *uppercase* ids that Swift's `UUID`
   type parses happily. Zero of the 206 were Atlanta's. Fixed to `[0-9a-fA-F]`.

The validator was **self-tested against 18 injected fault classes and caught 18/18 before being
believed**. CI's authoritative Swift `Validate Tours.json` later agreed: 0 errors.

---

## Audio delivery

**Ask for a `/scl/fo/` shared-folder link, never a Dropbox Transfer (`/t/…`).** The owner first
sent a Transfer link. Unlike the shared-folder form it has **no direct-download URL** — the bytes
come out only through a JavaScript flow — and **Chromium cannot reach Dropbox through this
session's egress proxy at all** (immediate `ERR_CONNECTION_RESET`, tried three ways including
blocking every third-party request). `curl` reads the landing page fine but the page is fully
client-rendered. The files arrived instead as 30 direct uploads, which worked.

**Encoding: 128 kbps mono at 48 kHz**, not the documented 44.1. Shipped as delivered rather than
re-encoded — a lossy-to-lossy pass costs quality for no functional gain, and the catalogue
already serves several 128/48000/mono files (UN HQ, Strand, Expo 98). ⚠️ Worth knowing the
catalogue is **not** uniform: a sample of eight live files found 128/44.1, 128/48 **and 320 kbps
stereo**. Do not treat an existing file as evidence of the standard.

Two delivered filenames carried typos that never reached the catalogue, since files are renamed
to their slugs: `OAKLAND_CEMETARY`, and `GEORGIA_CAPITAL` for the Capitol.

---

## Transcripts: three header formats, one file

Confirmed by parsing, not by trusting the README: **A** — 8 scripts with a `---` rule
(01,02,03,04,09,22,23,24); **B** — 17 with **no header at all**, body text from line 1;
**C** — 5 with a three-line `ATLANTA — STOP NN` header and **no rule** (14,15,28,29,30).
Extracted per format; beat markers stripped in both bare `[beat]` and asterisked `*[beat]*` forms.

---

## 🔴 Still unresolved — owner decision

**Stop 02's narration contradicts its own photographs.** The script describes a *replica* with the
original Zero Mile Post eight miles north. Every image shows **the original, indoors at the
Atlanta History Center**, where it moved in 2019. The shipped coordinate is the downtown Georgia
Railroad Freight Depot site, which keeps the walk coherent with the other 29 stops. **Only the
owner can settle which the script should say.**

## 🔴 Do not "correct" the APEX hero

`apex-auburn_hero.webp` carries a **WELCOME / INMAN PARK** banner in frame while the APEX Museum
is on Auburn Avenue ~1.5 km west, so it reads as the wrong neighbourhood on sight. It was queried
on exactly that basis and **the owner confirmed it is correct**.

## Two artwork rights ship OPEN, not cleared

Krog Street Tunnel's graffiti and Woodruff Park's *Atlanta from the Ashes* (1969), both
owner-directed — `drafts/CREDITS.md`. **There is no photograph of Woodruff Park without the
phoenix**: ten files across two sourcing passes, and every one showing the park contains the
sculpture, because it is the physical centre of the park.

---

## The Supabase step is automatic — I said otherwise and was wrong

I told the owner that `backend/seed_from_toursjson.py` had to be re-run by hand or Atlanta would
not appear in the app. **That is false.** `publish-catalog.yml` carries a **`seed-supabase` job**
that runs on every `Tours.json` change to `main`; it is opt-in on the `SUPABASE_DB_URL` repo
secret, and that secret is set. The owner challenged the claim and was right.

I produced it by quoting a line in `CLAUDE.md` instead of reading the workflow — the exact failure
mode that file's own opening section exists to prevent, and the **second** time in this session a
`CLAUDE.md` line proved less current than the system it describes. **Read the workflow.**

---

## gh-pages: batch pushes, and check your own SHA reached `success`

Recorded on 2026-08-27 and confirmed again today. **Pages cancels a queued build whenever a newer
commit lands**, and this repo has many parallel sessions plus an auto-publish workflow, so
competing pushes are normal. Today the audio push (`cda799f0`) was cancelled by two catalog
publishes and took ~25 minutes to serve.

**A cancelled build and slow propagation are indistinguishable from outside — both are a 404.**
Check that the Pages run for *your* `head_sha` reached `success`; a cancelled run needs no
re-push, since gh-pages deploys the whole tree and any later build carries the files out. Verify
the substantive thing instead: that your files are still in the tree and your commit is an
ancestor of HEAD.

---

## Verification performed

- Audio: 30 files map 1:1 onto the 30 staged slugs, nothing spare or missing; **30 distinct by
  SHA-1**; every slug checked against the live gh-pages tree *and* the catalogue's 1,927 existing
  audio slugs — all new; **all 30 confirmed serving 200** after the deploy.
- Images: **30/30 heroes serving 200**, counted by requesting each slug, not by arithmetic (three
  earlier arithmetic passes gave 20, 21 and 22 for the same state).
- Tags: all 29 Atlanta tags present in `Models/Tag.swift` — no `Designed by a Master` fallback.
- uuid5 scheme reverse-verified against live Chicago/ORD before minting ATL.
- `Tours.json` byte-stable under a Python re-dump before editing; diff **1,350 insertions /
  0 deletions**; no id collisions across 1,582 tours and 1,954 stops.
- CI: all four checks green including the authoritative Swift `Validate Tours.json`.

## Housekeeping note

The shared checkout at `/home/user/TRAVEL-GUIDED-TOUR` sits on
`claude/amsterdam-handoff-preserve-hlhyp8` at a commit **625 behind** that branch's remote, so a
stop hook reports "50 unpushed commits" every turn. Those 50 are already-merged history contained
in `origin/main`; pushing would be rejected, and forcing would destroy 625 commits including the
Atlanta work. **Do not push them.** All of this session's work was done in a separate worktree.
