# Handoff: 2026-09-14 — 33 link pins from a mixed creator batch, and Supabase at 522

## What happened

The owner dropped 40 links ("Random started 9/11"). 39 unique — #14 and #15 were
the same reel pasted twice. **33 became pins**; the other six are itemised below.

Branch `claude/new-tour-links-3th96b`, commit `f71682d`. Heroes on `gh-pages` at
`864ec36`.

| | |
|---|---|
| linkPins | 2043 → **2076** |
| makers | 389 → **414** (25 new creators) |
| cities | 24 represented, **12 countries** |

## 🔴 Supabase is returning 522 — read this first

Measured directly at 01:33 UTC: **Cloudflare 522, origin timed out**, on *both*
`rpc/catalog_snapshot_age` (34 bytes) and a `tours?select=id&limit=1` row count
(**47 bytes**). A 47-byte query cannot time out on cost, so this is the database
not answering, not one expensive statement. `session-start.sh` had reported the
milder **57014 statement timeout** an hour earlier, so it degraded during the
session.

Consequences, both carried as `status/owner/supabase-522.md`:

* **`seed_from_toursjson.py` could not run.** These 33 pins reach the gh-pages
  mirror on merge and **not Postgres**, which is primary. It must be run when the
  DB answers, or the mirror is newer than the live source.
* `merge-link-pins.py` printed `⚠️ COULD NOT CHECK` for the 25 new handles
  against existing Dozent accounts. Per the runbook that is **not an all-clear**;
  re-run `--check` once online.

The app is unaffected meanwhile — `RemoteCatalogLoader` falls through to the
mirror — which is precisely why this can go unnoticed.

## Traps hit

- **`check-image-duplicates.py --pins` printed `OK — no suspicious duplicates`
  while 34 images had failed to fetch.** 33 were this batch's own heroes, 404
  because GitHub Pages had not rebuilt yet. The verdict was true of the images it
  *could* hash and said nothing about the new ones. Caught only by reading the
  WARN count, which is the habit `CLAUDE.md § Reading a check's result` exists
  for. **Re-ran after the deploy; that second run is the one that counts.**
- **`make-link-pin.py` failed all 33 on the first pass: Pillow is not installed
  in a fresh web container.** It refuses to write an uncropped hero, which is the
  right call — `pip3 install Pillow`, then re-run.
- **One pin died on a transient TikTok CDN SSL error** (`curl (35)
  SSL_ERROR_SYSCALL`, Sullaluna). The loop printed `36 FAIL` mid-run; a tail of
  the log would have missed it. Found by checking every output file's **size**,
  not the loop's last lines. Retry succeeded first attempt.
- **Nominatim's first hit is routinely the wrong town.** `145 Perry Street`
  returned **Hempstead, Long Island** ahead of the West Village; `745 Washington
  Street` returned Baldwin Harbor second; `777 Washington Street` returned Utica
  and Franklin Square and **never offered Manhattan at all** until the query was
  narrowed. Every hit was read; none was taken on position.
- **No `gh` CLI in this container**, so `scripts/upload-images.py` cannot run —
  and a plain `git fetch` of `gh-pages` is ~4 GB and times out. Route that works:
  `git fetch --filter=blob:none --depth=1 origin gh-pages`, then build the commit
  with plumbing (`read-tree` → `hash-object -w` → `update-index --cacheinfo` →
  `write-tree` → `commit-tree`) and push the SHA to `refs/heads/gh-pages`. One
  commit, one Pages rebuild, no blob checkout. **Worth adding to the runbook.**

## The six that were not pinned

| # | Link | Why |
|---|---|---|
| 7 | `DdEwdxFA4Ap` CopenHill | **Already pinned** — triage re-derived the uuid5 and found it live |
| 24 | `DdMSyxXs1lQ` The Twist, Kistefos | **Already pinned**, same way |
| 31 | `tiktok.com/t/ZP83uvdUS/` | **Unreadable** — oEmbed returns no thumbnail. Needs a fresh link |
| 30 | `tiktok.com/t/ZP83u4CSW/` | Georgia waterfall, **not identifiable**. Caption is five hashtags; the thumbnail shows a walk-behind ledge on a developed boardwalk that resembles **Dry Falls, NC** — frequently posted as "GA". Not minted rather than guess a coordinate |
| 33 | `tiktok.com/t/ZP83uTpcj/` | NoHo restaurant, **not identifiable**. Thumbnail is a wall of vinyl behind glass; Vinyl Steakhouse is the obvious candidate and is **Flatiron, not NoHo** |
| 13 | `DdFgT_duwOb` Nighthawks | **Two places, both Manhattan** — 70 Greenwich Avenue and Hopper's studio at 3 Washington Square North. Needs the owner's explode / lead-only / skip call, and the same-city rule means subject-slug fragments, minted by hand |

## Identifications worth recording

Four were resolved from the **thumbnail**, not the caption — the captions named
nothing:

- **La Piscine, Roubaix** — the Art Deco pool-turned-museum, sunburst window.
  Caption was *"The prettiest museum I've ever been to #france"*.
- **Muscarelle Museum of Art** — name burned into the frame.
- **Skaneateles Fields Resort & Spa** — reception wall reads `…ELES FI… / …ORT & SPA`.
- **Rainier Tower, Seattle** — Yamasaki's inverted pedestal. ⚠️ **Inferred from
  the opening frame alone**; the caption ("Seattle has an insane bench of
  talented people") names nothing, so if the video is not about the tower this is
  the one to revisit.

Two came from research: Roy Lichtenstein's studio is **745 Washington Street**
(Whitney ISP since 2022), and Steve Cohen's mansion is **145 Perry Street**.

## Left undone deliberately

**Two architect tags do not exist in the vocabulary** and were skipped rather
than invented: **Enric Miralles** (Scottish Parliament) and **Minoru Yamasaki**
(Rainier Tower). Adding them touches `Models/Tag.swift`, which is app code and
therefore sits behind the owner-OK gate — not worth holding a content PR for.
`McKim, Mead & White` was skipped on the Prison Ship Martyrs' Monument for a
duller reason: `--tags` is comma-separated and the firm's name contains commas.

## Verification

- `validate-tours-mirror.py`: **0 errors**, selftest **32/32 faults caught**.
  3 warnings remain and all three are **pre-existing** (People's Choice Family
  Fun Center, UIC Skyspace, Gerry's Pompeii). Eight warnings this batch created
  — a missing Place-type or Theme facet — were patched before committing.
- 33 heroes, all **1200×900**, all **byte-distinct** (checked locally before
  upload, which is the Thyssen failure mode).
- All 40 gh-pages paths confirmed **new** before the push, so nothing was
  overwritten at a live URL.
