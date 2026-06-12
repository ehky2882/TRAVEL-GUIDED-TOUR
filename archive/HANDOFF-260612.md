# HANDOFF — 2026-06-12 (session 34, web/PM — multi-day)

## TL;DR

The **"stage tours ahead of audio" workflow** ran end-to-end for the first time, at
scale: **33 new London tours** (2 batches) were drafted + image-staged days before
their audio existed, then wired into `Tours.json` and shipped the day the MP3s
arrived. **PR #192 (batch 1, 15 West End/Soho tours)** and **PR #193 (batch 2, 18
Bloomsbury/South Bank tours)** both merged to `main`, CI green.
**Catalog: 4 makers / 243 tours / 252 stops** — London **25 → 58**
(100 NYC + 54 OPO + 31 LIS + 58 LDN). No Swift/asset/project changes.

## The audio-pending staging workflow (now proven)

1. Owner sends tour text (regular + TTS) with **no audio yet**.
2. Claude appends a draft to `drafts/pending-tours.json` **on the session branch**
   (slug, coords, category, tags, shortDescription, transcript) — survives
   container resets.
3. Images sourced immediately (Unsplash + Openverse CC0 + owner pastes), owner
   picks by number, crops staged to `gh-pages` — `heroImageURL` /
   `additionalImageURLs` recorded in the draft.
4. When MP3s arrive (5 at a time): read duration via `mutagen`, upload to
   `gh-pages` `audio/<slug>.mp3`, mark draft `audioStatus: READY`.
5. When a batch is fully READY: author per-tour `caption` +
   `longDescription`, assemble full Tour entries (UUIDs, lowercased tags,
   `kind: single`, `geofenced`), append to `Tours.json`, run validator
   (python mirror — no swift in container), live-check every audio+hero
   URL (curl 200), PR → CI → squash-merge. Draft file deleted in the same PR.

## What shipped

- **PR #192 — batch 1 (15):** Buckingham Palace, St James's Park, The Mall &
  Admiralty Arch, Burlington Arcade, Royal Academy, Berkeley Square, Shepherd
  Market, Covent Garden, Seven Dials, Neal's Yard, Soho, Chinatown, Denmark
  Street, Leicester Square, Carnaby Street. (Shipped in TestFlight 1.0 (40),
  cut by the owner's local session — see HANDOFF-260611.md.)
- **PR #193 — batch 2 (18):** British Museum, British Library, Sir John Soane's
  Museum, Lincoln's Inn Fields, Foundling Museum, Charles Dickens Museum, Senate
  House, Hatton Garden, Tate Modern, Shakespeare's Globe, Borough Market,
  Southwark Cathedral, The Shard, National Theatre, Royal Festival Hall,
  Millennium Bridge, Cross Bones Graveyard, Old Operating Theatre.
  **Not yet in a TestFlight build.**

## Incidents + lessons

1. **Tours.json merge conflict (PR #192).** Parallel Lisbon/Porto sessions merged
   26 tours into `main` after batch 1 branched → PR went `mergeable_state: dirty`
   and **CI refused to run at all** (0 check runs — a conflicted PR never triggers
   CI; don't wait for checks that will never come). Fix: `git merge origin/main`
   into the branch, take **main's** Tours.json wholesale, re-run the assembler to
   re-append the batch (assembler skips existing titles → idempotent), validate,
   push. Diff vs main confirmed +N/0-removed before pushing.
2. **Batch-2 prevention:** merged `origin/main` into the batch-2 branch *before*
   assembling. No conflict, clean +18 diff.
3. **Branch deletion is blocked by this environment's git proxy** — every
   `git push origin --delete` disconnects ("remote end hung up"). Merged branches
   `claude/dreamy-wozniak-nM6a4` and `claude/dreamy-wozniak-nM6a4-batch2` are
   still on origin; **owner should delete them from the GitHub UI** (or any local
   session can).
4. **gh-pages Pages deploys race** when two pushes land close together — the older
   deployment 401s ("Requires authentication") and emails a "Run failed" alert.
   Harmless: the newer deploy wins and carries the full accumulated content.
   Verify by URL-checking, not by the email.
5. **Unsplash rate cap (50/hr)** hit twice across the image-sourcing days. The
   reset can be polled cheaply: a background loop curling a 1-result search every
   3 min until HTTP 200 (`/tmp/poll_unsplash.sh` pattern).
6. **Wrong-building Unsplash results are the norm for niche subjects** — Royal
   Festival Hall returned the Royal *Albert* Hall, Senate House returned the Smith
   Tower (Seattle), Southwark Cathedral returned Westminster Abbey/St Paul's,
   "Shakespeare's Globe" returned literal globes. Verify pixels always; when
   unverifiable, ask the owner to paste rather than risking a wrong hero.
7. **CC0 niche wins:** Cross Bones' ribbon gates, the Old Operating Theatre's
   full interior set, Seven Dials' Doré/Boz engravings — Openverse/Wikimedia PD
   sometimes has exactly the defining shot Unsplash lacks.

## Open / follow-ups

- **Next TestFlight cut** should bundle batch 2 (18 tours, merged after 1.0 (40)
  was cut). Owner archives/uploads from a local session per `docs/testflight.md`.
- **Hero-only galleries:** Hatton Garden and Royal Festival Hall shipped with hero
  only; owner can paste interiors anytime to enrich.
- **Stale branches to delete via GitHub UI:** `claude/dreamy-wozniak-nM6a4`,
  `claude/dreamy-wozniak-nM6a4-batch2` (both merged).
- Carried code follow-ups unchanged (on-device M-qa, design pass, `placemark`
  deprecation, Player drag/volume device pass).
