# Handoff — 2026-09-14 → 17 · the delta scoping, the churn underneath it, and a day of places

**Session:** web/remote, several branches (`claude/*`), no Mac in container
**Merged (13):**
[#890](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/890) ·
[#904](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/904) ·
[#945](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/945) ·
[#951](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/951) ·
[#956](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/956) ·
[#964](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/964) ·
[#970](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/970) ·
[#974](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/974) ·
[#975](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/975) ·
[#976](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/976) ·
[#978](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/978) ·
[#984](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/984) ·
[#986](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/986)

⚠️ **`HANDOFF-260917-places-and-deletion.md` is a DIFFERENT session** (branch
`claude/scale-pinned-tours-automation-dba3lx`, covering #934–#972). The two ran in parallel and
both touched places. Neither is a superset of the other.

---

## The brief, and what it produced

Write a scoping document for delta catalogue fetching. **Design only** — no app code, no
migrations. Every figure re-derived, never quoted from a document; payload measured **compressed**,
because that is what Supabase bills.

`docs/delta-catalog-fetch-design.md` (#890). Four options with the trade-offs stated honestly:
**A** a changed-since cursor (recommended), **B** city scoping (rejected — it is a product change
wearing an engineering costume), **C** server-side diffing (rejected), **D** index + detail (second
choice).

| measured 2026-09-14, on the live RPC | |
|---|---|
| whole catalogue, gzip level 1 (what PostgREST uses) | **2,427,222 bytes** |
| median day's change | **7,019 bytes — 0.29%** |
| **so we send** | **≈345× more than the change is worth** |
| days out of 30 the catalogue changes | **28**, against an assumed "about 20" |
| growth | **+6.6% in 48 hours** |

---

## 🔴 Two wrong numbers in `CLAUDE.md`, and the method behind them

`longDescription` was recorded as **8.2%** of the compressed payload. It is **43.9%** — the largest
single thing we send. Two separate keep/cut decisions had already been argued on the wrong number.

**The method error matters more than the number.** The original measurement compressed at **gzip
level 9**; PostgREST serves at **level 1**. Level 9 understates the bill *and reorders the fields*,
so any figure produced that way is wrong in a way that cannot be spotted by looking at it. Both the
figure and the method are corrected in `CLAUDE.md` § Egress and `docs/lessons.md`.

⚠️ `longDescription` is still **KEPT**, and the reason changed: it is load-bearing, not small.
`TourDetailView` renders it and `SearchView` searches it — and **`Tour.longDescription` is
non-optional in Swift**, so a payload without it decodes `tours` as **zero elements** while
`ToursData` still reports success, and `RemoteCatalogLoader` then overwrites a good cache with the
empty result. Dropping it is not a regression, it is a silent wipe.

---

## 🔴 Phase 0 — the bug that would have made delta fetching worthless (#904)

`seed_from_toursjson.py` ended every upsert with `updated_at = now()` **unconditionally**. An
identical re-seed therefore rewrote **3,745 of 3,745 tours, 424 of 424 makers, 303 of 303 places
and all 4,117 stops — about five times a day.**

**This is the part worth carrying forward.** A delta cursor answers *"what changed since rev N?"*
If everything is stamped as changed five times a day, the answer is always *everything*. The whole
design would have shipped, appeared to work, and cost exactly what it cost before.

What landed:

- **`backend/catalog_rev.sql`** — additive, idempotent, self-verifying. A `rev` sequence, and a
  trigger that bumps it **only when the row actually differs**, comparing
  `to_jsonb(new) - 'rev' - 'updated_at'` against the same of `old`. Plus `stops.updated_at`, a
  stops→parent-tour bump, and `stops_tour_id_order_key` made DEFERRABLE.
- **`seed_from_toursjson.py`** — `upsert_tail(table, pairs, touch_updated_at=True)` generates the
  `set` list **and** the `where … is distinct from …` guard from one list, so the two cannot drift.
  Stops are upserted rather than deleted-and-reinserted.
- **`backend/test-seed-idempotence.sh`** — asserts an identical re-seed writes **zero** rows, by
  timestamp marker **and** by `xmin` (physical rewrite). 🔴 **Verified to FAIL when the guard is
  removed** — an assertion nobody has watched fail is not an assertion.

**Confirmed in production**, not inferred: **370 rows in 12 hours**, against roughly 4,000 per
seed before. The owner applied the SQL themselves ("RAN THE SQL. SUCCESS").

🔴 **The regression is invisible.** Re-add an unconditional `updated_at = now()`, or add a column
to the `set` list and forget the `where`, and the seed is still *correct* — content lands, the app
is fine, CI is green. The only symptoms are churn and a cursor that silently returns everything.
`test-seed-idempotence.sh` is the only thing in this repo that would notice.

---

## Places — nine PRs, most of them owner-spotted

| PR | what |
|---|---|
| **#956** | five pins sitting *on* a place without being members — they carry **7** decimal places where the place carries **6** (`40.7498787` vs `40.749879`), so they are 2–5 cm apart and invisible to an exact matcher |
| **#964** | the Barbican Estate pin, **39 m** out and identically titled. The owner found it by looking at the map |
| **#970** | the owner's Barbican part-vs-whole answers written down — **four taken, six left alone** |
| **#974** | `check-place-candidates.py` splits EXACT into **PROVEN** (act without asking) and **ASK** |
| **#975** | six restaurants made places by the PROVEN tier |
| **#976** | a pin titled for a restaurant it only *mentions* |
| **#978** | two All'Antico pins **4.54 km** from the branch they film |
| **#945 / #951** | rescued `docs/scaling-to-100k-design.md` and an owner decision that had sat unmerged on an abandoned branch for two days |

**The PROVEN rule:** both pins carry the **same venue @handle in their own captions** —
`sourceAuthor` excluded, since that is the creator's handle, not the venue's. The venue identifies
itself, so no judgement is needed. 49/49 selftests.

🔴 **The place-ID formula is written down at last** (#975, `docs/places.md`). Found in
`archive/CURRENT-STATE-HISTORY.md` after brute force failed:

```
uuid5(NAMESPACE_URL, f"atlas-place:{slug(city)}:{slug(name)}")   # lowercased
slug = re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")
```

⚠️ **It DROPS non-ASCII rather than transliterating** — 339/344 match as written, 320/344 if you
transliterate. Because it is deterministic, a `Tours.json` merge conflict in `places` can be
resolved by taking `main` wholesale and **re-deriving**; that is exactly how #975's conflict was
resolved, and the ids came back byte-identical.

---

## Settings: the refresh button (#984, #986)

Owner: *"it works for me becuase i'm super familiar with the app but in reality most people wont
know about it."*

**"Clear Cache" → "Check for new content"**, `trash` → `arrow.clockwise`, a **"Checking…"**
spinner while it runs, and a footer saying downloads are not removed. **No behaviour change** —
same three caches, same refresh. #986 followed the rename through six comments across five files.

Two things were wrong with the old name, and only one is obvious:

- **It named the mechanism.** Nobody wanting the newest tours goes looking for a *cache*.
- **It read as destructive and is not.** Checked rather than assumed: downloads live in
  **Documents** under `TourDownloader`; this path clears `URLCache`, `ImageCache` and the stored
  catalogue and **cannot reach a download**. Someone abroad with tours saved for a trip had every
  reason to avoid the one control that would have fixed them.

🔴 **THIS IS A REPAIR HATCH AND NOT THE FIX.** The app already refreshes on cold launch and on
foreground after **900 s**. One interval currently governs two different things: *checking*
(34 bytes via `catalog_snapshot_age`) and *downloading* (~2.4 MB). **Once 1.1.3 ships delta
fetching the download falls to roughly 19 KB, and `DataService.foregroundRefreshInterval` can come
down far enough that an ordinary listener never reaches for this row.** That is the actual answer
to the owner's question and it is **not done**.

⚠️ **Pull-to-refresh does not fit Home** — Home is a map (`HomeView` has no `ScrollView` at all),
and a downward drag pans it. `.refreshable` appears nowhere in the app. Library could take it.

---

## Mistakes, because they are the useful part

🔴 **I claimed 46 pins were invisible on the map. They were not — the real number is 0.** Every
oversized coordinate group was already a place, and a place renders as **one** pin that opens its
own screen, so `prefix(maxStacked)` cannot truncate a member. I had counted raw coordinate groups
without excluding place membership — **and PR #924 had already retracted that exact arithmetic**.
The owner caught it by simply asking whether the cathedral's pins were reachable. Membership lives
in `place.tourIds`, not on the pin.

🔴 **I asserted from a coordinate that the All'Antico video was about the Upper East Side branch.**
A coordinate cannot tell you what a video is about. The owner asked *"is the all'antico video
really specifically about the ues location?"*, then watched both and found they were **both
Sullivan Street** — meaning both pins were **4.54 km** wrong, not one.

**I checked place membership against `centroid` instead of the member's FIRST STOP** and got 27
false positives. `validate-tours.swift` checks the first stop. Re-run correctly: zero.

**I nearly duplicated another session's work** (#952 was already fixing the class I had started on)
and stopped only because the owner asked. **Check for a parallel session before starting on a
shared checker.**

**#975 had zero CI runs and looked fine.** It was opened against another `claude/*` branch, and
`ci.yml` only watches `main`. 🔴 **A PR with no checks is not a green PR** — read the count, not
the absence of red.

Smaller: a `set` joined with `" ".join(...)` gave random word order and broke a containment test;
backticks inside a double-quoted `python -c` were shell-expanded and mangled a PR body; unquoted
`TRAVEL GUIDED TOUR/...` word-split into three fake filenames; and `git commit` refused five times
with four different reasons before a plain retry worked — **inconsistent failures are flakiness,
read them as such sooner**.

---

## State at handoff

Re-derived on `main` at `8171e1bc`: **places 351 · tours 1,582 · link pins 3,067**. Invariants
clean — 0 duplicate place ids, no member whose first stop is off its place, no double membership,
no place under 2 members.

**Nothing of this session is open.** `gh` is **not installed** in this container; the GitHub REST
API via `curl` with `$GH_TOKEN` works, and needs an explicit `Content-Type: application/json` on
`PUT`/`POST` or it 415s. **Branch deletion returns 403** from here.

### Left undone, in the order it matters

1. 🔴 **Lower `foregroundRefreshInterval` once 1.1.3 ships.** This is the real answer to the
   owner's refresh question; the rename is cosmetic beside it.
2. **#984/#986 are not on any device.** They ship with the next TestFlight build. Owner OK was
   given for the merge, not for a build.
3. **1.1.3 itself — owner said explicitly "DONT START ON 1.1.3".** Do not.
4. **`status/owner/auto-created-places.md`** — the owner's decision on minting places in bulk.
   Gates section A1 of `docs/scaling-to-100k-design.md`. ⚠️ Its "invisible pins" evidence is
   **retracted and marked as such**; the decision stands on its own merits.
5. **Removals are still unbuilt.** `removedIds` is always empty, and `seed_from_toursjson.py` is
   upsert-only, so deleting content is a two-part change — the catalogue edit **and** an SQL paste.

### Known faults, not fixed

- **The place-ID formula collides for chains.** `city + name` cannot distinguish two branches of
  one restaurant in one city. Bit us on All'Antico.
- **`check-place-candidates.py` matches coordinates exactly**, so a large site is structurally
  invisible to it — the 40-acre Barbican was 39 m out and no metre-scale sweep would ever find it.
  A **name** match would have, in one pass. `docs/places.md` Rule 5 says this in that place's own
  worked example.
- **One pin filed under All'Antico Eighth Avenue is still unpaired.**

`ROADMAP.md` deliberately not touched: nothing here is a release milestone or a cut in scope, and
its status blocks are the single most conflict-prone text in the repo.
