# HANDOFF — 2026-06-15 (session 38, web/PM — Lisbon batch 3 + build 44)

## TL;DR

**14 Lisbon tours shipped (PR #200) and TestFlight 1.0 (44) cut, archived,
and live.** LIS **46 → 60** — Lisbon batch 3: Belém (Monument to the
Discoveries, National Coach Museum), the four Alfama / Bairro Alto
miradouros, the Estrela pair (basilica + garden), Casa dos Bicos,
Avenida da Liberdade, Jazigo dos Duques de Palmela, Ribeira das Naus,
Village Underground Lisboa. **Catalog 258 → 272 tours / 4 makers / 281
stops** (100 NYC + 58 LDN + 54 OPO + 60 LIS). All audio + images
owner-supplied (`/Users/EY/Downloads/260615_PORTUGAL/`), no sourcing
pipeline. Build 44 also carries **PR #201** (home placecard polish),
merged earlier by a parallel session.

## What happened

1. **gh-pages:** audio `d4bd503` (14 MP3s, slug-named), images `b56899a`
   (38 webp, `<Base>_hero/_2…` naming). All live URLs spot-checked 200
   (8 checks). Worked in the existing `/tmp/ghpages` worktree
   (gh-pages can only be checked out once; pulled clean before staging).
2. **PR #200** — 14 tours appended to `Tours.json` via an idempotent
   Python assembler (`/tmp/assemble_lisbon.py`, since removed) that reads
   each transcript file directly and does append-only textual insertion
   (640 insertions, 0 deletions — clean diff). Validator clean
   (4 makers / 272 tours / 281 stops); CI fully green (Build · Validate ·
   Unit tests); squash-merged `cccbd9b`, branch deleted. Built in a
   dedicated `/tmp/lisbon-batch` worktree.
3. **PR #201** (`0ea562b`) — home placecard polish, **merged by a
   parallel session** just before #200: `PlacecardView` title ALL CAPS
   with `lineLimit(2)`, distance line `tertiaryText` → `secondaryText`,
   card width standardized at **2/3 of the active scene width** via a new
   `HomeView.placecardWidth` static. `HomeView.swift` + `PlacecardView.swift`.
4. **PR #202** — bump **43 → 44** via the short-lived-PR pattern
   (app-target `CURRENT_PROJECT_VERSION` lines only; test target stays 1;
   `MARKETING_VERSION` stays 1.0); admin-squash-merged `7f675a3`, branch
   deleted. Ran in a `/tmp/build44` worktree.
5. `xcodebuild archive` clean at `/tmp/Atlas-20260615-2246-b44.xcarchive`;
   embedded version verified `1.0 (44)`; `UIRequiresFullScreen=true` held
   (no validation 90474). Owner uploaded via Organizer.
   **TestFlight 1.0 (44) is live.**

## Tours added (all Lisbon, single-stop, manual trigger, 30 m, free)

| Tour | Category | Dur |
|------|----------|-----|
| Avenida da Liberdade | `culturalHeritage` | 2:11 |
| Basilica of Estrela | `sacredSites` | 2:43 |
| Casa dos Bicos | `history` | 1:56 |
| Eduardo VII Park | `natureAndParks` | 2:15 |
| Jardim da Estrela | `natureAndParks` | 2:12 |
| Jazigo dos Duques de Palmela | `history` | 2:25 |
| Miradouro da Graça | `natureAndParks` | 2:03 |
| Miradouro das Portas do Sol | `natureAndParks` | 2:03 |
| Miradouro de Santa Catarina | `natureAndParks` | 2:14 |
| Miradouro de Santa Luzia | `natureAndParks` | 2:10 |
| Monument to the Discoveries | `history` | 1:52 |
| National Coach Museum | `culturalHeritage` | 2:02 |
| Ribeira das Naus | `culturalHeritage` | 2:08 |
| Village Underground Lisboa | `culturalHeritage` | 2:00 |

## Quirks handled / lessons

- **Accented drop-folder names break shell globs.** `Miradouro da Graça`
  (the `ç`) wouldn't match a `Gra*` literal-with-accent glob because of
  macOS Unicode normalization (NFC vs NFD); copied that one folder
  separately with a wildcard for the accented char. The Python assembler
  located folders by an ASCII prefix + `glob` to sidestep this.
- **Category deviation:** Ribeira das Naus → `culturalHeritage`, not the
  brief's suggested `natureAndParks` — the transcript is entirely about
  the Arsenal das Naus shipyard heritage, not green space.
- **`gh pr merge --delete-branch` local-checkout error.** After the
  server-side squash-merge succeeded, gh's post-merge `git checkout main`
  failed with `'main' is already used by worktree` (the primary checkout
  holds `main`). The merge had still landed — confirm via
  `gh pr view --json state,mergeCommit`, then delete the remote branch +
  ff-pull main manually. Happened on both #200 and (avoided on) #202.
- **Worktrees the whole way.** Three sessions were live on this checkout;
  every mutating step ran in an isolated worktree (`/tmp/ghpages`,
  `/tmp/lisbon-batch`, `/tmp/build44`), so the primary checkout never
  left `main` and there were **no branch-flip incidents** this session
  (unlike session 37). Remove each temp worktree when done;
  `/tmp/ghpages` is the documented persistent one — leave it.
- **Transcripts had no `Stop 1 —` header** this batch — `transcriptText`
  is the raw `.txt` content, trailing whitespace trimmed; `[beat]`
  markers preserved.

## Follow-ups

- Standing offer: 5-min App Store Connect API key setup for upload
  automation (`docs/testflight.md` § Full upload automation) — **owner
  deferred again this session** ("archive only as usual").
- Carried code follow-ups unchanged (on-device QA, compass ⌥-drag hand
  check from session 36, `placemark` deprecation, Player drag/volume
  device pass; rails deferred items: drawer scroll-reset on reopen,
  distance on NEAR YOU cards, per-rail "see all").
