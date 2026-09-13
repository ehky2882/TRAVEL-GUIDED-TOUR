# Branch decisions answered: private-account wording rebuilt as #875 (build 159), transcript branch deleted, Paris/London scripts kept

_2026-09-13 20:40 UTC · branch `board-branch-decisions`_

The owner answered all three questions left by the branch cleanup, so `branch-decisions` is cleared.

| branch | owner's answer | done |
|---|---|---|
| `private-friend-account-33psch` (the app half) | **fix it** | ported unchanged onto current `main` as **#875**, and TestFlight **build 159** dispatched. The old branch stays until #875 merges |
| `transcript-square-floor` | **delete**: already implemented | deleted, and it now returns **404**. #558 (2026-08-20) already makes the transcript box fill the step, and the location map is square. The branch only changed the box's shape for the frame before measurement, which is not worth a build |
| `paris-scripts-260622`, `london-batch3-scripts-260616` | **keep** | untouched; they are the only copy of the source scripts |

Remote branches now: `main`, `gh-pages`, `amsterdam-handoff-preserve-hlhyp8` (Atlanta scripts), the two script branches, `private-friend-account-33psch`, `private-account-followers-copy` (#875) and `more-tours-a1xhw4` (+1, never audited; left alone).

⚠️ #875 leaves out the old branch's `backend/test-migrations.sh` fixture. CI does not run that script, and the fixture conflicts with the `catalog_snapshot` fixture added since.
