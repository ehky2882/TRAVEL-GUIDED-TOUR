# Atlas — Handoff Notes (2026-06-09, session 29)

Web/PM session — **London expansion**. Added **9 more London tours**
under Atlas Studio LDN (London 6 → 15). No Swift / asset / project
changes; no build bump. Catalog **155 → 164 tours / 173 stops / 4 makers**.

---

## What happened
- **9 London tours added**, all single-stop, geofenced, owner-narrated,
  under Atlas Studio LDN (`9c40396a-74ed-49d2-9796-a41edb9e4105`):

  | Tour | Category | Dur | Hero source | Gallery |
  |------|----------|-----|-------------|---------|
  | Lloyd's of London | architecture | 139s | Unsplash | 3 (Unsplash) |
  | Bank Junction | history | 144s | Unsplash | 4 (Unsplash) |
  | St Stephen Walbrook | sacredSites | 132s | owner-pasted exterior | dome+altar+organ (CC0) |
  | St Bartholomew the Great | sacredSites | 142s | owner-pasted exterior | 1 (CC0 B&W nave) |
  | Smithfield Market | culturalHeritage | 144s | owner-pasted (Grand Ave) | CC0 exterior + owner interior |
  | Postman's Park | hiddenGems | 141s | owner-pasted loggia | 1 (owner park) |
  | The Barbican | architecture | 145s | Unsplash | 5 (Unsplash) |
  | Guildhall | history | 149s | owner-pasted exterior | 1 (owner Great Hall) |
  | Temple Church | sacredSites | 154s | owner-pasted exterior | 1 (owner interior) |

- **Merged to `main`:** PR #185 (Lloyd's, separate) + **PR #186**
  (the other 8 as one consolidated PR). All CI green (validate + iOS
  build + unit tests). gh-pages carries every audio + image; all live-URL
  spot-checked 200. Validator clean at every step.

## Key lessons (codified in CLAUDE.md)
1. **CC0-only is thin for interior-famous City churches/sites.** Unsplash
   returns *other* churches (St Paul's, Salisbury, random parish churches);
   Wikimedia's modern interiors/exteriors are CC BY-SA (excluded by the
   no-attribution-UI policy). Only historical engravings are CC0. So for
   St Stephen Walbrook, St Bartholomew, Smithfield, Postman's Park,
   Guildhall, Temple Church → the **owner supplied images**.
2. **Owner-pasted images live in the transcript, not the uploads dir.**
   When an image is pasted inline (not attached as a file) it is NOT in
   `/root/.claude/uploads/`. It is base64 in
   `/root/.claude/projects/-home-user-TRAVEL-GUIDED-TOUR/<session>.jsonl`
   as `{"type":"image","source":{"type":"base64",...}}`. Decode the last
   N image blocks with Pillow → crop → upload. This unblocked every
   owner-supplied hero/interior this session.
3. **EXIF orientation:** apply `ImageOps.exif_transpose()` and DON'T add a
   manual rotate — several crops were double-rotated until caught.
4. **Batch workflow:** accumulate tours on the session branch (one commit
   each; force-push as you go since the branch sits on a squash-merged
   base), then ONE PR → ONE CI → ONE merge. Much less idle CI time than a
   PR per tour. (Lloyd's #185 was already open when the batch started, so
   it merged on its own first.)
5. **Slow CI:** the iOS-simulator "Prepare" step occasionally takes ~5 min,
   pushing the unit-test job to ~13 min wall-clock; the MCP `get_check_runs`
   read also lags. Confirm true status with `actions_get get_workflow_job`
   before deciding a job is stuck.

## State at session end
- **Catalog: 4 makers / 164 tours / 173 stops** (96 NYC + 37 OPO + 5 LIS +
  15 LDN). All on `main`.
- **No build bump.** Latest TestFlight **1.0 (37)** (ships the first 6
  London tours). These 9 are on `main` but not yet in a build.

## How to resume / open items
1. Session-start ritual + read this file.
2. **Next TestFlight cut: bump 37 → 38** to ship these 9 London tours
   (plus Lloyd's). Owner does the archive/upload from a local session.
3. Carried code follow-ups (unchanged): on-device M-qa incl. multi-stop;
   design/polish pass (Theme tokens placeholder); `MKMapItem.placemark`
   deprecation warning; Player drag/volume device pass.
4. Possible future: a couple of tours ship with a single gallery image
   (St Bartholomew, Postman's Park, Guildhall, Temple Church) — owner can
   paste more gallery shots anytime to enrich them.
