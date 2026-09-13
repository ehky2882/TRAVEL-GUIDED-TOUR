# Unique usernames — design

**Status: DECIDED 2026-09-12 — all nine recommendations, not yet built.** Owner: *"i'll go with
your recommendation so long as they are aligned with 'industry standards'."* Each was checked
against that condition: see § Industry check at the end. Nothing is built and no SQL has been
written or pasted. Same pattern as `docs/catalog-version-check-design.md` and
`docs/filter-chips-design.md`.

**The requirement, in the owner's words (2026-09-12):**

> "this exposes the issue of usernames. at minimum, we definitely need every user to have a unique
> username"

**🔴 The hard constraint, also the owner's (2026-09-12), restating the standing decision of
2026-08-25:**

> "definitely do not delete any users. 0 tours doesn't mean anything."

Nothing in this design deletes, merges or takes back any account — including the sixteen called
`New Creator`. Every existing row keeps its id, its name, its tours and its sign-in.
`backend/remove_test_creators.sql` is not re-run and not adapted.

---

## The answer in one paragraph

Give every row in `makers` two new fields: a **platform** (`dozent`, `instagram`, `tiktok` or
`youtube`) and a **handle** (`kathyng`, `urbanistariel`). The pair is unique: there can be only one
`@urbanistariel` **on Instagram**, and only one `@kathyng` **on Dozent**. Every existing row is given
a handle automatically, so no one has to do anything and no one is blocked from signing in. The
display name stays exactly as it is — free text, duplicates allowed. New Dozent accounts cannot take
a handle that belongs to a creator we already pin, or a handle that looks official.

## What is there today

Measured against the live database on 2026-09-12 (a paged read of four columns, 19 KB, no catalogue
download). **Re-measure before building** — `main` moves every few hours.

| | |
|---|---|
| Rows in `makers` | **416** |
| — pinned creators (`Instagram @…`, `TikTok @…`, `YouTube @…`) | **354** (218 Instagram · 124 TikTok · 12 YouTube) |
| — Atlas studios (`Atlas Studio NYC` …) | **34** |
| — people with an account (`user_id` set) | **28** — exactly the rows that exist only in the database |
| Distinct display names | **401** — the one repeat is `New Creator`, ×16, **all sixteen real accounts** |
| Makers marked private | **3** (all accounts) |
| Any username or handle column | **none** |
| Any rule that two makers cannot share a name | **none** |

Why so many `New Creator`s: a `makers` row is created for **every** signup by `handle_new_user()` in
`backend/accounts.sql`, and its name comes from whatever the sign-in provider supplies. **Sign in
with Apple, as the app calls it, supplies nothing** (`AuthService.signInWithApple` passes only the
identity token), and neither does email sign-up. So everyone who signs up those ways is
`New Creator`. They have not abandoned anything; nobody asked them for a name.

✅ **Nothing in the app finds a maker by name.** Every tour, follow, list, share link
(`dozent.world/m/<id>`) and deep link goes through the maker's id. A handle is therefore a **new
thing added beside what exists**. No existing link or reference has to move.

---

## Decision 1 — a handle beside the name, or make the name itself unique?

| | **A. Handle beside the display name** *(recommended)* | B. Make the display name unique |
|---|---|---|
| What the person sees | A name (`Kathy Ng`) and an address (`@kathyng`) | One name, which must be unused |
| Two real people called *Sam Lee* | Both are `Sam Lee`; their handles differ | The second is told they cannot use their own name |
| The 16 `New Creator` rows | Stay as they are; each gets its own handle | 15 of them must be renamed first |
| Lookalikes (`Kathy Ng` · `kathy ng` · `Kathy  Ng` · `Kathy Ng 🌿`) | A handle is lowercase and plain letters, so these cannot exist | All four count as "different" and all four are allowed |
| Pinned creators | Their handle is their handle on the platform | Their name *is* their handle, so it already works |

**Recommendation: A.** It is what Instagram, TikTok, YouTube and GitHub all do, for the reasons in
the table. B looks simpler, but its uniqueness is weak: a name can differ by a space or a capital
letter and still read the same. It also turns away a real person over a clash they did not cause.

## Decision 2 — one namespace, or one per platform?

This is the question the requirement turns on, and **the live data answers it.**

**Nineteen creators are pinned under the same handle on two platforms** — `urbanistariel`,
`archimarathon`, `history_alice`, `joshuacharow` and fifteen more are each on both TikTok and
Instagram (one on TikTok and YouTube). Those are two separate rows today, each with its own posts,
and correctly so: the same name on two apps is not guaranteed to be the same person.

