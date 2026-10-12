# Makkah — Atlas audio guide scripts

Thirty-eight single-stop tours, one per listing in the Architecture-Hunter-style Makkah city guide
(Stay · Dine · Drink · Shop · Visit · Observe), written to the **atlas-audio-tour** skill:
British conversational voice, position check in paragraph two, 2–4 featured items each with a gift
detail, an editorial pivot, one `[beat]`, and an explore-further close.

**Every script was written only after its sources were fetched and read** (listed under each tour).
Where a source contradicted the original guide, the source won — see *What changed from the guide* below.

## Files

| File | What it is |
|---|---|
| `scripts/NN_slug_clean.txt` | Authoring script. Keeps `[beat]` and normal spelling. |
| `scripts/NN_slug_tts-safe.txt` | For the TTS engine. Phonetic respellings (plain lowercase-style words, no caps, no hyphens), no brackets or markup, `[beat]` replaced by a paragraph break, every number and year spelled out in full. Titles respelled where the title itself trips TTS. |
| `MAKKAH-GUIDE.md` | This file: index, coordinates, every clean script, its respelling table and its sources. |
| `source/*.txt`, `tools/build.py` | Edit the source, re-run `python3 tools/build.py`; it rebuilds both txt sets and this file, and fails if a TTS-safe file still holds a digit, hyphen, bracket, non-ASCII letter, all-caps word or unrespelled apostrophe name. |

Every script carries a `[beat]`, so every tour has a TTS-safe version.

## Access note (applies to every tour)

The haram of Makkah, everything inside the Mecca Gate boundary, is open to **Muslims only**. Mina,
Muzdalifah and Arafat are closed to ordinary visitors during the Hajj, and the Mashaaer metro runs
only in the Hajj season. Several scripts say so where it matters; none of them invites a non-Muslim
listener to enter.

## What changed from the guide — read before wiring anything

Reading the primary sources overturned five of the original picks. They are **not** scripted:

| Guide pick | What the sources showed | Action |
|---|---|---|
| **Mama Jamila Cafe** (Drink) | Google listing marked **permanently closed**. | Dropped. |
| **Al Tekkeya Café** (Drink) | Not a heritage café. Hyatt's own page: a **grab-and-go market** inside the Jabal Omar Hyatt Regency selling sandwiches, pastries and Starbucks drinks. The guide's "Ottoman takiyya" framing had no source. | Dropped. |
| **Dates Market, Al-Kakiyah** (Shop) | The only substantive source (Times Indonesia, June 2026) describes the Kakiyah market as a three-storey **general wholesale market** (perfume, clothing, prayer mats, toys), not a date souq. No source describes the OSM "سوق التمور" node. | Dropped. Re-source before re-adding. |
| **Souq al-Aziziya** (Shop) | No source describes the market itself. One aggregator placed it "a 10-minute walk from the Grand Mosque"; it is about 5 km away. | Dropped. |
| **Masjid Namirah** (Observe, paired with Arafat) | Kept inside tour 37, but the guide's claim that its western part lies outside Arafat had no source and was cut. | Folded into 37. |

Corrections made inside scripts that keep their venue:

- **Abraj Al-Bait** — designed by Dar Al-Handasah (hotel complex) with SL Rasch (the clock); built by the Saudi Binladin Group. The guide credited Dar Al-Handasah alone; the scripts name no architect for the tower, and only Dar Al-Handasah for the Jamaraat Bridge, where Wikipedia states it.
- **Al Baik** — founded in **Jeddah** (1974); first Makkah branch 1990. Wanderlog's "originated in Mecca" is wrong.
- **Hira Cultural District** — district opened January 2023; the **Holy Qur'an Museum opened March 2025**, not 2023.
- **Makkah Library** — founding year is disputed (1950, 1953, 1954 across sources); the script says "around nineteen fifty".
- **Kamal Ismail's Thassos-marble and refused-fee stories** — sourced only to magazines and a LinkedIn post; left out.

## Thin sourcing — flagged, not hidden

These venues were scripted from the Google listing (via Wanderlog's mirror of it) plus review summaries,
because no first-party website exists. Each script states only what those sources state.

- **07 Arika Um Qasem** — 9 Google ratings; one blog line. Shortest script in the set.
- **11 nootropic**, **12 Asante**, **13 Cultivo** — independent cafés with Instagram/Google presence only. Asante's FineDine menu link did not render.
- **25 Tuwa Well** — visitors report it closed for renovation at times; the script says so.
- **38 Arak Park** — DiscoverMakkah and Google listing only; no opening date found.

## Coordinates

WGS-84, as listed in the guide. Source per row: **Google** = Google's own place pin (read via Wanderlog,
which stores the Google placeId); **OSM** = OpenStreetMap; **Wikipedia** = article coordinates.
**32 Jabal Thawr** uses the OSM summit, because Google's "Thowr Mountain" pin sits ~700 m away.

## Index

| # | Category | Google Maps name | Coordinates (WGS-84) | Coord source | Words | Est. length |
|---|---|---|---|---|---|---|
| 01 | Stay | Raffles Makkah Palace | `21.419223, 39.824979` | OSM | 288 | ~1:51 |
| 02 | Stay | Fairmont Makkah Clock Royal Tower | `21.418038, 39.825302` | OSM | 301 | ~1:56 |
| 03 | Stay | Conrad Jabal Omar Makkah | `21.419329, 39.822078` | OSM | 316 | ~2:02 |
| 04 | Dine | Al Shorfa Restaurant | `21.419733, 39.82646` | Google | 270 | ~1:44 |
| 05 | Dine | Kabsa Hashi | `21.452752, 39.868801` | Google | 269 | ~1:43 |
| 06 | Dine | Al Qarmoshi Yemeni Restaurant | `21.426602, 39.807081` | Google | 252 | ~1:37 |
| 07 | Dine | Arika Um Qasem | `21.386563, 39.792393` | Google | 222 | ~1:25 |
| 08 | Dine | Al Romansiah - الرومانسية | `21.400914, 39.880772` | Google | 279 | ~1:47 |
| 09 | Dine | Al Baik Aziziya Makkah | `21.416927, 39.861186` | Google | 282 | ~1:48 |
| 10 | Drink | Cafe Moment | `21.420311, 39.823815` | Google | 296 | ~1:54 |
| 11 | Drink | nootropic cafe and roastery مقهى ومحمصة نوتروبك | `21.440653, 39.800355` | Google | 249 | ~1:36 |
| 12 | Drink | Asante Roastery \| محمصة اسانتي | `21.352867, 39.895026` | Google | 255 | ~1:38 |
| 13 | Drink | cultivo cafe and roastry  مقهى ومحمصة كالتيفو | `21.46286, 39.967878` | Google | 247 | ~1:35 |
| 14 | Shop | Abdul Samad Al Qurashi | `21.418569, 39.825599` | OSM | 288 | ~1:51 |
| 15 | Shop | Abraj Al-Bait Shopping Center | `21.418597, 39.826666` | Google | 298 | ~1:55 |
| 16 | Visit | Masjid al-Haram | `21.423658, 39.82536` | Google | 348 | ~2:14 |
| 17 | Visit | Safaa and Marwah (Saee) | `21.422076, 39.827531` | Google | 325 | ~2:05 |
| 18 | Visit | Makkah Al Mukarramah Library | `21.424907, 39.829817` | Google | 280 | ~1:48 |
| 19 | Visit | Exhibition of the Two Holy Mosques Architecture | `21.433782, 39.754361` | Google | 305 | ~1:57 |
| 20 | Visit | The Kiswa Factory of the Holy Ka'aba | `21.434722, 39.756922` | Google | 304 | ~1:57 |
| 21 | Visit | Mecca Museum | `21.446147, 39.807936` | Google | 287 | ~1:50 |
| 22 | Visit | Hira Cultural District | `21.456188, 39.869063` | Google | 302 | ~1:56 |
| 23 | Visit | Hira Cave, Mount of Light | `21.457254, 39.858974` | Google | 294 | ~1:53 |
| 24 | Visit | Bay'ah Mosque | `21.424717, 39.867493` | OSM | 231 | ~1:29 |
| 25 | Visit | Tuwa Well | `21.431619, 39.816657` | Google | 247 | ~1:35 |
| 26 | Visit | Masjid al Jinn | `21.433454, 39.828965` | OSM | 285 | ~1:50 |
| 27 | Visit | Al Muallaa Cemetery | `21.435021, 39.827908` | Google | 266 | ~1:42 |
| 28 | Visit | Aisha Al Rajhi Mosque | `21.381866, 39.873747` | Google | 259 | ~1:40 |
| 29 | Visit | Jamaraat Bridge | `21.420775, 39.873156` | OSM | 325 | ~2:05 |
| 30 | Visit | Haramain High Speed Railway - Makkah | `21.417655, 39.788532` | OSM | 308 | ~1:58 |
| 31 | Visit | Mecca Gate | `21.362361, 39.666722` | Wikipedia | 244 | ~1:34 |
| 32 | Visit | Jabal Thawr | `21.377, 39.849868` | OSM (summit) | 216 | ~1:23 |
| 33 | Observe | Al Kaaba | `21.422545, 39.82619` | Google | 309 | ~1:59 |
| 34 | Observe | Makkah Clock Tower | `21.419341, 39.825412` | Google | 282 | ~1:48 |
| 35 | Observe | Mina | `21.414605, 39.894564` | Google | 268 | ~1:43 |
| 36 | Observe | Jamarat (Mina Station 3) | `21.418396, 39.87064` | OSM | 260 | ~1:40 |
| 37 | Observe | Mt Arafat | `21.354885, 39.984116` | Google | 291 | ~1:52 |
| 38 | Observe | Arak Park | `21.383342, 39.876428` | Google | 246 | ~1:35 |

---

## 01 · Raffles Makkah Palace

**Stay** · Google Maps name: **Raffles Makkah Palace** · `21.419223, 39.824979` (OSM) · 288 words, ~1:51

Files: `scripts/01_raffles-makkah-palace_clean.txt`, `scripts/01_raffles-makkah-palace_tts-safe.txt`

### Script (clean)

Most hotels count their rooms. This one counts its suites, because there isn't a single ordinary room in the building.

The Clock Towers stand on the south side of the great plaza, facing the King Abdulaziz Gate of the mosque, and Raffles occupies part of that cluster. Its guests come and go by their own private lifts, which run straight down to the ground floor, about five minutes' walk from the mosque itself.

Start with the arithmetic, because it is rather striking. Two hundred and nineteen suites, and nothing smaller. The one-bedroom suites run to about eighty square metres, which is a decent family flat, and the largest of those facing the Kaaba stretch to around six hundred. Each one comes with the house butler service, on call around the clock.

Then think about what the building is really selling, which is the view. The best suites look directly down onto the Kaaba, and the hotel keeps its own prayer facilities overlooking the Haram, so a guest can follow the congregation below without leaving the building. Al Majlis, the fine-dining room, puts its tables out on a terrace above the mosque.

And here's the thing worth noticing. In most cities a grand hotel faces a park, a river or a promenade. In Makkah every one of these towers turns towards a single building a few hundred metres away, and the price of a room rises with how much of it you can see. The whole skyline is, in effect, a seating plan.

[beat]

If you'd like something smaller than a suite, the hotel's Creamery makes ice cream to order on a chilled teppanyaki plate, and the Narjes Tea Lounge is the quiet corner for tea and cake between prayers.

### TTS respellings

