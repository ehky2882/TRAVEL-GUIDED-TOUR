# The branch I never checked held an owner decision that never reached main

_2026-09-13 19:56 UTC · branch `recover-hero-decision`_

🔴 **I reported an audit of nine branches and had only really done eight.**
`claude/more-tours-a1xhw4` was listed and never ruled on. The cleanup session
correctly left it alone rather than assuming — which is the only reason this was
still recoverable.

**Checked now, and it was not obsolete.** Its single commit carries two things
that never reached `main`:

1. **An owner decision, 2026-09-03: *"keep both A"*** — the In's Point and Hong
   Kong Railway Museum heroes stay as shipped. The branch's own text warns that
   **anyone re-running the open-every-hero audit will flag both again**, citing the
   Ministry of Enterprise / Casa Lleó Morera / Rednaxela Terrace precedent. With it
   unmerged, that re-raise was guaranteed.
2. **A durable lesson the repo had already paid for once** — *any keep-or-pull
   question about a picture leads with the picture.* The question was put in prose
   and got *"i dont understand, more clearly pls"*; two labelled A/B images settled
   it in one exchange. **Second occurrence** — session 138 hit it on the
   `@notbadgalriri__` hero and wrote the rule down, and it was repeated anyway.

**Recovered:** the closure section restored to `archive/HANDOFF-260902-11.md` (the
file was on `main`, the section was not), and the lesson into `docs/lessons.md`
§ 10, which is where durable lessons live rather than a handoff nobody opens.

**The branch can now be deleted** — nothing unique remains on it.