| | **A. Unique per platform: `(platform, handle)`** *(recommended)* | B. One global namespace |
|---|---|---|
| The 19 cross-platform creators | Unchanged — `instagram/urbanistariel` and `tiktok/urbanistariel` coexist | 19 real creators need an invented handle that is not their real one |
| A Dozent user called `@joe` when we later pin TikTok `@joe` | Both allowed, each shown with its platform | The pin cannot be added under its real handle |
| Where "which platform?" lives | Its own field | Still has to be read out of the display-name string |

**Recommendation: A** — unique on the pair `(platform, handle)`, with every Dozent account and every
Atlas studio on platform `dozent`. It also retires the habit of reading the platform off the front
of a display name.

**What it deliberately leaves open:** a Dozent account and an Instagram creator *can* share a handle
in principle. Decision 5 closes that for the case that matters — impersonating someone we already
pin.

## Decision 3 — the rules for a Dozent handle

These apply to handles on platform `dozent`. Handles on Instagram, TikTok and YouTube follow **those
platforms' own rules**. We store them as the platform gives them, lowercased, and never invent or
shorten them.

| Rule | Proposal | Why |
|---|---|---|
| Characters | `a–z`, `0–9`, `.` and `_` | Instagram's set. **All 354 pinned handles already fit it**, so the two kinds read alike |
| Case | Stored lowercase; typing `KathyNg` saves `kathyng` | So `@KathyNg` and `@kathyng` can never be two people. (8 pinned handles carry capitals today; all three platforms ignore case, which is why `make-link-pin.py` already lowercases before hashing) |
| Length | **3 to 24** | 24 is TikTok's limit and the longest pinned handle today. Fits on one line on the narrowest phone |
| Shape | Starts and ends with a letter or digit; no `..`; not all digits | No `.kathy.`, and nothing that looks like an id number |
| The `@` | Never stored; typed or shown freely | `@kathyng` and `kathyng` are the same handle |

**Reserved — no account may take these:**

- **Words that sound official:** `dozent`, `atlas`, `admin`, `support`, `help`, `official`, `staff`,
  `moderator`, `team`, `system`, `api`, `me`, `null`, `everyone`, and the platform and company
  names `instagram`, `tiktok`, `youtube`, `apple`, `google`.
- **Anything starting `dozent` or `atlas`** — those belong to the studios.
- **Anything starting `user.`** — the shape given out automatically (Decision 6), so an assigned
  handle can never be mistaken for a chosen one or copied.
- **The website's own paths** — `about`, `privacy`, `terms`, `confirmed` — so that if
  `dozent.world/<handle>` is ever wanted, no handle is already in the way.
- **Every handle of a pinned creator** — Decision 5.

The reserved list lives in the database as a small table, not in the app, so adding a word needs no
app release.

### Can a handle be changed?

Nothing *breaks* when a handle changes: every link uses the id, not the handle. The risk is someone
grabbing the handle a well-known account just gave up.

| | |
|---|---|
| **A. Changeable at most once every 30 days; the old one is held for 30 days** *(recommended)* | Stops rapid swapping and stops someone taking an old handle the moment it is released |
| B. Changeable any time, released at once | Simplest; open to the handle-grab above |
| C. Never changeable | Unkind — most of today's accounts get their handle automatically and should be able to choose |

**The first change after an automatic handle does not count toward the 30 days.** So everyone who
was given `user.3f9a2c` can pick a real one straight away.

## Decision 4 — where the handle is chosen

| | |
|---|---|
| **A. Assigned automatically at signup; changeable in Edit Profile; a one-time prompt before first publish** *(recommended)* | Nobody is ever blocked. Signing in stays one tap. The people whose handle is actually seen get asked at the moment it starts to matter |
| B. Required at signup | Adds a screen to Sign in with Apple and Google, which are one tap today, for the many people who only want to save tours |
| C. Only at first publish | Leaves accounts without a handle — which breaks "every user has one" |

**Recommendation: A.** The requirement is that every user *has* a unique handle, not that every user
*chooses* one on day one.

**The availability check.** As someone types in Edit Profile, the app asks the database one tiny
question — *"is this handle free?"* — about half a second after they stop typing. The answer is one
of `available`, `taken`, `reserved` or `not allowed` (with the rule it breaks). It is a few bytes;
it never touches the catalogue.

