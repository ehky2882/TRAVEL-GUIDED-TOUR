# More like this + createdAt — PR #915 open, owner SQL owed

_2026-09-15 13:36 UTC · branch `open-source-ai-integration-pxuxd`_

[#915](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/915) — **open, needs
the owner's SQL paste first** (see `status/owner/add-related-tours-sql.md`) and a
device check.

Adds `relatedTourIds` to every tour and renders a **More Like This** section on
the tour detail page. Similarity is computed offline from sentence embeddings and
shipped in the catalogue as ids, so **the phone runs no model**. 1,580 of 1,582
tours get a neighbour; same city first, then cross-city fill (owner decision).

Bundles the `createdAt` fix — four sort controls have rendered and done nothing
on every real phone since #600/#601. 🔴 It is served from a **new nullable
`authored_on` column, never `created_at`**, which is an audit column holding seed
time.

⚠️ **36 tours stay undated and were deliberately not invented** — 35 are the
whole of Atlas Studio SFO, and this checkout is a shallow clone whose history
stops at 2026-08-17, so the dates are not recoverable here. They sort last.

Nothing compiled (Linux web session); CI is the `test_sim` stand-in.
