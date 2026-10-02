# Image credits — attribution ledger

Master list of every staged image that carries an attribution obligation (CC BY /
CC BY-SA). **These MUST be surfaced before the images ship live** — Atlas has no
attribution UI today, so per the standing PD-only policy these were owner-approved
only where no PD/CC0 version of the exact subject existed. Options at ship time:
a per-tour credits line, an in-app attributions screen, or swap for owner-supplied
shots. Everything NOT listed here is ship-safe (Unsplash/Pexels/Pixabay — no
attribution) or owner-supplied.

Last updated 2026-07-29 (🇺🇸 Chicago batch 1 staging in progress — 2 CC images so far; all 4 audit failures closed: both live images replaced with owner-supplied photographs; Berlin attributions re-verified by SHA-1 and 9 rows corrected; Dubai staged — 11 CC images).

> ### ⚠️ Ledger audit, 2026-07-28 — read this before relying on any row
>
> Every row in this file was machine-checked: the published `gh-pages` image was compared
> against the Commons file the row names. **115 rows checked, 111 verified, 4 failed.** The
> original attributions were gathered by matching image *dimensions* against a Commons
> category listing, which silently picks the wrong file whenever two images in a category
> share a size. **Attribute by SHA-1 instead** — hash the local original and query
> `list=allimages&aisha1=<sha1>`; that is exact file identity, not a guess.
>
> **Update 2026-07-29: all four are now closed** — the two live ones were replaced with
> owner-supplied photographs (no attribution owed), and the two Berlin ones are corrected or
> scoped below. The four failures, as found:
>
> 1. **`waterlooplein-rembrandt-house_hero.webp` (Amsterdam — LIVE).** The row claimed
>    Usernet123u / CC BY-SA 4.0 via `File:Europe 1979's 03.jpg`. Side-by-side, that is a
>    *different photograph* of the same building (a 1979 close-up of the doorway vs. the
>    published wide facade shot). No Commons file in the Rembrandt House / Jodenbreestraat
>    categories matches the published image, which points to **ship-safe stock** — i.e. the
>    row was asserting an obligation that probably does not exist. **Re-confirm provenance;
>    the current credit line is wrong either way.**
> 2. **`testaccio_hero.webp` (Rome — LIVE).** The image was **overwritten** at the Rome-extras
>    wire-in (the tracker records this). The row below still describes the *superseded*
>    picture (Tyler Bell / CC BY 2.0), not what is shipping. **Re-confirm the current image's
>    provenance.** General lesson: overwriting a published filename silently invalidates its
>    credit row — update the ledger in the same commit.
> 3. **`ghostline_stop4.webp` + `ghostline_hero.webp` (Berlin — staged, not live).** The named
>    file is a different photograph of the same stretch of Wall. The fetch log recorded this
>    candidate as **CC0**, so the real obligation is probably *none*, but the exact file is
>    unidentified. **Re-verify or re-source before Berlin ships.**
> 4. **`kollwitzplatz_2.webp` (Berlin — staged).** Off by two frames in the same photo series;
>    author and licence were always right and it is public domain. **Corrected below.**

## Rome — 6 credit-required images (`drafts/rome-batch1`)

Everything else in the Rome batch is ship-safe (Unsplash/Pexels/Pixabay) or owner-pasted.
New maker **Atlas Studio ROM** 🇮🇹 at wire-in.

| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `ara-pacis_hero.webp` | Ara Pacis museum (dusk) | Palickap | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Roma,_Museo_dell%27Ara_Pacis.jpg |
| `ara-pacis_2.webp` | Ara Pacis altar (interior) | Joel Bellviure | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Ara_Pacis,_general.jpg |
| `ara-pacis_3.webp` | Mausoleum of Augustus | Attila (Flickr) | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Dscn1097_(53662807386).jpg |
| `piazza-barberini_2.webp` | Triton Fountain | Chabe01 | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Fontaine_Triton_-_Rome_(IT62)_-_2021-08-30_-_5.jpg |
| `piazza-barberini_3.webp` | Fountain of the Bees | babizhet | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:%D0%A4%D0%BE%D0%BD%D1%82%D0%B0%D0%BD_%D0%B1%D0%B4%D0%B6%D1%96%D0%BB_%D0%A0%D0%B8%D0%BC.JPG |
| ~~`testaccio_hero.webp`~~ | Monte Testaccio (hill of shards) | — | **owner-supplied, no credit owed** | ✅ **REPLACED 2026-07-29** — row retired |

_(Piazza Barberini `_hero`, Baths of Caracalla, Jewish Ghetto, Santa Maria in Trastevere, and
Bocca della Verità's Cosmedin shot are owner-pasted → ship-safe. The `testaccio_hero` is also the
Testaccio stop image in the Aventine & Testaccio walk.)_

## Toronto — 17 credit-required images

### Hockey Hall of Fame (single-stop, `drafts/toronto-batch2`)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `hockey-hall-of-fame_2.webp` | NHL Zone (interior) | Christopher Amrich | CC BY-SA 2.0 | Wikimedia Commons |
| `hockey-hall-of-fame_4.webp` | goalie-mask exhibit | Christopher Amrich | CC BY-SA 2.0 | Wikimedia Commons |
| _(hockey-hall-of-fame_3 / IN1 is CC0 — no credit; hero HH6 is ship-safe)_ | | | | |

### Queen Street West (single-stop, `drafts/toronto-batch7`)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `queen-street-west_hero.webp` | The Drake Hotel | SimonP | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Drake_Hotel.jpg |
| _(also reused as stop 5 of the Immigrant West/Kensington walk — same credit)_ | | | | |

### Trinity Bellwoods (single-stop, `drafts/toronto-batch7`)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `trinity-bellwoods_hero.webp` | the gates (Queen & Strachan) | SimonP | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Trinity_Bellwoods_Gates.jpg |
| `trinity-bellwoods_2.webp` | cherry blossom | Canmenwalker | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:Trinity_Bellwoods_Park_Cherry_blossom_2022.jpg |
| `trinity-bellwoods_3.webp` | CN Tower from the park | Haaron755 | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:CN_Tower_DSCN4373.JPG |

### Yorkville / Mink Mile (single-stop, `drafts/toronto-batch8`)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `yorkville_hero.webp` | Cumberland Street | Enoch Leung | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Cumberland_Street,_Yorkville_(32676257228).jpg |
| _(yorkville_2 boulder is owner-supplied — no credit)_ | | | | |

### Aga Khan Museum (single-stop, `drafts/toronto-batch8`) — all 6 CC-licensed
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `aga-khan-museum_hero.webp` | building + reflecting pool | Canmenwalker | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:Aga_Khan_Museum_2022.jpg |
| `aga-khan-museum_2.webp` | inner courtyard | Canmenwalker | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:Aga_Khan_Museum_Courtyard.jpg |
| `aga-khan-museum_3.webp` | night / char-bagh garden | Faisal Anwar | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:01SensoryGardenCharBagh.jpg |
| `aga-khan-museum_4.webp` | exterior + name | JohnOyston | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Aga_Khan_Museum_in_Toronto-_Exterior.jpg |
| `aga-khan-museum_5.webp` | lobby / atrium | Canmenwalker | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:Aga_Khan_Museum_Lobby_2022.jpg |
| `aga-khan-museum_6.webp` | gallery of Islamic art | Canmenwalker | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:Aga_Khan_Museum_Exhibit_2022.jpg |

### Bata Shoe Museum (single-stop, `drafts/toronto-batch10`; also Museum Mile walk stop 2)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `bata-shoe-museum_hero.webp` | shoebox building (BT26) | Jim.henderson | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:Bata_Museum_WCNA_2023_(13).jpg |
| `bata-shoe-museum_2.webp` | shoebox angle (BT25) | Jim.henderson | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:Bata_Museum_WCNA_2023_(12).jpg |
| `bata-shoe-museum_3.webp` | + red shoe banner (BT31) | Eberhard J. Wormer | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Bata_Shoe_Museum_2.jpg |
| `bata-shoe-museum_6.webp` | museum sign (BT28) | Larry Koester | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Bata_Shoe_Museum_(4)_(22934136099).jpg |
| _(bata-shoe-museum_4 clog wall + _5 mukluks are ship-safe Pexels — no credit)_ | | | | |
| _(Gardiner Museum, batch 10, is hero-only + owner-supplied — no credit)_ | | | | |

### Los Angeles (batches 1–8, `drafts/la-batch1..8`)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `walt-disney-concert-hall_6.webp` | the "french-fry organ" (WD53) | Daniel Hartwig | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Disney_Concert_Hall_(10920404614).jpg |
| `la-brea-tar-pits_hero.webp` | La Brea Lake Pit + mammoth family (W8) | Downtowngal | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:La_Brea_Tar_Pits_January_2021.jpg |
| `moca-grand-avenue_hero.webp` | MOCA Grand Ave entrance (M32) | Minnaert | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:MOCA_LA_04.jpg |
| `moca-grand-avenue_2.webp` | Nancy Rubins sculpture on red wall (M28) | vasse nicolas, antoine | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:2013-07-26_MOCA_Los_Angeles_Nancy_Rubins.jpg |
| `moca-grand-avenue_3.webp` | MOCA building + plaza + sculpture (M31) | Dietmar Rabich | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Los_Angeles_(California,_USA),_South_Olive_Street_--_2012_--_8.jpg |
| _(batch 1: Disney concert room WD67 = CC0; Chinese Theatre CT38 + The Broad TB240 = PD/CC0; El Pueblo 09 = owner-supplied; all other batch-1 picks = Unsplash/Pexels — no credit.)_ | | | | |
| _(batch 2: Griffith 24 + Santa Monica 28 = Unsplash/Pexels — no credit. La Brea 20 is hero-only. LACMA 19 hero = owner-supplied Geffen photos, gallery L25/L27 = Pexels — no credit.)_ | | | | |
| `academy-museum_4.webp` | Academy Museum sphere + May Co. bldg (Y40) | _to confirm_ | CC BY-SA 4.0 | Wikimedia Commons (author TBD at ship) |
| `greek-theatre_3.webp` | Greek Theatre seating/stage (RG3) | User:Godfinger | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Greek_Theater_2007.JPG |
| `greek-theatre_4.webp` | Greek Theatre night concert (RG1) | Amhernandez8754 | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:The_Greek_Theatre.jpg |
| _(batch 3: Angels Flight 05 + Bradbury 06 + City Hall 07 = Unsplash/Pexels — no credit. MOCA 03 = all 3 CC-licensed, above.)_ | | | | |
| _(batch 4: Little Tokyo 10 + Last Bookstore 11 + Dolby 14 + Capitol 16 = all ship-safe/PD/owner — no credit.)_ | | | | |
| _(batch 5: Academy 21 gallery Y40 + Griffith/Greek 25 gallery RG3/RG1 = credit-required, above. Petersen 22 + Third St Promenade 29 = ship-safe/owner — no credit.)_ | | | | |
| _(batch 6: Venice Boardwalk 30 + Venice Canals 31 + Science Center/Endeavour 34 + NHM 35 = all ship-safe (Unsplash/Pexels) — no credit.)_ | | | | |
| `the-huntington_hero.webp` | Huntington Art Gallery front facade (UW2) | Matthew Field (Mfield) | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Huntington_art_gallery_at_huntington_library_california.jpg |
| `gamble-house_hero.webp` | Gamble House front elevation (DW20) | Cullen328 | CC BY-SA 3.0 | Wikimedia Commons |
| `gamble-house_2.webp` | Gamble House (DW8) | Codera23 | CC BY-SA 4.0 | Wikimedia Commons |
| `gamble-house_3.webp` | Gamble House (DW7) | Cullen328 | CC BY-SA 3.0 | Wikimedia Commons |
| _(batch 7: Coliseum 36 + Old Pasadena 41 = ship-safe (Pexels/Unsplash) — no credit. The Huntington 39 gallery U6/U9/U8 = Unsplash — no credit; hero above. Gamble House 40 `_4` = Mattnad PD — no credit; hero/`_2`/`_3` above.)_ | | | | |
| `egyptian-theatre_2.webp` | Egyptian Theatre palm forecourt (E14) | Andreas Praefcke | CC BY 3.0 | https://commons.wikimedia.org/wiki/File:Egyptian_Theatre_Hollywood_3.jpg |
| `egyptian-theatre_3.webp` | Egyptian Theatre forecourt at night (E3) | Pop Culture Geek (The Conmunity) | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Clone_Wars_screening_-_Egyptian_theater_entryway_(5240103221).jpg |
| `egyptian-theatre_4.webp` | Egyptian Theatre interior auditorium (E23) | Gb321 | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:Grauman%27s_Egyptian_interior_2026.jpg |
| `farmers-market-grove_2.webp` | Original Farmers Market clock tower (WF1) | Infernalfox (English Wikipedia) | CC BY 2.5 | https://commons.wikimedia.org/wiki/File:Farmer%27s_Market_2.jpg |
| `farmers-market-grove_4.webp` | The Grove green double-decker trolley (WG1) | Clotee Pridgen Allochuku | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:%22The_Grove%22_Street_Car_-_panoramio.jpg |
| _(batch 8: Getty 43 + Rodeo 44 = ship-safe — no credit. Egyptian 18 HERO = owner photo, gallery `_2`/`_3`/`_4` above. Farmers Market/Grove 23 hero F1 + `_3` F27 + `_5` GR16 = ship-safe — no credit; `_2`/`_4` above.)_ | | | | |