| Written | Spoken as |
|---|---|
| Al Majlis | al Majlis |
| King Abdulaziz | King Abdul Azeez |
| Kaaba | Kahbah |
| Haram | Harahm |
| Narjes | Narjis |
| teppanyaki | teppan yaki |

### Sources read

- https://www.raffles.com/makkah/
- https://all.accor.com/hotel/A5E4/index.en.shtml
- https://guide.michelin.com/en/hotels-stays/Mecca/raffles-makkah-palace-15081
- https://en.wikipedia.org/wiki/The_Clock_Towers

---

## 02 · Makkah Clock Royal Tower, a Fairmont Hotel

**Stay** · Google Maps name: **Fairmont Makkah Clock Royal Tower** · `21.418038, 39.825302` (OSM) · 301 words, ~1:56

Files: `scripts/02_makkah-clock-royal-tower-fairmont_clean.txt`, `scripts/02_makkah-clock-royal-tower-fairmont_tts-safe.txt`

### Script (clean)

The hotel is the least remarkable thing about this building, and it has one thousand, six hundred and sixty-two rooms.

From the plaza south of the mosque, look up at the tallest of the seven towers, the one carrying the four great clock faces. That is the Makkah Clock Royal Tower, six hundred and one metres to the tip of its spire, and the Fairmont runs the hotel floors inside it.

Have a look at the clock first. Each face is forty-three metres across, the largest clock faces anywhere, and the clock sits higher above the ground than any other in the world. The hotel beneath it is built on the same scale: more than sixteen hundred rooms and suites, many of them fitted with speakers that carry the sound of the Haram, so the call to prayer reaches you in your room.

Then there is the hotel within the hotel. Fairmont Gold has its own entrance, its own reception and its own lifts, with private prayer rooms looking over the Kaaba, and a restaurant the hotel describes as the highest in Makkah.

What's worth knowing, standing here, is what the tower replaced. This hill once carried the Ajyad Fortress, an Ottoman citadel built in seventeen eighty to protect the sanctuary from raiders. It was demolished in January two thousand and two, and Turkey protested loudly. So the tallest building in the city now stands where an old fort once kept watch over the mosque, and in its own way it has taken over the job.

[beat]

Before you leave the plaza, wait for the next call to prayer and keep your eyes on the crown of the tower. Its lights flash in time with the prayer, and on a clear night they can be seen from far out across the valley.

### TTS respellings

| Written | Spoken as |
|---|---|
| Kaaba | Kahbah |
| Haram | Harahm |
| Ajyad | Ajyaad |

### Sources read

- https://www.fairmont.com/en/hotels/makkah/makkah-clock-royal-tower.html
- https://en.wikipedia.org/wiki/The_Clock_Towers
- https://en.wikipedia.org/wiki/Ajyad_Fortress

---

## 03 · Conrad Jabal Omar Makkah

**Stay** · Google Maps name: **Conrad Jabal Omar Makkah** · `21.419329, 39.822078` (OSM) · 316 words, ~2:02

Files: `scripts/03_conrad-jabal-omar-makkah_clean.txt`, `scripts/03_conrad-jabal-omar-makkah_tts-safe.txt`

### Script (clean)

Until two thousand and six, this was a hillside of old houses. What you are looking at is the hill's replacement.

The Conrad stands in Jabal Omar, the district rising just south-west of the mosque plaza, along Jabal Omar Street. Look for a pair of hotel towers set into a dense cluster of new buildings that crowds right up to the edge of the plaza.

Start with the name. Jabal Omar was a real hill on the old southern edge of the city, covered in housing that had grown up piecemeal over generations. In late two thousand and six a clearance began, and a development company was set up with an initial budget of one point six billion dollars and plans for more than ninety buildings, with Foster and Partners and Buro Happold among the designers.

The Conrad was the fourth hotel to open here, after the Hilton, the Hyatt Regency and the Marriott, and it was the first Conrad anywhere in Saudi Arabia. It has four hundred and thirty-eight rooms across its two towers, sixty-two of them suites, and most look towards the Haram.

Inside, the designers reached back to the city that was cleared. There are mashrabiya screens, the carved wooden latticework that once shaded Hijazi windows, an inner courtyard in the manner of a traditional sahn, chandeliers patterned with leaves, and Qur'anic verses worked into the walls and ceilings.

And that is the tension of the place. The old houses are gone, and their vocabulary has come back indoors as decoration. The grand plan has not been finished either: as of two thousand and twenty-four, the original vision was still unrealised.

[beat]

Walk down to the south-west corner of the mosque plaza if you fancy it. That is where the fifteen towers of the Jabal Omar complex meet the sanctuary, and you can see the whole idea of the project in a single glance.

### TTS respellings

| Written | Spoken as |
|---|---|
| Jabal Omar | Jabbal Omar |
| Qur'anic | Koranic |
| Haram | Harahm |
| Hijazi | Hijaazi |
| mashrabiya | mashrabeeya |

### Sources read

- https://www.tradearabia.com/news/TTN_313707.html
- https://www.forbestravelguide.com/hotels/makkah-saudi-arabia/conrad-makkah-jabal-omar
- https://en.wikipedia.org/wiki/Jabal_Omar

---

## 04 · Al Shorfa Restaurant

**Dine** · Google Maps name: **Al Shorfa Restaurant** · `21.419733, 39.82646` (Google) · 270 words, ~1:44

Files: `scripts/04_al-shorfa-restaurant_clean.txt`, `scripts/04_al-shorfa-restaurant_tts-safe.txt`

### Script (clean)

Shorfa means balcony, and that tells you most of what you need to know.

Al Shorfa is on the eleventh floor of Al Marwa Rayhaan by Rotana, one of the towers of the Abraj Al Bait complex on the south side of the mosque plaza. Take the hotel lifts up and walk out onto the terrace. In front of you, across the plaza and over the King Abdulaziz Gate, you should be looking straight into the mosque, with the Kaaba at its centre.

The view is the point, so take that in first. The hotel promises an uninterrupted line of sight to the Kaaba, and it seats you outdoors on the terrace to make the most of it. From eleven floors up the circling crowd around the Kaaba becomes a single slow-moving ring, which is something you simply cannot see from the ground.

The food is a mix of Arabic and international cooking, served as a buffet or from the menu, and it is open for dinner. Regulars recommend the kabsa, and you can ask the kitchen for a proper strong karak chai if it isn't on the table. There are private family spaces too, if you would rather eat out of view.

Here's what I find interesting. Most restaurants with a view are selling you a skyline or a sunset. This one is selling a single building, and the meal is really an excuse to sit and watch it for an hour.

[beat]

Come back after the sunset prayer, when the plaza below empties and then fills again within minutes. From up here, you can watch the whole tide turn.

### TTS respellings

| Written | Spoken as |
|---|---|
| Al Marwa Rayhaan | al Marwa Rayhaan |
| Abraj Al Bait | Abraj al Bayt |
| Al Shorfa | al Shorfa |
| King Abdulaziz | King Abdul Azeez |
| Kaaba | Kahbah |

### Sources read

- https://www.rotana.com/rayhaanhotelandresorts/kingdomofsaudiarabia/makkah/almarwarayhaanbyrotana/diningout/alshorfa
- https://wanderlog.com/place/details/1179033 (Google listing + review summary)
- https://halalbooking.com/en/umrah/makkah/food-guide

---

## 05 · Kabsa Hashi

**Dine** · Google Maps name: **Kabsa Hashi** · `21.452752, 39.868801` (Google) · 269 words, ~1:43

Files: `scripts/05_kabsa-hashi_clean.txt`, `scripts/05_kabsa-hashi_tts-safe.txt`

### Script (clean)

Hashi is the Arabic word for a young camel, so there is no mystery about what's on the menu here.

Kabsa Hashi sits on King Faisal Road, near the foot of Jabal al-Nour, the Mountain of Light. Step inside and you'll notice there are no tables in the main dining area. The floor is carpeted, and you sit on it, the way meals have long been eaten in this part of the world.

Start with the house dish, which shares its name with the restaurant: kabsa hashi, spiced rice piled high and topped with camel meat. There is a camel mandi as well, the meat cooked slowly until it falls from the bone, and a bowl of camel soup for anyone who would rather start gently. The portions are generous, and they are meant for sharing.

Camel is the real reason to come. It is a meat most visitors have never tasted, and in Saudi Arabia young camel is treated as something of a delicacy rather than a novelty. The long, slow cooking is what makes it tender, and reviewers keep coming back to the word juicy.

And sitting on the floor matters more than it sounds. You eat from a shared platter, close to the people you came with, which is exactly how kabsa is meant to be eaten, and the whole meal slows down to match.

[beat]

If you've just come down from the cave of Hira, this is the obvious place to recover. And if you are heading up, the Hira Cultural District is only a few minutes along the road at the foot of the mountain.

### TTS respellings

| Written | Spoken as |
|---|---|
| Jabal al-Nour | Jabbal an Noor |
| Hira | Heera |
| hashi | haashee |
| Hashi | Haashee |
| mandi | mandee |

### Sources read

- https://wanderlog.com/place/details/2813421/kabsa-hashi (Google listing + review summary)
- https://magicpin.com/saudi-arabia/Mecca/Al-Sulaimaniyyah-Mecca/Restaurant/Kabsa-Hashi-Restaurant/store/2287437
- https://halalxplorer.com/the-food-and-drink-scene-in-makkah-and-madinah-saudi-arabia/

---

## 06 · Al Qarmoshi Yemeni Restaurant

**Dine** · Google Maps name: **Al Qarmoshi Yemeni Restaurant** · `21.426602, 39.807081` (Google) · 252 words, ~1:37

Files: `scripts/06_al-qarmoshi-yemeni-restaurant_clean.txt`, `scripts/06_al-qarmoshi-yemeni-restaurant_tts-safe.txt`

### Script (clean)

Makkah has always been fed by its neighbours, and at breakfast time the neighbour doing the feeding is Yemen.

Al Qarmoshi is on Prince Mansour Street in At Taysir, west of the mosque. It is a plain, busy breakfast place, and the thing to know is that its bread comes hot from a tannour, the traditional clay oven.

Have a look at what comes out of that oven first. Tamees is a broad, blistered flatbread, and here it is served hot with a double layer of cheese, best torn up and eaten with a glass of strong black tea. Then there is masoub, the dish people come back for, a sweet, soft breakfast of mashed bread, finished with cream and honey. Regulars also point you towards the mutabbaq, the stuffed and folded pancake that turns up all over the Hijaz.

It is quick, it is reasonably priced, and the staff are friendly, which is why it is popular with people slipping in for a meal before heading back to prayers.

What's worth thinking about is how at home a Yemeni breakfast feels here. This is a city made by people arriving from everywhere else, and its breakfast table shows it. Bread from a clay oven, honey and cream are as much a part of a Makkah morning as anything from the Hijaz itself.

[beat]

If you fancy comparing notes, the city has a second Yemeni breakfast tradition worth hunting down. Look for areeka, the honey-soaked bread dish, at Arika Um Qasem in Ash-Shawqiyyah.

### TTS respellings

| Written | Spoken as |
|---|---|
| Ash-Shawqiyyah | ash Shawkeeya |
| At Taysir | at Taiseer |
| Arika Um Qasem | Areeka Oom Kaasim |
| Al Qarmoshi | al Karmooshee |
| Hijaz | Hijaaz |
| Mansour | Mansoor |
| tannour | tanoor |
| masoub | masoob |
| mutabbaq | mutabbak |

### Sources read

