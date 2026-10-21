# Makkah image picker — candidates (2026-10-21)

Picker: https://claude.ai/artifact/BNf6bq6Ev12hgk3JFV49Ls (private to the owner).
`picker-data.json` maps every picker code (e.g. `16-4`) to its source photo: `src_id` (`px…` = Pexels id,
`us…` = Unsplash id, `wc…` = Wikimedia Commons page id), `page` (the photo's own page) and photographer.

- Sources: Pexels and Unsplash only. Wikimedia Commons returned HTTP 429 to every request from this
  environment and Openverse timed out, so no public-domain search ran.
- **Gemini gates were NOT run** (the key supplied was a project id). Every candidate was checked by eye on
  contact sheets and against its source caption instead; captions removed Khor Fakkan (UAE) shots filed as
  Jabal al-Nour/Thawr, Kuwait/Madinah/Gibraltar mosques filed as Aisha Al Rajhi, and off-subject dishes.
- Food, drink and shop tours (05–14) carry generic dish/drink photos, not the venues; their row titles say so.
- **No usable candidate:** 17 Safa and Marwah, 19 Two Holy Mosques exhibition, 21 Mecca Museum, 24 Bay'ah Mosque,
  25 Tuwa Well, 26 Masjid al-Jinn, 27 Al Muallaa, 28 Aisha Al Rajhi Mosque, 29 Jamaraat Bridge, 30 Haramain station,
  32 Jabal Thawr, 38 Arak Park.
- Unsplash: trigger each picked photo's `download_location` when it is used (API guidelines).
