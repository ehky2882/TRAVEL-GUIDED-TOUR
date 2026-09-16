# Noted: a local session must delete claude/scale-pinned-tours-automation-dba3lx (remote sessions get 403)

_2026-09-16 14:05 UTC · branch `note-delete-abandoned-branch-260`_

`#945` rescued the two files worth keeping from
`claude/scale-pinned-tours-automation-dba3lx`. Deleting the branch is the step
that actually removes the hazard — it carries a **second migration for work
already applied to production** — and **a remote/web session cannot do it**:
`git push origin --delete` and the GitHub API both return **403**. Push and merge
work from here; ref deletion does not.

Recorded as `status/owner/delete-abandoned-scale-branch.md` so it reaches a
session that can. **One command, no judgement required.**

⚠️ Worth knowing generally: CLAUDE.md automation rule 6 ("delete stale merged
`claude/*` branches, no prompting") **cannot be honoured from a remote session at
all.** Every such branch will keep accumulating until a local session runs the
deletions. That is a standing gap in the rule, not a one-off.
