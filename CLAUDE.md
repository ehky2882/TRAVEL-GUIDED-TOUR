# CLAUDE.md

## Project: Atlas

GPS-anchored audio tour platform. Makers record audio; consumers browse, download, and play while walking — audio auto-triggers at each stop. Closer to AllTrails than a guidebook.

**Spec:** `atlas_claude_code_prompt.md` — read before product decisions.
**Execution plan:** `ROADMAP.md` — read before implementation decisions.

Multi-platform SwiftUI. iOS 26.2 / macOS 26.2 / visionOS 26.2. Store name **Dozent**; the in-code
product name is still "Atlas" — legacy, do not "fix" it.

---

# ⚠️ READ FIRST — run this, do not trust this file for anything live

```bash
bash scripts/session-start.sh
```

**Many sessions work this repo at once.** They share one checkout, they open PRs against the same
files, and they finish in an order nobody controls. Nothing written in this file can keep up with
that, so the script prints the state instead of storing it: whose branch the shared checkout is on,
what PRs are open right now, which branches are ahead with no PR, whether the site and catalog are
serving, and what App Store Connect actually says.

**🔴 THE RULE: NEVER REPORT PERISHABLE STATE FROM A DOCUMENT.** This file is excellent at *durable*
facts — why a bug happened, why a decision was made, how a system works. It is **dangerous** for
facts that change with no commit, because nothing here updates when they do.

