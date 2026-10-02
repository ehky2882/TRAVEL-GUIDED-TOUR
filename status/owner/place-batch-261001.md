# Place? 9 proven same-site pairs + 2 joins + Kom Ombo + GEM part/whole (2026-10-01 54-pin batch; contributor asked to stack)

_opened 2026-10-01 · clear with `git rm status/owner/place-batch-261001.md`_

# Place questions from the 2026-10-01 batch (54 pins, 7 creators)

_The contributor is not confirmed as the owner, so these are left for you._

**The contributor asked for every same-subject pair to be stacked into one place** ("it offers
different stories to the same place"). Each new pin was minted on the **exact** coordinate of the
existing entry, so nothing moves if you say yes.

**Proven by the tooling** (`make-places.py`, PROVEN · 0 m). Say yes and a session runs
`make-places.py --apply` for these rows only:

| new pin (creator) | existing entry |
|---|---|
| Casa das Histórias Paula Rego (IG @archiwhisperer) | Atlas LIS tour |
| Catedral de la Almudena (IG @ricardotecuenta) | Atlas MAD tour |
| Palacio Real de Madrid (IG @ricardotecuenta) | Atlas MAD tour *Palacio Real* |
| Stockholm City Hall (IG @ricardotecuenta) | Atlas STO tour |
| Wat Rong Khun (White Temple) (IG @ricardotecuenta) | Atlas CNX tour (moved onto the temple this PR, see below) |
| Sun Tunnels (IG @briandphillips) | Sun Tunnels (TikTok @avant_arte) |
| San Cataldo Cemetery (IG @briandphillips) | San Cataldo Cemetery (IG @matter.by.millie) |
| Ramon Magsaysay Center (IG @ricardotecuenta) | The Ramon Magsaysay Center (TikTok @archimarathon) |
| Merdeka 118 (IG @ricardotecuenta) | Merdeka 118 (IG @pasttworld) |

**Joins into places you already made** (`join-places.py`, 0 m, identical name):
Bruder Klaus Field Chapel (IG @briandphillips) and Petronas Towers (IG @ricardotecuenta).

**Need judgement:**
- **Temple of Kom Ombo** (IG @courtneyinruins) + **Kom Ombo Temple** (TikTok @jamesinculture): the same
  temple, on the same point. The tool marks it GAZETTEER, which would move both 39 m onto Wikidata's point.
- **Grand Egyptian Museum** (IG @courtneyinruins) + **Khufu's Solar Boat, Grand Egyptian Museum**
  (TikTok @jamesinculture): part vs whole, which `docs/places.md` leaves to you.

**Also in this PR:** the Atlas CNX tour *White Temple (Wat Rong Khun)* sat **6.5 km north** of the
temple (19.8827, 99.7682). It now sits on OSM's temple-grounds centroid (19.82388, 99.76290), which is
inside the grounds. OSM tags no separate main-chapel feature, so the point is not checked against the
chapel doorway. The tour's geofence is 30 m.

Clear with: `git rm status/owner/place-batch-261001.md`
