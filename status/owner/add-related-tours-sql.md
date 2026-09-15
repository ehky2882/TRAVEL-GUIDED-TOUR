# Paste backend/add_related_tours.sql — relatedTourIds + createdAt

_opened 2026-09-15 · clear with `git rm status/owner/add-related-tours-sql.md`_

Paste **`backend/add_related_tours.sql`** into the Supabase SQL Editor.

It adds two columns and two catalogue keys in one go: `relatedTourIds` (the
"More like this" section) and `createdAt` (which switches on four sort controls
that currently render and do nothing — Newest/Oldest on maker pages, and date
ordering on places and lists).

🔴 **Run it BEFORE [#915](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/915)
merges.** The catalogue seed now writes both columns inside one transaction with
`ON_ERROR_STOP=1`, so on a database that does not have them the whole seed
aborts and **every content merge stops reaching Supabase** until this is
pasted. It fails loudly (red CI), but it blocks all content.

Applying it early costs nothing: until a re-seed runs, both columns are NULL,
both keys come back as null, and the app behaves exactly as it does today.

Then verify against the live RPC — **not** against the editor's "Success. No
rows returned.", which a severed function prints too:

```bash
python3 scripts/check-catalog-keys.py
python3 scripts/check-catalog-contract.py
```

⚠️ `check-catalog-contract.py` is red until this is applied. That is correct —
`createdAt` was a documented permanent gap and is now genuinely owed.
