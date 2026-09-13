# Account deletion: owner decided unpublish-and-retain, buyers keep access

_2026-09-13 01:21 UTC · branch `status-delete-decision`_

Owner, 2026-09-13: *"unpublish and retain, buyers keep access."*

**Mechanically this is already supported.** `backend/schema.sql:40` defines
`tour_status as enum ('draft','in_review','published','taken_down')`; the tour RLS
policy is `for select using (status = 'published')` and the catalogue builder
filters `where t.status = 'published'` explicitly. So setting a tour to
`taken_down` removes it from the app and the catalogue without destroying it, and
`purchases` rows are untouched — a buyer keeps access.

The three `on delete restrict` constraints that forced this question
(`purchases.tour_id`, `purchases.maker_id`, `tours.maker_id`) are all satisfied by
retaining rather than deleting, so the naive-delete failure mode disappears
entirely.

🔴 **One consequence needs the owner and is now a board item:** the published
privacy policy says creator content is *removed*, and unpublished-and-retained is
not removed. Either the wording or the behaviour has to move. Raised before the
build starts rather than after it ships.