- https://wanderlog.com/place/details/8582028 (Google listing + review summary)
- https://halalxplorer.com/the-food-and-drink-scene-in-makkah-and-madinah-saudi-arabia/

---

## 07 · Arika Um Qasem

**Dine** · Google Maps name: **Arika Um Qasem** · `21.386563, 39.792393` (Google) · 222 words, ~1:25

Files: `scripts/07_arika-um-qasem_clean.txt`, `scripts/07_arika-um-qasem_tts-safe.txt`

### Script (clean)

Some restaurants are named after their owner. This one is named after its dish, and it doesn't need to explain itself.

Arika Um Qasem is on Nasr bin al-Harith bin Kaab Street in Ash-Shawqiyyah, a residential district in the south-west of the city. Come early in the morning, which is when it matters, and you'll likely find a queue at the counter.

The dish is areeka. It starts as wheat bread, crumbled and worked into a dense, warm mound, then soaked with ghee and honey. Here it comes with cream and dates as well. It is rich, it is filling, and it is meant to be shared.

Areeka is usually linked with Asir, the mountains in the south-west of the kingdom, and it is eaten as a breakfast speciality in Yemen too. It has travelled to Makkah with the people who came here from both places, and this restaurant now has several branches across the city to prove it found an audience.

I think there's something rather lovely about a dish that refuses to be hurried. Areeka is made by hand, eaten by hand, and doesn't really work as a takeaway.

[beat]

Get here before the morning rush if you can, and order it with a pot of Arabic coffee. The bitterness of the coffee is the perfect partner for all that honey.

### TTS respellings

| Written | Spoken as |
|---|---|
| Nasr bin al-Harith bin Kaab Street | Nasr bin al Haarith bin Kaab Street |
| Ash-Shawqiyyah | ash Shawkeeya |
| Arika Um Qasem | Areeka Oom Kaasim |
| Asir | Aseer |

### Sources read

- https://wanderlog.com/place/details/8582086 (Google listing)
- https://halalxplorer.com/the-food-and-drink-scene-in-makkah-and-madinah-saudi-arabia/
- Saudipedia: العريكة (Arika)

---

## 08 · Al Romansiah

**Dine** · Google Maps name: **Al Romansiah - الرومانسية** · `21.400914, 39.880772` (Google) · 279 words, ~1:47

Files: `scripts/08_al-romansiah_clean.txt`, `scripts/08_al-romansiah_tts-safe.txt`

### Script (clean)

Every Saudi family has an opinion on where to get the best kabsa. A very large number of them will name this chain.

This branch of Al Romansiah is on Al Masjid Al Haram Road in Al Mursalat, on the eastern side of the city towards Mina. Inside you'll find two ways to eat: ordinary tables, or private family cabins, where you can sit on the floor in the traditional way, out of sight of the rest of the room.

Start with the menu, because it is a tour of Saudi rice cookery. Kabsa is the national dish, rice cooked in a spiced broth and crowned with meat. Mandi is the Yemeni way, the meat cooked slowly in a pit or oven. And madghout is chicken pressure-cooked with the rice so the flavour goes all the way through. Regulars also single out the maqluba, the upside-down dish of rice and vegetables turned out onto the plate at the table.

Al Romansiah was founded in nineteen ninety-seven, and it has grown to around forty-seven branches across Saudi Arabia, with one in Bahrain. In September two thousand and twenty-five it received approval from the Saudi market regulator to float on the stock exchange.

What's worth noticing is that a dish from the family kitchen has become a national brand without losing its manners. The cabins exist because families still want to eat together on the floor, privately, even in a restaurant.

[beat]

Go at a quiet hour if you can, as the queue at the cashier can be long at mealtimes. And if you're unsure what to order, ask how long each dish takes. The slow ones are usually worth the wait.

### TTS respellings

| Written | Spoken as |
|---|---|
| Al Masjid Al Haram Road | Masjid al Harahm Road |
| Al Mursalat | al Mursalaat |
| Al Romansiah | al Romanseeya |
| Mina | Meena |
| madghout | madghoot |
| maqluba | makloobah |

### Sources read

- https://www.agbi.com/companies/al-romansiah
- https://www.alromansiah.com/al-romansiah-restaurants-promoted-the-quality-and-distinct-service-in-its-new-identity
- https://wanderlog.com/place/details/3964496 (Google listing + review summary)

---

## 09 · Al Baik Aziziya Makkah

**Dine** · Google Maps name: **Al Baik Aziziya Makkah** · `21.416927, 39.861186` (Google) · 282 words, ~1:48

Files: `scripts/09_al-baik-aziziya-makkah_clean.txt`, `scripts/09_al-baik-aziziya-makkah_tts-safe.txt`

### Script (clean)

Almost every visitor to Makkah ends up in an Al Baik queue at some point. Very few know the story behind the chicken.

This branch is in Aziziyah, on the eastern side of the city between the mosque and Mina. Look for the red and white sign, and very probably a queue in front of it.

The founder was Shakour Abu Ghazalah, a Palestinian who arrived in Saudi Arabia after nineteen forty-eight and worked for Aramco for around fifteen years. In September nineteen seventy-four he opened a fried chicken restaurant in a converted warehouse on Airport Road in Jeddah. It was called simply Broast.

He died in nineteen seventy-six, and his sons Ihsan and Rami inherited a business that had lost its supply agreement and owed a bank seven million riyals. Ihsan, who had studied food technology in Paris, worked out a new recipe in nineteen eighty-four, a blend of eighteen herbs and spices, and the brothers mixed it themselves in the evenings at a secret location. The name Albaik, from a Turkish honorific roughly meaning sir, arrived in nineteen eighty-six.

The pilgrims came next. From nineteen eighty-eight the company was feeding them in Mina during the Hajj, and the first Makkah restaurant opened in nineteen ninety.

And that is why the queue here is worth joining at least once. This isn't a foreign chain that turned up in Makkah. It grew up alongside the pilgrimage itself, and for millions of people it has become part of the memory of the journey.

[beat]

Order the broast, the dish that started it all. Then carry on east along the main road towards Mina, if you fancy seeing where Al Baik first fed the pilgrims.

### TTS respellings

| Written | Spoken as |
|---|---|
| Shakour Abu Ghazalah | Shakoor Aboo Ghazaala |
| Al Baik Aziziya Makkah | al Bayk Azeezeeya Makkah |
| Al Baik | al Bayk |
| Albaik | al Bayk |
| Mina | Meena |
| Aziziyah | Azeezeeya |
| Ihsan | Ihsaan |
| Rami | Raamee |

### Sources read

- https://familybusinesshistories.org/spotlights/albaik/
- https://en.wikipedia.org/wiki/Albaik
- https://wanderlog.com/place/details/1179083/al-baik-aziziya-makkah

---

## 10 · Cafe Moment

**Drink** · Google Maps name: **Cafe Moment** · `21.420311, 39.823815` (Google) · 296 words, ~1:54

Files: `scripts/10_cafe-moment_clean.txt`, `scripts/10_cafe-moment_tts-safe.txt`

### Script (clean)

The best seat in this café is a window, and you'll probably have to wait your turn for it.

Cafe Moment is near the Clock Tower, opposite the Swissôtel, but it is rather well hidden. Go into the shopping complex, take the stairs or lift to the second floor, and walk past the perfume and abaya shops until you reach the café, tucked into one of the corners. If you're lost, show a shopkeeper or a security guard a photograph of the entrance, and they'll point you the right way.

Once you're in, look for the windows on the mosque side. From here you look straight down over the entrance and courtyard of the Haram, with the crowds moving in and out below you. The good tables carry a minimum spend, and the window seats are in such demand that you may only get them for a while.

Then order properly. The drink to have is Arabic coffee, qahwa, pale and spiced with cardamom and served with dates, or a sweet karak tea if you'd rather. Drinks arrive in traditional pots, each matched to what's inside, and when the tea comes a waiter may light a little bakhoor, the incense that scents a Gulf home, which burns for about a minute. There are fountains in the room and live birds, which is more theatre than most cafés attempt.

And here's what I like about it. Most people pass this view in a hurry, on their way to or from prayer. The café's whole proposition is that you should sit still and watch it for a while instead.

[beat]

Come in the afternoon, when it's quieter, and try the honey cake with your coffee. Then go down and join the flow of people you've been watching from above.

### TTS respellings

| Written | Spoken as |
|---|---|
| Swissôtel | Swissotel |
| cafés | cafes |
| café | cafe |
| Haram | Harahm |
| qahwa | kahwa |
| bakhoor | bukhoor |

### Sources read

- https://halalxplorer.com/cafe-moment-cafe-with-the-best-view-in-makkah/
- https://wanderlog.com/place/details/5678990/cafe-moment (Google listing + review summary)

---

## 11 · nootropic cafe and roastery

**Drink** · Google Maps name: **nootropic cafe and roastery مقهى ومحمصة نوتروبك** · `21.440653, 39.800355` (Google) · 249 words, ~1:36

Files: `scripts/11_nootropic-cafe-and-roastery_clean.txt`, `scripts/11_nootropic-cafe-and-roastery_tts-safe.txt`

### Script (clean)

A nootropic is anything said to sharpen the mind, so this café has set itself a high bar before you've even ordered.

Nootropic cafe and roastery is on Al Hajun Street, in the Az-Zahir district north-west of the mosque, and it is a neighbourhood café rather than a pilgrim stop. It is easy to miss, so keep an eye on the shopfronts as you walk.

Have a look at the room first. It is small and cosy, and regulars describe the atmosphere as calming, with traditional Gulf songs playing in the background rather than the usual café soundtrack. That one detail tells you who this place is for.

Then the coffee, which is the reason to come. It is a roastery as well as a café, so the beans are chosen and roasted here, and the drinks people talk about are the cortado and the lattes. The staff are happy to talk you through what they are brewing, and it is worth asking.

What's worth noticing is how much Makkah's coffee has changed. This is a city where coffee has always been served, pale and spiced, as an act of hospitality. A specialty roaster playing Gulf music while it pulls a cortado is a younger generation keeping both traditions at once.

[beat]

From here it is a short trip along the Madinah Road to the Mecca Museum in the old Al-Zahir Palace. Have your coffee first, and then go and see how the city looked before cafés like this existed.

### TTS respellings

| Written | Spoken as |
|---|---|
| Al-Zahir Palace | al Zaahir Palace |
| Az-Zahir | az Zaahir |
| Al Hajun | al Hajoon |
| cafés | cafes |
| café | cafe |
| nootropic | noo tropic |
| Nootropic | Noo tropic |

### Sources read

- https://wanderlog.com/place/details/3966607 (Google listing + review summary)

---

## 12 · Asante Roastery

**Drink** · Google Maps name: **Asante Roastery | محمصة اسانتي** · `21.352867, 39.895026` (Google) · 255 words, ~1:38

Files: `scripts/12_asante-roastery_clean.txt`, `scripts/12_asante-roastery_tts-safe.txt`

### Script (clean)

Asante is the Swahili word for thank you, which is a nice thing to have written over the door of a coffee shop.

This branch is on Ibrahim Al Joufaili Street in Al Awali, a newer residential district in the south of the city, well away from the pilgrim crowds. It has an outdoor seating area, which is where you want to be once the heat goes out of the day.

Start with the coffee, which is what the roastery is for. Ask what is on the pour-over list. Regulars point you towards a V60 of Ethiopian coffee from Hambela, and the cortado is a dependable order if you'd rather not choose.

