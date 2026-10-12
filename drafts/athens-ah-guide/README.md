# Athens — Architecture Hunter–style city guide, as Atlas audio tours

Thirty single-stop tours, one per venue, written to `atlas-audio-tour` (British conversational voice).
Grouped the way Architecture Hunter city guides are: **Stay · Dine · Drink · Shop · Visit · Observe**.

Every venue's primary sources (its own website where one exists, otherwise official guides and the best available write-ups) were fetched and read before writing; each script's `.md` lists them.

## Files per tour

| File | What it is |
|---|---|
| `athens_NN_slug.md` | Clean script with address, pin, length and sources |
| `athens_NN_slug.txt` | Clean script, `[beat]` kept as an authoring marker |
| `athens_NN_slug_TTS.txt` / `_TTS.md` | TTS-safe: phonetic respellings (lowercase, no hyphens), no markup or brackets, `[beat]` replaced by a paragraph break, years and numbers spelled out, title respelled |

## Tours

| # | Tour | Category | Pin (WGS-84) | Words |
|---|---|---|---|---|
| 01 | Perianth Hotel | Stay | 37.977471, 23.728421 | 357 |
| 02 | Shila | Stay | 37.980673, 23.737215 | 311 |
| 03 | The Modernist Athens | Stay | 37.977425, 23.749363 | 316 |
| 04 | Xenodocheio Milos | Stay | 37.977135, 23.733426 | 325 |
| 05 | Hotel Grande Bretagne | Stay | 37.976550, 23.735402 | 338 |
| 06 | Diporto | Dine | 37.980734, 23.725835 | 324 |
| 07 | Karamanlidika tou Fani | Dine | 37.980006, 23.725924 | 318 |
| 08 | Seychelles | Dine | 37.982258, 23.720289 | 310 |
| 09 | Atlantikos | Dine | 37.977534, 23.722976 | 286 |
| 10 | Nolan | Dine | 37.974824, 23.732408 | 279 |
| 11 | The Clumsies | Drink | 37.978972, 23.729831 | 335 |
| 12 | Brettos | Drink | 37.971709, 23.730525 | 297 |
| 13 | Couleur Locale | Drink | 37.976578, 23.724416 | 286 |
| 14 | Baba au Rum | Drink | 37.977399, 23.729783 | 293 |
| 15 | Taf Coffee | Drink | 37.983609, 23.730948 | 230 |
| 16 | Melissinos Art – The Poet Sandal Maker | Shop | 37.968378, 23.730970 | 352 |
| 17 | Kombologadiko | Shop | 37.978403, 23.735228 | 270 |
| 18 | Forget Me Not | Shop | 37.974084, 23.729360 | 239 |
| 19 | Varvakios Agora (Athens Central Market) | Shop | 37.980373, 23.727624 | 352 |
| 20 | Little Tree Books & Coffee | Shop | 37.968139, 23.727028 | 246 |
| 21 | Pikionis Paths & Agios Dimitrios Loumbardiaris | Visit | 37.970086, 23.720348 | 418 |
| 22 | Acropolis Museum | Visit | 37.968533, 23.728470 | 397 |
| 23 | Stavros Niarchos Foundation Cultural Center | Visit | 37.941042, 23.693306 | 408 |
| 24 | National Museum of Contemporary Art (EMST) | Visit | 37.963016, 23.725262 | 326 |
| 25 | Benaki Museum – Pireos 138 | Visit | 37.974474, 23.708603 | 303 |
| 26 | The Blue Building (Μπλε Πολυκατοικία) | Observe | 37.986442, 23.735477 | 342 |
| 27 | Athens Conservatoire | Observe | 37.973457, 23.743420 | 319 |
| 28 | Conrad Athens The Ilisian (former Athens Hilton) | Observe | 37.976194, 23.750467 | 321 |
| 29 | Anafiotika | Observe | 37.972407, 23.728133 | 343 |
| 30 | Lycabettus Funicular | Observe | 37.980316, 23.744006 | 328 |

## Corrections found while sourcing (vs. the earlier chat list)

