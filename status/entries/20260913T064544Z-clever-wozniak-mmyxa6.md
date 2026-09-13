# 10 sharpened link pins for @blessedarch merged (#857), 9 held on owner's word, 7 unresolvable

_2026-09-13 06:45 UTC · branch `clever-wozniak-mmyxa6`_

Follow-up to #842's @blessedarch/@__dreamspaces architecture triage. 26 pins were
held back from that PR for only geocoding to a city centroid (Nominatim couldn't
resolve the exact venue). This session re-researched each subject's own published
address (architecture press, official museum/tourism sites) rather than a bare
name search, then reverse-geocoded every hit to confirm it lands on the right
building.

Result, presented to the owner in three tiers:
- **10 resolved to the exact venue** — minted, PR #857 merged as `96f80ed`
  (linkPins 1972 → 1982): Lalbhai Dalpatbhai Institute of Indology, Panna Meena
  ka Kund, Sisodia Rani ka Bagh, Anokhi Museum, Hutheesingh Jain Temple, Mill
  Owners' Association Building, Sidi Saiyyed Mosque, House of Pierre Jeanneret,
  Rock Garden of Chandigarh, Hermès showroom Amsterdam.
- **9 narrowed to the right campus/street/village but not the exact building**
  (CEPT University campus, Bapu Bazaar, Semmedu village for the Isha Yoga Center
  pair, Lagoona Mall next to the Zig Zag Towers, Ahilya Fort near the
  boat-access Baneshwar temple, Sector 103 Gurugram) — owner said hold, not
  minted.
- **7 still stuck at city/town level**, no better address found anywhere
  (mostly private residences: Toy Storey house, SaffronStays Asanja x2,
  Chitnavis Wada, TARANG Pavilion, Museum of Meenakari Heritage - one C-Scheme
  lookup landed on the wrong Jaipur neighbourhood entirely, 6km off, backed off
  rather than risk it) — not minted.

validate-tours-mirror.py 0 errors (same 3 pre-existing warnings as main,
unrelated). check-image-duplicates.py --pins clean, 10 heroes hash-verified
live on gh-pages (`e3f5441`). No owner SQL owed - Supabase seed job to confirm
on next session-start.

Full triage (including #842's original 121, the duplicate/vlog/skip calls, and
this session's sharpening) is in the published artifact the owner already has
a link to.
