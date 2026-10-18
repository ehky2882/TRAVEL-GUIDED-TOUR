# Warsaw batch 1: Architecture Hunter-style city guide, as Atlas audio tours

**37 single-stop tours · British conversational register (atlas-audio-tour skill) · scripts only, no audio yet · drafted 2026-10-12**

These are the 37 venues from the Warsaw city guide (Stay, Dine, Drink, Shop, Visit, Observe), each written as its own tour.

**Every tour has three files in `scripts/`:**
- `.md` is the clean script, with the Google Maps name, the coordinates, the vantage point, and the sources read before writing.
- `.txt` is the clean script as plain text. `[beat]` stays in as an authoring marker.
- `_TTS.txt` is the TTS-safe version. Proper nouns, including the titles, are spelled phonetically in lowercase. It has no hyphens, no brackets, no markup and no digits, and years are spelled out. Each `[beat]` is replaced by a paragraph break.

**Rebuild:** run `python3 tools/build.py` after editing `source/*.txt`, then `python3 tools/make_readme.py`. The build fails if a TTS file still contains a digit, a bracket, a hyphen, an all-caps word, or a non-ASCII letter (a Polish name nobody has respelled).

**Research:** `RESEARCH-NOTES.md` records what each venue's sources said, before a word was written.

## Index

