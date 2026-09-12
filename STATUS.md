# STATUS — the live board

**What this file is.** A short, mechanical record of *what is in flight right now*: open PRs,
which TestFlight build carries which branch, and what is waiting on the owner. It is the thing
a session reads to answer "what is everyone else doing?" before it starts work.

**What this file is NOT.** History. `CLAUDE.md` § Current State is the narrative record of what
shipped and why, and it stays the authority for anything already merged. When an item here is
finished, it leaves this file and its story goes there. Never let this file grow a history
section — two histories drift, and drift is the problem this file exists to fix.

**Update rule (automatic, no prompting).** Any session that opens or merges a PR, dispatches a
TestFlight build, or discovers/clears an owner-blocked item updates the relevant table here in
the same commit. Re-derive rather than trust: `gh pr list --state open`, and read the build
numbers back from the Actions run list — never from what a PR body predicted.

**Last verified:** 2026-09-12, 21:20 UTC (**the owner pasted the SQL — the two duplicate pins are gone.**) Verified four ways rather than taken on trust: row count **3,441 → 3,439**, both pin ids return empty, the orphaned `Instagram @pacificmodernism` maker row is gone (so the conditional delete fired and it held no other pins), and `catalog_snapshot_age()` reads **21:17:56 UTC** — the rebuild is what makes a paste reach a phone, so it is the check that matters. ✅ **Both TikTok replacements survive**; after a deletion the risk is losing the survivor, not the duplicate. § 2's item is marked cleared, with the process rule kept — **a merged PR that needs an owner paste is not finished; it moves to § 2** — because that is what let it sit live for two days. **Still open and waiting on the owner: [#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776)**, which merges cleanly and needs an OK plus a two-minute device check.

