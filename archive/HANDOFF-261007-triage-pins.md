# Handoff 2026-10-07 — 25 link pins from a 39-link triage, 6 architect tags

## What shipped
- **25 link pins** from 39 Instagram/TikTok links (10 creators; 4 new creators: IG @sanfranciscoguide, IG @victor.yang1012, IG @chrischurchexplorer, TikTok @baroqueblockbuster). Catalogue 4058 → 4083 pins, makers 633 → 637, cities 919 → 929.
- **6 new architect tags** (Job 5, add-only): Charles and Ray Eames, Walter Gropius, Eliot Noyes, Eileen Gray, Takamitsu Azuma, Fritz Höger. The two existing Villa E-1027 pins (@nikola.matus, @rayisaplace) were tagged Eileen Gray too.
- 25 heroes + 1 avatar on gh-pages in one commit (`9586a9c`), 26 adds, 0 overwrites.

## What was skipped, and why (contributor's decisions, 2026-10-07)
- Already live, same creator: Carpenter Center, Antwerpen-Centraal, Bunker St. Pauli, Soho House Berlin; Bierpinsel (same creator's TikTok pin).
- #10 @anshmehra.in Swiss stationery shop (unplaceable from caption/cover), #9 Shinohara's House in Uehara (private home, no public address).
- Same creator, same building: kept one post each — Kilpeck (south door), Worcester Cathedral (main post), Tewkesbury Abbey (Gothic makeover). Dropped: Kilpeck corbel ×2, King John's tomb, Tewkesbury tower, Wakeman Cenotaph.
- Advertising: @paris_and_beyond_tours Sainte-Chapelle (tour-booking CTA), @janez_vermeiren The Ritz, Sea Point (estate-agent sign-off).
- #22 (St Anthony and the pig, Sa Pobla MULTI) pinned to the Church of Sant Antoni Abat on instruction.

## Coordinates worth knowing
- Uchida Shoten HQ: registered address 藤沢市本町1-4-23 (GSI). The new Schemata building is in Honmachi too; may be off by a block.
- Noyes House: 90 Lambert Rd (Noyes House II, 1955), private residence.
- Romanița: the SovMod tour's coordinate reverse-geocodes to Blocul Locativ „Romanița” — reused exactly.
- Three IG reels (Eltham Palace, Port House, Western City Gate) use licensed music — they open Instagram instead of playing inline.

## Open for Edward
`status/owner/place-batch-261007-triage.md` — 4 place questions (Sydney Opera House, Villa E-1027 join, Romanița, Genex/Western City Gate). Not asked of the contributor.

## Trap hit
On a `--filter=blob:none` gh-pages fetch, plain `git write-tree` (and a renames-on `git diff`) lazily fetches every missing blob — the 4 GB problem in another form. Use `GIT_NO_LAZY_FETCH=1`, `git write-tree --missing-ok` and `git diff-tree --no-renames`. A killed write-tree also leaves a truncated index; start from a fresh `GIT_INDEX_FILE`.