| # | Category | Tour title | Google Maps name | Coordinates (WGS-84) | Files |
|---|---|---|---|---|---|
| 01 | STAY | Raffles Europejski Warsaw | Raffles Europejski Warsaw | 52.241927, 21.015059 | `warsaw_01_raffles_europejski` |
| 02 | STAY | Hotel Bristol | Hotel Bristol, a Luxury Collection Hotel, Warsaw | 52.242404, 21.015724 | `warsaw_02_hotel_bristol` |
| 03 | STAY | Autor Rooms | Autor Rooms | 52.222336, 21.012410 | `warsaw_03_autor_rooms` |
| 04 | DINE | Bar Mleczny Prasowy | Bar Mleczny Prasowy | 52.215796, 21.020592 | `warsaw_04_bar_mleczny_prasowy` |
| 05 | DINE | Bez Gwiazdek | Bez Gwiazdek | 52.241921, 21.021865 | `warsaw_05_bez_gwiazdek` |
| 06 | DINE | Hala Koszyki | Hala Koszyki | 52.222224, 21.011017 | `warsaw_06_hala_koszyki` |
| 07 | DINE | Elektrownia Powiśle | Elektrownia Powiśle | 52.240774, 21.027832 | `warsaw_07_elektrownia_powisle` |
| 08 | DINE | Charlotte, Plac Zbawiciela | Charlotte | 52.220090, 21.018640 | `warsaw_08_charlotte_plac_zbawiciela` |
| 09 | DRINK | Kulturalna | Kulturalna | 52.231263, 21.007087 | `warsaw_09_kulturalna` |
| 10 | DRINK | Warszawa Powiśle | Warszawa Powiśle | 52.234078, 21.029892 | `warsaw_10_warszawa_powisle_bar` |
| 11 | DRINK | Pawilony Nowy Świat | Pawilony za Nowym Światem | 52.232943, 21.020321 | `warsaw_11_pawilony_nowy_swiat` |
| 12 | DRINK | Plan B | Plan B | 52.220004, 21.018694 | `warsaw_12_plan_b` |
| 13 | DRINK | Kafka | Caffe Kafka | 52.239532, 21.022711 | `warsaw_13_kafka` |
| 14 | DRINK | Rozbrat 20 | Rozbrat 20 | 52.224200, 21.035099 | `warsaw_14_rozbrat_20` |
| 15 | SHOP | Pawilon Cepelii | Pawilon Cepelii | 52.228941, 21.011624 | `warsaw_15_pawilon_cepelii` |
| 16 | SHOP | Bęc Zmiana | Bęc Zmiana | 52.226793, 21.022248 | `warsaw_16_bec_zmiana` |
| 17 | SHOP | Pan Tu Nie Stał | Pan Tu Nie Stał | 52.223017, 21.014392 | `warsaw_17_pan_tu_nie_stal` |
| 18 | SHOP | Hala Mirowska | Hala Mirowska | 52.238837, 20.997370 | `warsaw_18_hala_mirowska` |
| 19 | SHOP | Bazar Różyckiego | Bazar Różyckiego | 52.252305, 21.040079 | `warsaw_19_bazar_rozyckiego` |
| 20 | VISIT | The Palace of Culture and Science | Pałac Kultury i Nauki | 52.231766, 21.005798 | `warsaw_20_palac_kultury_i_nauki` |
| 21 | VISIT | The Neon Museum | Muzeum Neonów | 52.231878, 21.006114 | `warsaw_21_muzeum_neonow` |
| 22 | VISIT | The Museum of Modern Art | Muzeum Sztuki Nowoczesnej | 52.233129, 21.008984 | `warsaw_22_muzeum_sztuki_nowoczesnej` |
| 23 | VISIT | Zachęta National Gallery of Art | Zachęta — Narodowa Galeria Sztuki | 52.239241, 21.011491 | `warsaw_23_zacheta` |
| 24 | VISIT | POLIN Museum of the History of Polish Jews | Muzeum Historii Żydów Polskich POLIN | 52.249372, 20.993161 | `warsaw_24_polin` |
| 25 | VISIT | The University of Warsaw Library and its roof garden | Biblioteka Uniwersytecka w Warszawie | 52.242643, 21.025068 | `warsaw_25_buw` |
| 26 | VISIT | The Supreme Court | Sąd Najwyższy | 52.249808, 21.005280 | `warsaw_26_sad_najwyzszy` |
| 27 | VISIT | Warszawa Ochota station | Warszawa Ochota | 52.225616, 20.990102 | `warsaw_27_warszawa_ochota` |
| 28 | VISIT | The Church of the Ascension, Ursynów | Kościół Wniebowstąpienia Pańskiego | 52.157667, 21.030359 | `warsaw_28_kosciol_wniebowstapienia_panskiego` |
| 29 | VISIT | Królikarnia | Pałac Królikarnia | 52.189025, 21.028370 | `warsaw_29_krolikarnia` |
| 30 | VISIT | The Polish Vodka Museum at Koneser | Muzeum Polskiej Wódki | 52.255393, 21.045988 | `warsaw_30_muzeum_polskiej_wodki` |
| 31 | VISIT | Fotoplastikon Warszawski | Fotoplastikon Warszawski | 52.228590, 21.008643 | `warsaw_31_fotoplastikon` |
| 32 | OBSERVE | The Old Town Market Square | Rynek Starego Miasta | 52.249795, 21.011799 | `warsaw_32_rynek_starego_miasta` |
| 33 | OBSERVE | Plac Konstytucji and the MDM | Plac Konstytucji | 52.221690, 21.016461 | `warsaw_33_plac_konstytucji` |
| 34 | OBSERVE | The Za Żelazną Bramą estate | Osiedle Za Żelazną Bramą | 52.238118, 20.999971 | `warsaw_34_za_zelazna_brama` |
| 35 | OBSERVE | Katowicka Street, Saska Kępa | Katowicka | 52.231889, 21.052497 | `warsaw_35_ulica_katowicka` |
| 36 | OBSERVE | The Vistula Boulevards | Bulwar Flotylli Wiślanej | 52.230966, 21.042417 | `warsaw_36_bulwary_wislane` |
| 37 | OBSERVE | Złota 44 | Złota 44 | 52.231214, 21.002445 | `warsaw_37_zlota_44` |

Coordinates are OpenStreetMap objects that carry each venue's own name, found by name with Nominatim and Photon on 2026-10-12. The ones that need care:
- **Za Żelazną Bramą** is a neighbourhood centroid.
- **Katowicka** is a street point.
- **Plac Konstytucji** is a road segment on the square.
- **Bulwar Flotylli Wiślanej** is one section of the boulevards.

