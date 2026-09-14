# HANDOFF — 2026-09-14: the Westlake Theatre hiding inside "First National Bank of Hollywood"

Owner: *"CHECK FIRST NATIONAL BANK OF HOLLYWOOD.... WHY IS WESTLAKE THEATER IN THERE?"*

## What was wrong

The place page **First National Bank of Hollywood** had two members, both TikTok link pins from
`@nickcabotrodriguez`, both titled "First National Bank of Hollywood", both at 34.101687, −118.338437
(Hollywood & Highland). Their captions name no building — only *"What's up with this building? Part 5"*
and *"Part 6"*. The thumbnails do:

| Pin | Video | Thumbnail says | Really is |
|---|---|---|---|
| `57CAD837…` | Part 6, `7639208049722330381` | **First National Bank Building** | correct |
| `62ECCD3D…` | Part 5, `7635369706404318477` | **The Westlake Theatre** | wrong title, wrong place — 10 km away, on MacArthur Park |

## How it happened

1. **#790 (2026-09-10)** minted this creator's 21 pins. That session caught several mislabels by reading
   the names burned into thumbnails (`HANDOFF-260910-3.md` § 4), but did not read Part 5's, and titled
   and placed it as a second First National Bank of Hollywood. It noticed the two posts sat on *the
   exact same coordinate* and recorded that as a place-page question for the owner — not as a sign
   one of them might be mislabelled.
2. **#801 (2026-09-10)**, the place sweep, turned that exact coincidence into a place page. Its own
   description even says *"Two separate posts by the same creator sit on it."*

## The fix

- Pin `62ECCD3D-535D-5168-9299-54AEECE3FD16`: title → **Westlake Theatre**; moved to the OSM theatre
  (way 419974963, 638 S Alvarado St) at **34.058286, −118.27523**; tags `Notable Building, Commerce,
  History` → `Notable Building, History` (Commerce was chosen for a bank), category → `history`,
  matching this creator's other theatre pin (Hollywood Pacific Theatre).
- **Place "First National Bank of Hollywood" dropped** — one member left, and a place needs two. The
  seed prunes it on merge; no SQL owed. The Part 6 pin stays where it was, on the bank.
- The hero file is still named `first-national-bank-hollywood-2-…_hero.webp`; its **bytes are right**
  (it shows the Westlake), so it was not renamed. Cosmetic only.

## Checks

`validate-tours.swift` 0 errors; `validate-tours-mirror.py` 0 errors, selftest 32/32; seed generates
302 places with no reference to the dropped id; `check-place-candidates.py` identical to `main`.

## Worth doing

The same shape — **two posts from one creator on an identical coordinate** — can be checked across all
places whose members share a `sourceAuthor`. Not done here.