Then the cake counter, which has rather a following of its own. The mango cheesecake is the one regulars insist on, and there is a menu of light dishes, sandwiches and cold drinks for anyone staying a while.

Here's the thing worth knowing. Al Awali is not on any pilgrim's itinerary. It is where people who live in Makkah go about their ordinary lives, and a place like this is where they meet friends, rather than where visitors stop between prayers. Sitting here, you see a side of the city most visitors never do.

[beat]

It can get busy, and the wait for food can stretch at peak times, so come at a quieter hour and take your time over a pour-over. Then have a wander through the surrounding streets, which show you a Makkah of family homes and corner shops rather than hotels.

### TTS respellings

| Written | Spoken as |
|---|---|
| Ibrahim Al Joufaili Street | Ibraheem al Jufailee Street |
| Al Awali | al Awaalee |
| Hambela | Hambella |
| Asante | Asantay |
| V60 | vee sixty |

### Sources read

- https://wanderlog.com/place/details/4525955 (Google listing + review summary)
- https://qr.finedinemenu.com/asante-coffee-or-al-awali (menu; page did not render)

---

## 13 · Cultivo Cafe and Roastry

**Drink** · Google Maps name: **cultivo cafe and roastry  مقهى ومحمصة كالتيفو** · `21.46286, 39.967878` (Google) · 247 words, ~1:35

Files: `scripts/13_cultivo-cafe-and-roastry_clean.txt`, `scripts/13_cultivo-cafe-and-roastry_tts-safe.txt`

### Script (clean)

To cultivate is to grow something with care, which is a fair description of what happens to the coffee here.

Cultivo is on Al Qadisiyyah Road in Ar-Rashidiyyah, in the north-east of the city, a long way from the Haram. Look for the café sign, in Arabic and English, and step inside.

The first thing regulars mention is the room. More than one visitor has said the design reminds them of Greece, as if it had transported them somewhere else entirely, and it is a deliberately peaceful space in a city that rarely stops moving.

Then the coffee. Cultivo roasts its own beans, and the single-origin list is the point. The Colombian brewed through a V60 has its admirers, and the Ugandan espresso has been described, memorably, as brain-hitting. If you see a Cup of Excellence coffee on the board, that is a lot that has been judged in competition, and it is worth trying while it lasts. To eat, the banoffee pie is the house favourite.

What's worth noticing is the care. Reviewers keep praising the preparation of each cup, and the staff by name, which is rarely what people remember about a café. Here, the ritual of making the coffee is as much the attraction as the result.

[beat]

Ask the barista what has just been roasted and let them choose for you. Then, if you're heading back towards the centre, take the road past Jabal al-Nour and look up at the mountain on your way.

### TTS respellings

| Written | Spoken as |
|---|---|
| Jabal al-Nour | Jabbal an Noor |
| Ar-Rashidiyyah | ar Rasheedeeya |
| Al Qadisiyyah Road | al Kaadiseeya Road |
| café | cafe |
| Haram | Harahm |
| Cultivo | Kultivo |
| V60 | vee sixty |

### Sources read

- https://wanderlog.com/place/details/9573411 (Google listing + review summary)

---

## 14 · Abdul Samad Al Qurashi

**Shop** · Google Maps name: **Abdul Samad Al Qurashi** · `21.418569, 39.825599` (OSM) · 288 words, ~1:51

Files: `scripts/14_abdul-samad-al-qurashi_clean.txt`, `scripts/14_abdul-samad-al-qurashi_tts-safe.txt`

### Script (clean)

Long before the clock towers, Makkah traded in scent. This shop is one of the places where that trade still lives.

Abdul Samad Al Qurashi has a shop in the Abraj Al Bait complex, on the south side of the mosque plaza, among the shopping floors beneath the Clock Tower. Inside, you'll find shelves of small bottles of perfume oil, and an assistant ready to dab one on your wrist.

Start with oud, the house speciality. It is the resinous heartwood of the agarwood tree, which is distilled into a dark, smoky oil, and pure oud oils are what this family made its name on. The house also works with Taif rose, from the mountain city above Makkah, and still processes many of its own raw materials.

The family history begins here too. It started in eighteen fifty-two as a business processing oud, and in nineteen thirty-two Sheikh Abdul Samad Al Qurashi expanded it, began making his own perfumes and opened his first shop in Makkah. His sons later ran four separate perfume houses, then merged them back together under their father's name. The company is still headquartered in this city, and outside the Arab world it has had just one shop of its own, in Paris.

And that is the editorial point. In a district that has been almost entirely rebuilt, scent is one of the few things that connects the modern mall to the old market town. The bottles have changed. The smell has not.

[beat]

Ask to try a little oud oil on the back of your wrist, and leave it for a few minutes before you judge it. Oud opens slowly, and the scent you walk out with won't be the one you first smelled.

### TTS respellings

| Written | Spoken as |
|---|---|
| Abdul Samad Al Qurashi | Abdul Samad al Kurayshee |
| Abraj Al Bait | Abraj al Bayt |
| Taif | Taa if |

### Sources read

- https://www.parfumo.com/PerfumeBrand/Abdul_Samad_Al_Qurashi
- https://beautyworld-middle-east.ae.messefrankfurt.com/dubai/en/exhibitor-search.detail.html/abdul-samad-al-qurashi.html
- https://www.ampliz.com/company/abdul-samad-al-qurashi/83586998

---

## 15 · Abraj Al-Bait Shopping Center

**Shop** · Google Maps name: **Abraj Al-Bait Shopping Center** · `21.418597, 39.826666` (Google) · 298 words, ~1:55

Files: `scripts/15_abraj-al-bait-shopping-center_clean.txt`, `scripts/15_abraj-al-bait-shopping-center_tts-safe.txt`

### Script (clean)

It looks like a shopping centre. It is also the base of a building with a clock tower on top.

The Abraj Al-Bait Shopping Center fills the lower floors of the Clock Towers complex, on the south side of the mosque plaza, directly opposite the King Abdulaziz Gate. Step in from the plaza and you are standing in the podium that carries all seven towers above you.

Have a look at the scale first. The mall runs over five storeys, and beneath it there is parking for more than a thousand cars. Above it rise seven hotel towers, the tallest six hundred and one metres high, together housing tens of thousands of pilgrims within a few minutes' walk of the mosque. The whole complex, built by the Saudi Binladin Group, cost around fifteen billion dollars.

Then think about the ground under your feet. This was Bulbul hill, a spur of Jabal Kuda, crowned by the Ajyad Fortress, an Ottoman citadel from seventeen eighty. In January two thousand and two, the fortress was demolished and most of the hill was levelled to make way for what you see now.

And here's the real question the building asks. The Guardian once criticised projects like this for turning a city of low courtyard houses and narrow lanes into stacks of standardised concrete slabs. The other side of the argument is in the corridors around you: millions of pilgrims, housed, fed and sheltered within sight of the Kaaba. Both things are true at once, and this mall is where they meet.

[beat]

Before you leave, find a window on one of the upper floors that faces north. From inside the mall you can look straight across the plaza to the mosque, which is rather an unusual view to get from a shopping centre.

### TTS respellings

| Written | Spoken as |
|---|---|
| Jabal Kuda | Jabbal Kooda |
| Abraj Al-Bait Shopping Center | Abraj al Bayt Shopping Centre |
| Saudi Binladin Group | Saudi Bin Laden Group |
| King Abdulaziz | King Abdul Azeez |
| Kaaba | Kahbah |
| Ajyad | Ajyaad |

### Sources read

- https://en.wikipedia.org/wiki/The_Clock_Towers
- https://en.wikipedia.org/wiki/Ajyad_Fortress

---

## 16 · Masjid al-Haram

**Visit** · Google Maps name: **Masjid al-Haram** · `21.423658, 39.82536` (Google) · 348 words, ~2:14

Files: `scripts/16_masjid-al-haram_clean.txt`, `scripts/16_masjid-al-haram_tts-safe.txt`

### Script (clean)

You are standing in front of a building that has been expanded, again and again, for almost fourteen centuries, and the parts it has kept are the parts worth looking for.

From the great plaza on the south side, face the King Abdulaziz Gate, with the Clock Towers at your back. Ahead of you is the Masjid al-Haram, the Sacred Mosque, wrapped around the Kaaba at its centre, and stretching away to your left and right much further than you can see from here.

Start with the oldest layer, which is deep inside, around the courtyard. In fifteen seventy, Sultan Selim the Second commissioned Mimar Sinan, the great Ottoman architect, to renovate the mosque. His team replaced the flat roof of the arcades with domes, decorated inside with calligraphy, and set new columns beneath them. Those Ottoman arcades are the oldest surviving parts of the building.

Then come the Saudi layers. The first expansion, between nineteen fifty-five and nineteen seventy-six, roofed in the processional route between Safa and Marwa and added minarets, but it also pulled down much of the Ottoman work. A second expansion under King Fahd, from nineteen eighty-six, added a whole new wing, reached through the King Fahd Gate. The architect most often credited with the Saudi expansions is Mohamed Kamal Ismail, an Egyptian who lived to ninety-nine. The third, begun under King Abdullah, pushed north across three hundred thousand square metres, its halls hung with thousands of gilded chandeliers made in Vienna.

And here's the thing. Every one of those expansions answers the same question: how do you let more people stand in the same place? Over the centuries the answer has meant marble, escalators, air conditioning and, in the end, the demolition of much of the old city around it. The building's real design brief has always been the crowd.

[beat]

When you go in, make your way to the courtyard and look for the arcades crowned with small domes. They are Sinan's, more than four hundred and fifty years old, and they are the oldest part of the building you can see today.

### TTS respellings

| Written | Spoken as |
|---|---|
| Mohamed Kamal Ismail | Mohammed Kamaal Ismaeel |
| Masjid al-Haram | Masjid al Harahm |
| Mimar Sinan | Meemar Sinahn |
| Sinan's | Sinahn's |
| Selim the Second | Seleem the Second |
| King Abdulaziz | King Abdul Azeez |
| Kaaba | Kahbah |

### Sources read

- https://en.wikipedia.org/wiki/Great_Mosque_of_Mecca
- https://en.wikipedia.org/wiki/Mohamed_Kamal_Ismail

---

## 17 · Safaa and Marwah (Saee)

**Visit** · Google Maps name: **Safaa and Marwah (Saee)** · `21.422076, 39.827531` (Google) · 325 words, ~2:05

Files: `scripts/17_safa-and-marwah_clean.txt`, `scripts/17_safa-and-marwah_tts-safe.txt`

### Script (clean)

This is the only corridor I know that is built around a mother looking for water.

Inside the mosque, on its eastern side, follow the signs for the Mas'a, the gallery of the sa'i. You should find yourself at one end of a long, straight, enclosed walkway, its far end disappearing into the distance. At each end is one of two small hills, Safa and Marwa.

Start with the story, because it explains everything else. Muslim tradition holds that Hajar, the wife of Abraham, ran between these two hills seven times, searching for water for her infant son Ismail, until the spring of Zamzam appeared. Pilgrims repeat her journey as part of Hajj and Umrah, seven lengths between Safa and Marwa, which adds up to about two thousand seven hundred and sixty metres on foot.

Then look at the gallery itself. The hills were once separate from the mosque, with the route between them running through the old city. The first Saudi expansion roofed it over and brought it inside. Then, from two thousand and eight, the gallery was doubled in width from twenty metres to forty, and raised to four floors. The distance between the hills is three hundred and ninety-four metres, and the space for walking grew from around twenty-nine thousand square metres to more than eighty-seven thousand.