⚠️ **The check is a courtesy, not the guard.** Two people can check the same free handle in the same
second. The guard is the database's uniqueness rule. It refuses the second save, and the app shows
"just taken — try another" rather than an error code.

## Decision 5 — impersonation

**Today, nothing stops a new account naming itself `Instagram @urbanistariel`.** That is
byte-identical to a real creator whose posts are on the map. A unique handle alone does not fix it.
Two rules together do:

1. **Pinned creators' handles are reserved on Dozent.** A new account cannot take `@urbanistariel`
   on platform `dozent` while any platform's `@urbanistariel` is pinned. *(Recommended.)*
2. **An account's display name may not dress up as something else.** Names beginning
   `Instagram @`, `TikTok @`, `YouTube @` or `Atlas Studio` are refused for accounts. Checked in the
   database, so it holds for every build, old ones included. *(Recommended. Checked live: **none of
   the 28 existing accounts** has a name like that, so no one is affected.)*
3. **Accounts are always on platform `dozent`.** A signed-in person cannot set their own row to
   `instagram` and claim a handle there. *(Not optional — without it, rules 1 and 2 are open.)*

**The reverse case:** a Dozent user already holds `@joe`, and we later pin TikTok `@joe`. Both are
allowed — different platforms, each shown with its own badge. `make-link-pin.py` should *warn* when
a new pin's handle matches an existing Dozent account, so the owner sees it. It must not block or
rename the account (the hard constraint).

**Not in this design:** a real creator *claiming* their pinned page, and verification badges. Both
are worth having and both need their own design.

## Decision 6 — what every existing row gets

**The backfill runs once, needs nothing from anyone, and was dry-run against all 416 live rows on
2026-09-12:** every row gets exactly one valid handle, with no clashes, and no reserved words.

| Rows | Platform | Handle | Example |
|---|---|---|---|
| **354 pinned creators** | read from the front of their name | the text after `@`, lowercased | `Instagram @urbanistariel` → `instagram` / `urbanistariel` |
| **34 Atlas studios** | `dozent` | `atlas.` + the city code | `Atlas Studio NYC` → `atlas.nyc` |
| **12 accounts with a real name** | `dozent` | the name in plain lowercase letters and digits | `Kathy Ng` → `kathyng` |
| **16 `New Creator` accounts** | `dozent` | `user.` + six characters of their id | `user.3f9a2c` |

Checked on the live rows: all 354 pinned names parse, no two collide within a platform, and every
handle already meets the character rules. Studio codes run `AMS` to `YYZ`, all 34 valid.

**Two choices inside this:**

- **Accounts with a real name.** *Recommended:* derive the handle from the name, as above. A handle
  made from a public display name reveals nothing new, and it is friendlier than `user.3f9a2c`. The
  alternative is a neutral `user.` handle for all 28, and asking each to pick. If two names derive
  to the same handle, the later signup gets a `2`. Names that reduce to fewer than 3 letters, or hit
  a reserved word, get the neutral form.
- **Studio handles.** *Recommended:* `atlas.nyc`. The alternative, `atlasstudio.nyc`, is longer and
  says nothing more.

**Nobody's display name changes.** Pinned creators keep `Instagram @urbanistariel` as their display
name for now, because **the app on people's phones today (1.1.1) shows only the display name**. It
knows nothing about platform or handle. A later build can show `@urbanistariel` with an Instagram
badge instead; that is cosmetic and can wait.

### Why nobody can be locked out

- **A new row can never be saved without a handle, and can never fail for lack of one.** A database
  trigger gives any new row a handle if it arrives without one. That covers signup
  (`handle_new_user`), the app creating a profile (`MakerProfileService.saveProfile`), and a content
  seed that adds a new pinned creator.
- **Old builds keep working.** 1.1.1 saves a profile without sending a handle. The database fills in
  the columns a save leaves out on insert, and leaves them alone on update. So an old phone can
  neither erase a handle nor fail to save.
- **Signing in never touches the handle.** Sign-in reads nothing from it.

---

## Everything it touches

In build order. Order matters: the seed script cannot write columns that do not yet exist.

### 1. One SQL paste (owner, Supabase SQL Editor) — hand-held, as usual

A single file, `backend/usernames.sql`, run in one transaction:

1. Add `platform` and `handle` to `makers`, empty at first.
2. Backfill every row (Decision 6).
3. Add the reserved-handle table and the rules. Rules: lowercase only, allowed characters and
   length, unique on `(platform, handle)`, accounts always `dozent`, the display-name guard, reserved
   handles and pinned handles off-limits.
