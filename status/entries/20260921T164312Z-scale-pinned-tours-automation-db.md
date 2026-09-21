# Captions kept whole; clamp moves to the display site (owner decision)

_2026-09-21 16:43 UTC · branch `scale-pinned-tours-automation-db`_

**Captions are kept WHOLE; the clamp moves to the display site.** Owner decision
on `caption-truncation-140`, taken 2026-09-21.

- `make-link-pin.py:621` was `caption[:140]`. It destroyed **2,375 of 5,463
  captions, 2,320 mid-word** — and creators put the address LAST, so the cut
  landed on the most useful line. *Modern Coffee House* shipped **22.9 km
  wrong** because the postcode separating two East Broadways was in the tail.
- New `Components/ExpandableText.swift` clamps to 3 lines with *Read more*,
  wired into `TourDetailView` and `PlayerView` — the only two places a stop
  caption renders. Reuses the character-count proxy already documented in
  `TourDetailView.shouldShowReadMoreToggle` rather than a measurement
  round-trip, for the reason recorded there.
- The pipeline selftest now asserts the **opposite** of what it did, and the
  assertion is live: restoring the cut turns it red (74/74 → 1/74).

⚠️ **Two things the owner must weigh, both stated in the PR:**
1. **Builds in the field render captions with NO line limit.** Until 1.1.4 ships,
   new pins with long captions show in full on every phone.
2. **Egress.** ~140 → ~400–600 chars across 3,540 pins is an estimated **+12%**
   on a 2.4 MB payload, against a project with two overage notices. 🔴 It is an
   ESTIMATE and cannot be measured yet — the old captions were destroyed, so the
   real figure only exists after the first batch lands with them intact.
   `get_catalog_since` (1.1.3) is the mitigation.

🔴 **Code PR — waits for owner OK + visual review. Does NOT auto-merge.**