`check-coordinates.py` has not been run on these points.

## 🔴 Corrections to the original city-guide listing (found during research)

| Venue | The guide said | The sources say |
|---|---|---|
| Pawilon Cepelii | sells folk craft | Restored and reopened in **December 2024 as an Empik bookshop**. Cepelia is gone; its neon cockerel remains. |
| Rozbrat 20 | natural-wine bar and bistro | **Fine dining**, chef Bartosz Szymczak, first Michelin star in 2024, with a serious Italian organic wine list |
| Muzeum Sztuki Nowoczesnej | opened 2023 | Opened to the public on **25 October 2024** |
| Fotoplastikon | a viewer from about 1905 | At this address **since 1946**, when it was already about fifty years old |
| Za Żelazną Bramą | prefabricated slab blocks | **Cast in place in monolithic concrete**, not large-panel prefab |
| Pawilony Nowy Świat | (implied 1950s–60s) | Built from **1972** as craftsmen's workshops; bars only from the late 1990s |
| Neon Muzeum | (Soho Factory) | Moved to the **4th floor of the Palace of Culture** on 1 August 2025 |

## Owed before recording
1. **Native pronunciation pass** on the TTS respellings below, especially Krakowskie Przedmieście, Marszałkowska, Kościół Wniebowstąpienia Pańskiego and Za Żelazną Bramą.
2. **Perishable claims to re-check on the day.** These are opening hours ("dinner only, Tuesday to Saturday" for 05 and 14), Rozbrat 20's Michelin star, the Pawilony lease, and the state of Bazar Różyckiego.
3. **Unverified, so deliberately left out of the scripts:** the opening years of Charlotte, Plan B and Kulturalna.

## Pronunciation (TTS respellings used)

