# HANDOFF — 2026-08-16 (session 92, local — repo hygiene + PR triage)

**One-line summary:** No content and no app features — a full cleanup of the
repository and the working copy, plus triage of the PR backlog. **41 branches
deleted, 547 MB of unignored build output removed and permanently gitignored, a
2.5-month-old hidden stash cleared, 4 PRs merged and 2 closed as obsolete.**
`delete_branch_on_merge` is now **ON**, so merged branches clean themselves up
from here.

Branch: `claude/handoff-260816`. Catalog untouched at **1350 tours / 30 makers**.

## ⚠️ Behaviour change every future session must know

**`delete_branch_on_merge` is enabled on the repo** (set via
`gh api -X PATCH repos/… -f delete_branch_on_merge=true`, confirmed reading it
back). When your PR merges, **GitHub deletes your branch automatically**. That
is intentional, not a fault or someone else's cleanup racing you.

Two consequences seen the same session:

- The local checkout can end up **sitting on a branch that no longer exists on
  the remote** (it was on `claude/paid-tours-price-badges` after #498 merged).
  Harmless, but move back to `main`.
- **Auto-delete does not fire for a reused branch.** Three branches survived
  because more than one PR had been opened from them
  (`claude/pricing-doc-refresh` carried both #500 and #502;
  `claude/tours-upload-media-9x7h4q` carried #499 then #501). Branch reuse is
  common here — expect to sweep those by hand.

## 🐛 The find that mattered: 547 MB one `git add -A` from permanent history

The primary checkout held **20,640 untracked files** — `web/node_modules`
(453 MB) and `web/.next` (94 MB) from the Next.js landing-site work — and
**`.gitignore` covered neither**. Sessions routinely stage with `git add -A`
(this one did, in a worktree, an hour earlier). One of those in the primary
checkout would have committed half a gigabyte of regenerable dependencies into
history permanently: every clone and CI run slower forever, and painful to
excise afterwards.

Confirmed it never happened — `git rev-list --objects --all | grep node_modules`
returns **0 objects across all refs**. Caught before, not after.

Fixed at both layers:

- **[PR #506](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/506)** ignores
  `web/node_modules/`, `web/.next/`, `web/out/`, `web/next-env.d.ts`,
  `web/*.tsbuildinfo`, plus bare `node_modules/` and `.next/` for any future JS
  project.
- Deleted from disk — `web/` went **547 MB → 4 KB**, and `git add -A` now stages
  **1 file** instead of 20,640.

**Verified safe before deleting**, in this order: no dev server or node process
was running; the artifacts had not been touched since **2026-07-24** (three
weeks); and the entire landing-site source — `app/`, `components/`, **and
`package.json` + `package-lock.json`** — is preserved on
`claude/web-landing-site-preserve` (36 files). The local `node_modules` was an
orphan: its own source was not even in the working tree. One `npm install`
regenerates it.

**Worth knowing separately:** that branch holds a **complete Next.js marketing
site** (Hero, Features, HowItWorks, GeofenceDemo, Stats, CTA, PhoneFrame,
ScrollProgress, Waveform) — built, unmerged, and never mentioned in Current
State. Relevant to the App Store push.

## The hidden stash — why `git stash list` is not enough

A stash from **2026-05-29 12:32** had sat unnoticed for 2.5 months.
`git stash show --stat` showed **nothing**, which reads as "empty" — but that
command **hides the untracked-files component**. The real contents were in
`stash@{0}^3`: `.DS_Store`, an Xcode `.xcuserstate`, and a **670-line
`TourDetailView.swift`**.

Checked before dropping, and the file was **not** in history — so "unique
content", which sounds alarming. It was not:

- vs the commit made the **same day** (`cba0755b` "masthead + toolbar +
  overflow"): the stash is the **older** state, missing 132 lines that commit
  added.
- vs current `main`: the file is now **1,646 lines** — the stash is missing
  **1,231** of them.

So: an unfinished draft superseded within hours, of a file that has since nearly
tripled. Restoring it would have deleted ~2.5 months of work. Backed up to
`~/Desktop/dozent-stash-backup-2026-05-29/` (with a README saying not to restore
it), then dropped.

**Lesson:** to audit a stash, use `git rev-parse stash@{0}^3` and
`git show stash@{0}^3` — `git stash show` alone will tell you an untracked-only
stash is empty.

## PR triage

**Merged (4):**

- **[#493](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/493)** — 39
  architects added to the vocabulary (38 → 77), 95 tours tagged; tours naming an
  architect 134 → 210. **Oscar Niemeyer was the most-represented architect in
  the catalog — 11 tours across 3 cities — with no tag at all.** Its editorial
  restraint is the part worth remembering: **Louis Sullivan rejected entirely**
  (named in three Chicago tours, designed none — he is quoted describing other
  people's buildings), **Eiffel tagged on 2 of 5** (the other three narrations
  say explicitly he did *not* design them). A mention is not authorship.
- **[#502](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/502)** — the
  pricing correction (see below).
- **[#503](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/503)** —
  TestFlight export: signing flags were passed twice.
- **[#498](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/498)** — price
  badges on browse surfaces. Reviewed specifically for the pricing-model trap
  and it is **clean**: the maker-grid `HStack` gates `walkPill` and
  `TourPriceBadge` **independently**, so a paid single-stop tour renders the
  price alone. The "every paid tour today is a walk" comment explains the
  layout choice; it is not a dependency.

**Closed as obsolete (2):**

- **[#501](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/501)** — "44
  named-architect tours missing `Designed by a Master`". Opened **01:40**; #493
  merged **01:43** and had already fixed exactly those tours. Verified two ways
  against `main`: a full scan found **0** architect-tagged tours missing the
  label, and the five tours its own description named (Louvre, Pompidou, Casa da
  Música, Park Avenue Armory, MAAT) all carry both tags. Evidence posted on the
  PR so the finding is not re-derived from stale data. (#505 is that session
  documenting the same conclusion.)
- **[#504](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/504)** — this
  session's own pricing-correction PR, closed as a duplicate of #502, which was
  opened 3 minutes earlier and is the better version. **Process note: check for
  an existing PR on a topic before writing one** — with this many parallel
  sessions, two agents corrected the same paragraph within minutes, on the same
  two files, which would have conflicted.

## Pricing is per-maker — the correction #500 needed

#500 landed the uniform walk price as **"The rule is exactly one sentence: walks
cost $0.99, everything else is free. One sentence, no exceptions."** That
mischaracterises the product. Owner, 2026-08-16:

> *"that's not a rule. remember, each individual maker sets their own price. i
> know i dont have any app users yet so for simplicity sake and for testing's
> sake i'm just making all my mult-stop tours .99$."*

**Pricing is per-tour, set by the maker who owns it.** The live data looks
uniform only because the owner is currently the sole maker with published
content. #502 reframes both `CLAUDE.md` and `backend/README.md` as an observed
snapshot and adds the guard this session did not think of:

> **Do NOT "restore consistency"** if you find a walk at NULL or a single-stop
> tour with a price. That may be a deliberate maker choice. **Ask.**

## Branch inventory after the sweep

**41 deleted** — 32 remote (9 tracker/docs branches verified against their
squash commits, then 20 more, then 3 reuse-survivors) and 9 local-only
leftovers (`drop-ipad`, `fastlane-launch`, `fix-ipad-sim`, `fix-ruby-version`,
`fix-sim-names`, `fix-testflight-duplicate-signing-args`, `launch-website-web`,
`screenshot-quality`, `video-hero-shinsegae`).

**Every deletion was verified first**, never on assurance: the PR had to read
`MERGED` *and* its squash commit had to be present in `origin/main`
(`git log origin/main --grep="(#N)"`). Note that `git branch --merged` will
**not** list a squash-merged branch and `git branch -d` refuses it — that is
expected, not evidence of unmerged work. Deletion goes through
`gh api -X DELETE repos/…/git/refs/heads/<branch>`; a plain
`git push origin --delete` is blocked by this environment's proxy.

**7 remote `claude/*` remain. Four are protected — do not delete these whatever
`git branch --merged` says:**

| Branch | Why it stays |
|---|---|
| `claude/amsterdam-handoff-preserve-hlhyp8` | every narration script for the staged cities |
| `claude/london-batch3-scripts-260616` | staged batch, unmerged |
| `claude/dreamy-wozniak-tags-260612` | tag proposal, unmerged |
| `claude/paris-scripts-260622` | status never verified |
| `claude/web-landing-site-preserve` | the complete Next.js landing site (above) |

The other two back live sessions and will auto-delete on merge.

## Final state

| | |
|---|---|
| Stashes | 0 |
| Worktrees | 1 (`main` only) |
| Local branches | 4 — `main`, `gh-pages`, amsterdam-preserve, one live session's |
| Remote `claude/*` | 7 |
| Open PRs | 1 (#505, docs) |
| `main` | 0 ahead / 0 behind, CI green |
| Uncommitted | 1 — `.xcodebuildmcp/config.yaml`, another session's local tool setting |
| `git add -A` stages | 1 file (was 20,640) |
| `node_modules` in history | 0 objects, ever |

**Three-way catalog sync verified — the check that actually matters:**
`main/Tours.json` **1350** = gh-pages mirror **1350** = Supabase `get_catalog`
**1350**. Drift here is what caused the 272-vs-300 incident and the poisoned
build 47; all three agree.

**Not done, deliberately:** `.git` is **4.17 GB across 34 pack files** — mostly
legitimate (gh-pages carries every tour's audio and images), but unconsolidated,
and today's 41 deletions may have freed reclaimable objects. `git gc` is safe
but takes minutes and locks the checkout, and **four sessions were live on this
Mac**. Left for a quiet moment.

## Next

Owner is **pre-submission** on the App Store — nothing submitted yet, though the
whole release path exists (fastlane lanes, screenshots, metadata,
`docs/launch-runbook.md`). **Apple's side is now clear: the App Store Small
Business Program approval landed 2026-08-16 (15% not 30%), which the paid-tours
design had already assumed** — so no revenue-split rework. The remaining payout
gates are the owner's **Stripe live activation** and the **LLC vs sole
proprietor** decision. TestFlight is at **1.1 (57)**.
