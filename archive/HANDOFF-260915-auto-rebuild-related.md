# The suggestion rebuild runs itself now

**Session 114 (cont.) · branch `claude/open-source-ai-integration-pxuxdh` · CI only**

Owner asked, of the "More like this" lists shipped earlier today: *"why cant we
run this everytime a tour gets added etc? is that resource-intensive? not
advisable?"*

It was neither. Nobody had built it. `grep -l embedding .github/workflows/*`
returned nothing — regenerating was a command a human had to remember after a
city launch, which is exactly the kind of step that gets skipped once and then
silently stays skipped, leaving a whole city with no suggestions and no error
anywhere to say so.

---

## What it does

A new `rebuild-related` job at the head of `publish-catalog.yml`, which already
fires on every content merge. It runs the generator's model-free self-tests,
regenerates the neighbour lists, and — only if something actually changed —
validates and commits to `main` with `[skip ci]`. The existing `publish` and
`seed-supabase` jobs now `needs:` it, so the mirror and the database carry the
regenerated file in the same run.

## The decision worth recording: NO VECTOR CACHE

The obvious optimisation is to save the numbers and only embed what is new,
turning ~15 minutes into a few seconds. **It was considered and rejected.**

Caching means reusing a saved answer whenever an entry *looks* unchanged. The
day that judgement is wrong — a new field enters the embedded text, a hash
misses an edit — the affected entries keep a stale neighbour list **with no
error and no red build**. That is the precise shape of failure this project
keeps paying for (`docs/lessons.md` is largely a catalogue of it).

The compute is free: the repo is public, so Actions minutes are unlimited.
**Paying 15 minutes of free runner time to be certain beats saving it to be
probably right.** Only the MODEL download is cached — the slow, flaky,
network-dependent part, keyed by the model id so a model change misses the
cache rather than silently running old weights.

## The cheap check that makes it affordable

Added after watching a real merge. **#930 (26 owner-approved coordinate fixes)
landed while this was in review**, and it exposed the flaw: `tour_text()` reads
titles, descriptions, tags, city, country and stop captions — **never a
coordinate, never an image URL**. So #930 would have run the model for 15
minutes, produced nothing, and delayed the mirror and the Supabase seed by that
long. Most content merges look like #930.

`scripts/related-text.digest` is a sha256 over exactly what the model reads. The
job computes it, compares, and skips everything when it matches. **Verified
against the real event: the digest is byte-identical across #930's 170 changed
lines.**

🔴 **This is NOT the vector cache rejected above**, and the difference is the
failure mode. A per-entry cache decides for each tour whether a saved answer is
still valid; one wrong decision leaves that tour stale forever, silently. The
digest is written **only by a rebuild that actually succeeded and committed**, so
a run that is skipped, fails, or loses its push race leaves the old value and the
next run rebuilds. Worst case: one redundant run. Never a stale list.

⚠️ **A flaw in the first wiring, caught before it shipped.** The commit step was
gated on the *catalogue* changing. But a rebuild can legitimately leave the
catalogue untouched while the digest has moved — a new tour whose matches all
fall under the 0.45 floor and which displaces nobody. That would have skipped the
commit, left the digest unadvanced, and made **every future merge re-run the
15-minute rebuild forever**. The gate now checks both paths.

## The invariant that was broken, deliberately

The workflow header used to promise it *"pushes only to gh-pages (never main),
so it cannot retrigger itself."* That is no longer true, and the header now
says so. The loop is closed by **`[skip ci]`** in the commit message, which
stops GitHub raising a new run. Without it, every content merge would cost a
second 15-minute run that finds nothing to change.

## What happens when things go wrong

- **`main` moves during the rebuild** (a merge lands while embedding runs): the
  push fails, the job emits a `::warning::` and **does not fail the run**. The
  publish and seed jobs still ship whatever `main` holds, so content reaches
  phones either way, and the next content merge regenerates from scratch.
  Self-healing beats a force-push.
- **Embedding fails** (Hugging Face unreachable): `publish` and `seed-supabase`
  carry `if: ${{ !cancelled() }}`, so they run anyway. Suggestions going stale
  is a degradation; content not reaching phones is an outage. They are not
  ranked equally.
- **The generator is broken**: the self-tests run *before* the regeneration, so
  it fails before writing 15,000 lines into the catalogue.
- **The regenerated catalogue is bad**: `validate-tours-mirror.py` gates the
  commit. It is the Python stand-in for the Swift validator (no Swift on a
  generic runner) and it self-tests against injected faults before its verdict
  counts — and it carries the pin same-city rule, which nothing else can see.

## Verified

- `main` is **not** a protected branch (checked via the API, not assumed) — a
  `GITHUB_TOKEN` push will be accepted. This was the one thing that could have
  made the whole design a silent no-op.
- The workflow parses, and the job graph is
  `rebuild-related → {publish, seed-supabase}`.
- **The digest is byte-identical across #930** — a real merge of 26 coordinate
  fixes, 170 changed lines — so that merge would correctly have skipped. Checked
  by computing it at `0d17b7a8` and at `HEAD`, not by reasoning about it.
- 39 generator self-tests green, including the **negative** ones that carry the
  whole idea: a coordinate edit, a stop-coordinate edit and an image edit must
  NOT move the digest, while a title, a description and an id must.
- **The first real run will be a no-op**: the catalogue has not changed since
  this afternoon's regeneration (`git log 0d17b7a8..origin/main -- Tours.json`
  is empty), and that run was verified idempotent — 0 of 3,900 entries changed,
  byte-identical output. So the untested push path will not fire until genuinely
  new content lands, which is the gentlest possible first exercise.

⚠️ **Not verified: the commit-and-push path itself.** It cannot be exercised
from here — it needs a real content merge on a real runner. **Watch the next
city launch or pin batch**, and check that `main` gains a
`chore(catalog): rebuild More like this suggestions [skip ci]` commit and that
the new entries have neighbours.

## Cost

**Seconds on a merge that changes no embedded text**, which is most of them —
the digest check needs no model and no network. ~15 minutes of free runner time
on a merge that adds or edits real content, before the mirror and the seed run.

The catalogue churns slightly more on those — a new tour can bump into existing
entries' top eight, so a handful of other rows change too, and every changed row
is re-downloaded by phones. Small today; delta fetching (1.1.3) shrinks it.
