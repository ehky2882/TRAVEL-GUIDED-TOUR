# archive/

Snapshots of working docs from earlier in the project. Naming
convention: `<original-name>-YYMMDD.md`, where the date is the day
the snapshot was archived (or the day it represents, for handoffs).

**Reading rule.** Most files here are historical — not read at
session start; anything still relevant to current work belongs in
`CLAUDE.md` or `ROADMAP.md`. **Exception: the most recent
`HANDOFF-YYMMDD.md` is part of the session-start ritual** (see
`CLAUDE.md` § "Session-start ritual"). It bridges the gap between
durable project rules and the specific mid-flight state from the
prior session — queued user feedback, what was about to be tackled,
tribal knowledge not yet promoted.


**Where the detail went.** Every index entry's full text — the long accounts that
had grown to an average of 2,089 characters each, one of them 13,013 — now lives
verbatim in **[`INDEX-DETAIL.md`](INDEX-DETAIL.md)**. Nothing was deleted. This
file is the index; that one is the commentary; the handoffs themselves are the
record.

⚠️ **Do not quote the "latest handoff" from this file** — a pointer here goes
stale the moment another session writes one, and this one did (it named
`HANDOFF-260829.md` while `HANDOFF-260908.md` was on disk). Derive it:

```bash
git log --diff-filter=A --name-only --pretty=format: -- 'archive/HANDOFF-*.md' | grep . | head -1
```

⚠️ **Not `ls archive/HANDOFF-*.md | tail -1`.** That idiom appears elsewhere in
this repo and is wrong whenever a date carries a suffix: `-` sorts before `.`,
so `HANDOFF-260908-2.md` sorts *before* `HANDOFF-260908.md` and the newer file
is the one `tail -1` throws away. Parallel sessions produce those suffixes
constantly. Ordering by when git first saw the file has no such trap.

⚠️ **Two content sessions ran in parallel on 2026-08-27 and both wrote a handoff
for that date.** Read `HANDOFF-260827.md` alongside `HANDOFF-260827-2.md` — the
`-2` suffix is the renumbering that resolved the add/add conflict, not a second
draft of one file. The same collision has since happened on other dates; a
suffix always means a parallel session, never a revision.

**Naming a new handoff:** name it for its date (`HANDOFF-YYMMDD.md`), adding
`-2`, `-3`… if that date is already taken, and add a row here. Only the newest
is part of the session-start ritual, and it is derived with the command above,
not written down.

