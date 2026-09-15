# Rule 8d violated the day it was written: search the name

_2026-09-15 21:32 UTC · branch `tokyo-three-addresses`_

🔴 **Rule 8d was violated the same day it was written.** I told the owner three Tokyo pins could not
be placed because Wikidata had never heard of the venues. The owner sent Hotel Siro's address and
asked *"why weren't you able to find this?! it was practically the first result on google"*.

**One web search found each of the three immediately.** I never ran one — I queried Wikidata, got
nothing, and treated that as the fact being absent. That is exactly what rule 8d exists to prevent,
and it was added to `CLAUDE.md` earlier the same day after a session declared 42 Tokyo addresses
unobtainable and searching the names found 41.

Geocoded with GSI, every ward-check matching its pin's own neighbourhood:

| pin | GSI result | move |
|---|---|---:|
| Hotel Siro | 東京都豊島区池袋二丁目１２番１２号 | **203 m** |
| The Bellwood | 東京都渋谷区宇田川町４１番３１号 | **4 m** |
| Gyukatsu Ichi Ni San | 東京都千代田区外神田三丁目８番１７号 | **0 m** |

⚠️ **The outcome corrected my diagnosis as well as my method.** Two of the three were **already
correct** — only written at 3 dp. "These are broken" was as wrong as "these cannot be found". Same
shape as #917's three "unresolvable" pins that came out 11 m right, 220 m wrong, 100 m wrong:
**an unverifiable pin is not a wrong pin.**

⚠️ **Blind spot in the check itself:** Gyukatsu's correct coordinate is `35.702` — genuinely round —
so it still reads LOW-PRECISION after verification. The flag measures how a number is *written*,
not whether it is *right*.

LOW-PRECISION 13 → 11; flagged pins 19 → 17. Validator 0 errors.
