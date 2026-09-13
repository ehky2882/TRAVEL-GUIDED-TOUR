# Closed two of my own PRs: one carried a premise that was wrong

_2026-09-13 18:09 UTC · branch `filtered-view-lesson`_

**#853 shipped in-app account deletion** while this session was away, and it
**corrected a claim I had made to the owner.**

I said `taken_down` would keep buyers' access — *"by default rather than by
special-casing"*. It would not. The catalogue builder and the tours RLS both
filter `status = 'published'`, and a purchaser reaches tour content through that
same path, so an intact `purchases` row points at something invisible. I quoted
that RLS filter in the PR and did not follow it through.

What shipped instead, after the owner decided again: **unsold tours deleted with
their files; sold tours stay published, credited to "Former creator."**

**Closed:** #850 (wrong premise, explained in a comment) and #848 (its question is
answered). **Merged:** #862, another session's handoff, docs-only and clean, idle
since 15:59.

🔴 **Recorded in `docs/lessons.md` § 7, because it had only reached a handoff** —
and because it was the **second instance the same day** of the same mistake:
reading through a filtered view and drawing a conclusion about the unfiltered
world. The first was counting tours per maker through the anon published-only
view and reporting 27 accounts as empty.