| Perishable — check it, never quote it | How |
|---|---|
| Program License Agreement, agreements, tax, banking | No API. A recent build that uploaded and processed = accepted. Otherwise **ask the owner** |
| App Store **released** version | **Checkable from ANY session, no key:** `curl -s "https://itunes.apple.com/lookup?bundleId=com.ehky.TRAVEL-GUIDED-TOUR&country=us"` — returns `version`, `currentVersionReleaseDate` and the live release notes. Use this before saying you could not check |
| App Store **unreleased** version / build / review state | `scripts/session-start.sh` (App Store Connect API). ⚠️ **A remote/web session has no key** (`~/Downloads/AuthKey_*.p8` is on the owner's Mac), so the script SKIPS this check there — say you could not check it, or **ask the owner**. ⚠️ A build **rejected at upload with 90186 `Invalid Pre-Release Train`** is also evidence: that train closed because Apple approved the version |
| What is merged, open, or in flight | `scripts/session-start.sh` (never this file's prose) |
| dozent.world, gh-pages catalog | `scripts/session-start.sh` (HTTP check) |
| Stripe standing · EU DSA trader declaration | **Cannot be checked from here — ask the owner** |

**If you cannot verify one of these, say you could not.** Do not fall back to what is written here.

**🔴 This has already cost the owner real trust.** On 2026-08-19 they were told by four sessions in
a row that an agreement they had *already accepted* was unaccepted — each session read one stale
line here and repeated it as current fact (corrected in #550). The same failure had happened days
earlier with *"our account is in test mode"*, which was false and nearly went to Stripe. The rule
*"check the live system, not a project note"* was written after the first one and then not applied
to the second. **Both were caught by the owner, not by us.**

And the line directly above this block used to read *"V1: Consumer-side only. No backend, auth,
payments, or maker upload"* — while the app shipped accounts, Supabase sync, ten paid IAP tiers and
a tour-upload wizard, and sat in App Store review. It was the **third** instance, in the first ten
lines of the file every session reads.

---

## Session workflow

- **⚡ Web/remote sessions CAN now build + ship real app features — no Mac required (since 2026-07-19).** The on-demand signed-TestFlight CI pipeline (`.github/workflows/testflight.yml`) builds + signs + uploads a device-testable TestFlight build from any branch on a cloud Mac. So a Linux web session writes SwiftUI/app code, pushes a branch, triggers a build (Actions → Run workflow, or a PR `build` label), and the owner reviews it on their phone — then merges. **This is proven: Journeys (PR #395) and Group Listen (PR #396) were both built end-to-end in web sessions and shipped this way.** The old rule "implementation work needs a local Mac session" is **retired** — do NOT tell the owner a feature has to wait for a local session. Details: `docs/testflight-ci.md`; § "On-demand signed TestFlight builds" in Current State.
  - **How a web session ships a feature:** write code on a branch → push → (open a PR so `ci.yml` runs the simulator build + unit tests, the web-session equivalent of `test_sim`) → trigger `testflight.yml` (Actions → Run workflow on the branch, or add the `build` label to the PR) → owner installs the TestFlight build + reviews on device → merge on owner OK + green CI. Repo is **public → Actions minutes are free**, build as often as needed.
  - Web sessions still can't run `test_sim`/simulator locally (no Mac in-session) — `ci.yml` on the PR is the stand-in. Device-only features (Group Listen sync, GPS geofence) still need the owner's real device(s) to verify.
- **Web sessions remain great for** project management, content uploads, planning, and now full feature builds. A separate local session is optional (for tight iterative simulator work), not required.
- Owner does not use Terminal. Claude handles all shell/git work.
- **Supabase / SQL / backend infra is beyond the owner's technical comfort — hand-hold maximally.** When guiding through Supabase (or any dashboard/SQL/infra) work: give **exact copy-paste-ready SQL blocks** (don't link to repo files — the repo is private and links 404), walk the dashboard **click-by-click**, explain each confirmation prompt (e.g. the "destructive operations" warning is just the `drop … if exists` lines on a fresh DB — safe), and never assume Terminal. The owner runs SQL by pasting into the Supabase **SQL Editor**.

## Claude Automation Rules

These happen **automatically, without the owner asking**.

| # | Trigger | What Claude does automatically |
|---|---------|-------------------------------|
| 1 | Every session start | **Run `bash scripts/session-start.sh`** (§ READ FIRST) + read the latest HANDOFF file — before any other work. It prints live state; this file does not have it. |
| 2 | After any edit to `Resources/Tours.json` | Run `swift scripts/validate-tours.swift`; fix errors before continuing |
| 3 | Before pushing any code PR | **Local (Mac) session:** call `test_sim` (XcodeBuildMCP); fix failures before pushing. **Web/remote session (no Mac):** open the PR so `ci.yml` runs the simulator build + unit tests (the `test_sim` stand-in); fix any red before merge. |
| 4 | Doc-only / content-only / asset PR is ready (CI green) | Squash-merge to `main` automatically — no owner approval gate. Resolve merge conflicts in-line. Delete the merged branch. **Code PRs (anything in `*.swift`, `*.xcodeproj`/`*.pbxproj`, `Assets.xcassets/`) wait for explicit owner OK + visual simulator confirmation — see § Merging PRs for the exact boundary.** |
| 5 | Session ends (touched code or content) | Write `archive/HANDOFF-YYMMDD.md`; add a **one-line** row to `archive/README.md` (it is an index — the long account belongs in the handoff itself) and update `ROADMAP.md`. **🔴 Do NOT append a session narrative to this file.** That is what grew it to 1.5 MB — ~409,000 tokens on *every request of every session* (see § Current state). Touch `CLAUDE.md` only when a **durable rule** changes; a durable *lesson* goes in `docs/lessons.md`; everything else is the handoff's job. |
| 6 | Stale merged `claude/*` branches detected | Delete them via `git push origin --delete` — no prompting |
| 7 | Owner asks for a TestFlight build | **Web/remote session (preferred, no Mac):** push the branch, then trigger `.github/workflows/testflight.yml` (Actions → Run workflow on the branch, or add the `build` label to its PR) — CI builds + signs + uploads automatically; build number = `github.run_number` → `1.1 (N)`. See `docs/testflight-ci.md`. **Local (Mac) session:** bump `CURRENT_PROJECT_VERSION` in `project.pbxproj`, commit + push, `xcodebuild archive` (`docs/testflight.md`), owner uploads via Organizer. |
| 8b | **New city drop received, BEFORE wiring anything** | **Run `python3 scripts/check-coordinates.py --drop "<folder>" --city "<City>, <Country>"`.** A wrong coordinate is the only defect that is invisible to every other check — the validator passes, CI compiles, every URL 200s, and the tour simply never fires. It has shipped twice from the same upstream pipeline (Barcelona ×10, Milan ×2), **always displaced north**. Fix every GROSS before wiring; read every UNVERIFIABLE by hand; and **check the BIAS line — if the northward offset is gone, upstream has been fixed, and if it is still ~+10 m it has not, however clean the gross list looks.** |
| 8 | New tour added (to `Tours.json`) that lacks images | Run the image pipeline (§ Image Pipeline) automatically — no prompting — and **reply with a numbered, labeled contact sheet of ~12 verified CC0 candidates per tour so the owner can pick hero + gallery by number** (e.g. `"3 hero, 1, 7, 9"`). This is the standard "upload tours without images" flow. **Exception: owner-supplied images (Portugal/Porto/Lisbon tours) — do not run pipeline, use the provided assets.** **Always finish with `python3 scripts/check-image-duplicates.py --maker <CODE>` — or **`--pins`** for a link-pin batch (§ Image Pipeline step 8) — it is the only thing that catches an image written under the wrong tour's filename.** |
| 9 | Triggering ANY TestFlight build | **Always attach build notes — never ship a mystery build.** Provide two short sections: **What changed** (the features/fixes in this build) and **What to test** (concrete on-device steps + anything device-only). Put them in **(a)** the reply to the owner in chat, **(b)** the build's `notes` workflow input (Actions → Run workflow → *Build notes*, or the trigger call's inputs) — **the workflow then auto-attaches them to the build's "What to Test" field in TestFlight** (confirmed working 2026-07-25, via fastlane `upload_to_testflight` with `distribute_only: true` + `app_platform: "ios"`; falls back to PR title+body, then commit subject), so the owner reads them right in the TestFlight app — and **(c)** the PR body if a PR exists. Keep it plain-English for a non-technical owner. |
| 10 | Opening or merging a PR · dispatching a TestFlight build · finding or clearing an owner-blocked item | Update the matching table in **`STATUS.md`** in the same commit — it is the live board of what is in flight across all parallel sessions (open PRs, which build number carries which branch, what is owed by the owner). **Re-derive, never predict:** `gh pr list --state open`, and read the build number back from the Actions run list after dispatching. `STATUS.md` holds only current state; finished work moves to `CLAUDE.md` § Current State. |
| 11b | Editing catalog data BY HAND in the Supabase SQL Editor | **End with `select public.refresh_catalog_snapshot();`.** The catalog is materialised (`backend/catalog_snapshot.sql`) — `get_catalog()` serves a pre-built row, so an upsert is invisible to the app until the snapshot is rebuilt. `seed_from_toursjson.py` does this itself, so a normal content merge needs nothing. |
| 11 | Applying ANY SQL that touches `get_catalog` — or the owner reporting a feature "missing" that the code clearly ships | Run `python3 scripts/check-catalog-contract.py`. It asks the LIVE RPC what keys it returns and diffs them against the Swift models, which is the only way to catch a dropped key: every one of them is optional in Swift, so it decodes as nil and the feature silently stops existing — no crash, no log, no failed CI. This is how `places`, `priceTier` and `isPrivate` vanished for 14 hours on 2026-08-19. **Run it after the migration, not before.** |

## ⚠️ Egress — `get_catalog` is 3.4 MB and Supabase bills every byte

**2026-09-08: the owner was emailed for exceeding the free egress quota.** The
cause was not growth. `get_catalog()` returns the **whole catalogue in one
document — ~10.5 MB raw, ~3.4 MB gzipped** — and there is no way to ask it
"has anything changed?" (it is a POST RPC, so no ETag, no `If-None-Match`,
no 304). **A fetch that finds nothing new costs exactly as much as one that
finds a whole new city.** More than half of it is text no one is looking at:
`stops.transcriptText` is **38%** of the payload and `longDescription` another
**18%**, both sent for all 1,552 tours on every fetch.

So the rules below are not micro-optimisation — they are the difference
between a session costing 44 MB and costing 8 KB.

| If you need… | Do this | Cost |
|---|---|---|
| the whole catalogue (keys, contract, audits) | `curl --compressed` / `Accept-Encoding: gzip` — **neither curl nor urllib asks for compression on its own** | 3.4 MB (was 10.5) |
| only the **status code** (liveness / timeout probes) | also `--max-filesize 2000`; the status arrives in the headers before the body, so a 57014 timeout is still caught. ⚠️ curl exits **63** on success here — read `%{http_code}`, not the exit code | **2 KB** |
| only a **row count** | `GET /rest/v1/tours?select=id&limit=1` with `Range: 0-0` + `Prefer: count=exact`; the answer is in the `content-range` response header | **47 bytes** |
| the catalogue's **freshness** | `POST /rest/v1/rpc/catalog_snapshot_age` | **34 bytes** |

🔴 **Egress is billed on the COMPRESSED bytes, so measure compressed.** Raw size
overstates text fields badly and two separate cuts here were nearly decided on
it: `longDescription` is **13.3% raw but 8.2% gzipped**. Save one payload
(`curl --compressed … -o catalog.json`), then in Python remove one key at a
time and `len(gzip.compress(...))` the result — that one saved copy answers
every such question afterwards for free.

⚠️ **The count query counts DB rows, not app-facing tours.** Link pins are
`tours` rows with `kind='link'`, so it returns tours **+** pins (3,042 today
against the RPC's 1,553 tours). Use it for "is the row count what I expect",
never as the catalogue's tour count.

**🔴 Never poll `get_catalog` in a loop.** `scripts/session-start.sh` sampled it
**four times per session** purely to read a status code and threw all of it away
to `/dev/null` — **44 MB of egress at the start of every session**, likely the
single largest line item behind that email. It is now 8 KB and reports the same
`4/4 OK`. If you add a check that touches the RPC, the flags above are
load-bearing; do not "tidy" them off.

**⚠️ The app has the same shape, and raising the debounce only buys time.**
`DataService.foregroundRefreshInterval` is **900s** (was 60 — see the comment on
that init, which explains why it is an egress dial and not a freshness dial). A
cold launch always refreshes regardless.

### 🔴 The 2026-09-10 escalation, and what the dashboard actually said

A second notice arrived on **2026-09-10: 11.82 GB against 5 GB, grace period cut
from 4 October to 13 September.** The per-day breakdown settles the cause for
good, and it is worth knowing because two plausible theories were both wrong:

| | |
|---|---|
| **PostgREST** | **100.0% — every single day** |
| Auth | 28–64 KB/day |
| Storage | 977 bytes – 20 KB/day |
| Edge Functions | does not appear at all |

So it is this payload and nothing else. ⚠️ **238,583 Edge Function invocations
looked alarming and produce essentially zero egress** — do not chase that
number. ⚠️ And **it is not the users**: MAU was **17**.

The daily figures, which are the honest scoreboard for every fix here:

| 8 Sep | 9 Sep (the `--compressed` / debounce fixes land) | 10 Sep |
|---|---|---|
| **1,963 MB** | **493 MB** | **241 MB** |

The allowance is 5 GB/month ≈ **167 MB/day**. That is the number to beat.

**Two fixes now exist for it:**
1. **The cheap version check** — the app asks `catalog_snapshot_age()` (34 bytes)
   before downloading, and skips the fetch when nothing changed. Built; see
   `docs/catalog-version-check-design.md`. **Cuts how OFTEN we pay.**
2. **The transcripts are off the wire** (`backend/drop_transcript_from_catalog.sql`,
   2026-09-10). `stops.transcriptText` was **1.105 MB of 2.945 MB gzipped —
   37.5% of every byte billed** — sent for all 1,924 stops on every fetch and
   **displayed by no consumer screen at all** (only `Models/Stop.swift` and the
   maker paths, which query the `stops` table directly). Not a feature
   withdrawn; a field nobody read, taken off the wire. The column is untouched,
   and `String?` in Swift means every build already in the field decodes its
   absence as nil — so it needs no App Store release. **Cuts how MUCH we pay.**
   `check-catalog-keys.py` now carries a **`FORBIDDEN_STOP`** set that fails if
   the key ever returns: the damage runs that way, and nothing else would notice.

⚠️ **`longDescription` was considered in the same pass and deliberately KEPT.**
The "18%" once quoted here was **raw**; gzipped it is **8.2%**, and unlike the
transcripts it is *used* — `TourDetailView` renders it, `SearchView` searches
it. 8% does not buy a visible regression.

**What is still NOT fixed:** when anything changes, the app downloads all 1,552
tours. Delta or city-scoped fetching is the remaining step, and is not built.

## Image Pipeline

Standard process for sourcing hero + gallery images for tours that don't have owner-supplied assets. Run this automatically whenever a new tour is added without images, or when the owner asks to improve existing images.

**Tools:** Unsplash API + Openverse API (sources) → Gemini vision (verification gate) → Pillow (resize/crop) → gh-pages (hosting) → Tours.json patch.

**Sources & API keys** (owner pastes secret-bearing keys fresh each session — do not store):
- **Unsplash:** `Client-ID <key>` header on `https://api.unsplash.com/search/photos`. Generic/atmospheric travel shots; weakest at exact-subject match.
- **Openverse:** `GET https://api.openverse.org/v1/images/` — aggregates 800M+ CC/public-domain works across 45+ sources (Wikimedia Commons, Flickr, Europeana, …) in one call. Search the place by name. No key needed for low volume, but **anonymous is throttled hard (~5 req/hr, 100/day)** — too low for a full pipeline run. To get the Standard tier (much higher limits): register once via `POST https://api.openverse.org/v1/auth_tokens/register/` (JSON: `name`, `description`, `email`) → returns `client_id` + `client_secret`; exchange them for a Bearer token via OAuth2 `client_credentials` at `POST /v1/auth_tokens/token/`, then send `Authorization: Bearer <token>`. Useful query params: `q`, `license`/`license_type`, `source`, `category`, `aspect_ratio=wide`, `size`, `page`, `page_size`. **License policy (owner decision 2026-06-08): prefer public-domain only — `license=cc0,pdm`.** The app has NO attribution UI (no credit field on `Tour`), and CC BY / BY-SA legally require crediting creator + license. PD images (`cc0`, `pdm`) carry no such obligation, so they're safe to ship as-is. Only fall back to BY/BY-SA if PD coverage is too thin *and* the owner OKs it for that tour. Wikimedia downloads: send a descriptive `User-Agent` and space requests ~1.5s apart — `upload.wikimedia.org` returns **HTTP 429** on rapid bursts. **Caveat: Openverse depth varies wildly by subject** — strong for some landmarks, near-empty for others (e.g. Seagram Building = one Wikimedia "Park Av" series + false matches). For a thin subject, query **Wikimedia Commons directly** (MediaWiki API, no key — e.g. the building's `Category:` page) for a deeper, cleaner pool, or add Unsplash.
  - ⚠️ **PD-only and "modern photos" pull AGAINST each other on famous old landmarks** (Rome extras, 2026-07-27). Public-domain imagery of a well-known monument is overwhelmingly 19th-century prints, because modern photographs of it are rarely released as PD — so a strict `cc0,pdm` search returns beautiful engravings and almost no photography. After mining Openverse *and* Commons deeply, Piazza del Quirinale / Santa Maria Maggiore / Trajan's Column / Porta San Sebastiano yielded only **1–2 usable modern photos each**. **Unsplash is the practical source for these** (modern, and needs no credit line, so it's policy-safe), with **owner-supplied photos** the reliable fallback — the owner pasted 3 of the 7 Rome heroes directly. Don't grind PD sources for a subject that plainly has no PD photography; say so early and ask.
  - **Unsplash free tier is 50 searches/hour**, and a full pipeline run burns it fast (`per_page=30` + 2 pages × 5 queries × 2 subjects ≈ the whole budget). Check `x-ratelimit-remaining` before a big sweep; on 403, the window resets hourly. Budget queries across subjects rather than exhausting them on the first one.
- **Gemini:** `?key=<key>` on `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent`
- Gemini key format: starts with `AQ.` (NOT `AIzaSy` — do not prepend anything)

**Pipeline steps:**
1. **Search** — 5–6 targeted queries per tour, ~3 results each, covering different vantage points (exterior, interior, aerial, detail, night, golden hour, etc.). **Sourcing order under the CC0-only policy:** (a) **Openverse** `license=cc0,pdm` (search the landmark by name); (b) if too thin, **Wikimedia Commons directly** filtered to PD (the building's `Category:` page, no key); (c) **Unsplash** (`orientation=landscape&content_filter=high`) for atmospheric coverage — Unsplash needs no per-image credit so it's policy-safe. Filter to images that can crop to 1200×900 without upscaling (`min(w,h)≥900` and the long side ≥1200). Dedupe by image URL before the verify step.
2. **Verify — TWO INDEPENDENT GEMINI CALLS, never one combined question.** Both must pass.
   - **Gate A — "is this a MODERN COLOUR PHOTOGRAPH?"** Reject engravings, etchings, lithographs, drawings, paintings, book-page scans, historical B&W/sepia prints, antique photographs, maps, plans, museum catalogue reproductions.
   - **Gate B — "is this the required subject?"** with the subject described physically (what the viewer would actually see) **and the look-alikes named explicitly** ("answer NO if this is instead: …").
   - ⚠️ **Why two calls (learned the hard way, Rome extras 2026-07-27):** a single compound prompt ("is this the subject AND a usable photo, not an engraving…") gets answered on subject match only — the model silently drops the second half. That shipped a whole set of **Rijksmuseum 19th-century prints** to the owner as "photos" of Piazza del Quirinale and Santa Maria Maggiore. Owner: *"i need actual photos not scans of old books."*
   - ⚠️ **Naming the distractors is what catches wrong-monument errors.** Without it, Gate B passed the **Column of Marcus Aurelius** as Trajan's Column and **Porta Asinaria** (3 arches) as Porta San Sebastiano (1 arch) — both reached the owner, who spotted the second. With distractors named, both were rejected. For any subject with a famous sibling (columns, city gates, basilicas, obelisks, squares), list the siblings in the prompt.
   - **Mandatory for Openverse — its result titles are unreliable** (generic strings like "Park Av Nov 2025 01", or "Rúa preto da Piazza del Quirinale" = a street *near* the square); never trust Openverse metadata for subject match, always verify the pixels. Typical survival rate through both gates is **~25%** (Rome extras: 375 candidates → 105).
   - **Exclude `rijksmuseum` as an Openverse source** (`excluded_source=rijksmuseum`) and drop any title containing `RP-F` — that single collection is the origin of nearly all the "old book scan" false positives under a PD-only policy.
3. **Label** — Present the verified candidates (~10–12; fewer if the subject is thin) as **individual full-size images, sent inline** (each ~1000px long side, with a large number badge + source/license tag burned into the corner), batched a handful per `SendUserFile` call with a group caption. **Do NOT use a small contact-sheet grid** — owner feedback (2026-06-08): grid tiles are too small to judge. The number burned onto each image is how the owner refers back to it. Use a distinct number namespace per source when mixing (e.g. `1–35` CC0 vs `U01–U32` Unsplash) so picks are unambiguous.
4. **Owner picks** — Owner replies e.g. `"U07 hero, U01, U22, U20"`. First = hero; the rest = gallery order. Default target is **1 hero + up to ~5 gallery** (owner can pick fewer/more, mix sources, or say "none, leave as-is" / "keep current hero" / "find more on unsplash").
5. **Process** — Crop selections to final 1200×900 WebP (no label). Name: `{audio-slug}_hero.webp`, `{audio-slug}_2.webp`, etc.
6. **Upload** — Commit to `gh-pages` branch under `images/`. Pull + rebase if non-fast-forward.
7. **Patch Tours.json** — Replace `heroImageURL` + set/update `additionalImageURLs`. Commit + push to session branch.
8. **Verify the bytes, not the filename** — run `python3 scripts/check-image-duplicates.py --maker <CODE>`, or **`--pins`** for a link-pin batch (`--all` covers both and takes ~7 minutes). **This is not optional when staging a city or a batch of pins.** ⚠️ **`--maker <CODE>` is tours only, deliberately** — a pinned creator's handle collides with city codes as a substring (`STO` matches `@urbanstoriesyt`), so scoping a city must not sweep pins in. Two images written back-to-back can silently share content: in the Madrid batch the Thyssen hero was byte-identical to the Reina Sofía hero written 40 seconds earlier, and shipped the wrong building for a month. `validate-tours.swift` cannot see it — the URLs are distinct and all return 200. **⚠️ The same run ALSO reports shared URLs — two entries pointing at ONE file — which is a different bug the byte check is structurally blind to** (one file hashed once is one file, so it never forms a group): the London Natural History Museum tour played Los Angeles' narration for six and a half weeks because both used the bare slug `natural-history-museum`. That half is **catalogue-wide on every invocation and deliberately NOT scoped** (the collision spanned two cities and two makers, so any scope would hide it) and costs nothing — no network. **When an owner-pasted image is the only copy, hash the written file against the decode before committing** (a fresh web-session container has no prior transcripts, so a lost paste is unrecoverable). After a gh-pages push, **confirm the live URL's hash** rather than trusting the push — Pages deploys can be cancelled and serve stale for ~10 min.

9. **🔴 CORRECTING AN IMAGE MEANS A NEW FILENAME — NEVER OVERWRITE BYTES AT A LIVE URL.** Publish the replacement as its own file (`..._hero-2.webp`) and repoint `Tours.json` at it. **A phone that has downloaded a tour reads that tour's photographs off its own disk and never asks the server again** (PR #567), and the offline fallback serves whatever `URLCache` holds for a URL (PR #568) — so bytes swapped underneath an unchanged URL reach neither. Someone who downloaded a tour would keep the wrong photograph until they deleted and re-downloaded it, which nobody would think to do. **A new filename is a new address, so every phone fetches it automatically.** This is exactly how the Thyssen hero was corrected — in place, at the same URL — and that fix would not have reached a downloaded tour. Costs nothing; the old file can stay on gh-pages, orphaned, or be deleted once nothing references it.

**Special cases:**
- Owner says "keep current hero" → leave `heroImageURL` as-is; only add `additionalImageURLs`.
- Owner says "keep current hero in gallery" → put original URL as last entry in `additionalImageURLs`.
- Too few verified images → tell owner, offer to fetch more with different queries, or skip.
- Unsplash rate limit (50 req/hr free tier) → pause, note time to reset, continue other work.
- Openverse rate limit → anonymous is ~5 req/hr (100/day); if hit, authenticate (register → Bearer token, see Sources above) for the Standard tier, or fall back to Unsplash-only for that run.
- Openverse subject too thin (few/no PD matches) → say so, then try Wikimedia Commons directly (the building's `Category:` page) and/or Unsplash, rather than settling for off-subject or BY-SA shots.

**Audio slug** = the filename stem of the tour's `audioURL` (e.g. `audio/empire-state-building.mp3` → `empire-state-building`). Use this as the image filename prefix. Some older slugs use dots or mixed case — match exactly.

**Image URL base:** `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`

**gh-pages worktree:** `/tmp/ghpages` (already set up; `git pull origin gh-pages --rebase` before push if rejected).

## Current state

🔴 **Run `bash scripts/session-start.sh` first — it prints live state; this file does not have
it.** § READ FIRST above explains why that is not optional.

**🚀 Dozent is live on the App Store at 1.1.1**, released **1 September 2026, 15:23 UTC**, on
build 139. This is the durable fact; **the live number is not** — the released version is
checkable from any session with no key (§ READ FIRST's table has the one-line `curl`), so
re-derive it rather than quoting this paragraph. `MARKETING_VERSION` on `main` is **1.1.2**, and
the only app code the public lacks is [#728](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/728),
the bottom module going missing — everything else since is catalogue, which reaches 1.1.1 over the
air, because **1.1.1 understands `linkPins` and `places` where build 66 could not.** ⚠️ **This
board said the update was still owed for a week after it shipped**; the full account of how that
happened is in `archive/STATUS-HISTORY.md` (§ "1.1.1 SHIPPED") and the rule it produced is in
`docs/lessons.md` § 2.

**Where the history went.** Every dated `## Current State` block written between 2026-05-25
(session 8) and 2026-09-07 (session 148) — 34 of them — now lives verbatim in
**`archive/CURRENT-STATE-HISTORY.md`**. Nothing was deleted.

It was moved out on **2026-09-08** because it had reached **1.47 MB: 97.7% of this file, roughly
409,000 tokens injected into every request of every session.** That single fact was producing
three symptoms at once — plan limits burned through in a few turns, `prompt too long` on short
prompts (the history exceeded a 200k context window on its own), and sessions that stopped
auto-compacting (compaction summarises the *conversation*; this file is re-injected fresh
afterwards, so none of it could ever be reclaimed).

**⚠️ Search that archive, never load it whole** — doing so reinstates the problem for the rest of
the session:

```bash
grep -n "Thyssen" archive/CURRENT-STATE-HISTORY.md            # a specific incident
grep -n "^### .*Barcelona" archive/CURRENT-STATE-HISTORY.md   # a city launch
```

Most entries name an `archive/HANDOFF-YYMMDD*.md` carrying the fuller account; 94 distinct
handoffs are cited, and `archive/README.md` indexes 215 of the 221 files in `archive/` —
**re-derive that count, never quote it** (`grep -c '^| ' archive/README.md`), and note the
index carries one row for a handoff that was never committed, marked as such.

**The rules that history taught** are lifted into **`docs/lessons.md`** — verification discipline,
the live-systems-over-documents rule, content and geocoding traps, the image rules, the Supabase
`get_catalog` hazard, shell and gh-pages gotchas, SwiftUI patterns, and how the owner works. Read
it **before a tour or link-pin batch, before touching `get_catalog`, and whenever a check tells
you something surprising.** It is short enough to read in full.

### Key facts
- **1552 tours + 1870 link pins, 387 makers, 1924 tour stops (3794 including one per pin), 289 places covering 697 entries** in `Resources/Tours.json` (re-derived 2026-09-12 on the base carrying `0f73983`; **499 cities, 64 countries**). 🔴 **The link pins are NOT in the `tours` array — they are a sibling top-level `linkPins` array**, because one unknown `kind` inside `tours` fails the whole catalog decode on every build shipped before `TourKind.link` (see `TRAVEL GUIDED TOUR/Data/ToursData.swift`). The app merges them back at decode, so everything downstream still sees one list. **34 of the makers are Atlas studios, the other 353 are pinned creators (124 TikTok, 217 Instagram, 12 YouTube) — pinned creators now outnumber the studios ten to one, and Instagram has overtaken TikTok as the largest platform.** ⚠️ This line has gone stale TWENTY-TWO times already, and **three parallel sessions invalidated it on the same afternoon** — it has been rewritten inside a single session more than once because `main` moved under it every time, and not one session's own number has survived its merge — #733 invalidated it AGAIN during the very merge that was correcting it, while that branch sat open, and **#738 did it a fifteenth time while session 144’s own PR sat open with green CI, so it went stale inside the very merge that was correcting it — then #737 and #739 did it a sixteenth, invalidating session 145’s own number while ITS PR sat open, #742 did it a seventeenth while session 147’s batch was being validated, and #743 did it an eighteenth while session 148’s heroes were mid-upload, and **#758 did it a NINETEENTH inside its own merge — it landed 83 pins and left this line reading 1,343; a later session simply counted and got 1,426 — and a TWENTIETH time when #769 made Trinity Church, Madison Square Garden and Penn Station places and left this line reading 137 against a real 140 — and a TWENTY-FIRST time: this line read 1,551 pins while the catalogue held 1,588 — and a TWENTY-SECOND time, when it read 1,588 / 353 against a real 1,635 / 354 before session 155's own batch had added anything, because #784 and #787 both landed between the last correction and that session's start**. Session 156's own #790 (21 pins) landed cleanly on top of #789 with nothing else merging mid-flight — and #801 moved the **places** figure from 141 to **181** in one merge, the largest single jump it has taken; ⚠️ #802 landed between that branch's CI going green and its merge, so `main` moved under it once more — and a TWENTY-THIRD time, hours later: this line had just been corrected to 1,773 / 380 against the base carrying `ddba8ba` when #811's six pins merged and made it stale again, and `places` moved 250 → 266 in the same window — then a TWENTY-FOURTH, inside the very PR correcting the twenty-third: #814 and #815 landed while that docs branch waited on an 18-minute simulator build, taking 1,779 / 381 to 1,794 / 384 before it could merge, which is the whole argument for never quoting this line — **re-derive it, never quote it** — `grep -c '"displayName": "TikTok \|"displayName": "YouTube \|"displayName": "Instagram '` against the catalogue is the whole check. (101 Atlas Studio NYC + 100 Atlas Studio LDN + 71 Atlas Studio KYO + **68 Atlas Studio BCN** + **48 Atlas Studio MIL** + 66 Atlas Studio LIS + 63 Atlas Studio TYO + 57 Atlas Studio BKK + 54 Atlas Studio OPO + 52 Atlas Studio HKG + 50 Atlas Studio PAR + 46 Atlas Studio RIO + **45 Atlas Studio STO** + **40 Atlas Studio CPH** + 43 Atlas Studio CNX + 43 Atlas Studio SEL + 43 Atlas Studio SGN + 42 Atlas Studio LAX + 42 Atlas Studio SAO + 42 Atlas Studio YYZ + 38 Atlas Studio AMS + 37 Atlas Studio ROM + 36 Atlas Studio BER + 36 Atlas Studio BUE + 35 Atlas Studio MEL + 35 Atlas Studio SFO + 34 Atlas Studio MAD + **30 Atlas Studio CPT** + 30 Atlas Studio ORD + 29 Atlas Studio SYD + 29 Atlas Studio YUL + 26 Atlas Studio DXB + 26 Atlas Studio RAK + 15 Atlas Studio NAO); audio on `gh-pages` at `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/audio/<file>.mp3`. **The catalog is remote-loaded** via `RemoteCatalogLoader`: since **PR #255 (2026-06-27)** the primary source is the **Supabase `get_catalog` RPC** (project "Dozent"), with `https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/Tours.json` as a fallback mirror, then the on-disk cache, then the bundled offline seed. `.github/workflows/publish-catalog.yml` still auto-publishes the gh-pages mirror on every content merge to `main`; **but Supabase is now primary, so content changes must also reach the DB (rerun `backend/seed_from_toursjson.py`)** or the mirror could be newer than the live source. (Shipped in **TestFlight 1.0 (50)**, live 2026-06-27.)
- **1480 single-stop + 72 multi-stop** — all geofenced. Copenhagen added 40 singles with no walks; Rio launched as 46 singles with no walks; São Paulo added 41 singles + 1 walk; Berlin added 31 singles + 5 walks; Marrakech added 26 singles with no walks; Buenos Aires added 34 singles + 2 walks; Chicago added 25 singles + 5 walks; Melbourne added 34 singles + 1 walk; Sydney added 29 singles with no walks; Cape Town added 30 singles with no walks; Barcelona added 66 singles + 2 walks; Milan added 47 singles + 1 walk; **Stockholm added 42 singles + 3 walks**. Multi-stop walks by maker: London 5, Paris 5, Amsterdam 5, Rome 5, Berlin 5, Chicago 5, San Francisco 4, Toronto 4, Los Angeles 4, Madrid 4, Montreal 4, Dubai 4, Seoul 3, **Stockholm 3**, NYC 2, Naoshima 2, Buenos Aires 2, **Barcelona 2**, Bangkok 1, São Paulo 1, Melbourne 1, **Milan 1**. The 4 originally-named NYC/London walks ("American Museum of Natural History: Four Facades" (5 stops, NYC), "Fifth Avenue Walk" (6 stops, NYC), "After the Fire: Wren's City" (6 stops, London), "Albertopolis" (6 stops, London)) are still the reference multi-stop test cases; AMNH unblocks M-qa items 6 + 7.
- **Bilingual titles (`English | native script`) on both tour + stop across the Asian bureaus:** Tokyo (TYO), Kyoto (KYO), Naoshima (NAO) — `日本語`; Hong Kong (HKG) — `中文`; Seoul (SEL) — `한국어`; Bangkok (BKK) — `ไทย`; Ho Chi Minh City (SGN) — `Tiếng Việt` (where a Vietnamese name exists; proper-noun venues carry a single name); and Marrakech (RAK) — `العربية` (18 of 26; same proper-noun rule).
- **All tours have `heroImageURL`.** NYC tours use CC-licensed Wikimedia Commons 1280px thumbs; Porto/Lisbon/Braga tours use owner-supplied webps on `gh-pages` at 1200×900. Tours that received a gallery this session have an `additionalImageURLs` array of webps under the same slug — see catalog for the full list. Tours may also carry an optional **`videoURLs: [String]?`** (`.mp4` on gh-pages under `videos/`) — **videos LEAD the carousel** (owner decision 2026-07-26), so a tour with one opens on it and the still hero becomes page two. **`backend/add_video_urls.sql` HAS been applied** — verified against the live `get_catalog` on 2026-08-23, which emits the key on every tour; no SQL is owed, and `seed_from_toursjson.py` carries `video_urls` so a content merge cannot wipe it. Each video is openable **fullscreen** (session 107), and a tour also carries **`videoRole: TourVideoRole?`** — `gallery` (the default: b-roll beside the photographs) or **`narration`** (the clip **is** the tour, so its play bar and picture scrub together). ⚠️ **A `narration` tour may carry exactly ONE video**, validator-enforced. **Two tours carry video:** `via-57-west` (**`narration`**, 1080×1920 vertical with audio — a generated stand-in, replace when real footage exists) and `shinsegae-media-facade` (**`gallery`**, two clips: a 1200×900 silent one, plus `landscape-test.mp4`, **a 1920×1080 test card rather than real content**, added so rotation has something to run against — one-line revert). ⚠️ **`video_role` must reach Supabase to have any effect** — `seed_from_toursjson.py` carries it and `backend/add_video_role.sql` has been applied and verified live, but a catalogue edit alone is never enough. ⚠️ An earlier Key-facts note said no tour carried video; that was already false when written.
- **Every tour carries `city` AND `country`** (`country` added session 99 — **466 cities, 64 countries** across tours and link pins together, re-derived 2026-09-10 on the base carrying `887a8a7`; the figures this line carried before that read 447 / 63 — the figures this line carried before that read 442 / 63 — the figures this line carried before that read 427 / 63 — the figures this line carried before that read 414 / 61; the figures this line carried before that read 404 / 59 — stale within hours, because #758 added 83 pins without touching them — and before that 389 / 58 — session 147's batch alone added **eleven countries**, the largest single expansion — and before that 359 / 47, the figures this line carried before that read 274 / 41, then 250 / 40, then 203 / 37 — and the 250 was already stale against `main`'s 259 when it was written, so **re-derive rather than quoting it** — `docs/app-store-screenshots.md` § Scale figures has the one-liner). `country` is denormalised onto the tour exactly as `city` is, so it travels with the content and updates over the air; **a new city batch must author it** or that tour drops out of the Settings → About count. `Tour.country` is optional so the bundled seed, the gh-pages mirror and maker-authored tours all keep decoding. Its column + `get_catalog` key are live (`backend/add_country.sql`, applied 2026-08-19).
- `MiniPlayerBar` above tab bar at all times: marquee titles, skip-forward-10s, progress ring, idle welcome message
- `MarqueeText.swift` in `Components/` — scrolls overflow text continuously
- AppIcon is placeholder (green sphere); AccentColor: **dark gold (brass) `#8B7535` — owner-confirmed brand color (2026-07-04)**, same value in light + dark deliberately; terracotta is fully removed
- Theme tokens in `Theme/Atlas*.swift` are placeholder values pending design pass (color is now decided; type/spacing still placeholder)
- `UIBackgroundModes=audio` now in explicit `Info.plist` (not INFOPLIST_KEY — Xcode ignores that for arrays)

- **Public surfaces (as of 2026-08-19):** website **`https://dozent.world`** (Vercel project `dozent-world`, deployed from `site/` on every push to `main`) — a **splash front page** plus `/about/`, `/privacy/`, `/terms/` and `/acceptable-use/`, all sharing `site/atlas.css`, a port of the app's `Theme/Atlas*.swift` tokens, plus **`/confirmed/`**, where Supabase Auth lands people after they tap the button in a signup email (unlisted in the footer, `noindex`) · **outbound mail sends as "Dozent" from `noreply@send.dozent.world`** via Resend on a verified subdomain (SPF + DKIM + DMARC), wired into Supabase as Custom SMTP; the body is `backend/email-templates/confirm-signup.html` and the Site URL is `https://dozent.world/confirmed/` — see `archive/HANDOFF-260909-2.md` · contact **`hello@dozent.world`** (ImprovMX free tier — **forwards to the owner's Gmail, receive-only**; replying as the domain needs a real mailbox). `Theme/AtlasLegalLinks.swift` holds the three URLs for the app, and `fastlane/metadata/en-US/{support,privacy,marketing}_url.txt` for the App Store listing — **all three must agree with the Privacy Policy URL registered in App Store Connect.**
- **🔴 `dozent.world` and `ehky2882.github.io` are two hosts with two jobs.** The github.io host is the **asset CDN** — every tour's audio and images, and **7,713 absolute URLs in `Tours.json` point at it**. Never attach the custom domain to GitHub Pages; it would redirect all of them.

See `ROADMAP.md` for full milestone history. Read latest `archive/HANDOFF-*.md` for mid-flight context.

## Session-start ritual (automatic — Claude runs this first, every session)

```bash
bash scripts/session-start.sh      # ← this replaces the checks below; it also reports live
                                   #   external state, which none of them could
```

It prints: whose branch the shared checkout is on, uncommitted work, open PRs with mergeability,
branches ahead of main with no PR, recent merges to main, the staged-content tracker read from
`origin/main`, live HTTP checks, and the App Store version/build state. **Read § READ FIRST at the
top of this file for why perishable facts must never be quoted from documentation.**

The underlying commands, if you need them individually:

```bash
git fetch && git status && git branch --show-current && git log origin/main..HEAD && gh pr list --state open
ls archive/HANDOFF-*.md | tail -1   # then read that file

# What is staged but not yet live? ALWAYS read this from origin/main, never from your branch:
git show origin/main:drafts/AUDIO-PENDING-SURVEY.md
# Wire-in spec for any staged city (slug/coord/category/hero+gallery) — also on main:
# ls drafts/*/README.md   ·   index: drafts/README.md
```

Run before any substantive work. Investigate uncommitted changes before acting on them.

**⚠️ Read the audio-pending tracker from `origin/main`, not from your checkout.** Staged drafts
(`drafts/<city>-batch*`, `drafts/<city>-*-walk`) live only on their staging branch and **never
reach `main`** — so `drafts/AUDIO-PENDING-SURVEY.md` on `main` is the *only* cross-session signal
that a staged city exists. Long-lived staging branches drift 100+ commits behind `main`, and their
copy of the tracker goes stale and contradicts reality (2026-07-28: a branch copy still listed Rome
as pending two days after Rome shipped). Same rule when writing: land a city's tracker row on `main`
via a docs-only PR **as soon as the batch is staged** — not at the end of the city, and never only
on the staging branch.

## Reading a check's result

🔴 **A check that cannot run must not be able to return a pass.** Three ways that
has already happened here, and the one habit that closes all three:

| Trap | What it looks like | The habit |
|---|---|---|
| **The stale output file** | `sed … && grep -n "<anchor>" f.py && python3 suite.py > out.txt; cat out.txt` — the `grep` matches nothing, the `&&` short-circuits, `python3` **never runs**, and `cat` prints a file left by a run two days ago. It reads exactly like a pass. | **Confirm the stamp on the first line before believing anything under it**, and prefer a checker's own `--out` over shell redirection. Every checker in `scripts/` now prints `RUN <name> · rev <hash> · <UTC timestamp>` first (`scripts/runstamp.py`); `--out PATH` truncates and stamps the file *before* the work starts, so a previous run cannot survive underneath it. A stamped file with no verdict line under it is a run that **died**, not a run that passed. |
| **`PIPESTATUS`** | `python3 check.py \| tail; echo "EXIT=$?"` reports **tail's** status, so a script that exited 1 reads as 0. | Read the exit code **directly**, never through a pipe — redirect to a file, or use `${PIPESTATUS[0]}`. |
| **The checker that fetched nothing** | `check-image-duplicates.py` once printed `OK — no suspicious duplicates` having failed every fetch with an SSL error. | A checker that cannot reach the network **exits 2 — COULD NOT VERIFY** and says so; it does not exit 0. Read the counts it prints, not only its verdict (a run reporting 161 images when 173 were uploaded is a finding). |

⚠️ **The 2026-09-07 stale-file case was caught only because the counts happened to
disagree** — the stale run said 22/22 where the current suite has 20 faults. Had
they matched, an unverified change would have shipped with an apparent clean bill
of health. Do not rely on that.

## Merging PRs

**Auto-merge (squash, no owner approval) — content/docs/assets/CI/test code:**
- `*.md`, `docs/`, `archive/`, `ROADMAP.md`, `CLAUDE.md`, `CONTRIBUTING.md`
- `Resources/Tours.json` (content additions and edits)
- `scripts/` (developer tooling, doesn't ship in the app)
- `TRAVEL GUIDED TOURTests/` (test target; doesn't affect the running app)
- `.github/workflows/` (CI definitions)
- Lint / tooling configs (`.swiftlint.yml`, etc.)
- Audio + image uploads to `gh-pages` branch

Flow for auto-merge PRs: open PR → wait for CI green → `gh pr merge --squash --delete-branch`.

**Wait for owner OK (visual simulator review required) — code:**
- Anything in `TRAVEL GUIDED TOUR/<source-folder>/*.swift` (`Audio/`, `Components/`, `Data/`, `Features/`, `Location/`, `Models/`, `Theme/`, `ContentView.swift`, `SplashView.swift`, the App entry)
- Xcode project file (`*.xcodeproj`/`*.pbxproj`)
- Asset catalogs (`Assets.xcassets/`)
- `Info.plist`

Owner reviews via iOS Simulator or TestFlight before merge — not by reading code. **Reason:** the previous auto-merge-everything policy (briefly in effect 2026-05-25/27) produced visible regressions on `main` that required follow-up fix PRs (#68→#69→#70 chain after #66; #77→#78 chain after #76). Pre-merge visual review catches these in the simulator and avoids the fix-forward thrash.

**Merge conflicts: resolve them automatically** when they're structural (file renames, neighboring edits, import reorderings, doc reformats, version-number bumps). Stop and ask only if the conflict reflects a real business-logic disagreement between two PRs.

**When in doubt, ask** — better to over-confirm than merge something the owner hadn't seen yet.

## Keep Docs in Sync (automatic — no prompting needed)

Every session that touched code or content writes `archive/HANDOFF-YYMMDD.md` and indexes it in
`archive/README.md`. A shipped milestone or a cut in scope also updates `ROADMAP.md`. Non-negotiable.

🔴 **The session narrative goes in the handoff, NOT in this file.** Appending it here is exactly
what grew `CLAUDE.md` to 1.5 MB — ~409,000 tokens on every request of every session, which
exceeded a context window on its own (§ Current state). Three things earn an edit to `CLAUDE.md`:

| Change | Where it goes |
|---|---|
| A **durable rule** changed (workflow, an automation rule, a convention, the pipeline) | `CLAUDE.md`, edited in place — replace the stale text, never append beside it |
| A **durable lesson** learned (a trap, a gotcha, a precedent worth not re-paying for) | `docs/lessons.md` |
| A **live count** moved (tours, makers, cities, countries) | `CLAUDE.md` § Key facts — **re-derived, never quoted from the previous value** |

Everything else — what shipped, what was verified, what is in flight, what the owner decided —
is the handoff's job, and `STATUS.md`'s for anything still in flight across parallel sessions.

## Repo Layout

| Path | Purpose |
|------|---------|
| `atlas_claude_code_prompt.md` | Canonical product spec |
| `ROADMAP.md` | Execution plan + milestone history |
| `docs/authoring-tours.md` | Tour content authoring guide |
| `docs/link-pin-runbook.md` | **How a batch of creator links becomes catalog entries** — the verified uuid5 id scheme, the `make-link-pin.py` → `merge-link-pins.py` flow that keeps pin JSON out of the conversation, hero-filename rules, and the traps. Read before a pin batch |
| `docs/cdn-decision.md` | Audio hosting decision |
| `docs/design-tokens.md` | Typography/color/spacing reference |
| `docs/places.md` | **What qualifies as a place page** — the owner's settled rules from ~60 decisions. 🔴 **TWO entries qualify; never wait for a third** (73% of places have exactly two). Two names for one thing is always a place; an editorial angle never is; **co-location is not identity**; a tenant is not the site; and a place is a COORDINATE, so one point must be honest for every member. Part-vs-whole is explicitly undecided. **Read before offering place candidates** |
| `docs/lessons.md` | **Rules this project paid for** — verification discipline, live-systems-over-documents, content/geocoding/image traps, the `get_catalog` hazard, shell + gh-pages gotchas, SwiftUI patterns, how the owner works. Read before a tour batch or any `get_catalog` change |
| `docs/partner-onboarding.md` | **Zero-to-first-upload guide for a non-technical contributor** — accounts, repo access, Claude Code on the web/desktop, and the link-pin job written for someone who has never used a terminal. Send this to a new content contributor |
| `.claude/skills/atlas-upload/SKILL.md` | The skill a content contributor loads ("use the atlas-upload skill"). Routes link pins / city drops / images / scripts and carries the guardrails a novice cannot be expected to know |
| `archive/CURRENT-STATE-HISTORY.md` | The dated Current State blocks moved out of `CLAUDE.md`. **Search, never load whole** |
| `archive/ROADMAP-STATUS-HISTORY.md` | The 113 dated `**Status (…)**` blocks moved out of `ROADMAP.md` § Where we are right now, which they had grown to 86% of. **Search, never load whole** |
| `archive/INDEX-DETAIL.md` | The long-form entries moved out of `archive/README.md`, which they had grown to 94% of. **Search, never load whole** |
| `archive/STATUS-HISTORY.md` | The finished items moved out of `STATUS.md` § 1, which they had grown to 72% of. **Search, never load whole** |
| `docs/launch-runbook.md` | **Step-by-step App Store launch walkthrough — start here to ship** |
| `docs/fastlane.md` | How the release automation works (lanes, metadata, screenshots) |
| `fastlane/` | The release toolchain: lanes, App Store metadata, screenshot config |
| `site/` | **The public website, `dozent.world`** — home + privacy/terms/acceptable-use. Deployed by Vercel (project `dozent-world`, Root Directory `site`) on every push to `main`. **Not** the asset CDN |
| `docs/testflight.md` | Per-release upload runbook (~10 min) |
| `docs/troubleshooting.md` | Xcode + git landmines from real incidents |
| `scripts/validate-tours.swift` | Validates `Tours.json`; run: `swift scripts/validate-tours.swift` |
| `scripts/make-place-menu.py` | **Regenerates `docs/place-candidates-260911.md`, the live place-candidate menu** — re-run it, never hand-patch it: 45 of the first sweep's rows became places within hours. Escapes pipes in bilingual titles (24 entries carry one) and refuses to write a table whose columns do not line up |
| `scripts/merge-link-pins.py` | Merges `make-link-pin.py`'s output into `Tours.json` disk-to-disk, so a batch's JSON never passes through context. Idempotent; refuses pins in `tours`, missing coordinates, and a non-byte-stable catalog |
| `TRAVEL GUIDED TOURTests/` | 6 XCTest classes, data/logic layer |
| `archive/` | Dated session snapshots |

**`validate-tours.swift` mirrors `Tour/Stop/Maker/TourCategory.swift` — update the script in the same commit if any model changes.**

## Build & Run

Use **XcodeBuildMCP tools** — prefer over raw `xcodebuild` shell commands.

| Task | XcodeBuildMCP tool |
|------|--------------------|
| Verify session defaults | `session_show_defaults` — **call first every session before any build/test** |
| Build for iOS Simulator | `build_sim` |
| Build + launch in Simulator | `build_run_sim` |
| Run unit tests | `test_sim` |
| Take simulator screenshot | `screenshot` |

**Run `test_sim` automatically before pushing any code PR.** Skip for doc-only, CI-only, `Features/`/`Components/`/`Theme/`-only, or `Tours.json` content-only changes.

Fallback raw commands (CI + macOS builds):
```bash
xcodebuild -scheme "TRAVEL GUIDED TOUR" -configuration Debug build
xcodebuild test -scheme "TRAVEL GUIDED TOUR" \
  -destination "platform=iOS Simulator,name=iPhone 16,OS=latest" -configuration Debug
```

## Architecture

```
TRAVEL GUIDED TOUR/
├── TRAVEL_GUIDED_TOURApp.swift    App entry + SwiftUI Environment setup
├── ContentView.swift              AtlasTabBar — 3 tabs: Home / Library / Me
├── SplashView.swift
├── Models/                        Tour, Stop, Maker, TourCategory, Tag, TourList, RecentSearch, LibraryEntry
├── Data/                          DataService, RemoteCatalogLoader, LibraryStore, TourListService, SaveState, TourSaveActions, RecentSearchStore, RecentlyViewedStore, ToursData
├── Resources/Tours.json
├── Audio/                         AudioPlayerService (AVQueuePlayer + lock-screen), TourDownloader
├── Features/
│   ├── Home/                      HomeView, HomeMapSection, CategoryChipRow, TourListCard, HomeRailsViewModel, RailCarousel
│   ├── Search/                    SearchBar, SearchView
│   ├── Tour/                      TourDetailView
│   ├── Player/                    PlayerView, MiniPlayerBar
│   ├── Maker/                     MakerView
│   ├── Library/                   LibraryView, LikedEmptyState, LibraryTourRow
│   ├── Lists/                     TourListDetailView (named lists AND Liked), TourListTarget, TourListPresenter, TourListEditorSheet, TourListMembershipSheet
│   └── Settings/                  SettingsView, ManageDownloadsView
├── Location/                      LocationManager, ProximityMonitor
├── Components/                    HeroImageView, MarqueeText, TagChip, BottomSheet, PlatformHelpers
├── Theme/                         AtlasColors, AtlasTypography, AtlasSpacing
└── Assets.xcassets/
```

Environment services (instantiated once at app entry, injected via SwiftUI Environment — never in views): `DataService`, `LibraryStore`, `RecentSearchStore`, `RecentlyViewedStore`, `LocationManager`, `AudioPlayerService`, `TourDownloader`.

## Conventions

- `@Observable` not `ObservableObject`. `NavigationStack` not `NavigationView`.
- Hero images: use `Components/HeroImageView.swift` — never raw `AsyncImage`.
- Audio: always through `AudioPlayerService`. Never create `AVPlayer` in a view.
- No third-party libraries in V1. Apple frameworks only: SwiftUI, MapKit, CoreLocation, AVFoundation, MediaPlayer, SwiftData/UserDefaults.
- Design tokens: use `AtlasColors.*`, `AtlasTypography.*`, `AtlasSpacing.*`. No hardcoded colors/fonts/padding.
- Support Dynamic Type and Dark Mode.

## Design System

Tokens in `Theme/` are single source of truth. **Brand accent is decided: dark gold (brass) `#8B7535` (owner, 2026-07-04) — one value in both light and dark mode; never re-propose terracotta.** Type/spacing values remain placeholders pending the design pass. Build for function first.

## Build Config

- Bundle ID: `com.ehky.TRAVEL-GUIDED-TOUR`
- Swift 5.0; deployment targets iOS 26.2 / macOS 26.2 / visionOS 26.2
- Device families: iPhone, iPad, Apple Vision; code signing automatic, team `CPC7M72JTP`
- `Info.plist` at repo root (explicit file — `GENERATE_INFOPLIST_FILE = NO`)
- Keys: `NSLocationWhenInUseUsageDescription`, `NSLocationAlwaysAndWhenInUseUsageDescription`, `UIBackgroundModes=audio`, `ITSAppUsesNonExemptEncryption=NO`

## Out of Scope for V1

No: backend/API, user accounts/auth, in-app maker upload, payments/IAP, moderation, comments/reviews/ratings, follow/sharing/social, push notifications (local geofence notifications OK), onboarding tutorial, in-app search, analytics SDK. Don't introduce any without a spec update.