## Amsterdam — 7 credit-required images (batch 1, `drafts/amsterdam-batch1`)

Stock (Unsplash/Pexels/Pixabay) coverage was too polluted for the Oude Kerk (Delft's
Oude Kerk, look-alike churches) and the Begijnhof (Belgian beguinages), so those two
tours use Wikimedia-verified shots — all CC-licensed, logged here. **Dam Square & Royal
Palace and De Wallen are entirely ship-safe stock — no credit.**

### Oude Kerk (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `oude-kerk_hero.webp` | church exterior + tower from the square | jimmyweee | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_(6578772447).jpg |
| `oude-kerk_2.webp` | brick Gothic exterior | thierrytutin | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_(4093683725).jpg |
| `oude-kerk_3.webp` | interior — wooden vault + gravestone floor | Johan Bakker | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:3990_Oude_Kerk_(2).jpg |

### Begijnhof (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `begijnhof_hero.webp` | courtyard + statue, lawn + gabled houses | Sergey Galyonkin (Berlin) | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_(8697235291).jpg |
| `begijnhof_2.webp` | courtyard + weeping tree | Szilas | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:2019-06-21_Amsterdam_03.jpg |
| `begijnhof_3.webp` | courtyard lawn + gabled houses | thierrytutin | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_(4095056424).jpg |
| `begijnhof_4.webp` | gabled house facade detail | Fred Romero (Paris) | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_-_Begijnhof_(30183600072).jpg |

### Anne Frank House (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `anne-frank-house_hero.webp` | the house + museum entrance, Prinsengracht | Dietmar Rabich | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_(NL),_Anne-Frank-Huis_--_2015_--_7185.jpg |

### Westerkerk (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `westerkerk_3.webp` | interior — nave + whitewashed vault | Zairon | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_Westerkerk_Innen_Gew%C3%B6lbe.jpg |
| `westerkerk_4.webp` | wide interior + organ | rene boulay | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_Wester_Kerk_Nef_-_panoramio_(1).jpg |
| _(hero WK34 + `_2` WK11 tower+crown = ship-safe stock — no credit)_ | | | | |

### Our Lord in the Attic (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `our-lord-in-the-attic_hero.webp` | the hidden attic church + altar | Remi Mathis | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:AMsterdam_-_Museum_Ons%27_Lieve_Heer_op_Solder_-_the_hidden_church.JPG |
| `our-lord-in-the-attic_2.webp` | attic church — pews + galleries | Remi Mathis | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_-_Museum_Ons%27_Lieve_Heer_op_Solder_-_church_floor.JPG |

### Nieuwmarkt / De Waag (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `nieuwmarkt-de-waag_3.webp` | De Waag + market stalls | Shadowgate (Novara, IT) | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_(16033384506).jpg |
| _(hero WG7 + `_2` WG10 = ship-safe stock — no credit)_ | | | | |

### Homomonument (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `homomonument_hero.webp` | water triangle + flowers + visitor | User:Vmenkov | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_-_Homomonument_-_CIMG0484.JPG |
| `homomonument_2.webp` | granite triangle stepping to water | La Sequencia (Evanston, IL) | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Amsterdam-Homomonument-05.jpg |
| _(`_3` HM47 quay sign = Hnapel, **CC0** — no credit. ⚠️ HM52 rejected: it was the Madurodam scale-model, not the real monument.)_ | | | | |

### Noordermarkt / Brouwersgracht (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `noordermarkt-brouwersgracht_hero.webp` | Noorderkerk + square | Arianit Dobroshi | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:ArianitAmsterdam17.jpg |
| `noordermarkt-brouwersgracht_2.webp` | Brouwersgracht warehouses + houseboats | Shadowgate (Novara, IT) | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Amsterdam(tcaq)_(16059579475).jpg |

_(Muntplein/Munttoren, Museumplein/Concertgebouw, Stedelijk = ship-safe stock, no credit.)_

### Waterlooplein / Rembrandt House (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| ~~`waterlooplein-rembrandt-house_hero.webp`~~ | Rembrandt House front facade | — | **owner-supplied, no credit owed** | ✅ **REPLACED 2026-07-29** — row retired |

### Portuguese Synagogue (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `portuguese-synagogue_hero.webp` | Esnoga exterior (J.D. Meijerplein) | A. Bakker | CC BY 3.0 | https://commons.wikimedia.org/wiki/File:Amsterdam_-_Synagoge_J.D._Meijerplein.JPG |

### National Holocaust Names Monument (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `names-monument_hero.webp` | monument wall + "Namenmonument" | Ceescamel | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:2022_Holocaust_Namenmonument,_Asd_(01).jpg |
| `names-monument_2.webp` | brick name-walls + mirrored steel | Ceescamel | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:2022_Holocaust_Namenmonument,_Asd_(03).jpg |

### Hollandsche Schouwburg / Holocaust Museum (single-stop) — **Public Domain, NO credit**
_(hero facade + `_2` relief both by Andreas Praefcke, released Public Domain.)_

