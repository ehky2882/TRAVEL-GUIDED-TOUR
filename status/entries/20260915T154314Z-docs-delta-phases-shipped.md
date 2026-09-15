# Docs: the delta work is built — two files said it was not

_2026-09-15 15:43 UTC · branch `docs-delta-phases-shipped`_

Two files on `main` asserted that delta fetching "is not built". It has been built since #912
merged and the owner pasted `backend/catalog_since.sql`; `get_catalog_since` answers on
production. Corrected **in place**, not appended.

| file | was | now |
|---|---|---|
| `docs/delta-catalog-fetch-design.md` | *"Status: SCOPE AND DESIGN ONLY. Nothing here is built."* | a four-row phase table: 0 and 1 shipped, 2 built (#914), **3 not built** |
| `CLAUDE.md` § Egress | *"Delta or city-scoped fetching is the remaining step, and is not built."* | the server half is live, the client half is #914, **and nothing reaches a phone until 1.1.3** |

🔴 **Why this is not bookkeeping.** § READ FIRST opens with *"NEVER REPORT PERISHABLE STATE FROM
A DOCUMENT"*, and records four sessions in a row repeating one stale line to the owner. A doc
saying "nothing is built" is exactly the shape that costs a later session a day of re-planning
work that already exists.

⚠️ **Deliberately NOT claimed as solved.** Every build in the field still downloads the whole
catalogue; the egress arithmetic in that section is still what is being paid today. Both edits
say so explicitly, and both tell the reader to re-derive rather than quote — a
`get_catalog_since` call with a sentinel cursor costs **131 bytes** and answers "is it live?"
(404 if not).

⚠️ The hardcoded **"1,552 tours"** was dropped rather than updated. The file's own rule is
re-derive, never quote; the real figure is 3,901 rows (1,583 non-link + 2,318 `kind='link'`,
re-derived twice this session from `content-range`, 47 bytes each time).

⚠️ `CLAUDE.md` § Key facts deliberately **untouched** — no count moved today. #917 and #918
corrected coordinates and added nothing.