What I find moving is that all of that engineering serves a single, very human gesture. The marble, the air conditioning and the four levels exist so that millions of people can retrace the anxious footsteps of one woman, in exactly the same place.

[beat]

If you're walking it yourself, count your laps as you go: Safa to Marwa is one, Marwa back to Safa is two, and the seventh ends at Marwa. And if you're simply watching, go up to one of the higher floors and look down the full length of the gallery, with four storeys of people all moving in the same direction.

### TTS respellings

| Written | Spoken as |
|---|---|
| Safaa and Marwah (Saee) | Safa and Marwa |
| Mas'a | Masaa |
| sa'i | sa ee |
| Hajar | Haajar |
| Umrah | Umra |
| Ismail | Ismaeel |

### Sources read

- https://saudipedia.com/en/article/1509/religion/the-grand-mosque/what-is-al-masaa
- https://en.wikipedia.org/wiki/Great_Mosque_of_Mecca

---

## 18 · Makkah Al Mukarramah Library

**Visit** · Google Maps name: **Makkah Al Mukarramah Library** · `21.424907, 39.829817` (Google) · 280 words, ~1:48

Files: `scripts/18_makkah-al-mukarramah-library_clean.txt`, `scripts/18_makkah-al-mukarramah-library_tts-safe.txt`

### Script (clean)

This is a small, plain building with a very large claim to make about the ground it stands on.

Walk out of the mosque on its eastern side, towards the open plaza by the Safa end. On the plaza, look for a modest, rectangular two-storey building standing on its own, with its main façade turned west, towards the mosque. That is the Makkah Al Mukarramah Library.

Start with what lies beneath it. The library is also known as Bayt al-Mawlid, the House of the Birth, because it is believed to stand on the spot where the Prophet Muhammad was born. Whatever stood here before was levelled under early Saudi rule, out of concern that it would become a focus of excessive veneration.

Then the library itself. It was founded by Sheikh Abbas Qattan, around nineteen fifty, built on the old foundations and stocked with a collection of books he had bought and donated. It is two small floors, a main hall and a few rooms, and that is all. Accounts of the exact year differ, but none of them describes anything grander.

And here's the point worth pausing on. Look around and you'll see some of the largest buildings in the world, put up in the last twenty years. This one is tiny and old-fashioned, and that is exactly why it still stands. It survives because it asks so little of the visitor: not a shrine, not a monument, just a library.

[beat]

Stand at the west façade and turn round to face the mosque. The two buildings look at each other across the plaza, one enormous and one hardly noticed, and the smaller of them is arguably the older idea.

### TTS respellings

| Written | Spoken as |
|---|---|
| Makkah Al Mukarramah Library | Makkah al Mukarrama Library |
| Abbas Qattan | Abbas Kattaan |
| Bayt al-Mawlid | Bait al Mowlid |
| façade | facade |

### Sources read

- https://www.islamiclandmarks.com/makkah-other/birthplace-of-the-prophet-saw
- https://muslim.sg/articles/5-historical-places-to-visit-in-makkah
- https://muhammadencyclopedia.com/article/first-demolition-and-re-construction-of-the-birthplace-of-prophet-muhammad

---

## 19 · Exhibition of the Two Holy Mosques Architecture

**Visit** · Google Maps name: **Exhibition of the Two Holy Mosques Architecture** · `21.433782, 39.754361` (Google) · 305 words, ~1:57

Files: `scripts/19_exhibition-two-holy-mosques-architecture_clean.txt`, `scripts/19_exhibition-two-holy-mosques-architecture_tts-safe.txt`

### Script (clean)

If you want to understand how the Grand Mosque became what it is, start here, ten kilometres away, in a single exhibition building in Umm al-Joud.

The Exhibition of the Two Holy Mosques Architecture sits in the Umm al-Joud district on the western edge of the city, just beside the Kiswa factory. It is a museum building of about twelve hundred square metres, divided into seven halls, beginning with a reception hall set around a large model of the Grand Mosque.

Find the Kaaba hall first. Among old coverings and doors, there is a wooden pillar believed to date from around the sixty-fifth year after the Hijra, from the rebuilding of the Kaaba under Abdullah ibn al-Zubayr. Close by is a door of the Kaaba from nineteen forty-four, made in the reign of King Abdulaziz.

Then go and find the staircase. It is a carved teak ladder on wheels, dating from the eighteen-twenties, which was rolled up to the Kaaba so the door, set more than two metres above the ground, could be reached. There is also a rain spout from the roof of the Kaaba, from early in the seventeenth century.

And save a few minutes for the photographs. The rare photographs hall has pictures of Makkah and Madinah taken in eighteen seventy-nine and eighteen ninety by the Egyptian photographer Sadeq Bek, which show you the city before almost everything around the mosque was rebuilt.

That's the real gift of the place. The mosque today is all scale, and here you see it at human size, in wood, stone and metal you could reach out and touch.

[beat]

In the Zamzam hall, look out for a sundial from sixteen fourteen and, near it, the first clock ever installed in the Grand Mosque, in nineteen thirty-three. Then walk next door to see the Kiswa being made.

### TTS respellings

| Written | Spoken as |
|---|---|
| Abdullah ibn al-Zubayr | Abdullah ibn az Zubair |
| Sadeq Bek | Saadik Bek |
| Umm al-Joud | Oom al Jood |
| King Abdulaziz | King Abdul Azeez |
| Kaaba | Kahbah |
| Kiswa | Kisswa |

### Sources read

- https://en.wikipedia.org/wiki/The_Two_Holy_Mosques_Architecture_Exhibition
- https://www.arabnews.com/makkah-exhibition-features-historical-aspects-two-holy-mosques
- https://madainproject.com/exhibition_of_the_two_holy_mosques_architecture
- https://en.wikipedia.org/wiki/Kaaba

---

## 20 · The Kiswa Factory of the Holy Ka'aba

**Visit** · Google Maps name: **The Kiswa Factory of the Holy Ka'aba** · `21.434722, 39.756922` (Google) · 304 words, ~1:57

Files: `scripts/20_kiswa-factory_clean.txt`, `scripts/20_kiswa-factory_tts-safe.txt`

### Script (clean)

Every year the Kaaba is dressed in new clothes. This is the workshop that makes them.

The King Abdulaziz Complex for the Holy Kaaba Kiswa is in Umm al-Joud, about ten kilometres from the Haram, beside the Exhibition of the Two Holy Mosques Architecture. Guided visits walk you through the production halls, so you should find yourself among looms, embroidery frames and long tables of black silk.

Start with the silk itself. The kiswa uses about six hundred and seventy kilograms of white silk thread, dyed black. Jacquard machines weave it into forty-seven panels, each fourteen metres long and just under a metre wide, with the declaration of faith woven into the pattern.

Then find the embroiderers, because this is the part that is done by hand. More than two hundred artisans work here, and the Qur'anic verses are stitched in gold and silver thread: around a hundred and twenty kilograms of twenty-one-carat gold thread, and a hundred of silver. The band two-thirds of the way up the Kaaba, the hizam, is forty-seven metres long. The finished kiswa covers six hundred and fifty-eight square metres and costs about twenty-two million riyals to make.

What's worth knowing is how recently this all came here. For centuries the kiswa was made in Egypt and carried to Makkah in a ceremonial procession. Production began moving to Makkah in nineteen twenty-seven, became fully local in nineteen sixty-two, and moved into this complex in nineteen seventy-seven. In two thousand and twenty-four, for the first time in recorded history, women took part in the ceremony of replacing it.

[beat]

The complex opens to visitors on weekday mornings, so plan to arrive early. Afterwards, look closely at the corners of the Kaaba the next time you're in the mosque. The roundels of gold embroidery you'll see there were stitched in this building.

### TTS respellings

| Written | Spoken as |
|---|---|
| The Kiswa Factory of the Holy Ka'aba | The Kisswa Factory of the Holy Kahbah |
| Umm al-Joud | Oom al Jood |
| King Abdulaziz | King Abdul Azeez |
| Qur'anic | Koranic |
| Kaaba | Kahbah |
| Kiswa | Kisswa |
| kiswa | kisswa |
| Haram | Harahm |
| hizam | hizaam |
| Jacquard | Jakard |

### Sources read

- https://en.wikipedia.org/wiki/Kiswah
- https://visitsaudi.com/en/makkah/attractions/the-kiswa-factory-of-the-holy-kaaba-in-makkah
- https://www.bernama.com/en/news.php?id=2430681

---

## 21 · Mecca Museum

**Visit** · Google Maps name: **Mecca Museum** · `21.446147, 39.807936` (Google) · 287 words, ~1:50

Files: `scripts/21_mecca-museum_clean.txt`, `scripts/21_mecca-museum_tts-safe.txt`

### Script (clean)

Before it held the city's history, this building held a king's guests, and then a school full of children.

The Mecca Museum stands on Al Madinah Al Munawarah Road in the Az-Zahir district, north-west of the mosque, in the old Al-Zahir Palace. You should be looking at a two-storey building of cut and carved stone, set in its own gardens, quite unlike the glass and concrete around the Haram.

Start with the building. It was a guesthouse for King Abdulaziz, the founder of modern Saudi Arabia, before becoming a school under the Ministry of Education. Today it covers around three and a half thousand square metres of exhibition space, and the Ministry of Culture has commissioned a new reorganisation of its galleries.

Then go inside and work your way through time. The displays begin with archaeology and the history of the Arabian Peninsula before Islam, then move through Islamic art and calligraphy. One gallery traces how learning and education developed in Makkah, from the early Islamic centuries to today, which is rather fitting in a former school.

Look out, too, for a mouthpiece from the Zamzam well, the spring beside the Kaaba. It is a plain object, and it has been touched by an unimaginable number of hands.

And here's the thing about this place. In a city that has replaced so much of its fabric, a mid-century palace of carved stone is itself one of the exhibits. The building is as much a survivor as anything in its glass cases.

[beat]

Walk round the outside before you leave, and look at the stone carving on the façade. Then head up the road towards the Tan'eem mosque, where pilgrims staying in Makkah put on their ihram for Umrah.

### TTS respellings

| Written | Spoken as |
|---|---|
| Al Madinah Al Munawarah Road | Madeena Munawwara Road |
| Al-Zahir Palace | al Zaahir Palace |
| Az-Zahir | az Zaahir |
| King Abdulaziz | King Abdul Azeez |
| Kaaba | Kahbah |
| Tan'eem | Tan eem |
| façade | facade |
| Haram | Harahm |
| Umrah | Umra |

### Sources read

- https://www.lonelyplanet.com/saudi-arabia/mecca/attractions/makkah-museum/a/poi-sig/1531499/1340988
- https://avestagroup.eu/projects/al-zaher-palace/
- https://artessere.com/al-zaher-palace-museum

---

## 22 · Hira Cultural District

**Visit** · Google Maps name: **Hira Cultural District** · `21.456188, 39.869063` (Google) · 302 words, ~1:56

Files: `scripts/22_hira-cultural-district_clean.txt`, `scripts/22_hira-cultural-district_tts-safe.txt`

### Script (clean)

For centuries, the only thing at the foot of this mountain was the path up it.

The Hira Cultural District lies on the eastern side of Makkah, at the base of Jabal al-Nour. Stand in the open plaza in the middle of the district, and look up. The steep, double-peaked mountain above you holds the cave of Hira, where the Prophet Muhammad is believed to have received the first revelation of the Qur'an.

