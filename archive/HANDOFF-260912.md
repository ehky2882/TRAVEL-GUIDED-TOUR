# HANDOFF — 2026-09-12

## What happened

The owner pasted 30 raw `vm.tiktok.com` short links from one creator, asking for a **triage first** —
which are usable, which aren't — with nothing minted until they said so.

**Triage.** `scripts/triage-account.py --urls` resolved all 30 to one creator, **@heyrosiedart**
(London vintage/interiors/film-location content). The tool's caption-regex flags gave 16 SINGLE / 14
THIN / 0 MULTI, but per the skill's own warning ("flags are a pre-sort, not a verdict") I read every
caption by hand and then went a step further: pulled every post's oEmbed thumbnail via
`make-link-pin.py`'s `oembed()` and looked at the actual video frame. That mattered more than usual
here — **five of the eventual pins (Le Beaujolais, Michelin House, Wilton's Music Hall, Barbican
Laundrette, Turquoise Island) named nothing in their caption at all**; the regex would have binned
all five as THIN. Conversely several regex-SINGLE posts turned out to be movie/TV stills (Ratatouille,
Lady Bird, Shrek, The Incredibles, The Substance, Severance, The Parent Trap, The Princess Diaries)
with no real visited address, and two "SINGLE" posts ("vintage aesthetic swim spots", "swim
spots in/around London") were actually multi-location roundups in disguise.

Reported all 30 back to the owner as pin/skip/research-needed, with reasoning, before touching
anything.

**Owner's decisions.** Approved 15: 7 with owner-supplied coordinates (reverse-geocoded to sanity-check
— the-listed-slide, the Diana-history building, the Talgarth Road studios, the Nourish & Flourish
factory, Globe House, the Pied Bull Yard shop, the Canonbury glass-brick house), 2 approved by name
only (Porchester Spa, Reelstore — geocoded from their real addresses), and 6 more from my original
"confident pin" list that the owner hadn't explicitly mentioned — confirmed via one `AskUserQuestion`
rather than assumed. **Declined the Penguin Pool at London Zoo** despite it being a clean, confident
single-place ID — the owner's call, no reason asked. Left 14 more out: 8 fictional film/TV stills,
one private-home vlog, one unidentifiable shop, one private-residence glass-brick house (folded into
the approved 15 once the owner gave its coordinate), and 4 multi-location roundups pending a future
decision on whether to explode them into separate pins.

**Minted and shipped.** `make-link-pin.py` run 6 times (once per `primaryCategory`, since a batch
run shares one `--category`/`--tags` across all its rows) → merged with `merge-link-pins.py` →
`validate-tours-mirror.py` caught 5 pins missing a Theme or Place-type tag (all from the
`hiddenGems`/`musicAndPerformance` batches, whose shared tags didn't cover both facets) — fixed by
hand-editing the 5 `tags` arrays in `Tours.json`, re-validated 0/0. 16 heroes + 1 shared avatar
(all 15 pins are one creator) hashed with no duplicates among themselves, pushed to `gh-pages` in
one commit (`acb2170`), hash-verified live against the CDN afterward. PR
[#828](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/828): CI green (4/4 checks), no
review comments needing action (Vercel bot noise only), content-only → auto-merged per policy,
squash `0f73983`.

**Verified live, not just merged.** `publish-catalog.yml`'s `Seed catalog into Supabase` job ran and
succeeded on the merge; `catalog_snapshot_age()` shows the snapshot rebuilt at `09:50:57Z` (matching
the seed step), and a cheap `tours?source_author=eq.@heyrosiedart` count returns exactly **15**. No
owner SQL is owed. The gh-pages `Tours.json` mirror was still serving the pre-merge count a few
minutes after the workflow's own "Verify gh-pages now serves the same catalog" step passed — normal
CDN lag (§ READ FIRST's ~10 min caveat), not a defect; Supabase (primary source) already carried it.

## Environment note

No `gh` CLI in this remote session (as the system prompt says — GitHub work goes through the
`mcp__github__*` tools instead) and no `swift` either. `scripts/upload-images.py` assumes `gh api`,
so heroes went to gh-pages via a plain `git worktree` + `git push` instead (binary-safe, unlike
routing image bytes through an MCP tool's JSON string parameter, which would risk corrupting
non-UTF8 webp bytes). `swift scripts/validate-tours.swift` couldn't run either; `ci.yml`'s green
"Build (iOS Simulator)" + "Validate Tours.json" checks on the PR stood in, per this repo's
documented web-session workflow. `pip3 install Pillow` was needed before `make-link-pin.py` could
crop heroes — not present in this container by default.

## Numbers (re-derived on `0f73983`, this session's own merge — nothing landed mid-flight)

**1552 tours + 1809 link pins, 385 makers, 1924 tour stops (3733 including one per pin), 288 places
covering 694 entries. 486 cities, 64 countries** (unchanged — the batch's city/country, London/UK,
already existed). 34 Atlas Studios + 351 pinned creators (123 TikTok, 216 Instagram, 12 YouTube).

## Nothing owed

No owner SQL, no open review threads, no CI red. The 4 multi-location roundup posts
(#1/#12 swimming-pool videos, #23 "London's ghost signs", #26 music-video interiors) are the one
open thread if the owner wants to revisit them — each would need a per-post decision on whether to
explode into several pins or drop.
