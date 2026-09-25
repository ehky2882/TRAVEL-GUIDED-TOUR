# Handoff 2026-09-25: 51 link pins from @where.to.taste (+1 @chloecotter)

Follows `HANDOFF-260925-six-creator-batch.md`.

## What happened
A contributor pasted 66 Instagram links (63 unique). Triage first; the contributor then
said "mint all, pin #37 to Búzio, skip the ads".

| | |
|---|---|
| minted | **51** — Instagram @where.to.taste 50 (Lisbon-area food, plus Valencia, Amsterdam, Hasselt), Instagram @chloecotter 1 (Libreria Acqua Alta, Venice) |
| held | **6** — embed disabled by the creator; the only cover Instagram serves has a play button baked in. Listed with URLs and coordinates below and in `status/owner/where-to-taste-held-260925.md` |
| skipped | **6** — 4 advertising (Portugália "pub", Revithia "AD", 2 Odisseias voucher posts), Vibe (closed March 2026), a Cape Town post that names no restaurant |
| new creators | Instagram @where.to.taste, Instagram @chloecotter (emoji avatars — Instagram exposes none) |
| heroes | 51 on gh-pages in one plumbing commit `3af6920` (51 A, nothing else) |

## How the locations were settled
- Addresses are the caption's 📍 line where it had one; otherwise found by searching the
  venue's Instagram tag: The Capsule (R. do Crucifixo 71), Palms (Tv. dos Mastros 25),
  Brant (Cais das Naus 4C, Parque das Nações — it has a second branch on Av. de Roma; the
  original was chosen), Portugália Belém, IRU, Voltereta Manhattan.
- `@srtacorestaurantemexicano` is **Sr. Taco** (Carnaxide), not "Señorita Cor" — "loja 1b"
  matches its address.
- Cover frames settled three: **O Caneira** (Negrais — logo on the plate), **Voltereta
  Manhattan** (caption said only "Voltereta"), **D'Olival** (sign in shot).
- **Street-level, not door-level (tens of metres):** Intemporal, Tasca do Isaías, Mamma Rua,
  Izakaya, Sr. Taco, Solta, Quest, Broto, Palms, Noisy Voices, Familjen, D'Olival,
  Café do Paço, IRU. OSM carries no house numbers on these streets; all are short except
  Av. Casal Ribeiro (Noisy Voices).
- 2Monkeys sits on the Torel Palace node (R. Câmara Pestana 23; the caption says 45).

## Tool change: `make-link-pin.py` reads embed-disabled Instagram posts
6 of the 63 returned `EmbedBrokenMedia` — the creator has switched embedding off — and the
tool refused them. It now falls back to the post page's Open Graph tags (served to
link-preview crawlers). 🔴 **That cover carries a baked-in play button and is 360x640**; the
URL is signed, so no clean variant can be requested. The fallback says so in the WILL NOT
PLAY INLINE report. Selftest 74 → 78.

## The 6 held pins (coordinates ready)
| URL | Title | lat,lon | city |
|---|---|---|---|
| https://www.instagram.com/reel/DLFuTELsisO/ | Búzio | 38.826204,-9.468798 | Colares |
| https://www.instagram.com/reel/DJ8-TWFs_r1/ | Manteigaria Silva | 38.714160,-9.138706 | Lisbon |
| https://www.instagram.com/reel/DAvPGCDMvtq/ | The Kissaten | 38.725512,-9.147320 | Lisbon |
| https://www.instagram.com/reel/C7RzXXDMiQe/ | Parra | 38.708419,-9.154389 | Lisbon |
| https://www.instagram.com/reel/C1C1wXjM5VG/ | Rumours | 38.705806,-9.175569 | Lisbon |
| https://www.instagram.com/reel/CxYaTV_sTYt/ | MUSE | 38.645060,-9.237942 | Costa da Caparica |

## Decisions
- *A Taberna do Mar* and *A Mesa do CAM* merged with `--allow-unverifiable-title` — Portuguese
  "A" is the definite article; those are the real names (same precedent as *A Valenciana*).
- 20 of the 51 will not play inline (licensed music).

## Owed by Edward
- `status/owner/place-where-to-taste-260925.md` — Adega Mayor pin vs Atlas tour (59 m);
  A Mesa do CAM inside CAM (part vs whole).
- `status/owner/where-to-taste-held-260925.md` — the 6 held pins and 6 skipped posts.
