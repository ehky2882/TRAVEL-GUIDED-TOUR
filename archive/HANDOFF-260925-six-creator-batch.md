# Handoff 2026-09-25: 28 link pins from six creators

Follows `HANDOFF-260924-caption-addresses.md`.

## What happened
A contributor pasted 33 links (32 unique). Triage first, owner-of-batch approval second ("mint all, keep toile blanche").

| | |
|---|---|
| minted | **28** — matter.by.millie 1, shahaanabbasy 2, heyrosiedart 2 (1 TikTok, 1 Instagram), blessedarch 3, _seoullista 10, jamesinculture 10 |
| skipped | archimarathon Luce Chapel / Shenzhen Bay Cultural Plaza / Kunsthal (exact posts already live); urbanistariel NYPL (same creator already has *Inside the New York Public Library*) |
| new creators | Instagram @shahaanabbasy, Instagram @heyrosiedart, Instagram @_seoullista, TikTok @jamesinculture |
| heroes | 28 heroes + 1 avatar on gh-pages in one plumbing commit `1d3fb58` (29 A, nothing else). The TikTok @heyrosiedart avatar was regenerated but NOT uploaded — that maker already existed and its avatar is live |

## How the locations were settled
- **Landeau Chocolate**: caption says only "Lisbon"; the cover frame is Largo Camões, so the Rua das Flores 70 (Chiado) shop.
- **Cubitts**: the pie-and-mash shop is F. Cooke, 9 Broadway Market (Cubitts since 2023).
- **The Hangul Moment**: from the @thehangulmoment tag → 2F Milim Art, Insadong-gil 11-1.
- **Keith Haring bathroom**: caption wrongly says Leslie-Lohman Museum; pinned to The Center, 208 W 13th St.
- **Approximate (tens of metres):** Park Seo-Bo Museum sits on the neighbouring GIJI Foundation node (연희로24길 9-2; museum is 9-54); MoMA Bookstore (도산대로45길 18-10) on the no. 18 node next door.
- Seoul museums, Fondation Maeght, Millennium Bridge and the Waterloo Place Banksy reuse the existing entries' exact coordinates.

## Decisions
- **Toile Blanche** (a hotel the creator stayed in, likely hosted) — kept on the contributor's instruction; advertising policy is normally Edward's call, flagged here.
- `merge-link-pins.py` refused *A Valenciana* for starting with "A"; that is the restaurant's real name, merged with `--allow-unverifiable-title`.
- 9 pins given a Place type tag the validator asked for.

## Owed by Edward
`status/owner/place-batch-260925.md` — 9 place questions (4 Seoul pins vs Atlas SEL tours, Maeght + Millennium Bridge joins, MMCA Space Kids, Banksy, Gwacheon pair). Nothing created or joined.

Four Instagram pins will not play inline (licensed music): Park 'n' Play, Landeau, A Valenciana, The Little Theatre.
