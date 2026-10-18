# HANDOFF 2026-10-18: Vienna launches (Atlas Studio VIE 🇦🇹, 35 singles)

**What shipped:** a new studio, **Atlas Studio VIE**, the 47th: 35 single-stop audio tours of Vienna, no walks.
- **Maker:** platform `dozent`, handle `atlas.vie`, uuid5 `atlas-maker:vie` = `49778265-42af-5f37-be6d-16f714a1ea0b`.
- **Ids:** `atlas-tour:vie:<slug>`, stops `atlas-stop:vie:<slug>:1`; every slug starts `vie-`.
- **Catalogue:** tours 2034 → 2069, makers 701 → 702, stops 2493 → 2528. Cities, countries and places did not move
  (creator pins already covered Vienna).

**Source:** Dropbox drop from arthur.yung (the contributor, not the owner), 35 `output <Name> <lat>, <lon>` folders.
These are the scripts staged on `claude/vienna-city-guide-78rxw7` on 2026-10-12. That branch also holds the owner's
2026-10-17 image picks for 15 tours, and the drop's photos for those 15 match the picks. Triage went to the contributor
first. Nothing was skipped.
- **Audio:** 95–121 s each, no duplicates. Not transcribed against the scripts.
- **Photos:** 135, no byte duplicates, all 1200×900 except the Prunksaal hero (1834×1222 PNG, centre-cropped to WebP).
  Contributor: "all photos are royalty-free". Werkbundsiedlung's hero arrived hash-named (`iqpxkuo1jxi8npecbwq4.webp`);
  four folders (Postsparkasse, Furniture Museum, Haus Wittgenstein, Karl-Marx-Hof) were numbered and 01 leads.
- **Text:** `longDescription` = hook + paragraph 3; `shortDescription` cut at 145; captions hand-written from each
  script's orientation paragraph.
- **Bilingual `English | German`** on 8 tours where the names genuinely differ (Postsparkasse, Haus Wittgenstein,
  Wotrubakirche, Werkbundsiedlung, Prunksaal, Hofmobiliendepot, Flakturm, Friedhofskirche). This is the first European
  bureau to do it; the contributor asked for bilingual titles where available. Venues and names used as-is keep one.
- **Geofence:** 40 m venues; 50 m for the larger sites; 60 m Kahlenberg; 75 m Karl-Marx-Hof and Werkbundsiedlung.

**Coordinates.** `check-coordinates.py --drop`: 0 GROSS, 12 UNVERIFIABLE (mostly `#U00..`-mangled folder names; read
by hand, all on their venues), bias 5/30 north, median −0.1 m — no northward offset. Augarten Wien reads 1.9 km "off"
only because the geocoder found the park. The point is the Spiegelgasse shop the script describes. Haus Wittgenstein
uses the drop's point, about 4 m from the staging README's.

**Architect tags (Job 5), 20 new names, one line in each list:** Otto Wagner, Adolf Loos, Josef Hoffmann, Hermann
Czech, Oswald Haerdtl, Hans Hollein, Joseph Maria Olbrich, Johann Bernhard Fischer von Erlach, Karl Ehn, Josef Frank,
Fritz Wotruba, Paul Engelmann, Ludwig Wittgenstein, Max Hegele, PPAG architects, Atelier Heiss, Kühn Malvezzi, Conran and
Partners, Georg Lippert, Richard Neutra. Existing tags reused: Jean Nouvel, Zaha Hadid, Gerrit Rietveld. Left out on
purpose: Friedrich Tamms (it would badge a Nazi flak tower "Designed by a Master"), Matteo Thun (some rooms only),
Joseph Emanuel Fischer von Erlach, the café interior firms (Jelinek & Groß, Portois & Fix), Fritz Gerhard Mayr.
Werkbundsiedlung carries five of its architects (Frank, Loos, Hoffmann, Rietveld, Neutra).

**Places — for Edward:** `status/owner/vienna-launch.md`. The contributor asked to stack six tours on the existing pins
(Secession, State Hall, Kirche am Steinhof, Karl-Marx-Hof, Karlsplatz pavilions, WU library). Per the skill, only
Edward can rule on places, so nothing was created or joined. Note that the pre-existing creator pins for these sites do
not carry the new architect tags; tagging them would be a small follow-up.

**gh-pages:** one commit adding 170 files (35 audio, 135 images), built with plumbing. ⚠️ **`git write-tree` on a
blobless fetch lazily downloads every blob in the tree (~4 GB)** to check that each one exists. Next time use
`git write-tree --missing-ok`, since the new blobs are written locally anyway.

**Checks:** validate-tours-mirror 0 errors, no warnings on the new tours; filenames align (170);
check-place-candidates and join-places as above.
