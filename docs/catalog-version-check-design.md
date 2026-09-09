# Ask before you download — the catalogue version check

**Status: proposed. Nothing is built. This exists to be read and decided on.**

Written 2026-09-09, after the Supabase over-quota email. The immediate waste was fixed in
[#770](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/770); this is the thing that actually
scales.

---

## The problem, in one sentence

The app asks the database **"give me everything"** and gets 3.4 MB — *even when nothing has
changed since the last time it asked.*

There is no way to ask "has anything changed?" today, because the catalogue arrives from a POST
RPC, which carries none of the web's usual freshness machinery (no ETag, no `If-None-Match`, no
304). **A fetch that finds nothing new costs exactly as much as one that finds a whole new city.**

## The idea, in one sentence

Ask **"what version is the catalogue?"** first — 34 bytes — and only download the 3.4 MB if the
answer is different from what we already have.

---

## The good news: most of this already exists

`backend/catalog_snapshot.sql` (already applied) turned the catalogue into a **single stored row**
that is rebuilt once per seed instead of once per request. That row is:

```
public.catalog_snapshot
    id           -- always true; exactly one row, by construction
    payload      -- the whole catalogue, ~11 MB of JSON
    refreshed_at -- when it was last rebuilt
```

And it already publishes the timestamp:

```
public.catalog_snapshot_age()  ->  refreshed_at
```

**Measured live on 2026-09-09:**

| | bytes | time |
|---|---:|---:|
| `catalog_snapshot_age()` | **34** | 0.25–1.16 s (≈0.3 s warm) |
| `get_catalog()` | 3,623,495 | 2.43 s |

It is **already granted to `anon`**, so the app can call it today with the publishable key it
already ships. **No SQL migration is required.** The owner pastes nothing.

## Why this is safer than a version check usually is

The dangerous failure for any "has it changed?" scheme is a version that **says no when the answer
is yes** — every phone quietly freezes on old content, and nothing errors. Silent staleness is the
exact shape of the 2026-08-19 incident, where three features vanished for 14 hours because a
missing key decodes as `nil` rather than as a failure.

**That cannot happen here, and the reason is structural rather than careful:**

`payload` and `refreshed_at` are **two columns of the same single row**, written by the same
`insert … on conflict do update` inside `refresh_catalog_snapshot()`. They are updated together,
atomically. **The version cannot disagree with the content it describes**, because it *is* the
content's own row.

The one remaining way to get stale content — editing the database by hand and forgetting
`select public.refresh_catalog_snapshot();` — makes `get_catalog()` stale *too*. So downloading
would not have helped either. The check is exactly as fresh as the thing it is checking, never
less.

⚠️ It can be **wrong in the harmless direction**: a re-seed that changes nothing still bumps
`refreshed_at`, so the app downloads unnecessarily. That costs one download and breaks nothing.

---

## What actually gets built

All of it in `TRAVEL GUIDED TOUR/Data/RemoteCatalogLoader.swift`, which already owns the cache and
the source order.

**1. Remember the version beside the cache.** The loader already writes `Tours.cache.json` plus a
sidecar `Tours.cache.version` holding the app's build number. Add a second sidecar holding the
catalogue version the cache came from.

**2. Ask before fetching.** In `refresh()`, against the Supabase source only:

```
if we have a usable cached catalogue
   AND the server's version == the version stored beside that cache
then stop. Nothing to download.
otherwise download as we do today, and store the new version with it.
```

**3. Fail toward downloading.** If the probe errors, times out, or returns something unexpected —
download, exactly as today. **The check is an optimisation and must never be the reason content
fails to arrive.**

That is the whole change. Roughly 40 lines plus tests.

### Three details that matter

- **"Version matches" is not enough on its own.** It must be *version matches* **and** *we have a
  readable local copy*. A matching version with a corrupt or missing cache must still download,
  or the app shows nothing.
- **Only the Supabase source is checked.** The gh-pages mirror publishes no version, so if
  Supabase is unreachable and we fall through to the mirror, that path behaves exactly as it does
  today. That is the rare path and is deliberately left alone.
- **The stored version must be written only on a successful, decoded download.** Writing it on a
  fetch that later failed to decode would mark us up-to-date holding a catalogue we never
  actually got.

---

## What it saves

Measured payload sizes; usage patterns are estimates and marked as such.

| | today | after |
|---|---|---|
| Owner testing (repeated opens) | 3.4 MB most times | ≈0, almost always |
| Our own scripts | 3.4 MB per run | ≈0 unless content moved |
| A user opening the app several times a day | several downloads/day | **at most 1/day** |
| A user opening it once a day | ~30 downloads/month | ~20/month |

**The heavy cases improve most. The light case improves least**, because the catalogue changes on
roughly 20 days a month, so a once-a-day user meets new content most days anyway.

It also makes launch *faster* in the common case: a 0.3 s probe replaces a 2.4 s download.

## What it does NOT fix

**When something has changed — even one tour — the app still downloads all 1,552 tours.** That is
the real design problem underneath, and this does not touch it. It reduces *how often* we pay,
not *how much* we pay each time.

Two later steps, in order of value:

1. **Stop sending text nobody reads.** `stops.transcriptText` is **38%** of the payload and
   `longDescription` another **18%** — both sent for all 1,552 tours on every fetch, both visible
   only on one tour's own page. Dropping transcripts alone cuts the payload **41%**. This is
   bigger and simpler than the version check, but it is a **breaking** catalogue change and needs
   its own thinking about builds already on phones.
2. **Send only what changed** (`?since=<version>`), or **only where the user is**. Bigger jobs;
   not urgent yet.

---

## How it would be tested

The loader already takes an injectable fetcher and cache directory, and its tests already cover
the fallback chain, so this fits the existing shape.

- version matches + good cache → **no catalogue request is made at all**
- version matches + missing/corrupt cache → **downloads anyway**
- version differs → downloads, and stores the new version
- probe fails (timeout, non-200, junk) → downloads, exactly as today
- download fails after a differing version → the stored version is **not** advanced
- gh-pages fallback path → unchanged

Plus one live check against the real database before merge: change nothing, relaunch, confirm no
catalogue download happens; publish a content change, relaunch, confirm it does.

## The risk, stated plainly

**This is the launch path.** It is the code that runs when someone opens the app, and it is the
most sensitive code in the project: when it goes wrong the symptom is not a crash, it is an app
that shows nothing or shows month-old content, with no error anywhere.

That is the argument for the fail-toward-downloading rule above, and for the live check before
merge. It is not an argument against doing it — the change is small and the version is
structurally trustworthy — but it is why this was written down before being built.

## What is being asked

1. **Build it?** ~40 lines plus tests, no SQL, no owner action, one TestFlight build to confirm.
2. **Or go straight at the bigger win** — dropping transcripts from the payload (−41%) — and do
   this afterwards?

They are independent. Doing both is the eventual answer; the question is only which first.