- **Six d.o.g.s closed in December 2024**; its Avramiotou premises reopened as Klakaz in April 2026. Replaced in Drink by **Couleur Locale** (Normanou 3). Its old domain now serves a gambling page.
- **Nolan**: its founding chef Sotiris Kontizas has left; Michelin now lists "Nolan 2.0" under chef Michalis Nourloglou. The script says so. Its old domain also now serves a casino page — reconfirm it is trading before recording.
- **Melissinos Art** has moved to **Tzireon 16, Makrygianni** (official site). Founder Stavros Melissinos died in 2025.
- **The Modernist Athens** is the former **Canadian Embassy** (1950s), not a generic 1950s block.
- **Xenodocheio Milos** is two twin listed **neoclassical** buildings joined by a glass roof addition, not an interwar commercial building.
- **Conrad Athens The Ilisian** (ex-Hilton) reopened under that name on 23 April 2026.

## Pins that are street-level only (~50 m)

Shila (Mantzarou is pedestrian; OSM has the street, not the door) and Xenodocheio Milos. Run `scripts/check-coordinates.py` before wiring any of these into `Tours.json`.

## Respellings used in the TTS files

| Written | TTS respelling |
|---|---|
| Adrianou | ah dree ah noo |
| Aeter | eh ter |
| Agias Irinis | ah yahs ee ree nees |
| Agios Dimitrios | ah yee oss dee mee tree oss |
| Agios Dimitrios Loumbardiaris | ah yee oss dee mee tree oss loom bar dee ah rees |
| Aiolou | eh oh loo |
| Alexis Minotis | ah lek sees mee noh tees |
| Amerikis | ah meh ree kees |
| Anafi | ah nah fee |
| Anafiotika | ah nah fee oh tee kah |
| anthos | an thoss |
| Antonis Dimitriou | an toh nees dee mee tree oo |
| Antonis Georgiadis | an toh nees yor yah dees |
| Arachovis | ah rah hoh vees |
| Aristippou | ah ree stee poo |
| Athinas | ah thee nahs |
| Atlantikos | at lan tee koss |
| Avdi | av thee |
| Avliton | av lee tone |
| AvroKO | av roh koh |
| Baba au Rum | bah bah oh rum |
| Bernard Tschumi | bernard shoo mee |
| Bib Gourmand | bib goor mahn |
| Brettos | bret toss |
| Costas Spiliadis | koss tas spee lee ah dees |
| Costas Varotsos | koss tas vah roh tsoss |
| Couleur Locale | koo lur loh kahl |
| Despotopoulos | des poh toh poo loss |
| Dimitriou | dee mee tree oo |
| Dimitris Pikionis | dee mee trees pee kee oh nees |
| Dionysiou Areopagitou | dee oh nee see oo ah reh oh pah yee too |
| Diporto | dee por toe |
| Eftihia Stefanidi | ef tee hee ah steh fah nee dee |
| Emmanouil Benaki | em mah noo eel beh nah kee |
| Emmanouil Vourekas | em mah noo eel voo reh kas |
| EMST | emst |
| Ermou | er moo |
| Estiatorio | ess tee ah toh ree oh |
| Evripidou | ev ree pee doo |
| Exarchia | ek sar hee ah |
| falernum | fah ler num |
| Faliro | fah lee roh |
| Fani | fah nee |
| Fani's | fah nee's |
| Fanis | fah nees |
| FORMrelated | form related |
| G. Damigos | dah mee goss |
| Gazi | gah zee |
| Giorgio de Chirico | jor joh deh kee ree koh |
| Grande Bretagne | grahnd bruh tahn yuh |
| Hansen | hahn sen |
| Ieropoulos | ee eh roh poo loss |
| Ilisia | ee lee see ah |
| Ilisian | ill iss ee an |
| Ilissos | ee lee soss |
| Ioannis | yah nees |
| Ioannis Despotopoulos | yah nees des poh toh poo loss |
| K-Studio | kay studio |
| Kallirrois | kah lee roh ees |
| Kalymnos | kah leem noss |
| Karaman | kara mahn |
| Karamanlides | kara mahn lee dess |
| Karamanlidika | kara mahn lee dee kah |
| Katina Paxinou | kah tee nah pak see noo |
| Kavalloti | kah vah loh tee |
| kavourmas | kah voor mahs |
| Kerameikos | keh rah mee koss |
| Kerameikou | keh rah mee koo |
| Klitiou | klee tee oo |
| Kolokotroni | kollo ko troh nee |
| Kolokotronis | kollo ko troh nees |
| Kolonaki | kollo nah kee |
| Kombologadiko | kom boh loh gah dee koh |
| komboloi | kom boh loy |
| Korakis | koh rah kees |
| Kostas Voutsinas | koss tas voo tsee nas |
| Kostis Antonopoulos | koss tees an toh noh poo loss |
| Kostis Karatzas | koss tees ka rah dzas |
| Koukaki | koo kah kee |
| Kydathineon | kee dah thee neh on |
| Kyriakoulis Panagiotakos | kee ree ah koo lees pah nah yoh tah koss |
| Le Corbusier | luh kor boo zee ay |
| Lemnos | lem noss |
| Loumbardiaris | loom bar dee ah rees |
| M. Sigalas | see gah lass |
| Makrygianni | mah kree yah nee |
| Manolis Glezos | mah noh lees gleh zoss |
| Mantzarou | mahn dzah roo |
| Melissinos | meh lee see noss |
| Metaxourgeio | meh tah ksoor yee oh |
| Michael Photiadis | michael foh tee ah dees |
| Michail | mee hah eel |
| Michalis | mee hah lees |
| Michalis Nourloglou | mee hah lees noor loh gloo |
| Milos | mee loss |
| Mitsos | meet soss |
| Monastiraki | monna stee rah kee |
| Mple Polykatoikia | bleh poh lee kah tee kee ah |
| Mykonos | mee koh noss |
| Nafplio | naf plee oh |
| Nikos Bakoulis | nee koss bah koo lees |
| Normanou | nor mah noo |
| Panepistimiou | pah neh pee stee mee oo |
| Pantelis | pan teh lees |
| Pastirma | pass teer ma |
| pastirma | pass teer ma |
| Patriarchou Ioakim | pah tree ar hoo ee oh ah keem |
| patsas | pah tsas |
| peri, | perry, |
| Perianth | perry anth |
| Phaleron | fah leh ron |
| Philippos Khoury | fee lee poss koo ree |
| Philopappos | fee loh pah poss |
| Philopappou | fee loh pah poo |
| philoxenia | fee loh kseh nee ah |
| Pikionis | pee kee oh nees |
| Pireos | pee reh oss |
| Ploutarchou | ploo tar hoo |
| polykatoikia | poh lee kah tee kee ah |
| Praxitelous | prak see teh loose |
| Prokopis Vasileiadis | proh koh pees vah see lee ah dees |
| Psara | psah rah |
| Psyrri | psee ree |
| rakomelo | rah koh meh loh |
| Rigillis | ree yee lees |
| Rubaiyat | roo bye yaht |
| savoro | sah voh roh |
| Skyros | skee ross |
| Sofia Vembo | soh fee ah vem boh |
| Sofokleous | soh foh kleh ooss |
| Sokratous | soh krah toose |
| Sotiris Kontizas | soh tee rees kon tee zas |
| Soutzouki | soo dzoo kee |
| Spicy Baba | spicy bah bah |
| Spyros Papaloukas | spee ross pah pah loo kas |
| Spyros Staikos | spee ross stah ee koss |
| Stadiou | stah dee oo |
| Stavros | stahv ross |
| Stavros Niarchos | stahv ross nee ar hoss |
| Supremus | soo preh mus |
| Symi | see mee |
| Syngrou | seen groo |
| T shirts | tee shirts |
| Taf | taff |
| Takis Zenetos | tah kees zeh neh toss |
| Technopolis | tek noh poh lees |
| Thanos Prunarus | thah noss proo nah roos |
| Theatrou | theh ah troo |
| Themistokleous | theh mee stoh kleh ooss |
| Theodoropoulos | theh oh doh roh poo loss |
| Theodoros | theh oh doh ross |
| Theophil Hansen | tay oh feel hahn sen |
| Thiseio | thee see oh |
| Ti' Punch | tee punch |
| tsipouro | tsee poo roh |
| Tzireon | dzee reh on |
| Varvakios | var vah kee oss |
| Varvakis | var vah kees |
| Vasileos Konstantinou | vah see leh oss kon stan dee noo |
| Vasilissis Sofias | vah see lee sees soh fee as |
| Vassilis Kyritsis | vah see lees kee ree tsees |
| Voulis | voo lees |
| Xenodocheio | kseh noh doh hee oh |
| Yannis Moralis | yah nees moh rah lees |
| Yannis Taloumis | yah nees tah loo mees |
| Zenetos | zeh neh toss |
