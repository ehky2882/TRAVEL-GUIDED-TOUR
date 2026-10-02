# Handoff 2026-10-02: 114 link pins from Edward's "Random links" + "Jojo's in NYC" note

## What shipped (one PR, branch `claude/link-pins-261002`)
- **114 link pins from 98 creators** (net +113: one replaced a cross-posted Instagram duplicate), triaged from 113 links Edward pasted from an iCloud note
  (57 "Random links started 9/20", 56 "Jojo's in NYC"; the note itself was shared to named people
  only, `publicPermission: NONE`, so the text had to be pasted).
- Edward ruled on every question himself (he is the owner, so these are rulings, not proposals):
  - **Explode** multi-place posts. R49 Newport roundup became 5 pins (Breakers, Marble House,
    The Elms, Rosecliff, Chateau-sur-Mer); R5 Jūrmala became 2 (18 Tirgoņu St, 32 Vienības Ave,
    both named in the caption); J14 Pioneer Valley became 3 (Montague Bookmill, New England Peace
    Pagoda, Historic Deerfield). J37 Cotswolds became one pin at **St Edward's Church,
    Stow-on-the-Wold**, and J48 one pin on **Cheyne Walk**.
  - **Keep all hotels, resorts and shops** (Sedona, Limón Palm Springs, The Ranch ×2, Ray-Ban House,
    Secrets Tides Punta Cana, New Paltz Way, Virgin Hotels NYC, Andaz Miami Beach).
  - Unknowns identified by Edward: R40 = **Brooklyn Army Terminal**, R57 = **JoJo** (UES),
    J17 = **Trollstigen** (pinned at the visitor centre, 62.45403, 7.66442).
  - Ushaw (two posts, same creator): "if actually different, two pins + make a place".
- Multi-pin ids follow the runbook: different cities → `#slug(city)`; same city →
  `#slug(city)-slug(title)`. One shared hero per post (`newport-gilded-age-mansions-…`,
  `jurmala-wooden-houses-…`, `pioneer-valley-favourites-…`).
- Every "second take" was put on its existing twin's **exact** coordinate, so places can be made
  without moving anything.

## Coordinate fixes to existing entries (in this PR)
- **Karl Marx-Hof (IG @insightcities)** sat ~1.3 km south of the building (48.2385, 16.3583, near the
  Gürtel). Moved to Wikidata's point 48.24945, 16.36372; the new @ministeriumofhistory pin shares it.
- **The Ranch Hudson Valley**: an existing @ethanresortguide pin sits at 41.142731, −74.225239;
  both new Ranch pins snapped onto it. Note it is in **Sloatsburg**, not Accord.
- **Helena Modern Riviera**: snapped onto the existing @earthtokarisa pin (28.442705, −81.470304).
- New pins' Hong Kong country written as "Hong Kong" and Manisa as "Turkey" to match the catalogue
  (they had been minted as "China" / "Türkiye", which would have invented a 95th country).

## Dropped or deferred, with links
| Link | Subject | Why |
|---|---|---|
| https://www.instagram.com/reel/Dd2FtQOKzyW/ | Shelter for Roman Excavations (@briandphillips) | already live (same post) |
| https://www.instagram.com/reel/Dc4VthDvHyt/ | A-train + bus day trip (@imjennychang) | route, no destination; Edward: skip |
| https://www.instagram.com/reel/Ddt0TIUxkaF/ | "Guerrilla mosaics" in subway stations (@gregg_lefevre) | not a point; Edward: skip |
| https://www.tiktok.com/t/ZP8T37GFK/ | Delmonico's (TikTok @nickcabotrodriguez) | **already in open PR #1072** (same id, hero already on gh-pages) |
| https://www.instagram.com/reel/DdiouctoByy/ | National Theatre Prague (@insightcities) | **already in open PR #1072** |
| https://www.instagram.com/reel/DdgYjO-JDzp/ | Old Wan Chai Market (@breatheart_hk) | **already in open PR #1072** |

🔴 **PR #1072** (contributor account, 12 pins, opened 2026-09-22) is still unmerged. If it is
closed instead, those three posts need minting again.

## Places: applied in this PR on Edward's answer ("a - yes, b - yes, c - yes")
- **18 new PROVEN places** (`make-places.py --only PROVEN` run on a copy, and only the groups that
  contain a pin from this batch carried across): Aon Center, Bourse de Commerce, Carpenter Center,
  Freedom Tower, Helena Modern Riviera, Huntington Beach Central Library, Igreja do Sagrado Coração
  de Jesus, Jefferson Market Library, Karl Marx-Hof, Kioi Seido, Kunstmuseum Basel, Le Procope,
  Piedmont Park, Sir John Soane's Museum, The Breakers, The Elms, The Ranch Hudson Valley, The Rookery.
- **3 more new places** from the judgement groups: Albertine Books (with the Venetian Room), Pullman
  National Historical Park (with the Pullman Historic District pin), and Ushaw Historic House,
  Chapels and Gardens (two posts by one creator).
- **9 joins into existing places:** Lucas Museum, HKDI, Musée d'Orsay, Battersea, Louisiana,
  The Henderson, Magazzino, plus Gulbenkian Modern Art Centre → CAM and the Connie Bar → TWA Flight Center.
- 🔴 **Not touched:** the Bruder Klaus, Petronas and Largo di Torre Argentina joins, and the
  2026-10-01 batch's PROVEN groups. Those are still on Edward's board
  (`status/owner/place-batch-261001.md`), and a plain `--apply` would have swept them in.
- Left as they are: Thorne Rooms/Art Institute and Telephone Box/Royal Academy (part vs whole), and
  the Little Prince sculpture beside Albertine (co-located, not the same thing).

## Cross-posted duplicate: Edward kept the TikTok
The TikTok @nycartgal Chinese Scholar's Garden post (https://www.tiktok.com/t/ZP8TBpNmA/) is the same
video and caption as the live IG @oneyearinparis pin (https://www.instagram.com/reel/Dc2Denkg4mb/,
id 460EFECF-…). `check-image-duplicates.py` flagged it as "visually identical". Edward: *"keep
tiktok and discard instagram"*. The Instagram pin was removed from `linkPins`, along with two
`relatedTourIds` references to it. **Its maker row was deliberately KEPT** (now with no entries),
because the seed's prune deletes a missing pin from Postgres only while its maker is still in the
catalogue, so the merge removes it from the live database with no SQL paste. Check after the
publish job: `get_catalog` should no longer carry 460efecf-3451-570c-9db5-9018b501895d.

## Gotchas
- **Two posts from one creator on one subject produce the SAME hero filename.** The Elms
  (@itsblankcreative) single post and the Elms pin from the same creator's Newport roundup both
  wrote `the-elms-itsblankcreative_hero.webp`; the second overwrote the first, and the roundup's
  re-keying then deleted it. Caught by the filename-alignment diff, and regenerated. Mint
  same-creator, same-subject posts into separate out-dirs.
- Wikidata, Wikipedia and Commons all returned 429 after a few dozen lookups from this container,
  and Nominatim joined them later. Space Wikidata calls ≥5 s apart.
- `gh pr list` is GraphQL and returns 403 here. Use `gh api repos/…/pulls?state=open`.
- Re-running `make-link-pin.py` for a creator who already has a maker row re-emits their avatar;
  do not upload it (overwrites live bytes). Two such avatars were removed from the upload set.
