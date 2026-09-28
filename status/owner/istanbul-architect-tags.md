# Add 5 Istanbul architect tags (Sinan, Balyan, Vallaury, Tabanlıoğlu, Arolat)

_opened 2026-09-28 · clear with `git rm status/owner/istanbul-architect-tags.md`_

# Add five Istanbul architect tags to the vocabulary

_opened 2026-09-28 · Istanbul batch 1 (Atlas Studio IST) · clear with `git rm status/owner/istanbul-architect-tags.md`_

The Istanbul scripts name architects the controlled tag vocabulary does not have, so
those tours ship with only **Designed by a Master** for now. The contributor asked
that Edward add them on his side — it is a Swift change (`Models/Tag.swift`, plus the
mirrored lists in `scripts/validate-tours.swift`), so it waits for his OK.

| tag | tours that would carry it |
|---|---|
| **Mimar Sinan** | Süleymaniye Mosque, Sokullu Mehmet Pasha Mosque (Azapkapı), Kılıç Ali Paşa Hamamı |
| **Balyan family** (Garabet / Nikoğos Balyan) | Büyük Mecidiye (Ortaköy) Mosque, The Stay Bosphorus |
| **Alexandre Vallaury** | SALT Galata, Abdülmecid Efendi Köşkü, Tiled Pavilion (surveyed it; designed the museum opposite) |
| **Tabanlıoğlu** (Hayati / Murat) | Atatürk Cultural Centre (AKM), Beyazıt State Library, Zorlu Center |
| **Emre Arolat** | Sancaklar Mosque, Zorlu Center |

Once the tags exist, a content-only follow-up PR adds them to those tours.
