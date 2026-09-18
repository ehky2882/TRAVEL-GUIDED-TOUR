# Handoff — 2026-09-18 · places create themselves now

**Merged:** [#993](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/993) (23 places, gazetteer)
· [#995](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/995) (14 places, proof tier + the spec)

**37 places auto-created**, from a system that had never created one without the owner approving
it individually. Places **351 → 388**.

The owner's instruction was short: *"I want to implement this feature"*, then *"I want a more
robust all-inclusive system"*. Both were answered in one day.

---

## What the mechanism is

🔴 **Not a looser proximity rule.** `docs/places.md` records a 40 m proximity rule being measured
and **rejected** — 43 places of which **19 were wrong**, merging LACMA with the Academy Museum and
chaining three La Boca venues into one site. Nothing here relaxes that.

Two signals, each carrying its own honest coordinate. Both live in `scripts/make-places.py`.

| | Test | Covers | Yield |
|---|---|---|---|
| **A · proof** | coincident (≤25 m) **plus** an independent same-venue signal | **venues, restaurants, food** | 14 |
| **B · gazetteer** | Wikidata resolves both entries to one item, both within 120 m of it | landmarks | 23 |

**A's proof is `check-place-candidates.proven_same_venue`, reused unchanged**: an identical name, a
shared venue `@handle` (the creator's own excluded — otherwise every pin by one food reviewer would
pair), or one entry's name written out in another's caption.

🔴 **Neither signal subsumes the other**, and this is the whole argument for having both. Grace
Farms' pin sat **6.1 km** from Grace Farms, so no coordinate test could ever group it. Kossar's is
**in no gazetteer at all**, so no name lookup could.

## 🔴 The owner found the gap twice, in under an hour each time

**First:** #993 shipped and was described as "the feature". It covered **landmarks only**. The
coverage numbers were already measured and in hand — 86% for Atlas Studio LDN against **1% for
`@japanbyfood`** — and the limitation was still not stated. The owner found **Kossar's** and **Una
Pizza Napoletana** immediately, both already sitting in `check-place-candidates.py`'s output. **The
tool that covered venues was in the repo the whole time, minting nothing.**

**Second:** the fix's first version still missed Una Pizza, for a reason no amount of reasoning had
surfaced — see below.

**Both finds came from the owner's examples, not from analysis.** The measured numbers were not
enough; two named restaurants were.

## Two design errors, both found by real data

1. **Exact coordinate equality is the wrong bucket.** Kossar's sits **0.0 m** from its caption pin
   *by distance*, but the two coordinates differ below a centimetre — so bucketing on rounded
   equality filed them separately. Una Pizza is **12.4 m** away, which equality could never reach.
   Now clustered by distance at the repo's existing reviewed 25 m threshold.

2. 🔴 **Proof must DRIVE the grouping, not follow it.** Clustering by distance first let an
   arbitrary anchor decide everything: **Saigon Social** — a different restaurant — absorbed **Una
   Pizza Napoletana** 23.8 m away, that pair correctly failed proof, and **Una Pizza was consumed**,
   so its true partner 12.4 m off never formed a group. *A wrong anchor silently destroyed a right
   answer.* Testing pairs first and unioning the proven ones cannot do that.

⚠️ **The radius is not the proof, and the margin is thinner than it looks.** The nearest
owner-declined part-vs-whole case sits **6.9 m apart — inside the 25 m radius.** What keeps it out
is `proven_same_venue` and the declined record, never the distance.

## 🔴 The most important finding is not the feature

In #993 the declined-pairing guard **failed on its first run** — *Bar Luce at Fondazione Prada* +
*Fondazione Prada*, declined under Rule 4, *a tenant is not the site*.

**The guard was sound. The DATA was missing.** That decision and **eight others existed only as
prose in `docs/places.md`** and had never been written into `make-place-menu.py`'s machine-readable
record. **Every tool that read the record rather than the document believed nine owner decisions
were still open.** All nine are now in it, keyed by exact catalogue title.

⚠️ A gazetteer cannot know Bar Luce is a café *inside* the foundation; it resolves both to the
foundation and is correct on its own terms. **Auto-creation is only as safe as the declined record
is complete** — and a signal that fires more often makes an incomplete record *more* dangerous, not
less. Re-read `docs/places.md` against that record before widening anything.

## Signal C is a finding, not a gap

Same name, different points — Domino Park's pair 201 m apart, Asakusa's 662 m. **It cannot be
automated**: A's members are already on one point and B's point comes from the gazetteer, but C
carries no coordinate at all and nothing in it says which of the two is right. `docs/places.md`:
*"If you cannot name the single point, it is not a place."* Automating it would mean **inventing a
coordinate**, which is the one thing this system exists to prevent. It stays a proposal tier.

## A bug caught before it shipped

#993's first apply **sorted the `places` array** "for tidiness", turning a 23-place addition into
**4,048 insertions / 3,701 deletions across 1,570 coordinate lines** — unreviewable, and
indistinguishable from a change that had moved content it should not have. Reverted, cause fixed,
re-applied to 23 new blocks. **New places are appended; the comment in `apply()` says why.**

⚠️ **Read the diff shape after every apply.** N places should mean N new `tourIds` blocks and at
most two coordinate lines per member.

## Verification

36/36 selftests · **8/8 mutations caught** on signal A, 10/10 on signal B.

🔴 **Between the two changes, nine guards were initially unable to fail** — the declined-group
check, the declined-entry check, the two-member minimum (twice, and the second time because it is
checked in two places so breaking one is *masked* by the other), the CONFIRMS gate, the distance
bound, the shortest-name choice, the cross-signal claim guard, and a fixture where `reverse()`
happened to equal `sort()`. **Every one read as an ordinary green check.** Mutation testing is the
only thing that found them.

## What is still open

| | |
|---|---|
| **1.1.3** | Not submitted. Carries the delta client, device-verified on build 161. Owner's call |
| Signal C | Proposal tier by design. ~14 NAME pairs waiting on an owner-chosen anchor |
| EXACT · ASK | Coincident groups with no second signal — reported, never minted |
| Part-vs-whole | Still explicitly undecided; goes to the owner case by case |
| The 86 spine DISAGREES | Not a worklist — five sampled, none a catalogue error |
| CI | Reports candidates; **deliberately never mints** |