**Previously:** 2026-09-12, 21:00 UTC (coordinator catch-up — **no content, no code; two findings and one merge**). `main` moved **58 commits** since this session last looked. Catalogue re-derived on `f76bfac`: **1,552 tours · 1,886 pins · 388 makers · 290 places · 1,924 tour stops (3,810 including one per pin) · 501 cities · 64 countries** — ⚠️ the `CLAUDE.md` Key-facts line read **1,870 / 387 / 499**, its **twenty-fifth** staleness, because [#834](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/834)'s 16 pins landed *after* the previous correction; counted and corrected. ✅ **[#795](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/795)'s SQL HAS been applied** — proved against the live RPC, not read off a board: stop objects come back with **no `transcriptText`**, so the 37.5% cut is real and serving. 🔴 **But a different paste is still owed and was on NO board: [#805](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/805)'s removal SQL never ran**, so the two `@pacificmodernism` Instagram pins #804 replaced are **still live on the map beside their replacements** — found by diffing the `tours` table (3,441 rows) against `Tours.json` (3,438); see § 2. The third extra row is a **private in-app maker upload** and is correct. 🔴 **[#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776) is no longer conflicted** — re-tested, merges clean; it has been waiting on the owner since 9 Sep and is the only item blocked specifically on them rather than on another session. [#798](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/798) (docs-only, China reachability) **merged** as `f76bfac` under Rule 4 after sitting two days; squash verified to carry both files. App Store re-checked from Apple: still **1.1.1**, released 1 Sep. Latest TestFlight build: **150**. Supabase snapshot rebuilt **17:37 UTC** by #834's own seed; `get_catalog` 200 at TTFB 1.58 s. **Merged since the last look, in brief:** #749 (the 54-pin batch that was stuck for a week), #795, #835 filter chips, a **places expansion 181 → 290** across #801/#806/#807/#809/#818/#822 with several real coordinate defects repaired, #785 (a link pin that cannot load now says so), and #825/#827 (the website says the app is out). **All egress probes this session used the cheap forms in `CLAUDE.md` § Egress**; the one full-catalogue read was capped at 600 KB by stopping the stream.)

**Previously:** 2026-09-12 (session 160 — **CODE, awaiting owner device review.** The home map's filter row is rebuilt: the flat eighteen-toggle tag row becomes **All · Format · Price · Dozents · Tags**, each chip opening a panel, every chip multi-select. Open as [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835), on **build 145** — ⚠️ **never compiled: this session has no Mac, so CI on the PR is the first honest check and the device is the second.** Designed in Claude Design first and iterated against the owner's AllTrails reference, ~30 artboards, spec of record in `docs/filter-chips-design.md`. 🔴 **The design nearly shipped with no Price chip on a false reading of `Tours.json`** — it reads `priceTier: nil` for every tour **and always will**, because `seed_from_toursjson.py` omits the column deliberately; the live DB has **66 paid tours** (all multiStop, $0.99), read with the 47-byte count query, never the 3.4 MB RPC. Live figures the taxonomy was cut against: **1,553 tours vs 1,888 pins** (1,235 TikTok · 634 Instagram · 19 YouTube) — and the pin count moved 1,796 → 1,888 **mid-session**, which is the re-derive rule arriving on schedule. Counts beside each option are **contextual, not global** (`Contemporary` matches 401 alone and **zero** alongside four other picks), which is the part most likely to ship subtly wrong and is where the 17 tests are weighted. Chip heights are one decision: **44 pt in the row** (Apple's minimum, one-handed while walking) and **32 pt in the panels inside a 48 pt frame**, because a thumb feels the pitch rather than the drawn height. **Sort on the drawer header is designed and deliberately NOT built** — the one open item.)

**Previously:** 2026-09-11 (session 159 — **infra/docs/website, no code.** **Stripe round 5 SUBMITTED**, the first response able to show a product: the Website URL is now the **App Store listing**, because four rounds of argument could not substitute for a reviewer being able to look at the thing. 🔴 **Two claims from rounds 1–4 had quietly become FALSE** — "no transactions processed" and "all content is first-party" — both true when written, which is what makes copying them forward dangerous; the new rule is in `docs/stripe-review.md`. 🔴 **That file existed only on an unmerged branch** until [#802](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/802), so this session nearly re-sent round 3's answer; [#823](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/823) recorded round 5 verbatim, **three boxes not two** — the form reused round 3's title exactly and grew a required field, caught only because the owner sent a screenshot. **Purchase evidence: 4 rows, 1 real sale, 3 sandbox — ✅ closing the session-79 ES256 risk** (real user tokens DO reach `record-purchase`); no Apple money is the payout threshold, not a bug. 🔴 **And `dozent.world` had said "Coming Soon" for eleven days** while the App Store gave it as the support URL — six places across three pages, including `/g/` twice, fixed and **verified live** in [#825](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/825) (badge bytes hash-matched against the CDN). Two owner items added below, both minor. ⚠️ **I overwrote another session's `HANDOFF-260911-3.md`** by checking for a free suffix before fetching — restored intact from `origin/main`; the tell was `git status` showing `M`, not `A`.)

**Previously:** 2026-09-11 (session 158 — **[#811](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/811) MERGED** (squash `2208a76`): `scripts/triage-account.py` plus the triage step written into `docs/link-pin-runbook.md` and `.claude/skills/atlas-upload/SKILL.md`, and six link pins from TikTok `@jamiepeva`. Catalogue re-derived on the base carrying `ca2e449`: **1,552 tours · 1,794 pins · 384 makers · 266 places · 486 cities · 64 countries** — ⚠️ `main` moved twice around this work (#810 mid-flight, and `places` 250 → 266 *after* the merge), so the Key-facts line went stale for the twenty-third time — and then a twenty-fourth, inside the very PR correcting it, when #814 and #815 landed during an 18-minute simulator build. Counted and corrected against the base actually being merged. A creator's account is no longer minted unread: the tool flags LIVE / SINGLE / MULTI / THIN / DEAD and mints nothing. 🔴 **The flags are a pre-sort, not a verdict** — measured both ways in one run on `@jamiepeva`: 9 of 11 posts passed as SINGLE where **3** were pinnable, *and* a post captioned `📍 Mount Vernon, Virginia` was binned as non-place content. Enumeration ceilings measured rather than assumed: TikTok **14** from `/embed/@handle` (the profile page is captcha-walled — 371 KB, zero ids; a cursor does not deepen it), YouTube ~15 via RSS, **Instagram nothing at all — Basic Display died Dec 2024 and no third-party post-listing route exists**. `validate-tours-mirror.py` 0/0 with 32/32 faults caught; `check-image-duplicates.py --pins` clean and its count reconciled exactly; hero bytes hash-matched **7/7 against the live CDN** after the Pages rebuild. **Supabase seeded automatically** — `publish-catalog.yml`'s seed job ran and the live DB was checked directly (6/6 rows, snapshot 13:27 UTC, via the 34-byte `catalog_snapshot_age()` rather than pulling the catalogue). **No owner SQL owed.** **One owner decision recorded: property-listing videos are judged case by case** — the creator is a Georgetown estate agent as well as a historian. Two non-blocking items left open, in the handoff: the **Castillo San Felipe del Morro** half-finished hero correction (hero repointed to `-2`, its stop still on the original file), and one image that failed to fetch during the scan — unverified, not passed.)

**Previously:** 2026-09-11 (29 link pins from TikTok `@thedesignssuite` / `@vamuseum` / `@tate` — London architecture and housing estates — MERGED as [#810](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/810) (squash `ddba8ba`). **23 new subjects; 6 stack as a second creator's take on a building that already has an Atlas tour or pin (owner instruction): Lloyd's Building, Tate Modern, Habitat 67, Walden 7, the Barbican, Trellick Tower.** Coordinates: the owner's own Plus Codes decoded with `scripts/decode-plus-code.py` where given, else geocoded fresh from the caption's named subject — every one then reverse-geocoded (Photon + Nominatim) to confirm what's actually there before wiring it in. Two needed extra legwork: **Whittington Estate** (Plus Code recovers onto "Lulot Gardens, Whittington Estate" directly, confirmed via Nominatim) and **Samuda Estate** (caption said "Summerhouse" — that's Netflix *Top Boy*'s fictional estate name; the real building filmed since 2019 is the Samuda Estate, Cubitt Town). `validate-tours-mirror.py` 0 errors/0 warnings — 1,552 tours + 1,773 pins + 250 places. `check-image-duplicates.py --pins` clean. All 32 hero/avatar images pushed to gh-pages in one commit (`gh` CLI unavailable in this session — built via git plumbing: `git hash-object` + `git mktree --missing` + `git commit-tree` against a blobless partial clone, so the ~2GB of existing images was never downloaded) and confirmed byte-identical against the live CDN after the Pages rebuild. `publish-catalog.yml` run 223 confirmed both destinations post-merge: gh-pages mirror at 1,773 pins, live Supabase `get_catalog` RPC sampled directly at 1,775 (two more landed from a parallel session in between) with the new titles present. No owner decision owed.)

**Previously:** 2026-09-10 (session 156 — 21 link pins from TikTok `@nickcabotrodriguez` MERGED as [#790](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/790) (squash `8450c9a`), on top of #789's base. Catalogue re-derived: **1,552 tours · 1,700 pins · 376 makers · 141 places · 466 cities · 64 countries**. Coordinates decoded from Plus Codes and reverse-geocoded, then every subject re-checked against the post's own thumbnail — several corrected an initial geocoded guess (a generic "Hollywood building" was the **Hollywood Pacific Theatre**; a "Madison Avenue restaurant" is **E.A.T.**). `validate-tours-mirror.py` 0/0, `check-image-duplicates.py --pins` clean once gh-pages (`b600496`) deployed. **Two owner decisions owed, both `check-place-candidates.py` finds, neither blocking:** (1) two of the 21 pins ("Part 5"/"Part 6") are the exact same coordinate — **First National Bank of Hollywood**, keep as two pins or make a place? (2) this batch's **St. Vincent de Paul Church** pin sits 12m from an existing Instagram pin for the same church — same call. **The owner also asked to hold an "Abandoned" tag** — a durable vocabulary change (`Tag.swift` + `scripts/seed_tags.py` + `docs/tag-taxonomy-v2.md`), not done in this content-only PR — until that ships separately; 12 of the 21 pins would use it.)

**Previously:** 2026-09-10 (session 155 — 35 link pins open as [#789](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/789); catalogue re-derived after resolving onto `887a8a7`: **1,552 tours · 1,679 pins · 376 makers · 141 places · 466 cities · 64 countries** — ⚠️ `main` moved twice during this session (#787, and #784 landing 27 pins), so the `CLAUDE.md` Key-facts line and this board's previous reading were both stale before the work began; re-derived, never quoted. Two owner decisions owed, in § 5.)

**Previously:** 2026-09-09 (session 153 — 37 link pins open as [#782](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/782); catalogue re-derived on `57e71cb`: **1,552 tours · 1,588 pins · 353 makers · 141 places · 447 cities · 63 countries** — ⚠️ the `CLAUDE.md` Key-facts line read 1,551 / 442, its twenty-first staleness, counted and corrected. One owner decision owed, in § 4.)

**Previously:** 2026-09-09 (session 149, second pass — a catch-up, no content. **`main` moved 11 commits overnight.** Catalogue re-derived on `d7254ab1`: **1,552 tours · 1,489 pins · 353 makers · 140 places · 427 cities · 63 countries** — ⚠️ **#769 added three places and left the `CLAUDE.md` Key-facts line reading 137, its twentieth staleness; counted and corrected.** App Store re-checked from Apple: still **1.1.1**, released 1 Sep. 🔴 **The Supabase over-quota email was our own tooling and the biggest line item was a check I added yesterday — owned in § 2 below, fixed by #770.** ⚠️ **My own 25–33% RPC failure figure now carries a correction** (§ SQL pastes owed): a cheap probe reads 12/12 today, but it is a *different request*, so neither number supersedes the other. 🔴 **TWO PRs ARE CONFLICTED AND STUCK, and one of them is the egress fix itself:** **#776** (the 34-byte version check — built, 8 tests, no owner SQL, needs owner OK + a two-minute device check because it touches `Data/*.swift`) and **#749** (54 pins, untouched since 8 Sep 13:55). ⚠️ **Neither will look broken** — a conflicted PR never triggers CI here, so both show no checks rather than a failure.)

**Previously:** 2026-09-08 (session 149 — a catch-up pass, no content. **Two findings, both measured rather than read off this board.** (1) 🔴 **1.1.1 has been LIVE on the App Store since 1 Sep 15:23 UTC** and § 1d below said the opposite for a week — machine-verified from Apple's *public* lookup endpoint, which needs **no App Store Connect key**, so no session ever had an excuse; `scripts/session-start.sh` now runs it on every start and the perishable-facts table in `CLAUDE.md` is split into released-vs-unreleased. (2) ⚠️ **The catalog RPC is failing far more than the ~1-in-8 recorded below** — see § SQL pastes owed for the fresh sample. Catalogue re-derived on `68d03a67` **after #758 merged mid-session**: **1,552 tours · 1,426 pins · 353 makers · 130 places · 414 cities · 61 countries** — ⚠️ **#758 landed 83 pins and left the `CLAUDE.md` Key-facts line reading 1,343 / 404 / 59, its nineteenth staleness, so this session counted and corrected it.** The gh-pages mirror was byte-current with `main` when measured. Open PRs: **#749** only, another session's link-pin batch.)

**Previously:** 2026-09-07 (session 147 — **the `@poche_space` pin now moves onto the Gilder Center on owner instruction, open as [#746](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/746): Gilder 3 → 4 members, AMNH 6 → 5. It also closes a REAL blind spot in `validate-tours-mirror.py` — `validate-tours.swift:553-554` errors when a `kind: "link"` stop is not `manual` and the mirror checked nowhere — found by injection and checked against the Swift before being called one.** ⚠️ **[#743](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/743) merged while #746 sat open with green CI, so `Tours.json` conflicted and was resolved the documented way — main's file taken wholesale and the idempotent assembler re-run on it, never hand-resolved — with #743's Eastern State place asserted byte-identical afterwards.** Also session 146 continued — **[#742](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/742) MERGED (squash `9eaabdd1`), so the catalog-materialisation SQL paste was unblocked — ✅ **and the owner has since applied it, so NO owner SQL paste is outstanding**; and **`Inside the Abandoned Eastern State Penitentiary` joined the existing Eastern State Penitentiary place as its third member** on owner instruction — the pin moved 3.8 m, the place did not. ✅ **THAT PASTE HAS SINCE HAPPENED, AND THIS HEADER SAID OTHERWISE FOR A DAY — corrected 2026-09-08 by [#750](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/750).** Every earlier reading here was honest when taken: #746 measured `catalog_snapshot_age()` and `get_catalog_built()` both returning **404 `PGRST202`** and `get_catalog()` **500 on three of three** — and #746 merged *after* [#748](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/748) had already corrected the body of this file, so the false claim outlived its own correction **in the header nobody re-read**. Re-measured live: `catalog_snapshot_age()` returns **200** with the snapshot rebuilt at **2026-09-08T03:20:30Z** (the seed from #746's own merge), and `get_catalog()` returned **200 on 3 of 3** at **TTFB 0.79–2.18 s** on a 10.6 MB payload. ⚠️ **`get_catalog_built()` still returning `57014` is the migration WORKING** — the slow builder runs once per seed and nothing serves it to a phone; see § SQL pastes owed. 🔴 **The durable lesson is § READ FIRST's own, paid for twice in one day: an owner-owed item can clear while a session is mid-flight, and a header is where a corrected fact goes to survive. Re-probe; never quote a live-system fact from this board.** ⚠️ **The seed's `refresh_catalog_snapshot()` call is guarded by `to_regprocedure`, so with the SQL unpasted it skips the refresh, raises a notice and still finishes GREEN — ask `catalog_snapshot_age()`, never a green seed job.** Earlier the same session — **both content PRs have MERGED and #744 is verified live: the Supabase RPC and the gh-pages mirror each serve 130 places with The Gilder Center present, its 3 members all on the place coordinate, 0 members off their place coordinate catalogue-wide and 0 link pins wrongly inside `tours`.** **The two: [#744](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/744) made the Gilder Center a place (places 129 → 130, closing the last stack-cap finding from the Studio Gang batch), and [#745](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/745) added 28 link pins across 14 countries — eleven of them new to the catalogue, the largest expansion any batch has produced. #745 raises one owner decision: Griffith Observatory now sits exactly at `TourSetMap.maxStacked = 3` with no headroom.** ⚠️ **#744 claimed `archive/HANDOFF-260907.md` while #745's CI was running, so #745's handoff renumbered to `-2`, and both sides edited the Key-facts counts — re-derive rather than quoting them.** Earlier, session 146 — **the catalog RPC was found failing 4 calls in 12 with a statement timeout; the fix merged as #742 and carries an owner SQL paste that must come AFTER the merge**. Earlier the same day, session 145 — **[#740](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/740) MERGED (squash `62b662b4`): four Miami/Little Rock places, catalogue now 129 places**, after a rebuild onto the `main` that session 146's [#739](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/739) had moved. Earlier, session 146 — **four places for the sites at the stack cap (Alcatraz · Hoover Dam · Fort Jefferson · the Leaning Tower of Niles), places 121 → 125, MERGED as #739**. Earlier the same day, session 144 — **41 link pins from TikTok `@itshistoryonair` MERGED as [#737](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/737)**, after [#738](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/738) moved `main` underneath it. ⚠️ **Re-derive catalogue counts rather than quoting them — three sessions shipped content the same day.**)

**⚠️ This board is no longer polled on a timer.** The coordinator session ran a 25-minute check
from 04:50 to 12:25 and found something worth reporting on two of fifteen ticks, at roughly 20k
tokens a tick — so it is now **on demand** (owner decision, 2026-08-20). It goes stale the moment
a parallel session merges something. **Re-derive before trusting it**, per the update rule above.

---

## 1. Awaiting owner — device review



🔴 **OPEN — [#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776) — ask 34 bytes before downloading 3.4 MB. WAITING ON YOU SINCE 9 SEP; NO LONGER CONFLICTED.**
  - **What it does:** before pulling the catalogue, the app asks `catalog_snapshot_age()` — **34 bytes** — and skips the download when nothing has changed. It is the *frequency* half of the egress fix; [#795](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/795), now merged and live, was the *size* half.
  - ⚠️ **It was conflicted for two days and a conflicted PR shows NO checks here, so it looked pending rather than blocked.** Re-tested 2026-09-12: **merges cleanly**, 35 commits behind `main`. Nothing is stopping it but a review.
  - **No SQL to paste** — `catalog_snapshot_age()` already exists and is already granted to `anon`.
  - **The device check is two minutes:** open the app, close it, reopen it with nothing changed → content still correct. Then after a content merge, reopen → the new content arrives.
  - ⚠️ Touches `Data/*.swift`, the launch path, so it is code-class: **explicit OK plus that device check**. When this kind of code goes wrong the symptom is not a crash but an app showing old content or nothing.

🔴 **This section is for what is STILL waiting on the owner. It is not a log.**
41 finished items — every one whose pull requests GitHub reports as
merged or closed — moved verbatim to
[`archive/STATUS-HISTORY.md`](archive/STATUS-HISTORY.md) on 2026-09-08. Nothing
was deleted.

They had grown § 1 to **147,843 of this file's 205,618 bytes (72%)**, which is
precisely what this file's own header forbids: *"when an item here is finished,
it leaves this file… never let this file grow a history section."*

⚠️ **Four of them were still labelled `OPEN` while GitHub had them merged**
(#762, #748, #715, #691), as was Riverside Church, whose branch is gone and
whose place is in the catalogue. A label is not a state. **Re-derive before
trusting any line here:**

```bash
gh pr list --state open      # or the API; this board goes stale on every merge
```

✅ **CLEARED — the last `@urbanistariel` link is placed (2026-09-09).** The owner was asked where
`7255575696582446378` ("buildings that look like the Parthenon — they're everywhere") should go and
answered: **the Parthenon itself.** It ships as **The Parthenon: Copied Everywhere**, on the exact
coordinate of the existing `The Parthenon` pin, so the two form a **2-card coincident stack against
`TourSetMap.maxStacked = 3`** — one marker, headroom kept. **linkPins 1,550 → 1,551.** All 62 of the
batch's links are now live; nothing from it is owed.
  - ✅ **RESOLVED — the owner asked for a place, so `The Parthenon` is one** (places 140 → 141,
    `atlas-place:athens:the-parthenon`). All three pins are its members and collapse to a single
    marker. **Making it required moving `The Parthenon: The Missing Roof` 9.7 m onto the place
    coordinate** — `validate-tours.swift` hard-errors on a member whose `stops[0]` is off it, so a
    place cannot merely gather nearby pins. The Erechtheion (89 m) and the Theatre of Dionysus
    (147 m) keep their own pins, correctly.

🔴 **[#762](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/762) IS MERGED — kept here ONLY for its unresolved [#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) follow-ups below (a third Tower Bridge entry, a hero-filename collision). This item said `OPEN` for a day after it merged.**

Originally read:

> 🟡 **OPEN — [#762](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/762) — twenty-seven `@urbanistariel` link pins (session 150, 2026-09-08).** The owner sent 28 TikTok links; **27 ship, 1 is refused** because TikTok returns a completely empty oEmbed record for it (no author, no title, no thumbnail), so there is no hero to crop. **linkPins 1,426 → 1,453 · `tours`, `makers` and `places` otherwise byte-identical.** Content only — **auto-merge class**, squash on green CI.
 — twenty-seven `@urbanistariel` link pins (session 150, 2026-09-08).** The owner sent 28 TikTok links; **27 ship, 1 is refused** because TikTok returns a completely empty oEmbed record for it (no author, no title, no thumbnail), so there is no hero to crop. **linkPins 1,426 → 1,453 · `tours`, `makers` and `places` otherwise byte-identical.** Content only — **auto-merge class**, squash on green CI.
  - 🔴 **Three Met pins would have been a 4-deep stack at one coordinate** against `TourSetMap.maxStacked = 3`, one silently unreachable. Folded into the existing **Met place** instead (2 → 5 members), so they collapse to one marker. Catalogue-wide, **no group exceeds the cap** once place members are excluded.
  - 🔴 **Two coordinate defects caught that no downstream check would have.** A naive short Plus Code recovery put `P272+V9 New York` at longitude **−74.999** (rural Pennsylvania) — fixed with the real OLC `recoverNearest`; and `Park Avenue Plaza, New York` geocoded to **a village near Corning, 250 km upstate**, a real place that reverse-verification would have confirmed. **A bounding box per caption-named city is what caught it: 27/27 in box.**
  - ⚠️ **A hero filename would have overwritten a live file belonging to the then-unmerged 83-pin batch** (same creator, different post about Mount Prospect Park). Renamed; that batch has since merged as **#758**, and this branch was rebuilt on it — main's `Tours.json` taken wholesale and the idempotent assembler re-run.
  - ⚠️ **Flagged, not fixed:** `The Met's Design Flaw` sits 17 m off the Met place and is not a member, so it remains a lone pin beside it. Pre-existing on `main`; one line, owner's call.
  - ✅ **Five more places on owner instruction, closing every at-cap group in the catalogue (places 132 → 137):** Eldridge Street Synagogue · ParkLife · Awaji Yumebutai · Equilateral House · M+ Museum. 🔴 **The owner corrected the report while asking** — *"M+ HAS 4 TOURS"* — and was right: the sweep grouped by **exact coordinate**, so Atlas Studio HKG's `M+ Museum | M+博物館` at **54.3 m** was invisible to it. **An at-cap check keyed on exact equality understates any group with an Atlas tour nearby.** ⚠️ **Eldridge Street's anchor is geofenced** and already sat on the pins' point, so nothing moved there; only M+'s three link pins moved, onto their anchor tour. **Deepest loose group catalogue-wide is now 2.**
  - 🔴 **[#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) is still OPEN** — the owner asked whether its 54 pins had been sent; they had, and are still unmerged. **Verified link by link** (every `vm.tiktok.com` short link resolved through its redirect first), 49/49 present. One coordinate disagreement noted there: the `QHVR+HQ Nob Hill` code re-sent for San Francisco *Chinatown* is **153.6 m** from the live pin, which kept its August coordinate.
🆕 **OPEN — `claude/new-tour-links-zaguqm` — two places on owner instruction: United Nations Headquarters (6 members) and Tower Bridge (2) (session 149, 2026-09-08).** Owner asked for both after #758 merged; the owner's own count of "6 tours" at the UN was **correct and re-derived** — 5 new `@urbanistariel` pins plus the existing Atlas Studio NYC `United Nations Headquarters` tour. **places 130 → 132.** Content only. Diff **58 insertions / 24 deletions** — the deletions are the six member coordinates being moved onto their place point, which `validate-tours.swift` requires exactly.
  - 🔴 **THE GEOFENCED TOUR DID NOT MOVE.** Atlas Studio LDN's `Tower Bridge` is **`geofenced`**, so the place was put on **its** coordinate and the link pin moved onto it — the pin moves, never the tour. The UN anchor is `manual` and also left where it was. Asserted after the edit: both anchors unmoved, and the only six entries whose coordinate changed are the pins. The mover **refuses a non-`manual` stop** rather than trusting the author.
  - ⚠️ **The UN place supersedes #758's four-feature spread.** That spread existed only to dodge `maxStacked = 3`; a place collapses them into one marker, so all six now sit on one point as the validator requires.
  - 🔴 **[#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) CARRIES A THIRD TOWER BRIDGE ENTRY AND IT IS NOT IN THIS PLACE.** It could not be — `tourIds` must reference a tour already in the catalogue. **Whoever merges #749 must add its `Tower Bridge` pin to the `Tower Bridge` place AND move it onto `51.5055,-0.0754`**, or it draws a second marker beside the place. That also resolves the duplicate-title finding, since #749's pin is titled `Tower Bridge` exactly like the Atlas tour.
  - ✅ Mirror **selftest 32/32, control clean**, then **0 errors / 0 warnings across 1,552 tours + 1,426 pins + 132 places**, exit read directly. Place ids `uuid5(NAMESPACE_URL, "atlas-place:<slug(city)>:<slug(name)>")`, **the scheme asserted against a live place before minting**. Both place heroes re-use existing gallery images confirmed **HTTP 200**; addresses taken from OSM reverse geocodes, not recall.


🆕 **OPEN — [PR pending] `claude/new-tour-links-zaguqm` — eighty-three link pins from TikTok `@urbanistariel` (session 149, 2026-09-08).** 83 short links → **82 distinct posts → 83 pins**, because one Harry Potter post carries two Edinburgh Plus Codes (The Elephant House + George Heriot's School) and ships under the documented shared-post fragment scheme with **one shared hero — so 82 hero files cover 83 pins**. **linkPins 1,343 → 1,426 · `tours`, `makers` and `places` byte-identical** (the `@urbanistariel` maker row already existed and is byte-identical, so makers stay at 353). Content only — the auto-merge class. **Malta and Croatia are the catalogue's 60th and 61st countries.**
  - 🔴 **A HERO FILENAME COLLIDED WITH THE UNMERGED [#749](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/749) AND WOULD HAVE OVERWRITTEN A LIVE FILE.** Both batches carry a different `@urbanistariel` post about **Tower Bridge**, and the handle suffix cannot disambiguate one creator posting twice about one venue. Mine was renamed to `tower-bridge-glass-walkway-urbanistariel_hero.webp`; #749's live bytes were never touched. **A batch running beside another must diff its hero filenames against the gh-pages tree, not just against `main`.**
  - 🔴 **MOCA WOULD HAVE SHIPPED A PIN NOBODY COULD TAP.** Three of these posts are the Museum of Chinese in America and `main` already carries one, giving **depth 4 against `TourSetMap.maxStacked = 3`** — `prefix(3)` silently drops the rest. `Two Centuries of NYC's Chinatown` moved **405 m** onto OSM's Chinatown neighbourhood node, which is what its caption is actually about. **Nothing is over the cap; seven clusters sit exactly at 3.**
  - ⚠️ **THE FIVE UNITED NATIONS POSTS ARE SPREAD ACROSS FOUR REAL OSM FEATURES** (Headquarters ×3, Secretariat, complex centroid) so all five stay reachable. The spread keeps them tappable; it is **not** a claim about interior precision. **Owner may prefer a place instead.**
  - ⚠️ **ONE COORDINATE DOES NOT MATCH ITS CAPTION AND SHIPS AS SUPPLIED.** `J4X6+X6` puts the Black Death / first-quarantine post on the **Homeland War Museum on Mount Srđ, ~950 m above Dubrovnik's Old Town**. Kept as the owner supplied it, flagged rather than moved — the Seronera precedent.
  - ⚠️ **`Tower Bridge` is titled identically on `main` (an Atlas Studio LDN tour) and in #749 (a link pin), on one point.** Not this batch's to fix — mine reads `Up Inside Tower Bridge` — but it is the Railway Museum duplicate-title shape and #749's to resolve.
  - ✅ Mirror **selftest 32/32, control clean**, then **0 errors / 0 warnings across 1,552 tours + 1,426 pins + 130 places**, exit code read directly. `make-link-pin.py --selftest` **71/71 with Pillow installed first** (a bare container reports 62/62, which reads as a pass and is not one). gh-pages `d232ae3a`: remote head re-read in the same command as the push, status via `PIPESTATUS`, diff **exactly 82 additions / 0 modifications / nothing outside `images/`**, and **all 82 blobs confirmed byte-identical in the pushed tree**.


🔴 **Do NOT wire them on "the links work on my phone" alone.** The owner is signed in; the app's
`WKWebView` is not. With a null context the app's embed — `instagram.com/reel/{code}/embed`, the same
URL — renders **blank**, and there is no `display_url` so **no hero exists either**. A forced pin looks
right to the owner and is a dead card for every other user. **Verify the field, not the phone.**

**⚠️ It is an ACCOUNT-level block, so one post answers for all six**: 25 posts from 21 other creators
carried a full context in the same runs; all 6 from this one creator carried none.

**If the subjects matter sooner:** the owner rates these as quality tours, and an Atlas tour beats a link
pin anyway — it works offline, downloads, and fires at a geofence, none of which a link pin can do.
⚠️ Toronto already has **42** Atlas tours, so check for overlap before drafting.


🟡 **(superseded, kept for the decisions)**
Owner sent 31 Instagram reels as "Toronto links 260901". **linkPins 565 → 590 · makers 226 → 246**;
tours and places unchanged. **Toronto's first pin batch** — 42 Atlas tours, zero pins before.
Committed `f62daa8c` and pushed; gh-pages `a506a5b` with all 25 heroes hash-verified live.
**PR #698 opened on owner instruction — CI is the authoritative validator and nothing compiled locally.**
🔴 **Links 1, 2, 4, 8, 9, 10 are ALIVE, not dead — the owner opened them on their phone, correcting an
over-read on my part.** The real cause is `contextJSON: null` on the embed page: Instagram withholds the
media context from a logged-out reader. **They still cannot ship** — the app builds that same embed URL
and is logged out, so a pin would render blank and has no hero either. **NOT WIRED**; nothing was
removed. ⚠️ **Owner can settle WHY by sending the creator handles** — a private account says so publicly.
**Three things remain the owner's call:** (1) the **Cube House pair** ships as two pins, which takes
`check-place-candidates.py` **0 EXACT → 1** — honest, neither pin nudged, one line removes either;
(3) **three weak heroes**, **One King West** sharpest (its frame is the CN Tower, not the vault);
(4) **four place candidates** — ROM 9 m, Casa Loma 11 m, Distillery District 40 m, Osgoode Hall 57 m.
⚠️ **`Diminish and Ascend` is pinned at Christchurch though its thumbnail shows Waiheke — owner
decided: *"keep christchurch."* Settled; do not "fix" it.**


🔴 **OPEN, NEEDS AN OWNER DECISION — `MoMA PS1` SHIPS A DEAD HERO IMAGE.** Its
`heroImageURL` returns a hard **404**, confirmed across seven spaced attempts against four
same-host controls that all return 200, so it is not the rate limiting that hid it. **The tour has
no gallery**, so there is nothing to promote in its place (the Castello / DuSable free fix does not
apply) — a replacement has to be sourced through the image pipeline, which means owner picks.
**⚠️ It is the ONLY `upload.wikimedia.org/wikipedia/en/` URL in the catalogue** — an English
Wikipedia *local* upload rather than a Commons file, which is where non-free/fair-use images live
and where deletion is routine. Everything else Wikimedia-hosted is on Commons and healthy. **One
dead image in 5,848**, found only because #659's fetch fix stopped error-page bodies being hashed
as though they were pictures.

## 2. Blocked on owner — outside the repo

**✅ CLEARED 2026-09-12, 21:17 UTC — the owner pasted the SQL and the duplicates are gone.**
**Verified after the paste, four ways:** the row count went **3,441 → 3,439** (exactly two fewer),
both pin ids return empty, the orphaned `Instagram @pacificmodernism` maker row is gone — so the
conditional delete fired, confirming it held no other pins — and **`catalog_snapshot_age()` reads
`2026-09-12T21:17:56Z`**, which is the part that matters: the RPC serves a materialised snapshot, so
the paste only reaches a phone because that last line rebuilt it. ✅ **Both TikTok replacements
survive** (`145 Natoma`, `The Wind Harp`, one each on maker `537cc385`), which is the check worth
doing after any deletion — the risk is removing the survivor, not the duplicate.

**What it was.** Found the same day by diffing the live `tours` table against `Resources/Tours.json`:
the database held **3,441 rows against the catalogue's 3,438**, and every catalogue entry was
present, so nothing was *missing* — three rows were *extra*. Two of them are the `@pacificmodernism` **Instagram** pins that
[#804](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/804) replaced with TikTok equivalents:
**145 Natoma Street** and **The Wind Harp**, both San Francisco. `seed_from_toursjson.py` is
**upsert-only**, so deleting them from `Tours.json` reached the gh-pages mirror and the bundled seed
and **never reached Postgres — the app's primary source.** The snapshot is rebuilt from that table,
so the map is serving the old pin and the new one on the same spot.

  - **The fix was `backend/remove_pacificmodernism_instagram_duplicates.sql`**, written by
    [#805](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/805) for exactly this. It named the two
    ids explicitly and ended with `select public.refresh_catalog_snapshot();` — **that last line was
    load-bearing**, and the snapshot timestamp above is the proof it ran.
  - ✅ **The third extra row is NOT a defect and must not be deleted.** `Pigalle Duperré Basketball`
    (Paris) belongs to maker **"Wes the Wanderer"**, has a real `user_id`, a Supabase Storage hero and
    `is_private = true` — an **in-app maker upload**, which lives only in Postgres by design. A
    catalogue-vs-database diff will always show maker uploads as extra; that is correct behaviour.
  - 🔴 **The durable gap was the process, not the SQL, and it outlives this item.** #805 merged on
    10 Sep carrying an owner action, and no session put it in § 2 — so it sat owed to nobody for two
    days while the defect it fixes was live on the map. **A merged PR that needs an owner paste is not
    finished; it moves here.** The paste itself took the owner under a minute once it was asked for.
  - ⚠️ **This is only findable by diffing the database against the catalogue** — `validate-tours.swift`
    passes, CI compiles, every URL 200s, and the app shows two pins where one belongs. The diff recipe,
    with the two traps that make it lie, is in `CLAUDE.md` § Egress. **Worth running after any content
    removal.**

**🔴 THE SUPABASE OVER-QUOTA EMAIL WAS OUR OWN TOOLING, AND THE LINE ITEM WAS MINE.** The owner was
emailed on **2026-09-08** for exceeding the free egress quota. The largest single cause was a check
**I added to `scripts/session-start.sh` the same day** ([#761](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/761)):
it called `get_catalog` **four times per session** to read a status code and threw every byte to
`/dev/null` — **~44 MB of egress at the start of every session**, on a script Automation Rule #1
makes every session run. I never measured the payload I was pulling. ✅ **Fixed by another session in
[#770](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/770)**: `--compressed --max-filesize 2000`
takes the same check to **8 KB**, with the timeout detection proved intact rather than assumed. The
standing rule and the cheap alternatives are now in **`CLAUDE.md` § Egress** — read it before adding
anything that touches the RPC.

⚠️ **I nearly repeated it the next morning**, firing a 20-call uncompressed sample (~220 MB) before
recalling the incident; it was killed a few calls in, so **some tens of MB were still spent.** The
durable lesson is narrower than "be careful": **a probe that discards the response still pays for
it, and `-o /dev/null` hides that from you.** ⚠️ **And the quota is not fixed, only postponed** —
#770's own arithmetic puts a daily active user at **~240 MB/month**, so roughly **20 users** are
back over it with the fix in. The durable answer is asking **"what version is the catalogue?"**
before downloading it — **designed** in [#773](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/773)
(`docs/catalog-version-check-design.md`) and **BUILT** in
[#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776): a **34-byte** probe of
`catalog_snapshot_age()` before the **3.4 MB** download, both measured live, with 8 tests and
**no SQL for the owner** (the function already exists and is already granted to `anon`).

🔴 **#776 IS CONFLICTED AND IS THE ONE TO UNBLOCK.** It is the durable fix for the thing that
generated the quota email, it is finished, and it is sitting at `mergeable_state: dirty`. ⚠️ It
touches `Data/*.swift`, so it is **NOT auto-merge class** — it needs owner OK plus a device check,
and its own author says why: *"when this code goes wrong the symptom is not a crash but an app
showing nothing or showing old content."* The device check is two minutes — reopen with nothing
changed (content still right), then reopen after a content merge (new content arrives).

⚠️ **It does not fix the size, only the frequency.** When anything changes the app still downloads
all 1,552 tours. The larger step after it is dropping `transcriptText` (**38%** of the payload) and
`longDescription` (**18%**) — deferred deliberately, as a breaking catalogue change.

**🔴 A DEAD TIKTOK LINK NEEDS RE-SHARING (2026-08-27).** `https://www.tiktok.com/t/ZP8vkb5bP/`, the twentieth of the "SF Architecture" batch, resolves to a real id (`@aggie.sanfrancisco/video/7660328152421387534`) and then fails everywhere: an empty oEmbed shell on three spaced attempts (no `thumbnail_url`), and a 367 KB *"Video currently unavailable"* page with zero `og:` tags. No caption means no subject and no location; no thumbnail means no hero, and a pin with no hero cannot ship. **Nothing on our side recovers it — only the owner re-sharing a live link.** ⚠️ It is an ordinary `/video/` post that has gone, **not** a `/photo/` carousel; that limitation is separate and permanent.


Nothing here can be done from a session. Ordered by what blocks the most.

| Item | Why it matters | State |
|---|---|---|
| ~~**App Store 1.1 review**~~ | ✅ **APPROVED AND LIVE** — owner-reported 2026-08-28. Submitted 2026-08-18 03:22 UTC on build 66. See § 1d. | ✅ Done |
| **Stripe platform review** | **Round 5 submitted 2026-09-11.** First response able to show a product: the Website URL is now the **App Store listing**, not `dozent.world`. 🔴 Two claims from rounds 1–4 had become FALSE and were removed — "no transactions processed" (one $0.99 sale on release day) and "all content is first-party" (1,717 pins credit ~343 third-party accounts). Every round is recorded verbatim in `docs/stripe-review.md` — **read it before answering anything further, and re-verify each claim against the live system first.** | ❓ Awaiting Stripe reply |
| ~~**IAP tiers blocked**~~ | ✅ **ALL 14 ARE READY TO SUBMIT (owner, 2026-08-31)** — the nine that had sat in `MISSING_METADATA` since August, plus four new ones (**599 / 799 / 1299 / 1799**). SQL applied, products created, screenshots uploaded, all added for review. **They ride with the 1.1.1 submission.** Two findings, both now in the docs: **the review screenshot must be 1242×2208** (the 5.5″ size — 1320×2868 and 1290×2796 were both refused, and CLAUDE.md had the wrong value recorded), and **one image covers all fourteen** — Apple wants to see where the purchase appears, not what it costs, so the per-price screenshot rule was this project's own over-caution. | ✅ Done |
| **App Store badge: white or black** | The **white** badge shipped on `dozent.world` (Apple's recommendation for dark grounds). The **black** variant carries a white hairline border and sits more quietly on the site's black. Both are Apple artwork, both in guidelines. Comparison rendered and sent 2026-09-11. **One-line change either way.** | 🟡 Cosmetic, owner's call |
| **Apple tax / banking forms** | Complete in App Store Connect → Business → Agreements, Tax, and Banking? **No API — cannot be checked from a session.** Changes nothing at one sale (~$0.84 net, far below Apple's threshold) but would quietly block payment once volume builds. | 🟡 Owner check owed |
| **EU trader declaration** | App declared **non-trader** while selling IAP tiers into EU cities. Declaring trader publishes an address. | 🔴 Decision owed |
| **LLC vs sole proprietor** | Gates the Stripe payout path, and collapses the EU-trader and the AHWY/EHKY-initials trade-offs at once. | 🔴 Decision owed |

### SQL pastes owed (Supabase SQL Editor, project **Dozent**)

✅ **Applied:** `add_country.sql` (Countries row live) · `restore_catalog_keys.sql` (places, priceTier,
isPrivate restored 2026-08-20) · **`pull_la_duplicates_260830.sql` (owner ran it 2026-08-30 —
verified against the live RPC, not the SQL Editor's success line: all four deleted rows gone, all
three survivors present, `TikTok @thedesigndetourist` still at 19 pins, 0 pins wrongly inside
`tours`, `priceTier` and `isPrivate` both intact. **Nothing is owed here — do not ask again.**)** ·
**`catalog_snapshot.sql` (APPLIED — measured live 2026-09-07, not reported by anyone. Nothing is
owed here; do not ask the owner to paste it again.)**

🔴 **THE `catalog_snapshot.sql` CORRECTION, because this file said the opposite for a day and a
session repeated it to the owner.** Measured against the live database rather than inferred:
**all three of the migration's functions exist** — `catalog_snapshot_age` (200, reporting a refresh
at **21:44 UTC**, i.e. the seed from #743's own merge), `refresh_catalog_snapshot` (401 to anon,
which is correct — the seed calls it), and `get_catalog_built` (the builder, renamed aside).
**`get_catalog_built` still returns `57014 canceling statement due to statement timeout`** — and
that is the migration WORKING, not failing: the slow builder now runs once per seed, and nothing
serves it to a phone. **`get_catalog()` itself returned 200 on 14 of 14 calls**, TTFB **1.38–2.35 s**. ⚠️ **That 14/14 was a lucky window and is superseded — see the #742 row above: a longer sample puts it at roughly 1 failure in 10.**
⚠️ **The "sub-second" expectation in the session-146 note was optimistic and should not be read as a
failure signal on its own** — the payload is **10.6 MB**, of which ~0.5 s is transfer; a single-row
lookup of a 10.6 MB `jsonb` value out of TOAST is not free. **The signal that the fix landed is that
the builder times out and the served endpoint does not.** ⚠️ **The second half of that criterion does NOT hold: the served endpoint still times out on roughly 1 call in 8.** The builder moving off the request path is real; the endpoint being reliable is not yet true. ⚠️ **A second, independent 20-call sample the same morning agrees (3 failures in 20), and its latency band is what identifies this as the SAME ceiling rather than a new fault:** successes ran **0.75–5.8 s** TTFB while **every failure landed at 4.3–4.8 s**, still sitting on the anon statement timeout exactly as the pre-fix builder did.

🔴 **RE-MEASURED 2026-09-08 — THE FAILURE RATE HAS GONE BACK UP, AND THERE IS A MECHANISM THAT
PREDICTS IT WILL KEEP GOING UP.** Three unbiased samples across half an hour, all against
`get_catalog()`, the source the app reads **first**:

| Window (UTC) | Result | Failure TTFB |
|---|---|---|
| 21:53–21:55 (≈5 min after a snapshot refresh) | **9 fail / 20** | 4.6–9.6 s |
| 21:59–22:00 | **5 fail / 20** | 3.7–6.0 s |
| earlier pass | **3 fail / 8** | 4.5–5.6 s |

**Pooled: 17 of 52 ≈ 33%.** Excluding the window just after a refresh (the documented transient
class): **8 of 32 = 25%.** Either figure is far above the **~1 in 8** recorded above from earlier
the same day, and the higher one matches the **pre-fix** rate (4 in 12). Every failure is
`500 / 57014 canceling statement due to statement timeout`.

**The snapshot is genuinely in use throughout** — `catalog_snapshot_age()` returned 200 with a
timestamp minutes old in the same passes — so this is **not** the paste being lost, and #742 is not
broken. ⚠️ **The mechanism is that the snapshot ROW keeps growing.** The payload measured **10.88 MB**
today against **10.6 MB** when the fix was assessed, because the catalogue went from ~1,168 to
**1,426 pins** in between. `get_catalog()` is a single-row lookup of one `jsonb` value out of TOAST,
and that read is already sitting *on* the anon statement timeout — so **every content batch pushes
it further over.** Successes have drifted later too (2.1–6.8 s TTFB today against 0.75–5.8 s before).

**What this means in practice, stated plainly:** users are not stranded — `RemoteCatalogLoader`
falls through to the gh-pages mirror, which is healthy (**11.7 MB, HTTP 200, 0.84 s**) and
byte-current with `main`. The cost is that a third of cold launches take the slow path.
**Do not report this as fixed.** ⚠️ **And do NOT reach for gzip — it is already on, and checking
took one command:** with `Accept-Encoding: gzip` the same call returns **3.6 MB instead of 10.9 MB**
(`content-encoding: gzip` in the response), and `URLSession` sends that header by default, so the
app is already getting the compressed body. **Compression cannot help here anyway** — the failures
are at TTFB, i.e. inside the query, before a byte is sent.

🔴 **CORRECTION 2026-09-09, AND IT IS ABOUT THE MEASUREMENT, NOT THE ENDPOINT.** A cheap probe the
next morning — the one `CLAUDE.md` § Egress now prescribes, `--compressed --max-filesize 2000` —
returned **12 of 12 OK** against yesterday's 25–33%. **That is not evidence the endpoint improved,
and must not be read as one:** yesterday's samples pulled the **whole uncompressed 10.9 MB body**
on every call, today's abort after ~2 KB. Those are different requests, so the two numbers are not
comparable. What can be said is narrow and true: **the liveness probe reports healthy right now,
and `catalog_snapshot_age()` is fresh.** ⚠️ **A plausible mechanism cuts against the paragraph above
and is untested:** if any part of serialising 10.5 MB counts inside the statement timeout, then
asking for gzip (3.4 MB) would genuinely help — which would make *"compression cannot help"* wrong.
**Do not spend the egress to settle it** (see the incident below); settle it with the timeout lever,
which costs nothing to try.

The two levers that actually address it, neither attempted yet and neither a code change:

1. **Raise the anon statement timeout** — `alter role anon set statement_timeout = '15s';` (currently
   the failures cluster at 3.7–9.6 s, so the ceiling is what they are hitting). One owner paste.
   Cheapest thing to try first, and it says immediately whether the diagnosis is right.
2. **Serve less per request** — split `linkPins` into its own RPC, or add an `If-None-Match`/ETag
   path so an unchanged catalogue is a 304. This is the durable fix, because (1) only buys headroom
   that the next few content batches will eat.

**Not** another attempt at the builder — that part of #742 is working.

| File | Unlocks | Without it |
|---|---|---|
| `backend/saved_places.sql` | Saved places syncing across devices | Saving works, stays on one device |
| `backend/places_photos.sql` | Places serving their own photographs | Optional — the app is correct without it |

## 3. Builds — which run number carries what

🔴 **Build numbers are `github.run_number` and are SHARED across every branch.** Read them back
after dispatching; never promise one in advance. And a build carries its branch's **merge-base**,
not `main` — GitHub reports a PR's base as main's current tip, which is misleading.

| Build | Branch | Carries | Result |
|---|---|---|---|
| **151** | `splash-breathing` | [#836](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/836) draw the splash first (`LaunchDeferredContent`), the zoom back to the solid disc on a rising bright breath, and `main` merged in — including #835's filter row (`6e7c3f3c`); branch current with `main`, version **1.1.2**. ⚠️ **151, not the next after 149** — the filter-chips session took 150; read back from the run | ✅ **VALID at Apple, and owner-verified on device — *"reviewed it. looks great!"*** (2026-09-12). Breathing starts right away, zoom solid; **#836 merged, squash `f669493c`** |
| **150** | `claude/filtering-chip-system-htjq7k` | [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) device-review round 3 — the panel is presented from the MODULE'S OWN WINDOW (`a2eec8c`) | ⏳ **dispatched 2026-09-12 20:01 UTC**, CI run 2338 alongside it. ⚠️ 150, not 149 — another session again took the number in between |
| **149** | `splash-breathing` | [#836](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/836) the timing fix — the breath's floor counts from the splash's first drawn frame, one full breath (`376461ec`); branch current with `main`, version **1.1.2**. ⚠️ Owner expected **148** — a parallel session had taken it; **149 read back from the run** | ✅ **VALID at Apple** (uploaded 2026-09-12 13:02 PDT). ⚠️ **Owner: breathing visible, but *"i had to wait a long time for it"*** — the static launch picture lingered because `ContentView` had to be built before the splash could draw. **Fixed on the branch** (`LaunchDeferredContent`). 🔴 149 also carries the washed-out zoom (since 147) — fixed on the branch too; next build not yet cut |
| **148** | `claude/filtering-chip-system-htjq7k` | [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) device-review round 2 — the panels span edge to edge (`609e4ef`) | ✅ **green (CI 2335 too), and owner-reviewed on device.** It produced one finding — the module visibly vanished ~130 ms BEFORE the sheet arrived — which 150 fixes. ⚠️ **148, not 147** — `run_number` is shared across branches and another session took 147 between dispatches. Exactly why the board's rule is to read the number back |
| **147** | `splash-breathing` | [#836](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/836) the splash circle breathes again, on Core Animation (`8f1db87f`); branch current with `main`, version **1.1.2** against a live 1.1.1 | 🔴 **VALID at Apple, but owner saw NO breathing on device** — *"i really dont see any breathing"*. Cause measured in the sim with timestamps: the gate's clock starts at mount, but the splash's first frame lands ~4.9s later (main thread building the app), so it drew for only **~0.77s** — one dip — before hand-off. Fix pending: start the floor at the splash's first drawn frame |
| **146** | `claude/filtering-chip-system-htjq7k` | [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) device-review round 1 — the panels now cover the bottom module, plus four spacing/layout fixes (`b4dfb511`) | ✅ **green, and owner-reviewed on device — *"it's good"*, with one further note** (nothing should float but the bottom module), which is what 148 carries. CI run 2330 green on the same commit |
| **145** | `claude/filtering-chip-system-htjq7k` | [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835) the filter row: All · Format · Price · Dozents · Tags (`fc8ff92`) | ✅ **green — built, signed and uploaded 18:32 UTC; on TestFlight, awaiting owner device review.** It compiled **first time** despite never having been built in-session. Build notes attached at dispatch, so TestFlight carries them in *What to Test* |
| **143** | `creator-tours-china-visibility-wmnho7` | [#785](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/785) the link-pin embed failure state (`ef108754`) | ✅ **owner-verified — *"Build is live. I tested (not super extensively), think it works"*; #785 merged as `6a594081`.** ⚠️ Testing was the owner's own words *not super extensively*, so the false-positive case (the message appearing over a pin that works) is **watched, not proven** — see § 6 |
| **141** | `bottom-module-missing-45z6ep` | The same fix at **1.1.2** (`e6570bdc`) — 140's payload plus the version bump | ✅ **owner-verified — *"BUILD IS LIVE. MERGE"*; #728 merged as `4da52445`** |
| 140 | `bottom-module-missing-45z6ep` | [#728](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/728) the bottom module was HIDDEN, not uninstalled, with `main` merged in (`b52315f8`) | 🔴 **rejected at upload — 1.1.1 is now APPROVED, so its train is closed** (90186 *"Invalid Pre-Release Train"* + 90062). ✅ **It compiled and signed cleanly** (`build_app` 219 s); only the upload step failed. **This is the documented per-release cost, and it is also the only signal a web session gets that 1.1.1 shipped** — a closed train means Apple approved it. Superseded by 141 |
| **138** | `map-expand-control` | [#671](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/671) the expand control on every inline map, `main` merged in (`e0799d8c`) | ✅ **owner-verified — *"LOOKS GOOD"*; #671 merged as `01c70f63`** |
| **137** | `instagram-player-fit` | #662 the Instagram crop + fullscreen scrubber, `main` merged in, **marketing version 1.1.1** | ✅ **owner-verified — *"works! thank you"*; #662 merged as `845f0d86`** |
| 136 | `instagram-player-fit` | Same code at **1.1** (`49ac5382`) | 🔴 **rejected at upload** — 1.1 is released, so Apple refuses the version string |
| **134** | **`main`** | #622 the real fullscreen fix — the video's own window (`e22dba7`) | ✅ **install this** |
| 133 | `link-fullscreen-probe` | Same fix + the temporary readout (`f6aaf78c`) | ✅ owner-verified — *"that seem to be done the trick"* |
| 132 | `link-fullscreen-probe` | `isElementFullscreenEnabled` theory + probe (`839d2296`) | 🔴 wrong theory — probe proved it |
| 131 | `link-fullscreen-probe` | The probe readout alone (`773727ae`) | ✅ diagnostic — this is what cracked it |
| 130 | **`main`** | #617 the `onDisappear` guard (`adbe3b94`) | 🔴 shipped as "the fix"; was not |
| 129 | **`main`** | #611 withdraw the module on `fullscreenState` (`8df37de8`) | 🔴 shipped as "the fix"; was not |
| 128 | **`main`** | Everything, from the tip (`43c9411a`) — functionally identical to 127 | ✅ superseded |
| 127 | `open-source-ai-integration-pxuxdh` | #605 search + map, merged as `43c9411` | ✅ superseded |
| 126 | `instagram-best-effort` | #606 Instagram, merged as `2ecb95a9` | ✅ owner-verified — superseded |
| 125 | `open-source-ai-integration-pxuxdh` | #605 search, branch caught up to `main` (`73364503`) | ✅ superseded |
| 124 | `open-source-ai-integration-pxuxdh` | Merged app code + #605's then-unmerged search work (`fc94f197`) | ✅ superseded |
| 123 | `open-source-ai-integration-pxuxdh` | Same work, earlier commit (`2f1784e9`) | ✅ superseded |
| 122 | **`main`** | #603 Instagram tap (`e106fd3e`) | ⚠️ carries the behaviour #604 withdrew |
| 121 | `new-task-i2k12e` | #601 list-page grid + sort (`33d2b0c4`) | ✅ owner-verified — *"121 went live. Looks good."* |
| 120 | `new-task-i2k12e` | #600 place-page grid + sort (`ad1ff15e`) | ✅ owner-verified — *"120 is live. works"* |
| 119 | `new-task-i2k12e` | Same work, one commit earlier (`8b4e6cdc`) | ✅ superseded |
| 118 | **`main`** | #597 link pins split out + #598 decode tolerance (`d80465b`) | ✅ superseded — owner-verified, pins visible |
| 117 | **`main`** | #592 WALK pill, on the real AMNH pins (`2a47e28`) | ✅ superseded — shows no link pins |
| 116 | **`main`** | #584 link pins + #585 YouTube/Short fixes (`233eb912`) | ✅ superseded — shows no link pins |
| 115 | **`main`** | #583 the stale hero fix (`8f5748b7`) | ✅ superseded — **un-frozen by #597** |
| 114 | **`main`** | Fullscreen video, Swedish architects, Akalla hero, `get_catalog` hardening (`8d2ad947`) | ✅ superseded |
| 113 | `chrome-row-modifier` | #576 chrome row extracted — head merged `main` at 13:14 (`e90d9995`) | ✅ superseded |
| 112 | `color-mismatch-elements-pj2ptt` | #573 chrome row made opaque | ✅ merged |
| 111 | **`main`** | #565 architects, #566 launch mark, #567 + #568 offline photographs (`891702fd`) | ✅ last true from-main build |
| 110 | **`main`** | Everything to 22 Aug, plus #563 light mode (`b421bde9`) | ✅ superseded |
| 109 | `launch-performance-animations-df4d7p` | #559 launch sequence (`52a86cfa`) | ✅ superseded by 110 |
| 108 | `launch-performance-animations-df4d7p` | Same work, one commit earlier | ⚠️ superseded |
| 98 | `wizard-comments-round2` | #558 wizard round two (`e0132c90`) | ✅ merged |
| 97 | `wizard-comments-round2` | Same work, one commit earlier | 🔴 **Live and installable, run shows RED, no notes** |
| 96 | `upload-wizard-improvements-ejopz3` | #552 the seven-step wizard | ✅ owner-verified — *"so much better"* |
| 95 | `ellipsis-button-consistency-vdorpi` | Became #555 — Liked on the shared list screen | ✅ merged |
| 94 | `ellipsis-button-consistency-vdorpi` | #553 list page as a layer | ✅ owner-verified, merged |
| 93 | `library-launch-jitter` | #549 Library launch jitter | ✅ merged |
| 91 | `main` | Wizard, Settings, list page, 5:4 heroes | ✅ owner-verified |
| 90 | `tour-upload-polish-qiliop` | #540 + the saved-tour hang fix | ✅ owner-verified — hang closed |

✅ **#552 merged `main` in before merging out** (`a9a3b32`, two real conflicts resolved by hand) — so
the stale-base warning this board carried against build 96 was dealt with by the session itself.


## 4. Branches

| Branch | State |
|---|---|
| `claude/filtering-chip-system-htjq7k` | **Open as [#835](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/835)** — the filter row rebuilt: `TourFilter` (one Equatable value, four groups, the D6 combine rule, contextual counts) + `FilterChipRow` + `FilterPanels`, `TagFilterChipRow` deleted, `Tag.filterChips` → `Tag.panelGroups`, `LinkSource.isInstagramReel`, panel metrics in `AtlasSpacing`, 17 new tests. Spec: `docs/filter-chips-design.md`. **On build 145. Never compiled — CI is the first check.** Waiting on owner device review |
| `claude/optimistic-allen-lb09p8` | **Open as [#830](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/830)** — 7 link pins for TikTok `@kylewilliamdesign` + 1 for Instagram `@ninosbuildings`. The owner supplied 8 links with no coordinates; each was identified by caption (TikTok oEmbed) or, where the caption named nothing (both Instagram reels), by reverse-image-identifying the thumbnail, then geocoded and reverse-geocoded to confirm. Owner declined a second pin for El Nido de Quetzalcóatl (the Parque Quetzalcóatl post also names this adjacent site) and the "Oficina Cueva" post (no publicly identifiable building — it's inside an unnamed Santa Fe, Mexico City tower). Dropped a proposed "Javier Senosiain" tag before merging — not in the app's `Tag.swift` architect vocabulary, and adding it is a code change outside this content PR's scope; the two Senosiain pins keep "Designed by a Master" only. `linkPins` 1,809 → 1,816, makers 385 → 386. `validate-tours-mirror.py` 0 errors (fixed 4 missing Theme/Place-type tags before merging). `check-image-duplicates.py --pins` clean. 8 files (7 heroes + 1 avatar) pushed to gh-pages in one commit (`695dc51`) via a plain `git push` from a worktree — `gh` CLI is unavailable in this session and the GitHub MCP file-write tools proved to mangle binary content (confirmed with a 256-byte round-trip probe before touching real images), hash-verified identical locally; CDN live-check still pending Pages deploy. |
| `claude/elegant-cerf-tsnbrz` | **MERGED as [#828](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/828), squash `0f73983`; branch auto-deleted** — 15 link pins from TikTok `@heyrosiedart` (London), triaged from a 30-link dump the owner pasted in unread. Triage read every oEmbed thumbnail, not just captions — Le Beaujolais, Michelin House, Wilton's Music Hall, Barbican Laundrette and Turquoise Island all named nothing in their captions and were identified from the video frame. `linkPins` 1,794 → 1,809, makers 384 → 385. Owner declined the Penguin Pool at London Zoo (otherwise a confident single-place ID) and left 4 multi-location roundups (swimming pools, ghost signs, music-video interiors) unminted pending a decision on whether to explode them. `validate-tours-mirror.py` 0/0 (fixed 5 missing Theme/Place-type tags before merging); 16 heroes+avatar hash-checked with no duplicates, pushed to gh-pages in one commit (`acb2170`) and hash-verified live on the CDN post-deploy. ✅ **Verified live:** `publish-catalog.yml`'s seed job applied cleanly (`catalog_snapshot_age()` rebuilt at `09:50:57Z`) and Supabase's `tours` table returns exactly 15 rows for `source_author=eq.@heyrosiedart`. No owner SQL owed. |
| `claude/amazing-rubin-pkub81` | **Open (the last three)** — **287 → 288 places**, and 🔴 **the sweep reaches 0 exact / 0 within 25 m open**. `The Gamble House` becomes a place; the `Noguchi Museum` tour and the loose `Habitat 67` pin join theirs. **Every one of these groups exists BECAUSE of a repair earlier today** — the entries always described one site, they simply were not standing on it. 🔴 **0 entries modified: nothing moved.** ⚠️ The Habitat 67 joiner is the pin that **made the place's own 363 m error visible** in the first place. ⚠️ The place is filed under **Pasadena** (where the building is) while its tour keeps its maker's `Los Angeles` — a deliberate split, since that maker files all 42 tours that way. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (three repairs)** — found by running the coordinate check across the remaining near pairs instead of ruling on them by distance. `Gamble House` **343 m** out, `The Noguchi Museum` **497 m** out, and 🔴 **`Habitat 67`'s PLACE 363 m out, carrying BOTH its members with it.** That last one is different in kind: a place's coordinate *is* its identity, so members are pinned to it and **cannot disagree** — the validator and the sweep were both satisfied, and only a **third pin outside the place**, 10.9 m from the real building, made it visible. **A place propagates a coordinate error; check the place against the source, not only its members against the place.** ⚠️ Each repair leaves an exactly-coincident group (3 now, from 0) — that is the truth, and those are place decisions deliberately not taken here. ⚠️ **Not changed, checked rather than assumed:** the Gamble House tour says `Los Angeles` where its pin says `Pasadena`, but that maker files **all 42** of its tours as Los Angeles — a convention, not a typo. Lesson in `docs/lessons.md`. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (the 26–49 m band)** — the owner's seventeen yeses: **271 → 286 places**, 15 new + 2 joins. 🔴 **The band exposes a systematic pattern: in FIFTEEN of the seventeen groups the LINK PIN sits on the OSM feature — usually to 0.0 m — and the Atlas TOUR is the entry that is off.** Pins are geocoded per link; a good number of these tours carry 4-dp coordinates typed once and never checked, the same signature behind all five of today's repairs. Every anchor is therefore *the member OSM agrees with*. ⚠️ **The Ansonia is the exception — BOTH members were off** (44 m and 74 m from OSM's building), so it is anchored on the one that keeps the other inside its own geofence. ⚠️ Also caught: taking OSM's **first** result was wrong for Port Authority (a subway station), Marmorkirken (a metro stop) and Villa Charlotte Bronte (a beauty salon **17 km away**) — the right feature was further down the list, and one group needed a re-query by street address. 11 of 18 moves are past their own radius, by **+1.2 m to +18.7 m**, all approved with distances shown. Sweep **0 exact / 38 tight / 30 near**. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Z1–Z3 + the tight tier)** — **266 → 271 places**. 🔴 **The owner read the list and found a coordinate defect in it** — *"somehow a Lloyd's tour is closer to Leadenhall than to the other Lloyd's"*. Correct, and the **fifth defect of the day**: the `Lloyd's of London` TOUR sat at 4 dp **on The Leadenhall Building**, 92.8 m from Lloyd's. OSM settles it — its `Lloyd's of London` is the Lloyd's **pin** to 0.1 m, its `The Leadenhall Building` is the Cheesegrater **pin** to 0.0 m. ⚠️ **So P1 was never the false positive I called it.** I had recommended declining *Lloyd's / Cheesegrater at 7 m* as "two buildings across a street" — it was this defect in disguise, and declining it would have **buried the bug under a decision**. Repaired, they are 94.5 m apart and P1 stops existing on its own. Also: `Trellick Tower`, `Tate Modern`, and joins to `Walden 7` and `Leaning Tower of Niles`. Every move except the repair is **inside its own geofence — no waivers at all**. Sweep **0 exact / 38 tight / 50 near**. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Z1–Z3)** — the owner's yes to all three exactly-coincident groups: **266 → 268 places**. `UIC Skyspace` (Chicago) and `Kubuswoningen (Cube Houses)` (Rotterdam) become places; the **Obama Presidential Center tour finally joins its own place** — the coordinate repair in #809 put it there and *BAND B ONLY* kept it out. 🔴 **Nothing moved: 0 entries modified**, which is what the exact tier means. ⚠️ Two guards fired and both were right: Z1's two pins share **the same title AND the same coordinate** (title+position is not identity either — they are separated by `sourceAuthor`), and a 6-dp anchor literal read as a **5.5 cm move** against the pin's real float, so the anchor is now taken **from the entry** rather than typed. ⚠️ `Cube House` already existed as a place — **Toronto's**, 6,000 km away and unrelated (Ben Kutner, 1996 vs Piet Blom, 1984) — hence the Dutch name. Sweep back to **0 exact** / 46 tight / 51 near. ⚠️ 3 validator warnings are **pre-existing** on the base (missing tags on pins from other batches), confirmed by running the validator against the stashed base. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (seed prune)** — 🔴 **`seed_from_toursjson.py` could never DELETE a place.** Caught by verifying #809 against the live database: the catalogue held **266** places and the live count read **267**, with **0 tours** pointing at the orphaned `Westerkerk` row that the Jordaan split had dissolved. An upsert-only seed can only ever grow. ⚠️ **Nothing downstream objects** — valid SQL, validator green (it reads only `Tours.json`), CI green, `get_catalog` serves it — the sole symptom is a count check that reads one too many, and that check is what the runbook uses to confirm a publish landed. The prune is emitted **after** the `place_id` reset because `tours.place_id` references `places`. Verified: the generated keep-list is exactly the 266 catalogue ids and Westerkerk is not in it. Lesson in `docs/lessons.md`. `backend/` + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Jordaan split)** — owner: *"split our Jordaan place"*. Both `The Jordaan` tours become their own place and 🔴 **the `Westerkerk` place DISSOLVES** — it only ever existed because the Jordaan **walk's introduction stop sits at the church**, so removing the walk leaves one entry describing Westerkerk, and one entry is not a place. The Westerkerk tour keeps its own coordinate. Anchored on **the walk's own stop 3, titled *The Jordaan***, which is exactly where the single-stop tour sat before Band C — so this **restores** that coordinate rather than inventing one (OSM's `place=quarter` centroid is 106 m away: agreement, not conflict for a neighbourhood). ⚠️ **The only walk move in the whole sweep** — its intro travels 136 m, and that is a fix as much as a cost: stop 0 currently sits on the **identical coordinate** as stop 1 *Westerkerk*, so introduction and first stop fire together. Owner also confirmed **Bosco Verticale is the towers** (already anchored there) and **Gamla stan's walk stays put** (already untouched). ⚠️ #810 merged under this branch — merged in; its 29 pins add fresh candidates, sweep now **1 exact / 43 tight / 51 near**. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Band C)** — the owner's thirteen yeses from § 3's 100–200 m band: **8 new places + 3 joins, 258 → 266**, covering 643 entries. Same waiver discipline as Band B, at greater distance — the largest move is **194.5 m** (Stortorget into *Gamla stan*). 🔴 **Three more 4-dp coordinates found in the wrong place**: the `Neue Galerie` tour sat a full block east **on Madison rather than Fifth**, `Dennis Severs' House` **161 m** off Folgate Street, and the `Vasa Museum` tour **106 m** off the museum — each caught because the *other* member already sat exactly on the OSM feature. ⚠️ **`Bosco Verticale`'s pin sits on a RESTAURANT of that name, not the towers**, so the tour anchors it instead. ⚠️ **A walk may join only if it does not move** — `marker()` is the stop at order 0, so joining would relocate where a walk *begins*; *Gamla stan* is therefore anchored on its own 4-stop walk and **Stortorget travels instead**. ⚠️ Caught in flight: a 6-dp anchor read as a **2.8 cm move** against a full-precision float and tripped the multi-stop guard — identity is exact coordinate equality, so the test is now an exact compare, not a distance. Sweep **1 exact / 38 tight / 47 near**. Content + docs → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open (Band B)** — the owner's eleven yeses from § 3's 51–99 m band: **8 new places + 3 joins, 250 → 258**, covering 624 entries. 🔴 **Every move here is larger than the entry's own trigger radius — that is what Band B is**, and each waiver is recorded against the entry it applies to (no radius was edited). Anchors chosen by evidence: five members' own coordinates already ARE the OSM feature (Oculus, Apthorp, Monadnock, Sagrada Família, Art Institute) so those anchor and do not move. 🔴 **A twelfth coordinate defect found:** the `Obama Presidential Center` **tour** sat **259 m** from every OSM feature of that name, at 4 dp — repaired to the museum, and **deliberately left out of the place** because the owner said *BAND B ONLY* and that pair is N60/N64. It now shows as the one open **exact** group, which is the sweep working. ⚠️ Also: `make-place-menu.py` gained `DECLINED_PAIRS` — § 3 had **no** way to hold a decision, so Tibidabo (declined in #541) and the owner's own Red Room and LACMA calls were being re-offered as fresh candidates. Sweep **1 exact / 38 tight / 57 near**. Content + docs + `scripts/` → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **MERGED as [#808](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/808), squash `751df7b`** — the **Academy Museum of Motion Pictures** becomes a place with *The Walt Disney Company Piazza*, **250 places**, and the coincident tier reaches **zero open groups**: 0 exact, 0 sites within 25 m. This candidate only existed because #807's coordinate repair moved the museum onto a pin whose own text reads "at the Academy Museum" — two independently sourced positions agreeing. **What remains is § 3's 75 same-subject pairs at 25–500 m**, never reviewed, where making a place means moving an entry hundreds of metres. ✅ **Verified live:** `get_catalog` serves **250 places** and `check-catalog-contract.py` returns **PASS** (snapshot rebuilt `12:09:53Z`). ⚠️ The `places` row count read **249 for 14 minutes after the merge** — the seed job is not instant, and a check run too early reads as a failure that is not one. |
| `claude/amazing-rubin-pkub81` | **Open (under-25 m batch)** — **26 more places, 222 → 248**, and the sweep reaches **0 exact / 43 tight / 77 near** with only **4 open groups left**. Includes a bespoke **Wall Street** place (the Atlas tour + *The 1920 Wall Street Bombing* + *The Wall of Wall Street*) whose two furthest members are 54 m apart, so it sits at their **midpoint** — no member's own coordinate could serve without pushing another outside its 30 m geofence. 🔴 **Two real coordinate defects fixed:** the `Marina City` TOUR sat **460 m west of Marina City, on top of the Merchandise Mart** (both were 4 dp), and the Madrid *Ring of Green* walk's intro stop sat 14 m from the Palacio Real at 4 dp — both re-sourced from OSM. 19 groups declined and recorded. ⚠️ **Caught mid-flight: the menu's `P` labels renumber when a batch lands**, so the declines were briefly recorded against the wrong groups; they are keyed by member titles now, and the lesson is in `docs/lessons.md`. **Then the last four coincident groups, decided:** *The Dark Secret of Wall Street* joins the Wall Street page (⚠️ **115 m — outside its 30 m geofence, waived on owner instruction**; its subject is Wall Street itself, so it reads as a correction), the Red Room stays separate, **Hell Gate Bridge becomes a place** (3 pins, all within 13 m), and the LACMA trio stay separate with their **pins repaired** — LACMA and the Academy Museum were both 4 dp and **151 m out**; they are now 175 m apart. 🔴 **That repair immediately exposed a new 0 m group**: the Academy Museum now sits exactly on *The Walt Disney Company Piazza*, a pin whose own text reads "at the Academy Museum" — independent corroboration the fix was right, and the one candidate left open. **249 places; sweep 0 exact / 39 tight / 75 near.** Content + docs + `scripts/` → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **Open as [#806](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/806)** — the place menu becomes a **generated** document (`scripts/make-place-menu.py`), and the owner's under-10 m batch lands: **41 new places, 181 → 222**, 85 entries, 43 of them snapped onto their site (every move inside its own 30 m radius, asserted). **Sweep 1/121/79 → 0/75/79.** Five groups declined and now recorded in § 4 so they are never re-offered — Stockholm's shopfront, *Britain's Oldest Door / Tomb of Elizabeth I* (both Westminster Abbey, already a place 17 m away), Barcelona's café/hotel, Madrid's *El Retiro / Puerta de Alcalá* (a 4-dp rounding artefact — **both those coordinates are imprecise**, worth fixing separately) and Hong Kong's two shops inside D2 Place. 🔴 Two real bugs found while building it: a literal `|` in a bilingual title **silently shifts every cell after it** in a markdown table (24 entries carry one), and addressing group members **by title picked the wrong entry in 11 groups** that hold two entries sharing a title. Content + docs + `scripts/` → auto-merge class. |
| `claude/amazing-rubin-pkub81` | **MERGED as [#801](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/801), squash `e553227`; branch auto-deleted** — the place sweep. `check-place-candidates.py` gained a **TIGHT** tier (within 25 m whatever the titles say), because the title-containment rule is structurally blind to one site under two unrelated names — *Hook & Ladder 8* / *The Ghostbusters Firehouse* are 4 m apart and share no word; **82 of 151 TIGHT pairs were unreachable by any title rule**, 55 fully word-disjoint, and the old 148 NEAR pairs come back as 69+79 exactly. **Places 142 → 181**: § A 7 places / 8 entries, § B's 0 m rows 38 new places, and both held groups resolved by the owner (*Grand Central* pins joined the existing place at 88.4 m; *Tai Kwun* re-sited to the centre of OSM's 檢閱廣場 Parade Ground way, with *Madame Fu* relocated to its own published coordinate and **deliberately left outside** — a Tibidabo-style standing decision). 🔴 **"Adding the id is the whole change" was wrong**: identity is exact coordinate equality (1e-9°), so every joiner is **snapped**, each snap asserted inside its own `triggerRadiusMeters` — waived per entry, with a reason, only for the three owner-authorised moves that exceed it. **Sweep 41/151/79 → 0/117/78 and the checker now exits 0.** ⚠️ #802 landed between green CI and the merge; `mergeable_state` was re-checked as clean first. |
| `claude/tour-links-tstvw8` | **Open as [#789](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/789)** — 35 Instagram link pins from a random owner-collected batch (36 links, one dead); `linkPins` 1,644 → 1,679, `makers` 355 → 376 (21 new creators) — ⚠️ **rebased twice: `main` moved under this branch during its own CI**, so those are the second set of numbers, re-derived after resolving. 21 cities, 11 countries. 🔴 **No link came with a location**, so every coordinate was forward-geocoded and each returned name read back by hand — which caught four wrong subjects: the Huntington Beach **Central** Library (not the Banning branch), the **Runnymede Theatre at 2225 Bloor W** (not the library at 2178), **Aranya Wulingshan Phase 2** (which resolved only to its county until queried in Chinese), and **Conwell Cocktail Hall in New York's Financial District** — the name reads Philadelphian and is not. ⚠️ **The first geocode run reported "NO MATCH" for 30 of 35 subjects including Tribune Tower — that was HTTP 429, silently coerced into a negative result**, the § Reading a check's result trap in a fresh disguise; the script was rewritten to separate a failed fetch from a real miss. Five posts named no place at all and were identified from the video frame or research (111 Murray St · iMANISHi Sando Bar · St Vincent de Paul · On Labs Zurich · Conwell). Each pin minted with its own `--title` — a batch run takes the map title from the caption, which on Instagram is a paragraph. Validator 0/0 with self-test 32/32; 35 heroes, 35 unique hashes, all 1200×900, no filename collision against gh-pages' 7,514. **Two owner decisions in § 5.** Content-only → auto-merge class. |
| `claude/atlas-upload-link-pins-zb1l0o` | **Open as [#784](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/784)** — 27 link pins (Seattle, NYC, Stonehenge, Mont-Saint-Michel, Monaco, London, Pont du Gard, Chamonix, Lyon, Houston, Vence); `linkPins` 1,588 → 1,615. Coordinates OSM-verified and read back to the owner before minting. **11/12/13 share one TikTok post at three NYC monuments** — ids use the `#<city>-<title>` fragment scheme (docs/link-pin-runbook.md), one shared hero. **08/09 turned out to be two distinct Mont-Saint-Michel posts** (the abbey vs. a nearby basilica relic) that collided on hero filename twice — once with each other, once with a pre-existing `@urbanistariel` pin already live on gh-pages — both re-slugged rather than overwriting a live hero. Six free-text tags outside the closed vocabulary (`Ancient Monument`, `Abbey`, `Synagogue`, `Historic Market`, `Roman Aqueduct`, `Mountain`) mapped to valid equivalents; validator went 9 errors + 32 warnings → 0/0. Heroes live on gh-pages `e3950d4`, hashes verified; `check-image-duplicates.py --pins` clean (0 errors, 1,606 images). Content-only → auto-merge class. |
| `claude/inspiring-gauss-qwi8vu` | **Merged as [#782](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/782), squash `28409c0`** — 37 `@urbanistariel` link pins, `linkPins` 1,551 → 1,588. 🔴 **Katz's Deli arrived on a Plus Code that recovers to Albee Square, Downtown Brooklyn — 3.5 km away, wrong borough, and to the same point from a Manhattan reference too, so the code was wrong rather than its locality label.** Repinned at 205 East Houston Street; **owner confirmed the repin ("where you recommend")**. ✅ **The held-back Callanish link is DROPPED on owner instruction** — TikTok's oEmbed returned an empty author and no thumbnail on every retry while all 37 others returned both, so the post is gone; its Plus Code was good. Nothing from this batch is owed. ⚠️ `main` moved during CI (#781) and the merge conflicted on `archive/README.md` only — structural, both rows kept, `Tours.json` untouched by the merge. ⚠️ **Two pushes produced no `synchronize` event**, so CI was dispatched by hand twice — the exact gap `ci.yml`'s own `workflow_dispatch` comment documents. Heroes on gh-pages `5e15d8c`; mirror verified live carrying 1,588 pins. |
| `claude/tour-uploads-token-efficiency-hyrix3` (4th run) | **Open as [#764](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/764)** — closes the same-city link-pin id gap: when one post yields two pins in ONE city the city fragment collides, and **both times that happened the ids were invented on the spot** (Charging Bull, New York; Harry Potter, Edinburgh — #758, today). Rule is now `#<slug(city)>-<slug(title)>` on collision, and `merge-link-pins.py` **refuses an id it cannot derive**, naming the expected one. 🔴 **The five existing odd ids are NOT re-minted** — an id is identity; changing one makes phones lose the pin from saved libraries. ⚠️ A defect only the live catalogue exposed: grouping without dedupe made a re-merged pin count twice, breaking idempotence — all unit tests were green. 30/30 self-tests, catalogue untouched. |
| `claude/tour-uploads-token-efficiency-hyrix3` (3rd run) | **Open as [#759](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/759)** — the same append-forever pattern found in two more files: `archive/README.md` **474,582 → 31,588 B (−94%)** and `ROADMAP.md` **427,655 → 98,260 B (−77%)**, history moved verbatim to `archive/INDEX-DETAIL.md` and `archive/ROADMAP-STATUS-HISTORY.md`. **Zero lines lost on both**, verified against `git show HEAD:<file>`. 🔴 Turned up three defects: a parser silently dropping a third bullet format, a row mangled by a literal `|` inside a cell, and **`HANDOFF-260819.md` indexed but never committed** (row kept and marked, not deleted). ⚠️ Also fixed a stale "Active handoff" pointer and the wrong `ls … | tail -1` idiom (`-` sorts before `.`, so a `-2` suffix is discarded). **`STATUS.md` deliberately untouched** — prose about what the owner owes, no mechanical cut. Restarted from `origin/main` after #757 merged. |
| `claude/tour-uploads-token-efficiency-hyrix3` | **Open as [#757](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/757)** — `scripts/merge-link-pins.py` (merges a pin batch into `Tours.json` disk-to-disk, so its JSON never passes through a conversation — ~1.9 KB/pin measured, paid again on every later turn) + `docs/link-pin-runbook.md` (the uuid5 id scheme, verified live, with the command to re-prove it). Docs + `scripts/` only → auto-merge class. **Restarted from `origin/main` after #756 squash-merged and its branch was deleted — never stacked on merged history.** ⚠️ Found that `validate-tours-mirror.py` ALREADY carries the 32-case fault harness sessions kept rebuilding; no new one was written. |
| `claude/tour-uploads-token-efficiency-hyrix3` (first run) | **Merged as [#756](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/756), squash `f6adc5d`** — moved 34 dated Current State blocks out of `CLAUDE.md` into `archive/CURRENT-STATE-HISTORY.md` (1.5 MB → 47 KB, ~418k → ~13k tokens **on every request of every session**), added `docs/lessons.md`, and amended Automation Rule #5 + § Keep Docs in Sync so the narrative cannot grow back. Archive verified **byte-identical** to main's region. |
| `claude/tour-links-ds0387` | **Open as [#734](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/734), all four checks green on `2b171cae`** — 33 Toronto + Mississauga link pins, **plus six places and two architects** on owner instruction, cut clean off `origin/main` `5763c137` and since merged with `main`. ⚠️ **A CODE change** (`Models/Tag.swift`), so it waits for owner OK + a simulator look. gh-pages `5308c563` carries its 33 heroes, **all hash-verified live against the uploaded bytes**. ⚠️ **gh-pages moved between the clone and the push** (`0b15aa4` → `a0cd018`, a parallel session's 17 heroes) — detected by re-reading `git ls-remote`, and the tree was **rebuilt on the current head rather than force-pushed**, with collisions re-checked against the new tree. |
| `claude/new-tour-links-cytwc6` | **Open as [#729](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/729)** — 61 `@archimarathon` link pins plus two places, cut off `origin/main`. gh-pages `317046a` carries its 61 heroes. |
| `claude/tour-links-26dmsx` | **Merged ([#701](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/701), squash `5fc747fb`)** — twenty-eight Chicago link pins; linkPins 712 → 740, makers 247 → 262. ⚠️ **`main` moved THREE times while it was in flight** (#698, #699, #700 — 147 pins, the last arriving after the PR was open), and the catalogue edit was **redone each time by re-running the idempotent assembler on `main`'s file**, never hand-resolved. 🔴 **That caught a real hazard: #699 created maker rows for two of this batch's creators, so new rows went 17 → 15** — uuid5 reproduced both ids exactly; a naive resolve would have emitted `duplicate maker id` twice. ⚠️ **Handoff renumbered twice, to `-10`** — `-7`, `-8` and `-9` were all claimed by parallel sessions on the same afternoon. Story in `CLAUDE.md` § Current State |
| `claude/tour-links-upload-tbcerj` | **This session, pushed, no PR** — twenty link pins (15 × `@breatheart_hk` Hong Kong). Cut off `origin/main` `05e90f47`, **rebased onto `00a420bd`** after #640 and three doc commits landed mid-session; catalogue edit redone by re-running the idempotent assembler against the new `main`, never hand-resolved. gh-pages `a8a81767` |
| `claude/tour-links-upload-wa3e0g` | Merged (#640, squash `cd32e293`) — 32 pins. ⚠️ **Its branch diff was 33 pins, not 32**: it carried the Instagram Zacherlhaus the owner pulled in #641. Flagged pre-merge; **checked after and the pull held** — only the TikTok Zacherlhaus is on `main` |
| `claude/tour-links-upload-qeoxe7` | **Merged as [#648](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/648); follow-up places PR open** — twenty-three link pins from three creators (18 TikToks `@thedesigndetourist`, 4 Instagram `@shaunbirley`, 1 `@meliluu__`); linkPins 168 → 191, makers 154 → 157. Content only, images live on gh-pages at `251cf95e`. **🔴 MERGE HAZARD, NOW THE OTHER SESSION'S: this branch created the `TikTok @thedesigndetourist` maker row (uuid5 `67CA14A6-…`) and a parallel session's unmerged branch creates the identical id — that branch must drop the duplicate or the validator errors.** ⚠️ Ships two subjects twice on one coordinate each (Westin Bonaventure, Hotel Casa del Mar) — deliberate, both links were sent; `check-place-candidates.py` therefore reports 3 EXACT groups against main's 1 |
| `claude/project-tracking-dashboard-1kggmu` | **This session — restarted from `origin/main` `5e75112`, never stacked on merged history.** Its previous commit (`eee22bb`, one paragraph added to `release_notes.txt`) was **deliberately dropped, not landed**: 1.1.1 has since shipped, so that file is now the *published* notes and the next edit to it is a rewrite for 1.1.2 — see § 1d and `docs/launch-runbook.md` § Shipping an update, which this branch corrects instead. |
| `claude/link-fullscreen-probe` | 🔴 **Never merged, still on the remote** — carried the temporary readout and builds 131/132/133. **Owner deletes it in the GitHub UI**; the git proxy blocks branch deletion from a session |
| `claude/link-fullscreen-window` | Merged (#622, squash `e22dba7`) — the real fullscreen fix |
| `claude/link-fullscreen-module-ojs556` | Merged (#617, squash `adbe3b94`) — the `onDisappear` guard. ⚠️ The designated branch name; the first attempt's work was actually on `claude/link-fullscreen-module` |
| `claude/link-fullscreen-module` | Merged (#611, squash `8df37de8`) |
| `claude/new-tour-links-nniny1` | Merged (#626, squash `303012b3`) — nineteen San Francisco architecture link pins. **Verified live on BOTH sources afterwards**, not on the merge: the RPC and the gh-pages mirror each serve 76 link pins with 0 wrongly inside `tours`, and `places` / `priceTier` / `isPrivate` all survived. ⚠️ Restarted from `origin/main` for this board update — never stacked on merged history |
| `claude/new-tour-links-yr5o7r` | **Open as [#627](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/627)** — ten "Atlanta Architecture" TikToks, **nine shipped as link pins; the tenth (Mercedes-Benz Stadium) pulled by the owner over a probably-AI hero**. Cut clean off `origin/main` `c5e8862`, then **merged `main` in to resolve a four-way conflict with #626** (both batches touched `Tours.json`, `CLAUDE.md`, `STATUS.md`, and both claimed `archive/HANDOFF-260827.md`). Content only. Images live on gh-pages at `a93c06d4`. |
| `claude/tiktok-orlando-links-ziegoe` | **Restarted from `origin/main` after #621 merged** — now carries the Orlando *architecture* batch (10 pins, commit `da9c96ad`). ⚠️ Same branch name, fresh history: never stacked on merged commits. |
| ~~`claude/tiktok-orlando-links-ziegoe` (first run)~~ | Merged as #621 (squash `1c05613b`) — nine Orlando link pins, live on Supabase |
| `claude/library-launch-jitter` | Merged (#549 at 03:52) — auto-delete should remove it |
| `claude/upload-wizard-improvements-ejopz3` | Merged (#552 at 19:05) |
| `claude/wizard-comments-round2` | Merged (#558) and deleted |
| `claude/launch-performance-animations-df4d7p` | Merged (#559 at 16:43) — built as 108/109 |
| `claude/milan-tours-upload` · `claude/milan-docs-260822` | Merged (#560, #561) |
| `claude/coordinate-guard` | Merged (#562 at 17:20) |
| link-pin branches (#584, #585, #586, #587) | All merged 20:59–22:51; auto-delete should remove them |
| `claude/link-pin-batch-workflow` | Merged (#588 at ~01:40) |
| link-pin follow-ups (#589–#595) | All merged 01:40–03:10 |
| `claude/ellipsis-button-consistency-vdorpi` | Merged twice from one branch (#553, #555). ⚠️ The second stacked on already-merged history, which CLAUDE.md says to avoid — it worked, but no PR existed while build 95 was installable |
| `claude/tour-upload-polish-qiliop` | Merged (#540) — auto-delete should remove it |
| `claude/stripe-questions-fjhdo3` | ⚠️ No PR — verify contents before deleting |
| `claude/amsterdam-handoff-preserve-hlhyp8` | 🔒 Keep — only copy of staging pick-maps |
| `claude/web-landing-site-preserve` | 🔒 Keep — only copy of the Next.js landing site |
| `claude/london-batch3-scripts-260616` · `claude/paris-scripts-260622` · `claude/dreamy-wozniak-tags-260612` | 🔒 Keep (documented archival) |

## 5. Content

**⚠️ Re-derived from `Tours.json` on `main` at `8450c9a` (session 156, [#790](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/790) MERGED, squash, on top of #789): 1,552 tours + 1,700 link pins, 376 maker rows, 3,624 stops, 141 places, 466 cities across 64 countries.** Newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**. 21 TikTok pins from `@nickcabotrodriguez` (13 New York, 8 Los Angeles) — Plus Codes decoded and reverse-geocoded, then every subject re-checked against the post's own thumbnail before minting (several corrected the geocoded guess). `validate-tours-mirror.py` 0/0, `check-image-duplicates.py --pins` clean, heroes on gh-pages `b600496`. **Two owner decisions owed** (§ place-candidate finds, not blocking): the First National Bank of Hollywood pair (same coordinate, two posts) and the St. Vincent de Paul Church pin sitting 12m from an existing Instagram pin for the same church — keep both as separate pins, or make each a place? ⚠️ **Both are now items in the full sweep, `docs/place-candidates-260911.md`, which found 221 of them** — answer them there rather than one at a time. **An "Abandoned" tag was proposed and deliberately NOT added** — the owner asked to hold it for a durable vocabulary change rather than a one-off content edit; 12 of these 21 pins would use it once it ships.

**⚠️ Re-derived from `Tours.json` after resolving onto `887a8a7` (branch `claude/tour-links-tstvw8`, MERGED as [#789](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/789)): 1,552 tours + 1,679 link pins, 376 maker rows, 3,603 stops, 141 places, 466 cities across 64 countries.** 35 Instagram pins from a random owner-collected batch; every coordinate OSM-geocoded and read back by hand, four wrong subjects caught that way. `validate-tours-mirror.py` 0/0 (self-test 32/32), heroes on gh-pages `96e4906`, 35 unique hashes, no filename collisions.

**🔴 Two owner decisions owed from #789, neither blocking the merge:**
1. **12 of the 35 pins will not play inline** (licensed music — tapping opens Instagram). Reported, never refused, per the runbook. Keep or drop?
2. **Two pins are the same hotel** — @sdamiani's two St. Regis Kanai posts, both `#marriottpartner`, at one coordinate with distinct titles. Keep both or drop one?

⚠️ **One link is dead and was NOT added:** `instagram.com/reel/DdAAMMjuKhL/` returns neither handle nor thumbnail on repeated attempts — private or deleted. 35 of 36 landed.

**⚠️ Re-derived from `Tours.json` on `6b20d968` (branch `claude/atlas-upload-link-pins-zb1l0o`, open as [#784](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/784)): 1,552 tours + 1,615 link pins, 353 maker rows, 3,539 stops, 141 places, 451 cities across 64 countries.** Newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**. 27 link pins added (Seattle, NYC, Stonehenge, Mont-Saint-Michel, Monaco, London, Pont du Gard, Chamonix, Lyon, Houston, Vence), coordinates verified against OSM reverse/forward geocoding and read back to the owner before minting. `validate-tours-mirror.py` 0/0, `check-image-duplicates.py --pins` 0 shared-URL errors across 1,606 pin images. Heroes live on gh-pages `e3950d4`, hashes verified. Content-only PR — eligible for auto-merge once CI is green, no owner approval gate.

**⚠️ Re-derived from `Tours.json` on the session-143 branch `claude/tour-links-ds0387`: 1,552 tours + **1,184** link pins, **328** maker rows, 3,108 stops, **120** places.** Newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**. ⚠️ **Not yet on `main`** (pushed, no PR).

**⚠️ Re-derived from `Tours.json` on the session-141 branch `claude/new-tour-links-cytwc6`: 1,552 tours + **1,047** link pins, 305 maker rows, 2,971 stops, **114** places.** Newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**. ⚠️ **Not yet on `main`** (pushed, no PR), and ⚠️ **`main` moved twice while this batch was being wired** (#722, #725), so the base itself is a moving target.

**⚠️ Re-derived from `Tours.json` on `main` at `613e23e7`: 1,552 tours + 905 link pins, 297 maker rows, 2,829 stops, 105 places.** Newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**.
  - ✅ **That gap is CLOSED** — `backend/pull_pins_260902.sql` has been run and the RPC now matches the catalogue pin-for-pin (§ 1). The reading below was taken while it was still outstanding. It also reports **1,553 tours and 311 makers** against 1,552 / 297 — the documented `Zxxx` test tour and upsert-only maker accumulation. **Assert on link-pin counts, never on maker totals.**

**⚠️ Re-derived from `Tours.json` on `main` at `b46e354c` (session 137, after [#712](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/712) merged): 1,552 tours + 846 link pins, 263 maker rows, 2,770 stops, 100 places.** This is the newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**.
  - **The live Supabase RPC agrees**, and it is the source the app reads first: 846 `linkPins`, 0 wrongly inside `tours`, 100 places, `priceTier` on all 1,553 tours with 66 priced. ⚠️ **The RPC reports 1,553 tours and 275 makers against the catalogue's 1,552 / 263** — the documented `Zxxx` test tour and upsert-only maker accumulation. **Assert on link-pin counts, never on maker totals.**

**⚠️ Re-derived from `Tours.json` on 2026-09-02 (session 135c, open as **[#707](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/707)**): 1,552 tours + 740 link pins, 262 maker rows, 2,664 stops, **97 places**.** Branch `claude/tour-links-yg5yw2`, restarted off merged `main`. Owner: *"make both places"* — the last two coincident groups.
  - **✅ Cube House (Toronto) and Tribune Tower (Chicago) are places.** Both **pure additions**: nothing moved, both pairs already coincident, `makers`/`tours`/`linkPins` byte-identical.
  - 🎉 **`check-place-candidates.py` reaches 0 EXACT and exits 0** (main: 2 / 36), **NEAR unchanged at 36**. **The place backlog is EMPTY — treat any future EXACT group as a real finding.**
  - ⚠️ **The Atlas tour `The Wrigley Building & Tribune Tower` is 142 m away and correctly NOT a member** — which also closes the two-subject naming problem that pair has carried since #701.
  - 🔴 **The Cube House is slated for demolition** — Block Developments, permit filed, Von Wong to rebuild the material as public art. Heritage **listed, not designated**. The copy asserts no date and no claim it still stands. ⚠️ **Sources disagree on its designer**; neither reading is asserted.
  - ⚠️ **Both heroes borrowed by necessity** (pin-only sites, empty galleries, no Atlas tour to lend one) — count re-derived **26 of 97**. **Do not go sourcing replacements.**

**⚠️ Re-derived from `Tours.json` on 2026-09-01 (session 135b, on the base that carries #700): 1,552 tours + 740 link pins, 262 maker rows, 2,664 stops, **95 places**.** Branch `claude/tour-links-yg5yw2`, open as **[#703](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/703)** — all four checks green on `f5404260`. Restarted off merged `main`; five owner place decisions applied in one pass. ⚠️ **`main` moved a THIRD time mid-flight** — [#700](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/700) merged sixteen Hong Kong link pins and a maker row and collided **add/add on the handoff filename again**, so this session's second handoff renumbered **`-9` → `-10`**. `Tours.json` auto-merged cleanly (their change appends pins, mine edits `places` and two pin coordinates) and the result was **verified, not trusted**; every check re-run on the merged base.
  - **✅ Four new places** — **One Times Square**, **The Tin Building**, **Eastern State Penitentiary**, **Charles Scribner's Sons Building** — each two coincident pins the owner sent twice.
  - **✅ The Morgan Library place grows 3 → 5 members.** ⚠️ **The checker reported its two new pins as a FRESH EXACT group** because they sat 6.5 m off a place that already existed — build from the sweep, not the checker, or you create a second Morgan Library. **The pins moved onto the place, not the reverse** (2 edits vs 4; 6.5 m is the CalAcademy rounding artifact; both `manual`, so no geofence moved).
  - **✅ `check-place-candidates.py` 7 EXACT → 2, NEAR unchanged at 36** — falls by exactly the five groups resolved and gains nothing. ⚠️ **Both groups left are other sessions' and neither has been put to the owner: Toronto's Cube House pair ([#698](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/698)) and Chicago's Tribune Tower pair ([#701](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/701)).**
  - **✅ Eastern State has a SOURCED CC0 hero** (gh-pages `9252daff`), natively 4:3 so nothing is cropped and nothing upscaled; no CREDITS row. ⚠️ The other three borrow a member hero — borrowed-hero count **27 of 95**.
  - **🔴 STANDING OWNER POLICY: paid partnerships are NEVER raised again.** Do not flag `#morganpartner`, `#silversteinpartner`, `#marriottpartner`, ADs or `#Partner` on any future batch.
  - **✅ #77 Hart Island's talking-head hero STAYS** — settled; do not re-raise.


**⚠️ Re-derived from `Tours.json` on 2026-09-01 (session 135, this batch merged onto #698's Toronto pins): 1,552 tours + 696 link pins, 246 maker rows (34 Atlas studios + 212 pinned creators — 112 TikTok, 88 Instagram, 12 YouTube), 2,620 stops, **88 places**, 265 cities across 40 countries.** Branch `claude/tour-links-yg5yw2`, open as **[#699](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/699)**. ⚠️ **`main` moved AGAIN after the PR opened** — [#698](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/698) merged Toronto's first 25 link pins and 20 creator rows, conflicting in `Tours.json`, `CLAUDE.md` and — an **add/add** — on this session's own handoff filename. Resolved the documented way: **take `main`'s file and re-run the idempotent assembler**, never hand-resolve a JSON conflict; **0 overlap** with Toronto on sourceURL, ids or hero filenames. This handoff renumbered **`-7` → `-8`** (Toronto merged first and kept `-7`). On the merged base the batch reads **linkPins 590 → 696 · makers unchanged at 246 · places 87 → 88**, and every check was re-run: mirror **47/47** then **0 errors, 2 pre-existing warnings** across 1,552 tours + 696 pins + 88 places; place faults **14/14**; seed clean at **246 / 2,248 / 2,620 / 88**; `check-place-candidates.py` **1 EXACT / 25 NEAR → 6 / 33** — the one on `main` is Toronto's own, the five added are this batch's undecided groups, and **120 Broadway is absent because the place resolved it**. gh-pages `d6c1e75` carries its 106 heroes. **108 links → 106 distinct posts, every one TikTok `@hereinnyc`** — the largest batch to date, against a previous record of 105 — so **makers is unchanged**: the row already existed, uuid5 reproduced its id exactly, and the regenerated avatar was byte-identical to the live file and excluded rather than overwritten.
  - **🔴 A supplied Plus Code was wrong and only the hero says so.** "Holy Nail in Duomo" carries **the identical code as the post before it** (the *Volto Santo* in **Lucca**) while its frame is the **Milan Duomo roof** and its caption reads `#duomodimilano` — a 280 km error that decodes cleanly and reverse-geocodes to a real square. Corrected; it now sits 26 m from the existing `Duomo di Milano` tour.
  - **✅ 120 BROADWAY IS A PLACE — owner instruction, same session. Places 87 → 88, a pure addition; the cap no longer applies.** The rest of this bullet is why it was needed. **🔴 FOUR COINCIDENT PINS AT 120 BROADWAY AND THE MAKER-PAGE CAP IS THREE.** `HomeView.maxStackedPlacecards` is 4 (Home is fine, no headroom) but **`TourSetMap.maxStacked` is 3 and every pin in this batch is one creator**, so **one of the four is permanently unreachable on `@hereinnyc`'s own page**. Session 132 flagged Arthur Ashe as safe only because its four pins had four different makers — **that mitigation does not exist here.** No coordinates were manufactured to relieve it. **A place is the fix — ✅ built.**
  - **⚠️ `check-place-candidates.py` goes 0 EXACT / 21 NEAR → 6 / 29, then 5 / 29 once 120 Broadway became a place; it still exits 1**, ending the clean-exit state #694 restored. All six are sites the owner sent more than one link for — 120 Broadway ×4, the Morgan Library ×2 (**already a place with 3 members**, so these would be a 4th and 5th), the Tin Building ×2, Eastern State ×2, Scribner's ×2, and One Times Square (this batch's NYE Ball pin converging on the same OSM node as `@whatisthis_nyc`'s existing pin). **None was nudged together.**
  - **⚠️ Owner decisions owed:** the five other coincident groups; **#77 Hart Island's hero is a talking head** (keep or pull); and **four paid partnerships** — `#morganpartner` ×2, `#marriottpartner`, and `#silversteinpartner` on all four 120 Broadway posts (the Coca-Cola precedent says the owner may keep them).
  - ⚠️ **`main` moved mid-session** ([#697](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/697)), so the catalogue edit was redone on `main`'s file with the idempotent assembler and every check re-run. **Another session is staging Toronto link-pin heroes** (gh-pages `a506a5b6`, 25 subjects) — my push sat on top of theirs with **0 modifications**, so nothing was overwritten.

**⚠️ Re-derived from `Tours.json` on 2026-09-01 (session 132, this batch, NOT yet merged): 1,552 tours + 554 link pins, 224 maker rows (34 Atlas studios + 190 pinned creators — 111 TikTok, 67 Instagram, 12 YouTube), 2,478 stops, 80 places, 262 cities across 40 countries.** Branch `claude/tour-links-upload-vhsf8a`, **no PR opened** (the owner did not ask for one). gh-pages `19d7a985` carries its 29 images. **⚠️ `check-place-candidates.py` now exits 1 with 5 EXACT groups** — Arthur Ashe Stadium (**4 pins, exactly `HomeView.maxStackedPlacecards`, no headroom**), Grove at Grand Bay ×3, Bellevue/Lockridge Library ×2, Vancouver House ×2, Banyan Tree Mayakoba ×2. All five are subjects the owner sent more than one link for; none manufactured. **⚠️ Found, not fixed: session 125's `images//` correction was HALF APPLIED on the seven `@nikola.matus` pins** — `heroImageURL` is single-slashed, **`stops[0].imageURL` still carries the double**. Both forms serve 200, so it is not breakage, but **`check-image-duplicates.py --pins` reports seven phantom `INFO` groups on every run** because of it. Seven-line fix; deliberately left out of this batch's diff.

**⚠️ Re-derived from `Tours.json` on 2026-08-29 (session 122, after merging #640): 1,552 tours + 244 link pins, 189 maker rows (34 Atlas studios + 155 pinned creators — 98 TikTok, 44 Instagram, 13 YouTube), 1,924 tour stops, 38 places, 36 countries.** Twenty pins added on branch `claude/tour-links-upload-tbcerj`; **no PR opened** (harness forbids it unasked). **🔴 THREE LINK-PIN SESSIONS WERE IN FLIGHT SIMULTANEOUSLY ON NEAR-IDENTICAL BRANCH NAMES** (`…-tbcerj`, `…-wa3e0g`, plus a third pushing 23 heroes straight to gh-pages), so **deduping against `main` alone is no longer sufficient** — check the open PRs' branches too, and re-check after each merge. **⚠️ The Key-facts line written an hour earlier said 201 pins / 149 creators against a real 200 / 149, so not one session's own number has survived its merge.** **✅ Duddell Street Steps is now a place (places 38 → 39), built on owner instruction** from the Atlas tour and the new pin, which sat 9 m apart under the same name. ⚠️ **Neither member is geofenced**, so the pin moved on the CalAcademy rounding-artifact reasoning rather than the usual geofence one; the place hero is a **third** photograph promoted from the tour's own gallery; and **the two members disagree on three dates, so the place copy asserts none of them.** **⚠️ Four heroes are weak and one badly so**: the Bird Bridge pin's thumbnail is a red X the creator drew over a photograph to retract an earlier post, so it renders as a red X on the map (the Hugo de Grootplein shape). The Mercedes-Benz Stadium precedent says the owner may pull it.

**⚠️ Re-derived from `Tours.json` on 2026-08-27 (session 119, this batch): 1,552 tours + 124 link pins, 133 maker rows (34 Atlas studios + 99 pinned creators — 83 TikTok, 11 YouTube, 5 Instagram), 1,924 tour stops.** **Places 30 → 31: Barcelona Pavilion**, built on owner instruction from the Atlas tour and the new pin (77 m apart, same subject) — **the pin moved onto the geofenced tour, never the reverse**. Twenty-three pins added on branch `claude/tour-links-paste-thsd6q`, open as **[#632](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/632)** (owner asked for it). ⚠️ **#632 moves a GEOFENCED tour 78 m** — the Atlas *Mies van der Rohe Pavilion* onto the building — **on explicit owner instruction, overriding "the pin moves, never the tour"**; the move improves the geofence (old point was 64 m outside the building's edge, so standing at the pavilion did not fire it) and is recorded in `CLAUDE.md` so it is not reverted. ⚠️ **This batch adds NO new country** — India and Mexico both look new against the 22 that `tours` span, and both were already in the catalogue via existing link pins (Maya Somaiya Library; two Mexican food pins). **The catalogue spans 30 countries across tours AND pins, and it did before this batch too — never quote the tours-only figure as the catalogue's.** ⚠️ **This is the first batch where Instagram arrives at scale** — 6 reels across 4 creators, all playable inline, and **all four Instagram makers ship `avatarURL: null`** because Instagram's embed exposes no creator avatar; they fall back to the platform mark. ⚠️ **Pinned creators now outnumber Atlas studios almost three to one**, so the raw `dataService.makers.count` in Settings → About is further past the tipping point flagged when there were four pins; the owner's decision (userId-only / published-tour-only / split the row) is **still owed and getting worse each batch**.

**⚠️ Re-derived from `Tours.json` on 2026-08-27 (session 117, after merging #626 and #625): 1,552 tours + 85 link pins, 99 maker rows (34 Atlas studios + 65 pinned creators), 1,924 tour stops.** **⚠️ THREE CONTENT BATCHES LANDED WITHIN TWO HOURS** — nineteen San Francisco pins (#626), four Orlando architect names (#625) and ten Atlanta pins (#627, of which nine shipped). **#626 and #627 conflicted in four files, including an add/add on the same handoff filename**, and #627 had to merge `main` twice. Expect that whenever content sessions run in parallel. **⚠️ THE ATLANTA TOUR BATCH IS ALSO IN FLIGHT** and is in the tracker: 30 single-stop tours, 30 MP3s outstanding, under a new **Atlas Studio ATL**. Its Oakland Cemetery tour will land beside #627's pin for the same site. **The audio-pending queue is NOT empty.**

**⚠️ Re-derived from `Tours.json` on 2026-08-27 (session 116): 1,552 tours + 76 link pins, 90 maker rows (34 Atlas studios + 56 pinned creators — 46 TikTok, 9 YouTube, 1 Instagram), 1,924 stops. Live-confirmed on both the Supabase RPC and the gh-pages mirror after #626 merged.** ⚠️ The RPC reports **1,553 tours / 98 makers** against that — the long-standing `Zxxx` test tour plus upsert-only maker accumulation, both pre-existing. **Assert on link-pin counts, not maker totals.** The paragraph below predates Copenhagen and the last three link-pin batches and its figures are stale — **re-derive, do not quote.** **🔴 Pinned creators now outnumber Atlas studios nearly two to one**, so the raw `dataService.makers.count` in Settings → About has passed the tipping point flagged when there were four pins; the owner's decision (userId-only / published-tour-only / split the row) is still owed. **⚠️ An ATLANTA batch is still being staged by another session and is still not in the tracker** — a gh-pages push landed mid-session (MLK Birth Home ×7 + the Candler Building). Do not report the audio-pending queue as empty without re-deriving.
**⚠️ THE PARAGRAPH BELOW IS STALE AND IS KEPT ONLY FOR ITS LIVE-RPC NOTES — re-derive, do not quote.** Its figures predate Copenhagen and the last five link-pin batches, and **its claim that the audio-pending queue is EMPTY is now false**: Atlanta sits in it with 30 tours awaiting narration.

**Catalog 1,516 tours live / 45 maker rows served** (49 before the test-creator cleanup). The four `TEST -` pins are gone (#593),
replaced by **4 real AMNH creator link pins** (#591). **7 served makers have zero tours**, all of them real sign-ups who have not published yet. — **Stockholm (Atlas Studio STO, 45 tours) landed 2026-08-24**
and is live in the RPC, along with VIA 57 West. Milan (48 tours) landed 2026-08-22. ⚠️ The RPC reports **40** maker rows against a true 32: upsert-only accumulation,
long-standing. The audio-pending queue is **EMPTY**. `drafts/AUDIO-PENDING-SURVEY.md` on `origin/main` stays the
authority; read it from `origin/main`, never from a branch.

## 7. Verification traps — each one produced a wrong answer here

Not general advice. Every entry below is a check that **returned a confident, wrong result** on this
repo, and the correction that makes it honest.

- 🔴 **`check-image-duplicates.py --pins` PASSES A REUSED-FOOTAGE HERO.** Its confirmation threshold
  is **8.0**, and the `@hereinnyc` batch's two frames of one subway carriage scored **12.2** — so the
  tool reported OK on a pair that is visibly the same shot. That is the tool working as designed: it
  hunts byte-level re-writes, and "same footage, different frame" is not one. **A clean `--pins` run
  does not mean no two heroes show the same thing — only a per-batch perceptual sweep catches that**,
  and the pair it found put a Transit Museum carriage on the Yankee Stadium pin (owner-decided: it
  stays).
- 🔴 **A MERGED PR IS NOT EVIDENCE THAT NO BUILD CARRIES IT.** This board twice reported "nothing
  waiting on a build" from a list of merged PRs without re-reading the run list in the same turn, and
  was wrong within five minutes both times — another session had already built the work from its own
  branch. **Re-read the Actions run list in the same turn as any claim about what is waiting**,
  including when the answer is "nothing".
- 🔴 **`git diff` AGAINST A COMMIT GIT DOES NOT HAVE RETURNS EMPTY** — indistinguishable from "no
  differences". Branches auto-delete on merge, so a build's commit is routinely unreachable. **This
  produced a false clean twice in one session.** Fetch `refs/pull/<n>/head`, confirm with
  `git cat-file -t`, and only then trust the diff.
- 🔴 **A TAKEN-DOWN TOUR IS INVISIBLE TO EVERY ORDINARY READ.** `get_catalog` serves published only,
  and so does the RLS policy behind PostgREST. On 2026-08-25 the catalogue reported four creators had
  no tours, a direct API read agreed, and **both were wrong** — each still owned one `taken_down` row,
  which is why a delete matched nothing three times. **Anything reasoning about "does this maker have
  tours" must query the table as `postgres`.**
- 🔴 **A GUARD THAT TURNS A LOUD, SPECIFIC ERROR INTO SILENCE IS WORSE THAN NO GUARD.** That same
  delete carried `not exists (select 1 from tours …)`, which the hidden rows failed — so it reported
  *"Success. No rows returned."* Without the guard, `tours.maker_id` being `on delete restrict` would
  have raised a foreign-key violation **naming the exact blocking row**.
- ⚠️ **A GREEN `publish-catalog` RUN IS NOT PROOF THE CATALOGUE CHANGED.** It reported success while
  the live RPC still served the old place count for three more checks. **Ask the RPC.**
- ⚠️ **A SPAWNED CLOUD SESSION MAY HAVE NO GITHUB TOOLS, AND CANNOT BE MESSAGED FROM A WEB SESSION.**
  One spawned 2026-08-26 wrote the link-fullscreen fix, could not open a PR, and sat blocked eight
  hours while another session solved it independently; **its branch was never pushed, so the work was
  lost with the container.** Brief a spawned session completely up front, tell it to **push its branch
  early**, and check on it rather than reading silence as progress.

## 6. Known debt — real, not urgent

**🔴 SEARCH LISTS 27 EMPTY MAKER ROWS, 20 OF THEM CALLED "New Creator" (found 2026-09-12).**
The live `get_catalog` serves **417 makers** where `Tours.json` has 388. Twenty-nine are
database-only; **twenty-seven of those have zero tours and zero pins**, and `SearchView.filteredMakers`
filters on **display-name substring alone** — no content filter, no privacy filter:

```swift
dataService.makers.filter { $0.displayName.lowercased().contains(q) }
```

So typing `new` returns **twenty rows reading "New Creator · 0 tours"**. The rest are real people's
names and one `EHKY-APPL`. They are abandoned maker signups — someone opened the maker flow and
never finished — and **25 of the 27 carry `isPrivate: false`**, so nothing downstream suppresses them.
⚠️ **Two carry `isPrivate: true` and are served anyway**, which is the part worth a second look: the
payload contains `isPrivate`, `userId`, `avatarURL` and `bio` for every one of them, and no consumer
code reads the flag.

  - **Not fixed here** — it is `Features/Search/` + possibly `Data/`, so code-class, and the right
    shape is a decision: filter client-side, or stop the RPC emitting content-less makers (cheaper —
    it is also payload nobody can use). The second is the better fix and is a one-function change to
    `get_catalog_core`.
  - ⚠️ **Adjacent to [#820](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/820)**, which is open
    and fixes the *counts* on these same rows. Whoever takes that PR should see this first: #820 makes
    the "0 tours" subtitle refresh correctly, which is right, but the rows should not be there at all.


**The link-pin failure overlay's false-positive case is watched, not proven (#785, 2026-09-10).**
Failure is inferred from the absence of the iframe's own `load` event within 12 s, because a
cross-origin iframe cannot fail where `WKNavigationDelegate` can see it. The only regression route
is therefore the **false** failure — the message over a player that works — and the owner's
verification was, in their words, *"not super extensively"*. It is designed to be survivable (the
message is an overlay above a player that stays mounted, so a late `load` clears it by itself) and
19 tests pin the transition table, but **a platform whose embed page never fires `load` would show
the message on every one of its pins.** If a report of "that message on a video that plays" ever
arrives, the fix is a reachability probe as a second, positive-only signal — not a longer deadline.

**⚠️ UNGROUPED PLACE CANDIDATES, catalogue-wide (2026-08-27, owner asked for report-only).**
Re-derive with **`python3 scripts/check-place-candidates.py`** — do not quote the table below.

**🔴 ONE EXACT COINCIDENCE WITH NO PLACE PAGE, and it is a known deferral, not a new fault.**
**Casa Lleó Morera** and the **Dreta de l'Eixample** walk share the coordinate
`41.39134849385539, 2.16545472553582` exactly — the walk's intro stop is wired to the landmark, the
standard convention. CLAUDE.md already records it as *"a place candidate, deliberately NOT created
here (a place needs its own copy, address and photograph; that is separate editorial work)."*
**⚠️ The checker exits 1 on it, so a clean exit is not the current expected state** — that is the
one outstanding item, and it clears the moment someone writes the Barcelona place.

**NEAR — same subject, not coincident. None is acted on.**

| pair | apart | note |
|---|---|---|
| The Jordaan / The Jordaan (Amsterdam) | 136 m | **Identical titles.** Could be a place or could be a duplicate — open both before deciding |
| Gamla stan 1859 / Gamla stan (Stockholm) | 301 m | A historical tour and a present-day one of the same quarter |
| Benesse House Museum / …Outdoor Works (Naoshima) | 455 m | The museum vs its outdoor works |
| Tibidabo / Tibidabo Amusement Park (Barcelona) | 48 m | **🔴 NOT a candidate — settled.** #541 left these separate: a mountain and a funfair are two subjects. Do not re-raise |
| Chinatown (pin) / two Atlas Chinatown tours (SF) | 257 m, 395 m | **Owner declined 2026-08-27** — a district is not a site. Do not re-propose |

**🔴 THE PROCESS GAP THAT PRODUCED THIS ROW.** The SF batch shipped three place candidates without
anyone asking — the owner spotted them on a glance at the map. The evidence was in hand at the time
(two pins on an exactly identical coordinate, and two hero-slug collisions against existing Atlas
tours) and was read only as a rendering and filename concern. **A place-candidate sweep now runs as
part of the link-pin batch checks** so this never depends on a session noticing again.

**🔴 AND #629 MERGED AS AN EMPTY COMMIT.** The places were committed onto the local `main` by
mistake, then `git push -u origin <branch>` pushed the branch ref — still at an already-merged
commit. CI went green, GitHub said "successfully merged", and nothing shipped; re-landed as #630.
**"Successfully merged" is not evidence anything landed. Check `git log origin/main..HEAD` before
pushing and confirm the squash changed files afterwards.**


- **Supabase over-reports.** The RPC serves ~1,419 tours / 39 makers against a true 1,418 / 31.
  Upsert-only accumulation: rows deleted from `Tours.json` are never deleted from the database.
  Any count shown in-app inherits this.
- **2 dead gallery images** — The Oculus and The Charging Bull, Wikimedia 404s, deferred since
  2026-06-21.
- **Square Saint-Louis** is the one place still repeating an image; needs one sourced photo.
- **15 tours** missing a Place-type or Theme tag (validator warnings, content-only fix).
- **Policy pages** are long legal prose at 13px monospace — readability at length unconfirmed.