| Written | Spoken |
|---|---|
| Adam Myjak | adam mee yak |
| Aleja Wyzwolenia | alaya viz vo len ya |
| Aleje Jerozolimskie | alayeh yeh ro zo leem skyeh |
| Alfred Tarski | alfred tarskee |
| Anda Rottenberg | anda rottenberg |
| Andrzej Chołdzyński | and zhay how jin skee |
| Andrzej Milewski | and zhay mee leff skee |
| Andrzej Skopiński | and zhay sko peen skee |
| APA Wojciechowski Architekci | ah pah ah voy cheh hoff skee arhee tekt chee |
| Arseniusz Romanowicz | ar sen yoosh roman ovich |
| Artibus | artibus |
| Augustus the Second | augustus the second |
| Bambino | bambeeno |
| bar mleczny | bar mlechni |
| Bar Mleczny Prasowy | bar mlechni prah sovi |
| Barss | barss |
| Bartosz Szymczak | bartosh shim chak |
| Bazar Różyckiego | bazar roo zhits kyeh go |
| Bernardo Bellotto | bernardo bellotto |
| Bez Gwiazdek | bez gvyaz dek |
| Beza Projekt | beza proyekt |
| Biblioteka Uniwersytecka w Warszawie | bib lyo teh ka oo nee ver si tets ka v var sha vyeh |
| Bogna Świątkowska | bog na shvyont koff ska |
| Bohdan Lachert | boh dan la hert |
| Budzyński | boo jin skee |
| Bulwar Flotylli Wiślanej | bool var flo til lee veesh la nay |
| bęc | bents |
| Bęc Zmiana | bents zmyana |
| Caffe Kafka | kaffay kafka |
| Carlo Thomatis | karlo tomatis |
| Cepelia | tseh pel ya |
| Charlotte | sharlot |
| Cubryna | tsoo bri na |
| Daniel Libeskind | daniel lee bes kind |
| Dekert | deh kert |
| Dobra | dobra |
| Domenico Merlini | domeneeko merleenee |
| Dunikowski | doo nee koff skee |
| Elektrownia Powiśle | elek trov nya po veesh leh |
| Eligiusz Niewiadomski | eh lee gyoosh nyeh vya dom skee |
| Emilii | emeelee |
| Empik | em pick |
| Enrico Marconi | enreeko markoni |
| Europejski | ehro pay skee |
| façade | fassahd |
| façades | fassahds |
| Feliks Stamm | feh leeks stamm |
| Fotoplastikon Warszawski | foto plasti kon var shaff skee |
| Gabriel Narutowicz | gabryel na roo to vich |
| Hala Koszyki | hala koshi kee |
| Hala Mirowska | hala mee roff ska |
| Henryk Oderfeld | hen rik oder feld |
| Hinc omnia | hink omnia |
| Hoser | hozer |
| Ignacy Jan Paderewski | ignatsi yan pah deh reff skee |
| Ilmari Lahdelma | eelmaree lah del ma |
| Ilona Karwińska | eelona kar veen ska |
| Irena Bajerska | eerena bah yer ska |
| Ius est ars boni et aequi | yoos est ars bonee et eye kwee |
| Jan Furman | yan foorman |
| Jan Karski | yan karskee |
| Jan Knothe | yan kno teh |
| Jan Łukasiewicz | yan woo ka shyeh vich |
| JEMS Architekci | jems arhee tekt chee |
| Jerzy Czyż | yeh zhi chish |
| Julian Różycki | yool yan roo zhits kee |
| Julita Wójcik | yoo leeta vooy cheek |
| Juliusz Dzierżanowski | yool yoosh jer zha noff skee |
| Justyna Burzyńska | yoo stina boo zhin ska |
| Józef Chudy | yoo zef hoo di |
| Józef Gosławski | yoo zef go swaff skee |
| Józef Sigalin | yoo zef see ga leen |
| Józef Szanajca | yoo zef sha nai tsa |
| Kamionek | ka myo nek |
| karminadle | kar mee nad leh |
| Karol Szymanowski | karol shi ma noff skee |
| Karowa | ka ro va |
| Katowice | ka to vee tseh |
| Katowicka | ka to veets ka |
| Kazimierz Twardowski | ka zhee myesh tvar doff skee |
| Koneser | ko neh ser |
| Konrad Sojka | konrad soy ka |
| Konstanty Hegel | kon stanti hegel |
| Koszyki | koshi kee |
| Koszykowa | koshi kova |
| Kołłątaj | ko won tai |
| Kościół Wniebowstąpienia Pańskiego | kosh choow vnyeh bof stom pyen ya pan skyeh go |
| Krakowskie Przedmieście | krakoff skyeh pshed myesh cheh |
| Kraków | krakoff |
| Krempa | krem pa |
| Krucza | kroo cha |
| Kruczkowskiego | krooch koff skyeh go |
| Krzysztof Kieślowski | kshish tof kyesh loff skee |
| Królikarnia | kroo lee kar nya |
| Kulturalna | kool too ral na |
| Lachert | la hert |
| Lech Wałęsa | lek va wen sa |
| Lev Rudnev | lyev rood nyev |
| Libeskind | lee bes kind |
| Lourse | loorss |
| Luksusowa | look soo so va |
| Lwowska | lvoff ska |
| Lwów | lvoof |
| Lwów–Warsaw | lvoof warsaw |
| Maciek Lebiedowicz | mah chek leh byeh do vich |
| Mamastudio | mama stoodio |
| Marek Budzyński | marek boo jin skee |
| Maria Jeglinska | marya yeh gleen ska |
| Marian Lalewicz | mar yan la leh vich |
| Marszałkowska | mar shaw koff ska |
| Mateusz Baumiller | mateh oosh bow miller |
| Maurizio Cattelan | mowritsyo kattelan |
| MDM | em dee em |
| Metropol | metro pol |
| Mikołaj Wojciechowski | mee ko wai voy cheh hoff skee |
| Mokotowska | mo ko toff ska |
| Mokotów | mo ko toof |
| Monika Sosnowska | monika sos noff ska |
| Muranów | moo ra noof |
| Muzeum Historii Żydów Polskich | moo zeh oom his tor yee zhi doof pol skeeh |
| Muzeum Neonów | moo zeh oom neh o noof |
| Muzeum Polskiej Wódki | moo zeh oom pol skyay vood kee |
| Muzeum Sztuki Nowoczesnej | moo zeh oom shtoo kee no vo ches nay |
| Narodowa Galeria Sztuki | na ro do va gal er ya shtoo kee |
| Narutowicz | na roo to vich |
| Nowogrodzka | no vo grots ka |
| Nowy Świat | novi shvyat |
| Nulla poena sine lege | noola poyna seeneh legeh |
| Oboźna | o bozh na |
| Ochota | o ho ta |
| Ogród BUW | o grood boov |
| Orbis | orbis |
| oscypek | oss tsi pek |
| Osiedle Za Żelazną Bramą | o shed leh za zheh laz nom bra mom |
| Paderewski | pah deh reff skee |
| Pan Tu Nie Stał | pan too nyeh stow |
| Pan tu nie stał | pan too nyeh stow |
| Pawilon Cepelii | pa vee lon tseh pel yee |
| Pawilony Nowy Świat | pa vee loni novi shvyat |
| Pałac Królikarnia | pa wats kroo lee kar nya |
| Pałac Kultury i Nauki | pa wats kool too ri ee now kee |
| Phifer | fifer |
| pierogi | pyeh rogee |
| Piotr Szymaniak | pyotr shi man yak |
| Piotr Wicha | pyotr vee ha |
| Plac Defilad | plats deh fee lad |
| Plac Konesera | plats ko neh seh ra |
| Plac Konstytucji | plats kon sti toots yee |
| Plac Krasińskich | plats kra sheen skeeh |
| Plac Małachowskiego | plats ma wa hoff skyeh go |
| Plac Mirowski | plats mee roff skee |
| Plac Zawiszy | plats za vee shi |
| Plac Zbawiciela | plats zbah vee cheh la |
| Plater | plater |
| Po lin | po leen |
| Podhale | pod ha leh |
| POLIN | po leen |
| Polin | po leen |
| Poniatowski | pon ya toff skee |
| Powiśle | po veesh leh |
| Praesens | pray sens |
| Praga | praga |
| Prasowy | prah sovi |
| pyzy | pi zi |
| Rainer Mahlamäki | rainer mah la mah kee |
| Robert Trzópek | robert tshoo pek |
| Romanowicz | roman ovich |
| Rozbrat | roz brat |
| Rozbrat 20 | roz brat twenty |
| RS Architektura Krajobrazu | ar es arhee tek too ra kra yo bra zoo |
| Rynek Starego Miasta | rinek sta reh go myasta |
| Różycki | roo zhits kee |
| Saska Kępa | sas ka kem pa |
| Segiet Oniszh | seg yet onish |
| Skłodowska-Curie | skwo doff ska kyooree |
| Spodek | spo dek |
| Stadion | stad yon |
| Stanisław August | stah nee swaff owgoost |
| Stanisław Barylski | stah nee swaff ba ril skee |
| Stanisław Jankowski | stah nee swaff yan koff skee |
| Stanisław Kucharski | stah nee swaff koo har skee |
| Stanisław Leśniewski | stah nee swaff lesh nyeff skee |
| Stanisław Skibniewski | stah nee swaff skeeb nyeff skee |
| Stefan Szyller | stefan shiller |
| Syrenka | si ren ka |
| Szanghaj | shang hai |
| Szymon and Helena Syrkus | shi mon and helena sir koos |
| Sąd Najwyższy | sont nai vizh shi |
| Tadeusz Kantor | tadeh oosh kantor |
| Tadeusz Kościuszko | tadeh oosh kosh choosh ko |
| Targowa | tar go va |
| Teatr Dramatyczny | teh atr dra ma titch ni |
| Thomas Phifer | thomas fifer |
| Tom Aikens | tom aykens |
| Towarowa | to va ro va |
| TR Warszawa | tee ar var sha va |
| Ultralight | ultra light |
| UNESCO | yoo nesko |
| Ursynów | oor si noof |
| Vicenza | vee chen tsa |
| Wacław Zalewski | vats waff za leff skee |
| Warszawa Ochota | var sha va o ho ta |
| Warszawa Powiśle | var sha va po veesh leh |
| Warszawa Skarpa | var sha va skar pa |
| Wilhelm Sasnal | vilhelm sasnal |
| Witold Wołodkiewicz | veetold vo wod kyeh vich |
| Wiślana | veesh lana |
| Wschodnia | fs hod nya |
| Wyborowa | vi bo ro va |
| Władysław | vwa dis waff |
| Włodzimierz Gall | vwo jee myesh gall |
| Xawery Dunikowski | ksa veh ri doo nee koff skee |
| Za Żelazną Bramą | za zheh laz nom bra mom |
| Zachęta | za hen ta |
| Zakrzewski | za kshef skee |
| Zamość | za moshch |
| Zbigniew Badowski | zbeeg nyeff ba doff skee |
| zmiana | zmyana |
| Zygmunt Otto | zig moont otto |
| Zygmunt Stępiński | zig moont stem peen skee |
| Ząbkowska | zomb koff ska |
| Złota | zwo ta |
| Złota 44 | zwo ta forty four |
| Łódź | wootch |
| Śródmieście | shrood myesh cheh |
| Żagiel | zha gyel |
| Żubrówka | zhoo broof ka |

