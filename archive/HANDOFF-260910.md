# Handoff — 2026-09-10 (session 153, part 2)

**The Supabase egress emergency, and the catalogue payload cut that answers it.**
Continues `HANDOFF-260909-4.md` (the version check, PR #776 — still open, owner OK pending).

Two PRs: **[#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776)** (code, owner OK
pending, TestFlight build 142 uploaded) and **[#795](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/795)**
(SQL + tooling + docs — **the SQL has been applied and verified live**).

---

## What happened

A **second** Supabase notice arrived: **11.82 GB against a 5 GB allowance**, grace period cut from
4 October to **13 September**. The owner sent the usage dashboard, then a screen recording of the
per-day breakdown.

**The breakdown settles the cause completely, and killed two plausible theories:**

| | |
|---|---|
| **PostgREST** | **100.0% — every single day** |
| Auth | 28–64 KB/day |
| Storage | **977 bytes**/day |
| Edge Functions | does not appear at all |

- ⚠️ **238,583 Edge Function invocations looked alarming and produce essentially zero egress.**
  I raised them as suspicious in chat; that was a false alarm and I said so.
- ⚠️ **It is not the users. MAU is 17.**

Daily figures — the honest scoreboard for every fix here (allowance ≈ **167 MB/day**):

| 8 Sep | 9 Sep (#770 lands) | 10 Sep |
|---|---|---|
| **1,963 MB** | **493 MB** | **241 MB** |

---

## What shipped

**`stops.transcriptText` is off the wire.** 1,924 stops, 3,768,989 characters of narration script,
**displayed by no consumer screen at all** — grep-verified across the app, not assumed: the only
readers are `Models/Stop.swift` (the declaration), `MakerTourService`, `TourWizardRules` and
`CreateTourWizardView`, all maker-side, and `MakerTourService` queries the `stops` table directly
rather than the RPC. The column is untouched.

**Measured on the live wire, before and after:**

| | |
|---|---|
| before | 3,698,842 bytes |
| after | **2,163,115 bytes** |
| **saving** | **41.5%, every fetch, forever** |

It reaches phones **already in the field with no App Store release**, because
`Stop.transcriptText` is `String?` — an absent key decodes as nil on every build ever shipped.

⚠️ **`longDescription` was considered and deliberately KEPT.** Its "18%" in older notes was a
**raw** figure; gzipped — which is what is billed — it is **8.2%**, and unlike the transcripts it
*is* used (`TourDetailView` renders it, `SearchView` searches it).

---

## 🔴 The incident inside the fix — read this one

**The first version of the migration reverted the link-pin split.**

It rebuilt `get_catalog_core()` by copying the body out of `backend/restore_catalog_keys.sql` and
deleting one line. That body was superseded: `split_link_pins.sql` had renamed the builder aside to
`get_catalog_core_base()` and made `get_catalog_core()` the **wrapper** that lifts link pins into
their own `linkPins` key.

So the paste took the live catalogue from `tours 1553 / linkPins 1712` to
**`tours 3253 / linkPins 0`** — which fails the **whole** catalog decode on every build predating
`TourKind.link`, silently, because the loader reads a throw as a failed fetch and keeps its last
good copy. Live for roughly six minutes.

**Caught by counting the live payload immediately after the paste.** "Success. No rows returned."
said nothing.

**The rule it taught — now in `docs/lessons.md`:**
> **Transform what the live chain returns; never retype it.** Committed SQL records what was true
> when it was written, not what is live underneath it now. A wrapper cannot lose a key it never
> mentions.

The repaired migration does exactly that: it calls `get_catalog_core_base()` and applies
`- 'transcriptText'` to each stop on the way past, preserving stop order explicitly
(`with ordinality` + `order by` — that order is the walking route).

**Three durable guards came out of it:**

1. **The migration verifies its own shape.** It ends in a `do $$` block that raises if `linkPins`
   is empty, if a pin is still inside `tours`, if `places` is empty, or if any transcript survived.
2. **The audit was looking one layer too high.** `check-catalog-keys.py` inspected only
   `create or replace function public.get_catalog()`; the destructive statement was against
   `get_catalog_core()`, so the bad file **passed the audit that exists for exactly this**. It now
   audits both layers on the same rule — a body that CALLS the layer beneath it is a wrapper and is
   fine; a body that RETYPES it is a loaded gun.
3. **`restore_catalog_keys.sql` now carries the `NO LONGER SAFE TO RE-RUN` banner** it had always
   warranted, plus the stronger warning that it is not safe to **copy from** either — the mistake
   actually made.

Also added: **`FORBIDDEN_STOP`** in `check-catalog-keys.py`, which fails if `transcriptText` ever
returns to the payload. The damage runs that way — a key that comes back costs money on every fetch
by every phone forever, and nothing else would notice.

---

## Verified live after the owner's paste

- `check-catalog-keys.py` → **exit 0**, fresh RUN stamp, `1553 tours, 404 makers, 141 places`
- `check-catalog-contract.py` → **exit 0**, `PASS — every key the app decodes is being served`
  (one pre-existing known gap: `tours[].createdAt`)
- Direct count: tours **1553** / linkPins **1712** / places **141** / makers **404**;
  **0** strays, **0** transcripts, **0** tours with stops out of order, `longDescription` still served
- Wire bytes **2,163,115** (from 3,698,842)

---

## What is owed

| | |
|---|---|
| 🔴 **Upgrade to Supabase Pro before 13 Sep** | The 11.82 GB is already spent and cannot be un-spent. This fix governs the NEXT cycle. Advised repeatedly; owner's call |
| **Owner OK + device check on [#776](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/776)** | The version check. CI green, TestFlight **build 142** uploaded with notes |
| **Merge [#795](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/795)** | SQL/tooling/docs — auto-merge class once CI is green. **The SQL is already applied live** |
| Watch the daily egress bars | 11 Sep is the first full day carrying both the 9 Sep fixes and this cut. Expect well under 167 MB |

**Not built:** when anything changes, the app still downloads all 1,552 tours. Delta or
city-scoped fetching is the remaining step.

---

## Follow-up the same day — the China reachability question, actually measured

The owner asked whether `github.io` reachability from China could be checked "somehow". It can, from
here, with no mainland contact — and **the first tool that answered was wrong**, which is the whole
lesson.

### Method 1 — mainland DNS resolvers (AliDNS, Tencent DNSPod) over DoH

Both answer from inside China and both return the **correct** GitHub Pages IPs for
`ehky2882.github.io` (`185.199.108–111.153`), identical to a Google-DNS control. Same for
`dozent.world` and the Supabase host.

🔴 **And this proves nothing**, which is why the control matters: `www.tiktok.com` **also** resolves
cleanly from both, and TikTok is definitively unavailable in mainland China. Clean DNS rules out
**DNS poisoning only**; the GFW's usual HTTPS mechanism today is an SNI-triggered TCP reset, which
leaves DNS untouched. A resolver check that "passes" is not a reachability check.

### Method 2 — `chinafirewalltest.com` (5 mainland nodes, powered by ViewDNS)

| Host | Beijing · Shenzhen · Inner Mongolia · Heilongjiang · Yunnan |
|---|---|
| `www.tiktok.com` | BLOCKED ×5 — ✅ control passes |
| **`www.google.com`** | **OK ×5 — ❌ CONTROL FAILS** |
| `ehky2882.github.io` | OK ×5 |
| `apkcihljybvuyuzpbnqd.supabase.co` | OK ×5 |
| **`dozent.world`** | **BLOCKED ×5** |

Stable across re-runs. 🔴 **Because it calls Google reachable, its `OK` verdict is worthless** — the
tool is biased toward false-OK. That asymmetry is usable, though: a tool that under-reports blocking
saying **BLOCKED** is a *strong* signal, so `dozent.world` is the finding here, not `github.io`.

### Method 3 — OONI, real probes inside China (2026-03-01 → 2026-09-11)

| Domain | measurements | anomaly rate |
|---|---|---|
| `www.google.com` | 512 | **91%** |
| **`vercel.app`** | 47 | **100%** (0 OK) |
| `github.io` (bare apex only) | 38 | 47% |
| `github.com` | 1,701 | 36% |
| `raw.githubusercontent.com` | 421 | **14%** |
| `apps.apple.com` | 439 | 3% |
| **any real `*.github.io` Pages site** | **0** | — |
| `supabase.co` | 0 | — |

OONI is what disqualified method 2: 512 measurements at 91% anomaly is Google being blocked, exactly
as expected, against the checker's five green ticks.

### So: is `ehky2882.github.io` reachable from China?

**Still not proven, and it must not be written down as proven.** No OONI probe has ever tested a real
Pages subdomain from China; the 38 `github.io` measurements are the **bare apex**, which is a parking
page and not a Pages site at all.

The indirect evidence leans *"works, degraded"*: DNS is clean, and GitHub's other hosts are mostly
reachable — **`raw.githubusercontent.com` at 86% OK is the closest analogue we have**, being a static
asset host on shared infrastructure exactly like ours. Every `*.github.io` site shares the same four
anycast IPs, so blocking ours specifically would require someone to target our hostname by name,
which is implausible for an unknown travel app. Call it *probably fine, occasionally flaky, not
guaranteed* — and note the app already degrades correctly, because a downloaded tour reads its audio
and photographs off local disk.

### 🔴 The finding nobody went looking for: `dozent.world` looks unreachable from mainland China

Two **independent** sources agree, which neither did alone: the checker reports BLOCKED from all five
mainland nodes (and it under-reports blocking), and OONI puts **`vercel.app` at 100% anomaly over 47
measurements with zero OK**. `dozent.world` is served by Vercel (`64.29.17.65`).

This is worse than the link-pin problem in one respect: **it is our own surface, not a third party's.**

1. **`Theme/AtlasLegalLinks.swift`** — Privacy, Terms and Acceptable Use in Settings all point at
   `dozent.world`. In China they open nothing. The same three URLs are the App Store listing's
   support/privacy/marketing URLs (`fastlane/metadata/en-US/`).
2. 🔴 **`https://dozent.world/confirmed/` is where Supabase Auth lands someone after they tap the
   button in a signup email.** A user in mainland China would tap it, Supabase would verify the token
   server-side, and then redirect them to **a page that cannot load**. The account is most likely
   confirmed; the person has every reason to believe signup failed.

**Not fixed here, and it is a product decision rather than a bug with one obvious patch** — the
options (a mainland-reachable mirror of the legal pages, moving `/confirmed/` off Vercel, or
accepting it) trade against each other and were put to the owner rather than chosen.

### What none of this is

**Not a phone on a Chinese consumer network.** Every node above is a datacenter; China Mobile,
Unicom and Telecom mobile routing differ, and GFW behaviour varies by province, ISP and hour. These
are three independent remote measurements with their controls stated, not a device test.
