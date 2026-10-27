# Handoff 2026-10-27 — 37-pin triage batch (6 Instagram creators)

Contributor (@arthuryung-gif, not the owner) pasted 50 Instagram links (49 unique) and asked for a
triage first. They approved: pin the clear ones, drop same-venue repeats, skip the open questions.

## What shipped
- **37 link pins**: @globalfoodquest 16 (Portuguese restaurants), @urban_garbagebin 9 (post-war
  architecture), @historianaisha 8 (UK + Florence history), @floating_foreigner 2, @_robbiethompson 1,
  @archiwhisperer 1. 4 new creators. 11 new cities, no new country, no new place.
- 37 heroes on gh-pages in one commit (`b9b0485`), built with git plumbing because `gh api` writes are
  blocked by the proxy (HTTP 403) — `upload-images.py` cannot run in this environment.
- `spine/lookups.json.gz` refreshed (37 asked, 0 failed).

## How subjects were found
- Captions where they named the venue; Instagram tags (@thecapsule.lisbon → Capsule Neo Bistro,
  Rua do Crucifixo 71; @malacopa_tacobar → Malacopa, Cascais) resolved by searching the name.
- Cover frames: Laurentian Library (caption said only "Michelangelo"), Flodden Wall at the Vennel.
- **Video frames** (Instagram exposes `video_url` for original-audio reels; ffmpeg 4×4 contact sheet,
  burned-in subtitles readable): L-Flat Zeist ("longest apartment building"), Blok Statek Wrocław
  ("strangest building"), Churrasqueira da Cidreira (Piri Piri ep. 6, named on screen).
- Coordinates from OSM named nodes. Approximate (street-level): Astro Ramen, After Dark, Familjen
  (matches the existing @where.to.taste pin), Silos da Trafaria (terminal centroid).

## Left out, deliberately
- Repeats of the same venue by the same creator: Familjen aubergine (`DeZN1BWNHDa`), Torta de Azeitão
  (`DTQNXoKikPO`, = Pastelaria Cego), Capsule octopus hot dog (`DQFF0cFiYbh`).
- Skipped: `Dc84M-8MGkT` (already live), `De9uNqCAeTP` (embed disabled, unreadable), two Mar à Mesa
  posts (`DdRELjQNV2n`, `DdEZpmtNpyB`: the creator's own past pop-up event on a 10 km beach).
- Contributor said skip: Sauda III thesis (`DesDKccO9BZ`, unbuilt design proposal), Lenin statue
  (`DZucYBhsFZf`, moved Tjuchem → Oostwold Aug 2026, moving again), O Brasas (`DWEbhbFAchz`, no
  address found anywhere).
- **Added in a follow-up PR (contributor said yes):** Rio de Mel and Churrasqueira O Galaró. The Galaró branch was settled from the video: a takeaway shopfront on a main road matches the Rua de Lisboa (Brejos de Azeitão) branch, not the Aldeia de Irmãos restaurant. No listing confirmed it.
- ~~**Open with the contributor:** Rio de Mel (`DSID1aGjecd`, 38.753432,-9.142439) and Churrasqueira
  O Galaró (`DSYEW1JjRiu`, 38.538189,-9.025087 — a second branch exists 3 km south). I miscounted the
  "five to skip", so these two were held back rather than guessed; mint them if the contributor says so.~~

## For the owner
`status/owner/place-batch-261027.md`: six place questions, plus an existing @insightcities Nová Scéna
pin ~450 m off its subject. Three @urban_garbagebin reels use licensed music (open Instagram on tap).
Jaap Bakema, Karel Prager and Alexander "Greek" Thomson are not architect tags yet.
