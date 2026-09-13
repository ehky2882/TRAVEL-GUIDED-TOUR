# The privacy policy says creator content is REMOVED; the decision is to retain it

_opened 2026-09-13 · clear with `git rm status/owner/privacy-policy-vs-retain.md`_

🔴 **Surfaced 2026-09-13 by the account-deletion decision, and it is a wording
problem rather than a build problem.**

**Your decision:** on account deletion, published tours are **unpublished and
retained**, and buyers keep access. Mechanically clean — `tour_status` already has
`taken_down`, and both RLS and the catalogue builder filter `status = 'published'`,
so the tour leaves the app without being destroyed and a purchaser's access
survives.

**But `site/privacy/index.html` currently says:** *"Delete your account and we
remove your profile, synced library **and creator content**; records we must keep
for legal or financial reasons are retained in minimal form."*

**Unpublished-and-retained is not removed.** If the feature ships as decided, that
sentence becomes inaccurate the day it does — a published privacy commitment that
does not match behaviour.

**Two ways to settle it, your call:**

1. **Change the policy wording** to say published tours are withdrawn from the app
   and retained so that people who bought them keep access — which is the honest
   description, and a reason a reader would accept.
2. **Change the behaviour** to actually delete tours where no purchase blocks it,
   and retain only those that were bought.

⚠️ **Also worth deciding, and easy to miss:** the maker row survives with
`user_id` set to null but **keeps its display name**, so a buyer opening a
purchased tour still sees the creator's chosen name. That is defensible as
attribution for something they paid for — but it does mean a name persists after
someone asked to be deleted. Say which you want.
