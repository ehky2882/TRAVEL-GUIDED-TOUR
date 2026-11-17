# Girona batch 1 — 35 single-stop scripts (STAGED, no audio yet)

Written 2026-11-17 from the Architecture Hunter–style Girona guide (Stay · Dine · Drink · Shop · Visit · Observe).
Voice: `atlas-audio-tour` skill (British conversational). One tour per location, ~260–330 words (~1:45–2:15).

## Files
- `scripts/NN_<slug>_clean.txt`: title line + script, with one `[beat]`. Numbers and years are spelled out.
- `scripts/NN_<slug>_tts-safe.txt`: phonetic respellings (titles included) and no `[beat]` (it becomes a paragraph break). Also no hyphens, all-caps, brackets, digits or accents.
- `md/NN_<slug>.md`: both versions of each tour in one file.
- `GIRONA-SCRIPTS.md`: all 35 clean scripts in one document.
- `coordinates.tsv`: Google Maps name, then WGS-84 lat/lon. Each point is the venue's own OpenStreetMap feature, from the guide session.
- `source/scripts-*.txt`: the text everything else is built from. `tools/build.py` regenerates every output: `python3 -I tools/build.py .`. **Edit the source, not the outputs.** The TTS respelling table is `RESPELL` in `build.py`.

## Sourcing (read before a word was written)
Each venue's own site where it was reachable; otherwise the press, heritage and official sources below. Some are
gaps or conflicts that were **deliberately left out or hedged** in the scripts:
- **Casa Cacao.** hotelcasacacao.com: 15 rooms, rooftop terrace. World's 50 Best / press: Jordi Roca + Anna Payet, opened Feb 2020. The building's date is disputed (1940s vs 1960s), so the script says "mid twentieth century".
- **Nord 1901.** nord1901.com: restored 2009, family-run, "only garden with swimming pool in the city centre" (their claim, attributed).
- **Llegendes.** The hotel's site is blocked from this session. Listings give an 18th-century building and 15 rooms. The legends used (the flies of Sant Narcís, the lioness) are standard Girona folklore. The hotel's floor-by-floor theme was **not** verified and is not claimed.
- **Bellmirall.** Frommer's and the guesthouse's own description: founded in the 1960s by the painter Isidre Vicens (1918–2016), whose paintings hang in it. The "1,100-year-old palace" figure comes from a guest review and was not used.
- **El Celler.** Wikipedia / cellercanroca.com / Jancis Robinson: dates, stars, 50 Best. The López Vilalta + Tarruella (+ Trenchs) birch courtyard comes from Arquitectura Catalana.
- **Normal.** VilaWeb (opened 9 Jul 2021, Josep Roca + Elisabet Nolla) and Wallpaper (Carulla interiors, recycled El Celler glass terrazzo). The current chef was not verified, so the script says "when it opened".
- **Divinum.** Catalan News / Michelin: Morillo + Tejero, first star Nov 2024, Albereda 7.
- **Cal Ros.** Ara (Apr 2025): Gascons family, Fonda Cal Ros. Earlier history comes from listings only and is hedged ("by most accounts").
- **Rocambolesc.** Fine Dining Lovers / LSN: April 2012, Jordi Roca + Ale Rivas, Sandra Tarruella interior. One listing gives Hortes 6 instead of Santa Clara 50. The script and the pin use Santa Clara 50, which matches the OSM node.
- **La Fábrica / Espresso Mafia.** Velodrom, Sprudge, Rouleur, Catalonia Today. Espresso Mafia's founding year conflicts across sources and is omitted.
- **Federal.** 2015 is from one listing and attributed ("by its own account"). Via Augusta on Carrer de la Força is a standard fact.
- **Nykteri's.** Time Out: 2013, Mariona Vilanova, 50+ gins, Temps de Flor, Terrània ratafia, Thursday after-work session.
- **Le Bistrot.** Time Out (late 1970s, pizza de pagès) and Lonely Planet (17th-century church at the top of the steps).
- **Llibreria 22.** Catalonia Today / Ara: 1978, Guillem Terribas (manager until 2015), Just M. Casero prize, Abacus 51%.
- **Mercat del Lleó.** Surt de Casa: first municipal market, 1940s. The architect and the origin of the lion name were not found and are not claimed.
- **Velodrom.** Ara (6 May 2025): Odeon, Miquel Casals, €2M, architect Bruna Vila, The Traka.
- **Banys Àrabs.** Enciclopèdia Catalana / patrimoni.gencat: 1194, 1285, octagonal pool with eight columns, lantern.
- **Cathedral.** Wikipedia / Museu Nacional: 22.98 m nave, Bofill + Canet 1416, stair 1607, façade 1606–1961, Game of Thrones S6, Tapestry of Creation. Step counts vary (90–93), so the script says "roughly ninety".
- **Sant Pere de Galligants.** Wikipedia / Fodor's / Lonely Planet: 992, church c. 1131, ~60 capitals, national monument 1931.
- **Jewish museum.** girona.cat/call / Enciclopèdia: the mikveh found in 2014, the 1492 decree. The synagogue's location is disputed, so the script says "is thought to".
- **Bòlit.** Surt de Casa / Time Out: city art centre since 2008, the 12th-century Sant Nicolau chapel.
- **Museu del Cinema.** The museum's own site: opened 8 Apr 1998, bought 28 Jan 1994, ~20,000 pieces, Casa de les Aigües.
- **Museu d'Art.** museuart.cat / gencat: Episcopal Palace, Sant Pere de Rodes altar, Cruïlles beam.
- **Onyar houses.** Ara: Ansesa + Faixó palette of 39 colours, Fuses + Viader, 83 properties, the houses grey before. Another source names Lluís Gelpí and gives 32 colours. The script follows Ara.
- **Peixateries Velles.** Girona city archive: 1877 (other sources say 1876), Eiffel et Cie.
- **Casa Masó.** rafaelmaso.girona.cat: four houses, last changes 1919, council-owned since 2006, booking required.
- **Farinera Teixidor.** rafaelmaso.girona.cat / COAC: 1910–11 to 1923, ear-of-wheat pinnacle, restored 1997–99, El Punt.
- **Les Àligues.** Enciclopèdia (1561/1572), Time Out (Fuses + Viader, only the façade original), Detail (L-plan, courtyard as a square). The restoration year is unconfirmed and is not stated.
- **Sant Domènec.** Wikipedia / Time Out: Dominicans in the mid-13th century, consecrated 1339, barracks, Arts Faculty around 2000.
- **Torre Gironella.** Enciclopèdia / heritage sites: Roman tower, castle c. 1000, the 1391 refuge, French demolition 1814 (the most-cited date).
- **Sant Feliu.** Wikipedia: first cathedral, eight 3rd–4th c. sarcophagi, tomb of Narcís, minor basilica 2011. The cause of the truncated spire is **not** claimed.
- **Plaça de la Independència.** girona.cat / UdG: Martí Sureda, Sant Agustí convent demolished 1841, renamed 1868, the 1809 monument.
- **Devesa.** Patrimoni Gencat / spain.info: ~40 ha, ~2,600 planes, 1850s, BCIN. Heights are hedged ("by most accounts").
- **Auditori.** gironacongressos.girona.cat: Sala Montsalvatge has 1,236 seats + 300 on stage. **The architects are unverified and not named.**

## Owner checks before recording
- Casa Masó is called "the white house" in three scripts. That is widely known but did not appear in any source read this session.
- Les Àligues (29) and Plaça de Sant Domènec (30) sit ~50 m apart. Keep their geofences small (25–30 m), or merge them.
- Hotel Museu Llegendes: the hotel's own site could not be reached from this session (network allowlist).