| File | What it covers | Date |
|---|---|---|
| `HANDOFF-260912.md` | 15 `@heyrosiedart` link pins (#828), triaged from a 30-link dump the owner pasted in unread. Five of the eventual pins named nothing in their caption at all (Le Beaujolais, Michelin House, Wilton's Music Hall, Barbican Laundrette, Turquoise Island) — identified only by pulling each post's oEmbed thumbnail and looking at the frame, not the regex flags. Owner declined the one confident ID the tool was most sure of (the Penguin Pool). | 2026-09-12 |
| `HANDOFF-260911-4.md` | Stripe **round 5** — and two facts we had been sending them had quietly become false: "no transactions processed" (there was a sale) and "all content is first-party" (1,717 pins credit ~343 third-party accounts). 🔴 The record of what we had told a financial institution lived only on an **unmerged branch** until #802. The form reused round 3's title and had **three fields, not two** — caught only because the owner sent a screenshot. Purchase evidence closes the session-79 ES256 risk: real user tokens do reach `record-purchase`. Also 🔴 **the website had said "Coming Soon" for eleven days** while the App Store listed it as the support URL (#825). |  |
| `HANDOFF-260911-2.md` | a creator's feed is triaged before any of it is minted (`scripts/triage-account.py`, #811), plus six `@jamiepeva` pins. 🔴 **The flags are a pre-sort, not a verdict** — measured both ways in one run: 9 of 11 posts passed as SINGLE where 3 were pinnable, *and* a post captioned `📍 Mount Vernon, Virginia` was binned as non-place content. Enumeration ceilings measured, not assumed: TikTok 14 from the embed (the profile is captcha-walled), YouTube ~15, **Instagram nothing — no third-party route exists at all**. |  |
| `HANDOFF-260910-4.md` | Four documents that had eaten themselves — `CLAUDE.md` 1.5 MB → 47 KB (~418k tokens **per request**), `ROADMAP.md` −77%, `archive/README.md` −93%, `STATUS.md` −68%, zero lines lost; plus MoMA PS1's dead hero, and the blobless-fetch trick for uploading to gh-pages from a web session | 2026-09-10 |
| `STATUS-HISTORY.md` | The finished board items moved out of `STATUS.md` § 1 — 41 items whose PRs GitHub reports merged or closed, plus four self-declared-done sub-sections. **Search, never load whole** | 2026-09-08 |
| `INDEX-DETAIL.md` | The long-form entries this index used to carry, verbatim. **Search, never load whole** | 2026-09-08 |
| `ROADMAP-STATUS-HISTORY.md` | The dated `**Status (…)**` blocks moved out of `ROADMAP.md`, which they had grown to 86% of. **Search, never load whole** | 2026-09-08 |
| `CURRENT-STATE-HISTORY.md` | The 34 dated `## Current State` blocks that accumulated in `CLAUDE.md` between 2026-05-25 (session 8) and 2026-09-07 (session 148), verbatim, newest first. | 2026-09-08 |
| `ACCOUNT-TRANSFER-260520.md` | One-time orientation doc for the successor Claude on a different account. | 2026-05-20 |
| `HANDOFF-260901-13.md` | Session 137, 2026-09-01 (web, content) — three Hong Kong places, and an address settled by fetching the venue's own page. |  |
| `HANDOFF-260902.md` | Session 135c, 2026-09-02 (web, content) — Cube House and Tribune Tower become places — EXACT reaches ZERO and the checker exits 0 | 2026-09-02 |
| `HANDOFF-260901-12.md` | Session 135b, 2026-09-01 (web, content) — five place decisions in one owner instruction | 2026-09-01 |
| `HANDOFF-260901-9.md` | Session 137, 2026-09-01 (web, content) — sixteen Hong Kong link pins from one creator, and a coordinate that reverse-geocodes to a motorway tunnel. | 2026-09-01 |
| `HANDOFF-260901-10.md` | Session 136, 2026-09-01 (web, content) — twenty-eight Chicago link pins from 20 Instagram creators, and four posts Instagram will not serve. | 2026-09-01 |
| `HANDOFF-260901-11.md` | Session 135b, 2026-09-01 (web, content) — Casa Loma, the Distillery District and Osgoode Hall become places, and the Crystal joins the ROM | 2026-09-01 |
| `HANDOFF-260901-8.md` | Session 135, 2026-09-01 (web, content) — one hundred and six link pins from `@hereinnyc` | 2026-09-01 |
| `HANDOFF-260901-7.md` | Toronto's first link-pin batch, and six posts Instagram no longer serves. | 2026-09-01 |
| `HANDOFF-260901-3.md` | Session 133, 2026-09-01 (web, content) — eleven link pins from Joshua Charow | 2026-09-01 |
| `HANDOFF-260830-3.md` | Session 123, 2026-08-30 (web, content + backend) — two duplicate LA link pins pulled on owner instruction | 2026-08-30 |
| `HANDOFF-260829.md` | Session 121, 2026-08-29 (local Mac, content) — nineteen link pins — 12 TikTok + 7 Instagram, all from ONE creator, `@about_buildings`. | 2026-08-29 |
| `HANDOFF-260829-2.md` | Session 121b, 2026-08-29 (web, content) — thirty-two link pins from thirty-five links; 2 dead, 1 parked. | 2026-08-29 |
| `HANDOFF-260828.md` | Session 120, 2026-08-28 (web, content) — thirty link pins; Luxembourg and Norway become the catalogue's 31st and 32nd countries. | 2026-08-28 |
| `HANDOFF-260827-2.md` | ten Atlanta TikToks; nine shipped, and the owner pulled the tenth. | 2026-08-27 |
| `HANDOFF-260826.md` | Session 113, 2026-08-26 (web, code) — a link pin's fullscreen was not fullscreen | 2026-08-26 |
| `HANDOFF-260826-2.md` | Session 113, 2026-08-26 (web, content) — Copenhagen launched as the 34th Atlas maker | 2026-08-26 |
| `HANDOFF-260826-3.md` | nine Brick Award link pins, and the letterbox bars every YouTube hero had been carrying. | 2026-08-26 |
| `HANDOFF-260824-2.md` | Stockholm launched as the 33rd city/maker | 2026-08-24 |
| `HANDOFF-260824.md` | Session 107, 2026-08-24 (web, code) — the chrome row was a slightly different colour than its page, and the owner spotted the band. | 2026-08-24 |
| `HANDOFF-260823-5.md` | Session 106, 2026-08-23 (web, content + code) — planning the creator-video work, and the catalogue's first vertical video. | 2026-08-23 |
| `HANDOFF-260819.md` | ⚠️ **NOT IN THE REPO** — Session 94, 2026-08-19 (web, code) — keeping and sending a list | 2026-08-19 |
| `HANDOFF-260817.md` | Session 93, 2026-08-17 (web, code) — 24 map pins could never be opened — on the home map AND every affected creator page. | 2026-08-17 |
| `HANDOFF-260818-4.md` | Session 98, 2026-08-18 (web, code only) — the place layer's device bugs, builds 69 → 73. | 2026-08-18 |
| `HANDOFF-260818-2.md` | Session 96, 2026-08-18 (web, content) — Barcelona launched — 68 tours (66 single-stop + 2 walks) under Atlas Studio BCN, the 31st maker. | 2026-08-18 |
| `HANDOFF-260818-3.md` | Session 97, 2026-08-18 (local, infra + docs + 1 code PR) — Stripe flagged the account as a restricted business, and answering it exposed a privacy policy that had been false for months. | 2026-08-18 |
| `HANDOFF-260818.md` | Session 94, 2026-08-17/18 (web, code) — the tour upload flow got its missing half. | 2026-08-18 |
| `HANDOFF-260816.md` | Session 92, 2026-08-16 (local, repo hygiene) — No content, no app features — a full cleanup of the repository and working copy, plus PR triage. | 2026-08-16 |
| `HANDOFF-260812.md` | Session 90, 2026-08-12 (web, content) — Cape Town launched as the 30th city/maker — the catalog's first South African city and Africa's second bureau. | 2026-08-12 |
| `HANDOFF-260811-2.md` | Session 89, 2026-08-11 (web, content) — Sydney launched as the 29th city/maker — Australia's second bureau, wired the same evening Melbourne merged. | 2026-08-11 |
| `HANDOFF-260811.md` | Session 88, 2026-08-11 (web, content) — Melbourne launched as the 28th city/maker — the catalog's first Australian city. | 2026-08-11 |
| `HANDOFF-260809.md` | Session 87, 2026-08-09 (web, content) — Chicago launched as the 27th city/maker — and the audio-pending queue is EMPTY for the first time ever. | 2026-08-09 |
| `HANDOFF-260808.md` | Session 86, 2026-08-08 (web, content) — Buenos Aires launched as the 26th city/maker — the catalog's first Argentine city. | 2026-08-08 |
| `HANDOFF-260807.md` | Session 85, 2026-08-07 (web, content) — Marrakech launched as the 25th city/maker — the catalog's first African city. | 2026-08-07 |
| `HANDOFF-260806.md` | Session 83, 2026-08-06 (web, content) — Berlin launched as the 24th city/maker | 2026-08-06 |
| `HANDOFF-260804.md` | Session 82, 2026-08-04 (web, content) — São Paulo launched as the 23rd city/maker | 2026-08-04 |
| `HANDOFF-260801.md` | Session 81, 2026-08-01 (web, content) — Rio de Janeiro launched as the 22nd city/maker | 2026-08-01 |
| `HANDOFF-260731.md` | Historical (superseded by `-260801`). Session 80, 2026-07-31… — Dubai launched as the 21st city/maker | 2026-07-31 |
| `HANDOFF-260728-3.md` | Historical (superseded by `-260731`). Session 79, 2026-07-28… — paid tours Phase 2 went LIVE | 2026-07-28 |
| `HANDOFF-260728-2.md` | Historical (superseded by `-260728-3`). Session 78, 2026-07… — Montreal launched as the 20th city/maker | 2026-07-28 |
| `HANDOFF-260728.md` | Session 77c, 2026-07-28 (web, code + SQL) — lists on other people's maker pages, and LIKED on everyone's | 2026-07-28 |
| `HANDOFF-260727-4.md` | Session 77b, 2026-07-27 (web, code) — maker page gains a TOURS / LISTS / MAP tab strip, and the app's two segmented controls convert to the same strip | 2026-07-27 |
| `HANDOFF-260727-3.md` | Session 77, 2026-07-27 (web, code + docs) — closing out the saving consolidation — TestFlight 1.1 (51) verified, and `Journey` renamed to `List` throughout the app. | 2026-07-27 |
| `HANDOFF-260727-2.md` | Historical (superseded by `-260727-3`). Session 76, 2026-07… — a wrong hero shipped for a month — root-caused, fixed, and the whole catalog swept clean of duplicate images | 2026-07-27 |
| `HANDOFF-260727.md` | Historical (superseded by `-260727-3`). Session 75, 2026-07… — Rome launched — 30 tours + 19th maker Atlas Studio ROM | 2026-07-27 |
| `HANDOFF-260726.md` | 1.1 (42)→(46) | 2026-07-26 |
| `HANDOFF-260726-2.md` | Historical (superseded by `-260727`). Session 74 (2 of 2 — p… — saving consolidated — one save action, "Liked" is the default list | 2026-07-26 |
| `HANDOFF-260725-4.md` | Historical (superseded by `-260726`). Session 73, 2026-07-25… — Madrid launched — 34 tours + 18th maker Atlas Studio MAD | 2026-07-25 |
| `HANDOFF-260725-3.md` | Historical (superseded by `-260725-4`). Session 72, 2026-07… — Group Listen ("SharePlay") went from "does nothing" to device-verified working | 2026-07-25 |
| `HANDOFF-260725-2.md` | Historical (superseded by `-260725-3`). Session 71, 2026-07… — paid tours Phase 2 — the money backend is written, awaiting 3 owner dashboard steps. | 2026-07-25 |
| `HANDOFF-260725.md` | Historical (superseded by `-260726`). Session 70, 2026-07-25… — build notes now land in TestFlight's "What to Test" field — owner-confirmed working. | 2026-07-25 |
| `HANDOFF-260724.md` | Session 69, 2026-07-24 (infra, no code) — paid tours Phase 1 done — all 10 IAP tier products created in App Store Connect | 2026-07-24 |
| `HANDOFF-260722.md` | Historical (superseded by `-260724`). Session 68, 2026-07-22… — Ho Chi Minh City launched — 43 tours + 16th maker Atlas Studio SGN | 2026-07-22 |
| `HANDOFF-260721.md` | Historical (superseded by `-260722`). Session 66, 2026-07-21… — maker tour list + grid now distinguish multi-stop walks from single stops | 2026-07-21 |
| `HANDOFF-260720-3.md` | Historical (superseded by `-260721`). Session 64, 2026-07-20… — Follow-request UX polish batch → TestFlight 1.1 (25) | 2026-07-20 |
| `HANDOFF-260720-2.md` | Historical (superseded by `-260720-3`). Session 63, 2026-07… — Library-tab jitter fixed → TestFlight 1.1 (21) | 2026-07-20 |
| `HANDOFF-260720.md` | Historical (superseded by `-260720-2`). Session 62, 2026-07… — drawer rails re-anchored to the user's location → TestFlight 1.1 (16) | 2026-07-20 |
| `HANDOFF-260719-3.md` | Historical (superseded by `-260720`). Session 61, 2026-07-19… — maker bookmark removed — Follow is the single "keep a creator" concept | 2026-07-19 |
| `HANDOFF-260719-2.md` | Historical (superseded by `-260719-3`). Session 60, 2026-07… — (1) home map/animation performance fix → TestFlight 1.1 (10) | 2026-07-19 |
| `HANDOFF-260719.md` | Historical (superseded by `-260719-2`). Session 59, 2026-07… — (1) on-demand signed-TestFlight CI | 2026-07-19 |
| `HANDOFF-260705-5.md` | Historical (superseded by `-260719`). Session 58, 2026-07-05… — Me-tab first-open lag fully killed → TestFlight 1.0 (74). | 2026-07-05 |
| `HANDOFF-260705-4.md` | Historical (superseded by `-5`). Session 58, 2026-07-05 (cod… — Build 73 cut — profile perf + create-tour tag picker + bottom-module fix. | 2026-07-05 |
| `HANDOFF-260705-3.md` | #357 merged into build 73 | 2026-07-05 |
| `HANDOFF-260705-2.md` | Session 57, 2026-07-05 (code) — Tag Phase 2 (browsable tag UI) + Dozent identity → TestFlight 1.0 (72). | 2026-07-05 |
| `HANDOFF-260705.md` | Session 56, 2026-07-05 (code) — Directed polish pass → TestFlight 1.0 (71). | 2026-07-05 |
| `HANDOFF-260704-4.md` | Historical (restored 2026-07-26 — written in a parallel sess… — perf — Home + its map kept alive across tab switches, fixing the return-to-Home lag the owner reported on device | 2026-07-04 |
| `HANDOFF-260704-3.md` | Session 55, 2026-07-04 (code) — Batch D COMPLETE — D2 follow-lists + D3 requests shipped in TestFlight 1.0 (70) | 2026-07-04 |
| `HANDOFF-260704-2.md` | Session 54, 2026-07-04 (code) — Batch D (social layer) begun — designed + D1 shipped in TestFlight 1.0 (68). | 2026-07-04 |
| `HANDOFF-260704.md` | Session 53, 2026-07-04 (code) — Device-testing polish batch (8 fixes) → TestFlight 1.0 (67) + a live moderation-email upgrade | 2026-07-04 |
| `HANDOFF-260703-4.md` | Session 53, 2026-07-03 (code) — Profile/maker polish + audio-write bug fix → TestFlight 1.0 (66) | 2026-07-03 |
| `HANDOFF-260703-3.md` | Session 53, 2026-07-03 (code) — Profile/maker polish batch C → TestFlight 1.0 (65) | 2026-07-03 |
| `HANDOFF-260703-2.md` | Session 53, 2026-07-03 (code) — Profile/maker polish batches A + B → TestFlight 1.0 (64). | 2026-07-03 |
| `HANDOFF-260703.md` | Session 51 cont'd, 2026-07-03 (code) — V2 Step 4 maker-authoring Phase-1 loop COMPLETE — LIVE in TestFlight 1.0 (63). | 2026-07-03 |
| `HANDOFF-260702-2.md` | Session 52, 2026-07-02 (web/PM — content) — Kyoto launched — 30 tours + 9th maker Atlas Studio KYO ([PR #309](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/309), `af02819`, auto-merged). | 2026-07-02 |
| `HANDOFF-260702.md` | Session 51, 2026-07-02 (code) — V2 Step 4 (maker authoring) BEGUN — the profile-as-maker-page architecture + first Supabase content writes. | 2026-07-02 |
| `HANDOFF-260701-2.md` | Session 50, 2026-07-01 (infra, no code) — report-a-concern EMAIL notifications now LIVE — owner-confirmed end-to-end. | 2026-07-01 |
| `HANDOFF-260701.md` | Session 49, 2026-07-01 (code) — fixed the owner's real-device sync bug — un-saving a tour then signing out/in no longer resurrects it in Saved — and archived TestFlight 1.0 (58). | 2026-07-01 |
| `HANDOFF-260630-2.md` | Session 47, 2026-06-30 (code) — V2 Step 3 (accounts & auth) COMPLETE — shipped TestFlight 1.0 (56). | 2026-06-30 |
| `HANDOFF-260630.md` | Session 48, 2026-06-30 (web/PM — content) — Tokyo launched — 63 tours + 7th maker Atlas Studio TYO ([PR #280](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/280), `4ab886a`, auto-merged). | 2026-06-30 |
| `HANDOFF-260627.md` | Session 46, 2026-06-27 (code) — V2 Step 2 app cutover — the app now reads its catalog from the live Supabase backend ([PR #255](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/255)… | 2026-06-27 |
| `HANDOFF-260626-2.md` | Session 45, 2026-06-26 (code) — geofence "already-inside" fix — AMNH stop 2 now triggers at tour start ([PR #251](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/251), `2eb89c0`). | 2026-06-26 |
| `HANDOFF-260626.md` | Session 44, 2026-06-26 (code) — catalog refresh hardened (PR #245) + shipped in TestFlight 1.0 (49). | 2026-06-26 |
| `HANDOFF-260623.md` | Verified live: 362 tours / 5 makers / 381 stops / 4 multi-stop | 2026-06-23 |
| `HANDOFF-260621.md` | nothing ships in the app yet | 2026-06-21 |
| `HANDOFF-260618.md` | Fortieth session 2026-06-18 (verify/build) — PR #209 (catalog detach) verified + merged (`de8ff6a`) and TestFlight 1.0 (46) cut and shipped. | 2026-06-18 |
| `HANDOFF-260616.md` | Thirty-ninth session 2026-06-16 (local build cut) — TestFlight 1.0 (45) cut and shipped — catalog crosses 300 tours. | 2026-06-16 |
| `HANDOFF-260615.md` | Thirty-eighth session 2026-06-15 (web/PM) — Lisbon batch 3 — 14 tours (PR #200) + TestFlight 1.0 (44) cut and shipped. | 2026-06-15 |
| `HANDOFF-260612-4.md` | Thirty-seventh session 2026-06-12 (web/PM) — Lisbon batch 2 — 15 tours (PR #198) + TestFlight 1.0 (43) cut and shipped. | 2026-06-12 |
| `HANDOFF-260612-3.md` | Thirty-sixth session 2026-06-12 (implementation) — home drawer pivoted to category rails | 2026-06-12 |
| `HANDOFF-260612-2.md` | Thirty-fifth session 2026-06-12 (local build cut) — TestFlight 1.0 (41) cut and shipped. | 2026-06-12 |
| `HANDOFF-260612.md` | Thirty-fourth session 2026-06-12 (web/PM, multi-day) — 33 London tours shipped via the audio-pending staging workflow | 2026-06-12 |
| `HANDOFF-260611.md` | Thirty-third session 2026-06-11 (web/PM) — TestFlight 1.0 (40) cut and shipped. | 2026-06-11 |
| `HANDOFF-260610.md` | Thirty-second session 2026-06-10 (web/PM) — TestFlight 1.0 (39) cut and shipped | 2026-06-10 |
| `HANDOFF-260609-2.md` | Thirtieth session 2026-06-09 (web/PM) — London expansion II | 2026-06-09 |
| `HANDOFF-260609.md` | Twenty-ninth session 2026-06-09 (web/PM) — London expansion | 2026-06-09 |
| `HANDOFF-260608.md` | Twenty-eighth session 2026-06-08 (web/PM) — London launch. | 2026-06-08 |
| `HANDOFF-260607-2.md` | no validation 90474 | 2026-06-07 |
| `HANDOFF-260607.md` | no validation 90474 | 2026-06-07 |
| `HANDOFF-260606-3.md` | Makers | 2026-06-06 |
| `HANDOFF-260606-2.md` | Twenty-fourth session 2026-06-06 (implementation): full-screen Player polish, round 2 (continues session 22). | 2026-06-06 |
| `HANDOFF-260606.md` | Places | 2026-06-06 |
| `HANDOFF-260605.md` | Twenty-second session 2026-06-05 (implementation): full-screen Player polish, owner-driven at the simulator. | 2026-06-05 |
| `HANDOFF-260604.md` | Twentieth session 2026-06-04 (web/PM): pure image-pipeline pass on existing NYC tours. | 2026-06-04 |
| `HANDOFF-260603-2.md` | TestFlight 1.0 (28) is live. | 2026-06-03 |
| `HANDOFF-260603.md` | 113 → 131 tours | 2026-06-03 |
| `HANDOFF-260602-2.md` | TestFlight 1.0 (25) is live. | 2026-06-02 |
| `HANDOFF-260602.md` | Biblioteca Pública e Arquivo Regional Luís da Silva Ribeiro — first Azores tour | 2026-06-02 |
| `HANDOFF-260601-3.md` | TestFlight 1.0 (23) is live. | 2026-06-01 |
| `HANDOFF-260601-2.md` | TestFlight 1.0 (21) is live. | 2026-06-01 |
| `HANDOFF-260601.md` | Thirteenth session 2026-06-01 (web/PM): 10 new NYC tours added (Domino Park, Wave Hill, Queens Museum, Museum of the Moving Image, Snug Harbor, Yankee Stadium… | 2026-06-01 |
| `HANDOFF-260529-2.md` | Twelfth session 2026-05-29 (evening): build-bump-and-archive only — cut TestFlight build 1.0 (17). | 2026-05-29 |
| `HANDOFF-260529.md` | Same-day earlier session 2026-05-29: shipped PR #95 — bottom-module appearance tracks Settings picker correctly in both directions. | 2026-05-29 |
| `HANDOFF-260528.md` | Eleventh session 2026-05-28: shipped PR #91 — bottom-module chrome-shade seam fix. | 2026-05-28 |
| `HANDOFF-260527-3.md` | No code or content changed. | 2026-05-27 |
| `HANDOFF-260527-2.md` | Ninth session 2026-05-27 (late): content-only PR train. | 2026-05-27 |
| `HANDOFF-260527.md` | Known issue: subtle chrome shade mismatch in dark mode | 2026-05-27 |
| `HANDOFF-260526.md` | 2026-05-26 remote session: shipped PR #78 (merged — enter-slide mirror fix) + AMNH Four Facades multi-stop tour (39 tours, unblocks M-qa items 6+7). | 2026-05-26 |
| `HANDOFF-260525-7.md` | Seventh session 2026-05-25: shipped PR #78 — enter-slide mirror fix. | 2026-05-25 |
| `HANDOFF-260525-6.md` | Sixth session 2026-05-25: shipped PR #77 — tour-detail slide animation fix, closes the open issue from session 5. | 2026-05-25 |
| `HANDOFF-260525-5.md` | open issue (slide animation reads as fade) | 2026-05-25 |
| `HANDOFF-260525-4.md` | Fourth session 2026-05-25: shipped PR #70 (`643cbd7`) — buttons identical across every surface; only the edge-to-edge background fill behind the inset bar… | 2026-05-25 |
| `HANDOFF-260525-3.md` | Third session 2026-05-25: shipped PR #69 (`8d928b3`), fixing two regressions PR #68 introduced on Home. | 2026-05-25 |
| `HANDOFF-260525-2.md` | Introduced two regressions on Home that PR #69 (handoff `-3`) fixes | 2026-05-25 |
| `HANDOFF-260525.md` | First session 2026-05-25: shipped PR #66 (`2452f52`), extending PR #60's bottom-module geometry to the rest of the app. | 2026-05-25 |
| `HANDOFF-260524-3.md` | Late-evening session 2026-05-24: shipped PR #60 (home polish bundle + player-state hardening, `e5b31da`). | 2026-05-24 |
| `HANDOFF-260524-2.md` | Afternoon/evening Mac session 2026-05-24: shipped PR #61 (mini-player end-of-tour state fix — kills the post-tour "Loading…" flicker, adds in-place replay via… | 2026-05-24 |
| `HANDOFF-260524.md` | Mac session 2026-05-23/24 morning: populated `heroImageURL` for all 38 tours via CC-licensed Wikimedia Commons photos (landscape-optimised batch), bumped build… | 2026-05-24 |
| `HANDOFF-260522.md` | TestFlight build 1.0 (5) | 2026-05-22 |
| `HANDOFF-260521.md` | Short handoff from a parallel 2026-05-21 remote session, written just after PR #54 merged (build 5 bumped but not yet uploaded). | 2026-05-21 |
| `HANDOFF-260520.md` | TestFlight build 1.0 (4) upload | 2026-05-20 |
| `HANDOFF-260519.md` | Consolidated end-of-day snapshot from 2026-05-19. | 2026-05-19 |
| `HANDOFF-260518.md` | End-of-day snapshot from the 2026-05-18 session. | 2026-05-18 |
| `pre-qa-audit-260518.md` | Pre-QA code self-audit (22 findings, P0–P3). | 2026-05-18 |
| `HANDOFF-260819-2.md` | the website restyled to the app's tokens; splash home page, /about/, pinned chrome. |  |
| `HANDOFF-260819-3.md` | AMNH becomes a place (its tour's pin was 107 m off its own script), and the bottom bars stop painting as a floating island under a slide-up layer. |  |
| `HANDOFF-260819-4.md` | ratio |  |
| `HANDOFF-260819-5.md` | A crash log is one sample of a spin — diff the working path against the broken one. |  |
| `HANDOFF-260819-6.md` | actually |  |
| `HANDOFF-260820.md` | the Library launch jitter (lists had no disk cache, so three stacked round-trips re-laid-out the tab on every launch) and the 1,418-tour linear scan behind… |  |
| `HANDOFF-260820-2.md` | the list page stops being the odd one out: its `…` was drawing its own ring and taking the environment accent (the session-99 wordmark bug in a second place)… |  |
| `HANDOFF-260820-3.md` | The apex is a COMING SOON splash, so `/about/` is the URL that shows a product |  |
| `HANDOFF-260820-4.md` | Liked stops being a screen of its own: `LikedListView` is deleted and Liked renders through `TourListDetailView` with a `.liked` target, because two screens… |  |
| `HANDOFF-260821.md` | `maxHeight: .infinity` inside the wizard's step area has never done anything |  |
| `HANDOFF-260822.md` | 1.1 (109) |  |
| `HANDOFF-260822-2.md` | Milan launches |  |
| `HANDOFF-260822-3.md` | every light-mode launch flashed white → black → white |  |
| `HANDOFF-260823.md` | iOS's own launch screen |  |
| `HANDOFF-260823-2.md` | The cause is not the splash |  |
| `HANDOFF-260823-3.md` | The coordinate fault measured and proven upstream |  |
| `HANDOFF-260824-3.md` | Three hit-testing traps with one symptom: |  |
| `HANDOFF-260823-4.md` | the other half of the subway report — a failed request does not mean we do not have the photograph. |  |
| `HANDOFF-260824-4.md` | link pins: someone else's TikTok, Reel or Short as a map pin that PLAYS INSIDE THE APP. |  |
| `HANDOFF-260825.md` | the ordering hazard the entry above predicted actually happened, and this is the fix that reaches builds already shipped. |  |
| `HANDOFF-260825-2.md` | the seatbelt for next time: decode tolerance. |  |
| `HANDOFF-260825-3.md` | both catalogue PRs merged, the migration applied and verified, and old builds confirmed reading the live payload again. |  |
| `HANDOFF-260825-4.md` | a place page can be read as a grid, and its tour header becomes the profile page's. |  |
| `HANDOFF-260825-6.md` | fourteen TikTok/YouTube link pins, and the Dozents count that stopped meaning what it says. |  |
| `HANDOFF-260825-5.md` | the same two controls reach list pages, and a list needed a sort state the other pages do not. |  |
| `HANDOFF-260826-4.md` | ten Orlando TikToks; nine shipped, one dead at the source. |  |
| `HANDOFF-260826-5.md` | eleven Orlando architecture TikToks; ten shipped, one unpinnable twice over. |  |
| `HANDOFF-260826-6.md` | four Orlando architects join the vocabulary, 323 → 327 |  |
| `HANDOFF-260827.md` | twenty San Francisco architecture TikToks; nineteen shipped, the twentieth is gone from TikTok's own servers. |  |
| `HANDOFF-260827-4.md` | twenty-three TikTok/Instagram links; all twenty-three shipped. |  |
| `HANDOFF-260827-3.md` | sixteen mixed-city TikTok/YouTube links; all sixteen shipped — the first fully intact batch since the link-pin work began. |  |
| `HANDOFF-260829-3.md` | twenty-three TikTok/Instagram links; all twenty-three shipped, from three creators (18 TikToks from `@thedesigndetourist`, 4 Instagram reels from… |  |
| `HANDOFF-260830-8.md` | an expand button on every inline map: back to the Home map, framed on what you were reading. |  |
| `HANDOFF-260830-7.md` | seven Instagram reels from one creator (`@nikola.matus`), and an Atlas tour that can never fire. |  |
| `HANDOFF-260830-5.md` | every shared link previewed as a green sphere, and the tour photo could never have appeared. |  |
| `HANDOFF-260830-4.md` | fourteen link pins from three creators; all fourteen alive, nothing parked. |  |
| `HANDOFF-260830-2.md` | the duplicate-image checker had never seen a link pin. |  |
| `HANDOFF-260830.md` | five architects join the controlled vocabulary (329 → 334), and one of them is the Brooklyn Bridge's. |  |
| `HANDOFF-260829-4.md` | twenty links, all twenty shipped; fifteen from one Hong Kong creator. |  |
| `HANDOFF-260830-6.md` | an Instagram reel stops being cropped, and its fullscreen scrubber starts moving. |  |
| `HANDOFF-260831.md` | an audit of un-placed place candidates, then seven of them built: places 49 → 56, and EXACT reaches zero. |  |
| `HANDOFF-260902-10.md` | nineteen Hong Kong link pins from `@notbadgalriri__`, and a Plus Code that belongs to another post. |  |
| `HANDOFF-260902-6.md` | ten owner notes on the `@shivanidukhandee` batch: 5 renames, 7 coordinate moves, 2 removals |  |
| `HANDOFF-260901-6.md` | Riverside Church becomes a place, and its Atlas tour stops firing on Broadway. |  |
| `HANDOFF-260901-5.md` | the last three place cards, and Windsor Castle finally gets a photograph of Windsor Castle. |  |
| `HANDOFF-260901-4.md` | Arthur Ashe Stadium and Banyan Tree Mayakoba become places, and seven slashes finally go. |  |
| `HANDOFF-260901-2.md` | twenty-one link pins from nineteen creators, and a caption that named no place at all. |  |
| `HANDOFF-260901.md` | four place cards, and the Empire State Building moved onto its own address. |  |
| `HANDOFF-260831-8.md` | fifty link pins from `@hereinnyc`, and a Plus Code 970 m from its own subject. |  |
| `HANDOFF-260831-7.md` | the two checks that could have caught the Natural History Museum, added to `check-image-duplicates.py`. |  |
| `HANDOFF-260831-9.md` | Dozent 1.1.1 submitted: build 139, ten new App Store screenshots, and two metadata fields that would have shipped wrong. |  |
| `HANDOFF-260831-6.md` | the London Natural History Museum tour had been playing the Los Angeles narration, and the reported gallery bug was the smaller half. |  |
| `HANDOFF-260831-5.md` | nine Tier 2 place cards for the pin-only clusters — places 66 → 75. |  |
| `HANDOFF-260831-4.md` | ten place cards for the tour-plus-pin sites the 95-pin batch created — places 56 → 66. |  |
| `HANDOFF-260831-2.md` | ninety-five link pins from Alice Loxton (`@history_alice`, 92), Domus (2) and Rome Art Stories (1) — the largest batch to date by a wide margin, against a… |  |
| `HANDOFF-260831-3.md` | one hundred and five link pins from a single NYC history creator (`@hereinnyc`) — the largest batch to date, against a previous record of 95. |  |
| `HANDOFF-260902-7.md` | forty-two Miami link pins, five places, and a scraped address that was a 404 page's footer. |  |
| `HANDOFF-260902-8.md` | session 138: the Hong Kong batch closed. |  |
| `HANDOFF-260902-9.md` | thirty-two Hong Kong link pins, and a Plus Code that belongs to another post. |  |
| `HANDOFF-260902-11.md` | nineteen Hong Kong and Macau link pins, a story highlight that can never be pinned, a what3words that lands in New York, and two pins beside a pin. |  |
| `HANDOFF-260903.md` | twenty-nine link pins, a post that names no place, and Alwyn Court going three deep. |  |
| `HANDOFF-260903-2.md` | sixty-one link pins from ONE creator, and a geocoder that turned rate limiting into "not found". |  |
| `HANDOFF-260903-3.md` | one hundred and four more @archimarathon pins, twelve coincident groups, and a caption pasted onto the wrong video. |  |
| `HANDOFF-260903-4.md` | the bottom module went missing again, and it was HIDDEN rather than uninstalled — the failure three previous fixes could not see. |  |
| `HANDOFF-260904.md` | the Barcelona Pavilion becomes a five-member place, and 36 architects join the vocabulary (383 → 419). |  |
| `HANDOFF-260904-3.md` | thirty-three Toronto and Mississauga link pins, a blocked post, and three subjects the pixels named. |  |
| `HANDOFF-260904-2.md` | written as `-260904` and renumbered on an add/add collision. |  |
| `HANDOFF-260905-5.md` | four places, and one owner decision recorded. |  |
| `HANDOFF-260905-2.md` | twenty-three Miami link pins, seven of them on two coordinates. |  |
| `HANDOFF-260905-3.md` | written as `-260905`, then `-2`, and renumbered TWICE on add/add collisions with two parallel sessions. |  |
| `HANDOFF-260905-4.md` | four places for the four sites at the stack cap. |  |
| `HANDOFF-260908.md` | the token-cost session: `CLAUDE.md` was 1.5 MB, injected into every request of every session. |  |
| ``HANDOFF-260908-2.md`` | ⚠️ **NOT IN THE REPO** — session 149: 83 link pins from TikTok `@urbanistariel`; a hero filename that would have overwritten open PR #749's live file, and a MOCA stack at depth 4 that… |  |
| `HANDOFF-260908-3.md` | session 150: onboarding a non-technical contributor — a beginner guide (`docs/partner-onboarding.md`) and the repo's first `.claude/skills/` entry, `atlas-upload`, which it points at. | 2026-09-08 |
| `HANDOFF-260908-4.md` | session 151: 27 `@urbanistariel` link pins; a Plus Code recovery that put a pin in Pennsylvania, a geocode 250 km upstate that reverse-verification would have confirmed, and six groups folded into places to clear the stack cap. | 2026-09-08 |
| `HANDOFF-260906.md` | the catalog RPC was failing a third of the time; materialise it. |  |
| `HANDOFF-260905.md` | thirteen Studio Gang link pins across eight buildings, and two stack caps hit at once. |  |
| `HANDOFF-260907-4.md` | Thirty-seven link pins from three creators, and one post that is three pins. |  |
| `HANDOFF-260907-2.md` | written as `-260907`, renumbered on an add/add collision with [#744](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/744). |  |
| `HANDOFF-260907-3.md` | Eastern State Penitentiary gains its third member, and the standing note calling it a place CANDIDATE was wrong. |  |
| `HANDOFF-260907.md` | the Gilder Center becomes a place, and a bug the mirror cannot see. |  |
| `HANDOFF-260909-3.md` | the Supabase over-quota email answered: the session-start health check was pulling the whole catalogue four times to read a status code — 44 MB/session, now 8 KB. |  |
| `HANDOFF-260911-3.md` | the place sweep: **142 → 288 places**, both decidable tiers closed — and **nine wrong coordinates** found by asking which member OSM agrees with. 🔴 One was a **PLACE** 363 m out carrying both its members, invisible because the check that members sit on their place **passes by construction**; only a pin *outside* it could disagree. The owner found a tenth-of-a-kind themselves: a Lloyd's tour parked on the Leadenhall Building, in a pair I had recommended declining as an obvious false positive. Also: the seed could never DELETE a place (#814). |  |
| `HANDOFF-260910.md` | A link pin that cannot load now says so (#785, merged `6a594081`, owner-verified on build 143). A cross-origin iframe cannot fail where `WKNavigationDelegate` can see it, so the detector is the iframe's own `load` event plus a deadline — and the message is an overlay, so a late arrival clears it. The false-positive case is watched, not proven. |  |
| `HANDOFF-260910-2.md` | 35 Instagram link pins from a random owner batch (#789); no link carried a location, so every coordinate was geocoded and every returned name read back — catching a wrong library branch, a theatre 47 street numbers off, a county-level match and a venue whose name reads Philadelphian but sits in NYC. 🔴 A geocoder **429 was being silently coerced into "NO MATCH"**, 30 of 35 subjects, Tribune Tower included. `--title` is ignored in a `--batch` run, so Instagram batches must be minted per-pin or the map title becomes the caption. Heroes 404'd for ~12 min after a successful push — the Pages deploy queue, not a lost upload; verified live-hash-identical and `--pins` clean (0 errors, 1,661 images) once it landed. |  |
| `HANDOFF-260910-3.md` | 21 TikTok link pins from `@nickcabotrodriguez` (#790); Plus Codes decoded and reverse-geocoded, then several subjects corrected by reading the post's own thumbnail rather than trusting the geocode — a "Hollywood building" was the Hollywood Pacific Theatre, a "Madison Avenue restaurant" was E.A.T. Owner asked to hold a proposed "Abandoned" tag for a later vocabulary change rather than add it here. Two place candidates surfaced (First National Bank of Hollywood pair; a St. Vincent de Paul Church pin 12m from an existing one), neither resolved. |  |
| `HANDOFF-260909-5.md` | 37 `@urbanistariel` link pins (#782); Katz's Deli arrived on a Plus Code 3.5 km away in the wrong borough, and one post has vanished from TikTok. |  |
| `HANDOFF-260910.md` | the egress emergency answered: the dashboard breakdown is **100.0% PostgREST every day** (Edge Functions absent, MAU 17), so transcripts came off the wire — **3,698,842 → 2,163,115 bytes, 41.5%**, reaching phones already in the field because `String?` decodes an absent key as nil. 🔴 **The first migration reverted the link-pin split** (`tours 1553 → 3253`, `linkPins → 0`) by retyping a superseded function body; caught by counting the live payload, repaired by wrapping instead. The audit that exists for this was looking one layer too high and now watches both. |  |
| `HANDOFF-260909-4.md` | 61 `@urbanistariel` link pins (#777), Greece 7 → 35; two Plus Codes labelled `Lower Town` recovered 88 km out to sea before their captions named Mystras. Then #779 placed the held link and #780 made The Parthenon a place — which hard-errors unless every member's stop sits exactly on it. |  |
| `HANDOFF-260909.md` | thirty-six `@urbanistariel` pins; four join places that already existed, and two titles were wrong until the picture was opened. |  |

232 entries (re-derived via `grep -c '^| ' archive/README.md`, not quoted from the prior value).
Full text for every one of them is in
[`INDEX-DETAIL.md`](INDEX-DETAIL.md), in this same order.

⚠️ **2 entry names a file that is not in the repo** (`HANDOFF-260819.md`, ``HANDOFF-260908-2.md``). It was indexed but never committed — a row promising a handoff nobody can open. The row is kept, marked, rather than quietly deleted: the gap is the finding.
- [HANDOFF-260912-2.md](HANDOFF-260912-2.md) — **Fifty-four link pins from two creators, and Puerto Rico joins the catalogue.** The owner sent **55 links** (20 Instagram reels, 35 TikToks); **all 55 resolved — the eighth fully-intact batch running — and one was already pinned, so 54 ship**, the largest link-pin batch this project has taken. **linkPins 1,306 → 1,360 · makers 350 → 351 · `tours` and `places` byte-identical at 1,552 / 130.** 🎉 **Puerto Rico is the 59th country** (5 pins), following the catalogue's own territory convention — `Hong Kong` (270 entries) and `Macau` (6) are their own country values — and it is how the owner supplied them; ⚠️ the catalogue already contains an unrelated **`San Juan, Philippines`**. Two creators: **`@arishaintokyo`** (Instagram, 6 — Japan) and **`@urbanistariel`** (14 Instagram + 34 TikTok = 48). 🔴 **ONE LINK WAS ALREADY IN THE CATALOGUE** — `@urbanistariel/video/7638665562838600973` is live as the San Francisco **"Chinatown"** pin, so the owner re-sent one already pinned; **0 other already-pinned sourceURLs**, checked against `main` **and** all three in-flight branches (#743, #746, #747), zero overlap on every one. 🔴 **`openlocationcode` INSTALLS ON THIS MAC — do not hand-roll a Plus Code decoder here.** CLAUDE.md records two web sessions writing one by hand because `pip install` "cannot build a wheel", and **both got the arithmetic wrong first time**; `pip3 install openlocationcode` just works on the owner's Mac, and the published Eiffel Tower vector `8FW4V75V+8Q` decodes to **`48.8583125, 2.2944375`** exactly. 33 locations were supplied (24 short codes, 7 full, 2 raw lat/lon), 22 derived from the caption. ⚠️ **RE-QUERYING WAS THE WHOLE FIX, SIXTH BATCH RUNNING** — two Venice codes failed on the **locality string**, not the code (`Venice, Metropolitan City of Venice, Italy` geocodes to nothing; `Venice, Italy` resolves instantly), and **all four** caption-derived subjects that missed first time resolved on a second query (La Collina, the **New** Fulton Fish Market, West Park Presbyterian, NYPL's `Stephen A. Schwarzman Building`). 🔴 **I NEARLY "CORRECTED" A COORDINATE THAT WAS EXACTLY RIGHT** — 161 Maiden Lane reverse-geocodes to **34 Fletcher Street**, so it read as ~85 m off its own caption's address, but a forward geocode of that address puts OSM's `161 Maiden Lane` node **3 m** from the supplied point: the reverse-geocoder was preferring a neighbouring *addressed* feature, the documented Inter&Co Stadium / Swan House pattern. **Nothing moved.** ⚠️ **Four other reverse-geocodes land on an enclosing or neighbouring feature and all four are right** — the Oculus → `Apple World Trade Center` (the store inside it), Smith–Ninth Streets → `Ninth Street Bridge` (the viaduct that *is* the station), Heptapyrgion → `Παπαρέσκα, Άνω Πόλη`, MICA → `Main Building, 1300 West Mount Royal Avenue`. 🔴 **THE FREUD MUSEUM SITS EXACTLY AT `TourSetMap.maxStacked = 3`** — three pins coincident on one point; all three render, and **a fourth Freud link would put one permanently out of reach, invisibly**. **Flagged, not created:** a place needs its own copy, address, photograph and human approval. Every other group is two deep (Canterbury ×2, One Vanderbilt ×2), and the two NYPL pins pair with *different* existing `@hereinnyc` pins **22 m apart — two 2-groups, not one 4-group**. **No pin is coincident with an existing place** (nearest 137 m, different subject), so nothing joins a place and nothing needed one for correctness. 🔴 **THE HANDLE SUFFIX PREVENTED TWO LIVE ATLAS HERO OVERWRITES** — `images/royal-observatory-greenwich_hero.webp` and `images/tower-bridge_hero.webp` are both live **Atlas tour** heroes and both subjects are in this batch; **0 of 54 target paths pre-existed** against 7,126 gh-pages `images/` paths, and since #567 a downloaded tour reads its photographs off its own disk, so an overwrite would never have reached a phone. ⚠️ **BOTH `@urbanistariel` MAKER ROWS ALREADY EXISTED and the uuid5 scheme reproduced both ids AND both full row objects exactly**, so they merge rather than duplicate and no existing row is modified; **their TikTok avatar also regenerated byte-identically to the live file** (sha256 against the served bytes) and was **excluded from the upload rather than overwritten** — the `@urbanistariel` case for the fifth time. **54 generated, 54 uploaded, 0 avatars.** Instagram `@arishaintokyo` is the one new row and ships `avatarURL: null`. ✅ **All 54 heroes opened and read against their captions — zero wrong subjects**, many naming themselves in frame (*SEIRENSHO ART MUSEUM*, *TAKETOMI ISLAND*, *Dyckman Farmhouse Museum*, *B&O Railroad Museum*, *Barbican*, *London's Cathedral of Sewage*); St Mark's shows the looted bronze horses its caption is about and Smith–Ninth Streets the viaduct over the canal. ⚠️ **ONE TITLE WAS WRONG UNTIL THE HERO WAS OPENED** — `The Headless Horseman` was authored as `Sleepy Hollow Cemetery` from the caption alone, but the frame is the Horseman sculpture and its sibling pin in the same cemetery is already `The Bronze Lady`; **retitling changes the hero slug**, so that pin was rebuilt and the stale file removed. ⚠️ **The three Freud pins need three distinct titles** for the same reason — identical titles would be indistinguishable on the map *and* their heroes would overwrite each other. ⚠️ **TWO HAND RE-CROPS — the vertical `--focus` gap, ELEVENTH batch running** (every source is vertical, so the square is width-limited and `--focus` does nothing), through a mirror of `render_hero` at the **same filenames**: the Ishigaki sculpture garden at 0.22 and Ye Olde Cheshire Cheese at 0.20, both recovering the creator's own full text card. **Lake Saiko and Big Bang deliberately left alone** — what they clip is a hook, not the subject's name. ⚠️ **`@urbanistariel`'s house format is a presenter in frame with the subject behind** and it ships unchanged (*"dont change the heros"*). ⚠️ **Two creator misspellings kept verbatim in `longDescription` and repeated nowhere we author** — *"The San Jaun Fortress"* and *"Saint Thomas Beckett"* (correctly Becket), the Schweizer convention. ⚠️ **4 of 20 Instagram reels are rights-withheld**, all four `@arishaintokyo` — the licensed-music gate, verdict taken from the **absent `video_url`**, never the track name; the poster + `OPEN IN INSTAGRAM` fallback is correct, not a defect. All 35 TikToks play inline. ⚠️ **ARCHITECTS: `Santiago Calatrava` is in the vocabulary and the Oculus caption names him outright** → tagged **alongside** `Designed by a Master`; 🔴 **`Terunobu Fujimori` is absent and is this batch's most conspicuous gap** (La Collina's caption is *entirely* about him); ⚠️ **`Hiroshi Sambuichi` IS in the vocabulary and is deliberately NOT tagged** on Inujima Seirensho — he designed it, but the caption names no architect (the Jules Dalou rule), and the same holds for `Horace Jones` on Tower Bridge and `Joseph Bazalgette` on Crossness. **Verification:** 🔴 **`swift scripts/validate-tours.swift` ITSELF** — a Mac session, so the authoritative validator rather than a Python mirror: **0 errors, 2 warnings across 1,552 tours + 1,360 pins + 130 places**, and the same binary run against `origin/main` with the change stashed reports the **identical pair**, so **both are pre-existing** (VIA 57 West's transcript gap, Bedrock Caverns' deliberate null `walkingDistanceMeters`). `make-link-pin.py --selftest` **71/71** with Pillow installed. **0** duplicate tour/stop/maker ids, **0** id collisions across `tours` and `linkPins`, **0** orphan `makerId`s, **0** link pins inside `tours`, **0** non-link rows inside `linkPins`, **0** heroes in their own gallery, **0** duplicate hero filenames, **0** byte-duplicate heroes; closest perceptual pair **33.4** (identical pictures score under 1), all 54 at 1200×900. ⚠️ **Two shared sourceURLs exist on `main` and NEITHER is mine** — the documented deliberate `@malata.antwerp` five-pin case plus a pre-existing pair — so the check is **scoped to this batch**, which has 0. `Tours.json` **byte-stable under a Python re-dump at `indent=2` before editing**; diff **2,467 insertions / 0 deletions**, purely additive. gh-pages `932066d5`: `git ls-remote` **re-read in the same command as the push**, tree diff **exactly 54 additions, 0 deletions, nothing outside `images/`**, deploy read **`in_progress`, never `cancelled`**. ⚠️ **gh-pages moved mid-session** (`0358fa83 → 6f9fb9fa`) and the tree was **rebuilt on the new base** rather than force-pushed over it. ⚠️ **THIS IS THE THIRD HANDOFF DATED 2026-09-07** — `-260907.md` (#744) and `-260907-2.md` (#745) were claimed earlier the same day by parallel sessions, so `-3` was verified free against `origin/main` **and** all three in-flight branches before writing; **three sessions have now edited the Key-facts counts today — re-derive, never quote.** ✅ **THE FREUD MUSEUM IS NOW A PLACE — owner instruction, places 288 → 289** (`f4e64b3c-…` = uuid5 `atlas-place:london:freud-museum-london`, the scheme reverse-verified against **127 of the 130** existing places). **Nothing moved to make it** — all three members were already on the identical coordinate and all three are `manual`, so the exact-coordinate identity rule held on its own; `check-place-candidates.py`'s report diff proves it **removes the Freud group and adds nothing**, and a catalogue-wide sweep of what the map actually draws (places collapsed to one capsule each) now finds **0 groups over `maxStacked = 3`**. 🔴 **The hero is BORROWED and that is structural** — every member is a link pin with an empty gallery and **nothing at all is within 400 m**, so no third photograph exists anywhere in the catalogue (the closed Waterlooplein case); **do not go sourcing a replacement**. All three candidates were rendered and looked at, and it takes the **couch** frame, the only one composed as a room rather than a portrait, ⚠️ **with the stated cost that the creator is lying on the couch in it**. ⚠️ **THE FILENAME WAS RENUMBERED TWICE AND THEN DATED FORWARD** — written as `-260907-3`, taken by #743; renumbered `-4`, taken by #751; dated **`260908`** instead, which is also honest since the session ran across midnight. ⚠️ **`main` MOVED FOUR TIMES while this PR sat open with green CI** (#743, #747, #746, #748, then #751 and #752), and the catalogue was rebuilt the documented way each time — main's file taken wholesale and the idempotent assembler re-run on it, never hand-resolved — with overlap re-verified at **0 on every axis** against each new base. (session 148, opened 2026-09-07 · merged 2026-09-12)
- [HANDOFF-260909-2.md](HANDOFF-260909-2.md) — **signup emails come from Dozent now, and the bug that cost five test signups was mine.** Owner: *"If they're unfamiliar with it they don't know if it's legitimate."* Supabase's built-in sender was also documented dev-only and rate-limited, so it needed replacing before launch regardless of branding. Resend on a verified **`send.dozent.world`** — the subdomain **deliberately over the apex**, because `dozent.world` already carries ImprovMX's MX and SPF records and **only one SPF record is permitted per name**, so verifying the apex would have meant merging them and risking the `hello@` forwarding; the stated cost is that mail sends from `noreply@send.dozent.world`. ⚠️ **Resend adds its own `send.` bounce subdomain on top of whatever you give it**, so the records read `send.send.dozent.world` — not a mistake. **🔴 EVERY CLICK RETURNED `otp_expired` AND NO ACCOUNT EVER CONFIRMED — because the emails contained `token=EXAMPLE`.** I had sent a *rendered preview* of the template before the paste-ready code, with the placeholder baked in where `{{ .ConfirmationURL }}` belongs, and the preview is what got pasted. **Four rounds went into scanner, prefetch and expiry theories, all wrong**; what settled it was fetching the owner's pasted link and reproducing their error URL **character for character, including the trailing `&sb=`**. ⚠️ **Never ship a rendered preview beside a paste-ready template.** ⚠️ **And the final, working confirmation LOOKED like a failure** — the screenshot showed `otp_expired` because links are single-use and it was a second click; the account was confirmed, proved by asking the database with the publishable key rather than reading the page. **⚠️ DMARC was skipped on my advice and that was wrong** — Resend marks it *(Optional)*, Gmail has expected it since 2024, and the first email went to spam; added at `_dmarc.send.dozent.world` with `p=none`, so the apex is untouched. ✅ **Resend's "Auto configure" button does the whole Vercel DNS step** and shows exactly which records it will create — creations only, all on the `send.` branch — far safer than hand-typing with a non-technical owner. Ships `backend/email-templates/confirm-signup.html` (**no images anywhere**, because clients block them and a blocked logo is a broken box where the brand mark belongs; button is a `bgcolor` on a `<td>` because Outlook drops padding from a styled `<a>`) and `site/confirmed/index.html` (**two states**, because Supabase appends failures to the **fragment** and a page that only said "Email confirmed" would lie at exactly the wrong moment; the fragment is read, never echoed). **Left open:** password-reset emails land on the same page saying the wrong thing, and the app has a "Forgot password?" link with no screen to enter a new password; the confirm link still reads `<ref>.supabase.co`; inbox placement still warming. [#771](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/771)
- [HANDOFF-260911.md](HANDOFF-260911.md) — **the place sweep: 221 sites the catalogue already held and had not recognised.** The existing checker matched titles, which is structurally blind to one site under two unrelated names — *Hook & Ladder 8* and *The Ghostbusters Firehouse* are 4 m apart and share no word. A **TIGHT** tier (≤25 m, any titles) found 151 pairs, **82 unreachable by any title rule**; the old 148 NEAR pairs come back as 69 + 79 exactly. `docs/place-candidates-260911.md` is the list: **A** 10 existing places missing a member standing on them, **B** 132 new sites, **C** 79 pairs 25–500 m apart. Lesson: **match a physical thing on the physical fact, and use the text only to explain the match.** **§ A then applied on owner pick — 7 places, 8 entries — and "adding the id is the whole change" was wrong**: a place's identity is exact coordinate equality (1e-9°), so each entry also had to be snapped onto its place (0.6–20.9 m, all inside their own 30 m geofence). Surfaced as the validator exiting 2 with *control DIRTY* and no detail. [#801](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/801)
