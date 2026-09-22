# Send the 4 @welldonestuff links so they can be restored

_opened 2026-09-21 · rewritten 2026-09-21 after the original claim was found to be false_

## 🔴 What this item used to say was WRONG

It said PR #1032 dropped four posts because they duplicated landmarks
"already pinned in the catalog from **earlier posts by the same creator**".

**They are not the same creator.** Checked against the live catalogue:

| landmark | the existing pin is by | the dropped post was by |
|---|---|---|
| Calgary Central Library | **@taylinmaylin** | @welldonestuff |
| Guangzhou Circle | **@pasttworld** | @welldonestuff |
| Huajiang Grand Canyon Bridge | **@pasttworld** | @welldonestuff |
| Three Gorges Dam | **@pasttworld** | @welldonestuff |

The owner spotted this: *"i dont have a duplicate at calgary central library
unless you say the tour by taylinmaylin is the same thing?"*

**It matters because the owner has twice ruled the other way on exactly this
case.** On the #1040 batch they overrode the duplicate-drop default for
Fraunces Tavern, Ye Olde Cheshire Cheese and the Stonewall Inn, wanting a
different creator's take pinned alongside the existing entry. Same-creator
twice is a genuine duplicate; **a different creator is a second take, and the
owner wants those.** All four of these should have been kept.

## 🔴 What is blocking the fix

**The four source URLs were never recorded anywhere**, so the posts cannot be
restored from the repo. Checked and came up empty:

- the `#1032` branch — **deleted** after merge
- the PR body — names the four landmarks, no links
- `drafts/` and the rest of the tree — nothing
- a web search for the reels — @welldonestuff has 1,241 posts and Instagram
  offers no per-post search; the profile will not serve a scrape

### Re-checked 2026-09-22 — three more routes, all empty

| route | result |
|---|---|
| **PR #1032's retained commits** (`refs/pull/1032/head` — GitHub keeps these after the branch is deleted) | 4 commits; the first carries **exactly 54** Instagram URLs, the 54 pins that were kept. **The four were filtered out before anything was committed**, so they were never in git at all |
| PR #1032's comments, review comments and reviews | none exist |
| a targeted web search for the four reels | reels about those landmarks exist, but **none by `@welldonestuff`** |

🔴 **So the links only ever existed in the session that built the batch.**
That PR was opened by **`@arthuryung-gif`**, not the owner — they pasted the
original list, and are the likeliest person to still have the four links.

## What is needed

**Send the four Instagram reel links** (or ask `@arthuryung-gif`, whose batch this was) (Calgary Central Library, Guangzhou
Circle, Huajiang Grand Canyon Bridge, Three Gorges Dam) and a follow-up PR
will pin all four alongside the existing entries — which will also make each
of the four a two-entry **place candidate**, since the pairs sit on one point.

Clear with: `git rm status/owner/link-pin-batch-1032-duplicates.md`
