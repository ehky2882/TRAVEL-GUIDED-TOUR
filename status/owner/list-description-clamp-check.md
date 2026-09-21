# Check the list-description clamp when convenient (deferred)

_opened 2026-09-21 · clear with `git rm status/owner/list-description-clamp-check.md`_

# Check the list-description clamp when convenient

`ExpandableText` (#1051) replaced a character-count guess with a real
measurement in **four** places. Three were confirmed on device:

| surface | |
|---|---|
| stop captions | ✅ Plateau walk |
| tour descriptions | ✅ |
| place pages | ✅ |
| **list descriptions** | ⏸ **deferred — not yet looked at** |

It is the same component and the same code path as the three that pass, so the
risk is low. It was deferred only because **there is no seeded example** — list
descriptions are user-authored, so checking it means creating one.

**When convenient:**
1. Library → create a list, give it a name
2. Paste a long paragraph as its description
3. Open the list — it should clamp to **four lines with "Read more"**
4. Edit it down to one short sentence — the link should **disappear**

🔴 The thing to watch is the same everywhere: **text clamped with NO link to
open it**. That was the original bug, and it hides content with no way to reach
it.

Clear this with `git rm status/owner/list-description-clamp-check.md`.
