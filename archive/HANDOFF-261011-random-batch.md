# Handoff 2026-10-11 — random batch: 67 link pins from 76 links, 10 new places

Worked directly with **Edward (the owner)** in session, so place and advertising questions were answered by him, not a contributor.

## What shipped (branch `claude/random-pins-261011`)
- **67 link pins** from 50 creators (33 new). Catalogue pins 4171 → 4238, makers 646 → 679, cities 961 → 978, places 497 → 507, countries unchanged.
- **77 images** on gh-pages in one plumbing commit `dc4c585` (67 heroes + 10 TikTok avatars), 77 adds, 0 modified.
- Minted **one URL at a time with `--title`** (batch mode titles from captions, which here were paragraphs). Spec: one TSV row per pin.

## Triage decisions (owner, 2026-10-11)
- **Advertising sign-offs: all pinned** — Olde Good Things (Steinway Hall, Carnegie Hall), NYSERDA "Experience Clean Heat" (ADS Warehouse Newburgh, Mount Kisco Library), Richmond City Hall deck (realtor sign-off), Gloucester Blackfriars (sells a talk recording).
- **Multi-place posts: split.** Finger Lakes (@syracusesocialite) → 6 pins (Ganondagan in Victor; Ontario County Historical Society, Downtown Canandaigua, Canandaigua Lake, Skenoh Island, Sonnenberg Gardens in Canandaigua). SF free rooftops (@humminglion) → One Kearny, 343 Sansome, Conservatory at One Sansome. Ids follow `merge-link-pins.py`'s `#<city>` / `#<city>-<title>` scheme; each pin from one post shares that post's cover bytes (expected).
- **Same creator, same building: one post.** Dropped Union Station East Hall (kept the station post), a second Oslo post, and three posts whose creator already had a live pin on that building (Operaparken @karyna.y, Opus 40 @intricateexplorer, Oslo Opera House @thearchitectscookbook) — caught because their hero filenames already existed on gh-pages. **Check `git cat-file -e origin/gh-pages:images/<file>` before uploading**; a collision means a same-creator repeat and the upload would overwrite a live hero.
- Skipped: a private Fifth Ave apartment (@notenoughangers, newsletter plug, no address). Hermès Williamsburg is still held under `triage-batch-261007`.
- **Held (owner item `random-batch-261011-held`):** Museum SAN (37.418620, 127.823088) and Evergreen Museum (39.349074, -76.620847) — covers have a baked-in ▶; four unnamed places (London hotel, countryside monk retreat, Isaac French wellness project, CenTrio plant — best guess 401 S Wacker).

## Places (owner-approved)
- Joins (0 m): Marin County Civic Center, Isabella Stewart Gardner Museum, Kyoto International Conference Center, Aon Center, The Gamble House, The Elms. The Schwarzman pin joined the existing NYPL place (moved 22 m).
- New: Fairmount Water Works, Carnegie Hall, National Museum of Western Art, Driehaus Museum, He Art Museum, Geisel Library, Grundtvigs Kirke, Steinway Hall, Union Station (with the Continental Club pin — tenant, owner said yes), Castelgrande (whole + Galfetti entrance; the entrance pin moved 178 m onto the castle point). Created with `make-places.py`'s own `apply()` on a filtered proposal list, so other pending proposals (Sydney Opera House, Philadelphia walk pairs, Soho House Istanbul…) were **not** applied — they are still owner-board questions.
- Not touched: the NYC studio tour "New York Public Library, Fifth Avenue" sits 71 m from the NYPL place and is not a member.

## Coordinates worth knowing
- Harvard Graduate Center = Harkness Commons = today's Caspersen Student Center (the cover shows the sign).
- He Art Museum's city is **Shunde**, matching the existing pin (not Foshan).
- Hillstone Winter Park: OSM restaurant node, on Lake Killarney. Castelgrande entrance: Piazza del Sole.
- Wikidata and Commons returned **HTTP 429** mid-session from this container; Photon (komoot) and Nominatim covered the gaps.