4. The trigger that gives a new row a handle when none is supplied.
5. The small `handle_available(text)` function for the Edit Profile check, and the 30-day change rule.
6. Add `platform` and `handle` to the maker block of `get_catalog_core_base()`.
7. `select public.refresh_catalog_snapshot();` — **load-bearing**; without it no phone sees the
   change (Automation Rule 11b).
8. A final line that returns the counts, so the Editor's result is itself the proof: 416 rows, 416
   handles, 0 duplicates.

⚠️ **Step 6 is the dangerous one, and this repo has been hurt by exactly it.** Redefining the
catalogue function from an out-of-date copy is how `places`, `priceTier` and `isPrivate` vanished
for 14 hours on 2026-08-19. The migration must start from the **live** definition
(`pg_get_functiondef`) and only add two keys. Then run `python3 scripts/check-catalog-contract.py`
**after** the paste (Automation Rule 11).

**What it does not change:** which makers `get_catalog` returns. So the **Dozents count in Settings
does not move** — it counts every maker row, by the owner's decision of 2026-07-05.

**Egress:** two short keys on 416 makers. *Estimated* at a few KB compressed on a 2.3 MB payload —
well under 1%. **Measure it compressed after the paste** (`CLAUDE.md` § Egress); do not quote this
estimate.

### 2. A content-and-scripts PR (auto-merge class)

- **`Resources/Tours.json`** — every one of its 388 makers gains `platform` and `handle`. That is
  the 354 pinned creators and 34 studios; the 28 accounts live only in the database. Old builds
  ignore keys they do not know, so the bundled seed and the gh-pages mirror keep decoding.
- **`scripts/validate-tours.swift`** — the `Maker` mirror gains both fields, in the **same commit**
  as the model (the mirror rule). New checks: `(platform, handle)` unique; handle obeys the rules; a
  pinned creator's display name agrees with its platform and handle.
- **`scripts/make-link-pin.py`** — emits `platform` and `handle` for each new creator. Warns when a
  new pin's handle matches an existing Dozent account (Decision 5).
- **`backend/seed_from_toursjson.py`** — writes both columns for makers.
- **`scripts/check-catalog-contract.py` / `check-catalog-keys.py`** — know about the two new keys,
  so their disappearance is caught.

### 3. An app PR (code — waits for owner OK and a device check)

- **`Models/Maker.swift`** — `platform: String?` and `handle: String?`. **Optional on purpose**:
  the bundled offline seed and older mirrors may not carry them, and a missing optional decodes as
  empty rather than failing the whole catalogue.
- **`Data/MakerProfileService.swift`** — `MakerRow` reads the handle; saving sends it only when the
  person changed it. A clash comes back as a friendly message.
- **`Features/Profile/ProfileEditorView.swift`** — a **HANDLE** field under DISPLAY NAME, shown with
  `@`, with the live availability line and the 30-day note.
- **`Features/Maker/MakerView.swift`** — `@handle` under the display name, for Dozent accounts.
- **`Features/Search/SearchView.swift`** — creator search also matches the handle. Today it matches
  the display name only.
- **The one-time prompt before first publish** (Decision 4), in the upload flow.
- **Signup — no change.** `SignInView` and `AuthService` are untouched; that is the point of
  Decision 4.
- Tests: handle normalisation, the rule checks the app mirrors for instant feedback, decoding with
  and without the new keys.

---

## A related finding, corrected here — what is public about an account

The finding as recorded: *"two makers with `isPrivate: true` are served regardless, and no consumer
code reads that flag."* Re-checked while writing this.

**The facts hold; the reading of them needs correcting.** There are now **three** private makers,
not two, and it is true that no screen showing *someone else* reads the flag. But **"private" in this
app never meant a hidden profile.** `backend/social.sql` defines it as Instagram's private account:

- follow requests wait for approval instead of going through, and
- the follower and following lists are hidden from everyone but the owner.

The database enforces both, not the app. So a private account's name, photo and bio being visible is
**what the flag promises**, not a leak of it.

**The real question is a different one, and it is the owner's.** Because every signup gets a maker
row, **someone who signed up only to save tours has a public creator page** — their sign-in name,
their photo if they uploaded one, and their account id. That page appears in Search as a creator
with "0 tours". Two facts shape the options:

- The `makers` table is **readable by anyone, directly** (`makers_public_read … using (true)` in
  `backend/schema.sql`). Removing rows from `get_catalog` alone would make nothing private.
- Removing content-less accounts from `get_catalog` would **move the Dozents count in Settings**,
  which is deliberately every account (2026-07-05).

