# Atlas — Handoff Notes (2026-06-04, session 20)

Web/PM session — image pipeline pass on existing NYC tours. No new
tours added, no Swift changes, no build bump. Catalog stays at
**138 tours / 147 stops / 3 makers**. Branch:
`claude/session-012bd7xvvgfz8cpkucw3bqy8-0MeY7` — **not yet merged
to main** (all content commits, so auto-merge on CI green is the
right path).

---

## What happened this session

### 1. Image pipeline codified as an automation rule

`CLAUDE.md` updated (commit `81b52f4`) with:
- **Rule #8** — new tour added without gallery images → run pipeline
  automatically. Exception: owner-supplied Portugal/Porto/Lisbon
  assets.
- **§ Image Pipeline** — full procedure documented: Unsplash search (6
  queries × 3 results) → Gemini vision verification gate → Pillow
  1200×900 WebP q82 crop → labeled owner preview → final crop →
  gh-pages upload → Tours.json patch.
- **Gemini key note** — key starts with `AQ.`; never prepend
  `AIzaSy`. Confirmed working after an earlier incorrect-prefix
  failure.

### 2. Fourteen NYC tours received new images

Owner drove all hero / gallery selections from labeled previews.
"Keep current hero" = Wikimedia URL left in place; only
`additionalImageURLs` updated.

| Tour | Slug | Hero | Gallery |
|------|------|------|---------|
| Empire State Building | `empire-state-building` | obs-deck view (new) | low-angle ×2, night |
| Chrysler Building | `chrysler-building` | gargoyle close-up (new) | exterior ×2, crown |
| Brooklyn Bridge | `brooklyn-bridge-manhattan-side` | iconic shot (new) | walkway, cables, aerial, golden hour |
| Met Museum | `metropolitan-museum-fifth-ave-steps` | exterior (new) | exterior, steps |
| Bethesda Terrace | `bethesda-terrace` | fountain (new) | staircase ×2, angel/fountain |
| Grand Central | `GRAND.CENTRAL.SOUTH.FACADE` | **kept Wikimedia** | 2 exterior gh-pages shots |
| High Line | `high-line-10th-avenue-overlook` | **kept Wikimedia** | 1 overlook gh-pages shot |
| Rockefeller Center | `rockefeller-center-the-plaza` | plaza (new gh-pages) | ice rink, original Wikimedia |
| One WTC | `One_World_Trade_Center` | exterior (new) | night, exterior-2 |
| Guggenheim | `guggenheim-museum` | FLW facade (new) | exterior, FLW facade, interior ×2 |
| Times Square | — | skipped ("None, leave as-is") | — |
| Statue of Liberty | `statue-of-liberty` | aerial/close (new) | aerial, crown/detail, golden hour ×2 |
| Washington Square Park | `washington-square-park` | **kept Wikimedia** | arch-close, arch-wide, fountain, path, fountain-2 |
| Flatiron Building | `flatiron-building` | symmetry (new) | exterior, from-above, daytime |
| Lincoln Center | `lincoln-center` | plaza-wide (new gh-pages) | night, original Wikimedia |

All images: 1200×900 WebP q82, hosted at
`https://ehky2882.github.io/TRAVEL-GUIDED-TOUR/images/`.
Naming: `<audio-slug>_hero.webp`, `<audio-slug>_2.webp`, etc.

### 3. Gemini caught several impostors

Rejected across the session: Williamsburg Bridge (labeled as Brooklyn
Bridge night), Las Vegas Statue of Liberty replicas ×2, Milan Galleria
(labeled as Grand Central ceiling), Montreal Museum of Fine Arts
(labeled as Met), generic NYC skylines labeled as Central Park /
One WTC. Pass rate ~60–80% depending on subject specificity.

### 4. "Central Park" mis-pick corrected

Near session end, Claude mistakenly fetched images for a "Central
Park" tour that doesn't exist as a standalone tour — only Bethesda
Terrace (already done). Caught immediately; the 16 images were
discarded. No Tours.json change.

---

## In-flight at session end

A background process (`/tmp/wait_and_fetch_911.py`) is polling for
the Unsplash rate limit to recover (50 req/hr free tier; was at ~3
remaining). When it recovers it auto-fetches **9/11 Memorial** images
to `/tmp/memorial_911/`. Check with:

```bash
cat /tmp/claude-0/-home-user-TRAVEL-GUIDED-TOUR/29a685d0-8039-452e-a7bf-84a93ef49cfc/tasks/bfplw6ow6.output | tail -20
ls /tmp/memorial_911/ 2>/dev/null
```

If the background process completed: run Gemini verification, generate
labeled previews, show owner. If it timed out or the directory is
empty: re-fetch manually.

---

## NYC tours still needing gallery images

Roughly 25+ tours remain. High-priority next picks:

1. **9/11 Memorial** — in-flight (fetch queued)
2. St. Patrick's Cathedral
3. New York Public Library, Fifth Avenue
4. Brooklyn Museum
5. Whitney Museum of American Art
6. American Museum of Natural History
7. Brooklyn Bridge Park
8. South Street Seaport, Pier 16
9. Governors Island
10. The Oculus
11. Vessel, Hudson Yards
12. Wall Street
13. Cooper Hewitt, Smithsonian Design Museum
14. The Frick Collection
15. The Morgan Library & Museum
16. New Museum
17. The Shed
18. MoMA PS1

---

## Unsplash rate limit notes

- Free tier: 50 requests/hour. Hit after ~14 tours (6 queries × 3
  results = 18 req per tour, plus re-fetch rounds).
- Check remaining via any API call's `x-ratelimit-remaining` response
  header before starting a new tour's fetch.
- Rate limit resets at the top of each UTC hour.

---

## How to resume

1. `git fetch && git status && git branch --show-current` — confirm
   you're on `claude/session-012bd7xvvgfz8cpkucw3bqy8-0MeY7`.
2. Check if the background 9/11 Memorial fetch completed (see
   § "In-flight" above). If yes, pick up from Gemini verification.
   If no, re-run the fetch script.
3. Continue the pipeline tour by tour — owner picks selections from
   labeled previews, Claude processes + uploads + patches Tours.json
   + commits.
4. When a natural stopping point is reached (rate limit, or owner
   wraps up): open a PR for the branch (`git push`, then
   `gh pr create` or use the GitHub MCP tool). This is a pure
   content/Tours.json PR — auto-merge on CI green per the merge
   policy.
5. Do **not** run the pipeline on Portugal/Porto/Lisbon tours.
   Owner supplies those images.
