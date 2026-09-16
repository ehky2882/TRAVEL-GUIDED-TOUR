# HANDOFF — 2026-09-16 — @ninosbuildings link pins

**65 link pins added from a single creator, [#940](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/940), merged.**

## What the owner asked for

A pile of 69 TikTok links from one creator (@ninosbuildings), with instructions to
triage first — pin/skip proposals with subject, category and tags per pin — and add
nothing until told to. The owner also flagged that most captions are generic
engagement questions ("Would you live in this?") with the real subject only visible
in the video content, not the text.

## Triage pass

Pulled every post's oEmbed (caption + thumbnail) via `triage-account.py` and
`make-link-pin.py`'s own oEmbed helper. As expected, 60 of 69 captions carried no
place name — but the video thumbnails themselves were usually enough: many are
famous landmarks recognizable on sight (Casa Batlló, Habitat 67, the TWA Hotel …),
and several thumbnails had the *reveal* text burned into the frame as on-screen
subtitles, confirming the owner's hint (Bosco Verticale's thumbnail literally names
"architect Stefano Boeri"; Boston City Hall's sign is in frame; Fondation Cartier's
sign is in frame).

Reported back 37 confident identifications, 14 "I have a lead but can't confirm"
(a style/hashtag match with no name), and 14 "no landmark visible, skip" — plus one
MULTI (a single post naming two Singapore towers).

## Owner's response

Approved all 37 confident ones, then supplied exact addresses for **27 more** of the
32 flagged/skipped posts — recognizing several from lived experience that the triage
couldn't confirm from pixels alone (Walden 7, Piscina das Marés, the Neutra VDL
house, the Whitney/Met Breuer building, Casa de Serralves, El Nido de Quetzalcóatl,
Brasília Palace Hotel — several of these directly confirmed guesses the triage had
already made but flagged as unconfirmed). Also directed the Singapore MULTI to
become two separate pins (Beverly Mai + The Concourse) rather than one or neither.
Only 1 of 69 posts (a private home interior with no address given) ended up
unpinned.

## Build

- **Geocoding**: Nominatim, ~1 request/2s, several queries needed reformatting from
  a landmark name to a plain street address before they resolved (named-POI search
  is much flakier than address search on Nominatim). A handful of raw coordinates
  the owner gave directly were used as-is; reverse-geocoded them only for naming
  context.
- **Minting**: `make-link-pin.py`'s CLI takes one `--category`/`--tags` pair for an
  entire `--batch` run, which doesn't fit 65 pins each needing building-specific
  tags. Wrote a driver (`mint_batch.py`, not committed — scratch) that imports the
  module and calls `make_one()` directly per row, collecting the same
  `{makers, linkPins}` shape `main()` would emit, so `merge-link-pins.py` sees
  identical input either way.
- **Caught before minting**: cross-checked every row's assigned URL against the
  authoritative caption table (built from the original oEmbed dump) before running
  anything expensive. Found and fixed three mapping errors from manual transcription
  — Lloyd's Building and Rosewood São Paulo had been given a different post's URL,
  and a "Pavilion in the Pond" entry had a placeholder URL I'd forgotten to fill in.
  Worth the extra pass: any of the three would have pinned a real building's map
  location to a TikTok video about something else entirely.
- **Two-pins-from-one-post**: hand-computed the `#<city>-<title>` fragment ids per
  `docs/link-pin-runbook.md` for the Singapore pair. First attempt hashed my own
  short `vm.tiktok.com` link and `merge-link-pins.py --check` refused both ids as
  "not derivable" — the scheme hashes the **canonical** `sourceURL` `make_one()`
  resolves to and stores, not the input URL. Recomputed against `tour["sourceURL"]`
  and both reproduced exactly.
- **gh-pages**: `gh` unavailable in this session; built the commit via plumbing
  (`git read-tree` on `origin/gh-pages`, stage 65 new blobs, `commit-tree`, push) —
  never checked out the ~4 GB branch. Diff was exactly 65 additions, nothing else
  touched. Hash-verified all 65 live URLs against local bytes once Pages finished
  deploying (~10 min lag, matching the documented behavior — `check-image-
  duplicates.py --pins` run immediately after the push 404'd on every new file and
  still printed "OK", also as documented).

## Verification

- `validate-tours-mirror.py`: 0 errors, only pre-existing-style warnings (missing
  optional Theme/Place-type tag facets, same pattern as existing catalog entries).
- `merge-link-pins.py --check` then a real merge: clean, all 65 ids derivable.
- Generated hero filenames matched `git diff`'s new `heroImageURL`/`imageURL`
  references exactly.
- `check-image-duplicates.py --pins`: only byte-identical pair is the deliberate
  Beverly Mai/Concourse share (same source video); no collisions elsewhere in the
  catalog.
- PR #940: CI green (unit tests, `Validate Tours.json`, iOS Simulator build), no
  merge conflict, squash-merged.

## Left alone

CLAUDE.md's Key-facts paragraph (tour/pin/city counts) was not hand-edited. At least
nine other PRs (#931 through #939) merged to `main` during this single session, and
the file's own history shows that paragraph going stale within the same PR that
corrects it — every prior correction records `main` having moved again before merge.
Re-derive live counts from `scripts/session-start.sh` or a fresh query rather than
trusting anything written there.

## Known debt / left open

- 14 flagged-but-unresolved subjects from the original triage were superseded by the
  owner's direct addresses, so none remain outstanding from this batch specifically.
- Two of the newly-pinned buildings (Beverly Mai, a brutalist church on Via San
  Paolino/Via Dalmazia in Milan, one in Coração de Jesus Lisbon) carry a
  descriptive rather than a confirmed proper-noun title — Nominatim had no named POI
  at those addresses and I didn't want to invent a dedication. Worth a follow-up
  pass if the owner knows the actual names.
