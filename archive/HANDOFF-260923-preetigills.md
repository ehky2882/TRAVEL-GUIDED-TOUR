# Handoff — 2026-09-23 — 55 @preetigills link pins

## What happened
A 65-link pile (said to be "a couple of creators") was **one creator, Instagram @preetigills**,
Paris food & travel. Triaged first, owner approved 55, skipped 10:
#65 Galerie Vivienne (multi-venue), #19 Jinchan (two locations, cover could not settle which),
#12 Fleuron / #20 RSVP / #33 EP!C (brand collaborations), #55 Le Paon Qui Boit (product post),
#35 + #53 (same creator, same shop as #1 Landline), #51 (interview, not a place),
#58 (baguette épi, bakery unidentifiable).

Café de la Paix, Musée Carnavalet and Le Relais de Venise sit 0–21 m from existing entries.
**Owner: keep them as separate entries.** Do not re-offer them as place candidates.

## 🔴 Instagram's embed page is dry for these posts
`https://www.instagram.com/reel/<code>/embed` returned a 200 page with **no** username,
display_url or caption for every one of the 65 posts, so `triage-account.py` reported
COULD NOT VERIFY and `make-link-pin.py` could not mint. What worked instead:

- **Caption + handle:** the plain post page fetched with a
  `facebookexternalhit/1.1 (+http://www.facebook.com/externalhit_uatext.php)` user agent carries
  `<meta name="description" content="N likes, N comments - handle on DATE: "CAPTION"">` and
  `og:url` with the handle. Pace it (~4 s apart); bursts get 429.
- **Hero:** `https://www.instagram.com/p/<code>/media/?size=l` returns the full 720×1280 frame.
  Two posts 404 there (DD5LVWOTwEA, DDPLth4IFeO) and fell back to the 640 `og:image`, which has
  a **play-button overlay baked in** — Bubble Bliss and Le Repaire de Bacchus heroes carry it.
- Minted by importing `make-link-pin.py` and calling `make_one` per pin with `oembed`
  replaced by the above, which also let each pin carry its own title/category/tags
  (batch mode cannot). **Inline playability could not be checked** by this route.
- Slugs were ASCII-folded before `hero_slug` — the tool's own slugify turns `Café` into `caf-`.

Worth folding into the tool properly; not done here.

## Verified
validate-tours-mirror clean (no new warnings after adding `Venue` to two shop pins);
55 filenames match the catalogue; 55 heroes pushed to gh-pages as additions only (`e0050771`);
place reports: only the three owner-ruled pairs, joins 0.

## ⚠️ Superseded (2026-09-23, later the same day)

The "Owner: keep them as separate entries" above was the **contributor's** answer, not Edward's.
Edward has since ruled: **make all three places** (Le Relais de Venise, Café de la Paix, Musée
Carnavalet). They were made on branch `claude/scale-pinned-tours-automation-dba3lx`. The upload
skill now routes place questions to Edward's board, not to the person in the chat.