| | |
|---|---|
| **A. Search lists only Dozents with published content** *(recommended, as its own small app change)* | Fixes "New Creator · 0 tours" in Search. Changes no count and no database rule |
| B. Stop publishing accounts that have published nothing | A genuine privacy change, but it touches the database's read rule, the Settings count, followers and public lists. Needs its own design |
| C. Leave it | — |

**Recommendation: keep it out of this design, and do A separately.** Handles do not make it better or
worse. An automatic `user.3f9a2c` publishes nothing new, and a handle made from a display name
publishes nothing the display name did not already. B is worth raising again if the owner wants
non-creators to be invisible, but that is a different requirement from unique usernames.

## What is explicitly NOT being done

- **No account is deleted, merged, renamed or reclaimed.** Not the 16 `New Creator` rows, not any
  account with no tours. `backend/remove_test_creators.sql` is not re-run and not adapted.
- **Display names do not become unique**, and no existing display name changes.
- **No handle-based links** (`dozent.world/@kathyng`). Links stay on ids. The website's paths are
  reserved so this stays possible later.
- **No verification badges and no creator claiming a pinned page.**
- **No change to signup or sign-in screens.**
- **No change to which makers the catalogue serves**, and so none to the Settings count.
- **Pinned creators' display strings are not reformatted** while 1.1.1 is the public build.
- **No privacy change** — see the section above.

## What is being asked

Each has a recommendation; "go with the recommendations" is a complete answer.

1. **Handle beside the display name** (A) or unique display names (B)? — *recommend A*
2. **Unique per platform** (A) or one global namespace (B)? — *recommend A*
3. **Handle rules** as proposed (3–24 characters, `a–z 0–9 . _`, lowercase, reserved list)? — *recommend yes*
4. **Changing a handle:** once per 30 days with the old one held (A), any time (B), or never (C)? — *recommend A*
5. **Reserve pinned creators' handles, and refuse account names that imitate a platform or a studio?** — *recommend yes to both*
6. **Existing accounts:** handles derived from their names (recommended), or neutral `user.` handles for all 28?
7. **Studio handles:** `atlas.nyc` (recommended) or `atlasstudio.nyc`?
8. **Where the handle is chosen:** automatically at signup, editable, with a prompt before first publish (A)? — *recommend A*
9. **The public-account question:** separately, as a Search-only fix (A)? — *recommend A, not in this build*

Once answered, the build is the three pieces above in that order: one SQL paste, one auto-merge
content PR, one app PR for device review.

---

## Industry check — the condition the owner attached

**Answered 2026-09-12: the recommendations, on condition they match industry standards.** Checked
one by one:

| # | Recommendation | Precedent | Standard? |
|---|---|---|---|
| 1 | Handle beside a free display name | Instagram, TikTok, X, YouTube, GitHub | ✅ |
| 2 | Unique per platform | How any app stores accounts from other services (provider + name). Ours are pinned creators | ✅ |
| 3 | 3–24 chars, `a–z 0–9 . _`, lowercase | Instagram: same characters, up to 30. TikTok: same characters, up to 24 | ✅ |
| 4 | Change once per 30 days, old handle held | TikTok: once per 30 days. Instagram holds a released handle for 14 days | ✅ |
| 5 | Reserved words; no imitating a platform or studio | Every major platform reserves official names and bans impersonation | ✅ Reserving pinned creators' handles goes slightly further than most, in the same direction |
| 6 | Automatic handles for existing and new accounts | TikTok assigns `user` + digits by default | ✅ |
| 7 | Studio handles `atlas.nyc` | No standard applies — a brand choice | ➖ Defaulted to match the studios' current public names |
| 8 | Assigned at signup, editable, prompt before first publish | TikTok | ✅ |
| 9 | Public-account question handled separately | A process choice | ➖ |

### 🔴 Found while checking: no way for a user to delete their own account

**Apple requires it** (App Review Guideline 5.1.1(v), since 2022): an app that lets people create
an account must let them start deleting it from inside the app. A search of the app, the backend
SQL, the Edge Functions and the website on 2026-09-12 found **no such feature**. It may exist under
wording the search missed; **re-check before acting on this.**

It matters here because it meets the owner's rule *"never delete any users"* head-on. The likely
reading — and the industry-standard one — is that **we** never delete anyone, while **a person** can
always delete **their own** account. That is an owner decision, not something to assume, and it is
outside this design. If a person deletes their account, their handle is held for 30 days like any
released handle, then freed.