Start with the scale of what has been built here. The district covers about sixty-seven thousand square metres, and it was opened in January two thousand and twenty-three. Its buildings draw on the traditional architecture of Makkah, and they are designed to sit below the mountain rather than compete with it.

Then visit the Revelation Exhibition, the heart of the district. It tells the story of how revelation came to the prophets, through audio-visual galleries, and it even offers a virtual ascent to the cave, for those who cannot make the climb themselves. Nearby, the Holy Qur'an Museum opened in March two thousand and twenty-five, with rare manuscripts and a photographed copy of the Qur'an of the Caliph Uthman.

There is more besides: a visitor centre, a library, gardens, cafés and the Saudi Coffee Museum.

And that is the change worth noticing. For most of its history, the visit to Hira was simply a hard climb. Now there is a civic space at the bottom, which turns the mountain from an ordeal into a destination, for the young, the old and everyone between.

[beat]

If you're fit and it's cool, the path to the cave starts close by. Otherwise, call in at the Saudi Coffee Museum, and then find a seat in the gardens and look up at the path, picking out the climbers on their way to the cave.

### TTS respellings

| Written | Spoken as |
|---|---|
| Jabal al-Nour | Jabbal an Noor |
| Qur'an | Koran |
| cafés | cafes |
| Hira | Heera |
| Uthman | Uthmaan |

### Sources read

- https://saudipedia.com/en/hira-cultural-district
- https://www.arabnews.com/node/2508426
- https://arab.news/2bryk
- https://english.ajel.sa/business/revelation-exhibition-in-makkah-offers-immersive-journey-into-islamic-history

---

## 23 · Hira Cave, Mount of Light

**Visit** · Google Maps name: **Hira Cave, Mount of Light** · `21.457254, 39.858974` (Google) · 294 words, ~1:53

Files: `scripts/23_hira-cave-mount-of-light_clean.txt`, `scripts/23_hira-cave-mount-of-light_tts-safe.txt`

### Script (clean)

The cave you are climbing towards is about three and a half metres long and not much more than a metre and a half wide. It has changed the world rather more than its size suggests.

You should be on the path up Jabal al-Nour, the Mountain of Light, on the eastern side of Makkah, with the Hira Cultural District below you. Look up and you'll see why the mountain is easy to recognise: its summit looks like one mountain sitting on top of another.

Start with the climb. There are around seventeen hundred and fifty steps to the cave, and the walk takes anything from half an hour to three hours, depending on you and on the heat. The mountain itself rises to about six hundred and forty metres, bare and rocky, with no water and very little growing on it.

Then the cave. It sits about two hundred and seventy metres up. Muslim tradition holds that the Prophet Muhammad came here for a month each year to be alone, taking provisions with him and feeding the poor who found him, and that here, around six hundred and ten, he received the first five verses of the Qur'an from the angel Jibril.

What's worth knowing is that visiting Hira is not part of the Hajj, and under most interpretations of Islam a prayer here earns no more reward than anywhere else in Makkah. People come anyway, in their thousands. It isn't a ritual that brings them, it's the wish to stand where something began.

[beat]

When you reach the cave, turn and look back the way you came. The city spreads out below, and you can pick out the Clock Tower above the Haram, which is a view the Prophet, of course, never had.

### TTS respellings

| Written | Spoken as |
|---|---|
| Jabal al-Nour | Jabbal an Noor |
| Qur'an | Koran |
| Hira | Heera |
| Haram | Harahm |
| Jibril | Jibreel |

### Sources read

- https://en.wikipedia.org/wiki/Jabal_al-Nour

---

## 24 · Bay'ah Mosque

**Visit** · Google Maps name: **Bay'ah Mosque** · `21.424717, 39.867493` (OSM) · 231 words, ~1:29

Files: `scripts/24_bayah-mosque_clean.txt`, `scripts/24_bayah-mosque_tts-safe.txt`

### Script (clean)

This mosque is easy to miss. It is also one of the oldest standing places of worship anywhere near Makkah.

The Bay'ah Mosque lies in Mina, below the slopes near the Jamarat Bridge, at the foot of the Aqaba hill. You should be looking at a small, walled mosque with an open courtyard inside, standing quite apart from the modern structures around it.

Start with its age. It was built at the request of the Abbasid caliph Abu Ja'far al-Mansur, in seven hundred and sixty-one, which makes it more than twelve and a half centuries old.

Then what it marks. This is the place where, before the migration to Madinah, the Prophet Muhammad met a group of people from Madinah, the Ansar, and they swore him their allegiance, the pledge of Aqaba. Bay'ah means pledge, and the mosque takes its name from that promise.

And here's what I find remarkable. A short walk away, the Jamarat Bridge moves hundreds of thousands of people an hour, and the tent city of Mina stretches across the valley. This modest courtyard, open to the sky, has outlasted almost everything that ever stood around it, simply by being small and staying put.

[beat]

Walk round the outside before you go, and notice how little there is of it. Then follow the road down towards the Jamarat, and notice how quickly the twentieth century takes over again.

### TTS respellings

| Written | Spoken as |
|---|---|
| Abu Ja'far al-Mansur | Aboo Jaafar al Mansoor |
| Bay'ah | Bay ah |
| Jamarat | Jamaraht |
| Mina | Meena |
| Ansar | Ansaar |
| Aqaba | Akaba |
| Abbasid | Abbaasid |

### Sources read

- https://en.wikipedia.org/wiki/Bay%27ah_Mosque
- https://en.wikipedia.org/wiki/Mina,_Saudi_Arabia

---

## 25 · Tuwa Well

**Visit** · Google Maps name: **Tuwa Well** · `21.431619, 39.816657` (Google) · 247 words, ~1:35

Files: `scripts/25_tuwa-well_clean.txt`, `scripts/25_tuwa-well_tts-safe.txt`

### Script (clean)

This well marks the last stop before Makkah, on the journey into the city that early Muslims made.

Tuwa Well is in the Jarwal district, north-west of the mosque, in what was once the valley of Dhu Tuwa. You should be looking at a modest enclosure around an old well, quiet and easy to walk past.

Start with the tradition. Abdullah ibn Umar, a companion of the Prophet, used to spend the night in this valley before entering Makkah. In the morning he would pray the dawn prayer, bathe, and only then go on into the city, and he said the Prophet had done the same. The account is preserved in the collection of Bukhari.

Then look at what is here now. A mosque once stood close to the well, and it has been demolished. The well has survived. Some visitors have arrived to find the site closed for renovation, so it is worth checking before you make a special trip.

And here's the thing. Almost everything in central Makkah has been rebuilt to handle crowds. This is a place that has never had crowds, and it records something that crowds can't: the pause before arriving, a night's rest and a wash on the edge of the city before stepping into it.

[beat]

From here, it is a short drive to the Masjid al-Jinn and the Mu'alla cemetery on the northern approach to the mosque. Make your way into the centre the slow way, as the companions did.

### TTS respellings

| Written | Spoken as |
|---|---|
| Abdullah ibn Umar | Abdullah ibn Omar |
| Masjid al-Jinn | Masjid al Jinn |
| Dhu Tuwa | Dhoo Toowa |
| Mu'alla | Moo alla |
| Tuwa | Toowa |
| Bukhari | Bukhaaree |

### Sources read

- https://thepilgrim.co/bir-tuwa/
- https://ihadis.com/en/bukhari/hadith/1573
- https://wanderlog.com/place/details/4899997/tuwa-well

---

## 26 · Masjid al-Jinn

**Visit** · Google Maps name: **Masjid al Jinn** · `21.433454, 39.828965` (OSM) · 285 words, ~1:50

Files: `scripts/26_masjid-al-jinn_clean.txt`, `scripts/26_masjid-al-jinn_tts-safe.txt`

### Script (clean)

The name means the Mosque of the Jinn, and it records one of the stranger audiences in the story of Islam.

Masjid al-Jinn is in Al-Hajun, about nine hundred metres north of the Grand Mosque, just east of the Mu'alla cemetery. You should be looking at a neighbourhood-sized mosque on Al Masjid Al Haram Road, modest beside the towers to the south.

Start with the story. According to tradition, it was here that the Prophet Muhammad recited the Qur'an to a gathering of jinn, the unseen beings of Islamic belief, and they accepted Islam. The opening verse of the seventy-second chapter of the Qur'an, Surat al-Jinn, describes a company of jinn who listened and said they had heard a wondrous recitation. The tradition adds that the Prophet drew a circle around his companion Abdullah ibn Mas'ud, and told him to stay inside it until the gathering was over.

Then the other name. It is also called Masjid al-Haras, the Mosque of the Guards, after the night watchmen of old Makkah.

The building itself has been rebuilt more than once. A mosque has stood here since at least the third century of the Islamic calendar; it was renovated in nineteen seventy-nine and rebuilt again in two thousand and one, under King Fahd, in a modern Islamic style.

And that is rather the pattern of this whole quarter. The stories are very old, the walls are very new, and the sense of place is carried almost entirely by the name.

[beat]

From the mosque, cross over to the walls of the Mu'alla cemetery next door. It is the resting place of some of the Prophet's closest family, and it is a good deal quieter than the road outside.

### TTS respellings

| Written | Spoken as |
|---|---|
| Abdullah ibn Mas'ud | Abdullah ibn Masood |
| Al Masjid Al Haram Road | Masjid al Harahm Road |
| Masjid al-Haras | Masjid al Harras |
| Masjid al-Jinn | Masjid al Jinn |
| Surat al-Jinn | Soorat al Jinn |
| Al-Hajun | al Hajoon |
| Mu'alla | Moo alla |
| Qur'an | Koran |

### Sources read

- https://discovermakkah.sa/en/places-worth-visiting/landmarks/mosque-of-the-jinn
- https://visitsaudi.com/en/makkah/attractions/masjid-al-jinn

---

## 27 · Al Muallaa Cemetery

**Visit** · Google Maps name: **Al Muallaa Cemetery** · `21.435021, 39.827908` (Google) · 266 words, ~1:42

Files: `scripts/27_al-muallaa-cemetery_clean.txt`, `scripts/27_al-muallaa-cemetery_tts-safe.txt`

### Script (clean)

There are no grand tombs here, and that is the whole point.

Jannat al-Mu'alla lies on the northern approach to the Grand Mosque, in the Al-Hajun district, beside the Masjid al-Jinn. Through the gates you should see a broad, walled hillside of plain ground, the graves marked by little more than low heaps of stones.

Start with who is buried here. This was a burial ground before Islam, used by the Quraysh and the old families of Makkah. Khadijah, the first wife of the Prophet Muhammad and the first person to accept his message, is buried here, as are his uncle Abu Talib and his grandfather Abd al-Muttalib, who raised him.

Then imagine what once stood here. In the seventeenth century, the Ottoman traveller Evliya Çelebi counted seventy-five domed tombs in this cemetery. In nineteen twenty-five and nineteen twenty-six, after the Hijaz came under the rule of Ibn Saud, those structures were removed, as part of a wider programme intended to discourage the veneration of graves. The same happened at the Baqi cemetery in Madinah.

And here's what's worth sitting with. To some, the bare ground is a loss, and it is still mourned. To others it is the point: the grave of the Prophet's beloved wife marked no differently from anyone else's. Either way, this is one of the few places in central Makkah where nothing has been built up at all.

[beat]

If you cannot go in, stand at the gates and look up the hillside. And then walk back south towards the Haram, on the road that the people buried here once walked themselves.

