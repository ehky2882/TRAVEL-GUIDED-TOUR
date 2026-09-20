# HANDOFF 2026-09-20 — the catalogue-wide vision sweep

## What this was

Until this week **no check in the repo asked whether a title matches the content it links
to.** `validate-tours.swift` proves the JSON is well-formed; `check-coordinates.py` proves a
pin is in the right city; `check-image-duplicates.py` proves two entries do not share bytes.
None of them opens the picture and asks *is this the thing the title says it is?*

`scripts/check-pin-subject.py` does. It reads each entry's hero image and puts it to Gemini
through four gates:

| Gate | Question | Notes |
|---|---|---|
| **A** | Is this a photograph of an identifiable place at all? | A plate, a face, a title card → **UNUSABLE** |
| **B** | Is it *the titled subject*? | Distractors named explicitly — that is what catches the wrong monument |
| **C** | Open-ended: *what is it?* | Asked for **evidence, never a verdict** |
| **D** | Are these two NAMES the same thing? | No image. Can only **WITHDRAW** a finding, never create one |

🔴 **Two independent calls, never one compound question.** A single prompt asking "is this the
subject AND a usable photo" gets answered on subject match alone — that is the failure that
shipped Rijksmuseum engravings to the owner as photographs (see `docs/lessons.md`).

🔴 **UNUSABLE is not a pass.** It means the check could not speak. Those titles remain
**unverified**, exactly as `spine-match`'s UNMATCHED does.

## The run

Ten chunks of ~450 entries, on a 45-minute scheduled wake, each committing
`checks/pin-subject.json.gz` and pushing before the next. The cache is the unit of progress, so
no chunk depended on the conversation surviving — and one did not need to.

| chunk | CONTRADICTS | CONFIRMS | DISPUTED | UNUSABLE |
|---|---|---|---|---|
| 1 | 34 | 325 | 12 | 75 |
| 2 | 47 | 242 | 6 | 152 |
| 3 | 35 | 292 | 13 | 110 |
| 4 | 40 | 231 | 12 | 167 |
| 5 | 26 | 212 | 19 | 193 |
| 6 | 26 | 127 | 16 | 281 |
| 7 | 24 | 186 | 14 | 226 |
| 8 | 33 | 111 | 7 | 299 |
| 9 | 16 | 40 | 1 | 393 |
| 10 | 20 | 135 | 5 | 209 |
| **total** | **323** | **2,106** | **126** | **2,307** |

**4,862 of 4,862 entries with a hero. 0 unchecked.**

## 🔴 The honest headline is the unverified half, not the confirmed one

**UNUSABLE climbed from 75 in chunk 1 to 393 in chunk 9** — and it is not noise. The sweep
began on landmark tours, where the hero is a building, and ended on creator pins, where the
hero is a plate, a face or a title card. **2,307 entries — 47% of the catalogue — the check
could not read at all.** It is heavily concentrated:

| creator | UNUSABLE / total |
|---|---|
| Instagram @jacksdiningroom | **250 / 256** |
| Instagram @japanbyfood | **87 / 88** |
| TikTok @asamapov | **37 / 37** |
| Instagram @rayisaplace | 29 / 33 |
| Instagram @shivanidukhandee | 86 / 105 |
| TikTok @urbanistariel | 147 / 326 |

That concentration is the useful finding: for a handful of food accounts the hero is *never* a
place, so re-running the check on them will never produce anything. Verifying those needs a
different instrument (the post's own caption and location tag), not a better prompt.

## The findings, and what they are worth

**323 CONTRADICTS.** **22 of them the owner has already ruled on** (`checks/owner-verdicts.json`,
matched by title) — **do not re-ask those**. **301 are new.**

🔴 **Precision is 42%, measured, not guessed.** Of the first 33 the owner reviewed one at a time:
**14 were real catalogue errors** (7 on the wrong continent — MSG Sphere was the Lucas Museum in
LA, MOL Campus was Eurovea Tower in Slovakia, Bosco Verticale was La Nouvel KLCC) and **19 were
the check being wrong**. So 301 new findings implies **roughly 125 real errors** — and roughly
175 rows that will cost the owner's attention for nothing.

**That ratio is the open problem.** Reviewing 33 one at a time in chat consumed most of a
session. 301 cannot go the same way. Unresolved options, for whoever picks this up:

- Rank by the check's own confidence signals (gate C naming a place in a *different country* is
  a far stronger signal than one naming a neighbour) and put only the top band to the owner.
- Corroborate before asking: a CONTRADICTS whose gate-C answer *also* disagrees with the spine
  coordinate is near-certainly real; one that does not is probably the check being wrong.
- Batch by creator — the CONTRADICTS are concentrated (17 @pasttworld, 15 @nom_life,
  15 @archimarathon, 14 Atlas Studio TYO, 14 @urbanistariel), and a creator's errors tend to
  share a cause.

**Do not hand the owner 301 rows sorted by the check's own enthusiasm.** That mistake was already
made once this session and they said so plainly.

## 🔴 The root cause is still unfixed

`scripts/make-link-pin.py` takes **`--lat --lon --city --title` as INPUTS**. Nothing derives
them, nothing corroborates them. Every error this sweep found entered the catalogue because a
human (or a session) typed a value and no check could contradict it. The authoring gate added
this week (`check-pin-title.py`, wired into `merge-link-pins.py`) catches a caption masquerading
as a title, and the vision check catches a wrong subject *after* the fact — but neither derives
the coordinate. **Until something does, the catalogue keeps accruing these at the rate links are
added.**

## State

- Branch `claude/overnight-vision-sweep`, cache committed after every chunk.
- The Gemini key lived in the session scratchpad (mode 600, outside the repo tree) and **dies
  with the container** — a re-run needs a fresh paste.
- Re-running is cheap: the cache is keyed by entry id + image digest + `RECORD_VERSION`, so a
  changed hero re-derives and an unchanged one costs nothing. **Bump `RECORD_VERSION` to
  re-derive everything** rather than trusting a cache written by an older prompt.
