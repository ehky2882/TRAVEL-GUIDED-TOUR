# Handoff 2026-09-28: 26 link pins from nine creators

## What happened
A contributor pasted 44 links (40 unique; one reel appeared four times) from 11 creators and
asked for triage first. Every caption was read in full; ambiguous ones were settled by searching
the venue's name and by opening the cover frame. The contributor then ruled: **skip #41 and
#25–36, mint the rest, and pin same-site posts alongside the existing entries** (different
creators = a second take, per the owner's standing preference).

| | |
|---|---|
| minted | **26** — IG @historyskills 7 (Rome, Pompeii, Greece), IG @diegosomewhere 6 (Pompeii, Rome, Herculaneum, Naples, Teotihuacán, Querétaro), TikTok @chiara_in_italy 6 (Florence, Amalfi, Dolomites, Santa Marinella), IG @babatunde_roy 2, and one each from @flipdaddie, @jacobzander_, @reinesoleill, @thedesignssuite (Instagram — their TikTok is a separate maker), @scot.landbeauty |
| held for Edward | **2** — advertising question (`status/owner/held-ads-260928.md`) |
| skipped (contributor) | **13** — listed below with URLs |
| new creators | 9 · catalogue linkPins 3818 → 3844 · makers 537 → 546 · cities 799 → 808 |
| heroes | 27 files (26 heroes + @chiara_in_italy's avatar) on gh-pages in one plumbing commit `65629386`, 27 A |
| validator | 0 errors; only new warnings are Lago di Braies and Santa Marinella Beach with no Theme tag (no theme honestly fits a lake or a beach) |

## How the locations were settled
- Addresses from the web, searched by name: Il Giardino Mediterraneo (Via Nuova dei Conti 43,
  Ischia), Km.0 Praiano (Via G. Marconi 45), Pegna (Via dello Studio 26R, from the caption),
  Sennelier (3 Quai Voltaire, OSM shop node), Milano Fashion Library (Via I Maggio 13, Vanzago —
  supplied by the contributor). The first two and Vanzago are **street-level**, not door-level:
  OSM has no house numbers there.
- Cover frames settled: **V&A Dundee** (caption only "Dundee museum"; frame shows the Scottish
  Design Galleries sign) and **Talo, Hadano** (on-screen "📍 Hadano").
- 🔴 **Nominatim's "Chand Baori" is a village of that name ~250 km away** (24.94, 75.75). The
  stepwell is at Abhaneri, 27.007292, 76.606392 (Wikidata Q2273412). It was skipped with its
  creator, but the trap stands for the next session.
- `spine-match.py` shows Theatre of Epidaurus 528 m from Wikidata's match — that match is the
  whole *Sanctuary of Asclepius*; our point reverse-geocodes to OSM `historic=theatre`. Kept.
- Pompeii: the casts post sits on the Garden of the Fugitives, the post-AD-79 post on the Forum.
  Teotihuacán sits on the Pyramid of the Sun.

## Skipped by the contributor (URLs kept so it can be revisited)
| URL | creator | subject | why |
|---|---|---|---|
| https://www.instagram.com/reel/DR45fQzDGfl/ | IG @london | Hawksmoor Martini Bar, St Pancras (51.529333,-0.126115) | "Filmed in partnership with @LONDON & Hawksmoor" — paid |
| https://www.instagram.com/reel/Ddyj8TPCaBr/ | IG @omarcmysteries | Katskhi Pillar, Georgia | account tagged #AI — likely AI-generated |
| https://www.instagram.com/reel/Ddv_Ht1iIXV/ | 〃 | Cliff Palace, Mesa Verde | 〃 |
| https://www.instagram.com/reel/DdtacOcgbZa/ | 〃 | Moeraki Boulders, NZ | 〃 |
| https://www.instagram.com/reel/Ddq1lQ1j8X4/ | 〃 | Hanging Temple, Shanxi | 〃 |
| https://www.instagram.com/reel/DdoQsy_j_Lb/ | 〃 | Chand Baori, Abhaneri | 〃 |
| https://www.instagram.com/reel/Ddl56SzlOfv/ | 〃 | Spotted Lake, Osoyoos (existing: IG @pasttworld) | 〃 |
| https://www.instagram.com/reel/DdksIuGjgsf/ | 〃 | Montezuma Well, Arizona | 〃 |
| https://www.instagram.com/reel/DdkEIyBDB5p/ | 〃 | Giant's Causeway (existing: TikTok @travelih) | 〃 |
| https://www.instagram.com/reel/DdY1SeCCIBp/ | 〃 | Marble Caves, Chile | 〃 |
| https://www.instagram.com/reel/DdRGGONCi-u/ | 〃 | Pamukkale / Hierapolis | 〃 |
| https://www.instagram.com/reel/DdE3EMOgM3m/ | 〃 | Kailasa Temple, Ellora | 〃 |
| https://www.instagram.com/reel/DcfK2vMDh70/ | 〃 | Barabar Caves, Bihar | 〃 |

## Decisions
- The contributor asked for #18 (Peter's Beach, hosted) and #22 (Talo, dealer series) to be
  minted. The atlas-upload skill makes advertising Edward's call, so both are **held** with
  coordinates ready — not minted.
- Place questions (7 same-site pairs) went to Edward's board, not to the contributor, per the
  skill. Nothing was joined or created.
- 10 Instagram pins will not play inline (licensed music).

## Owed by Edward
- `status/owner/place-batch-260928.md` — 7 same-site pairs.
- `status/owner/held-ads-260928.md` — the 2 held pins.

## Follow-up, 2026-09-29: the 2 held pins minted
The contributor asked again for **Peter's Beach** (Sorrento, 40.628707,14.373656) and
**Talo Scandinavian Furniture** (Hadano, 35.378201,139.176483) after being told they read as
promotional. Minted as asked; heroes on gh-pages in `b1b53888` (2 A — @chiara_in_italy's avatar
was already live and was not re-uploaded). Place checks, spine lookup and audit clean.
`status/owner/held-ads-260928.md` is replaced by `status/owner/ads-minted-260929.md`, which asks
Edward whether to keep them — removing a pin is a catalogue edit **plus** an SQL delete.