### TTS respellings

| Written | Spoken as |
|---|---|
| Masjid al-Jinn | Masjid al Jinn |
| Jannat al-Mu'alla | Jannat al Moo alla |
| Abd al-Muttalib | Abdul Muttalib |
| Abu Talib | Aboo Taalib |
| Al Muallaa Cemetery | al Moo alla Cemetery |
| Evliya Çelebi | Evliya Chelebi |
| Al-Hajun | al Hajoon |
| Haram | Harahm |
| Hijaz | Hijaaz |
| Khadijah | Khadeeja |
| Quraysh | Koraish |
| Baqi | Bakee |
| Saud | Saood |

### Sources read

- https://en.wikipedia.org/wiki/Jannat_al-Mu%27alla
- https://madainproject.com/jannat_ul_mualla

---

## 28 · Aisha Al Rajhi Mosque

**Visit** · Google Maps name: **Aisha Al Rajhi Mosque** · `21.381866, 39.873747` (Google) · 259 words, ~1:40

Files: `scripts/28_aisha-al-rajhi-mosque_clean.txt`, `scripts/28_aisha-al-rajhi-mosque_tts-safe.txt`

### Script (clean)

Most new mosques in Makkah are built to cope with numbers. This one was built as a gift.

The Aisha Al Rajhi Mosque stands in Al-Naseem, about four kilometres east of the Haram. Look for the two tall minarets first, and you'll find the mosque at their feet, with Arak Park and its palm-lined paths beside it.

Start with the minarets, because they are the thing you see from across the district. There are two, each about sixty-eight metres high.

Then go inside, to the prayer halls. They are finished in black and white marble, which gives the interior a sharp, graphic look. The men's prayer hall runs over three floors and the women's over two, and with its outer courtyard, the mosque can hold about forty-eight thousand people.

It was built by the businessman and philanthropist Suleiman Al Rajhi, and it opened in two thousand and thirteen, inaugurated by Prince Khalid Al Faisal, the governor of the Makkah region.

And here's what I find interesting. In the Grand Mosque, every new hall is a state project, an answer to the problem of the crowd. This is something else: one man's offering, built in a residential district, among the people who live around it. It is a reminder that Makkah is a city where people live, as well as a place people visit.

[beat]

Come back in the evening and walk out into Arak Park next door. From the lawns, the minarets rise straight up over the palms, and you'll see why local families choose to spend their evenings here.

### TTS respellings

| Written | Spoken as |
|---|---|
| Aisha Al Rajhi | Aysha al Rajhee |
| Suleiman Al Rajhi | Sulaiman al Rajhee |
| Khalid Al Faisal | Khaalid al Faisal |
| Al-Naseem | an Naseem |
| Haram | Harahm |

### Sources read

- https://mosqpedia.org/masajid/aisha-al-rajhi-mosque/
- https://www.arabnews.com/news/456717
- https://visitsaudi.com/en/makkah/attractions/masjid-al-rajhi

---

## 29 · Jamaraat Bridge

**Visit** · Google Maps name: **Jamaraat Bridge** · `21.420775, 39.873156` (OSM) · 325 words, ~2:05

Files: `scripts/29_jamaraat-bridge_clean.txt`, `scripts/29_jamaraat-bridge_tts-safe.txt`

### Script (clean)

It is a bridge you cross on foot, not to get over anything, but to get to three walls of stone.

The Jamaraat Bridge stands at the western end of the Mina valley, about five kilometres east of the Grand Mosque. You should be looking at a long, multi-level concrete structure, with wide ramps leading up to it. Inside it, running up through every level, are the three jamarat, long, tall walls that pilgrims stone during the Hajj.

Start with the ritual. In the last days of the Hajj, pilgrims throw pebbles at the three jamarat, the small, the middle and the great, in memory of Abraham, who in Muslim tradition rejected the Devil in this valley. The first two are about a hundred and thirty-five metres apart, the second and third about two hundred and twenty-five.

Then the history, which is a sober one. A bridge was first built here in nineteen sixty-three, and as the number of pilgrims grew, the crush at the pillars caused fatal accidents, more than once. After the disaster of January two thousand and six, the old bridge was demolished, and a new one, designed by Dar Al-Handasah and built by the Saudi Binladin Group, rose in its place. The old round pillars were replaced by long walls, so more people could reach them at once.

The result can carry around five hundred thousand people an hour, against two hundred thousand before. A fire-safety engineer worked out that this was like moving the largest football crowd in history every twenty-four minutes.

And here's the thing. This is architecture as crowd science. Every ramp, every exit and every widened column exists because of lives lost here, and it is one of the most consequential pieces of design in the city.

[beat]

Outside the Hajj, walk up one of the ramps and look along the length of the bridge. Then look east, across the valley, where the white tents of Mina begin.

### TTS respellings

| Written | Spoken as |
|---|---|
| Dar Al-Handasah | Dar al Handasa |
| Saudi Binladin Group | Saudi Bin Laden Group |
| Jamaraat | Jamaraht |
| jamarat | jamaraht |
| Mina | Meena |

### Sources read

- https://en.wikipedia.org/wiki/Jamaraat_Bridge
- https://en.wikipedia.org/wiki/Mina,_Saudi_Arabia

---

## 30 · Haramain High Speed Railway, Makkah Station

**Visit** · Google Maps name: **Haramain High Speed Railway - Makkah** · `21.417655, 39.788532` (OSM) · 308 words, ~1:58

Files: `scripts/30_haramain-high-speed-railway-makkah_clean.txt`, `scripts/30_haramain-high-speed-railway-makkah_tts-safe.txt`

### Script (clean)

The two holy cities are now about two hours apart by train, which is a journey the pilgrim caravans could only have dreamed of.

Makkah's high-speed station is in Ar-Rusayfah, by the Third Ring Road, west of the city centre. Step into the concourse and look up. You should be under a vaulted roof held up by a forest of steel columns, each branching into arches like a tree.

Start with the roof, because it is the whole idea. The architects, Foster and Partners with Buro Happold, designed every station on the line from the same twenty-seven-metre-square module, a steel column branching into arches. Repeat it across a grid and you get a vault. It echoes the colonnades of the region's traditional architecture, and it can be extended simply by adding more trees.

Then watch the light. Small openings in the vault and the walls let beams of daylight fall to the concourse below, while keeping out the glare of the desert sun, and spherical lamps hang between the arches. Each station on the line has vaults of a different colour, to give each city its own identity.

The railway opened in October two thousand and eighteen. It runs four hundred and forty-nine kilometres from here to Madinah, by way of Jeddah, with trains limited to three hundred kilometres an hour, and the stations are designed for twenty thousand passengers an hour.

What's worth knowing, standing here, is that this is the most generous public interior in Makkah. Most of the city's great modern spaces are built for prayer, or for business. This one was built for the ordinary act of arriving.

[beat]

If you have time, buy a ticket and ride as far as Jeddah, forty-three minutes away. Watching the desert slide past the window is the best way to feel how far the pilgrimage used to be.

### TTS respellings

| Written | Spoken as |
|---|---|
| Ar-Rusayfah | ar Rusaifa |

### Sources read

- https://en.wikipedia.org/wiki/Haramain_High-Speed_Railway
- https://worldarchitecture.org/architecture-news/ecezf/foster--partners-designs-stations-with-treelike-flexible-roofs-for-saudi-arabian-cities.html
- https://www.designboom.com/architecture/foster-partners-haramain-high-speed-rail-saudi-arabia-06-13-2019/

---

## 31 · Mecca Gate

**Visit** · Google Maps name: **Mecca Gate** · `21.362361, 39.666722` (Wikipedia) · 244 words, ~1:34

Files: `scripts/31_mecca-gate_clean.txt`, `scripts/31_mecca-gate_tts-safe.txt`

### Script (clean)

You will probably pass under this monument at a hundred kilometres an hour. It is still the front door to the city.

The Mecca Gate spans the Jeddah to Makkah expressway on the western approach to the city. As you drive east, look ahead and up: a great concrete open book, the Qur'an, resting on a carved book stand, straddling the carriageway.

Start with the idea. The book stand is a rehal, the X-shaped stand that holds a Qur'an while it is being read. Designer Dia Aziz Dia scaled that domestic object up to span a motorway, and he worked with architects, engineers and calligraphers to finish it. The architect was Samir Elabd, and the gate was built in nineteen seventy-nine, in reinforced concrete, with mosaics and stained glass beneath its arches and lights for after dark.

Then what it means. The gate marks the boundary of the haram, the sacred precinct of Makkah. Beyond this point, non-Muslims are not permitted to enter.

And here's the thing. Most city gates are walls with a hole in them, built to keep people out. This one is built from the object at the centre of the faith, and its message is not defence, but welcome, to those it welcomes.

[beat]

If someone else is driving, look up through the windscreen as you pass beneath the open pages. It is the briefest of tours, and for most people it is the first moment they know they have arrived.

### TTS respellings

| Written | Spoken as |
|---|---|
| Dia Aziz Dia | Deeya Azeez Deeya |
| Samir Elabd | Sameer el Abd |
| Qur'an | Koran |
| haram | harahm |
| rehal | rihaal |

### Sources read

- https://en.wikipedia.org/wiki/Mecca_Gate
- https://www.arabnews.com/node/1543431

---

## 32 · Jabal Thawr

**Visit** · Google Maps name: **Jabal Thawr** · `21.377, 39.849868` (OSM (summit)) · 216 words, ~1:23

Files: `scripts/32_jabal-thawr_clean.txt`, `scripts/32_jabal-thawr_tts-safe.txt`

### Script (clean)

Hira is the mountain of the beginning. Thawr is the mountain of the escape.

Jabal Thawr rises in the south of Makkah, beyond the district of Misfalah, about eight kilometres from the Grand Mosque. From its base, look up: a high, steep, rocky peak, around seven hundred and fifty metres above sea level, with the path to the cave winding up its face.

Start with the story. In six hundred and twenty-two, as the Prophet Muhammad left Makkah for Madinah, he and his companion Abu Bakr hid in a cave near the top of this mountain while the Quraysh searched for them. The cave is Ghar Thawr, and the journey that followed, the Hijra, is the event from which the Islamic calendar is counted.

Then the climb. It is long and steep, so carry water and set off early in the day, before the heat.

And that's what's worth sitting with. Hira marks where the revelation began; Thawr marks the moment it nearly ended, hidden in a crack in the rock with pursuers outside. Two caves, a few kilometres apart, holding the first and the most frightening moments of the story.

[beat]

From the top, look north. Somewhere in the haze is the Clock Tower above the Haram, standing over the city the two travellers left behind.

### TTS respellings

| Written | Spoken as |
|---|---|
| Jabal Thawr | Jabbal Thowr |
| Ghar Thawr | Ghaar Thowr |
| Abu Bakr | Aboo Bakr |
| Hira | Heera |
| Thawr | Thowr |
| Misfalah | Misfala |
| Haram | Harahm |
| Quraysh | Koraish |

### Sources read

- https://en.wikipedia.org/wiki/Jabal_Thawr

---

## 33 · Al Kaaba

**Observe** · Google Maps name: **Al Kaaba** · `21.422545, 39.82619` (Google) · 309 words, ~1:59

Files: `scripts/33_al-kaaba_clean.txt`, `scripts/33_al-kaaba_tts-safe.txt`

### Script (clean)

Its name simply means the cube, and it is the direction every Muslim on earth faces in prayer.