_(Ship-safe stock, NO credit: Hortus Botanicus ×4, EYE/A'DAM/Ferries ×4, Waterlooplein flea-market gallery.)_

### Nieuwe Kerk (single-stop) — **owner-supplied, NO credit**
_(hero exterior + `_2` interior both supplied by the owner inline; not CC.)_

_(Ship-safe stock, NO credit: Dam Square & Royal Palace hero+4, De Wallen hero+5, Canal Ring / Golden Bend hero+5, Nine Streets hero+5, Westerkerk hero+`_2`, Jordaan hero+2, Rijksmuseum hero+3, Van Gogh Museum hero+2, Vondelpark hero+2, De Pijp / Albert Cuyp hero+4 — DP `_5` is Wikimedia **CC0**, still no credit.)_

## Montreal — 10 credit-required images (batch 1, `drafts/montreal-batch1`)

Maker at wire-in: **Atlas Studio YUL** 🇨🇦. Old Montreal, 5 single-stop tours. Notre-Dame + Old Port
heroes/galleries are ship-safe stock (Unsplash/Pexels — NO credit). The three Wikimedia-sourced
subjects below carry CC credit (two picks within them are CC0/PD — noted, no credit).

### Place Jacques-Cartier / City Hall (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `place-jacques-cartier-city-hall_hero.webp` | Nelson's Column + square | Jean Gagnon | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Monument_Nelson_Montreal_01.jpg |
| `place-jacques-cartier-city-hall_3.webp` | City Hall from the street | eugene_o | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:20190515_-_Montreal_-_1_(48285153032).jpg |
| `place-jacques-cartier-city-hall_4.webp` | City Hall front + balcony | Diego Delso | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Ayuntamiento_de_Montreal,_Montreal,_Canad%C3%A1,_2017-08-11,_DD_11.jpg |

_(`place-jacques-cartier-city-hall_2.webp` = Nelson's Column at sunset, Wilfredor, **CC0** — no credit.)_

### Pointe-à-Callière (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `pointe-a-calliere_hero.webp` | Éperon museum building | Jeangagnon | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Eperon_-_Pointe-a-Calliere_10.JPG |
| `pointe-a-calliere_2.webp` | Éperon museum, side | Jeangagnon | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Eperon_-_Pointe-a-Calliere_08.JPG |
| `pointe-a-calliere_3.webp` | buried Saint-Pierre river tunnel | Nicolas Leboeuf | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Igp_(224278719).jpeg |
| `pointe-a-calliere_4.webp` | excavated foundations under glass | Jeangagnon | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Pointe-a-Calliere_-_001.jpg |

### Bonsecours Market + chapel (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `bonsecours-market-chapel_hero.webp` | market across the water | Jiaqian AirplaneFan | CC BY 3.0 | https://commons.wikimedia.org/wiki/File:Bonsecours_Market_-_panoramio.jpg |
| `bonsecours-market-chapel_3.webp` | Bon-Secours chapel tower at night | Jazmin Million | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Chapelle_Notre-Dame-de-Bon-Secours_-_Mus%C3%A9e_Marguerite-Bourgeoys.jpg |
| `bonsecours-market-chapel_4.webp` | Bon-Secours chapel spire, Rue Saint-Paul | Jean Gagnon | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Chapelle_Notre-Dame-de-Bon-Secours_12.JPG |

_(`bonsecours-market-chapel_2.webp` = silver dome close, Daderot, **Public Domain** — no credit.)_
_(Ship-safe stock, NO credit: Notre-Dame Basilica hero+4, Old Port hero+4.)_

## Montreal — batch 2 (`06`–`09`, 5 credit-required images)

Same maker (**Atlas Studio YUL** 🇨🇦). Habitat 67 = ship-safe Unsplash (NO credit). The three re-sourced
Wikimedia subjects below carry CC credit; two picks within McGill are CC0 (noted, no credit).

### Château Ramezay (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `chateau-ramezay_hero.webp` | fieldstone facade, Rue Notre-Dame | Jean Gagnon | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Chateau_Ramezay_02.jpg |
| `chateau-ramezay_2.webp` | house + Governor's Garden | Jean Gagnon | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Chateau_Ramezay_04.jpg |

### McGill / Golden Square Mile (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `mcgill-golden-square-mile_2.webp` | Roddick Gates | Jeangagnon | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Portail_Roddick_02.jpg |

_(`mcgill-golden-square-mile_hero.webp` = Roddick Gates, D. Benjamin Miller, **CC0** — no credit. `mcgill-golden-square-mile_3.webp` = Arts Building tower, D. Benjamin Miller, **CC0** — no credit.)_

### Christ Church Cathedral (single-stop)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `christ-church-cathedral_hero.webp` | Gothic church + glass tower | Diego Delso | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Catedral_iglesia_de_Cristo,_Montreal,_Canad%C3%A1,_2017-08-11,_DD_42.jpg |
| `christ-church-cathedral_2.webp` | spire / facade | ActuaLitté | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Christ_Church_Cathedral_(37829695634).jpg |

_(Ship-safe stock, NO credit: Habitat 67 hero + `_2`–`_6` (all Unsplash).)_

## Montreal — batch 3 (`10`–`31`, 16 single-stop tours) + Mount Royal walk — 4 credit-required images

Same maker (**Atlas Studio YUL** 🇨🇦). Batch 3 is **almost entirely ship-safe** (owner-supplied
heroes + Unsplash/Pexels) — only the two Wikimedia picks below need credit. Owner-supplied
(pasted, ship-safe, no credit): Mary Queen exterior, Place Ville Marie esplanade, Plateau
(Square-St-Louis Victorians), The Main (Schwartz's + boulevard).

### Batch-3 singles (2 credit-required)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `jean-talon-market_2.webp` | market street + red chairs | Andre Carrotflower | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:20181014_-_23_-_Montreal_(Little_Italy).jpg |
| `atwater-market_hero.webp` | Art Deco building + clock tower | Colin Rose | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:AtwaterMarket.jpg |

_(All other batch-3 single heroes/galleries = ship-safe (owner / Unsplash / Pexels), no credit. Pending galleries not yet cropped: Mary interiors (Wikimedia CC — will log at pick), PVM, Square Saint-Louis, The Main.)_

### Mount Royal walk (2 credit-required — the 3 new images)
| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `mount-royal-trail_hero.webp` | forest path (walk entrance) | Matias Garabedian | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Au_bonheur_de_l%27automne_au_parc_Mont-Royal_(15341849438).jpg |
| `mount-royal-trail_2.webp` | staircase (walk climb) | Yanik Crépeau | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Golden_Square_Mile,_Montreal,_QC,_Canada_-_panoramio_(14).jpg |

_(`mount-royal-cross_hero.webp` = the Cross, Unsplash, **ship-safe**, no credit. Belvedere stop reuses the ship-safe single-stop hero.)_

## Montreal multi-stop walks (4) — credits mostly inherited
- **Old Montreal** (5 stops), **Plateau & Mile End** (4), **Downtown / Underground City** (4) — reuse single-stop heroes; credits (if any) already listed above (e.g. Jean-Talon isn't in these walks; The Main/Square SL heroes are owner ship-safe). **No new credits.**
- **Mount Royal** (4 stops) — adds the 2 CC-credited trail images above + the ship-safe Cross.

## Multi-stop walks — credits are inherited, not new
The four Toronto walks (Old Town, Downtown Spine, Museum Mile, Immigrant West/Kensington)
reuse single-stop stop images. Only two carry a credit, both already listed above:
- **Museum Mile** → Bata Shoe Museum (`bata-shoe-museum_hero` = BT26, Jim.henderson, CC BY 4.0).
- **Immigrant West/Kensington** → Queen West stop = the Drake Hotel (`queen-street-west_hero`, SimonP, CC BY-SA 3.0).
- Downtown Spine + Old Town = **no credits** (all stop images ship-safe/owner; e.g. the Downtown Spine Hockey Hall stop uses the ship-safe HH6 exterior, not the CC BY-SA interiors).

## All other cities — audited 2026-06-30 (already credited at their own staging)

Audit result: **every other city was credited at build time** in its own per-city
`IMAGE-CREDITS-*.txt` file. Those files are the **authoritative, file-by-file
ledgers** (each row: filename → license → author/source URL) and they live on the
**`gh-pages` branch root** (not in this code branch), because that's where the images
they describe are hosted. This section is the index + summary; consult the named file
for the exact per-image list.

| City | Authoritative credit file (on `gh-pages`) | Credit-required images (CC BY / CC BY-SA) |
|------|-------------------------------------------|-------------------------------------------|
| **Toronto** | *this file* (`drafts/CREDITS.md`) | 17 (listed above) |
| **Los Angeles** | *this file* (below) | 17 so far (WD53 b1; La Brea b2; MOCA ×3 b3; Academy Y40 + Greek RG3/RG1 b5; Huntington hero + Gamble ×3 b7; Egyptian gallery ×3 + Farmers Market/Grove ×2 b8) |
| **Amsterdam** | *this file* (above) | 22 — Oude Kerk ×3 + Begijnhof ×4 + Anne Frank House hero + Westerkerk interior ×2 + Our Lord in the Attic ×2 + De Waag `_3` + Homomonument ×2 + Noordermarkt/Brouwersgracht ×2 + Rembrandt House hero + Portuguese Synagogue hero + Names Monument ×2 (Wikimedia CC). Hollandsche Schouwburg ×2 = Public Domain (no credit). Nieuwe Kerk + Leidseplein hero = owner-supplied (no credit). All other Amsterdam images = ship-safe stock / CC0, no credit. |
| **Montreal** | *this file* (above) | 15 — **batch 1 (10):** Place Jacques-Cartier: Nelson's Column hero + City Hall `_3`/`_4` (Nelson `_2` = CC0, no credit); Pointe-à-Callière ×4 (Éperon hero/`_2`, buried-river `_3`, foundations `_4`); Bonsecours: market hero + chapel `_3`/`_4` (market `_2` = PD, no credit). Notre-Dame + Old Port = ship-safe stock. **batch 2 (5):** Château Ramezay hero+`_2` (Jean Gagnon CC BY-SA 3.0); McGill `_2` (Jeangagnon CC BY-SA 3.0; hero + `_3` = CC0, no credit); Christ Church hero (Diego Delso CC BY-SA 4.0) + `_2` (ActuaLitté CC BY-SA 2.0). Habitat 67 = ship-safe stock, no credit. |
| **San Francisco** | `IMAGE-CREDITS-sf.txt` | ~27 — Fisherman's Wharf, Hyde St Pier, City Lights, Washington Square SF, Waverly Place, Ross Alley, Union Square SF, SFMOMA, Nob Hill, Castro Theatre, Harvey Milk, de Young (Mission Dolores hero owner / _2 PD — logged in `IMAGE-CREDITS-nyc-refresh.txt`) |
| **London** | `IMAGE-CREDITS-london-batch3.txt` | ~55 — Brompton Oratory, Science Museum, Columbia Road, Whitechapel Gallery, Bevis Marks, Wilton's Music Hall, Dennis Severs', Royal Observatory, Coal Drops Yard, Abbey Road, Lord's, Kenwood, London Zoo, Highgate, Leighton House + walk stops (After the Fire, Spine of Power, South Bank Mile, Albertopolis, Measure of the World) |
| **Paris** | `IMAGE-CREDITS-paris-batch1.txt` | ~15 — Palais-Royal, Place des Vosges, Quai Branly, La Madeleine galleries + walk stops (Îles hero = David.Monniaux CC BY-SA 3.0; Marais stop 3 Musée Picasso = LPLT CC BY-SA 3.0). All other Paris walk stops ship-safe. |
| **Madrid** | `IMAGE-CREDITS-madrid.txt` + `drafts/madrid-batch3/IMAGE-CREDITS-madrid-batch3.txt` | 5 — Museo Thyssen `_2` (CC BY 2.0); Fuente de Neptuno hero (Luis García/Zaqarbal, CC BY-SA 3.0) + `_3` (CC BY-SA 4.0); CaixaForum hero + `_2` (CC BY-SA 4.0). Mercado de San Miguel `_4` is CC0 (no credit). |
| **NYC** | `IMAGE-CREDITS-nyc-refresh.txt` | 2 — Riverside Church `_2` + `_3` (Epicgenius, CC BY-SA 4.0). The rest of the NYC catalog is Wikimedia-thumb / Unsplash / Pexels; this file covers only the 2026-06-24 refresh batch. |

**Counts are approximate** for the large ledgers (London/SF) — the per-city file is
the exact record; CC0 and Public-Domain images are excluded from the counts (they need
no attribution). Grand total of attribution-obligated images across the whole app is on
the order of **~120**, concentrated in London and SF.

**Recommendation unchanged:** before any of this ships live, surface the credits (a
per-tour credits line, or a single in-app attributions screen that ingests these
files), or swap the CC-licensed shots for owner-supplied/CC0 ones. The per-city files
+ this index together are that ingest list.

**Housekeeping note:** the per-city `IMAGE-CREDITS-*.txt` files should ideally be moved
off `gh-pages` (a public asset host) into the repo alongside this file so they travel
with the code. Deferred — they're safe where they are, just not co-located.

## Berlin — credit-required images (`drafts/berlin-batch1` + the 5 walk folders)

New maker **Atlas Studio BER** 🇩🇪 at wire-in. Everything else in the Berlin batch is ship-safe
(Unsplash/Pexels/Pixabay) or owner-pasted (Bernauer Strasse). CC0 / Public-domain rows below carry
**no** obligation and are listed only for provenance. Wikimedia used where no PD/CC0 image of the exact
subject existed (niche stations, memorials, courtyards) or the subject demanded a dignified exact match.


> **Re-verified 2026-07-28 by SHA-1 reverse-lookup** against the Commons `allimages` API (exact file identity). The original attributions here were produced by matching image *dimensions* against a Commons category listing — that method silently picks the wrong file when two images in a category share a size, and **9 of these rows were wrong** (all five Topography of Terror rows, the two Tränenpalast subjects swapped, the Nordbahnhof file, and the East Side Park riverbank). They are corrected below. Three rows could not be SHA-1 matched because the pipeline downloaded a Commons *thumbnail* rather than the original — `bebelplatz_3`, `bebelplatz_4` and `ghostline_stop4`/`ghostline_hero`; all three were corroborated by exact pixel dimensions plus the licence recorded at fetch time, and are left as-is. **Do not use dimension matching for attribution again — SHA-1 the local file.**

| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `bebelplatz_3.webp` | Bebelplatz book-burning memorial (night) | Robyn Fleming | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Bebelplatz_at_night.jpg |
| `bebelplatz_4.webp` | Empty Library / book-burning memorial | Daniel Neugebauer | CC BY-SA 2.5 | https://commons.wikimedia.org/wiki/File:Berlin_DenkmalBuecherverbrennung_BookBurningMemorial_Bebelplatz.jpg |
| `topography-of-terror_hero.webp` | Topography of Terror — Wall + outdoor exhibition | Marco van Oel | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Topo_1309w.jpg |
| `topography-of-terror_2.webp` | Topography of Terror site | Marco van Oel | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Topo_1285w.jpg |
| `topography-of-terror_3.webp` | Wall along Niederkirchnerstraße | BrokenSphere | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Berlin_Wall_at_Niederkirchnerstrasse_2.JPG |
| `topography-of-terror_4.webp` | Wall + Mauermuseum outdoor panels | Wici | Public domain (ship-clean, no obligation) | https://commons.wikimedia.org/wiki/File:Mauermuseum.1.jpg |
| `topography-of-terror_5.webp` | Berlin Wall documentation, Niederkirchnerstraße | Jorge Royan | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Berlin-_The_Berlin_Wall_Museum_-_2879.jpg |
| `hackesche-hoefe_hero.webp` | Hackesche Höfe first courtyard (Endell) | Tuxyso | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Hackesche_H%C3%B6fe-2023.jpg |
| `hackesche-hoefe_2.webp` | Hackesche Höfe street entrance | Jörg Zägel | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Berlin%2C_Mitte%2C_Hackescher_Markt%2C_Hackesche_Hoefe.jpg |
| `hackesche-hoefe_3.webp` | Hackesche Höfe courtyard | Dosseman | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Hackesche_H%C3%B6fe_7920.jpg |
| `neue-synagoge_hero.webp` | Neue Synagoge facade + gilded dome | Mark Ahsmann | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:200806_Berlin_470.JPG |
| `neue-synagoge_2.webp` | Neue Synagoge gilded dome | Taxiarchos228 | FAL (Free Art License) | https://commons.wikimedia.org/wiki/File:Berlin_-_Neue_Synagoge3.jpg |
| `neue-synagoge_3.webp` | Neue Synagoge facade | Kurt Kaiser | CC0 (ship-clean, no obligation) | https://commons.wikimedia.org/wiki/File:Berlin_Neue_Synagoge_2019.jpg |
| `traenenpalast_hero.webp` | Tränenpalast (Palace of Tears) pavilion | Paul Korecky | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:2018-08-09_DE_Berlin-Mitte%2C_Tr%C3%A4nenpalast_%2849923409376%29.jpg |
| `traenenpalast_2.webp` | Tränenpalast pavilion (setting) | Sir James | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:2024-11-02_Berlin_Traenenpalast_Lage_IMG_1599.JPEG |
| `traenenpalast_3.webp` | Tränenpalast pavilion entrance | Sir James | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:2024-11-02_Berlin_Traenenpalast_Eingang_IMG_1595.JPEG |
| `neue-wache_hero.webp` | Neue Wache (Schinkel temple front) | Ansgar Koreng | CC BY 3.0 (DE) | https://commons.wikimedia.org/wiki/File:150214_Neue_Wache_Berlin.jpg |
| `neue-wache_2.webp` | Kollwitz Pietà under the oculus | Daniel Schwen | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:B_Neue_Wache_interior_1.jpg |
| `neue-wache_3.webp` | Kollwitz Pietà (Mother with dead son) | Marek Mróz | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:2015-10_Berlin-Mitte_%2833%29.jpg |
| `karl-marx-allee_hero.webp` | Frankfurter Tor twin towers | H. Helmlechner | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Berlin_Frankfurter_Tor_02.jpg |
| `kollwitzplatz_hero.webp` | Käthe Kollwitz statue (Kollwitzplatz) | Jens Cederskjold | CC BY 3.0 | https://commons.wikimedia.org/wiki/File:K%C3%A4the_Kollwitz%2C_Kollwitzplatz%2C_Prenzlauer_Berg_-_panoramio.jpg |
| `kollwitzplatz_2.webp` | Wasserturm (Prenzlauer Berg) | Norbert Aepli, Switzerland (User:Noebu) | Public domain (ship-clean, no obligation) | https://commons.wikimedia.org/wiki/File:2009-04-10_Berlin_717.jpg |
| `nollendorfplatz_hero.webp` | Nollendorfplatz station + rainbow flag | Fridolin freudenfett | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Sch%C3%B6neberg_Nollendorfplatz_Regenbogenfahne.jpg |
| `[walk] ghostline_stop1.webp` | Nordbahnhof (ghost station) entrance | Ansgar Koreng | CC BY 3.0 (DE) | https://commons.wikimedia.org/wiki/File:150501_Berlin_Nordbahnhof_Eingang.jpg |
| `[walk] ghostline_stop2.webp` | Wall Memorial — line of steel rods | Andrzej Otrębski | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Berlin_Miejsce_Pamieci_Muru_Berlinskiego_10.jpg |
| `[walk] ghostline_stop3.webp` | Chapel of Reconciliation | Laima Gūtmane (simka) | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Berlin_Church_of_Reconciliation_-_panoramio.jpg |
| `[walk] ghostline_stop4.webp + ghostline_hero.webp` | Preserved Wall (Bernauer Str) | **UNRESOLVED — see note** | **UNRESOLVED** (fetch log recorded CC0) | ~~File:200806 Berlin 717.JPG~~ — **disproven, different photograph** |
| `[walk] scheunenviertel_stop2.webp` | Haus Schwarzenberg courtyard | Soluvo | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Berlin_2012_%28106%29.jpg |
| `[walk] scheunenviertel_stop3.webp` | Große Hamburger — deportation memorial (Will Lammert) | Jochen Teufel | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Skulptur_Juedische_Opfer_des_Faschismus_%28Foto_2008%29.jpg |
| `[walk] riverborder_stop3.webp` | East Side Gallery — bank of the Spree | Indrajit Das | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:East_Side_Gallery_-_Bank_of_River_Spree_01.jpg |


## ✅ RESOLVED — the 2 unattributable live images were replaced (2026-07-29)

> **Both images below have been replaced with owner-supplied photographs and now owe no
> attribution at all.** New files are live on `gh-pages` at the same URLs, cropped 1200×900 from
> 2000×1493 with no upscale — so all six references (three each, across two tours apiece) picked
> up the change with **no `Tours.json` edit and no app build**. The investigation is kept below
> because the method is reusable and the failure mode recurs.

Two shipped images cannot be attributed. Both name a Commons file that a side-by-side comparison
**disproves** — the named file is a genuinely different photograph of the same subject — and four
independent identification passes then failed to find the real source. Recorded here rather than
left asserting something false.

| Image | Tours affected | What the row claimed | Why it's wrong |
|---|---|---|---|
| `waterlooplein-rembrandt-house_hero.webp` | 🇳🇱 *Waterlooplein & the Rembrandt House* (hero) · *The Jewish Quarter* walk (stop image) | Usernet123u / CC BY-SA 4.0 / `File:Europe 1979's 03.jpg` | Named file is a **1979 close-up of the doorway**; the published image is a **modern wide shot of the facade**. |
| `testaccio_hero.webp` | 🇮🇹 *Testaccio* (hero + stop image) · *The Aventine and Testaccio* walk (stop image) | Tyler Bell / CC BY 2.0 / `File:Monte Testaccio.jpg` | That was correct for the **original** image, which was **overwritten at the Rome-extras wire-in**. The published file is now a street-level shot along the base of the mound. |

**Search effort (identity threshold ≈ mae < 14; a true match scores ~0.1):**

| Method | Rembrandt House | Testaccio |
|---|---|---|
| Commons category search | 11 files ≥1200×900, best **34.8** | best **33.5** |
| Commons geosearch (200 m / 400 m) | 252 geolocated files, best **34.2** | 285 geolocated files, best **37.5** |
| Unsplash + Pexels + Pixabay, 5 queries each | 317 candidates, best **24.7** | 252 candidates, best **34.8** |
| Fresh pipeline fetch (stock + wiki) | 39 candidates, best **28.9** | 37 candidates, best **33.5** |

**What can still be said with confidence.** The stock pools demonstrably do **not** contain these
subjects — a Rembrandt House query returns canal scenes, the Rembrandt*plein* statue and a
Rijksmuseum interior; a Testaccio query returns the Colosseum and St Peter's. Both published images
*are* genuine, specific views of their subject. So both are near-certainly **Wikimedia CC**, which
matches what each staging README recorded at the time (`drafts/amsterdam-batch1/README.md` says
"CC"; `drafts/rome-batch1/README.md` says "Wikimedia CC BY 2.0"). The licence *family* is credible.
The exact file, author and sub-licence are lost.

**How exposed is this, actually?** Not very, today: **Atlas has no attribution UI**, so *no* CC image
in this ledger is currently being credited in the shipped app. These two are not uniquely
mis-credited — they are uniquely *un-creditable*. The exposure lands the day an attributions screen
ships, or a credits line appears on a tour.

**What was done:** the owner supplied replacement photographs for both, which is the cleanest
possible outcome — owner-supplied images owe no attribution, so the question of *which* CC licence
applied simply stops existing. Superseded options are kept below for the record.

- **Rembrandt House** — replaced with an owner-supplied wide shot of Jodenbreestraat 4, the museum
  wing and Rembrandt Corner either side. *(Superseded fallbacks: `Amsterdam - Rembrandthuis
  (29670034014).jpg` — Fred Romero, CC BY 2.0; `Maison Rembrandt - Amsterdam (NL32) - 2024-11-25 -
  1.jpg` — Chabe01, CC BY-SA 4.0. No PD/CC0 exterior surfaced; stock has none at all.)*
- **Testaccio** — replaced with an owner-supplied view from the piazzale: the mound itself and the
  cut-into-the-hill frontage beneath it. *(Superseded fallback: `File:Monte Testaccio.jpg` — Tyler
  Bell, CC BY 2.0.)*

**Why it wasn't done unilaterally:** swapping a live hero on four tours is a content decision, and
heroes are the owner's pick. The owner supplied both directly, which settled it.

**The reusable lesson.** Two attributions were wrong *and undetectable* because they were produced by
matching image **dimensions** against a Commons category listing. Verify by **SHA-1** instead —
`list=allimages&aisha1=<sha1>` — and when a hash lookup fails, compare the published image against the
named file **side by side** before trusting the row. A row that names a plausible file is not evidence
that it names the right one.



## Chicago — 18 credit-required images (`drafts/chicago-batch1`)

New maker **Atlas Studio ORD** 🇺🇸 at wire-in. **Everything else in the Chicago batch is
ship-safe** (Unsplash / Pexels / Pixabay) or owner-supplied — only these two carry an obligation.
Attributions resolved by **SHA-1 reverse-lookup** against the Commons `allimages` API (exact file
identity), never by dimension match.

| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `historic-water-tower_2.webp` | Water Tower, looking up at the turrets | Ed Schipul | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Chicago_Water_Tower_-_Schipul.jpg |
| `historic-water-tower_3.webp` | Water Tower at dusk, illuminated | Joi Ito | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Chicago-20080523.jpg |
| `the-rookery_2.webp` | Rookery light court (Wright remodel) | w_lemay | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Atrium,_Rookery_Building,_LaSalle_Street_and_Adams_Street,_Chicago,_IL_-_52900630177.jpg |
| `the-rookery_3.webp` | Rookery light court, glass roof | w_lemay | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Atrium,_Rookery_Building,_LaSalle_Street_and_Adams_Street,_Chicago,_IL_-_52901590335.jpg |
| `the-rookery_4.webp` | Rookery marble staircase (Wright) | Onasill – Bill Badzo | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Chicago_IL_~_Rookery_Building_~_Stair_Case_-_Frank_Lloyd_Wright_(51092884753).jpg |
| `the-rookery_5.webp` | Rookery exterior, S LaSalle Street | HaSt | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Chicago_-_S_LaSalle_St_-_Rookery_-_01.jpg |
| `daley-plaza-picasso_hero.webp` | The Chicago Picasso, Daley Plaza | Dan DeLuca | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Downtown-chicago-picasso-sculpture_(6360678643).jpg |
| `daley-plaza-picasso_2.webp` | Daley Plaza in civic use, Picasso behind | 5ukhotskaya | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:2017_Tax_Day_March_in_Chicago_12.jpg |
| `chinatown-ping-tom_hero.webp` | Pui Tak Center / Chinatown at night | Daniel Schwen | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Chicago_Chinatown_night.jpg |
| `chinatown-ping-tom_2.webp` | Chinatown, Chicago | Paul R. Burley | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Chinatown_Chicago_Illinois-0574_10.jpg |
| `robie-house_hero.webp` | Robie House exterior (Wright, 1910) | Sailko | CC BY 3.0 | https://commons.wikimedia.org/wiki/File:Chicago,_robie_house_di_frank_lloyd_wright,_1908-1910,_esterno_01.jpg |
| `robie-house_2.webp` | Robie House, Hyde Park | erikccooper | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Chicago_Hyde_Park_(28896861434).jpg |
| `robie-house_3.webp` | Robie House, Hyde Park | erikccooper | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Chicago_Hyde_Park_(29232014870).jpg |
| `old-town-st-michaels_hero.webp` | St Michael's front, Old Town | Victorgrigas | **Public domain** (no obligation) | https://commons.wikimedia.org/wiki/File:St._Michael_Old_Town,_2.jpg |
| `old-town-st-michaels_2.webp` | St Michael's interior | Victorgrigas | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:St_Michaels_Church_in_Chicago_2018.jpg |
| `old-town-st-michaels_3.webp` | St Michael's steeple over the rooftops | Victor Grigas | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:St.Michaels_Church,_Chicago_in_Old_Town_in_2015.jpg |
| `old-town-st-michaels_4.webp` | Old Town buildings | Victor Grigas | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Buildings_in_Old_Town,_Chicago_2015-18.jpg |
| `old-town-st-michaels_5.webp` | Lincoln Avenue Rowhouse District | Thshriver | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Lincoln_Avenue_Rowhouse_District_3.JPG |
| `[walk] chicago-loopskyscraper_stop4.webp` | Federal Plaza — Mies post office + towers | Chris Rycroft | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Looking_west_from_Federal_Plaza_toward_the_Clark_Adams_Building_(52041873550).jpg |

**⚖️ Calder's *Flamingo* (Federal Plaza, walk 2 stop 4) is IN COPYRIGHT — no exception applies.** Calder died in
1976 and the US has no freedom of panorama for artworks, so a photograph centred on it is an encumbered
derivative work. **This is the opposite of the Chicago Picasso**, which a 1970 ruling put in the public domain —
do not reason from one to the other. **12 of the 22 files in `Category:Federal Center (Chicago)` are
Calder-dominant**, so the obvious grab is the wrong one; the staged image is Mies buildings and granite plaza only.

**⚠️ Tour 21's wooden cottages were never found.** The script's second half is about the small
wooden houses built inside the two-and-a-half-year window before the 1874 city-wide ban. `_4` and
`_5` are **brick Victorian rowhouses**, not those cottages — flagged to the owner and picked
knowingly. A first pass also mis-identified a different Gothic church as St Michael's; the owner
caught it and the set was re-sourced from `Saint Michael's Church, Old Town, Chicago`.

**Owner-supplied (no credit owed):** `art-institute_3.webp` — the Modern Wing (Renzo Piano, 2009),
Monroe Street front.

**✅ `the-rookery_hero.webp` — owner-supplied (2026-07-29), no credit owed.** The LaSalle and Adams
corner: dark red brick and terra cotta, the deep arched entrance, the fortress base. It fills a gap
the Commons pool could not — Rookery coverage there is almost entirely Wright's interior light court,
with no usable exterior of the front the script opens on.

**⚖️ The Chicago Picasso sculpture is PUBLIC DOMAIN in the US** — *Letter Edged in Black Press, Inc.
v. Public Building Commission of Chicago* (1970) held that its design was published without a
copyright notice under the 1909 Act. Commons carries a `{{ChicagoPicasso}}` template recording this.
So photographs of it are **not** encumbered derivative works, and the only licence that attaches is
the photographer's own — the two rows above. This is a documented exception: the US has no freedom
of panorama for artworks, so the general rule would have gone the other way. **Verified, not assumed.**

**⏳ `monadnock-building_2.webp` pending** — owner is supplying a second image; hero (`MND1`, the
storefront lettering) is staged.

**Public-domain Rookery extras available, not yet picked** (no credit owed if used): the 1870s
engraving *The Book Room in the Old Water Tank* — the post-fire temporary city hall whose resident
crows gave the building its name — and the HABS measured elevation of the LaSalle front.

## Chicago walk 5 (Pilsen) — 2 credit-required images + 2 UNRESOLVED mural rights

`drafts/chicago-pilsen-walk`. Both photographer attributions resolved by **SHA-1 reverse-lookup**
against the Commons `allimages` API.

| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `chicago-pilsen_stop3.webp` | 18th Street station platform | Eric Allix Rogers | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:18th_Street_Pink_Line.jpg |
| `chicago-pilsen_stop4.webp` | National Museum of Mexican Art entrance | Skvader | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:National_Museum_of_Mexican_Art_entrance.jpg |

**Hero and stop 2 reuse live owner images** (`pilsen-18th-street_2.webp` and
`pilsen-18th-street_hero.webp`) — no obligation. **Stop 1 is owner-supplied** — no *photographer*
obligation.

### ⚠️ UNRESOLVED — two in-copyright murals are principal subjects, shipped at owner direction

The rows above cover the **photographers only**. Two of these images also depict copyrighted
**murals**, which is a separate right the photographer cannot license:

| File | Mural | Artist(s) | Status |
|------|-------|-----------|--------|
| `chicago-pilsen_stop1.webp` | *Hay Cultura en Nuestra Comunidad*, Casa Aztlan | Ray Patlan (d. 2024); 2017 repaint with Roberto Valadez (living) | **no permission sought** |
| `chicago-pilsen_stop3.webp` | 18th Street station platform murals incl. the Aztec sun stone | Francisco Mendoza (d. 2012) and students | **no permission sought** |

The US has **no freedom of panorama for artworks** — 17 USC §120 exempts *architectural works*
only — so a photograph of a mural is a derivative work. In both images the mural is a **principal
subject, not incidental**: the AZTLAN arch, portraits and butterfly fill the lower third of stop 1,
and the sun stone dominates the right of stop 3. Neither would pass a de minimis test.

This was **flagged in advance and shipped at the owner's explicit direction** (2026-07-30) after
the buildings-only option was offered and priced. Recorded here so the obligation is visible rather
than lost. **Note the trap for future sessions: an owner-supplied photo does NOT clear this** — it
clears the photographer, never the muralist. Contrast the Chicago Picasso (tour 14), which really
is public domain by a 1970 court ruling; do not reason from one case to the other.

**Casa Aztlan has no photograph on Wikimedia Commons at all** — zero files, which is likely this
same rule operating upstream.

## Dubai — 11 credit-required images (`drafts/dubai-batch1`)

Everything else in the Dubai batch is ship-safe (Unsplash / Pexels / Pixabay / CC0)
or owner-supplied. New maker **Atlas Studio DXB** 🇦🇪 at wire-in. Attributions below
were resolved by **SHA-1 reverse-lookup** against the Commons `allimages` API (exact
file identity), not by dimension matching.

| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `gold-souk_hero.webp` | Dubai Gold Souk arcade | Rob Young | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Dubai_Gold_Souk_(8668422526).jpg |
| `gold-souk_3.webp` | Al Ras / Gold Souk quarter, Deira | Imre Solt | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Al_Ras_on_26_December_2007_Pict_3.jpg |
| `jumeirah-mosque_hero.webp` | Jumeirah Mosque (exterior) | Bgabel | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Dub-jum-mos2.jpg |
| `jumeirah-mosque_2.webp` | Jumeirah Mosque | Aidas U. | CC BY 3.0 | https://commons.wikimedia.org/wiki/File:Jumeirah_Mosque_-_panoramio_(4).jpg |
| `jumeirah-mosque_3.webp` | Jumeirah Mosque, Jumeira 1 | ianpudsey | CC BY 3.0 | https://commons.wikimedia.org/wiki/File:Jumeira_1_-_Dubai_-_United_Arab_Emirates_-_panoramio.jpg |
| `etihad-museum_2.webp` | Etihad Museum with UAE flag | Lxs | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:UAE_flat_with_Etihad_Museum_in_background,_Dubai,_UAE.jpg |
| `textile-souk_hero.webp` | Textile Souk sikka (alleyway) | Chris Waits | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Dubai_Textile_Souk_Sikka_(Alleyway).jpg |
| `al-shindagha_2.webp` | Shindagha historic village | A.Savin | **FAL** (Free Art License) | https://commons.wikimedia.org/wiki/File:UAE_Dubai_Shindagha_village_img1_asv2018-01.jpg |
| `al-fahidi-fort_hero.webp` | Al Fahidi Fort / Dubai Museum (rear) | أمين علوان | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Al_Fahidi_Fort_(Dubai_Fort)_(Dubai_Museum)_Back_view.jpg |
| `al-fahidi-fort_2.webp` | Al Fahidi Fort / Dubai Museum | Jasonbalaba | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Al_Fahidi_Fort_(Dubai_Museum).jpg |
| `al-fahidi-fort_3.webp` | Al Fahidi Fort (Dubai Fort) | Rye jb23 | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Al_Fahidi_Fort_(also_known_as_Dubai_Fort)_DSC_8954.jpg |

**Note — `al-shindagha_2.webp` is FAL, not CC.** The Free Art License is copyleft:
attribution *and* share-alike. It is not more permissive than CC BY-SA; treat it the
same way at ship time.

**No credit required:** `alserkal-avenue_hero.webp` is Wikimedia **CC0**, and the
`al-shindagha_hero.webp` / `difc-gate_hero.webp` heroes are owner-supplied (both
carry provenance flags — see `drafts/dubai-batch1/README.md`).

## Istanbul batch 1 (Atlas Studio IST) — 187 images, licence per image NOT recorded

Wired 2026-09-28. The contributor supplied every photograph (1200×900 webp, already
cropped) and described them as **"from Creative Commons"**. No per-image source,
author or licence came with them, so none can be listed here yet, and the crops defeat
a SHA-1 lookup against Commons. **Owner item `istanbul-photo-licences`** asks Edward
to accept them as shipped or have the contributor send a source link per image; any
CC BY / BY-SA rows then belong in this section.

## Miami — 60 credit-required images (`drafts/miami-batch1`, staged 2026-09-25)

**Owner decision 2026-09-29: keep these Commons photos with credits (option 1),** rather than swap them.
They were first reported as all PD/CC0, which was wrong; see `archive/HANDOFF-260925-miami-staging.md`
§ Correction 2026-09-29. **Every file below was byte-verified** against the gh-pages copy (sha256
from the sourcing manifest). Licence and author come from Openverse's Wikimedia index, matched on
the exact Commons filename. Commons itself was rate-limiting this container, so **re-confirm against
each file page before the credits are surfaced in the app.**

Three Commons heroes were superseded by owner photographs and live on as `_3` (byte-identical
to the orphaned `_hero.webp`). They are listed under their `_3` name.

### miami-circle
| File | Author | License | Source |
|------|--------|---------|--------|
| `miami-circle_2.webp` | EduardoValle | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Miami_Circle_aerial_view_with_river_and_tower.JPG |
| `miami-circle_4.webp` | Ebyabe | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Miami_FL_Miami_Circle_pano01.jpg |
| `miami-circle_hero.webp` | EduardoValle | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Miami_Circle_aerial_view.JPG |
| `miami-circle_3.webp` | CobraZaroia | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Brickell_Point_Site_2012-09-15_16-54-59.jpg |

### brickell-avenue-bridge
| File | Author | License | Source |
|------|--------|---------|--------|
| `brickell-avenue-bridge_hero.webp` | Phillip Pessar from Miami, USA | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Brickell_Avenue_Bridge_from_northwest_in_2015.jpg |
| `brickell-avenue-bridge_2.webp` | Neil Williamson | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Brickell_Avenue_Bridge_at_night_with_bascule_span_open_%282017%29.jpg |
| `brickell-avenue-bridge_3.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Miami_River_Downtown_Miami_Florida_1_May_2023.jpg |

### ocean-drive-art-deco
| File | Author | License | Source |
|------|--------|---------|--------|
| `ocean-drive-art-deco_hero.webp` | Robbschultz69 | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Ocean_Drive_in_the_Miami_Beach_Art_Deco_Historic_District.jpg |
| `ocean-drive-art-deco_2.webp` | Dough4872 | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Ocean_Drive_NB_past_11th_Street_Miami_Beach_at_night.jpeg |
| `ocean-drive-art-deco_3.webp` | Mickey Løgitmark | CC BY 3.0 | https://commons.wikimedia.org/wiki/File:Ocean_Drive_-_panoramio_%281%29.jpg |

### maximo-gomez-park
| File | Author | License | Source |
|------|--------|---------|--------|
| `maximo-gomez-park_hero.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Domino_Park_Little_Havana%2C_Miami_Florida_6_June_2024.jpg |
| `maximo-gomez-park_2.webp` | SK Sturm Fan | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Domino_Club_%E2%80%93_Florida_Heritage%3B_M%C3%A1ximo_G%C3%B3mez_Park_%28Domino_Park%29%2C_Little_Havana%2C_Miami%2C_Florida_%282019%29_%286%29.jpg |

### cuban-memorial-boulevard
| File | Author | License | Source |
|------|--------|---------|--------|
| `cuban-memorial-boulevard_hero.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Cuban_Memorial_Boulevard_Calle_Ocho_Little_Havana%2C_Miami_2023.jpg |

### the-barnacle
| File | Author | License | Source |
|------|--------|---------|--------|
| `the-barnacle_hero.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:The_Barnacle_Coconut_Grove_%2816815440570%29.jpg |
| `the-barnacle_2.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:The_Barnacle_Coconut_Grove_%2816815512178%29.jpg |

### vizcaya
| File | Author | License | Source |
|------|--------|---------|--------|
| `vizcaya_hero.webp` | Leslie Platt | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Vizcaya_Museum_and_Gardens_060524_DSC6661.jpg |
| `vizcaya_2.webp` | Leslie Platt | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Vizcaya_Museum_and_Gardens_060524_DSC6702.jpg |
| `vizcaya_3.webp` | Leslie Platt | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Vizcaya_Museum_and_Gardens_060524_DSC6700.jpg |
| `vizcaya_4.webp` | Leslie Platt | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Vizcaya_Museum_and_Gardens_060524_DSC6677.jpg |
| `vizcaya_5.webp` | Leslie Platt | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Vizcaya_Museum_and_Gardens_060524_DSC6697.jpg |

### wynwood-walls
| File | Author | License | Source |
|------|--------|---------|--------|
| `wynwood-walls_hero.webp` | osseous | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:April_7%2C_2015_-_Wynwood_Miami_-_07.jpg |
| `wynwood-walls_3.webp` | Phillip Pessar from Miami, USA | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Wynwood_Mural_%2816811746490%29.jpg |
| `wynwood-walls_5.webp` | Phillip Pessar from Miami, USA | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Wynwood_Murals_%2812926225503%29.jpg |
| `wynwood-walls_6.webp` | osseous | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:April_7%2C_2015_-_Wynwood_Miami_-_05.jpg |
| `wynwood-walls_2.webp` | Dan Lundberg | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:Wynwood_Walls_Miami_Florida_October_2013.jpg |

### dade-county-courthouse
| File | Author | License | Source |
|------|--------|---------|--------|
| `dade-county-courthouse_2.webp` | Rob Olivera | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:The_Miami_Dade_County_Flagler_Courthouse.jpg |
| `dade-county-courthouse_hero.webp` | Daniel Di Palma | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Miami-Dade_County_Courthouse_-_Miami_-_Daniel_Di_Palma_Photography_06.jpg |

### gesu-church
| File | Author | License | Source |
|------|--------|---------|--------|
| `gesu-church_3.webp` | Tamanoeconomico | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Gesu_Catholic_Church_%28Miami%2C_Florida%29.jpg |
| `gesu-church_2.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Gesu_Catholic_Church_Downtown_Miami_-_exterior_-_26_November_2022_-_Inscription.jpg |

### miami-dade-cultural-center
| File | Author | License | Source |
|------|--------|---------|--------|
| `miami-dade-cultural-center_hero.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Cultural_Center_Downtown_Miami_FL%2C_construction_in_background%2C_4_May_2023.jpg |
| `miami-dade-cultural-center_2.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Miami-Dade_Cultural_Center%2C_Miami_FL_7_January_2023_-_05.jpg |
| `miami-dade-cultural-center_3.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Miami-Dade_Cultural_Center%2C_Miami_FL_7_January_2023_-_04.jpg |
| `miami-dade-cultural-center_4.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Miami-Dade_Cultural_Center%2C_Miami_FL_7_January_2023_-_06.jpg |
| `miami-dade-cultural-center_5.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Miami-Dade_Cultural_Center%2C_Miami_FL_7_January_2023_-_03.jpg |

### ferre-park
| File | Author | License | Source |
|------|--------|---------|--------|
| `ferre-park_hero.webp` | AuntieMamesTravels | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Bicentennial_Park_June_2014.JPG |
| `ferre-park_2.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:PAMM_MRD_21.jpg |
| `ferre-park_3.webp` | Phillip Pessar | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:PAMM_MRD_28.jpg |

### lummus-park-downtown
| File | Author | License | Source |
|------|--------|---------|--------|
| `lummus-park-downtown_2.webp` | Phillip Pessar from Miami, USA | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Fort_Dallas_William_English_Plantation_Lummus_Park_Historic_District_%2830642638520%29.jpg |
| `lummus-park-downtown_3.webp` | Phillip Pessar from Miami, USA | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:William_Wagner_House_Circa_1855_Lummus_Park_Historic_District_%2822765725588%29.jpg |
| `lummus-park-downtown_hero.webp` | Daniel Di Palma | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Lummus_Park_Historic_Distric_-_Miami_-_Daniel_Di_Palma_Photography_03.jpg |
| `lummus-park-downtown_4.webp` | Daniel Di Palma | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Lummus_Park_Historic_Distric_-_Miami_-_Daniel_Di_Palma_Photography_01_Wagner_House_and_Fort_Dallas.jpg |

### casa-casuarina
| File | Author | License | Source |
|------|--------|---------|--------|
| `casa-casuarina_hero.webp` | chensiyuan | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Gianni_versace_miami_home.JPG |
| `casa-casuarina_3.webp` | CZmarlin — Christopher Ziemnowicz would appreciate a photo credit if this image is used anywhere other than Wikipedia. Please leave a note at Wikipedia here. Thank you! | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Casa_Casuarina_at_night_Versace_Mansion%2C_hotel_restaurant_at_1116_Ocean_Drive%2C_Miami_Beach.jpg |
| `casa-casuarina_2.webp` | Vadelmavene | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Casa_Casuarina_Pool.jpg |

### holocaust-memorial-miami-beach
| File | Author | License | Source |
|------|--------|---------|--------|
| `holocaust-memorial-miami-beach_hero.webp` | Daniel Di Palma | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Miami_Beach_-_South_Beach_Monuments_-_Holocaust_Memorial_28.jpg |
| `holocaust-memorial-miami-beach_3.webp` | Daniel Di Palma | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Miami_Beach_-_South_Beach_Monuments_-_Holocaust_Memorial_01.jpg |

### fontainebleau
| File | Author | License | Source |
|------|--------|---------|--------|
| `fontainebleau_hero.webp` | InvadingInvader | CC BY 4.0 | https://commons.wikimedia.org/wiki/File:Fontainebleau_Miami_Beach_Aerial_2025.jpg |
| `fontainebleau_3.webp` | Visitor7 | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Fontainebleau-10.jpg |
| `fontainebleau_4.webp` | Acroterion | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Fontainebleau_Miami_interior_FL3.jpg |
| `fontainebleau_2.webp` | Visitor7 | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Fontainebleau-1.jpg |

### tower-theater
| File | Author | License | Source |
|------|--------|---------|--------|
| `tower-theater_3.webp` | Tamanoeconomico | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Tower_Theater_%28Miami%2C_Florida%29.jpg |
| `tower-theater_2.webp` | Raghavan Prabhu | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Tower_Theater_-_Looks_Like_That_70%27s_show.jpg |

### lyric-theater
| File | Author | License | Source |
|------|--------|---------|--------|
| `lyric-theater_3.webp` | Tamanoeconomico | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Miami_Lyric_Theater_%284%29.jpg |
| `lyric-theater_2.webp` | Tamanoeconomico | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Miami_Lyric_Theater_%281%29.jpg |

### freedom-tower
| File | Author | License | Source |
|------|--------|---------|--------|
| `freedom-tower_2.webp` | Infrogmation of New Orleans | CC BY 2.0 | https://commons.wikimedia.org/wiki/File:Miami_Florida_2018-01-16_-_Freedom_Tower.jpg |

### jewish-museum-of-florida
| File | Author | License | Source |
|------|--------|---------|--------|
| `jewish-museum-of-florida_hero.webp` | Ebyabe | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Miami_Beach_FL_Beth_Jacob_Hall_msm01.jpg |
| `jewish-museum-of-florida_2.webp` | Ebyabe | CC BY-SA 3.0 | https://commons.wikimedia.org/wiki/File:Miami_Beach_FL_Beth_Jacob_Hall_msm07.jpg |

### bacardi-building
| File | Author | License | Source |
|------|--------|---------|--------|
| `bacardi-building_hero.webp` | Dan Lundberg | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:20131012_Miami_3615_Bacardi_annex.jpg |
| `bacardi-building_2.webp` | Dan Lundberg | CC BY-SA 2.0 | https://commons.wikimedia.org/wiki/File:20131019_Miami_3688_Bacardi_plaza.jpg |
| `bacardi-building_4.webp` | PhillipPessar | CC BY-SA 4.0 | https://commons.wikimedia.org/wiki/File:Bacardi_Building_Biscayne_Boulevard_Miami.jpg |

### Miami — no credit owed
| File | Why | Source |
|------|-----|--------|
| `royal-palm-hotel-site_hero.webp` | CC0 — no credit owed | https://commons.wikimedia.org/wiki/File:View_of_the_Miami_River_from_the_South_Miami_Avenue_bridge_2026-04-06.jpg |
| `bayfront-park_2.webp` | CC0 — no credit owed | https://commons.wikimedia.org/wiki/File:Challenger_Memorial_%28Miami%29_by_night_%28January_2022%29_-_inscription.JPG |
| `bayfront-park_3.webp` | CC0 — no credit owed | https://commons.wikimedia.org/wiki/File:Challenger_Memorial_%28Miami%29_by_night_%28January_2022%29.JPG |
| `royal-palm-hotel-site_2.webp` | US National Archives (NARA 544634) — public domain | https://commons.wikimedia.org/wiki/File:TRAFFIC_INTERCHANGE_CUTS_THROUGH_THE_HEART_OF_DOWNTOWN_MIAMI_-_NARA_-_544634.jpg |
| all `*_hero-2`, `lyric-theater_4`, `south-pointe-park_*`, `dupont-building_hero-2`, `little-haiti-cultural-complex_*`, `virginia-key-beach_hero`, `lincoln-road_*` | owner-supplied | — |
| `overtown-interchange_hero.webp` | owner-supplied, **source unknown**; reverse-search before launch (handoff § Overtown) | — |

### ⚠️ Miami — licence NOT yet verified (10)
Openverse had no record of these files and Commons was throttled. **Look each one up before launch.**

| File | Source |
|------|--------|
| `freedom-tower_hero.webp` | https://commons.wikimedia.org/wiki/File:Freedom_Tower_Miami_%28top%29%2C_NE_view.jpg |
| `freedom-tower_3.webp` | https://commons.wikimedia.org/wiki/File:Miami_freedom_tower_night.jpg |
| `bayfront-park_hero.webp` | https://commons.wikimedia.org/wiki/File:Torch_of_Friendship_-_panoramio.jpg |
| `espanola-way_hero.webp` | https://commons.wikimedia.org/wiki/File:Miami_Beach_-_Espa%C3%B1ola_Way_Reconstruction_February_2016_01_View_East_Mid_Street.jpg |
| `holocaust-memorial-miami-beach_2.webp` | https://commons.wikimedia.org/wiki/File:Reaching_sky_-_Flickr_-_LANSA301.jpg |
| `miami-circle_5.webp` | https://commons.wikimedia.org/wiki/File:Miami_FL_Miami_Circle_plaque01.jpg |
| `miami-circle_6.webp` | https://commons.wikimedia.org/wiki/File:Miami_Circle_%289081683470%29.jpg |
| `cuban-memorial-boulevard_2.webp` | https://commons.wikimedia.org/wiki/File:Josemartibust.jpg |
| `wynwood-walls_4.webp` | https://commons.wikimedia.org/wiki/File:-RETNA_Wynwood_Walls_%288170950212%29.jpg |
| `lummus-park-downtown_5.webp` | https://commons.wikimedia.org/wiki/File:Miami_FL_Lummus_Park_HD_Wagner_Homestead_plaque01.jpg |

Held back and never uploaded, so they need no row: `dupont-building_hero` (CC BY 2.0) and `little-haiti-cultural-complex_hero` (CC BY 3.0), both replaced by owner photos, and `bacardi-building_3` (CC BY 2.0), which is unused.

## Miami walks — 7 credit-required images (`drafts/miami-walks`, picked 2026-09-30)

Flickr originals sourced via Openverse. The licence was read from each live Flickr page. Owner option 1 applies: keep with credits.

| File | Subject | Author | License | Source |
|------|---------|--------|---------|--------|
| `miami-pitch_stop5.webp` | W1-5 Olympia Theater | Phillip Pessar | CC BY 2.0 | https://www.flickr.com/photos/southbeachcars/11375548644/ |
| `miami-calle-ocho_stop2.webp` | W3-2 Walk of Fame (Celia Cruz star) | Phillip Pessar | CC BY 4.0 | https://www.flickr.com/photos/southbeachcars/31825441737/ |
| `miami-calle-ocho_stop5.webp` | W3-5 Woodlawn Park mausoleum | Phillip Pessar | CC BY 2.0 | https://www.flickr.com/photos/southbeachcars/6654773763/ |
| `miami-grove_stop1.webp` | W4-1 Mariah Brown House, Charles Ave | Phillip Pessar | CC BY 2.0 | https://www.flickr.com/photos/southbeachcars/17093231140/ |
| `miami-grove_stop2.webp` | W4-2 Plymouth Congregational Church | Jorge Elías | CC BY 2.0 | https://www.flickr.com/photos/italintheheart/11658406774/ |
| `miami-grove_stop4.webp` | W4-4 Vizcaya entrance, S Miami Ave | Jared | CC BY 2.0 | https://www.flickr.com/photos/jared422/8772177391/ |
| `miami-water-line_stop2.webp` | W5-2 Venetian Causeway | Phillip Pessar | CC BY 2.0 | https://www.flickr.com/photos/southbeachcars/17009368825/ |


## Boston — no credit owed (83 images, picked 2026-10-02)

The owner picked these in the Boston Image Picks page. **None is credit-required:** 54 come from Unsplash and 14 from Pexels (both licences need no credit), and 15 are public domain (CC0/PDM, via Openverse). Sources are recorded for provenance. Byte hashes are in `drafts/boston-batch1/image-manifest.json`.

| File | Pick | Licence | Author | Source |
|------|------|---------|--------|--------|
| `african-meeting-house_hero.webp` | owner | Owner-supplied (2026-10-02) | — | pasted in chat |
| `shaw-54th-memorial_hero.webp` | owner | Owner-supplied (2026-10-02) | — | pasted in chat |
| `bunker-hill-monument_hero.webp` | owner | Owner-supplied (2026-10-02) | — | pasted in chat |
| `old-north-church_hero-2.webp` | owner | Owner-supplied (2026-10-02) | — | pasted in chat |
| `park-street-church_hero-2.webp` | owner | Owner-supplied (2026-10-02) | — | pasted in chat |
| `kings-chapel_hero.webp` | owner | Owner-supplied (2026-10-02) | — | pasted in chat |
| `paul-revere-house_hero-2.webp` | owner | Owner-supplied (2026-10-02) | — | pasted in chat |
| `massachusetts-state-house_hero.webp` | 01-2 | Unsplash | Pix Tresa | https://unsplash.com/photos/massachusetts-state-house-with-golden-dome-and-flags-NfgDqrqaqJQ |
| `massachusetts-state-house_2.webp` | 01-3 | Pexels | Richard Lathrop | https://www.pexels.com/photo/golden-dome-at-massachusetts-state-house-at-sunset-38276919/ |
| `massachusetts-state-house_3.webp` | 01-1 | Unsplash | Aubrey Odom | https://unsplash.com/photos/white-concrete-building-under-blue-sky-during-daytime-uQStpRlY1qw |
| `massachusetts-state-house_4.webp` | 01-6 | Public domain (cc0 1.0) | Daderot | https://commons.wikimedia.org/w/index.php?curid=47119979 |
| `boston-common_hero.webp` | 02-3 | Unsplash | Wei Liang | https://unsplash.com/photos/boston-skyline-viewed-from-a-park-at-sunset-1dLS643cqiE |
| `boston-common_2.webp` | 02-2 | Unsplash | Christopher Ryan | https://unsplash.com/photos/a-field-full-of-american-flags-with-a-city-in-the-background-1JAYItINTpw |
| `boston-common_3.webp` | 02-8 | Unsplash | Sean Sweeney | https://unsplash.com/photos/boston-skyline-above-boston-common-park-8sCtnULy3aE |
| `old-state-house_hero.webp` | 03-1 | Unsplash | Leo Heisenberg | https://unsplash.com/photos/cars-parked-on-side-of-the-road-near-brown-concrete-building-during-daytime-LgHghP14qeU |
| `old-state-house_2.webp` | 03-2 | Unsplash | Herry Sutanto | https://unsplash.com/photos/a-brick-building-with-a-clock-tower-with-old-state-house-in-the-background-L0J_ejfmyKs |
| `old-state-house_3.webp` | 03-3 | Unsplash | Aubrey Odom | https://unsplash.com/photos/brown-and-white-concrete-building--J0uMCDL2KQ |
| `old-state-house_4.webp` | 03-10 | Unsplash | Nils Huenerfuerst | https://unsplash.com/photos/a-city-street-at-night-TuNgI21FyMc |
| `faneuil-hall_hero.webp` | 04-1 | Unsplash | Brett Wharton | https://unsplash.com/photos/a-large-brick-building-with-a-dome-with-faneuil-hall-in-the-background-DibBKV3MTp8 |
| `faneuil-hall_2.webp` | 04-2 | Public domain (cc0 1.0) | Marco Almbauer | https://commons.wikimedia.org/w/index.php?curid=68436449 |
| `acorn-street-louisburg-square_hero.webp` | 05-1 | Unsplash | Wei Zeng | https://unsplash.com/photos/brown-brick-building-with-green-tree-yYHnNSZSK5E |
| `acorn-street-louisburg-square_2.webp` | 05-2 | Unsplash | Mike Bryant | https://unsplash.com/photos/cobblestone-street-lined-with-historic-brick-buildings-5aSGI7qPx5I |
| `acorn-street-louisburg-square_3.webp` | 05-4 | Public domain (cc0 1.0) | Michael Browning michaelwb | https://commons.wikimedia.org/w/index.php?curid=61872608 |
| `paul-revere-house_hero.webp` | 06-1 | Public domain (cc0 1.0) | Education Prof | https://commons.wikimedia.org/w/index.php?curid=112487492 |
| `old-north-church_hero.webp` | 07-1 | Unsplash | Julie Haider | https://unsplash.com/photos/a-church-steeple-towering-over-a-city-street-wufGIg3LBd4 |
| `uss-constitution_hero.webp` | 09-1 | Unsplash | David Trinks | https://unsplash.com/photos/a-large-sailing-ship-in-the-water-with-a-city-in-the-background-0yMtNlunh_c |
| `uss-constitution_2.webp` | 09-3 | Unsplash | Sarah Brown | https://unsplash.com/photos/black-galleon-near-dock-mvRKPeJuHJg |
| `uss-constitution_3.webp` | 09-7 | Unsplash | David Trinks | https://unsplash.com/photos/a-large-sailing-ship-in-the-water-with-a-city-in-the-background-efLu9QmkuIU |
| `uss-constitution_4.webp` | 09-10 | Unsplash | Lens Fables | https://unsplash.com/photos/deck-of-an-old-sailing-ship-with-cannons-zz7HNj1E_pw |
| `boston-public-garden_hero.webp` | 10-2 | Unsplash | Aubrey Odom | https://unsplash.com/photos/black-horse-statue-near-green-trees-and-buildings-during-daytime-dwYY9NDj4_Q |
| `boston-public-garden_2.webp` | 10-1 | Unsplash | Sean Sweeney | https://unsplash.com/photos/man-riding-horse-statue-on-snow-covered-ground-during-daytime-6LOmOsHGQ9w |
| `boston-public-garden_3.webp` | 10-3 | Unsplash | Taylor Keeran | https://unsplash.com/photos/a-boat-floating-on-top-of-a-lake-next-to-a-lush-green-park-2gWWRPvW3gw |
| `boston-public-garden_4.webp` | 10-4 | Unsplash | Josephine Baran | https://unsplash.com/photos/woman-sitting-on-bench-cjrULwnJKhI |
| `boston-public-garden_5.webp` | 10-5 | Unsplash | Spyder Marketing Co. | https://unsplash.com/photos/green-trees-beside-lake-during-daytime-26Yv9t_rCSU |
| `boston-public-garden_6.webp` | 10-6 | Unsplash | Ana Garnica | https://unsplash.com/photos/a-park-with-trees-and-a-building-in-the-background-znU3QLzfZbw |
| `boston-public-garden_7.webp` | 10-7 | Unsplash | Yassine Khalfalli | https://unsplash.com/photos/red-and-white-boat-on-water-near-city-buildings-during-daytime-k2mcSzPYHmA |
| `boston-public-garden_8.webp` | 10-8 | Unsplash | Sean Sweeney | https://unsplash.com/photos/boston-public-garden-pond-and-skyline-5BSN8C8abm4 |
| `boston-public-garden_9.webp` | 10-9 | Unsplash | Isaac S | https://unsplash.com/photos/weeping-willow-trees-reflected-in-calm-water-at-night-PiqBvbwOaF0 |
| `boston-public-garden_10.webp` | 10-10 | Unsplash | Isaac S | https://unsplash.com/photos/bridge-over-water-at-night-with-reflections-k-cwISNBsQk |
| `copley-square_hero.webp` | 11-6 | Pexels | Phil Evenden | https://www.pexels.com/photo/winter-view-of-boston-s-historic-architecture-36989585/ |
| `copley-square_2.webp` | 11-2 | Unsplash | Piermario Eva | https://unsplash.com/photos/a-group-of-people-walking-in-front-of-a-building-1aH0IU3YAhg |
| `copley-square_3.webp` | 11-5 | Pexels | Guohua Song | https://www.pexels.com/photo/boston-public-library-with-trinity-church-in-view-38911057/ |
| `copley-square_4.webp` | 11-7 | Pexels | Mohammed Abubakr | https://www.pexels.com/photo/traffic-in-front-of-the-old-south-church-at-dusk-19828348/ |
| `fenway-park_hero.webp` | 12-1 | Unsplash | Clark Van Der Beken | https://unsplash.com/photos/text-eA0-9tGE13k |
| `fenway-park_2.webp` | 12-2 | Unsplash | Wei Zeng | https://unsplash.com/photos/people-watching-football-game-during-daytime-tnn5A1uT1I4 |
| `fenway-park_3.webp` | 12-3 | Unsplash | Richard Scordato | https://unsplash.com/photos/a-large-boston-red-sox-stadium-sign-on-the-side-of-a-building-IfZRmG5Yl94 |
| `fenway-park_4.webp` | 12-4 | Unsplash | Ilse Orsel | https://unsplash.com/photos/aerial-view-of-green-and-brown-stadium-during-daytime-71m6FIV9Brw |
| `fenway-park_5.webp` | 12-7 | Unsplash | NICOLE UMANA | https://unsplash.com/photos/fenway-park-entrance-is-shown-in-the-image-CZ96_KN7YgI |
| `granary-burying-ground_hero.webp` | 13-1 | Public domain (cc0 1.0) | Marco Almbauer | https://commons.wikimedia.org/w/index.php?curid=76382340 |
| `park-street-church_hero.webp` | 14-1 | Unsplash | Brett Wharton | https://unsplash.com/photos/a-view-of-a-city-with-tall-buildings-laPXdiH2tS8 |
| `old-south-meeting-house_hero.webp` | 15-2 | Unsplash | Pascal Bernardon | https://unsplash.com/photos/tower-clock-surrounded-with-high-rise-buildings-during-daytime-z8k6D7gKVws |
| `old-south-meeting-house_2.webp` | 15-1 | Unsplash | Nathalie Anfuso | https://unsplash.com/photos/a-church-with-a-steeple-and-a-clock-tower-bRUGeCrWDWU |
| `old-south-meeting-house_3.webp` | 15-3 | Public domain (cc0 1.0) | Daderot | https://commons.wikimedia.org/w/index.php?curid=76947597 |
| `old-south-meeting-house_4.webp` | 15-4 | Public domain (cc0 1.0) | Daderot | https://commons.wikimedia.org/w/index.php?curid=76947598 |
| `boston-city-hall-plaza_hero.webp` | 17-5 | Public domain (cc0 1.0) | Daniel Lobo | https://commons.wikimedia.org/w/index.php?curid=101393489 |
| `boston-city-hall-plaza_2.webp` | 17-6 | Public domain (cc0 1.0) | — | https://commons.wikimedia.org/w/index.php?curid=96759382 |
| `boston-city-hall-plaza_3.webp` | 17-1 | Unsplash | Leon Bredella | https://unsplash.com/photos/a-very-tall-building-with-a-clock-on-its-side-BVJtR3YQunE |
| `boston-city-hall-plaza_4.webp` | 17-2 | Unsplash | CDMA | https://unsplash.com/photos/brown-concrete-building-with-glass-windows-YgofkpLw82M |
| `quincy-market_hero.webp` | 18-1 | Unsplash | Bernd 📷 Dittrich | https://unsplash.com/photos/a-group-of-people-standing-in-front-of-a-building-p_phiM5drG0 |
| `quincy-market_2.webp` | 18-2 | Public domain (cc0 1.0) | Marco Almbauer | https://commons.wikimedia.org/w/index.php?curid=72816412 |
| `charles-street-beacon-hill_hero.webp` | 21-1 | Unsplash | Matt Collamer | https://unsplash.com/photos/brown-brick-building-near-green-trees-during-daytime-UpYF6ibFud0 |
| `charles-street-beacon-hill_2.webp` | 21-3 | Unsplash | Matías  Ramos | https://unsplash.com/photos/red-car-parked-beside-brown-brick-building-H-lFz_ZuJwQ |
| `charles-street-beacon-hill_3.webp` | 21-2 | Unsplash | Zoshua Colah | https://unsplash.com/photos/a-city-street-lined-with-parked-cars-and-tall-buildings-Iv0ZWxTW15s |
| `charles-street-beacon-hill_4.webp` | 21-6 | Unsplash | Wei Liang | https://unsplash.com/photos/street-view-of-historic-buildings-and-parked-cars-in-city-truWglYhWuM |
| `greenway-north-end_hero.webp` | 24-1 | Pexels | Phil Evenden | https://www.pexels.com/photo/custom-house-tower-seen-from-park-in-boston-usa-13710117/ |
| `greenway-north-end_2.webp` | 24-3 | Pexels | Phil Evenden | https://www.pexels.com/photo/a-view-of-the-city-from-a-park-bench-27359141/ |
| `greenway-north-end_3.webp` | 24-4 | Public domain (cc0 1.0) | Daderot | https://commons.wikimedia.org/w/index.php?curid=47109888 |
| `long-wharf-boston_hero.webp` | 25-2 | Pexels | Mohan Nannapaneni | https://www.pexels.com/photo/skyscrapers-on-sea-coast-in-boston-at-sunset-27062463/ |
| `long-wharf-boston_2.webp` | 25-4 | Pexels | Mohan Nannapaneni | https://www.pexels.com/photo/skyline-of-modern-skyscrapers-in-the-boston-harbor-massachusetts-usa-12754933/ |
| `long-wharf-boston_3.webp` | 25-9 | Public domain (cc0 1.0) | Emw | https://commons.wikimedia.org/w/index.php?curid=88460632 |
| `long-wharf-boston_4.webp` | 25-6 | Public domain (cc0 1.0) | Emw | https://commons.wikimedia.org/w/index.php?curid=88460630 |
| `long-wharf-boston_5.webp` | 25-1 | Pexels | Phil Evenden | https://www.pexels.com/photo/night-cityscape-with-fan-pier-park-in-boston-17424551/ |
| `long-wharf-boston_6.webp` | 25-8 | Public domain (cc0 1.0) | Emw | https://commons.wikimedia.org/w/index.php?curid=88460629 |
| `boston-marathon-finish-line_hero.webp` | 27-1 | Unsplash | Brett Wharton | https://unsplash.com/photos/a-group-of-people-standing-on-top-of-a-street-ZvPBlmp7F2g |
| `christian-science-plaza_hero.webp` | 28-1 | Pexels | Karan Dalal | https://www.pexels.com/photo/cathedral-in-city-in-winter-11012217/ |
| `christian-science-plaza_2.webp` | 28-2 | Public domain (cc0 1.0) | Daderot | https://commons.wikimedia.org/w/index.php?curid=132346430 |
| `chinatown-gate-boston_hero.webp` | 29-1 | Unsplash | Brett Wharton | https://unsplash.com/photos/snowy-street-scene-in-a-chinatown-with-people-walking-jwskDdqfUGY |
| `chinatown-gate-boston_2.webp` | 29-3 | Unsplash | Ethan Hansen | https://unsplash.com/photos/a-narrow-city-street-with-tall-buildings-on-both-sides-uyHHQ7wtA1E |
| `chinatown-gate-boston_3.webp` | 29-4 | Unsplash | Brett Wharton | https://unsplash.com/photos/chinese-archway-with-american-and-taiwanese-flags-poO-Lk9a83Q |
| `chinatown-gate-boston_4.webp` | 29-2 | Unsplash | Rina Kemppainen | https://unsplash.com/photos/busy-street-market-in-chinatown-with-traditional-archway-and-people-hFaseTAhiKM |
| `chinatown-gate-boston_5.webp` | 29-5 | Unsplash | Charlie Young | https://unsplash.com/photos/chinatown-gate-with-cars-on-street-DGcrG8IEnaU |
| `harvard-yard_hero.webp` | 30-2 | Unsplash | Arthur Tseng | https://unsplash.com/photos/a-bunch-of-chairs-that-are-in-the-grass-NRRtq0f2xC0 |
| `harvard-yard_2.webp` | 30-1 | Unsplash | Pascal Bernardon | https://unsplash.com/photos/people-standing-in-front-of-white-concrete-building-during-daytime-dLifkLvc5t8 |
| `harvard-yard_3.webp` | 30-3 | Pexels | Trần Phan Phạm Lê | https://www.pexels.com/photo/harvard-statue-and-tourists-on-sunny-day-39714010/ |
| `harvard-yard_4.webp` | 30-4 | Pexels | Gu Bra | https://www.pexels.com/photo/black-statue-of-a-man-6477521/ |
| `boston-the-other-bank_stop4.webp` | W4-4-1 | Unsplash | Michael Denning | https://unsplash.com/photos/brown-bridge-over-river-under-blue-sky-during-daytime-nFzZH0Qxy40 |
| `boston-the-other-bank_stop4-2.webp` | W4-4-2 | Unsplash | Bernd 📷 Dittrich | https://unsplash.com/photos/a-bridge-over-water-4i0VmAIIqvk |
| `boston-the-other-bank_stop4-3.webp` | W4-4-7 | Pexels | Brandon Benedict | https://www.pexels.com/photo/cars-parked-on-side-of-the-road-9715151/ |
| `boston-the-other-bank_stop4-4.webp` | W4-4-4 | Unsplash | Bernd 📷 Dittrich | https://unsplash.com/photos/esplanade-riel-with-a-blue-sky-l_zgRHPm3WM |
| `boston-the-other-bank_stop4-5.webp` | W4-4-6 | Pexels | Phil Evenden | https://www.pexels.com/photo/scenic-view-of-boston-s-skyline-and-river-29864742/ |
