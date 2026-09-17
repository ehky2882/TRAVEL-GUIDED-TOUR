# The place detector can now tell 'obviously one venue' from 'ask the owner'

_2026-09-17 01:10 UTC · branch `place-candidates-venue-handle-26`_

Owner, 2026-09-17: *"i need you to be proactive and finding them and asking for
our opinion, and when it is super-clear and doesnt need input, just go ahead and
do it"*.

`check-place-candidates.py` reported **16 EXACT groups** and told a session to put
**all sixteen** to the owner. That is why sixteen had accumulated unanswered: the
tier could not tell "obviously one restaurant posted twice" from "two pins that
share a coordinate for no good reason".

**EXACT now splits in two**, on a second, independent signal:

| tier | meaning | what a session does |
|---|---|---|
| **EXACT · PROVEN** — 14 | coincident AND shown to be one venue | act, then tell the owner |
| **EXACT · ASK** — 2 | coincident and nothing else | put to the owner |

**The signal the tool was missing is the venue @handle in the caption.** Creators
write `📍@marksoffmadison`; two pins naming the same venue handle are the same
venue. Handle spellings vary (`@eatnamkeen` / `@eat.namkeen`; `@allantico` /
`@allanticovinaionyc`) so comparison is on letters and digits with a prefix
match, and a plain name is normalised into handle form so `Mark's Off Madison`
matches `@marksoffmadison`. A third rule catches prose: *"the fried chicken from
Pecking House"* beside `Pecking House`.

🔴 **The trap, and it is guarded by a selftest:** `sourceAuthor` is the CREATOR
and appears in most captions. Counting it would make every pair of pins by one
food reviewer look like one venue — firing on an entire feed. It is excluded.

⚠️ **Why automating this tier is safe, measured rather than assumed:** every
part-vs-whole case the owner has ever declined sits **6.9 m – 290 m** apart —
the Barbican Centre 149 m, the laundrette 243 m, Golden Lane 290 m, Carmine
Street Mural 6.9 m, Blue Ribbon Garden 17.7 m, Hoyt–Schermerhorn 10.3 m. **Not
one is coincident**, so a tier that only ever sees identical coordinates cannot
reach the owner's judgement calls. A selftest asserts that boundary directly.

**Two bugs the new selftests caught in my own first draft**, both silent:
`" ".join(subject_words(...))` joins a SET, so the containment test compared
against a randomly-ordered string; and requiring *both* captions to carry the
handle missed the commonest real shape — one titled entry beside one caption.

49/49 selftests pass. **No catalogue change in this PR** — the 14 proven groups
still need creating, and that is blocked separately: place ids are uuid5 over an
input I could not derive from the catalogue, and inventing one is how duplicate
places happen.