Go up to one of the upper levels of the mataf, the circular space around the Kaaba, and find a place at the parapet. Below you, at the centre of the mosque, is a black cube draped in silk and gold, with a slow ring of people moving round it, anticlockwise.

Start with the cube itself. Its four corners point roughly to the four points of the compass. Set in its eastern corner, in a silver frame, is the Black Stone, the place where every circuit begins. The door, on the north-east face, is set two metres above the ground, and since nineteen seventy-nine it has been made of gold, some three hundred kilograms of it.

Then look round the base. On the north-west side you'll see a low, curved white marble wall, about one point three metres high. That is the Hatim, marking ground that was once part of the Kaaba itself, and pilgrims walk around it rather than inside it. Facing the door is the Maqam Ibrahim, the Station of Abraham, under its protective enclosure.

Then watch the ring. Pilgrims circle the Kaaba seven times, starting from the Black Stone. The mataf has been widened and stacked into several levels over the last century so that more people can walk at once.

And here is the thing I keep coming back to. Most architecture asks you to look at it. This building asks you to walk around it and to face it, and the whole city, really, is built around that one act.

[beat]

Stay for a while, if you can, through the hours after midnight, when the crowd thins but rarely stops. Count the circuits of one person below you, and you'll see how long seven turns can take.

### TTS respellings

| Written | Spoken as |
|---|---|
| Maqam Ibrahim | Makaam Ibraheem |
| Al Kaaba | al Kahbah |
| Kaaba | Kahbah |
| Hatim | Hateem |

### Sources read

- https://en.wikipedia.org/wiki/Kaaba
- https://en.wikipedia.org/wiki/Great_Mosque_of_Mecca

---

## 34 · Makkah Clock Tower

**Observe** · Google Maps name: **Makkah Clock Tower** · `21.419341, 39.825412` (Google) · 282 words, ~1:48

Files: `scripts/34_makkah-clock-tower_clean.txt`, `scripts/34_makkah-clock-tower_tts-safe.txt`

### Script (clean)

From a balcony right beneath the largest clock face in the world, you can look straight down into the Grand Mosque.

The Clock Tower Museum fills the top four floors of the Makkah Clock Royal Tower, just behind the clock faces, and it is open to Muslim visitors with a ticket. Take the lift up and find the panoramic balcony, with its telescopes trained on the Kaaba far below.

Have a look at the clock first, from the inside. Each of the four faces is forty-three metres across and covered in ninety-eight million pieces of glass mosaic. The minute hand is twenty-three metres long, the hour hand eighteen, and an atomic clock in the spire keeps the time.

Then explore the museum. It is about astronomy and the measuring of time, as well as the history of Makkah and of the Grand Mosque itself. Above you, in the base of the spire, a scientific centre is used to sight the new moon that marks the start of each Islamic month, which is precisely the job the clock tower does for the whole city.

And at the very top, there is a gold crescent twenty-one metres across, built in Dubai and weighing up to thirty-five tonnes, with a small prayer room inside.

What's worth noticing is the ambition. A clock tower in London or Zürich tells the hours to a town. This one carries the call to prayer seven kilometres across the valley, and its lights flash for each of the five daily prayers.

[beat]

Time your visit for a prayer if you can. From the balcony, you'll see the courtyard fall still below you as the lights on the tower begin to flash.

### TTS respellings

| Written | Spoken as |
|---|---|
| Kaaba | Kahbah |
| Zürich | Zurich |

### Sources read

- https://en.wikipedia.org/wiki/The_Clock_Towers
- https://www.lokalee.app/tours/makkah-clock-tower-museum-general-entry-ticket

---

## 35 · Mina

**Observe** · Google Maps name: **Mina** · `21.414605, 39.894564` (Google) · 268 words, ~1:43

Files: `scripts/35_mina_clean.txt`, `scripts/35_mina_tts-safe.txt`

### Script (clean)

For most of the year, this is a city with almost nobody in it.

Mina lies in a valley about eight kilometres south-east of the Grand Mosque. From a high point at its western end, near the Jamarat Bridge, look east. You should see white roofs filling the valley floor and climbing the slopes on both sides, as far as you can see.

Start with the tents. There are more than a hundred thousand of them, each eight metres square, made of fibreglass with a fireproof Teflon coating. They are grouped into walled camps, divided by the pilgrims' nationalities, each with its own kitchen and washrooms, and marked with colour-and-number codes so that people can find their way back. At its peak, this valley houses up to three million people.

Then the reason they look like this. Before the nineteen nineties, pilgrims brought their own tents. Permanent cotton tents followed, and they burned: the fire of nineteen ninety-seven killed more than three hundred and forty people. The fireproof tents were the response.

In the middle of the valley is the Masjid al-Khayf, the largest mosque in Mina, covering some twenty thousand square metres, which comes fully alive only during the Hajj.

And here's the thing worth sitting with. Mina is a city designed to be used for a few days a year, and to stand empty and waiting for the rest. Few places anywhere are built so completely around a single week.

[beat]

Drive slowly along one of the valley roads outside the Hajj season. It's eerily quiet, and the rows of white roofs reach further than seems possible.

### TTS respellings

| Written | Spoken as |
|---|---|
| Masjid al-Khayf | Masjid al Khaif |
| Jamarat | Jamaraht |
| Mina | Meena |

### Sources read

- https://en.wikipedia.org/wiki/Mina,_Saudi_Arabia

---

## 36 · Jamarat (Mina Station 3)

**Observe** · Google Maps name: **Jamarat (Mina Station 3)** · `21.418396, 39.87064` (OSM) · 260 words, ~1:40

Files: `scripts/36_jamarat-mina-station-3_clean.txt`, `scripts/36_jamarat-mina-station-3_tts-safe.txt`

### Script (clean)

This railway station is busier than almost any in the world for one week of the year, and shut for the other fifty-one.

Mina Station Three stands near the Jamarat Bridge, at the western end of the Mina valley, the last stop on the Al Mashaaer Al Mugaddassah Metro, the Sacred Sites line. You should be looking at the station, with the track running away east towards Muzdalifah and Arafat.

Start with how it was built. The line was built by China Railway Construction Corporation, and it opened on the thirteenth of November, two thousand and ten, in time for that year's Hajj. Its construction was claimed to be among the fastest in the world, at twenty-two months.

Then how it runs. Each train has twelve cars and carries three thousand pilgrims. In its first full Hajj, the line carried almost four million passengers, which made it, for that week, one of the most intensively used metro lines in the world. At its peak, it loads three trains at once at three different stations, then moves them together as a set, to empty the platforms.

And here's the thing. A metro is usually the most everyday kind of building there is. This one is the opposite: a line that only exists for a few days a year, linking three places that each matter for only one day of the Hajj.

[beat]

Outside the Hajj, follow the line with your eyes as it heads east. It traces the pilgrim's route in reverse, back to Muzdalifah and on to the plain of Arafat.

### TTS respellings

| Written | Spoken as |
|---|---|
| Al Mashaaer Al Mugaddassah Metro | Mashaa ir Mukaddasa Metro |
| Mina Station Three | Meena Station Three |
| Jamarat (Mina Station 3) | Jamaraht, Meena Station Three |
| Arafat | Arafaht |
| Muzdalifah | Muzdaleefa |
| Jamarat | Jamaraht |
| Mina | Meena |

### Sources read

- https://en.wikipedia.org/wiki/Al_Mashaaer_Al_Mugaddassah_Metro_line
- https://en.wikipedia.org/wiki/Mina,_Saudi_Arabia

---

## 37 · Mt Arafat

**Observe** · Google Maps name: **Mt Arafat** · `21.354885, 39.984116` (Google) · 291 words, ~1:52

Files: `scripts/37_mt-arafat_clean.txt`, `scripts/37_mt-arafat_tts-safe.txt`

### Script (clean)

The hill is only about seventy metres high. On one day a year, well over a million people come to stand around it.

Mount Arafat, also called Jabal al-Rahmah, the Mount of Mercy, rises from the plain of Arafat, about twenty kilometres south-east of Makkah. Look for the pillar on the summit; that is your landmark.

Start with the rock. It is granodiorite, a granite-like stone, and it has been here for millions of years. Muslim tradition says that this is where the Prophet Muhammad delivered his Farewell Sermon, at the end of his life, to the companions who had joined him on the Hajj. Some believe it is also where Adam and Eve were reunited after leaving Paradise, and forgiven, which is how the hill came to be called the Mount of Mercy.

Then look out across the plain. On the ninth day of the month of Dhu al-Hijjah, the Day of Arafah, pilgrims leave Mina and spend the afternoon here, in prayer, until sunset. Being present on this plain on that day is so essential that, without it, the Hajj does not count.

Nearby stands the Masjid Namirah, where the sermon of the Day of Arafah is delivered. It was first built in the ninth century, under the Abbasids, and has been expanded to cover twenty-seven thousand square metres.

And that's what's worth sitting with. The most important moment of the pilgrimage does not happen in a building at all. It happens on an open plain around a small hill, with no roof but the sky.

[beat]

Climb to the pillar towards sunset, and look west over the plain. When the sun goes down on the Day of Arafah, the whole crowd turns and begins to move towards Muzdalifah, together.

### TTS respellings

| Written | Spoken as |
|---|---|
| Masjid Namirah | Masjid Nameera |
| Jabal al-Rahmah | Jabbal ar Rahma |
| Dhu al-Hijjah | Dhul Hijja |
| Arafah | Arafa |
| Arafat | Arafaht |
| Muzdalifah | Muzdaleefa |
| Mina | Meena |
| Abbasids | Abbaasids |
| granodiorite | grano diorite |

### Sources read

- https://en.wikipedia.org/wiki/Mount_Arafat
- https://en.wikipedia.org/wiki/Masjid_al-Namirah

---

## 38 · Arak Park

**Observe** · Google Maps name: **Arak Park** · `21.383342, 39.876428` (Google) · 246 words, ~1:35

Files: `scripts/38_arak-park_clean.txt`, `scripts/38_arak-park_tts-safe.txt`

### Script (clean)

Not everything in Makkah is about pilgrimage. This is where the city simply goes out for the evening.

Arak Park is in Al-Naseem, about four kilometres east of the Haram, right beside the Aisha Al Rajhi Mosque. Stand on one of the paths between the lawns and look up: the mosque's two minarets rise just beyond the palms.

Start with what's here. Green lawns, rows of palm trees, walking paths with proper surfaces, shade over parts of them, and playgrounds for children. It is open around the clock, and it costs nothing to get in.

Then look at who is using it. After the heat of the day, this is where families from the neighbourhood come to walk, to sit on the grass and to let their children run. It is an ordinary municipal park, and that is exactly what makes it worth seeing.

Here's the thing. Visitors tend to see Makkah only as the Haram and its towers, a city made for crowds who are just passing through. A park like this is a reminder that more than two million people call this place home, and need what people need anywhere: a bit of green, a bit of shade and somewhere to take the children.

[beat]

Stay on into the evening, when the paths fill up and the minarets of the Aisha Al Rajhi Mosque are lit up over the trees. It's the best place in the city to see how Makkah lives when nobody's visiting.

### TTS respellings

| Written | Spoken as |
|---|---|
| Aisha Al Rajhi | Aysha al Rajhee |
| Al-Naseem | an Naseem |
| Haram | Harahm |

### Sources read

- https://discovermakkah.sa/en/places-worth-visiting/landmarks/arak-park
- https://wanderlog.com/list/geoCategory/105953/top-things-to-do-and-attractions-in-mecca
