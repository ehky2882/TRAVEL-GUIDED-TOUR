# HANDOFF 2026-09-08 — the token-cost session

Two PRs, one cause. The owner reported three symptoms — plan limits burned through in a few
turns, `prompt too long` on short prompts, and sessions that had stopped auto-compacting — and
asked whether the catalogue had grown too big. It had not. All three were one file.

---

## What was actually wrong

`CLAUDE.md` was **1,505,116 bytes — roughly 418,000 tokens, injected into every request of every
session.** 97.7% of it was 34 dated `## Current State` blocks appended one session at a time.

That single fact produced all three symptoms:

- **Plan limits** — every request paid ~418k tokens before the user's prompt was read.
- **`prompt too long` on a short prompt** — the file exceeded a 200k context window *on its own*,
  so prompt length was never the problem.
- **No auto-compaction** — compaction summarises the *conversation*; `CLAUDE.md` is re-injected
  fresh afterwards, so none of it could ever be reclaimed. Compaction could not help by design.

⚠️ **`Tours.json` was explicitly ruled out**, by measurement: 11.6 MB, but never loaded whole —
sessions query it with `python3 -c`. The owner's instinct that "the catalog is getting too big"
was reasonable and wrong, and checking rather than agreeing is what found the real cause.

## PR #756 — the fixed per-request cost

Squash `f6adc5d`. `CLAUDE.md` **1.5 MB → 47,142 bytes (~418k → ~13k tokens), 96.9% smaller.**

- All 34 blocks moved verbatim to `archive/CURRENT-STATE-HISTORY.md`, **verified byte-identical**
  to main's region by sha256 against `git show origin/main:CLAUDE.md`, not against my own script.
- `docs/lessons.md` (464 lines) extracts the durable rules the history had been carrying.
- **Automation Rule #5 and § Keep Docs in Sync were amended in the same PR** — without that the
  file simply regrows. Three things now earn a `CLAUDE.md` edit: a durable rule (in place), a
  durable lesson (`docs/lessons.md`), a live count (re-derived). Everything else is the handoff's.

⚠️ **Merge conflict mid-flight**: #753 landed while CI ran, editing prose inside the Current State
region this branch had moved. Resolved by the documented pattern — take `main`'s file wholesale
(`git show origin/main:CLAUDE.md > CLAUDE.md`) and re-run the split, never hand-resolve. The split
was **rewritten to key on anchors rather than line numbers** so it survives `main` moving again,
and their edit was confirmed present in the archive **by searching for its text**, not by assuming.

## PR #757 — the per-upload cost

The owner then said they had new tour links to upload. The remaining waste was in that flow.

**Measured, not guessed:** across all 1343 live pins, `make-link-pin.py` emits **~1.9 KB of JSON
per pin**. Printing a batch to the conversation and pasting it back to write it pays for it twice
— and a conversation re-sends its whole history every request, so a batch of 20 costs ~21,000
tokens on arrival **and again on every later turn**.

- **`scripts/merge-link-pins.py`** — merges disk-to-disk; the session sees six lines. Idempotent.
  Refuses a pins file carrying a `tours` array, a pin with no coordinate or at exactly (0, 0), and
  a catalog that is not already byte-stable (a two-pin merge would otherwise reformat 11 MB).
  Keeps an existing creator row rather than overwriting it — that row may carry hand edits.
- **`docs/link-pin-runbook.md`** — the uuid5 scheme (`atlas-tour:link:`, `atlas-stop:link:`,
  `atlas-maker:<platform>:@<handle>`), which had been reverse-engineered from the live catalogue
  at least twice. Written **with the command that re-proves all three against the newest live
  pin**, so it can be checked rather than trusted.

**Verified against the real catalogue, not only its own selftest**: one existing pin + one new one
→ existing skipped, existing creator kept, **46 added lines and zero deletions**, re-run a no-op,
and `validate-tours-mirror.py` clean at 0 errors / 0 warnings over 1344 pins. `--check` left the
catalogue's sha256 unchanged.

---

## 🔴 Two corrections future sessions should inherit

**The fault harness already exists.** `validate-tours-mirror.py` injects **32 known faults on
every run** and refuses a verdict if it misses any (`SELFTEST FAILED — verdict not trustworthy`,
exit 2). Sessions 145, 146 and 148 each rebuilt one from scratch and threw it away. No new one was
written here. When you find a rule in `validate-tours.swift` the mirror does not mirror, add a
`case(...)` to its `selftest()` — that is how sessions 143, 146 and 148 each found one.

**The one-post-many-pins fragment scheme is real, and I got it wrong first.** I recorded that it
"does not exist" because no live pin has a `#` in its stored `sourceURL`. Wrong field: **the
fragment lives only in the hashed key.** `archive/README.md` contradicted the claim, and checking
properly confirmed the scheme — `atlas-tour:link:<url>#<slug(city)>`, same on `atlas-stop:`.
Reproduced live: **1333/1333** single-URL pins from the bare key, **7/10** shared-URL pins from the
city-fragment key on both ids.

⚠️ **The other 3 are a real gap, recorded rather than smoothed over.** Two are the Charging Bull
pair, **both in New York** — city cannot disambiguate two pins in one city, so their ids follow no
rule. A batch needing two pins from one post in one city has **no convention yet** and must invent
and record one.

The general lesson is in `docs/lessons.md`: **before recording that something does not exist, look
for what it would *produce*** — here, pins sharing a `sourceURL` — **not only for the spelling you
expected.** Grepping the field name returned a clean, confident, wrong answer.

## Advice given to the owner

The new rules are live on `main`, but **a conversation that already loaded the 1.5 MB file still
carries it in its own history** — the fix is fully realised only in a session started afterwards.
For the upload: start fresh.

## Not done, deliberately

`ROADMAP.md` (427 KB), `STATUS.md` (199 KB) and `archive/README.md` (471 KB) have the same shape
of problem. None is auto-injected, so none causes the reported symptoms — but `ROADMAP.md` is read
on instruction from `CLAUDE.md` fairly often. Worth the same treatment later; not urgent, and not
worth bundling into a PR about something else.