## Images (picked 2026-10-18)

The owner picked these in the [Warsaw Image Picks](https://claude.ai/artifact/QGGnecrEVZRKg6mGgk4N7J) page. They are 24 photos for 9 tours, all from Unsplash or Pexels. Neither licence requires a credit line.

Each file was cropped from a full-size (2400 px) original to 1200 × 900 WebP, and none had to be enlarged. They are staged in `images/`, **not yet on gh-pages**. Upload them only when the tours are wired into `Tours.json`, then run `check-image-duplicates.py --maker <CODE>`. The filenames use the tour slugs from the index above, and none clashes with an existing gh-pages file (checked 2026-10-18).

⚠️ **The Gemini gates were NOT run.** The key supplied was a Cloud project name, not an API key. Every photo was identified by eye instead, and checked against its source caption. That review rejected look-alikes from Bucharest, Bratislava, Mysuru, Jabłonna and Poissy.

**28 tours still have no image.** Wikimedia Commons, and Openverse (which fetches from it), returned 429 to every request from the cloud session. A session with Commons access, or owner or venue photos, is needed for those tours.

| Tour | File | Role | Licence | Photographer | Source |
|---|---|---|---|---|---|
| 02 hotel-bristol | `hotel-bristol_hero.webp` | hero | Unsplash | flickch | <https://unsplash.com/photos/elegant-illuminated-building-at-night-with-street-and-parked-cars-h1xPyeW9Nqs> |
| 18 hala-mirowska | `hala-mirowska_hero.webp` | hero | Pexels | MART  PRODUCTION | <https://www.pexels.com/photo/brown-building-with-arched-windows-7316948/> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_hero.webp` | hero | Unsplash | Valentyn Chernetskyi | <https://unsplash.com/photos/high-rise-building-beside-park-D7fPbwGQMHY> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_2.webp` | gallery 1 | Pexels | Julia Filirovska | <https://www.pexels.com/photo/the-facade-of-the-palace-of-culture-and-science-8259171/> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_3.webp` | gallery 2 | Unsplash | JEREMY MALECKI | <https://unsplash.com/photos/gray-concrete-building-under-white-clouds-during-daytime-sF7ClFY47yM> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_4.webp` | gallery 3 | Unsplash | Paweł Malinowski | <https://unsplash.com/photos/a-view-of-a-large-city-with-tall-buildings-UwfHpAg_A6w> |
| 20 palac-kultury-i-nauki | `palac-kultury-i-nauki_5.webp` | gallery 4 | Pexels | Memory Lane | <https://www.pexels.com/photo/night-view-of-palace-of-culture-and-science-in-warsaw-35119863/> |
| 22 muzeum-sztuki-nowoczesnej | `muzeum-sztuki-nowoczesnej_hero.webp` | hero | Unsplash | Mathis Mauprivez | <https://unsplash.com/photos/an-aerial-view-of-a-building-in-a-city-S1W2Bf81qoE> |
| 25 buw | `buw_hero.webp` | hero | Pexels | Bogdan Krupin | <https://www.pexels.com/photo/flowerbeds-at-warsaw-university-library-garden-12028385/> |
| 25 buw | `buw_2.webp` | gallery 1 | Pexels | Anastasiia Lopushynska | <https://www.pexels.com/photo/warsaw-university-library-building-with-plants-growing-on-walls-12022296/> |
| 25 buw | `buw_3.webp` | gallery 2 | Pexels | Thomas Renaud | <https://www.pexels.com/photo/green-rooftop-walkway-in-warsaw-botanical-garden-35792463/> |
| 25 buw | `buw_4.webp` | gallery 3 | Pexels | vilnis Izotovs | <https://www.pexels.com/photo/drone-shot-of-house-roofs-and-green-grass-6054755/> |
| 26 sad-najwyzszy | `sad-najwyzszy_hero.webp` | hero | Unsplash | Nikolai Kolosov | <https://unsplash.com/photos/modern-building-with-a-large-stone-sculpture-outside-m11GGxMpsXs> |
| 26 sad-najwyzszy | `sad-najwyzszy_2.webp` | gallery 1 | Pexels | MART  PRODUCTION | <https://www.pexels.com/photo/a-historical-monument-in-front-of-a-building-7316991/> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_hero.webp` | hero | Unsplash | Maksym Harbar | <https://unsplash.com/photos/people-walking-near-multicolored-building-okn8ZIjPMxI> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_2.webp` | gallery 1 | Unsplash | Federico Mata | <https://unsplash.com/photos/the-mermaid-of-warsaw-statue-stands-in-the-city-center-LJ4pJtkMTzU> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_3.webp` | gallery 2 | Unsplash | Sam | <https://unsplash.com/photos/a-group-of-people-walking-down-a-street-next-to-tall-buildings-WvNvTf5fb-k> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_4.webp` | gallery 3 | Pexels | Egor Komarov | <https://www.pexels.com/photo/old-town-in-warsaw-17741460/> |
| 32 rynek-starego-miasta | `rynek-starego-miasta_5.webp` | gallery 4 | Pexels | Lesław Dzik | <https://www.pexels.com/photo/old-town-market-square-during-daytime-7115502/> |
| 36 bulwary-wislane | `bulwary-wislane_hero.webp` | hero | Pexels | Wojciech Wyszkowski | <https://www.pexels.com/photo/aerial-view-of-swietokrzyski-bridge-warsaw-poland-38487655/> |
| 36 bulwary-wislane | `bulwary-wislane_2.webp` | gallery 1 | Pexels | Radek Przybyłek | <https://www.pexels.com/photo/panoramic-view-of-warsaw-s-urban-skyline-31479746/> |
| 36 bulwary-wislane | `bulwary-wislane_3.webp` | gallery 2 | Pexels | Oleksiy Yeshtokyn,🌻🇺🇦🌻 | <https://www.pexels.com/photo/warsaw-s-national-stadium-and-vistula-river-view-38094410/> |
| 37 zlota-44 | `zlota-44_hero.webp` | hero | Pexels | urtimud.89 | <https://www.pexels.com/photo/aerial-view-warsaw-downtown-poland-18261856/> |
| 37 zlota-44 | `zlota-44_2.webp` | gallery 1 | Pexels | Wojciech Wyszkowski | <https://www.pexels.com/photo/modern-aerial-view-of-warsaw-s-skyline-38487664/> |
