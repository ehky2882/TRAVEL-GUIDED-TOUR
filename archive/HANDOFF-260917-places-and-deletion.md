# Handoff — 2026-09-17 · the place tier was testing the wrong thing, and the seed learned to delete

**Session:** web/remote, branch `claude/scale-pinned-tours-automation-dba3lx`
**Merged this session (8):** [#934](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/934) ·
[#936](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/936) ·
[#941](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/941) ·
[#950](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/950) ·
[#952](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/952) ·
[#958](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/958) ·
[#971](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/971) ·
[#972](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/972)

The previous handoff ([#931](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/931)) stops at
#930. Everything above had none.

---

## The question that started it

> *"I just found another place candidate. Rothko Chapel in Texas. So why wasn't that picked up? Am
> I still going to find a lot more? I feel like we've scanned the catalog many times and
> implemented new systems and yet I'm still discovering new examples."*

**The answer is yes, and the reason was structural.** `docs/places.md` Rule 1 says *two names for
one thing is always a place*. `check-place-candidates.py` tested **whether two entries sat on the
same coordinate**. Coincidence is a *proxy* for identity — a good one, and it found plenty — but it
is not the rule, and everything the proxy missed stayed invisible however many times the catalogue
was scanned. The owner kept finding those by eye.

🔴 **Rothko Chapel was not even a miss by the tool** — it was in the TIGHT output that had been
printed. An ad-hoc scan run beside the tool dropped it because `"therothkochapel" != "rothkochapel"`.
Two failures in one: a proxy where the rule belonged, and a hand-rolled scan trusted over the
checker's own output.

## The fix — a NAME tier, and CI runs it (#950)

`scripts/check-place-candidates.py` gained a **NAME** tier that compares subject words rather than
metres:

- `display_stem()` takes the text before `|` (bilingual titles) and strips parentheticals
- `subject_words()` drops the **union of both entries' city words**, then tests set **equality**
- `NAME_RADIUS_M = 1500` bounds it to the same locality
- NAME is reported **first**, and NAME pairs are suppressed from TIGHT/NEAR so nothing double-counts

⚠️ **Set equality, not containment.** Containment matched *"Akihabara"* to *"Gyukatsu Ichi Ni San,
Akihabara"* — a restaurant in a district, not two names for one thing.

⚠️ **The union of both cities is load-bearing.** Dropping each side's *own* city words stripped
`asakusa` from `Tokyo (Asakusa)` but not from `Tokyo`, and the tier lost Asakusa Underground Street.
Caught only by a regression check against the **pre-#941** catalogue — 8 of 9 recovered, not 9. Run
that check on any change to the tier.

Selftests 35 → **42**. And a new **`place-candidates` job in `.github/workflows/ci.yml`**, so rule
8c no longer depends on a session remembering it:

```yaml
code=0
python3 scripts/check-place-candidates.py --out candidates.txt || code=$?
if [ "$code" -ge 2 ]; then exit "$code"; fi
```

⚠️ **`|| code=$?` is not decoration.** GitHub Actions runs `run:` blocks under `bash -e`, so a
bare non-zero exit kills the step before the report is ever written. The job reports and annotates,
and fails only on exit ≥ 2 (COULD NOT VERIFY).

**Result: EXACT 18 → 0, NAME 11 → 1.**

## What the backlog actually contained — 29 places, and worse

#941 (9), #952 (Grace Farms), #958 (10) and #936 (7 + two orphans) minted or extended **29** places.
But the places were the smaller half of the finding.

🔴 **In 13 of 15 place groups, the TOUR was the thing in the wrong position** — not the pin. Every
one of these coordinates was **precise, plausible and in the right city**, which is exactly why no
check has ever caught them:

| Entry | Off by |
|---|---|
| Grace Farms *(owner-found)* | **6.1 km** |
| Geisel Library | **5.4 km** |
| La Collina | **1,440 m** |
| Casa de Vidro | **833 m** |
| Asakusa Underground Street | **718 m** |
| Domino Park | 201 m |

And #936 closed the other half of #930's coordinate work: **#930 moved 26 coordinates and changed
zero centroid lines.** `Tour.coordinate` and the "distance away" label read `centroidLatitude`, not
stop 0 (`Models/Tour.swift:393,448`) — so the map pins moved and every distance calculation stayed
on the old spot. **36 entries, worst 366 m, 4,270 m of total drift**, re-synced.

## Grace Farms — the shape of the mistake worth remembering

> *"'PAVILION IN THE POND' BY NINOSBUILDINGS IS NOT AT THE GLASS HOUSE!.... IT'S AT GRACE FARMS!"*

I had filed it as a **part-vs-whole judgement call** — which `docs/places.md` records as explicitly
undecided and therefore a question for the owner. That framing questioned the *relationship between
the two titles while assuming both were true*. Both were wrong: the pin was at Grace Farms, 6.1 km
from The Glass House, and neither entry was correctly named. Retitled to **Grace Farms — River
Building** on the owner's decision.

**A place candidate can be two wrong names for one right place.** A group is not only a question
about whether to merge; it is evidence that at least one of the two is describing something else.

## Four owner catches, one cause

1. **Skunk Train** — reported as a candidate; already a place (minted by another session in #953).
2. **1111 Lincoln Road** — same; *"CHECK THE REPO. SKUNK AND 1111 ARE ALRADY PLACES"*.
3. **Grace Farms**, above.
4. **"THOSE ARE VERY OBVIOUSLY PLACES"** — I had softened three- and four-member groups into
   deliberation, the exact presentational failure `docs/places.md` Rule 0 warns about.

**The common cause of 1–3: quoting a scan taken minutes earlier while four other sessions kept
merging.** Re-derive at the moment of speaking, not at the moment of scanning.

🔴 **And 1111 produced a red CI run — `duplicate place id`** — from two compounding mistakes:
an **EXACT group reporting does not mean no place exists**, it means *a member* is unplaced; and my
membership query did not exclude already-placed entries. The process failure underneath both: I ran
the full invariant check, **then added a group afterwards**, and re-ran only the candidate scan.

## Phase 3, server half — the seed can delete (#971)

`backend/seed_from_toursjson.py` has always been **upsert-only**, so content deleted from
`Tours.json` reached the gh-pages mirror and the bundled seed and **never reached Postgres, which is
the app's primary source**. Removing anything was a two-part change nobody could be relied on to
remember.

It now emits a guarded prune, **keyed on the maker** so in-app uploads are untouched:

```sql
select count(*) into doomed from public.tours
 where lower(id::text) not in (<catalogue ids>)
   and lower(maker_id::text) in (<catalogue maker ids>);
if doomed > 300 then raise exception '...'; end if;
delete from public.tours where ...;
```

Two guards, both deliberate: `PRUNE_CEILING = 300` inside the transaction, and
`MIN_SANE_TOURS = 1000` in `validate()` so a truncated `Tours.json` cannot even reach the SQL.

✅ **Verified against production before shipping**: all 4,382 rows are `'published'`; exactly one
row is not in the catalogue — *Wes the Wanderer*'s in-app upload — and the maker key protects it.
✅ **And verified after merging, on a real run**: the `publish-catalog.yml` run on `5a80849e`
completed success and a live count read **`Tours.json` 4,381 / Postgres 4,382 / difference 1**. The
prune ran for real and deleted nothing, exactly as predicted.

**The client half is NOT built.** `removedIds` in `get_catalog_since` is still always empty, so a
deletion still reaches a phone only via a full download. Reconciliation in `RemoteCatalogLoader` was
designed (83,542 bytes measured, chosen over tombstones) and is app code — it needs TestFlight and a
device review.

## The rest

- **#934** — `check-coordinates.py` and `check-catalog-contract.py` were the last two checkers not
  printing a `RUN … · rev … · timestamp` stamp. Now stamped, plus a selftest that walks `scripts/`
  and fails **naming the offender**. ⚠️ My first version of that guard *could not fail* —
  `"import runstamp" not in source` matched a commented-out import. Mutation-tested after fixing.
- **#972** — the Monkey King hero was a Manhattan street, not the restaurant. Owner supplied an
  interior. ⚠️ The popmenucloud URL they pasted is a **CDN resizer**: it served **1200×800**, under
  the pipeline's 900 floor. The untransformed original is **7200×4802**. New filename per image
  rule 9 — never overwrite bytes at a live URL.
- **Rule 6 was skipped all session** and then caught up: two stale merged `claude/*` branches
  deleted.

## Housekeeping this handoff carries

- **`status/owner/delete-abandoned-scale-branch.md` is cleared.** The branch it names is this
  session's designated branch. Its dangerous head — `backend/add_catalog_rev.sql`, a **second**
  migration for a job already applied to production — has been replaced by resetting the branch onto
  `main`. The hazard it describes (*"a future session tidies that branch up and opens a PR in good
  faith, and the owner gets handed a duplicate SQL block"*) no longer exists: nothing from that head
  is reachable from any ref. Everything worth keeping had already been rescued to `main` in #945.
  ⚠️ **The branch itself still exists** — a remote/web session gets 403 on `git push origin --delete`
  — but it now points at `main` plus this handoff, so it is ordinary tidying rather than a trap.
- **§ Key facts was re-derived and needed no change**: 1,582 tours · 2,799 pins · 344 places · 472
  makers · 1,954 tour stops · 619 cities · 69 countries. Another session had already corrected it
  after #959/#961, and it still held. **Re-derive it anyway next time** — that line's own history is
  thirty-one stalings long.

## What is still open

| | |
|---|---|
| Phase 3 **client half** | Reconciliation in `RemoteCatalogLoader`/`DataService`. App code → TestFlight + device review |
| `removedIds` | Still always empty; deletions reach phones only by full download |
| **1.1.3** | Carries the delta client (#914, device-verified on build 161). Not submitted — owner's call |
| NAME tier | **1 group left**; EXACT is at 0 |
