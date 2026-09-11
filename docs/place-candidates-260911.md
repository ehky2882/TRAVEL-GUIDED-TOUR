# Place candidates — sweep of 2026-09-11

**Re-derive, never quote.** Every number here is a reading of `Tours.json` at
`a6f6b71` and goes stale the moment a pin batch merges. Regenerate with:

```bash
python3 scripts/check-place-candidates.py --out /tmp/places.txt
```

---

## What this is

A `Place` is a site that more than one tour describes: the site becomes the thing on the
map and the tours become its contents. The catalogue has **142 of them** covering **362
entries**. This sweep asked what is left.

**221 findings, none of them a new idea — every one is already in the catalogue, sitting
unrecognised.**

| | Finding | Act on it? |
|---|---|---|
| **A** | 10 existing places that are **missing a member** already standing on them | Yes — additive, no new place |
| **B** | **132 sites** with 2+ entries, linked by a hop of ≤25 m, that have no place page | Owner picks |
| **C** | 79 same-subject pairs 25–500 m apart | Read one by one; some are deliberately separate |

§ A is the one to do first. It costs one id per row and it is not a judgement call: the
place page already exists and an entry standing on it is simply absent from it.

## What changed in the checker, and why the count jumped

`scripts/check-place-candidates.py` already reported two tiers — **EXACT** (an identical
coordinate, the catalogue's documented identity rule) and **NEAR** (titles where one's
meaningful words contain the other's, within 500 m). This sweep added a third, **TIGHT**:
two markers within 25 m of each other *whatever their titles say*.

🔴 **That tier is not a loosening of the rule — it is the case the title rule cannot see
at all.** The commonest shape in this catalogue is one site that two entries call by two
unrelated names, and no amount of string comparison reaches it:

| One site | The two names | Apart |
|---|---|---|
| A firehouse on North Moore Street | *Hook & Ladder 8* · *The Ghostbusters Firehouse* | 4 m |
| Westminster Abbey | *Britain's Oldest Door* · *The Tomb of Elizabeth I* | 5 m |
| The Nabisco building | *Chelsea Market* · *👀 Oreos were first made in NYC!* | 8 m |
| Old St Patrick's | *The Catacombs of Old St. Patrick's* · *The Godfather Baptism Church* | 16 m |
| 33 Liberty Street | *The Federal Reserve Bank of New York* · *$500 Billion of Gold Under 33 Liberty Street* | 0 m |

Those five pairs share **not one word between them**, and **55 of the 151 TIGHT pairs are
word-disjoint like that**. Counted the other way: **82 of the 151 could never have reached
the old NEAR tier** under any title rule — they are new signal, not a re-sort of what was
already there.

The refactor is otherwise behaviour-preserving: the old NEAR tier's 148 pairs come back as
69 TIGHT + 79 NEAR, exactly.

## 🔴 The false positives to expect, because they are real

Proximity is evidence, not proof. Two classes of wrong answer are in § B and will stay
there; do not batch-approve past them.

1. **A dense block of separate venues.** Hong Kong's restaurant pins sit 10–20 m apart and
   are different restaurants — *Little Bao* and *Primo Posto* (14 m), *Lazy Suzy* and
   *Peng Leng Zheng* (20 m), *Haidilao* and *Matsukiyo* (17 m). Same for Stockholm's
   *Bar Montan* / *Hosoi* (22 m) and Sydney's *Pellegrino 2000* / *The Rover* (24 m).
2. **Coordinates rounded to four decimal places.** Four dp is ~11 m, so two genuinely
   separate sites can round to within a few metres of each other. This is what puts
   Madrid's *El Retiro* 8 m from the *Puerta de Alcalá* and Chicago's *Marina City* 17 m
   from the *Merchandise Mart* — neither pair is one site, and the tours are simply
   recorded at low precision.

## The same-title pairs are NOT a duplicate bug — this was checked

19 of the § B groups hold two entries with an **identical title** (*Hollyhock House* twice,
*The Noguchi Museum* twice, *Fondation Maeght* twice), which reads like a merge that ran
twice. It is not. Every one was checked against its `sourceURL` and `makerId`, and they are
**different creators covering the same building** — which is the exact thing a place exists
to hold.

The two that share a maker were checked individually and are also clean: @urbanistariel
posted about Mont Saint-Michel twice (videos `71563846…` and `71563191…`), and
@nickcabotrodriguez posted about the First National Bank of Hollywood twice (videos
`7639208049…` and `7635369706…`, with two different heroes).

Separately, **5 `sourceURL`s are shared by more than one pin** — one video pinned at each
of the several places it visits (a Zumthor reel pinned at LACMA, Therme Vals and the Bruder
Klaus Chapel; an antique-markets reel pinned at five Italian markets). Also correct, also
not a duplicate.

⚠️ And the standing warning from #541 still applies at the far end: *Tibidabo* and
*Tibidabo Amusement Park* are 48 m apart and were **deliberately** left separate, because a
mountain and a funfair are two subjects. They are C-tier here, as they should be.

## 🔴 What a place actually costs

A place is not a grouping flag. It needs its **own name, its own editorial description, an
address and a coordinate** — and picking the coordinate is a decision, not an average.
`heroImageURL` is optional by design (the page falls back to its top tour's hero), so a
place is never blocked on sourcing an image, but everything else is writing.

So § B is a menu, not a to-do list. Say which ones you want and they get written.

---

## A — ten existing places are missing a member (10) — ✅ SEVEN APPLIED 2026-09-11

**Owner picked all of § A except Il Presidente, Westminster Abbey and the Channel Gardens.**
Each of those three was the *only* missing member of its row, so A4, A8 and A9 drop out
entirely and stay open candidates. The remaining seven — **A1, A2, A3, A5, A6, A7, A10, eight
entries** — are applied.

🔴 **"Adding the id is the whole change" was WRONG, and the validator caught it.** `Place.swift`
makes a place's identity **exact coordinate equality**, and `validate-tours` enforces it at
**1e-9 degrees** — so a member must sit *exactly* on its place. All 362 existing members do.
Adding the eight ids alone produced **8 errors: `member not on the place coordinate`**.

So joining a place also means **snapping the entry onto the place coordinate**, which is how
the other 362 got there. Every move here is small and, importantly, **inside the entry's own
30 m trigger radius**, so nothing changes about when it fires:

| Moved | Onto | By |
|---|---|---|
| *Where Julius Caesar Was Assassinated* | Largo di Torre Argentina | 20.9 m |
| *M+ Museum* | M+ Museum | 15.6 m |
| *Museum at Eldridge Street* | Eldridge Street Synagogue | 11.9 m |
| *Above the Bradbury Building's Atrium* | Bradbury Building | 8.9 m |
| *Who Funded Griffith Observatory* | Griffith Observatory | 5.4 m |
| *The Crimes of Griffith J. Griffith* | Griffith Observatory | 5.4 m |
| *Charging Bull: How It Got There* | The Charging Bull | 3.5 m |
| *Tribune Tower* | Tribune Tower | 0.6 m |

After: validator **0 errors, 0 warnings** (selftest 32/32, control clean) and the sweep drops
from 41/151/79 to **40 exact · 132 tight · 79 near** — the seven groups fall silent and the
three held rows correctly still report.

| # | Place | City | Span | Missing from the page |
|---|---|---|---|---|
| A1 ✅ | Tribune Tower | Chicago | 1 m | `[pin]` Tribune Tower |
| A2 ✅ | The Charging Bull | New York | 3 m | `[pin]` Charging Bull: How It Got There |
| A3 ✅ | Griffith Observatory | Los Angeles | 5 m | `[pin]` The Crimes of Griffith J. Griffith<br>`[pin]` Who Funded Griffith Observatory |
| A4 ⏸ held | Duddell Street Steps and Gas Lamps | Hong Kong | 6 m | `[pin]` Il Presidente |
| A5 ✅ | Bradbury Building | Los Angeles | 9 m | `[pin]` Above the Bradbury Building's Atrium |
| A6 ✅ | Eldridge Street Synagogue | New York | 12 m | `[pin]` Museum at Eldridge Street |
| A7 ✅ | M+ Museum | Hong Kong | 16 m | `[pin]` M+ Museum |
| A8 ⏸ held | Westminster Abbey | London | 17 m | `[pin]` The Cosmati Pavement<br>`[pin]` The Shrine of Edward the Confessor |
| A9 ⏸ held | Rockefeller Center | New York | 18 m | `[pin]` The Channel Gardens |
| A10 ✅ | Largo di Torre Argentina | Rome | 21 m | `[pin]` Where Julius Caesar Was Assassinated |

## B — 132 sites with two or more entries and no place page — ✅ ALL 0 m ROWS APPLIED 2026-09-11

**Owner: *"do the 0m candidates in section b".*** The 0 m rows are the EXACT tier — every member
on an identical coordinate, the catalogue's own identity rule. There were 40. **38 are now
places; 2 are held.**

🔴 **Eight of the 38 were folded wider than 0 m, deliberately.** Each had a same-subject entry a
few metres off the exact coordinate, and creating the place from the coincident pair alone would
have produced **a place called "The Pantheon" that excludes the Pantheon tour standing 5.8 m
away**. On the § A precedent they are snapped in, each move asserted to be inside that entry's
own 30 m trigger radius:

| Folded in | Onto | By |
|---|---|---|
| *Mont-Saint-Michel* | Mont Saint-Michel | 25.8 m |
| *The Dark History of the Hofbräuhaus* | Hofbräuhaus am Platzl | 16.3 m |
| *Populus Denver* | Populus | 16.3 m |
| *Palais Garnier* (tour) | Palais Garnier | 14.9 m |
| *The 28-Storey Prison in Downtown Chicago* | Metropolitan Correctional Center | 6.2 m |
| *The Pantheon* (tour) | The Pantheon | 5.8 m |
| *Catacombs of Paris* (tour) | Catacombs of Paris | 5.7 m |
| *Museum of Chinese in America* | Museum of Chinese in America | 1.4 m |

### ✅ The two held are now RESOLVED (owner, 2026-09-11) — see below. The original statement of the problem:

Both have a same-subject entry **87.9 m away, outside its own 30 m geofence**, so it *cannot* be
snapped in without changing where that tour actually fires:

| Held | The coincident pair | What sits 88 m away |
|---|---|---|
| **Grand Central** (New York) | *The Train Board at Grand Central* · *Grand Central: Why the Zodiac Is Reversed* | the existing **Grand Central Terminal** place, holding *The South Facade of Grand Central* and a *Grand Central Terminal* pin |
| **Tai Kwun** (Hong Kong) | *Madame Fu* · *The Public Spaces of Tai Kwun* | the **Tai Kwun** tour |

Grand Central is the sharper one: a *second* place with the same name 88 m from the first is
worse than no place. The choice is **move the far entries onto one coordinate** — accepting that
their geofence then fires 88 m from where it does today — **or leave the site split in two.**
That is an editorial call, not a mechanical one.

### ✅ How the owner resolved them

**Grand Central — *"yes move the tour into the place".*** The two coincident pins joined the
existing `Grand Central Terminal` place, an **88.4 m move each**. That place now has four members.
⚠️ **This genuinely changes where those two pins fire** — from the north end of the concourse to
the 42nd Street facade — which is the cost the owner accepted.

**Tai Kwun — *"'the public spaces of tai kwun' and the atlas tours belong in the place. madame fu
should be outside of it. but maybe put tai kwun place in the dead center of the tai kwun courtyard
and madame fu try to locate more precisely on the map".***

A new place **Tai Kwun** sits at **22.281513, 114.154187 — the centre of OSM's 檢閱廣場 Parade
Ground way**, the larger of the compound's two courtyards. Its two members are *The Public Spaces
of Tai Kwun* (43.7 m) and the *Tai Kwun | 大館* tour (45.5 m). ⚠️ **Both moves are outside the
30 m geofence, deliberately, and here it is an improvement**: the tour currently fires at the
Hollywood Road gate and will now fire when the listener actually reaches the courtyard.

⚠️ **There is only ONE Atlas tour for Tai Kwun**, not several — *Tai Kwun | 大館*. The instruction
said "the atlas tours"; the catalogue has one.

**Madame Fu** is relocated and **deliberately left outside the place**. It now sits at
**22.2813602, 114.1539782 — the restaurant's own published `businessLocationCoordinates` on
madamefu.com.hk**, which is **0.3 m from OSM's 營房大樓 Barrack Block centre**: two independent
sources agreeing, and its address there reads *3/F, Barrack Block, Tai Kwun, 10 Hollywood Road*.
That is a 22.9 m move — **inside** its own geofence, so no waiver was needed. It was previously
sitting on OSM's generic representative point for the whole compound, which is why it and *The
Public Spaces of Tai Kwun* were coincident in the first place.

🔴 **Madame Fu ends up 27.4 m from the Tai Kwun place — just outside the 25 m TIGHT radius — so
the sweep does not report it, checked.** It is out because the owner said so, not by accident:
a restaurant inside a heritage compound is not the compound. Treat this like the Tibidabo
precedent and do not "fix" it.

### The guard had to be waived, and only per entry

Three of those four moves exceed the entry's own `triggerRadiusMeters`. The assertion that
protected § A and § B is **not removed** — it is waived per entry, in the script, with the reason
recorded. Madame Fu's move was inside its radius and took no waiver.

### After

Validator **0 errors / 0 warnings** across 1,552 tours + 1,717 pins + **181 places** (was 142).
Seed emits 181. The sweep goes **40 exact → 0**, and `check-place-candidates.py` now **exits 0**:
every coincident group in the catalogue is a place.

⚠️ **The numbering below is the original sweep and is deliberately NOT renumbered** — B15 and B83
are cited elsewhere. Re-run `check-place-candidates.py` for the live remaining menu.


Every group below is built only from hops of 25 m or less, and the **widest of the 142
groups is 30 m end to end** — so none of them is a chain of separate sites strung together,
which is the failure mode that sank the 40 m proximity rule measured in session 95. 318
entries are covered.

| # | City | Span | Entries |
|---|---|---|---|
| B1 | Alang | 0 m | `[pin]` The Most Valuable Ships at Alang<br>`[pin]` Why Alang Became the Capital of Shipbreaking |
| B2 | Amesbury | 0 m | `[pin]` Stonehenge<br>`[pin]` The Oldest Photograph of Stonehenge |
| B3 | Ancient Messene | 0 m | `[pin]` Ancient Messene<br>`[pin]` Ancient Messene: Rivals of Sparta |
| B4 | Athens | 0 m | `[pin]` Metropolitan Cathedral of Athens<br>`[pin]` The Chains of Saint Paul |
| B5 | Atsugi | 0 m | `[pin]` KAIT Plaza<br>`[pin]` KAIT Workshop and Plaza |
| B6 | Baltimore | 0 m | `[pin]` Baltimore's Coastal Defenses<br>`[pin]` The Ruins of Fort Carroll |
| B7 | Braine-l'Alleud | 0 m | `[pin]` The Battlefield of Waterloo<br>`[pin]` The Lion's Mound, Waterloo |
| B8 | Brooklyn | 0 m | `[pin]` Inside the City Reliquary, Williamsburg<br>`[pin]` The City Reliquary, NYC's Tiny Museum |
| B9 | Brooklyn | 0 m | `[pin]` Inside FDNY Engine 226, Boerum Hill<br>`[pin]` Remembering the 343 Firefighters |
| B10 | Chicago | 0 m | `[pin]` Federal Reserve Bank of Chicago<br>`[pin]` The Machine Gun Turret at the Chicago Fed |
| B11 | Edinburgh | 0 m | `[pin]` Mary King's Close and Edinburgh's First High Rises<br>`[pin]` The Real Mary King's Close |
| B12 | Hong Kong | 0 m | `[pin]` Hong Kong Design Institute<br>`[pin]` The Vertical Campus of Hong Kong Design Institute |
| B13 | Hong Kong | 0 m | `[pin]` Madame Fu<br>`[pin]` The Public Spaces of Tai Kwun |
| B14 | Kyoto | 0 m | `[pin]` Inside Kyūkyodō Kyoto<br>`[pin]` Kyūkyodō Kyoto |
| B15 | Los Angeles | 0 m | `[pin]` First National Bank of Hollywood<br>`[pin]` First National Bank of Hollywood |
| B16 | Madison | 0 m | `[pin]` The Extension to the Unitarian Meeting House<br>`[pin]` The Unitarian Meeting House |
| B17 | Marathon | 0 m | `[pin]` A History of the Florida Keys<br>`[pin]` Building the Seven Mile Bridge |
| B18 | Mont-Saint-Michel | 0 m | `[pin]` Mont Saint-Michel<br>`[pin]` Mont Saint-Michel |
| B19 | Munich | 0 m | `[pin]` The Devil's Footprint at the Frauenkirche<br>`[pin]` The Frauenkirche Gravestones |
| B20 | New York | 0 m | `[pin]` Bronx Zoo<br>`[pin]` Ota Benga at the Bronx Zoo |
| B21 | New York | 0 m | `[pin]` Long Lines Building<br>`[pin]` The Windowless Skyscraper |
| B22 | New York | 0 m | `[pin]` Grand Central: Why the Zodiac Is Reversed<br>`[pin]` The Train Board at Grand Central |
| B23 | New York | 0 m | `[pin]` Katz's Deli: The Air Rights That Saved It<br>`[pin]` Katz's Delicatessen |
| B24 | New York | 0 m | `[pin]` The Hidden Hum of Times Square<br>`[pin]` The Times Square Confetti Blizzard |
| B25 | New York | 0 m | `[pin]` Solar Carve<br>`[pin]` Solar Carve from the High Line |
| B26 | New York | 0 m | `[pin]` The Separated Families of Ellis Island<br>`[pin]` Why Families Were Separated at Ellis Island |
| B27 | Osakasayama | 0 m | `[pin]` The Models at Sayamaike Museum<br>`[pin]` The Water Ramp at Sayamaike Museum |
| B28 | Pasadena | 0 m | `[pin]` Craig Ellwood at ArtCenter<br>`[pin]` The Sinclaire Pavilion |
| B29 | Queens | 0 m | `[pin]` Inside the Museum of the Moving Image<br>`[pin]` Museum of the Moving Image, Astoria |
| B30 | Queens | 0 m | `[pin]` The New York Hall of Science<br>`[pin]` Where Spider-Man Got His Powers |
| B31 | Tokyo | 0 m | `[tour]` Nishi-Sando Public Toilets | 西参道公衆トイレ<br>`[pin]` Sou Fujimoto's Nishisando Toilet |
| B32 | Topeka | 0 m | `[pin]` A Tour of the Kansas Museum of History<br>`[pin]` John Brown: Hero, Villain, or Anti-Hero? |
| B33 | Washington | 0 m | `[pin]` George Washington's Legacy<br>`[pin]` The Washington Monument's Troubled Build |
| B34 | Wonju | 0 m | `[tour]` Museum SAN | 뮤지엄 산<br>`[pin]` The Space of Light (Museum SAN) |
| B35 | New York | 0 m | `[pin]` $500 Billion of Gold Under 33 Liberty Street<br>`[pin]` The Federal Reserve Bank of New York |
| B36 | New York | 0 m | `[pin]` Hotel New Yorker: Nikola Tesla's Last Home<br>`[pin]` The Nikola Tesla Museum |
| B37 | New York | 0 m | `[pin]` Inside the Municipal Building<br>`[pin]` The Manhattan Municipal Building |
| B38 | Philadelphia | 0 m | `[pin]` Calder Gardens<br>`[pin]` Inside the New Calder Gardens |
| B39 | Brooklyn | 0 m | `[pin]` The New York Transit Museum<br>`[pin]` The New York Transit Museum |
| B40 | Queens | 0 m | `[pin]` Queens County Farm<br>`[pin]` Queens County Farm Museum |
| B41 | Oslo | 0 m | `[pin]` Deichman Bjørvika<br>`[pin]` Deichman Bjørvika<br>`[pin]` Inside Deichman Bjørvika |
| B42 | New York | 0 m | `[pin]` The Noguchi Museum<br>`[pin]` The Noguchi Museum |
| B43 | Toronto | 0 m | `[pin]` R.C. Harris Water Treatment Plant<br>`[pin]` R.C. Harris Water Treatment Plant |
| B44 | Toronto | 0 m | `[pin]` CIBC Square<br>`[pin]` The Rooftop Park at CIBC Square |
| B45 | Vatican City | 1 m | `[pin]` Is this a Renaissance diss track?! The Last Judgement by…<br>`[pin]` The Sistine Chapel |
| B46 | Los Angeles | 1 m | `[pin]` Hollyhock House<br>`[pin]` Hollyhock House |
| B47 | New York | 1 m | `[pin]` Inside the Museum of Chinese in America<br>`[pin]` Museum of Chinese in America<br>`[pin]` The Hidden Archive Above the Museum of Chinese in America |
| B48 | New York | 2 m | `[pin]` Sugar House Prison Window<br>`[pin]` The Sugar House Prison Window |
| B49 | Rome | 3 m | `[pin]` Bernini and Borromini in Piazza Navona<br>`[tour]` Piazza Navona |
| B50 | London | 4 m | `[tour]` St Paul's Cathedral<br>`[pin]` St Paul's Cathedral After the Great Fire |
| B51 | Stockholm | 4 m | `[tour]` Gamla stan 1859<br>`[tour]` Kouthoofd Familie Winkel |
| B52 | Sant Just Desvern | 4 m | `[pin]` Living in Walden 7<br>`[tour]` Walden 7 |
| B53 | Rome | 4 m | `[tour]` The Trevi Fountain<br>`[pin]` The Trevi Fountain |
| B54 | New York | 4 m | `[pin]` Hook & Ladder 8<br>`[pin]` The Ghostbusters Firehouse |
| B55 | Brooklyn | 4 m | `[pin]` Mount Prospect Park, Brooklyn<br>`[pin]` Mount Prospect and the Battle of Brooklyn |
| B56 | London | 5 m | `[pin]` Britain's Oldest Door<br>`[pin]` The Tomb of Elizabeth I |
| B57 | Paris | 6 m | `[tour]` Catacombs of Paris<br>`[pin]` What's Inside the Paris Catacombs<br>`[pin]` Why the Paris Catacombs Were Built |
| B58 | Chicago | 6 m | `[pin]` River City<br>`[pin]` River City |
| B59 | Rome | 6 m | `[tour]` The Pantheon<br>`[pin]` The Pantheon, Standing 2,000 Years<br>`[pin]` Who Really Built the Pantheon? |
| B60 | San Simeon | 6 m | `[pin]` Hearst Castle<br>`[pin]` Julia Morgan at Hearst Castle |
| B61 | Chicago | 6 m | `[pin]` Early Chicago's Justice System<br>`[pin]` The 28-Storey Prison in Downtown Chicago<br>`[pin]` The Skyscraper Prison |
| B62 | Roquebrune-Cap-Martin | 6 m | `[pin]` Eileen Gray's Villa E-1027<br>`[pin]` Villa E-1027 |
| B63 | Paris | 7 m | `[pin]` Centre Pompidou<br>`[tour]` Centre Pompidou |
| B64 | London | 7 m | `[pin]` Leadenhall Market<br>`[tour]` Leadenhall Market |
| B65 | New York | 7 m | `[tour]` New Museum<br>`[pin]` The New Museum Expansion |
| B66 | Paris | 7 m | `[tour]` Eiffel Tower<br>`[pin]` The Eiffel Tower<br>`[pin]` The Eiffel Tower in the First World War |
| B67 | Kyoto | 7 m | `[pin]` Ando's Garden of Fine Art<br>`[tour]` Garden of Fine Arts Kyoto | 京都府立陶板名画の庭 |
| B68 | Vence | 7 m | `[pin]` Matisse Chapel (Chapelle du Rosaire de Vence)<br>`[pin]` Matisse's Chapelle du Rosaire |
| B69 | Paris | 7 m | `[pin]` Gae Aulenti at the Musée d'Orsay<br>`[tour]` Musée d'Orsay |
| B70 | Barcelona | 8 m | `[tour]` Cafè de l'Arquitecte<br>`[tour]` Hotel Casa Sagnier |
| B71 | Chicago | 8 m | `[tour]` Cloud Gate (The Bean)<br>`[pin]` The Bean: Chicago's Million-Dollar Public Art<br>`[pin]` Under Cloud Gate |
| B72 | Chicago | 8 m | `[pin]` Chicago Water Tower<br>`[tour]` The Historic Water Tower |
| B73 | Madrid | 8 m | `[tour]` El Retiro: The Garden Handed to Everyone<br>`[tour]` Puerta de Alcalá |
| B74 | New York | 8 m | `[tour]` Chelsea Market<br>`[pin]` 👀 Oreos were first made in NYC! #nychistory #nyclife |
| B75 | Berlin | 9 m | `[tour]` The Reichstag<br>`[pin]` The Reichstag Dome |
| B76 | Hong Kong | 9 m | `[pin]` Handcrafter, D2 Place<br>`[pin]` Hoopla, D2 Place |
| B77 | New York | 9 m | `[pin]` Manhattan's Most Haunted House<br>`[pin]` The Merchant's House and the Underground Railroad |
| B78 | Humlebæk | 10 m | `[pin]` How Louisiana Became International<br>`[tour]` Louisiana Museum of Modern Art |
| B79 | Hong Kong | 10 m | `[pin]` Natural Spices Shop<br>`[pin]` New Patoy |
| B80 | Paris | 10 m | `[tour]` Arc de Triomphe<br>`[pin]` The Tomb of the Unknown Soldier |
| B81 | Florence | 10 m | `[pin]` All'Antico Vinaio<br>`[pin]` All'Antico Vinaio |
| B82 | New York | 11 m | `[tour]` Whitney Museum of American Art<br>`[pin]` Whitney Museum of American Art |
| B83 | New York | 12 m | `[pin]` Church of St Vincent de Paul<br>`[pin]` St. Vincent de Paul Church |
| B84 | Mechernich | 12 m | `[pin]` Bruder Klaus Field Chapel<br>`[pin]` Burning the Bruder Klaus Chapel |
| B85 | New York | 12 m | `[tour]` Citi Field<br>`[pin]` How the Mets Got Their Name |
| B86 | Hong Kong | 14 m | `[pin]` Little Bao<br>`[pin]` Primo Posto |
| B87 | Madrid | 14 m | `[tour]` Palacio Real<br>`[tour]` Royal Madrid: The Ring of Green |
| B88 | Taipei | 14 m | `[pin]` NTU College of Social Sciences Library<br>`[pin]` NTU Social Sciences Library |
| B89 | New York | 14 m | `[pin]` Central Park<br>`[pin]` Central Park: How It Was Designed |
| B90 | Kyoto | 15 m | `[tour]` Face House | フェイスハウス<br>`[pin]` The Face House of Kyoto |
| B91 | Tokyo | 15 m | `[pin]` The Glass Wave of the National Art Center<br>`[tour]` The National Art Center, Tokyo | 国立新美術館 |
| B92 | Paris | 15 m | `[pin]` Palais Garnier<br>`[tour]` Palais Garnier<br>`[pin]` Palais Garnier: The Real Phantom |
| B93 | New York | 15 m | `[tour]` Federal Hall<br>`[pin]` The Rotunda at Federal Hall |
| B94 | New York | 16 m | `[pin]` The Catacombs of Old St. Patrick's<br>`[pin]` The Godfather Baptism Church |
| B95 | Amsterdam | 16 m | `[tour]` Muntplein & the Munttoren<br>`[pin]` Munttoren |
| B96 | Denver | 16 m | `[pin]` Populus<br>`[pin]` Populus Denver<br>`[pin]` The Occupiable Windows of Populus |
| B97 | Munich | 16 m | `[pin]` Hofbrauhaus: JFK's Visit<br>`[pin]` Hofbrauhaus: The Beer Steins<br>`[pin]` Hofbrauhaus: The Dark Secret<br>`[pin]` The Dark History of the Hofbräuhaus |
| B98 | Chicago | 17 m | `[tour]` Marina City<br>`[tour]` Merchandise Mart |
| B99 | Barcelona | 17 m | `[tour]` Casa Amatller<br>`[tour]` Casa Batlló |
| B100 | San Juan | 17 m | `[pin]` Castillo San Felipe del Morro<br>`[pin]` The Sentry Box of Old San Juan |
| B101 | New York | 17 m | `[pin]` The Fletcher-Sinclair House<br>`[pin]` The Venetian Room at Albertine |
| B102 | Ho Chi Minh City | 17 m | `[tour]` Bếp Mẹ Ỉn<br>`[tour]` STIR - Modern Classic Cocktail |
| B103 | New York | 17 m | `[pin]` Conwell Coffee Hall<br>`[pin]` Inside Conwell Coffee Hall |
| B104 | Hong Kong | 17 m | `[pin]` Haidilao Hot Pot, Carnarvon Road<br>`[pin]` Matsukiyo |
| B105 | Hong Kong | 18 m | `[tour]` Fringe Club | 藝穗會<br>`[pin]` Ho Lan Zheng |
| B106 | Saint-Paul-de-Vence | 18 m | `[pin]` La Colombe d'Or<br>`[pin]` La Colombe d'Or<br>`[pin]` The Art on the Walls at La Colombe d'Or |
| B107 | New York | 18 m | `[tour]` Apollo Theater<br>`[pin]` Inside the Apollo Theater |
| B108 | Stockholm | 18 m | `[tour]` ArkDes — Swedish Centre for Architecture and Design<br>`[tour]` Moderna Museet |
| B109 | New York | 20 m | `[tour]` Flatiron Building<br>`[pin]` Why the Flatiron Building Is Empty |
| B110 | Hong Kong | 20 m | `[pin]` Lazy Suzy<br>`[pin]` Peng Leng Zheng |
| B111 | New York | 20 m | `[pin]` The 1920 Wall Street Bombing<br>`[tour]` Wall Street |
| B112 | Berlin | 21 m | `[tour]` East Side Gallery<br>`[pin]` Two Sides of the Berlin Wall |
| B113 | New York | 21 m | `[pin]` The Dark Secret of Wall Street<br>`[pin]` The Red Room at One Wall Street |
| B114 | Saint-Paul-de-Vence | 21 m | `[pin]` Fondation Maeght<br>`[pin]` Fondation Maeght<br>`[pin]` How Fondation Maeght Was Built |
| B115 | New York | 22 m | `[tour]` Stonewall Inn<br>`[pin]` The Stonewall Inn |
| B116 | Seoul | 22 m | `[tour]` Blue Bottle Studio Seoul | 블루보틀 삼청 한옥<br>`[tour]` Kukje Gallery K3 | 국제갤러리 K3 |
| B117 | New York | 22 m | `[pin]` The Real Winnie-the-Pooh<br>`[pin]` The Wertheim Study at the New York Public Library |
| B118 | Buenos Aires | 22 m | `[tour]` Diego Iluminado<br>`[tour]` Fundación Proa |
| B119 | New York | 22 m | `[tour]` Bethesda Terrace<br>`[pin]` Bethesda Terrace: The Tiled Ceiling in Central Park |
| B120 | Stockholm | 22 m | `[tour]` Bar Montan<br>`[tour]` Hosoi |
| B121 | Bangkok | 22 m | `[tour]` Baan Plern Jitt | บ้านเพลินจิตต์ ณ คลองบางหลวง<br>`[tour]` Khlong Bang Luang Floating Market | ตลาดชุมชนคลองบางหลวง |
| B122 | Barcelona | 23 m | `[tour]` Sant Pau Recinte Modernista<br>`[pin]` The Forty-Eight Pavilions of Sant Pau |
| B123 | Hong Kong | 23 m | `[pin]` Social Goods<br>`[tour]` Stone Slab Street | 石板街 |
| B124 | Buenos Aires | 23 m | `[tour]` Palacio Barolo<br>`[tour]` Salón 1923 |
| B125 | Hong Kong | 23 m | `[pin]` Heartwarming<br>`[pin]` Yu Chau Street |
| B126 | Chicago | 24 m | `[tour]` The Loop — Where the Skyscraper Was Born<br>`[tour]` The Rookery |
| B127 | Sydney | 24 m | `[tour]` Pellegrino 2000<br>`[tour]` The Rover |
| B128 | Uji | 25 m | `[pin]` The Keihan Uji Station<br>`[tour]` Uji Station | 宇治駅 |
| B129 | New York | 25 m | `[pin]` 31 Canal Street<br>`[pin]` Loew's Canal Theater |
| B130 | Queens | 25 m | `[pin]` The Hell Gate Bridge<br>`[pin]` The Hell Gate Sabotage Plot<br>`[pin]` Why the Hell Gate Bridge Was Built |
| B131 | Los Angeles | 26 m | `[tour]` Academy Museum of Motion Pictures<br>`[pin]` Jeff Koons' Split-Rocker Edition<br>`[tour]` LACMA |
| B132 | Hong Kong | 30 m | `[pin]` Dieci<br>`[tour]` Kau Kee | 九記牛腩<br>`[pin]` O'rm |

## C — 79 same-subject pairs 25–500 m apart

Related by name but not coincident. **Never auto-create these** — picking the
one coordinate is an editorial decision, and some are deliberately two subjects.

| # | City | Apart | Pair |
|---|---|---|---|
| C1 | Hong Kong | 26 m | `[pin]` Man Mo Temple<br>`[tour]` Man Mo Temple | 文武廟 |
| C2 | Hong Kong | 26 m | `[tour]` The Henderson | 美利道2號<br>`[pin]` The Henderson |
| C3 | New York | 28 m | `[pin]` The Breuer Building<br>`[tour]` The Breuer Building |
| C4 | Tokyo | 29 m | `[tour]` Tokyo International Forum | 東京国際フォーラム<br>`[pin]` The Glass Hall at Tokyo International Forum |
| C5 | Tokyo | 29 m | `[tour]` Prada Aoyama | プラダ 青山店<br>`[pin]` Prada Aoyama Epicenter |
| C6 | Paris | 29 m | `[pin]` Sainte-Chapelle<br>`[tour]` Sainte-Chapelle |
| C7 | New York | 31 m | `[pin]` The Ansonia: Should We Build Like This Again?<br>`[tour]` The Ansonia |
| C8 | Bronx | 31 m | `[tour]` Yankee Stadium *(in Yankee Stadium)*<br>`[pin]` Yankee Stadium and a Baseball Anthem |
| C9 | Bronx | 31 m | `[pin]` Yankee Stadium *(in Yankee Stadium)*<br>`[pin]` Yankee Stadium and a Baseball Anthem |
| C10 | Hong Kong | 31 m | `[tour]` Upper Lascar Row Antique Street Market | 摩羅上街古董露天市集<br>`[pin]` Upper Lascar Row |
| C11 | New York | 32 m | `[tour]` Washington Square Park *(in Washington Square Park)*<br>`[pin]` The 20,000 Skeletons Under Washington Square Park |
| C12 | New York | 34 m | `[pin]` The Port Authority Bus Terminal<br>`[pin]` Port Authority Bus Terminal |
| C13 | Copenhagen | 35 m | `[tour]` Frederik's Church - Marmorkirken (The Marble Church)<br>`[pin]` Frederik's Church (Marmorkirken) |
| C14 | London | 36 m | `[pin]` Abbey Road: The Conspiracy Theories<br>`[tour]` Abbey Road |
| C15 | New York | 39 m | `[pin]` Villa Charlotte Bronte<br>`[pin]` Villa Charlotte Bronte: English Villas in the Bronx |
| C16 | New York | 40 m | `[pin]` The Wall of Wall Street<br>`[pin]` The 1920 Wall Street Bombing |
| C17 | London | 40 m | `[tour]` Battersea Power Station<br>`[pin]` Battersea Power Station, Rebuilt |
| C18 | Toronto | 47 m | `[pin]` The Toronto Reference Library *(in Toronto Reference Library)*<br>`[pin]` Toronto Reference Library |
| C19 | Toronto | 47 m | `[pin]` Toronto Reference Library<br>`[pin]` Inside the Toronto Reference Library *(in Toronto Reference Library)* |
| C20 | Chicago | 47 m | `[pin]` Building Marina City<br>`[pin]` Marina City |
| C21 | Barcelona | 48 m | `[tour]` Tibidabo<br>`[tour]` Tibidabo Amusement Park |
| C22 | New York | 49 m | `[pin]` The Ford Foundation Building<br>`[tour]` Ford Foundation Building |
| C23 | Milan | 49 m | `[tour]` Fondazione Prada<br>`[pin]` Bar Luce at Fondazione Prada |
| C24 | Paris | 51 m | `[pin]` Place des Abbesses<br>`[tour]` Place des Abbesses & the Wall of Love |
| C25 | Chicago | 51 m | `[pin]` Obama Presidential Center<br>`[pin]` Obama Presidential Center |
| C26 | Toronto | 53 m | `[tour]` Graffiti Alley<br>`[pin]` Walking Graffiti Alley |
| C27 | New York | 54 m | `[pin]` The Wall of Wall Street<br>`[tour]` Wall Street |
| C28 | New York | 58 m | `[tour]` The Oculus<br>`[pin]` The Oculus |
| C29 | New York | 62 m | `[pin]` The Apthorp<br>`[pin]` The Apthorp |
| C30 | New York | 65 m | `[pin]` The Times Square Mosaic Map<br>`[pin]` Times Square |
| C31 | New York | 68 m | `[pin]` Behind Trinity Church: New York's Old Red Light District<br>`[tour]` Trinity Church *(in Trinity Church)* |
| C32 | Atsugi | 79 m | `[pin]` KAIT Plaza and Workshop<br>`[pin]` KAIT Plaza |
| C33 | Atsugi | 79 m | `[pin]` KAIT Workshop and Plaza<br>`[pin]` KAIT Plaza and Workshop |
| C34 | Chicago | 85 m | `[tour]` The Monadnock Building<br>`[pin]` Monadnock Building |
| C35 | New York | 88 m | `[tour]` Wall Street<br>`[pin]` The Dark Secret of Wall Street |
| C36 | Hong Kong | 88 m | `[pin]` The Public Spaces of Tai Kwun<br>`[tour]` Tai Kwun | 大館 |
| C37 | New York | 89 m | `[tour]` Little Island, Southwest Overlook<br>`[pin]` Little Island |
| C38 | Barcelona | 90 m | `[pin]` Why Millions Visit La Sagrada Família<br>`[tour]` Sagrada Família |
| C39 | London | 99 m | `[tour]` Covent Garden<br>`[pin]` Covent Garden: London's First Public Square |
| C40 | New York | 100 m | `[pin]` One Times Square *(in One Times Square)*<br>`[pin]` Times Square |
| C41 | Stockholm | 105 m | `[pin]` Vasa Museum<br>`[tour]` Vasa Museum |
| C42 | New York | 108 m | `[pin]` The Red Room at One Wall Street<br>`[tour]` Wall Street |
| C43 | Milan | 109 m | `[tour]` Bosco Verticale<br>`[pin]` Bosco Verticale |
| C44 | New York | 109 m | `[pin]` The Times Square Confetti Blizzard<br>`[pin]` Times Square |
| C45 | New York | 109 m | `[pin]` The Hidden Hum of Times Square<br>`[pin]` Times Square |
| C46 | New York | 127 m | `[tour]` Neue Galerie<br>`[pin]` The House Behind the Neue Galerie |
| C47 | Hong Kong | 129 m | `[tour]` Victoria Peak | 太平山頂<br>`[pin]` Bakehouse at Victoria Peak |
| C48 | Kyoto | 130 m | `[tour]` Gion | 祇園<br>`[pin]` Gion Ishi Sakashita Building |
| C49 | Queens | 135 m | `[pin]` Inside the Museum of the Moving Image<br>`[tour]` Museum of the Moving Image |
| C50 | Queens | 135 m | `[pin]` Museum of the Moving Image, Astoria<br>`[tour]` Museum of the Moving Image |
| C51 | London | 135 m | `[pin]` Big Ben<br>`[tour]` Houses of Parliament and Big Ben *(in Houses of Parliament)* |
| C52 | Amsterdam | 136 m | `[tour]` The Jordaan *(in Westerkerk)*<br>`[tour]` The Jordaan |
| C53 | New York | 142 m | `[pin]` The Wall of Wall Street<br>`[pin]` The Dark Secret of Wall Street |
| C54 | Chicago | 142 m | `[tour]` The Wrigley Building & Tribune Tower<br>`[pin]` Tribune Tower |
| C55 | Chicago | 142 m | `[tour]` The Wrigley Building & Tribune Tower<br>`[pin]` Tribune Tower *(in Tribune Tower)* |
| C56 | Bentonville | 152 m | `[pin]` Crystal Bridges Museum of American Art<br>`[pin]` Crystal Bridges Museum of American Art |
| C57 | Athens | 158 m | `[pin]` The Ancient Agora of Athens<br>`[pin]` The Agora of Athens |
| C58 | London | 161 m | `[tour]` Dennis Severs' House<br>`[pin]` Dennis Severs' House |
| C59 | New York | 162 m | `[pin]` The Red Room at One Wall Street<br>`[pin]` The Wall of Wall Street |
| C60 | Stockholm | 194 m | `[pin]` Stortorget, Gamla Stan<br>`[tour]` Gamla stan |
| C61 | Los Angeles | 212 m | `[tour]` LACMA<br>`[pin]` LACMA's David Geffen Galleries |
| C62 | Chicago | 214 m | `[tour]` Obama Presidential Center<br>`[pin]` Obama Presidential Center |
| C63 | New York | 256 m | `[pin]` Times Square<br>`[tour]` Times Square — The View from the Red Steps |
| C64 | San Francisco | 257 m | `[tour]` Chinatown: The City That Refused to Move<br>`[pin]` Chinatown |
| C65 | New York | 260 m | `[pin]` Roy Lichtenstein's Times Square Mural<br>`[pin]` Times Square |
| C66 | Chicago | 264 m | `[tour]` Obama Presidential Center<br>`[pin]` Obama Presidential Center |
| C67 | Paris | 276 m | `[pin]` Petit Palais<br>`[tour]` Pont Alexandre III & Petit Palais |
| C68 | Hong Kong | 289 m | `[pin]` Kowloon Park Stone Columns | 九龍公園百年石柱<br>`[pin]` Kowloon Park |
| C69 | Stockholm | 301 m | `[tour]` Gamla stan 1859<br>`[tour]` Gamla stan |
| C70 | Pasadena | 343 m | `[pin]` The Gamble House<br>`[tour]` Gamble House |
| C71 | Brooklyn | 364 m | `[pin]` The Cyclone at Coney Island<br>`[tour]` Coney Island |
| C72 | San Francisco | 395 m | `[tour]` Chinatown Dragon Gate<br>`[pin]` Chinatown |
| C73 | New York | 424 m | `[pin]` Governors Island<br>`[tour]` Governors Island |
| C74 | Brooklyn | 428 m | `[tour]` Domino Park<br>`[pin]` Domino Park |
| C75 | Chicago | 445 m | `[tour]` Marina City<br>`[pin]` Building Marina City |
| C76 | Naoshima | 455 m | `[tour]` Benesse House Museum | ベネッセハウス ミュージアム<br>`[tour]` Benesse House Museum Outdoor Works | ベネッセハウスミュージアム屋外作品 |
| C77 | Chicago | 486 m | `[tour]` Marina City<br>`[pin]` Marina City |
| C78 | New York | 497 m | `[pin]` The Noguchi Museum<br>`[tour]` The Noguchi Museum |
| C79 | New York | 497 m | `[pin]` The Noguchi Museum<br>`[tour]` The Noguchi Museum |
