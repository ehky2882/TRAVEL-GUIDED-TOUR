# Handoff 2026-10-22: 143-pin triage batch (136 from @architectphilipp, Vienna)

## What shipped

A contributor (arthur.yung) pasted 166 links: 163 unique posts, 3 of them pasted twice. Everything was triaged first, and
nothing was minted until they had approved.

- **143 link pins added** from 7 creators. Two creators are new: **@architectphilipp** (136 Vienna architecture/history
  reels) and **@whitlamsberlintours** (the Esplanade's Kaisersaal, Berlin). The other five already existed:
  @josh.snaith11, @ninosbuildings, @chloecotter, @archimarathon and @sashi_trip_tip.
- **11 new architect tags** (Job 5, names only, on a line of their own): Theophil Hansen, Johann Lucas von Hildebrandt,
  Friedrich von Schmidt, Günther Domenig, Roland Rainer, Karl Schwanzer, Hubert Gessner, Eduard van der Nüll, August Sicard
  von Sicardsburg, Oskar Marmorek and Joseph Kornhäusel. Existing tags were also used: Otto Wagner, Adolf Loos, Jože Plečnik,
  Johann Bernhard Fischer von Erlach, Fritz Wotruba, Max Hegele and Luís Pedro Silva. Every tagged pin also got *Designed
  by a Master*.
- **Heroes:** 143 files went to gh-pages in one plumbing commit, `de8d921`, with 143 additions and nothing else. The two
  regenerated TikTok avatars (ninosbuildings, sashi_trip_tip) were **not** uploaded, because both creators already exist.

## Skipped (20), all decided by the contributor

- **BAPS Mandir** (@thedesigndetourist): the same creator already has a pin of it from a different video.
- **Battersea Power Station** (@liambedfordyt, `DepAuwUTsQ7`): open PR #1153, from a parallel session, already pins the
  same creator's *Animals* video from another reel (`DYw5ZagKzbh`).
- **Not about one place:** Viennese Baroque's Italian roots (`DUIbF5gjM6I`, filmed in Turin), and the city's cube clocks
  (`DDOrI7DOmCR`).
- **Older remakes by the same creator:** Peterskirche, Maria am Gestade, Zacherlhaus, Heiligenkreuzerhof and
  Ruprechtskirche. The newer video of each was kept.
- **Votivkirche part 2**, a series sequel on the same subject. Part 1 is pinned.
- **Location not certain enough:** Melkerhof in Josefstadt (it is on Laudongasse, but no house number was found; the
  1st-district Melkerhof is a different building), "Alte Harnischhaus" (probably Augustinerstraße 12, the Báthory house,
  but the name is unconfirmed), and Schottendurchhaus.
- **Seven street videos** (Bräunerstraße, Barnabitengasse, Annagasse, Ballgasse, Naglergasse, Tiefer Graben and
  Grünangergasse): the contributor skipped them with the less-certain group.

These can be revisited. The triage table with every coordinate is not committed; the reasons above are the record.

## How subjects were identified

- Instagram captions name most subjects. For the rest, `fetch-cover.py` frames were read, plus a web search: the
  Schweizerhof fountain in the Hofburg, the "Mozart plane tree" (the Jacquin-Platane at Rennweg 14), Astoria Garage
  (Trautsongasse 4), Renngasse 10, Palais Niederösterreich, the Marinesektion building (Marxergasse 2), the Heumühle, the
  Domenig Humanic shop (Trude-Waehner-Platz on Alser Straße) and the LA Memorial Coliseum (the TikTok caption names nothing).
- The @sashi_trip_tip "octopus" video is the **Leixões Cruise Terminal**, identified from the caption: 750 m into the
  Atlantic, a million hex tiles, and the university marine lab.
- Coordinates come from Nominatim and were each checked by reverse lookup. Several venue queries returned no hit
  (Salvatorkirche, Annakirche, Schanzelkapelle and others) and were resolved by address or alias. One query resolved the
  Burggarten statue to the 7th district, and it was corrected.
- The ten "stack" pins sit **exactly** on the existing entry's coordinate. Same-creator pins on one church (St Stephen's ×6,
  Minorite ×4, St Michael's ×2, Servite ×2) share one point.

## Owner

`status/owner/place-triage-261022.md` holds 10 place candidates. No Supabase reseed is owed: publish-catalog seeds the
database on merge.
