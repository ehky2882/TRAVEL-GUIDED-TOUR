# One command for a LOCAL session: delete an abandoned branch

_opened 2026-09-16 · clear with `git rm status/owner/delete-abandoned-scale-branch.md`_

**Not your job to run — hand it to a local (Mac) session, or any session that can
delete a remote branch.** A remote/web session cannot: `git push origin --delete`
and the GitHub API both return **403** there. Push and merge work; delete does not.

```
git push origin --delete claude/scale-pinned-tours-automation-dba3lx
```

## 🔴 Why this matters more than ordinary branch tidying

That branch is **abandoned unmerged** and carries **`backend/add_catalog_rev.sql` — a
SECOND migration doing the same job as `backend/catalog_rev.sql`, which is already
applied to production** — plus a `backend/catalog_since.sql` **126 lines different**
from the one live via #912.

If a future session tidies that branch up and opens a PR in good faith, **the owner
gets handed a duplicate SQL block to paste against a database that already has it.**
That is the specific harm; the branch sitting there is not otherwise urgent.

## Nothing is lost by deleting it

Everything on it worth keeping was rescued to `main` in **#945**:
`docs/scaling-to-100k-design.md` and `status/owner/auto-created-places.md`. Its
commits stay in git history either way.

## Why it was abandoned — its own author's words

It built Phase 0 of the delta design in parallel with #904 and later recorded that
its own commits *"duplicate it and should not be merged"*. It also filed, then
**retracted**, a claim that #904 crashed the seed on a stop reorder — the retraction
attributes the failure to that session's own fixture, not to `main`.

⚠️ **Do not merge any part of this branch.** If something on it looks valuable,
check `main` first — it is probably already there.
