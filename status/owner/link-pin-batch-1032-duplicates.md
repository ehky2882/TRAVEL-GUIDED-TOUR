# Confirm: 4 engineering pins dropped as duplicates of existing catalog entries

_opened 2026-09-21 · clear with `git rm status/owner/link-pin-batch-1032-duplicates.md`_

PR #1032 (54 new link pins) intentionally left out 4 posts from @welldonestuff
that would have duplicated landmarks already pinned in the catalog from
earlier posts by the same creator, at the same coordinate (0 m apart per
`merge-link-pins.py --check`):

- Calgary Central Library
- Guangzhou Circle
- Huajiang Grand Canyon Bridge
- Three Gorges Dam

Each of the new posts is a different Instagram reel about the exact same
subject as an existing pin. Default action taken: skip the new post, keep the
existing pin — no second map marker at the same spot.

If you'd rather swap in the new post (e.g. better clip, more recent), or keep
both pins side by side despite the overlap, say so and a follow-up PR will
handle it. Otherwise no action needed — this is FYI only.

Clear with: git rm status/owner/link-pin-batch-1032-duplicates.md
