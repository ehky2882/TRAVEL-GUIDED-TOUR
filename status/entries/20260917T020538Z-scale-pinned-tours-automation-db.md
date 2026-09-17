# Session close: the handoff, five lessons, and the abandoned-branch hazard neutralised

_2026-09-17 02:05 UTC · branch `scale-pinned-tours-automation-db`_

Closes the record for a session that merged eight PRs (#934 #936 #941 #950 #952
#958 #971 #972) without a handoff — the last one merged, #931, stops at #930.

- `archive/HANDOFF-260917-places-and-deletion.md` + a one-line index row
- `docs/lessons.md` — five traps that were only in commit messages: a proxy is
  not the rule; a place candidate can be two WRONG names for one right place;
  the tour is usually the displaced one (13 of 15 groups, all precise and in the
  right city); an EXACT group reporting does not mean no place exists; a CDN
  resizer URL is not the image
- `ROADMAP.md` — Phase 3's server half shipped, client half not built

Also clears `status/owner/delete-abandoned-scale-branch.md`. The branch it names
is this session's own designated branch; its dangerous head (a SECOND migration
for a job already applied to production) has been replaced by resetting the
branch onto `main`, so the hazard it describes no longer exists. The branch
still exists — a web session gets 403 on `git push origin --delete` — but it now
points at `main`, so it is ordinary tidying rather than a trap.

§ Key facts re-derived and needed no change: 1,582 tours · 2,799 pins · 344
places · 472 makers · 1,954 tour stops · 619 cities · 69 countries.
