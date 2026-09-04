# STATUS — the live board

**What this file is.** A short, mechanical record of *what is in flight right now*: open PRs,
which TestFlight build carries which branch, and what is waiting on the owner. It is the thing
a session reads to answer "what is everyone else doing?" before it starts work.

**What this file is NOT.** History. `CLAUDE.md` § Current State is the narrative record of what
shipped and why, and it stays the authority for anything already merged. When an item here is
finished, it leaves this file and its story goes there. Never let this file grow a history
section — two histories drift, and drift is the problem this file exists to fix.

**Update rule (automatic, no prompting).** Any session that opens or merges a PR, dispatches a
TestFlight build, or discovers/clears an owner-blocked item updates the relevant table here in
the same commit. Re-derive rather than trust: `gh pr list --state open`, and read the build
numbers back from the Actions run list — never from what a PR body predicted.

**Last verified:** 2026-09-04 (session 143 — **a Toronto link-pin batch is open as [#734](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/734).** 40 owner-supplied Instagram links → **34 distinct posts → 33 shipped**; `linkPins` **1,151 → 1,184**, `makers` **305 → 328**; `tours` and `places` byte-identical. 🔴 **One post is BLOCKED, proven against a live control in the same pass with the same UA** — `DJUA6mbNMBi` returns `contextJSON: null` at ~215 KB on three spaced attempts while the control returns 256,575 bytes every time; no handle, no caption, **no `display_url`**, so no subject and no hero. ⚠️ **Six posts are Mississauga, not Toronto** — the heading was read against the payload, not trusted; Mississauga is new to the catalogue. **All 33 heroes opened and read against their captions — zero wrong subjects**, and **three vague captions were closed by the pixels alone**. 🔴 **Two place candidates the checker structurally CANNOT see, flagged by hand** — Museum Station at **0.05 m** and Ripley's at 13.8 m. **Nothing was nudged.** Heroes on gh-pages `5308c563`; deploy read **`in_progress`, never `cancelled`**, then **all 33 live URLs hash-verified against the uploaded bytes — 33 ok, 0 mismatch, 0 non-200**, after which `check-image-duplicates.py --pins` reads **`OK` over 1,179 images**, shared-URL half **0 errors / 208 documented reuses**. ⚠️ **`main` moved THREE commits mid-flight** (#731, #728, #732) and was merged in — ⚠️ **#731 claimed `archive/HANDOFF-260904.md`, an add/add collision, so this session's renumbered to `-2`**. Previously: session 142 — **PR [#730](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/730) MERGED** (squash `5763c137`: 104 link pins) and **VERIFIED LIVE** — the Supabase RPC, which the app reads first, serves **1,151 linkPins / 114 places**, with **0 pins wrongly inside `tours`**; ⚠️ the gh-pages mirror lagged at 1,047 for several minutes, the documented CDN lag, and the publish job's own verify step had already confirmed the committed blob. ⚠️ **The RPC returned HTTP 500 `57014 canceling statement due to statement timeout` on a cold call and 200 on retry** — the ~10 MB payload can exceed the statement timeout, which is the transient class `RemoteCatalogLoader`'s retry-with-backoff exists for; **do not read one 500 as a broken deploy.** **Then, on owner instruction (*"ADD THE ARCHITECTS AND MAKE BARCELONA PAVILION A PLACE"*), a follow-up is pushed on `claude/new-tour-links-cytwc6`, restarted clean off the merged `main`.** **Barcelona Pavilion 2 → 5 members with NOTHING MOVED** (all three pins were already on the place's exact coordinate), so `check-place-candidates.py` goes **12 → 11 EXACT, NEAR unchanged at 50** — falling by exactly the group resolved. **36 architects added to BOTH vocabularies, 383 → 419**, 50 entries gaining 58 tags, `Designed by a Master` kept on every one; **693 named-architect entries, 0 missing the shelf tag, 0 unused names.** 🔴 **The catalogue-wide sweep found 9 real authorship hits and 4 false positives** (Trinity Bellwoods ×3, a Melbourne suburb, and Manel Vicens the *client* of Casa Vicens), plus **`Lund Hagem`, a co-designer only the sweep surfaced.** ⚠️ **This is a CODE change and wants a simulator look.**)

**⚠️ This board is no longer polled on a timer.** The coordinator session ran a 25-minute check
from 04:50 to 12:25 and found something worth reporting on two of fifteen ticks, at roughly 20k
tokens a tick — so it is now **on demand** (owner decision, 2026-08-20). It goes stale the moment
a parallel session merges something. **Re-derive before trusting it**, per the update rule above.

---

## 1. Awaiting owner — device review

⚠️ **`list_pull_requests(state=open)` re-derived 2026-09-04 — [#728](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/728) has MERGED (squash `4da52445`), owner-verified on TestFlight 1.1.2 (141), and its story moves to `CLAUDE.md` § Current State.** #726, #729, #730 and #731 have merged too. Every "OPEN" line below is stale on the PR itself and survives only because it still carries a live owner decision. **Re-derive before trusting any line here.**

⚠️ **`list_pull_requests(state=open)` re-derived 2026-09-03 — the open PRs are [#726](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/726) and [#729](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/729) (session 141's).** #722, #723 and #717 have all merged, so every "OPEN" line further down this board is stale on the PR itself and survives only because it still carries a live owner decision. **Re-derive before trusting any line here.**

🟢 **[#734](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/734) — branch `claude/tour-links-ds0387`, 33 Toronto and Mississauga link pins (session 143).** Commit `1a477971`, cut clean off `origin/main` `5763c137`. 40 owner-supplied Instagram links → **37 distinct posts** (three pasted twice) → **33 shipped, 1 blocked, 3 dropped as duplicates**. `linkPins` **1,151 → 1,184** · `makers` **305 → 328** (23 new creator rows; the uuid5 scheme reproduced five live ids exactly, so those merged) · `tours` and `places` **byte-identical**. Content only — no Swift, no SQL, no build; the seed carries it, so it reaches Supabase on merge with **nothing for the owner to run**. Diff **1,709 insertions / 0 deletions**, asserted purely additive.
  - 🔴 **ONE POST IS BLOCKED AND CANNOT SHIP — proven, not assumed.** `DJUA6mbNMBi` returns **`contextJSON: null` at ~215 KB** on three spaced attempts, while a live control fetched in the same pass with the same UA returns **256,575 bytes every time**. No handle, no caption, and **no `display_url`** — so there is no subject and no hero, and a pin without one cannot exist. 🔁 **Blocked to a logged-out reader, not deleted.** ⚠️ **Do NOT re-wire it on "the link opens on my phone"** — the owner is signed in; a logged-out Atlas user gets a blank card.
  - ⚠️ **SIX POSTS ARE MISSISSAUGA, NOT TORONTO — the heading was read against the payload rather than trusted** (the session-135 rule). They ship `city: "Mississauga"`, which is **new to the catalogue**. Everything else is inside Toronto proper.
  - 🔴 **TWO PLACE CANDIDATES THE CHECKER STRUCTURALLY CANNOT SEE, FLAGGED BY HAND — owner's call, nothing created.** **Museum Station** lands **0.05 m** from the existing `@explorewithkevs` pin of the same station — a 6th-decimal difference, which defeats the EXACT tier, while the titles defeat the NEAR tier (the documented Grand Central / Textile Conservation Lab blind spot). **Ripley's Aquarium** lands **13.8 m** from the live Atlas tour. **Neither coordinate was nudged** — in either direction — so `check-place-candidates.py` is unchanged at **0 EXACT, exits 0**, and every group in the batch is two markers deep, inside `TourSetMap.maxStacked = 3`.
  - ✅ **ALL 33 HEROES OPENED AND READ AGAINST THEIR CAPTIONS — ZERO WRONG SUBJECTS**, and **three vague captions were closed by the pixels alone** (Bay Adelaide Centre, Curiosa, Riverdale Park East). ⚠️ **The Riverdale identification is an inference from the picture and is stated as one** — independently corroborated by the reverse-geocode landing on a sports pitch on Broadview Avenue, which is the running track in frame.
  - ⚠️ **FIVE SPEC ISSUES WERE CAUGHT BEFORE SHIPPING AND FIXED RATHER THAN SHIPPED** — one unknown tag (`Postmodern`, absent from the styleEra facet) and four entries carrying a Place type and an Experience tag but **no Theme**. Fixed by following the dominant park convention rather than inventing one.
  - 🔴 **THREE NEW BLIND SPOTS FOUND IN `validate-tours-mirror.py`, EACH ASSERTED DIRECTLY ON THE BATCH INSTEAD** — it checks neither a non-https hero, nor a duplicate maker id, nor a stop `order` other than 0. **Worth closing in the mirror.** ⚠️ The fault harness also under-counted its own misses on the first run by ignoring **warnings** — the documented session-141 harness bug, live again.

✅ **[#730](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/730) — MERGED (squash `5763c137`), verified live on the Supabase RPC at 1,151 linkPins / 114 places.** 104 link pins from `@archimarathon`, session 142's SECOND batch. 106 links → **105 distinct posts → 104 shipped** (one link pasted twice; one post names no place and is **parked, not guessed**). `linkPins` **1,047 → 1,151**; `tours`, `makers` and `places` byte-identical, **0 new maker rows** — the uuid5 scheme reproduced the live `@archimarathon` id exactly, and its avatar regenerated byte-identically and was **excluded rather than overwritten**. Content only — no Swift, no SQL, no build; the seed carries it, so it reaches Supabase on merge with **nothing for the owner to run**. Heroes on gh-pages `1d0ca6d6` (tree diff **exactly 104 additions, 0 deletions, nothing outside `images/`**; the deploy read **`in_progress`, never `cancelled`** against the Actions API, then **all 104 live URLs hash-verified against the uploaded bytes — 104 ok, 0 mismatch, 0 non-200**, after which `check-image-duplicates.py --pins` reads **`OK` over 1,146 images**, shared-URL half **0 errors / 208 documented reuses**). **Philippines is the catalogue's 45th country**; 22 new cities. **Both flagged owner decisions have since been ACTED ON — see the follow-up block above.**
  - ✅ **THE BARCELONA PAVILION IS NOW A FIVE-MEMBER PLACE (owner instruction).** The other eleven EXACT groups remain, all inside the cap. Original finding: 🔴 **TWELVE EXACT COINCIDENT GROUPS — `check-place-candidates.py` goes 0 → 12 and exits 1, ending the clean-exit state.** Every one is genuine (a multi-part series about one building, or convergence on OSM's own node) and **nothing was nudged together to manufacture one**. ⚠️ **The Barcelona Pavilion is the one that actually bites**: its existing place holds 2 members and this batch adds 3 more pins on the same point, so the site now carries **one capsule plus three loose pins against `TourSetMap.maxStacked = 3`** — past the cap, which puts a marker permanently out of reach on a shared list. **Joining them to the existing place is one line per pin.** The other eleven (ParkLife ×3, Yumebutai ×3, Equilateral House ×3, M+ ×3, Kyūkyodō ×2, Unitarian Meeting House ×2, ArtCenter ×2, plus Nishisando / HKDI / Tai Kwun / Serlachius forming with live content) are all inside the cap.
  - ✅ **THE ARCHITECT GAP IS CLOSED (owner instruction) — 36 names added to both vocabularies, 383 → 419.** Original finding: ⚠️ **named architects absent from the vocabulary, shipping the generic tag** — Paul Rudolph, Gordon Bunshaft / SOM, Pierre Jeanneret ×2, Arne Jacobsen, Junya Ishigami, Reima Pietilä, Roche & Dinkeloo, Schindler, Greene & Greene, Studio Gang, Atelier Oslo, Leandro Locsin, Berlage and Austin Maynard ×3 among them. **A `Models/Tag.swift` code change, kept out of a content batch.**

✅ **[#729](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/729) — MERGED (squash `32531c71`), verified live.** 61 link pins from `@archimarathon` plus TWO places and 48 architects (session 141). `linkPins` **986 → 1,047**; `tours`, `makers` and `places` byte-identical, **0 new maker rows**. Content only — no Swift, no SQL, no build; the seed carries it, so it reaches Supabase on merge with no owner SQL. **Two owner decisions are flagged and NOT acted on:**
  - ✅ **The two EXACT place candidates were BUILT on owner instruction (*"Make the places. Open PR"*)** — **Depot Boijmans Van Beuningen** and **Sayama Lakeside Cemetery**, places **112 → 114**, nothing moved (both pairs already coincident), and `check-place-candidates.py` returns to **0 EXACT, exits 0, NEAR unchanged at 39**. ⚠️ Both heroes are **borrowed from a member and that is structural** — no Atlas tour at either site, every member's gallery empty. ⚠️ **Sayama takes the chapel exterior over the community hall's finer interior**, on the establishing-shot criterion; one line swaps it.
  - **4 weak heroes, flagged not fixed.** **Rozet** is the sharpest — its frame is the library's interior stair rather than the Arnhem streetscape its caption is about. A link pin re-hosts only the thumbnail, so no other frame exists; the choice is keep or pull. ⚠️ **The other three are milder** and are named in `archive/HANDOFF-260903-2.md`.
  - ✅ **The architect gap is CLOSED on owner instruction (*"Definitely add those architects"*)** — **48 names added to BOTH vocabularies (335 → 383, total tags 385 → 433), 52 entries gained 62 tags**, `Designed by a Master` kept on every one. ⚠️ **This makes the PR a CODE change** (`Models/Tag.swift` + `scripts/validate-tours.swift`), so it wants a simulator look; CI is the compile check. Catalogue-wide after: **593 named-architect entries, 0 missing the shelf tag, 0 of 383 names unused.** ⚠️ The sweep found `Alvar Aalto` mentioned at Triennale di Milano and Stockholm Public Library and `James Stirling` at Palazzo Citterio — **all three are mentions, not authorship, and are deliberately untagged.**

🟢 **[#726](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/726) — branch `claude/tour-links-tp9fwp`, 29 link pins from `@archiwhisperer` and Avant Arte, plus Alwyn Court as a place and a third Guggenheim member (session 140).** `linkPins` **957 → 986** on the merged base; `tours`, `makers` and `places` byte-identical. Content only — no Swift, no SQL, no build; the seed carries it, so it reaches Supabase on merge with **nothing for the owner to run**. Heroes on gh-pages `44d7cc00`, **all 29 live URLs hash-verified against the uploaded bytes (29 ok, 0 mismatch, 0 non-200)**; `check-image-duplicates.py --pins` run **after** the deploy: **`OK`** over 981 images, shared-URL half **0 errors / 208 documented reuses**. Mirror **22/22 with a clean control**, then **0 errors, 0 warnings** across 1,552 tours + 986 pins + 111 places; **`check-place-candidates.py` holds at 0 EXACT and exits 0 on both sides**, NEAR 36 → 43. **Serbia is the 42nd country.** ⚠️ **`main` moved twice mid-session** (#722, #725) and `Tours.json` conflicted — resolved by taking `main`'s file and **re-running the idempotent assembler**, every check re-run. ✅ **FOLLOW-UP, same session — three owner decisions applied** (*"Alwyn court - make place. Guggenheim - add to place. Gilder center keep separate"*): **places 111 → 112.** **Alwyn Court is now a place** with all three pins as members, anchored on **OSM way 265147967**, which reverse-geocodes by name — so the stack cap no longer applies. ⚠️ **One member was already exactly on the anchor and did not move** (the build's first revision demanded that every member change and correctly refused to run); the other two moved **0.1 m** and **11.6 m**, all three asserted `manual` first. ⚠️ **Swept 400 m rather than trusting the checker's pairs** — The Osborne 82 m and Carnegie Hall 97 m correctly excluded. 🔴 **Its hero is borrowed from a member and that is structural** (three link pins with empty galleries and no Atlas tour at the site) — borrowed-hero count re-derived **38 of 112**; ⚠️ all three candidates were rendered and looked at, and **`@hereinnyc`'s is the better picture, rejected on the establishing-shot criterion** — one line swaps it. **The Guggenheim pin joined its existing place as a third member** (a 29 m move of a `manual` pin; the place's hero stays a third photograph). **The Gilder Center stays separate.** `tours` and `makers` byte-identical; **exactly 3 pins changed, in exactly their four coordinate fields**; diff **30 insertions / 13 deletions**. Mirror **22/22 with a clean control**, then **0 errors, 0 warnings** across 1,552 tours + 986 pins + 112 places; ⚠️ **18 place-layer faults injected against the two changed places — 18/18 caught, control clean**, exit code read directly. 🎉 **`check-place-candidates.py` holds at 0 EXACT and exits 0 on both sides, NEAR 43 → 38** — the diff proves it fell by **exactly the five pairs resolved** and gained nothing. Seed clean at **305 / 2,538 / 2,910 / 112**, **0 `images//`**, both place heroes live **200**.

**Nothing on this batch is waiting on the owner — both open questions are now closed:**
  - 🔴 **A POST IS PARKED AND CANNOT SHIP WITHOUT A DECISION — the Andreas Gursky reel** (`https://www.instagram.com/reel/CxgEBMxqcQX/`). Its caption names **no place**, its hero is **a portrait of the artist against a concrete wall with his name burned in** (not a photograph of anywhere), and **the two coordinates supplied for it are 7,006 m apart**: the Plus Code `8QC7XPRV+JC` decodes to Yanggak in central Pyongyang, the raw pair `39.0495750, 125.7752194` lands near the Rungrado May Day Stadium. Gursky's Pyongyang series photographs the Arirang Mass Games at that stadium, which favours the **raw** coordinate — **but that is inference and the post itself supports neither**, so it was handed back rather than guessed at (the session-112 precedent). ⚠️ **North Korea would be the catalogue's 43rd country.** **Owner: give one point, or drop it.**
  - **✅ CLOSED 2026-09-03 — the owner left it. *"Ok leave the gursky"*.** It was never wired, so this costs **no catalogue edit and owes no SQL** — a post that never reached `Tours.json` never reached Postgres (verified: `CxgEBMxqcQX` is absent from both the live RPC and the gh-pages mirror). **Do not re-raise it, and do not site it later from the raw coordinate** — the May Day Stadium reading is inference, which is exactly why it was parked.
  - ✅ **RESOLVED 2026-09-03 — Alwyn Court is a place, the Guggenheim pin joined its existing place as a third member, and the Gilder Center stays separate** (owner: *"Alwyn court - make place. Guggenheim - add to place. Gilder center keep separate"*). Places 111 → 112. **Do not re-raise any of the three.**
  - ✅ **Five weak heroes flagged — the Koons/LACMA pin was the likeliest pull and the OWNER KEEPS IT (2026-09-03: *"i'm fine with the koons"*). CLOSED; do not re-raise or quietly pull it.** Its hero is Jeff Koons holding two edition pieces, its caption is a limited-edition draw that **closed on 17 March**, and its only tie to a place is *"launched in support of @lacma"*; the supplied coordinate is exactly 5905 Wilshire, **4.3 m from the live Atlas LACMA tour**. Also weak: **Calder Gardens** (motion-blurred planting, **no building visible**), **Princeton University Art Museum** (a dim interior corridor), **the Studio Museum in Harlem** (an **archival B&W** of the 125th Street building, not the new Adjaye one), and **Wim Delvoye's X-Ray Windows** — whose Ghent coordinate reverse-geocodes to a **bare house number with no venue in OSM at any zoom**, with Caermersklooster 124 m away but nothing confirming it, so **no venue is asserted**.
  - ⚠️ **Three architect tags are practice→person mappings and are judgements**, following the `Foster + Partners`→`Norman Foster` precedent: caption says **OMA** → tagged `Rem Koolhaas`; **David Adjaye** → `Adjaye Associates`; **Studio Gang** → `Jeanne Gang`. One line each to reverse. 🔴 **The Studio Museum is deliberately NOT tagged `Adjaye Associates`** although he designed its new building, because that caption names no architect — **do not "finish the job."**
  - ⚠️ **7 of 15 Instagram pins will not play inline** — the documented licensed-music gate; poster + OPEN IN INSTAGRAM is the correct outcome. One also reports `copyright_blocked: true`.


⚠️ **`gh pr list --state open` re-derived 2026-09-02 20:25 UTC — exactly THREE open PRs: [#723](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/723) (Kowloon Hum place), [#722](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/722) (19 Hong Kong + Macau pins) and [#717](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/717) (closing the `@notbadgalriri__` decisions).** **#721, #715, #714 and #716 have all MERGED** — the entries below that still say OPEN are stale on the PR and were left alone only because each still carries an owner decision that is genuinely open. **Re-derive before trusting any line on this board.**

🟡 **[#722](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/722) — branch `claude/more-tours-a1xhw4`, 19 Hong Kong + Macau link pins (session 139), sent in two waves.** `linkPins` **905 → 924** · `makers` **297 → 303** · **`places` 108 → 111** (the three candidates, built on owner instruction) · `tours` byte-identical. Content only — no Swift, no SQL, no build; the seed carries it, so it reaches Supabase on merge with nothing for the owner to run.
  - 🔴 **Two of the first sixteen links CANNOT be pinned, ever.** They are Instagram **story highlights** (`/s/…`) by a third creator, `@kieranbrowntravel`. `LinkSource.embedURL` matches only `p`/`reel`/`tv`, so the app can build **no player**; the page also carries no `display_url` (no hero) and no caption (no subject). ⚠️ They are **NOT dead and NOT blocked** — do not re-try on "the link opens on my phone". Their two Plus Codes are orphaned.
  - ✅ **ALL THREE PLACE CANDIDATES ARE BUILT — owner instruction *"make the 3 places"*. Places 108 → 111.** **Hong Kong Railway Museum** · **In's Point** · **Bowrington Bridge Villain Hitting**, each two pins by **different creators** on one site (the Cube House shape, not the duplicate-Cheung-Hing shape); pins moved **0.46 / 36.57 / 25.72 m**, all `manual`, `tours` and `makers` byte-identical. 🔴 **Each anchors on a different member and the EVIDENCE decided, not seniority** — the Railway Museum and villain-hitting take the older pin (they sit on OSM's own named nodes), **In's Point takes the NEW pin because OSM carries the shop twice and only that node has the house number 530** (the Jamia Mosque rule). 🔴 **`check-place-candidates.py` could see only two of the three** — the hyphen in `Villain-Hitting` breaks its title-containment rule — so **NEAR falls 38 → 36 and nothing is removed for the third**; EXACT stays 0, clean exit both sides. ⚠️ **All three heroes are borrowed and that is structural** (every member is a link pin with an empty gallery, no Atlas tour at any site); borrowed-hero count re-derived **37 of 111**.
  - 🟡 **Three weak-ish heroes, flagged not fixed** — `The Four Columns at Kadoorie Farm` is a **historical B&W photograph of the demolished building the columns came from**; `The Rare LEGO Sets at In's Point` is the shop's **sign**, carrying none of the LEGO; `I Love Cake, Wan Chai` is **creator-forward**, though the shelves read behind her. A link pin re-hosts only the thumbnail, so no other frame exists.
  - ⚠️ **One title is a stated compromise** — `Louis Vuitton Lee Gardens` is titled for the **venue, not the Bar Leone pop-up it hosts** (so it cannot go stale), but categorised `foodAndDrink` because the post is entirely a bar visit and the catalogue has no shopping category.
  - ⚠️ **11 of 19 will not play inline** — the documented licensed-music gate; poster + OPEN IN INSTAGRAM is the correct outcome.


🟡 **MERGED — [#721](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/721) (squash `51889d67`), session 139, 32 Hong Kong link pins. The PR is closed, and TWO of its three owner decisions are now closed too.** ✅ **Verified against the systems rather than the success line:** the squash genuinely changed files on `main` (1,821 insertions across 6 files, all 32 shortcodes present, the blocked post correctly absent), the **live RPC serves 937 link pins with 0 wrongly inside `tours`** and places 107, and the gh-pages **committed blob** carries 937/299/107 while the CDN was still serving 905 — the documented lag, not a failed publish. All 32 heroes confirmed still in the gh-pages head tree, which matters because a parallel session was pushing more Hong Kong heroes on top throughout. ⚠️ **`main` moved mid-flight** — [#719](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/719) landed and was merged in with every check re-run, so the merged base reads **107 places**, not the 105 this batch was cut against. linkPins **905 → 937**, makers **297 → 299**; `tours` and `places` byte-identical. gh-pages `2baba65`, all 32 live heroes hash-verified. Three things want an owner call:
  - **✅ CLOSED — the stray Plus Code, and the answer means NOTHING MOVES.** `75M2+9X Central` was pasted beside the EONIQ reel but decodes onto Aberdeen Street, SoHo, 13 km from the Tsuen Wan address that reel's own caption gives; EONIQ ships on the caption. Owner named its real post: **`DTK5kAFk6Dx` — Chez Trente**, which had *already* been pasted with its own code (`75J2+WX Central`), so **the venue was given two codes at different times under adjacent links**. Measured: `75J2+WX` reverse-geocodes to **house 4-6, Chung Wo Lane** (Chez Trente's published address is **6 Chung Wo Lane**, forward geocode 10 m away) while `75M2+9X` is **117 m off on 20 Aberdeen Street**. **The pin already sits on the door and was deliberately NOT moved.** 🔴 **Do NOT "fix" Chez Trente onto Aberdeen Street** — a hand-dropped code is a tap on a map, and the venue's published address outranks it.
  - **✅ CLOSED — `Heartwarming` STAYS (owner, 2026-09-02: *"keep heartwarming"*). Do not re-raise or replace it.** Its hero is the creator walking a street with no view of the shop or its sesame desserts — the batch's weakest — and a link pin re-hosts only the thumbnail, so keep-or-pull was the whole choice. Lazy Suzy, Dieci and La Petite Maison are creator-forward and stay too. ⚠️ **The open-every-hero audit will flag this again; it is settled** (the Ministry of Enterprise precedent).
  - **⚠️ STILL OPEN, but it is a DISCLOSURE rather than a question.** `Jean-Pierre` — OSM maps no 9 Bridges Street, so the pin sits between Bridges Street Market (no. 2) and Yardbird (no. 33), which bracket it. **The batch's weakest coordinate, stated rather than hidden.** Nothing to decide unless the owner knows the exact door, in which case it moves.
  - **⚠️ One post is blocked** (`C3r_kz1v9Ct`, `contextJSON: null` proven against three live controls) — blocked now, not gone; re-testable in two minutes later.

✅ **DONE — `backend/pull_pins_260902.sql` HAS BEEN RUN (owner, 2026-09-02). Nothing is owed here; do not tell the owner to run it again.** **Verified against the LIVE RPC rather than the SQL Editor's success line:** `linkPins` **907 → 905** and `@shivanidukhandee` **106 → 104**, both now matching the catalogue exactly. `Xiang Bo Bo` is gone. ⚠️ **`Cheung Hing Coffee Shop` is STILL SERVED and that is CORRECT** — the file deleted the *duplicate* (`c4071953…`, the Pineapple Bun Hunt post) and kept the surviving twin `d3bb855c…`, which is confirmed present; exactly one remains where there were two. ⚠️ **`Cheung Hing Tea Hong` is a DIFFERENT venue 2 km away and was untouched.** Session-99 dropped-key check clean on the same payload: `priceTier` on all 1,553 with 66 priced, `isPrivate` on all 311 makers, `country` 1,552, `videoRole` 1,553, **0 link pins wrongly inside `tours`**, both new places still served, places 107. ✅ **RE-VERIFIED 2026-09-02 after the owner ran it a second time** (idempotent, so the repeat cost nothing): the live RPC and the catalogue now agree **exactly at 937 link pins**, with **0 catalogue pins missing from the RPC and 0 pins live that the catalogue does not carry** — drift is zero in both directions. Both target ids are absent, the maker row is kept, and `@shivanidukhandee` reads **104 live against 104 in the catalogue**.
  - ✅ **Everything else from those ten notes is LIVE and verified field-by-field on the RPC** — five renames and all seven coordinate moves, including three that were badly wrong: **Aquatic Market sat in Luohu District, SHENZHEN** (25 km away, across an international border, while its own `country` field read Hong Kong), **Min Fong Hong** in Tai Po 13 km from the Tsuen Wan its caption names, and **Lau Hing Kee** in Tin Hau against the creator's own `#mongkok` hashtag.
  - ✅ **CLOSED — the address request is answered and the batch is finished.** Owner: ***"TAKE OUT THESE TOURS. CANT FIND A RELIABLE ADDRESS FOR THESE SO WE'RE GOING TO OMIT"*** — all eight dropped. **Nothing was deleted and no SQL is owed**: none of the eight was ever wired, so none ever reached Postgres. ⚠️ **Haidilao was NOT a ninth deferral — it was already live**, and has since been moved to Carnarvon Road on owner instruction. ⚠️ **`Lau Kee Aberdeen Boat Noodle` in the catalogue is an ATLAS NARRATED TOUR, not the dropped pin — do not remove it on a name match.** Final: **105 shipped · 11 dropped · 0 deferred · 2 blocked** of 116 pinnable — the last deferral (a second Kowloon Hum reel) was shipped on owner instruction *"if they are different reels, then add it and make it a place"*, and **Kowloon Hum is now a place**. ⚠️ **Wiring it also exposed that the LIVE pin was 281 m off the address its own caption gives** — see § 1. ⚠️ **Do not count this batch from `analysis.json`** — it carries two posts by other creators and a first pass here reported 106/118 off it, wrong by two.
  - 🟡 **STILL OPEN — 1 EXACT place candidate: The Hideout, Mui Wo** (two posts about one venue on one owner-supplied coordinate). The Cheung Hing pair that sat beside it was resolved by the owner's own "duplicate" call. ⚠️ **The perceptual check had scored that pair 55.8 — comfortably "two different pictures" — so byte and perceptual checks were both right and still could not see it. A duplicate of SUBJECT is not a duplicate of PIXELS.**

🟡 **OPEN — [#715](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/715) nineteen Hong Kong link pins from Instagram `@notbadgalriri__` (session 138)**, branch `claude/tour-links-exviiy`. Twenty links, one reel pasted twice, so **19 distinct posts ship**. **linkPins 846 → 865 · makers 263 → 264 · `tours` and `places` byte-identical.** Content only — no Swift, no SQL, no build; the seed carries `linkPins`, so it reaches Supabase on merge with **no owner SQL**. Heroes on gh-pages `e3503251`, **all 19 live URLs hash-verified against the uploaded bytes (19 ok, 0 mismatch)**; `check-image-duplicates.py --pins` **`OK`** over 860 images, shared-URL half **0 errors / 208 documented reuses**. Validator mirror **self-tested 40/40**, then **0 errors, 2 pre-existing warnings**; `check-place-candidates.py` output **byte-identical to `main`'s** (2 EXACT / 38 NEAR — nothing manufactured).
  - ✅ **CLOSED — a supplied Plus Code contradicted its own post, and the owner confirmed the caption.** `862H+Q4 Cha Kwo Ling` was pasted beside the second copy of `DZuR4QoP_8R`; it decodes onto the **Central Kowloon Bypass, a motorway under construction**, while that reel's caption gives an explicit address **15 km away** in Tsuen Wan. Confirmed three ways (OSM names 荃德花園 Tsuen Tak Gardens at **house number 208** exactly; the creator's own burned-in subtitle reads *"Nocturnal Stationery in Tsuen Wan is a humble shop"*; the code lands on a road, not a venue), so **the caption won**. ✅ **CONFIRMED BY THE OWNER 2026-09-02** (*"go with the correct location as you've placed it"*): the pin stays in Tsuen Wan, **the stray code is ignored, and there is no missing twentieth reel**. Closed — do not re-open it or move the pin onto the code's point.
  - ✅ **CLOSED — the Rednaxela Terrace hero stays.** Owner decided 2026-09-02 on sight (*"keep"*), after the live hero was **rendered and sent** rather than described. It is a wet market while the subject is beyond doubt (the code reverse-geocodes onto the terrace by name) — **the sharpest mismatch in the batch, and it ships as-is. Do not re-raise it or source a replacement** (the Ministry of Enterprise / Casa Lleó Morera precedent). 🟡 **Victoria Skypark** (a mall walkway, not the sunset-and-skyline its caption is about) and **Camelpaint Building** (street b-roll) are still open, though keeping the worst of the three effectively answers them. A link pin re-hosts only the thumbnail, so **no other frame exists** — the choice is only ever keep-or-pull.
  - ✅ **CLOSED — the toy store stays unnamed** (owner, 2026-09-02: *"leave the toy store name unknown as-is"*). Its caption withholds it (*"COMMENT 'TOY' TO GET THE LOCATION"*) and the shopfront sign is only partly legible (`…0AMPM TOYS`, its first character behind the creator's own `[13/100]` overlay), so it ships as **`A Vintage Toy Store in Tsim Sha Tsui`** — the Banksy convention. **Do not name it later from a guess; a partly-legible sign is not a name.**
  - ✅ **CLOSED — Man Luen Choon's district was raised in error and needs no decision.** The pin sits on OSM's node named for the shop (140-142 Des Voeux Road Central, which OSM files under **Central**) while the caption says **Sheung Wan** — but **"Sheung Wan" appears only inside `longDescription`, the creator's verbatim caption, and the pin's own `city` is `Hong Kong`**, so nothing this catalogue authors names a district and there is no line to move. 🔴 **Check what a discrepancy changes in the shipped fields before putting it to the owner** — two sources disagreeing is a decision only if a field we author must pick one. The siting reasoning stands: OSM *also* names Wing Cheong Commercial Building, 19-25 Jervois Street (Sheung Wan) 230 m away, and **the OSM node named for the business is the only in-session evidence tying the name to a point**, so it won.
  - ⚠️ **Ohara Ikebana ships on a street centroid and no house number was invented** — OSM maps Kam Ping Street with no addressed nodes (the Operaparken precedent). ⚠️ **Prime Steak Restaurant is in no OSM record** and sits on its code's real address point, 218-220 Sai Yeung Choi Street South (the COSM Atlanta case). ⚠️ **13 of 19 will not play inline** — the documented licensed-music gate.
  - ⚠️ **[#714](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/714) is open in parallel** (42 Miami pins + 5 places, `claude/new-tour-links-mphq67`). **Zero overlap on sourceURLs, tour ids, maker ids and hero filenames — checked, not assumed** — but both append to `linkPins`, so **whichever merges second must redo its catalogue edit the documented way: take `main`'s file and re-apply, never hand-resolve a JSON conflict.**

✅ **MERGED AND CLOSED — the `@shivanidukhandee` Hong Kong batch, now 104 of 116 pinnable posts shipped (session 137, closed session 138)** — it was 106 when these four PRs merged; #716 then removed two on owner instruction, across four PRs: [#708](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/708) (46), [#710](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/710) (3), [#711](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/711) (15), [#712](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/712) (42 new + 15 coordinate upgrades, squash `b46e354c`). **linkPins 740 → 846 · makers 262 → 263 · tours and places byte-identical.** **Verified live on the Supabase RPC — 846 pins, 106 on the maker row, 0 wrongly inside `tours`, `priceTier` on all 1,553 with 66 priced, `isPrivate` on every maker, places 100** — and the gh-pages mirror converged ~6 minutes later. All 42 new heroes **hash-verified against the uploaded blobs, 42 ok / 0 mismatch**; `check-image-duplicates.py --pins` **`OK — no suspicious duplicates`** over 841 images, shared-URL half **0 errors / 208 documented reuses**. Content only — no Swift, no SQL, no build.
  - ✅ **CLOSED 2026-09-02 — the owner dropped all eight rather than sourcing addresses.** `drafts/hk-shivanidukhandee/ADDRESSES-NEEDED.txt` is now a **closed record**, not a pending request; it names the eight shortcodes and the two catalogue entries that share a name with them and must not be removed. **Haidilao was never a ninth deferral** — that reading was wrong, it was already shipped.
  - 🟡 **STILL OPEN — 2 posts are blocked by Instagram and 1 was dropped.** `C6vyhv4NhMu` and `DW_uE17B0dW` return `contextJSON: null` (~219 KB against ~260 KB, proven against live controls in the same pass with the same UA) — **no handle, no caption, no thumbnail, so a pin with no hero cannot exist**. 🔁 Blocked now, not gone; worth a two-minute recheck in a month. ⚠️ **Do NOT re-wire them on "the link opens on my phone"** — the owner is signed in. `DViylUIjGUg` was dropped as a **reposted Disneyland clip** (perceptual distance 2.8 against its twin); one line restores it.
  - 🟡 **STILL OPEN — 8 place candidates flagged, none created.** Including **Cheung Hing Coffee Shop ×2** (two genuinely different posts, both shipped) and **The Hideout, Mui Wo ×2** (two posts about one venue on one owner-supplied coordinate). `check-place-candidates.py` reads **2 EXACT / 38 NEAR**; neither pair was nudged apart to dodge the checker.
  - ⚠️ **Three pins ship outside Hong Kong and MACAU IS THE CATALOGUE'S 41st COUNTRY** — Chagee at the Venetian and IONG'S Magic Shop (Macau, a new city), and Elco Pani Puri (Mumbai, new city; India already existed). All three reverse-verified.
  - 🔴 **One creator caption is wrong and the owner's coordinate is right.** A post captioned *"Sai Wan Ho Rock Pools"* sits **20 km** from the supplied point, which lands in **Sai Kung country park** where Hong Kong's cliff-jumping rock pools actually are — and the hero settles it independently. It ships as **`Rock Pools at Tai Long, Sai Kung`**; the creator's wording stays verbatim in their own caption.

✅ **MERGED — [#700](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/700) sixteen Hong Kong link pins (session 137)**, squash `c868a964`, **verified live on the Supabase RPC**: all sixteen present, 0 pins wrongly inside `tours`, 66 tours still priced. Owner sent sixteen Instagram reels; all sixteen shipped. **linkPins 696 → 712, makers 246 → 247.** Content only — no Swift, no SQL, no build; the seed carries `linkPins`, so it reaches Supabase on merge with **no owner SQL**.
  - 🟡 **STILL OPEN — four weak heroes are the owner's call** — **#10 The Pokfulam Farm is a close-up of a blue COW SCULPTURE** with nothing identifying the farm or Hong Kong (the likeliest pull); PMQ is a basement, Green Hub an interior jail cell, HKDI a corridor detail. A link pin re-hosts only the thumbnail, so **no other frame exists** for any of them.
  - ✅ **ALL THREE PLACE CANDIDATES ARE BUILT — owner instruction, [#705](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/705), CI green. Places 97 → 100.** PMQ, Jamia Mosque and Sai Wan Swimming Shed; the pin moved 45 / 28 / 30 m onto its tour (nothing here is geofenced, so each anchor was decided on its own evidence). **Every hero is a real third photograph** from the Atlas tour's own gallery, so nothing was sourced and these three add **zero** borrowed heroes. See `archive/HANDOFF-260901-13.md`.
  - 🟡 **STILL OPEN — ⚠️ `Coldefy & Associés` is named in a caption and is absent from the vocabulary** — the Hong Kong Design Institute ships the generic `Designed by a Master`. Adding the name is a `Models/Tag.swift` **code** change for a future architect PR.


**The test — one field decides it.** Fetch each post's embed and read `contextJSON`:

```bash
UA="Dozent/1.0 (link-pin tool; +https://dozent.world)"
for sc in Dcrfes9p-_x DVMsHoSkfHz DbODWROJUPl Day97y6Jvya DaWJQoESt0g DaDjmywBe8U; do
  n=$(curl -sSL --max-time 25 -A "$UA" "https://www.instagram.com/reel/$sc/embed" \
      | grep -o 'contextJSON":null' | wc -l)
  echo "$sc  $([ "$n" = 0 ] && echo READABLE || echo still-null)"
  sleep 3
done
```

**`contextJSON: null` → still blocked, change nothing.** Non-null → they are pinnable: run the normal
link-pin flow and they join the catalogue in minutes. ⚠️ **Always run a live control in the same pass**
(e.g. `DcTW0yzsEok`, a pin already in the catalogue) — without one, a transient failure reads as a
restriction.

🔴 **Do NOT wire them on "the links work on my phone" alone.** The owner is signed in; the app's
`WKWebView` is not. With a null context the app's embed — `instagram.com/reel/{code}/embed`, the same
URL — renders **blank**, and there is no `display_url` so **no hero exists either**. A forced pin looks
right to the owner and is a dead card for every other user. **Verify the field, not the phone.**

**⚠️ It is an ACCOUNT-level block, so one post answers for all six**: 25 posts from 21 other creators
carried a full context in the same runs; all 6 from this one creator carried none.

**If the subjects matter sooner:** the owner rates these as quality tours, and an Atlas tour beats a link
pin anyway — it works offline, downloads, and fires at a geofence, none of which a link pin can do.
⚠️ Toronto already has **42** Atlas tours, so check for overlap before drafting.


✅ **MERGED — [#698](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/698) squashed as `0312ced5` (session 135): 25 Toronto link pins.** All four CI checks green (**Validate Tours.json**, simulator build, unit tests, Vercel), and the squash was **verified to have actually changed files on `main`** — 1,705 insertions across 5 files — rather than trusting GitHub's success line (the #629 empty-squash lesson). ✅ **VERIFIED LIVE ON BOTH SOURCES, read back rather than assumed from the workflow's success line:** the **Supabase RPC** (the PRIMARY source) serves **590 link pins · 25 Toronto · 0 link pins inside `tours`**, and the **gh-pages mirror** serves **590 · 25**. ⚠️ The seed took **~15 minutes** on "Apply seed" — well past the mirror job, which finished in 12 seconds — so a content merge is not live the moment CI goes green; poll the RPC. ⚠️ **The RPC reports 1,553 tours against the catalogue's 1,552** — the long-standing `Zxxx` test tour, pre-existing; **assert on link-pin counts, not tour totals.** The original PR notes follow.

🟡 **(superseded, kept for the decisions)**
Owner sent 31 Instagram reels as "Toronto links 260901". **linkPins 565 → 590 · makers 226 → 246**;
tours and places unchanged. **Toronto's first pin batch** — 42 Atlas tours, zero pins before.
Committed `f62daa8c` and pushed; gh-pages `a506a5b` with all 25 heroes hash-verified live.
**PR #698 opened on owner instruction — CI is the authoritative validator and nothing compiled locally.**
🔴 **Links 1, 2, 4, 8, 9, 10 are ALIVE, not dead — the owner opened them on their phone, correcting an
over-read on my part.** The real cause is `contextJSON: null` on the embed page: Instagram withholds the
media context from a logged-out reader. **They still cannot ship** — the app builds that same embed URL
and is logged out, so a pin would render blank and has no hero either. **NOT WIRED**; nothing was
removed. ⚠️ **Owner can settle WHY by sending the creator handles** — a private account says so publicly.
**Three things remain the owner's call:** (1) the **Cube House pair** ships as two pins, which takes
`check-place-candidates.py` **0 EXACT → 1** — honest, neither pin nudged, one line removes either;
(3) **three weak heroes**, **One King West** sharpest (its frame is the CN Tower, not the vault);
(4) **four place candidates** — ROM 9 m, Casa Loma 11 m, Distillery District 40 m, Osgoode Hall 57 m.
✅ **All four are BUILT — see the entry below.**


✅ **MERGED — [#702](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/702) squashed as `855938a8`, and
**verified live on the Supabase RPC** (the PRIMARY source, ~2 min after merge): **91 places · 7 in Toronto ·
all three new ones present · the Royal Ontario Museum place carrying 3 members, all resolving and all on its
exact coordinate · 0 link pins wrongly inside `tours`**, with the session-99 dropped-key check clean
(`priceTier` on all 1,553 with 66 priced, `isPrivate` on all 274 makers). The squash was confirmed to have
**actually changed files** — 347 insertions across 5 — rather than trusting GitHub's success line. ⚠️ The
gh-pages mirror lags the RPC and converges on its own; the RPC is what the app reads first. ⚠️ **The RPC
reports 1,553 tours and 274 makers against the catalogue's 1,552 and 262** — the long-standing `Zxxx` test
tour and upsert-only maker accumulation, both pre-existing; **assert on place counts, not totals.** The
original entry follows.

🟡 **(superseded, kept for the decisions)** Casa Loma, the Distillery District
and Osgoode Hall become places, and the Crystal joins the ROM (branch `claude/tours-links-upload-h6t2cs`,
session 135b).** Owner: *"ROM IS ALREADY PLACE -
ADD THE NEW TOUR INTO THE PLACE, MAKE CASA LOMA A PLACE, MAKE DISTILLERY A PLACE, OSGOODE A PLACE"* —
the four candidates #698 flagged. **Places 88 → 91.** Content only — no Swift, no SQL, no gh-pages push,
no build; the seed carries `places`, so this reaches Supabase on merge with **no owner SQL**.
  - **Each new place is an Atlas Studio YYZ single-stop tour paired with the #698 link pin of the same
    subject.** The ROM place gains the Crystal pin as a **third** member beside the Museum Mile walk and
    the ROM single.
  - **🔴 The pin moves, never the tour — and the build asserts why.** All four Atlas tours are
    `geofenced` (moving one changes where its audio fires); all four pins are `manual`, so moving one
    costs nothing. Moves: **11.4 m** Casa Loma · **40.3 m** Distillery · **56.7 m** Osgoode · **9.5 m**
    the Crystal, onto the ROM place's existing coordinate. Exactly **four coordinate fields per pin**.
  - **✅ EVERY HERO IS A THIRD PHOTOGRAPH, promoted from the member tour's own gallery** — already
    uploaded, already verified, **nothing sourced**, and `hero not in member_heroes` is a hard assertion.
    **The borrowed-hero count does not move: 21 of 88 → 21 of 91.** All nine candidates were **rendered
    and looked at**, not chosen by filename.
  - **⚠️ Two hero calls are judgements and each is a one-line swap.** **Distillery takes the winter
    street-clock view** (`_6`) — the cobbled lane with the stone mill, the most *establishing* frame —
    over the LOVE-padlock wall (`_4`, warmer, no people, but one wall) and the **seasonal** Christmas
    market (`_5`). ⚠️ Its "JOHN FLUEVOG" tenant sign is legible; that is a real shopfront in a
    re-tenanted Victorian works, the Crocker Galleria precedent, not a watermark. **Osgoode takes the
    painted-ceiling hall** (`_2`) over the two courtrooms (`_3`, `_4`) — all three candidates are
    interiors, because the tour's own hero already carries the classical exterior. **Casa Loma's Great
    Hall (`_2`) was the only candidate.**
  - **⚠️ Membership was swept, not inferred from the checker's pairs.** Within 320 m: Spadina Museum
    (150 m) is a separate museum; Nathan Phillips Square (189 m) and the City Hall pin (270 m) are
    separate subjects; Gardiner Museum (111 m) and Museum Station (150 m) likewise. **🔴 The Old Town
    walk's stop 5 IS the Distillery District, 16 m away — and it is correctly NOT a member:** a walk
    anchors on stop 0, which is 1,771 m away at St Lawrence Market, and that walk is already in the
    Union Station place. A tour may belong to one place only.
  - **⚠️ Addresses are editorial, corroborated by geocoding rather than taken from it.** Casa Loma
    reverse-geocodes **by name** to *1 Austin Terrace*; Osgoode's forward geocode names it exactly at
    *130 Queen Street West*, on the pin's own coordinate. **The Distillery ships 55 Mill Street, the
    complex's published address (38 m away), not OSM's 10 Trinity Street filing** — the La Pedrera rule.
  - **⚠️ The Osgoode tour's coordinate is a deliberate vantage and was NOT moved.** It sits 57 m south of
    OSM's building node, on the Queen Street fence — which is where the cow gates are, and the gates are
    the tour's whole hook (the Grand Central / Petersen shape).
  - **Verification.** Validator mirror (vocabulary from **both** Swift files, **385 tags**) **0 errors,
    0 warnings** across 1,552 tours + 740 pins + 91 places. ⚠️ **Eleven place-layer faults were injected
    against the FOUR TOUCHED PLACES specifically — 11/11 caught, control clean** — because a suite
    written before the layer you changed is not evidence about it; the pin-layer suite is 16/16.
    `check-place-candidates.py` **NEAR 40 → 36**, falling by exactly the four pairs resolved, with
    **EXACT unchanged at 7**, so no coincident group was manufactured (all six are other sessions' or
    the Cube House pair the owner chose to keep); ⚠️ exit code read **directly, not through a pipe**.
    `seed_from_toursjson.py` clean at **262 / 2,292 / 2,664 / 91**. `Tours.json` **byte-stable under a
    Python re-dump** before and after editing; **`tours` and `makers` byte-identical to `main`**, exactly
    4 pins changed in exactly 4 fields each. All four place heroes live **200**.
  - ⚠️ **`main` moved mid-session** **four times** (#698, #699, #700 and #701 — the last two **after CI had already gone green**), so each time the catalogue edit was **redone the documented
    way — take `main`'s file and re-run the idempotent assembler, never hand-resolve a JSON conflict** —
    and every check above was re-run afterwards. ⚠️ **Nothing compiled — CI on
    [#702](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/702) is the authoritative validator.**


🟡 **OPEN — [#691](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/691) two place cards, and seven
slashes (branch `claude/tour-links-upload-vhsf8a`, session 134).** Owner: *"arthur ashe place page yes"*,
then *"make banyan tree mayakoba a place page"*. **Places 80 → 82.** Content only — no Swift, no SQL, no
gh-pages push, no build; the seed carries `places`, so it reaches Supabase on merge with **no owner SQL**.
  - **Both are pure additions and nothing moved** — `makers`, `tours` and `linkPins` byte-identical, both
    member groups already exactly coincident. **🔴 Arthur Ashe was hitting `HomeView.maxStackedPlacecards`
    with no headroom; a place collapses its members into one capsule pin, so the cap stops applying.**
  - **🔴 Both heroes are borrowed from a member and that is structural** — every member is a link pin with
    an empty gallery and a 5 km sweep found no third photograph of either site. **Do not go sourcing
    replacements.** ⚠️ **The renovation pin is excluded as a hero because it is a rendering, not a
    photograph** — it stays a member.
  - **✅ The seven `@nikola.matus` `images//` stop URLs are fixed in the second commit** — the catalogue now
    holds zero, and `--pins` goes **557 images with 7 phantom groups → 550 with none**. That closes the
    item CLAUDE.md had recorded as fixed when only its hero half was.
  - ⚠️ **Rebased onto `main` mid-session** after [#690](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/690)
    landed underneath it; `Tours.json` auto-merged cleanly and **every check was re-run afterwards** —
    mirror **0 errors / 2 pre-existing warnings** over 1,552 tours + 565 pins + 82 places, seed clean at
    **226 / 2,117 / 2,489 / 82**. ⚠️ **Both sessions numbered themselves 133**; theirs was already on
    `main`, so this one is renumbered **134** and its handoff is `archive/HANDOFF-260901-4.md`.
  - **Still owed to the owner, none blocking:** three EXACT groups remain (**Grove at Grand Bay** ×3,
    **Bellevue (William O. Lockridge) Library** ×2, **Vancouver House** ×2), each a real place candidate;
    and the five weak heroes from #689 are unchanged.

🟢 **MERGED — [#690](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/690) eleven link pins from Joshua Charow**
(squash `34cae196`; linkPins 554 → 565, makers 224 → 226). Verified live rather than on the
workflow's success line: the **Supabase RPC serves all 11 pins and both maker rows, 0 pins wrongly
inside `tours`**, and the gh-pages mirror converged byte-identical after ~3 min of CDN lag.
**✅ Both questions it raised are CLOSED by the owner — do not re-raise either:**
  - **The same reel ships as TWO pins** (the Bedi Makky foundry and the Charging Bull) — *"IT'S FINE
    THERE ARE 2 OF THE SAME REELS AT DIFFERENT LOCAITONS"*. ⚠️ The Bull pin's photograph is a foundry
    in Greenpoint; **that is the accepted cost, not an oversight**, and an open-every-hero audit will
    flag it again.
  - **The Charging Bull is now a place** and **the Textile Conservation Lab is the cathedral place's
    fifth member** — [#693](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/693), on owner
    instruction. **Places 82 → 83.**

🟡 **OPEN — Riverside Church becomes a place, and its Atlas tour stops firing on Broadway
(branch `claude/place-riverside-church`, session 134c).** Owner: *"i have a new 'place' to report.
riverside church"*. **Places 86 → 87.** Content only — no Swift, no SQL, no gh-pages push, no build.
  - **🔴 The Atlas tour's coordinate was wrong and it is GEOFENCED, so it could never fire at its own
    subject.** It sat on **3019 Broadway, 243 m from the church** and outside its polygon, while its own
    script opens *"You're on Riverside Drive at 120th Street, outside Riverside Church"* — not a
    deliberate vantage, simply wrong (the Chelsea Hotel / Leighton House shape). Anchored now on the
    church's own OSM polygon centroid, which **reverse-verifies by name**.
  - **🔴 Radius re-derived, not inherited: 60 → 100 m**, covering the building (61 m), the Riverside
    Drive pavement (74 m) and West 120th (93 m). **0 other geofenced markers within 500 m.**
  - ✅ **The hero is a third photograph** from the tour's own gallery — nothing sourced, neither
    member's hero. All six candidates rendered and looked at.
  - **🔴 A gap in the Python validator mirror was found and fixed: it checked no enum domains at all**,
    leaving it blind to the `triggerMode: "geofence"` class that once reached 18 tours. Now parsed from
    the Swift, refusing a short parse; **11/12 → 12/12**, still 0 errors on the real catalogue.

🟢 **MERGED — [#694](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/694) the last three place cards, and
a sourced Windsor hero (squash `41a667d4`, session 134).** ✅ **Verified live, not on the merge line:** the
squash actually changed files (6 files, 369 insertions), and the **Supabase RPC — the source the app reads
first — now serves 86 places** with all three present and their members resolving, the Windsor hero repointed
to `windsor-castle_hero.webp`, and the session-99 dropped-key check clean (`priceTier` on all 1,553 with 66
priced, `isPrivate` on all makers, `country` and `videoRole` intact, **0 link pins wrongly inside `tours`**).
The gh-pages mirror converged at 86 and all four place heroes return **200**. Owner: *"do the other 3
place pages"*, then *"SOURCE A HERO FOR WINDSOR CASTLE"*. **Places 83 → 86.** Content only — no Swift, no
SQL, no build; the seed carries `places`, so it reaches Supabase on merge with **no owner SQL**.
  - 🎉 **`check-place-candidates.py` reaches ZERO exact groups and exits 0** — the clean state last held
    before #674. **The place backlog is empty, and a clean exit is the expected state again: treat any
    future EXACT group as a real finding.**
  - Built **Grove at Grand Bay** (Miami, 3 pins) · **Bellevue (William O. Lockridge) Library** (Washington,
    2) · **Vancouver House** (Vancouver, 2). All **pure additions with nothing moved**. ✅ **Every
    coordinate reverse-geocodes to its subject by name**, so no polygon test was needed anywhere.
  - ⚠️ **`main` moved mid-session** (#693 made The Charging Bull a place), so the catalogue edit was
    **redone the documented way — take `main`'s file and re-run the idempotent assembler** — and every
    check re-run: mirror **0 errors / 2 pre-existing warnings** over 1,552 tours + 565 pins + 86 places,
    **11/11** injected place faults caught, seed clean at **226 / 2,117 / 2,489 / 86**, diff still
    **47 insertions / 1 deletion** with `tours`/`linkPins`/`makers` byte-identical to `main`.
  - ⚠️ **The Ribbon is a member of Grove at Grand Bay, not a place of its own** — its caption places it
    *"within the site"* (the Arab Hall shape, not the Beauchamp Tower exclusion). One line reverses it.
  - ✅ **Windsor Castle's borrowed hero is replaced with a sourced CC0 photograph of the Round Tower**,
    closing the item that had sat in this section since #679. **No CREDITS row is owed** (CC0), and the
    source is natively 4:3 so nothing is cropped or upscaled.
  - ⚠️ **One hero trade-off stated rather than hidden:** Vancouver House takes the people-free facade over
    the frame that shows the building's famous twist, because two identifiable presenters fill that one's
    bottom third. **One line swaps it.**
  - **⏸️ DEFERRED BY THE OWNER, 2026-09-01: *"for now i'm fine with the things you flagged."*** The
    **five weak heroes** from #689 — the Grand Central Stones (an elevated subway platform rather than
    the thirteen monoliths) sharpest among them, plus Banyan `@everythingeryn`, 150 N Riverside, 87th
    Street and Xcaret — and the **Vancouver House hero trade-off** (the people-free facade was taken
    over the frame showing the building's famous twist, which carries two identifiable presenters in
    its bottom third; one line swaps it). ⚠️ **"For now" is a deferral, not a decision** — unlike the
    Ministry of Enterprise and Casa Lleó Morera heroes, which the owner settled outright, these are
    still open questions. **Do not re-raise them as fresh findings** (they have been through the
    open-every-hero audit and were put to the owner), and equally **do not treat them as closed** or
    quietly source replacements. A link pin re-hosts only its thumbnail, so for each one the real
    choice remains keep or pull.

🟢 **MERGED — THE THREE PLACE/NHM ITEMS THAT SAT HERE ARE ALL ON `main`.**
[#676](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/676) ten Tier 1 place cards (places
56 → 66) · [#679](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/679) nine Tier 2 cards plus
Gracie Mansion (66 → 76, and `check-place-candidates.py` reaches **0 EXACT**) ·
[#680](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/680) the London Natural History Museum
playing Los Angeles' narration. Their stories live in `CLAUDE.md` § Current State.
  - **✅ WINDSOR CASTLE IS FIXED (session 134, [#694](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/694)).**
    It had **no picture of the castle at all** among its members (an armour, three portraits, a drawing
    room and a postbox), so its place hero was the weakest of the borrowed ones; it now carries a
    sourced CC0 photograph of the Round Tower. **One owner decision remains and blocks nothing:**
    **The Charles Dickens Museum** ships `heroImageURL: null` deliberately (the
    field is optional and falls back to the top-ranked tour's hero) because that tour's only spare
    image is a 19th-century engraving.

🟢 **MERGED (re-derived 2026-09-01: only #691 and #692 are open) — THE TWO CHECKS THAT COULD HAVE CAUGHT THE NATURAL HISTORY MUSEUM
(branch `claude/shared-url-checks`).** Owner: *"add the two missing checks"*. Tooling only —
`scripts/check-image-duplicates.py`, **255 insertions / 0 deletions**; no catalogue, Swift, SQL or
build change. **Auto-merge class** (`scripts/` does not ship in the app).
  - **🔴 The byte checker was blind to this by construction:** it compares two DIFFERENT urls
    holding the same bytes, while the NHM case is two entries pointing at the SAME url — **one file
    hashed once is one file, so it never forms a group** — and nothing anywhere touched `audioURL`.
  - Shared **`audioURL` = ERROR**; **one-source-post link pins = INFO** (the `@malata.antwerp` case,
    checked **before** the city rule because those pins are legitimately in five cities); **holders
    in two cities = ERROR**; **any `multiStop` holder = INFO**; otherwise ERROR.
  - **🔴 Deliberately NOT scoped by `--maker`/`--pins`** — the NHM collision spanned two cities and
    two makers, so any convenient scope hides the bug it exists to find. Costs nothing: no network.
  - **9 injected fault classes, 9/9 caught.** ⚠️ **The two wiring faults were MISSED first time —
    `--selftest` exits before `main()`'s body runs**, so neutering the call site is invisible to
    every logic case; the selftest now reads `inspect.getsource(main)` and asserts the wiring.
  - **Regression proof:** over `521bbb5b` it reports **8 errors** (seven images + the shared
    `natural-history-museum.mp3`); against the current catalogue **0 errors, 207 documented reuses**.

🟢 **MERGED — NINETY-FIVE LINK PINS FROM ALICE LOXTON, DOMUS AND ROME ART STORIES
([#674](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/674), merged 12:01 UTC).**
**linkPins 283 → 378 · makers 206 → 208; tours (1,552) and places (56) unchanged.** Content only.
  - **⚠️ Owner decision available, not blocking:** whether any of the ten EXACT same-subject pairs
    the owner sent twice should become places (Harvington Hall ×2, Hatfield + the Elizabeth Oak,
    Syon Park ×2, York Minster + Roman York, **Windsor Castle ×3**, Hampton Court ×2, Hever ×2, the
    National Gallery ×2, Leighton + the Arab Hall) plus **CaixaForum Madrid**, where the Domus pin
    lands on the existing Atlas tour. **Flagged, not created.**
  - **⚠️ One weak hero flagged, not fixed:** *Windsor Castle #88* is a **postbox**. Its caption is
    "Historic delights of Windsor Castle!" and Windsor does have a famous Victorian wall postbox, but
    on the map it reads as a generic red box. One line removes the pin if the owner prefers.
  - **🔴 A failure class worth knowing before the next batch:** 13 posts answered their oEmbed
    thumbnail with **52 bytes of `{"code":5009,"error":"fail to make process filters"}`** — not a
    dead post, not transient, and per-object rather than per-host. **The fix is the same post's
    `originCover` (`tplv-tiktokx-origin`)**, fed through the tool's own `best_thumbnail`. 13/13
    recovered. **If it recurs, fold the fallback into `make-link-pin.py` itself.**

🟢 **MERGED — SEVEN PLACE CARDS FROM AN AUDIT, AND `check-place-candidates.py` REACHES ZERO
([#673](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/673)).**
**places 49 → 56; tours (1,552), link pins (283) and makers (206) byte-for-byte unchanged.** Built:
**Casa Milà — La Pedrera**, **Operaparken**, **Wave Hill**, **Grand Central Terminal**,
**Chichén Itzá**, **Rosewood Mayakoba**, **Casa Lleó Morera**. The pin moved and the tour never did.
  - 🔴 **EXACT reached zero and the script exited 0 for the first time in its history** at that
    point. **CLAUDE.md's standing note that a clean exit is NOT the expected state is corrected in
    place** — treat any future EXACT group as a real finding. ⚠️ The two batches above have since
    taken it to 11; those are same-subject pairs the owner sent twice, not a regression.
  - 🔴 **The checker cannot see every candidate.** Its NEAR tier matches on title containment, so
    *The South Facade of Grand Central* and *Grand Central Terminal* never pair — run it **and** a
    hand sweep (every pair within 40 m, plus every pair within 200 m sharing a distinctive word).
  - ⚠️ **Two heroes are BORROWED from a member** (Chichén Itzá, Rosewood Mayakoba) — both are
    pin-only sites with empty galleries, so no third photograph exists. The Waterlooplein case,
    already closed by the owner: **do not go sourcing a replacement.**
  - ⚠️ **The Great Ball Court is deliberately excluded** from the Chichén Itzá place and stays its
    own pin 224 m away. **Do not "complete" it.**
  - **Still flagged, not built:** Monestir de Montserrat (31 m), Tribune Tower (142 m), Petit Palais
    (276 m), Walt Disney World Swan + Dolphin (216 m). **There is no Grand Palais candidate** — it
    has one entry in the catalogue and the pin beside it is the Petit Palais, 155 m away.

🟢 **MERGED — SEVEN `@nikola.matus` PINS, THE CHELSEA HOTEL COORDINATE, AND THE CHELSEA PLACE
([#668](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/668) `a997860a`, plus the place PR).**
**linkPins 276 → 283 · makers 205 → 206 · places 48 → 49 · tours unchanged at 1,552.** CI green on
all three jobs; verified live against the Supabase RPC **and** the gh-pages mirror, both serving
283 pins with **0 pins wrongly inside `tours`**, and `priceTier` / `isPrivate` / `country` all
intact. ⚠️ The mirror lagged Supabase by **~8 minutes** — a mirror read taken straight after a
merge will lie to you.
  - ✅ **The Atlas `The Chelsea Hotel` tour could never fire and is fixed.** It sat **290 m** from
    the hotel behind a **60 m** geofence, while its own script says *"outside the Chelsea Hotel"*.
    Stop 0 and the centroid now sit on `40.7443742, -73.9968175` (`Hotel Chelsea, 222, West 23rd
    Street`). **Radius re-derived and kept at 60 m; 0 other geofenced markers within 500 m.**
  - ✅ **The Chelsea Hotel is now a place** (owner: *"make it a place"*), **places 48 → 49**,
    `check-place-candidates.py` **4 EXACT → 3**. **Nothing moved to make it** — the pair became
    coincident when the tour was corrected. **Hero is a third photograph** from the tour's own
    gallery; place + both members are three distinct pictures. No owner SQL.
  - ⚠️ **7 of 7 pins will not play inline** — the licensed-music rights gate, `video_url` absent
    from every embed. Correct behaviour, but the first batch where a creator's *entire* output is
    withheld; **whether to keep them is a curation call.**
  - ⚠️ **Two heroes are portraits of a person rather than a place** (Marilyn Monroe, Edie
    Sedgwick). Not wrong, but they render as a face on the map; no other frame exists.

🟢 **MERGED — GLASSHOUSE THEATRE BECOMES A PLACE
([#663](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/663), `claude/tour-links-upload-3bqlib`,
restarted off `main` after #659 merged).** Owner: *"make place card for glasshouse theater."* The two
coincident pins from #659 become one place; **places 44 → 45**, `check-place-candidates.py` **4 EXACT
→ 3**. **Nothing moved** — both pins were already on the identical coordinate, so the exact-coordinate
identity rule held with no pin relocated. **🔴 The hero is BORROWED from the interior pin because no
third photograph exists**: the venue opened March 2026 and every Commons image of it is CC BY-SA 4.0,
off-policy while the app has no attribution UI. **The Hotel Casa del Mar case — do not go sourcing a
replacement.** Content only; the seed carries `places`, so **no owner SQL**.


✅ **MERGED — FOURTEEN LINK PINS + THE CHECKER THAT CRIED WOLF
([#659](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/659), squash `e21b4fd5`), AND ALL
FOURTEEN ARE LIVE.** Verified against the **live sources**, not the workflow's success line: the
Supabase RPC (what the app reads first) and the gh-pages mirror each serve **256 link pins**, with
**0 pins wrongly inside `tours`** and `priceTier` / `isPrivate` both intact.

✅ **MERGED — FOURTEEN LINK PINS + THE CHECKER THAT CRIED WOLF
([#659](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/659), `claude/tour-links-upload-3bqlib`).**
Fourteen links from the owner — 13 TikToks + 1 Instagram reel, **all alive, nothing parked**.
**linkPins 242 → 256 · makers 188 → 191 · New Zealand the 37th country** (re-derived after [#658](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/658) merged under it; the PR body's 244 → 258 was measured against the older base). Then, on owner
instruction (*"fix the checker"*), the tooling half: **`check-image-duplicates.py` was hashing error
pages and caching them**, so two URLs failing the same way became a permanent false "duplicate" — it
reported two unrelated pins as byte-identical when they are not. `download()` now reads the status
code (a 200 is the only success), `looks_like_image()` gates the hasher, nothing failing either is
cached, and the cache dir moved to `.cache/image-dupes-v2/` because a poisoned entry is
indistinguishable from a good one. **Content + tooling + docs, no Swift — auto-merge on green.**
⚠️ **`Diminish and Ascend` is pinned at Christchurch though its thumbnail shows Waiheke — owner
decided: *"keep christchurch."* Settled; do not "fix" it.**


✅ **MERGED — LA CLEANUP: TWO DUPLICATE PINS PULLED, FOUR LA PLACES BUILT
([#658](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/658), squash `2a222899`), AND ITS SQL
HAS BEEN RUN.**
Owner instructions: remove one of the two Hotel Casa del Mar pins and its place page, take out the
YouTube Castle Green, then *"make bradbury, griffith and union station places. make petersen also a
place, and go with your recommended coordinate."* **linkPins 244 → 242 · makers 189 → 188 · places
41 → 40 → 44 · tours unchanged at 1,552.** Content + one SQL file; no Swift, no build.
**✅ `backend/pull_la_duplicates_260830.sql` HAS BEEN RUN (owner, 2026-08-30) and nothing is owed** —
re-read from the **live RPC** rather than the SQL Editor's success line: all four deleted rows gone,
all three survivors present, `TikTok @thedesigndetourist` still at 19 pins, 0 pins wrongly inside
`tours`, `priceTier` (66 priced) and `isPrivate` both intact. **The four places needed no SQL** — the
seed carries them, so they arrived with the merge. **The pin moved and the tour did not — verified by diff: 0 Atlas tours changed a coordinate,
trigger mode or radius.** Every place hero is a **third photograph promoted from the member tour's
own gallery**, nothing sourced.

✅ **MERGED — THE DUPLICATE-IMAGE CHECKER HAD NEVER SEEN A LINK PIN
([#657](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/657), `claude/tour-links-upload-qeoxe7`),
squash `597b5aff`.**
Owner: *"do it now if it helps."* `scripts/check-image-duplicates.py` reads `catalog["tours"]` and
nothing else, so **all 244 link-pin heroes were invisible to it, `--all` included**, from the day
#597 split them into a sibling `linkPins` array. Measured before the fix: **`--all` saw 5,595 images
and 0 of the 240 pin heroes.** Tooling + docs only — no catalogue change, no Swift, no SQL — so this
is the **auto-merge class**: merge on green, no owner gate. ⚠️ **The catalogue is clean, and that is
now measured** (5,835 images, 0 errors, 27 INFO, 0 fetch failures) rather than assumed — my first
description of this to the owner called it a convenience gap and said nothing was wrong because of
it, which was not something I had checked. Adds **`--pins`**; **`--maker <CODE>` stays tours-only
deliberately**, because pinned handles collide with city codes as substrings (`STO` matches
`@urbanstoriesyt`; 31 collisions catalogue-wide).


✅ **MERGED — FIVE ARCHITECTS JOIN THE VOCABULARY
([#654](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/654), squash `f93321b6`).** `Moshe
Safdie` · `John Augustus Roebling` · `William Henry Barlow` · `KieranTimberlake` · `José Ignacio
Linazasoro`. **⚠️ IT MERGED *AFTER* THE PORTMAN PR ([#655](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/655), `0086a212`) THOUGH IT WAS BRANCHED BEFORE IT** — the case where one
session's vocabulary edit silently reverts another's. **Checked rather than assumed, on `main`:
Portman survived, 330 + 5 = 335 architects / 385 tags, and the two copies of the vocabulary agree
exactly** (`Models/Tag.swift` and `scripts/validate-tours.swift` — a mismatch produces an error per
tagged entry). Validator mirror: **0 errors, 2 warnings across 1,552 tours + 244 pins + 41 places**,
both pre-existing; **0 unused names**, and **0 of the 497 named-architect entries missing `Designed
by a Master`**. ⚠️ **Still never compiled or seen in a simulator** — it is a `Models/Tag.swift`
change and CI's build is the only check it has had.

🔴 **OPEN, NEEDS AN OWNER DECISION — `MoMA PS1` SHIPS A DEAD HERO IMAGE.** Its
`heroImageURL` returns a hard **404**, confirmed across seven spaced attempts against four
same-host controls that all return 200, so it is not the rate limiting that hid it. **The tour has
no gallery**, so there is nothing to promote in its place (the Castello / DuSable free fix does not
apply) — a replacement has to be sourced through the image pipeline, which means owner picks.
**⚠️ It is the ONLY `upload.wikimedia.org/wikipedia/en/` URL in the catalogue** — an English
Wikipedia *local* upload rather than a Commons file, which is where non-free/fair-use images live
and where deletion is routine. Everything else Wikimedia-hosted is on Commons and healthy. **One
dead image in 5,848**, found only because #659's fetch fix stopped error-page bodies being hashed
as though they were pictures.

✅ **THE `@nycunfilteredstories` REMOVAL SQL HAS BEEN RUN (2026-08-30).** Owner applied
`backend/pull_nycunfilteredstories.sql`; verified against the live RPC — all four pins and both
creator rows gone, 0 pins wrongly inside `tours`. **Nothing owed; do not ask again.**

✅ **THE LINK-PIN FULLSCREEN BUG IS FIXED, SHIPPED AND OWNER-VERIFIED.**
[#622](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/622) squash `e22dba7`, **build 134 from
`main`**. Owner on the probe build carrying the same fix: *"133 is live. that seem to be done the
trick."* **Nothing is open from this work; the story moves to `CLAUDE.md` § Current State.**

- **🔴 IT TOOK FOUR BUILDS AND THREE WRONG DIAGNOSES, and this board carried two of them as fact.**
  #611 (build 129) and #617 (build 130) both shipped as "the fix" and neither was. **TikTok and
  YouTube embeds do not use WebKit element fullscreen at all** — the video takes its **own
  `UIWindow`**, at or below `.normal + 1`, which is where the module window lives. `fullscreenState`
  never changed, so nothing ever fired. **Never record a fix as verified on the strength of a merge.**
- **⚠️ The probe branch `claude/link-fullscreen-probe` is still on the remote and was never merged**
  — builds 131/132/133 came from it. **Owner must delete it in the GitHub UI**; the git proxy blocks
  branch deletion from a session. `grep TEMP-PROBE` on `main` is clean.

✅ **NINETEEN LINK PINS MERGED, ONE PULLED, AND THE PULL SQL IS APPLIED.**
[#638](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/638) squash `ce6ec46b` ·
[#641](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/641) squash `2f84df52` ·
[#642](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/642) (scratch files that rode in on a
`git add -A`). **This batch took linkPins 150 → 169 → 168 and makers 153 → 154.**

⚠️ **A PARALLEL SESSION'S [#640](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/640) LANDED
MINUTES LATER** (*"Thirty-two link pins, and the stack cap that demanded a place"*, squash
`cd32e293`), so read the counts above as **this batch's deltas, not the catalogue's totals**.
That session then closed itself out with two more merges — [#646](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/646)
squash `f172f07b` (**Jefferson Market Garden**, the one link it had parked for want of an
identifiable subject, wired on the owner's *"pretty sure it's jefferson market garden"*) and
[#647](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/647) squash `cec3aa39` (docs).

**`main` now carries 201 link pins · 184 makers · 38 places.** Pins and places were re-derived
from the **live Supabase RPC** after the last merge (201 · 38, confirmed); the maker figure is the
**catalogue's**, because ⚠️ **the RPC reports 194** — upsert-only accumulation plus real sign-ups,
long-standing and expected. **Assert on link-pin counts, not maker totals.** Both branches
auto-deleted. Its story is in
`CLAUDE.md` § Current State and `archive/HANDOFF-260829-2.md`. **Open PRs: [#657](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/657) (tooling, auto-merge class) plus the architect-vocabulary PR above.**

- **✅ THE SWAN & DOLPHIN HERO IS SETTLED — the owner keeps it** (*"i'm fine with the swan dolphin
  hero"*, 2026-08-29). Its YouTube thumbnail is a dark, indecipherable frame and **no better one
  exists** — `maxresdefault` and `sddefault` both 404 on that upload. **A hero audit will flag it
  again; it is closed**, like the Royal Hospital Chelsea and Ministry of Enterprise heroes above.
- **⚠️ Two of the thirty-five links are dead at the source and cannot be recovered from this end** —
  each returns a ~215 KB embed shell with no owner blob on six spaced fetches, against ~257–262 KB
  with one for a live post. **Only the owner re-sharing live links fixes those.**

- **✅ `backend/pull_pins_260829.sql` HAS BEEN RUN and verified against the live RPC** — `linkPins`
  **168**, all five pins gone (the Instagram Zacherlhaus plus the four from 2026-08-28 that had
  never been removed from Postgres), both pulled creator rows gone, `places` still 37 and
  `priceTier` still on all 1,553 with 66 priced. **Nothing is owed on the backend.**
- **✅ THE LAST OWNER CALL IS CLOSED: the Royal Hospital Chelsea hero stays** — *"keep chelsea,
  i'm fine with it"* (2026-08-29), though its thumbnail is a podcast talking head with no view of
  the building. **A hero audit will flag it again; it is settled.** Nothing from this work is open.

✅ **COPENHAGEN AND THE DANISH ARCHITECTS BOTH MERGED AND VERIFIED LIVE (2026-08-26).**
[#615](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/615) squash `1e966661` ·
[#616](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/616) squash `5196e459`. Both branches
auto-deleted. **Nothing is open from this work and nothing is owed on the backend** — the story
moves to `CLAUDE.md` § Current State, per this file's own rule.

- **Verified against the LIVE RPC, not the merge:** Atlas Studio CPH 🇩🇰 serving all 40 tours,
  `country: Denmark` on 40, `places` still 27 and `priceTier` still emitted (no keys dropped).
  Architect tags landed too — `Henning Larsen` 0 → 2, `Designed by a Master` 449 → 466. The
  gh-pages mirror converged about seven minutes after Supabase.
- **⚠️ OWED — no simulator or device review of #616.** Owner approved the merge without one. The
  visible effect is 24 new architect names as filter chips and 21 tours joining the
  "Designed by a master" shelf; no layout change, and CI's simulator build + unit tests were green.
- **🔴 STILL UNRESOLVED: an ATLANTA batch is staged on gh-pages with no tracker row.** gh-pages
  `c533f3c4` (2026-08-24) pushed 41 Atlanta images while `drafts/AUDIO-PENDING-SURVEY.md` said the
  queue was empty. Flagged in the tracker; **whether scripts exist, and on which branch, was never
  established.** Do not report the queue empty without re-deriving.

---

## 1b. Earlier board state (link pins)

**Eight PRs merged between 01:22 and 03:10. Zero are open.** The link-pin feature went from four
throwaway test pins to real content in under two hours.

✅ **BUILD 117 IS UP, FROM `main` AT `2a47e28`** — the tip itself, succeeded 03:33 with notes
attached. It carries #592 (the WALK pill below the metadata), which was the only merged app code not
in a build. **Nothing is stranded and nothing is open except the board PR below.**

🟡 **[#596](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/596) OPEN — this board, the contract
check and `restore_catalog_keys.sql` finally reach `main`.** All three had only ever existed on
`claude/project-tracking-dashboard-1kggmu`, so `CLAUDE.md`'s own session-start ritual
(`git show origin/main:STATUS.md`) has been 404ing for every parallel session. **Additive only: 5
files, +614, −0.** The branch was 41 commits behind, so `main` was merged in first and both conflicts
(`CLAUDE.md`, `backend/schema.sql`) resolved toward `main` — `schema.sql`'s newer warning is strictly
better, and rules 10/11 plus the 2026-08-20 block were re-added surgically.

✅ **THE TEST CREATORS ARE GONE — 49 makers → 45, verified against the live RPC.** Exactly the seven
real sign-ups remain, every one carrying a `user_id`. Places still 25, contract check passes.

**🔴 IT TOOK THREE PASTES, AND THE REASON IS WORTH KEEPING. THE TEST TOURS WERE TAKEN DOWN, NOT
DELETED.** Each of the four creators still owned one tour at `status = 'taken_down'` —
`takedown_tour()`, run in an earlier session. **A taken-down tour is invisible to every ordinary
read:** `get_catalog` serves published only, and so does the RLS policy behind PostgREST. So the
catalogue reported those creators had no tours, a direct API read agreed, and **both were wrong**.
Only a query run as `postgres` saw them.

- **⚠️ DURABLE RULE: anything reasoning about "does this maker have tours" must query the table as
  `postgres`.** Otherwise it is reading a filtered view and will conclude the exact opposite of the
  truth. The same applies to any tour count, any orphan check, any cleanup script.
- **⚠️ AND THE GUARD MADE IT INVISIBLE — the sharper lesson.** The first version's maker delete
  carried `not exists (select 1 from tours …)`, which the hidden rows failed, so the statement matched
  zero rows and reported *"Success. No rows returned."* **`tours.maker_id` is `on delete restrict`**,
  so without that guard Postgres would have raised a foreign-key violation naming the exact blocking
  row, and the answer would have arrived on the first paste. **A guard that turns a loud, specific
  error into silence is worse than no guard.**
- **⚠️ It could not be one statement:** `restrict` fires the moment the parent row goes, even when the
  child is being deleted alongside it. Tours first, then makers. `purchases.tour_id` is also
  `restrict`, so a tour that had ever been bought would raise rather than destroy the record of a sale.
- **The wider debt is unchanged and still real:** `seed_from_toursjson.py` is upsert-only, so nothing
  ever leaves the live database on its own. Every future removal needs a hand-written delete like
  this one. Worth fixing properly before launch.

## 1c. ✅ RESOLVED — build 66 can read the catalogue again

**Both fixes merged and are LIVE. Verified against both sources, not the PR descriptions.**

| | `tours` | `linkPins` | Build 66 decodes? |
|---|---|---|---|
| gh-pages mirror | 1,512, only `single`/`multiStop` | 4 | ✅ all of it |
| Supabase RPC | 1,513, only `single`/`multiStop` | 4 | ✅ all of it |

Top-level keys on both: `linkPins`, `makers`, `places`, `tours`. **Zero unfamiliar kinds inside
`tours`** — which is the whole test. Build 66 now catches up to the full catalogue on first launch
rather than freezing at its 1,350-tour August seed.

- **[#597](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/597)** — link pins move out of `tours`
  into their own top-level array, carried consistently through `Tours.json`, the gh-pages mirror
  (`publish-catalog.yml`), `seed_from_toursjson.py` and `get_catalog` (`backend/split_link_pins.sql`).
  New `LegacyCatalogCompatibilityTests` pins the guarantee.
- **[#598](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/598)** — per-field tolerance plus a
  tolerant array, and it **counts what it drops** rather than swallowing silently.

**🔴 WHY THIS WORKED AT ALL, and the rule to keep:** an unknown top-level KEY is free; an unknown
VALUE in a known field is fatal. `ToursData` uses synthesised `Codable`, which ignores keys it does
not know. Proven on this app before it was relied on: `sourceURL`, `sourceAuthor`, `country`,
`videoURLs` and `videoRole` were all added over time with no shipped build noticing. Nothing ever
broke until a new *value* appeared inside a field builds already parsed.

**⚠️ Tolerance could not have fixed this and must not be mistaken for the fix.** It protects only
builds shipped after it; build 66 is strict and always will be. The separate section is the only
thing that rescues an already-shipped build. Keep both — different jobs.

✅ **BUILD 118 IS LIVE, FROM `main` AT `d80465b`** — the tip itself. It is the first build that reads
`linkPins`, so the four creator pins reappear after being absent from 116 and 117. **The one-build
lag is closed and nothing merged is stranded.**

⚠️ **118 changed HOW THE CATALOGUE IS READ, so ordinary browsing is the real test** — home map, a few
cities, a walk, the library. A decode regression would not look like a decode regression; it would
look like content quietly missing.

⚠️ **Build 66's release decision is now the owner's, unblocked.** It can be released safely, or
replaced with something current. It is still eight days and three cities behind in what it ships in
the box; it just no longer stays that way.

⚠️ **A cloud session cannot be messaged from a web session** — `ListAgents` does not reach it and
`SendMessage` fails. A session briefed on tolerance only had to be archived and replaced rather than
corrected. **Brief a spawned cloud session completely up front.**

## 1b. ✅ RESOLVED — the catalog regression, fixed and verified

**Owner ran `backend/restore_catalog_keys.sql` 2026-08-20, and has since confirmed on device that
the place pages and capsule pins are back.** Verified against the live RPC as well, not just the
success message:

| | Before | After |
|---|---|---|
| `places` | absent | **25** ✅ |
| `priceTier` | absent on 1419 tours | present on 1419, **66 priced** ✅ |
| `isPrivate` | absent on 39 makers | present on **39** ✅ |
| `country` | 1418 | **1418** — held ✅ |
| `videoURLs` · `userId` | intact | intact ✅ |

All 25 places carry ≥2 tours, so every one renders. **`country` holding is the specific proof that
mattered** — re-running `places_apply.sql` instead would have restored places and knocked country
back out, which is why the separate file existed.

**Cause, for the record:** `add_country.sql` rebuilt `get_catalog()` from `schema.sql`'s body —
correctly, by its own design — but `schema.sql` had never carried `places`, `priceTier` or
`isPrivate`, all added by later migrations. Nothing errored; all three are optional in Swift, so
the features silently stopped existing. **Not a code fault, and not build 91's.**

**Hardened, two ways.** `schema.sql` now carries both missing keys plus a 🔴 warning that the
function is wrapped in production and every later key must be added there too. And there is now a
check that runs whether or not anyone is paying attention:

**`scripts/check-catalog-contract.py`** — queries the live RPC and diffs its key set against the
Swift models. The expected keys are **parsed out of `Models/Tour.swift`, `Maker.swift` and
`Place.swift`**, never hardcoded, so adding a field starts requiring it on the next run with no
edit to the script. A hardcoded list would drift and quietly stop testing anything, which is the
exact class of bug it exists to catch.

**It works: its first run found a fourth missing key nobody knew about** — `tours[].createdAt`.
That one is **pre-existing, not a regression** (the RPC has never served it). `Place.ranked` sorts
NEWEST FIRST on it, so that rule has no dates to sort on and falls through to its tiebreaks.
⚠️ **Do not "fix" it by emitting `tours.created_at`** — that column is `default now()` and the seed
never carries the authored date, so it holds *seed* time; most of the catalog shares 2026-06-27,
the original bulk seed. It would look fixed and rank wrongly. The real fix is to make
`seed_from_toursjson.py` carry the authored `createdAt` first. Recorded in the script as a **known
gap**: printed as a warning every run, but not a failure — a check that always fails gets ignored,
and then it catches nothing.

## 1d. ✅ DOZENT IS LIVE ON THE APP STORE

**Owner-reported 2026-08-28: approved by Apple and published.** Submitted 2026-08-18 03:22 UTC as
version 1.1 on **build 66**, `releaseType` MANUAL, so the owner pressed Release themselves. Ten
days from submission to live. **This is the first public release; every prior build was TestFlight.**

⚠️ **Not machine-verified from this session** — a remote container has no App Store Connect key
(`~/Downloads/AuthKey_*.p8` lives on the owner's Mac), so `scripts/session-start.sh` skips the
check here. The owner is the primary source and outranks any document; a local session should
confirm the live version/state from the API before quoting numbers back.

**🔴 WHAT CHANGES NOW, AND IT CHANGES THE STAKES OF EVERY CONTENT MERGE.** Until today a bad
catalogue reached TestFlight testers. It now reaches **App Store users on build 66**, which is a
strict decoder frozen at 18 August:

- **Build 66 has no tolerance layer.** [#598](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/598)'s
  per-field fallbacks and tolerant array **only protect builds shipped after it**. On 66, one
  unfamiliar value inside a known field still fails the whole catalogue decode, silently, and the
  phone keeps its last good copy forever.
- **What saves it is [#597](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/597)** — link pins
  travel in their own `linkPins` array, which 66 ignores as an unknown key. **That split is now
  load-bearing for a shipped App Store build. Never put a `kind: "link"` row back inside `tours`.**
- **The three guards that enforce it must stay green**: `scripts/check-catalog-keys.py`,
  `publish-catalog.yml`'s mirror refusal, and `validate-tours.swift`.
- ⚠️ **Build 66 bundles 1,350 tours against 1,552 live** — it catches up on first launch from
  Supabase, which is exactly the path the split protects.

**Owed, and worth doing before the next release:** ship an update, because every fix since
18 August — the launch sequence, offline photographs, fullscreen video, the search rewrite, the
link-pin fullscreen fix — is **not** in what the public has.

**✅ THE UPDATE IS PREPPED (2026-08-31).** `fastlane/metadata/en-US/release_notes.txt` is written
(required for an update, impossible on a first release — which is why it had been deleted), the
description's stale counts are corrected and its two missing features added, and
`docs/launch-runbook.md` gained a **§ Shipping an update** with the two rules that only bite on an
update: What's New is mandatory, and the version must be new (**`MARKETING_VERSION` is 1.1.1**,
because Apple refuses builds against a released 1.1).

- **The build is ready: 137**, owner device-verified. Its app code was diffed against `main` and
  differs by **one comment block**; only its bundled seed is behind, which catches up on first
  launch. **No new build is needed.**
- **🔴 VERIFIED AGAINST BUILD 66'S OWN SOURCE, not assumed:** its `ToursData` decodes
  `{makers, tours}` only and the tree carries **no `Models/Place.swift`** — so **every one of the
  283 link pins and 49 place pages is invisible to the public today.** That is the split working as
  designed, and it makes both the headline of the release notes.
- **⚠️ Remaining steps are owner-only and outside the repo:** create the 1.1.1 version record, push
  the metadata, attach build 137, submit. § Shipping an update has them in order.

## 2. Blocked on owner — outside the repo

**🔴 A DEAD TIKTOK LINK NEEDS RE-SHARING (2026-08-27).** `https://www.tiktok.com/t/ZP8vkb5bP/`, the twentieth of the "SF Architecture" batch, resolves to a real id (`@aggie.sanfrancisco/video/7660328152421387534`) and then fails everywhere: an empty oEmbed shell on three spaced attempts (no `thumbnail_url`), and a 367 KB *"Video currently unavailable"* page with zero `og:` tags. No caption means no subject and no location; no thumbnail means no hero, and a pin with no hero cannot ship. **Nothing on our side recovers it — only the owner re-sharing a live link.** ⚠️ It is an ordinary `/video/` post that has gone, **not** a `/photo/` carousel; that limitation is separate and permanent.


Nothing here can be done from a session. Ordered by what blocks the most.

| Item | Why it matters | State |
|---|---|---|
| ~~**App Store 1.1 review**~~ | ✅ **APPROVED AND LIVE** — owner-reported 2026-08-28. Submitted 2026-08-18 03:22 UTC on build 66. See § 1d. | ✅ Done |
| **Stripe platform review** | Response submitted; account flagged under Restricted Businesses. | ❓ Awaiting Stripe reply |
| ~~**IAP tiers blocked**~~ | ✅ **ALL 14 ARE READY TO SUBMIT (owner, 2026-08-31)** — the nine that had sat in `MISSING_METADATA` since August, plus four new ones (**599 / 799 / 1299 / 1799**). SQL applied, products created, screenshots uploaded, all added for review. **They ride with the 1.1.1 submission.** Two findings, both now in the docs: **the review screenshot must be 1242×2208** (the 5.5″ size — 1320×2868 and 1290×2796 were both refused, and CLAUDE.md had the wrong value recorded), and **one image covers all fourteen** — Apple wants to see where the purchase appears, not what it costs, so the per-price screenshot rule was this project's own over-caution. | ✅ Done |
| **EU trader declaration** | App declared **non-trader** while selling IAP tiers into EU cities. Declaring trader publishes an address. | 🔴 Decision owed |
| **LLC vs sole proprietor** | Gates the Stripe payout path, and collapses the EU-trader and the AHWY/EHKY-initials trade-offs at once. | 🔴 Decision owed |

### SQL pastes owed (Supabase SQL Editor, project **Dozent**)

✅ **Applied:** `add_country.sql` (Countries row live) · `restore_catalog_keys.sql` (places, priceTier,
isPrivate restored 2026-08-20) · **`pull_la_duplicates_260830.sql` (owner ran it 2026-08-30 —
verified against the live RPC, not the SQL Editor's success line: all four deleted rows gone, all
three survivors present, `TikTok @thedesigndetourist` still at 19 pins, 0 pins wrongly inside
`tours`, `priceTier` and `isPrivate` both intact. **Nothing is owed here — do not ask again.**)**.

| File | Unlocks | Without it |
|---|---|---|
| `backend/saved_places.sql` | Saved places syncing across devices | Saving works, stays on one device |
| `backend/places_photos.sql` | Places serving their own photographs | Optional — the app is correct without it |

## 3. Builds — which run number carries what

🔴 **Build numbers are `github.run_number` and are SHARED across every branch.** Read them back
after dispatching; never promise one in advance. And a build carries its branch's **merge-base**,
not `main` — GitHub reports a PR's base as main's current tip, which is misleading.

| Build | Branch | Carries | Result |
|---|---|---|---|
| **141** | `bottom-module-missing-45z6ep` | The same fix at **1.1.2** (`e6570bdc`) — 140's payload plus the version bump | ✅ **owner-verified — *"BUILD IS LIVE. MERGE"*; #728 merged as `4da52445`** |
| 140 | `bottom-module-missing-45z6ep` | [#728](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/728) the bottom module was HIDDEN, not uninstalled, with `main` merged in (`b52315f8`) | 🔴 **rejected at upload — 1.1.1 is now APPROVED, so its train is closed** (90186 *"Invalid Pre-Release Train"* + 90062). ✅ **It compiled and signed cleanly** (`build_app` 219 s); only the upload step failed. **This is the documented per-release cost, and it is also the only signal a web session gets that 1.1.1 shipped** — a closed train means Apple approved it. Superseded by 141 |
| **138** | `map-expand-control` | [#671](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/671) the expand control on every inline map, `main` merged in (`e0799d8c`) | ✅ **owner-verified — *"LOOKS GOOD"*; #671 merged as `01c70f63`** |
| **137** | `instagram-player-fit` | #662 the Instagram crop + fullscreen scrubber, `main` merged in, **marketing version 1.1.1** | ✅ **owner-verified — *"works! thank you"*; #662 merged as `845f0d86`** |
| 136 | `instagram-player-fit` | Same code at **1.1** (`49ac5382`) | 🔴 **rejected at upload** — 1.1 is released, so Apple refuses the version string |
| **134** | **`main`** | #622 the real fullscreen fix — the video's own window (`e22dba7`) | ✅ **install this** |
| 133 | `link-fullscreen-probe` | Same fix + the temporary readout (`f6aaf78c`) | ✅ owner-verified — *"that seem to be done the trick"* |
| 132 | `link-fullscreen-probe` | `isElementFullscreenEnabled` theory + probe (`839d2296`) | 🔴 wrong theory — probe proved it |
| 131 | `link-fullscreen-probe` | The probe readout alone (`773727ae`) | ✅ diagnostic — this is what cracked it |
| 130 | **`main`** | #617 the `onDisappear` guard (`adbe3b94`) | 🔴 shipped as "the fix"; was not |
| 129 | **`main`** | #611 withdraw the module on `fullscreenState` (`8df37de8`) | 🔴 shipped as "the fix"; was not |
| 128 | **`main`** | Everything, from the tip (`43c9411a`) — functionally identical to 127 | ✅ superseded |
| 127 | `open-source-ai-integration-pxuxdh` | #605 search + map, merged as `43c9411` | ✅ superseded |
| 126 | `instagram-best-effort` | #606 Instagram, merged as `2ecb95a9` | ✅ owner-verified — superseded |
| 125 | `open-source-ai-integration-pxuxdh` | #605 search, branch caught up to `main` (`73364503`) | ✅ superseded |
| 124 | `open-source-ai-integration-pxuxdh` | Merged app code + #605's then-unmerged search work (`fc94f197`) | ✅ superseded |
| 123 | `open-source-ai-integration-pxuxdh` | Same work, earlier commit (`2f1784e9`) | ✅ superseded |
| 122 | **`main`** | #603 Instagram tap (`e106fd3e`) | ⚠️ carries the behaviour #604 withdrew |
| 121 | `new-task-i2k12e` | #601 list-page grid + sort (`33d2b0c4`) | ✅ owner-verified — *"121 went live. Looks good."* |
| 120 | `new-task-i2k12e` | #600 place-page grid + sort (`ad1ff15e`) | ✅ owner-verified — *"120 is live. works"* |
| 119 | `new-task-i2k12e` | Same work, one commit earlier (`8b4e6cdc`) | ✅ superseded |
| 118 | **`main`** | #597 link pins split out + #598 decode tolerance (`d80465b`) | ✅ superseded — owner-verified, pins visible |
| 117 | **`main`** | #592 WALK pill, on the real AMNH pins (`2a47e28`) | ✅ superseded — shows no link pins |
| 116 | **`main`** | #584 link pins + #585 YouTube/Short fixes (`233eb912`) | ✅ superseded — shows no link pins |
| 115 | **`main`** | #583 the stale hero fix (`8f5748b7`) | ✅ superseded — **un-frozen by #597** |
| 114 | **`main`** | Fullscreen video, Swedish architects, Akalla hero, `get_catalog` hardening (`8d2ad947`) | ✅ superseded |
| 113 | `chrome-row-modifier` | #576 chrome row extracted — head merged `main` at 13:14 (`e90d9995`) | ✅ superseded |
| 112 | `color-mismatch-elements-pj2ptt` | #573 chrome row made opaque | ✅ merged |
| 111 | **`main`** | #565 architects, #566 launch mark, #567 + #568 offline photographs (`891702fd`) | ✅ last true from-main build |
| 110 | **`main`** | Everything to 22 Aug, plus #563 light mode (`b421bde9`) | ✅ superseded |
| 109 | `launch-performance-animations-df4d7p` | #559 launch sequence (`52a86cfa`) | ✅ superseded by 110 |
| 108 | `launch-performance-animations-df4d7p` | Same work, one commit earlier | ⚠️ superseded |
| 98 | `wizard-comments-round2` | #558 wizard round two (`e0132c90`) | ✅ merged |
| 97 | `wizard-comments-round2` | Same work, one commit earlier | 🔴 **Live and installable, run shows RED, no notes** |
| 96 | `upload-wizard-improvements-ejopz3` | #552 the seven-step wizard | ✅ owner-verified — *"so much better"* |
| 95 | `ellipsis-button-consistency-vdorpi` | Became #555 — Liked on the shared list screen | ✅ merged |
| 94 | `ellipsis-button-consistency-vdorpi` | #553 list page as a layer | ✅ owner-verified, merged |
| 93 | `library-launch-jitter` | #549 Library launch jitter | ✅ merged |
| 91 | `main` | Wizard, Settings, list page, 5:4 heroes | ✅ owner-verified |
| 90 | `tour-upload-polish-qiliop` | #540 + the saved-tour hang fix | ✅ owner-verified — hang closed |

✅ **#552 merged `main` in before merging out** (`a9a3b32`, two real conflicts resolved by hand) — so
the stale-base warning this board carried against build 96 was dealt with by the session itself.


## 4. Branches

| Branch | State |
|---|---|
| `claude/tour-links-ds0387` | **Open as [#734](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/734)** — 33 Toronto + Mississauga link pins (commit `1a477971`), cut clean off `origin/main` `5763c137`. gh-pages `5308c563` carries its 33 heroes, **all hash-verified live against the uploaded bytes**. ⚠️ **gh-pages moved between the clone and the push** (`0b15aa4` → `a0cd018`, a parallel session's 17 heroes) — detected by re-reading `git ls-remote`, and the tree was **rebuilt on the current head rather than force-pushed**, with collisions re-checked against the new tree. |
| `claude/new-tour-links-cytwc6` | **Open as [#729](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/729)** — 61 `@archimarathon` link pins plus two places, cut off `origin/main`. gh-pages `317046a` carries its 61 heroes. |
| `claude/tour-links-26dmsx` | **Merged ([#701](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/701), squash `5fc747fb`)** — twenty-eight Chicago link pins; linkPins 712 → 740, makers 247 → 262. ⚠️ **`main` moved THREE times while it was in flight** (#698, #699, #700 — 147 pins, the last arriving after the PR was open), and the catalogue edit was **redone each time by re-running the idempotent assembler on `main`'s file**, never hand-resolved. 🔴 **That caught a real hazard: #699 created maker rows for two of this batch's creators, so new rows went 17 → 15** — uuid5 reproduced both ids exactly; a naive resolve would have emitted `duplicate maker id` twice. ⚠️ **Handoff renumbered twice, to `-10`** — `-7`, `-8` and `-9` were all claimed by parallel sessions on the same afternoon. Story in `CLAUDE.md` § Current State |
| `claude/tour-links-upload-tbcerj` | **This session, pushed, no PR** — twenty link pins (15 × `@breatheart_hk` Hong Kong). Cut off `origin/main` `05e90f47`, **rebased onto `00a420bd`** after #640 and three doc commits landed mid-session; catalogue edit redone by re-running the idempotent assembler against the new `main`, never hand-resolved. gh-pages `a8a81767` |
| `claude/tour-links-upload-wa3e0g` | Merged (#640, squash `cd32e293`) — 32 pins. ⚠️ **Its branch diff was 33 pins, not 32**: it carried the Instagram Zacherlhaus the owner pulled in #641. Flagged pre-merge; **checked after and the pull held** — only the TikTok Zacherlhaus is on `main` |
| `claude/tour-links-upload-qeoxe7` | **Merged as [#648](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/648); follow-up places PR open** — twenty-three link pins from three creators (18 TikToks `@thedesigndetourist`, 4 Instagram `@shaunbirley`, 1 `@meliluu__`); linkPins 168 → 191, makers 154 → 157. Content only, images live on gh-pages at `251cf95e`. **🔴 MERGE HAZARD, NOW THE OTHER SESSION'S: this branch created the `TikTok @thedesigndetourist` maker row (uuid5 `67CA14A6-…`) and a parallel session's unmerged branch creates the identical id — that branch must drop the duplicate or the validator errors.** ⚠️ Ships two subjects twice on one coordinate each (Westin Bonaventure, Hotel Casa del Mar) — deliberate, both links were sent; `check-place-candidates.py` therefore reports 3 EXACT groups against main's 1 |
| `claude/link-fullscreen-probe` | 🔴 **Never merged, still on the remote** — carried the temporary readout and builds 131/132/133. **Owner deletes it in the GitHub UI**; the git proxy blocks branch deletion from a session |
| `claude/link-fullscreen-window` | Merged (#622, squash `e22dba7`) — the real fullscreen fix |
| `claude/link-fullscreen-module-ojs556` | Merged (#617, squash `adbe3b94`) — the `onDisappear` guard. ⚠️ The designated branch name; the first attempt's work was actually on `claude/link-fullscreen-module` |
| `claude/link-fullscreen-module` | Merged (#611, squash `8df37de8`) |
| `claude/new-tour-links-nniny1` | Merged (#626, squash `303012b3`) — nineteen San Francisco architecture link pins. **Verified live on BOTH sources afterwards**, not on the merge: the RPC and the gh-pages mirror each serve 76 link pins with 0 wrongly inside `tours`, and `places` / `priceTier` / `isPrivate` all survived. ⚠️ Restarted from `origin/main` for this board update — never stacked on merged history |
| `claude/new-tour-links-yr5o7r` | **Open as [#627](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/627)** — ten "Atlanta Architecture" TikToks, **nine shipped as link pins; the tenth (Mercedes-Benz Stadium) pulled by the owner over a probably-AI hero**. Cut clean off `origin/main` `c5e8862`, then **merged `main` in to resolve a four-way conflict with #626** (both batches touched `Tours.json`, `CLAUDE.md`, `STATUS.md`, and both claimed `archive/HANDOFF-260827.md`). Content only. Images live on gh-pages at `a93c06d4`. |
| `claude/tiktok-orlando-links-ziegoe` | **Restarted from `origin/main` after #621 merged** — now carries the Orlando *architecture* batch (10 pins, commit `da9c96ad`). ⚠️ Same branch name, fresh history: never stacked on merged commits. |
| ~~`claude/tiktok-orlando-links-ziegoe` (first run)~~ | Merged as #621 (squash `1c05613b`) — nine Orlando link pins, live on Supabase |
| `claude/library-launch-jitter` | Merged (#549 at 03:52) — auto-delete should remove it |
| `claude/upload-wizard-improvements-ejopz3` | Merged (#552 at 19:05) |
| `claude/wizard-comments-round2` | Merged (#558) and deleted |
| `claude/launch-performance-animations-df4d7p` | Merged (#559 at 16:43) — built as 108/109 |
| `claude/milan-tours-upload` · `claude/milan-docs-260822` | Merged (#560, #561) |
| `claude/coordinate-guard` | Merged (#562 at 17:20) |
| link-pin branches (#584, #585, #586, #587) | All merged 20:59–22:51; auto-delete should remove them |
| `claude/link-pin-batch-workflow` | Merged (#588 at ~01:40) |
| link-pin follow-ups (#589–#595) | All merged 01:40–03:10 |
| `claude/ellipsis-button-consistency-vdorpi` | Merged twice from one branch (#553, #555). ⚠️ The second stacked on already-merged history, which CLAUDE.md says to avoid — it worked, but no PR existed while build 95 was installable |
| `claude/tour-upload-polish-qiliop` | Merged (#540) — auto-delete should remove it |
| `claude/stripe-questions-fjhdo3` | ⚠️ No PR — verify contents before deleting |
| `claude/amsterdam-handoff-preserve-hlhyp8` | 🔒 Keep — only copy of staging pick-maps |
| `claude/web-landing-site-preserve` | 🔒 Keep — only copy of the Next.js landing site |
| `claude/london-batch3-scripts-260616` · `claude/paris-scripts-260622` · `claude/dreamy-wozniak-tags-260612` | 🔒 Keep (documented archival) |

## 5. Content

**⚠️ Re-derived from `Tours.json` on the session-143 branch `claude/tour-links-ds0387`: 1,552 tours + **1,184** link pins, **328** maker rows, 3,108 stops, **114** places.** Newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**. ⚠️ **Not yet on `main`** (pushed, no PR).

**⚠️ Re-derived from `Tours.json` on the session-141 branch `claude/new-tour-links-cytwc6`: 1,552 tours + **1,047** link pins, 305 maker rows, 2,971 stops, **114** places.** Newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**. ⚠️ **Not yet on `main`** (pushed, no PR), and ⚠️ **`main` moved twice while this batch was being wired** (#722, #725), so the base itself is a moving target.

**⚠️ Re-derived from `Tours.json` on `main` at `613e23e7`: 1,552 tours + 905 link pins, 297 maker rows, 2,829 stops, 105 places.** Newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**.
  - ✅ **That gap is CLOSED** — `backend/pull_pins_260902.sql` has been run and the RPC now matches the catalogue pin-for-pin (§ 1). The reading below was taken while it was still outstanding. It also reports **1,553 tours and 311 makers** against 1,552 / 297 — the documented `Zxxx` test tour and upsert-only maker accumulation. **Assert on link-pin counts, never on maker totals.**

**⚠️ Re-derived from `Tours.json` on `main` at `b46e354c` (session 137, after [#712](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/712) merged): 1,552 tours + 846 link pins, 263 maker rows, 2,770 stops, 100 places.** This is the newest reading on this board — every count below it is an older snapshot, so **re-derive rather than quoting any of them**.
  - **The live Supabase RPC agrees**, and it is the source the app reads first: 846 `linkPins`, 0 wrongly inside `tours`, 100 places, `priceTier` on all 1,553 tours with 66 priced. ⚠️ **The RPC reports 1,553 tours and 275 makers against the catalogue's 1,552 / 263** — the documented `Zxxx` test tour and upsert-only maker accumulation. **Assert on link-pin counts, never on maker totals.**

**⚠️ Re-derived from `Tours.json` on 2026-09-02 (session 135c, open as **[#707](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/707)**): 1,552 tours + 740 link pins, 262 maker rows, 2,664 stops, **97 places**.** Branch `claude/tour-links-yg5yw2`, restarted off merged `main`. Owner: *"make both places"* — the last two coincident groups.
  - **✅ Cube House (Toronto) and Tribune Tower (Chicago) are places.** Both **pure additions**: nothing moved, both pairs already coincident, `makers`/`tours`/`linkPins` byte-identical.
  - 🎉 **`check-place-candidates.py` reaches 0 EXACT and exits 0** (main: 2 / 36), **NEAR unchanged at 36**. **The place backlog is EMPTY — treat any future EXACT group as a real finding.**
  - ⚠️ **The Atlas tour `The Wrigley Building & Tribune Tower` is 142 m away and correctly NOT a member** — which also closes the two-subject naming problem that pair has carried since #701.
  - 🔴 **The Cube House is slated for demolition** — Block Developments, permit filed, Von Wong to rebuild the material as public art. Heritage **listed, not designated**. The copy asserts no date and no claim it still stands. ⚠️ **Sources disagree on its designer**; neither reading is asserted.
  - ⚠️ **Both heroes borrowed by necessity** (pin-only sites, empty galleries, no Atlas tour to lend one) — count re-derived **26 of 97**. **Do not go sourcing replacements.**

**⚠️ Re-derived from `Tours.json` on 2026-09-01 (session 135b, on the base that carries #700): 1,552 tours + 740 link pins, 262 maker rows, 2,664 stops, **95 places**.** Branch `claude/tour-links-yg5yw2`, open as **[#703](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/703)** — all four checks green on `f5404260`. Restarted off merged `main`; five owner place decisions applied in one pass. ⚠️ **`main` moved a THIRD time mid-flight** — [#700](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/700) merged sixteen Hong Kong link pins and a maker row and collided **add/add on the handoff filename again**, so this session's second handoff renumbered **`-9` → `-10`**. `Tours.json` auto-merged cleanly (their change appends pins, mine edits `places` and two pin coordinates) and the result was **verified, not trusted**; every check re-run on the merged base.
  - **✅ Four new places** — **One Times Square**, **The Tin Building**, **Eastern State Penitentiary**, **Charles Scribner's Sons Building** — each two coincident pins the owner sent twice.
  - **✅ The Morgan Library place grows 3 → 5 members.** ⚠️ **The checker reported its two new pins as a FRESH EXACT group** because they sat 6.5 m off a place that already existed — build from the sweep, not the checker, or you create a second Morgan Library. **The pins moved onto the place, not the reverse** (2 edits vs 4; 6.5 m is the CalAcademy rounding artifact; both `manual`, so no geofence moved).
  - **✅ `check-place-candidates.py` 7 EXACT → 2, NEAR unchanged at 36** — falls by exactly the five groups resolved and gains nothing. ⚠️ **Both groups left are other sessions' and neither has been put to the owner: Toronto's Cube House pair ([#698](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/698)) and Chicago's Tribune Tower pair ([#701](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/701)).**
  - **✅ Eastern State has a SOURCED CC0 hero** (gh-pages `9252daff`), natively 4:3 so nothing is cropped and nothing upscaled; no CREDITS row. ⚠️ The other three borrow a member hero — borrowed-hero count **27 of 95**.
  - **🔴 STANDING OWNER POLICY: paid partnerships are NEVER raised again.** Do not flag `#morganpartner`, `#silversteinpartner`, `#marriottpartner`, ADs or `#Partner` on any future batch.
  - **✅ #77 Hart Island's talking-head hero STAYS** — settled; do not re-raise.


**⚠️ Re-derived from `Tours.json` on 2026-09-01 (session 135, this batch merged onto #698's Toronto pins): 1,552 tours + 696 link pins, 246 maker rows (34 Atlas studios + 212 pinned creators — 112 TikTok, 88 Instagram, 12 YouTube), 2,620 stops, **88 places**, 265 cities across 40 countries.** Branch `claude/tour-links-yg5yw2`, open as **[#699](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/699)**. ⚠️ **`main` moved AGAIN after the PR opened** — [#698](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/698) merged Toronto's first 25 link pins and 20 creator rows, conflicting in `Tours.json`, `CLAUDE.md` and — an **add/add** — on this session's own handoff filename. Resolved the documented way: **take `main`'s file and re-run the idempotent assembler**, never hand-resolve a JSON conflict; **0 overlap** with Toronto on sourceURL, ids or hero filenames. This handoff renumbered **`-7` → `-8`** (Toronto merged first and kept `-7`). On the merged base the batch reads **linkPins 590 → 696 · makers unchanged at 246 · places 87 → 88**, and every check was re-run: mirror **47/47** then **0 errors, 2 pre-existing warnings** across 1,552 tours + 696 pins + 88 places; place faults **14/14**; seed clean at **246 / 2,248 / 2,620 / 88**; `check-place-candidates.py` **1 EXACT / 25 NEAR → 6 / 33** — the one on `main` is Toronto's own, the five added are this batch's undecided groups, and **120 Broadway is absent because the place resolved it**. gh-pages `d6c1e75` carries its 106 heroes. **108 links → 106 distinct posts, every one TikTok `@hereinnyc`** — the largest batch to date, against a previous record of 105 — so **makers is unchanged**: the row already existed, uuid5 reproduced its id exactly, and the regenerated avatar was byte-identical to the live file and excluded rather than overwritten.
  - **🔴 A supplied Plus Code was wrong and only the hero says so.** "Holy Nail in Duomo" carries **the identical code as the post before it** (the *Volto Santo* in **Lucca**) while its frame is the **Milan Duomo roof** and its caption reads `#duomodimilano` — a 280 km error that decodes cleanly and reverse-geocodes to a real square. Corrected; it now sits 26 m from the existing `Duomo di Milano` tour.
  - **✅ 120 BROADWAY IS A PLACE — owner instruction, same session. Places 87 → 88, a pure addition; the cap no longer applies.** The rest of this bullet is why it was needed. **🔴 FOUR COINCIDENT PINS AT 120 BROADWAY AND THE MAKER-PAGE CAP IS THREE.** `HomeView.maxStackedPlacecards` is 4 (Home is fine, no headroom) but **`TourSetMap.maxStacked` is 3 and every pin in this batch is one creator**, so **one of the four is permanently unreachable on `@hereinnyc`'s own page**. Session 132 flagged Arthur Ashe as safe only because its four pins had four different makers — **that mitigation does not exist here.** No coordinates were manufactured to relieve it. **A place is the fix — ✅ built.**
  - **⚠️ `check-place-candidates.py` goes 0 EXACT / 21 NEAR → 6 / 29, then 5 / 29 once 120 Broadway became a place; it still exits 1**, ending the clean-exit state #694 restored. All six are sites the owner sent more than one link for — 120 Broadway ×4, the Morgan Library ×2 (**already a place with 3 members**, so these would be a 4th and 5th), the Tin Building ×2, Eastern State ×2, Scribner's ×2, and One Times Square (this batch's NYE Ball pin converging on the same OSM node as `@whatisthis_nyc`'s existing pin). **None was nudged together.**
  - **⚠️ Owner decisions owed:** the five other coincident groups; **#77 Hart Island's hero is a talking head** (keep or pull); and **four paid partnerships** — `#morganpartner` ×2, `#marriottpartner`, and `#silversteinpartner` on all four 120 Broadway posts (the Coca-Cola precedent says the owner may keep them).
  - ⚠️ **`main` moved mid-session** ([#697](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/697)), so the catalogue edit was redone on `main`'s file with the idempotent assembler and every check re-run. **Another session is staging Toronto link-pin heroes** (gh-pages `a506a5b6`, 25 subjects) — my push sat on top of theirs with **0 modifications**, so nothing was overwritten.

**⚠️ Re-derived from `Tours.json` on 2026-09-01 (session 132, this batch, NOT yet merged): 1,552 tours + 554 link pins, 224 maker rows (34 Atlas studios + 190 pinned creators — 111 TikTok, 67 Instagram, 12 YouTube), 2,478 stops, 80 places, 262 cities across 40 countries.** Branch `claude/tour-links-upload-vhsf8a`, **no PR opened** (the owner did not ask for one). gh-pages `19d7a985` carries its 29 images. **⚠️ `check-place-candidates.py` now exits 1 with 5 EXACT groups** — Arthur Ashe Stadium (**4 pins, exactly `HomeView.maxStackedPlacecards`, no headroom**), Grove at Grand Bay ×3, Bellevue/Lockridge Library ×2, Vancouver House ×2, Banyan Tree Mayakoba ×2. All five are subjects the owner sent more than one link for; none manufactured. **⚠️ Found, not fixed: session 125's `images//` correction was HALF APPLIED on the seven `@nikola.matus` pins** — `heroImageURL` is single-slashed, **`stops[0].imageURL` still carries the double**. Both forms serve 200, so it is not breakage, but **`check-image-duplicates.py --pins` reports seven phantom `INFO` groups on every run** because of it. Seven-line fix; deliberately left out of this batch's diff.

**⚠️ Re-derived from `Tours.json` on 2026-08-29 (session 122, after merging #640): 1,552 tours + 244 link pins, 189 maker rows (34 Atlas studios + 155 pinned creators — 98 TikTok, 44 Instagram, 13 YouTube), 1,924 tour stops, 38 places, 36 countries.** Twenty pins added on branch `claude/tour-links-upload-tbcerj`; **no PR opened** (harness forbids it unasked). **🔴 THREE LINK-PIN SESSIONS WERE IN FLIGHT SIMULTANEOUSLY ON NEAR-IDENTICAL BRANCH NAMES** (`…-tbcerj`, `…-wa3e0g`, plus a third pushing 23 heroes straight to gh-pages), so **deduping against `main` alone is no longer sufficient** — check the open PRs' branches too, and re-check after each merge. **⚠️ The Key-facts line written an hour earlier said 201 pins / 149 creators against a real 200 / 149, so not one session's own number has survived its merge.** **✅ Duddell Street Steps is now a place (places 38 → 39), built on owner instruction** from the Atlas tour and the new pin, which sat 9 m apart under the same name. ⚠️ **Neither member is geofenced**, so the pin moved on the CalAcademy rounding-artifact reasoning rather than the usual geofence one; the place hero is a **third** photograph promoted from the tour's own gallery; and **the two members disagree on three dates, so the place copy asserts none of them.** **⚠️ Four heroes are weak and one badly so**: the Bird Bridge pin's thumbnail is a red X the creator drew over a photograph to retract an earlier post, so it renders as a red X on the map (the Hugo de Grootplein shape). The Mercedes-Benz Stadium precedent says the owner may pull it.

**⚠️ Re-derived from `Tours.json` on 2026-08-27 (session 119, this batch): 1,552 tours + 124 link pins, 133 maker rows (34 Atlas studios + 99 pinned creators — 83 TikTok, 11 YouTube, 5 Instagram), 1,924 tour stops.** **Places 30 → 31: Barcelona Pavilion**, built on owner instruction from the Atlas tour and the new pin (77 m apart, same subject) — **the pin moved onto the geofenced tour, never the reverse**. Twenty-three pins added on branch `claude/tour-links-paste-thsd6q`, open as **[#632](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/632)** (owner asked for it). ⚠️ **#632 moves a GEOFENCED tour 78 m** — the Atlas *Mies van der Rohe Pavilion* onto the building — **on explicit owner instruction, overriding "the pin moves, never the tour"**; the move improves the geofence (old point was 64 m outside the building's edge, so standing at the pavilion did not fire it) and is recorded in `CLAUDE.md` so it is not reverted. ⚠️ **This batch adds NO new country** — India and Mexico both look new against the 22 that `tours` span, and both were already in the catalogue via existing link pins (Maya Somaiya Library; two Mexican food pins). **The catalogue spans 30 countries across tours AND pins, and it did before this batch too — never quote the tours-only figure as the catalogue's.** ⚠️ **This is the first batch where Instagram arrives at scale** — 6 reels across 4 creators, all playable inline, and **all four Instagram makers ship `avatarURL: null`** because Instagram's embed exposes no creator avatar; they fall back to the platform mark. ⚠️ **Pinned creators now outnumber Atlas studios almost three to one**, so the raw `dataService.makers.count` in Settings → About is further past the tipping point flagged when there were four pins; the owner's decision (userId-only / published-tour-only / split the row) is **still owed and getting worse each batch**.

**⚠️ Re-derived from `Tours.json` on 2026-08-27 (session 117, after merging #626 and #625): 1,552 tours + 85 link pins, 99 maker rows (34 Atlas studios + 65 pinned creators), 1,924 tour stops.** **⚠️ THREE CONTENT BATCHES LANDED WITHIN TWO HOURS** — nineteen San Francisco pins (#626), four Orlando architect names (#625) and ten Atlanta pins (#627, of which nine shipped). **#626 and #627 conflicted in four files, including an add/add on the same handoff filename**, and #627 had to merge `main` twice. Expect that whenever content sessions run in parallel. **⚠️ THE ATLANTA TOUR BATCH IS ALSO IN FLIGHT** and is in the tracker: 30 single-stop tours, 30 MP3s outstanding, under a new **Atlas Studio ATL**. Its Oakland Cemetery tour will land beside #627's pin for the same site. **The audio-pending queue is NOT empty.**

**⚠️ Re-derived from `Tours.json` on 2026-08-27 (session 116): 1,552 tours + 76 link pins, 90 maker rows (34 Atlas studios + 56 pinned creators — 46 TikTok, 9 YouTube, 1 Instagram), 1,924 stops. Live-confirmed on both the Supabase RPC and the gh-pages mirror after #626 merged.** ⚠️ The RPC reports **1,553 tours / 98 makers** against that — the long-standing `Zxxx` test tour plus upsert-only maker accumulation, both pre-existing. **Assert on link-pin counts, not maker totals.** The paragraph below predates Copenhagen and the last three link-pin batches and its figures are stale — **re-derive, do not quote.** **🔴 Pinned creators now outnumber Atlas studios nearly two to one**, so the raw `dataService.makers.count` in Settings → About has passed the tipping point flagged when there were four pins; the owner's decision (userId-only / published-tour-only / split the row) is still owed. **⚠️ An ATLANTA batch is still being staged by another session and is still not in the tracker** — a gh-pages push landed mid-session (MLK Birth Home ×7 + the Candler Building). Do not report the audio-pending queue as empty without re-deriving.
**⚠️ THE PARAGRAPH BELOW IS STALE AND IS KEPT ONLY FOR ITS LIVE-RPC NOTES — re-derive, do not quote.** Its figures predate Copenhagen and the last five link-pin batches, and **its claim that the audio-pending queue is EMPTY is now false**: Atlanta sits in it with 30 tours awaiting narration.

**Catalog 1,516 tours live / 45 maker rows served** (49 before the test-creator cleanup). The four `TEST -` pins are gone (#593),
replaced by **4 real AMNH creator link pins** (#591). **7 served makers have zero tours**, all of them real sign-ups who have not published yet. — **Stockholm (Atlas Studio STO, 45 tours) landed 2026-08-24**
and is live in the RPC, along with VIA 57 West. Milan (48 tours) landed 2026-08-22. ⚠️ The RPC reports **40** maker rows against a true 32: upsert-only accumulation,
long-standing. The audio-pending queue is **EMPTY**. `drafts/AUDIO-PENDING-SURVEY.md` on `origin/main` stays the
authority; read it from `origin/main`, never from a branch.

## 7. Verification traps — each one produced a wrong answer here

Not general advice. Every entry below is a check that **returned a confident, wrong result** on this
repo, and the correction that makes it honest.

- 🔴 **`check-image-duplicates.py --pins` PASSES A REUSED-FOOTAGE HERO.** Its confirmation threshold
  is **8.0**, and the `@hereinnyc` batch's two frames of one subway carriage scored **12.2** — so the
  tool reported OK on a pair that is visibly the same shot. That is the tool working as designed: it
  hunts byte-level re-writes, and "same footage, different frame" is not one. **A clean `--pins` run
  does not mean no two heroes show the same thing — only a per-batch perceptual sweep catches that**,
  and the pair it found put a Transit Museum carriage on the Yankee Stadium pin (owner-decided: it
  stays).
- 🔴 **A MERGED PR IS NOT EVIDENCE THAT NO BUILD CARRIES IT.** This board twice reported "nothing
  waiting on a build" from a list of merged PRs without re-reading the run list in the same turn, and
  was wrong within five minutes both times — another session had already built the work from its own
  branch. **Re-read the Actions run list in the same turn as any claim about what is waiting**,
  including when the answer is "nothing".
- 🔴 **`git diff` AGAINST A COMMIT GIT DOES NOT HAVE RETURNS EMPTY** — indistinguishable from "no
  differences". Branches auto-delete on merge, so a build's commit is routinely unreachable. **This
  produced a false clean twice in one session.** Fetch `refs/pull/<n>/head`, confirm with
  `git cat-file -t`, and only then trust the diff.
- 🔴 **A TAKEN-DOWN TOUR IS INVISIBLE TO EVERY ORDINARY READ.** `get_catalog` serves published only,
  and so does the RLS policy behind PostgREST. On 2026-08-25 the catalogue reported four creators had
  no tours, a direct API read agreed, and **both were wrong** — each still owned one `taken_down` row,
  which is why a delete matched nothing three times. **Anything reasoning about "does this maker have
  tours" must query the table as `postgres`.**
- 🔴 **A GUARD THAT TURNS A LOUD, SPECIFIC ERROR INTO SILENCE IS WORSE THAN NO GUARD.** That same
  delete carried `not exists (select 1 from tours …)`, which the hidden rows failed — so it reported
  *"Success. No rows returned."* Without the guard, `tours.maker_id` being `on delete restrict` would
  have raised a foreign-key violation **naming the exact blocking row**.
- ⚠️ **A GREEN `publish-catalog` RUN IS NOT PROOF THE CATALOGUE CHANGED.** It reported success while
  the live RPC still served the old place count for three more checks. **Ask the RPC.**
- ⚠️ **A SPAWNED CLOUD SESSION MAY HAVE NO GITHUB TOOLS, AND CANNOT BE MESSAGED FROM A WEB SESSION.**
  One spawned 2026-08-26 wrote the link-fullscreen fix, could not open a PR, and sat blocked eight
  hours while another session solved it independently; **its branch was never pushed, so the work was
  lost with the container.** Brief a spawned session completely up front, tell it to **push its branch
  early**, and check on it rather than reading silence as progress.

## 6. Known debt — real, not urgent

**⚠️ UNGROUPED PLACE CANDIDATES, catalogue-wide (2026-08-27, owner asked for report-only).**
Re-derive with **`python3 scripts/check-place-candidates.py`** — do not quote the table below.

**🔴 ONE EXACT COINCIDENCE WITH NO PLACE PAGE, and it is a known deferral, not a new fault.**
**Casa Lleó Morera** and the **Dreta de l'Eixample** walk share the coordinate
`41.39134849385539, 2.16545472553582` exactly — the walk's intro stop is wired to the landmark, the
standard convention. CLAUDE.md already records it as *"a place candidate, deliberately NOT created
here (a place needs its own copy, address and photograph; that is separate editorial work)."*
**⚠️ The checker exits 1 on it, so a clean exit is not the current expected state** — that is the
one outstanding item, and it clears the moment someone writes the Barcelona place.

**NEAR — same subject, not coincident. None is acted on.**

| pair | apart | note |
|---|---|---|
| The Jordaan / The Jordaan (Amsterdam) | 136 m | **Identical titles.** Could be a place or could be a duplicate — open both before deciding |
| Gamla stan 1859 / Gamla stan (Stockholm) | 301 m | A historical tour and a present-day one of the same quarter |
| Benesse House Museum / …Outdoor Works (Naoshima) | 455 m | The museum vs its outdoor works |
| Tibidabo / Tibidabo Amusement Park (Barcelona) | 48 m | **🔴 NOT a candidate — settled.** #541 left these separate: a mountain and a funfair are two subjects. Do not re-raise |
| Chinatown (pin) / two Atlas Chinatown tours (SF) | 257 m, 395 m | **Owner declined 2026-08-27** — a district is not a site. Do not re-propose |

**🔴 THE PROCESS GAP THAT PRODUCED THIS ROW.** The SF batch shipped three place candidates without
anyone asking — the owner spotted them on a glance at the map. The evidence was in hand at the time
(two pins on an exactly identical coordinate, and two hero-slug collisions against existing Atlas
tours) and was read only as a rendering and filename concern. **A place-candidate sweep now runs as
part of the link-pin batch checks** so this never depends on a session noticing again.

**🔴 AND #629 MERGED AS AN EMPTY COMMIT.** The places were committed onto the local `main` by
mistake, then `git push -u origin <branch>` pushed the branch ref — still at an already-merged
commit. CI went green, GitHub said "successfully merged", and nothing shipped; re-landed as #630.
**"Successfully merged" is not evidence anything landed. Check `git log origin/main..HEAD` before
pushing and confirm the squash changed files afterwards.**


- **Supabase over-reports.** The RPC serves ~1,419 tours / 39 makers against a true 1,418 / 31.
  Upsert-only accumulation: rows deleted from `Tours.json` are never deleted from the database.
  Any count shown in-app inherits this.
- **2 dead gallery images** — The Oculus and The Charging Bull, Wikimedia 404s, deferred since
  2026-06-21.
- **Square Saint-Louis** is the one place still repeating an image; needs one sourced photo.
- **15 tours** missing a Place-type or Theme tag (validator warnings, content-only fix).
- **Policy pages** are long legal prose at 13px monospace — readability at length unconfirmed.
