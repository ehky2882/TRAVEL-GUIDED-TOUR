# 10+ pins stacked within metres of each other (Ginza + Shimokitazawa centroid fallback)

_opened 2026-09-14 · clear with `git rm status/owner/ginza-shimokitazawa-pin-precision.md`_

`scripts/check-place-candidates.py`, run right after PR #896 merged (per the
automation rule for "a link-pin batch has been merged"), found 4 of my 20
new pins sitting within 1–8 metres of OTHER unrelated pins:

- **Oniku Karyu, Ginza** — 2.1–2.4 m from a cluster of SIX other Ginza pins
  (Cafe de l'Ambre, Tir na nog, Mizutani Camera, Makiyaki Ginza Onodera,
  Kobe Beef Ginza Wagyu Souei, Meat Kappo Ginza KEIJI). Those six already
  form an EXACT coincident group among themselves — all landed on the same
  generic "Ginza" district centroid.
- **Sandwich Club, Shimokitazawa** — 1.1 m from Pannya, CAPOON Matcha
  Seizojo and Planet of Curry — another EXACT group, same failure (a bare
  "Shimokitazawa" centroid).
- **Nishiazabu Kamikura** — 3.5 m from Nishiazabu Teppanyaki Kichi.
- **Yoshoku Yoshikami, Asakusa** — 7.2 m from THE WAGYU BROTHERS, Asakusa.

**None of these are places** — seven or more unrelated restaurants are not
one site, and `docs/places.md` is explicit that co-location isn't identity.
I have NOT created any place pages. This is a coordinate-precision problem,
not a places.md question, and it's the same problem PR #896's own body
already flagged for 7 of its 20 pins (no street address in the caption, so
the geocode fell back to a neighborhood centroid) — this check just proved
it with hard numbers, and shows the earlier #893/#885 batch has at least
6 more pins in the same state.

**What I did NOT do:** touch any coordinate. A better fix needs a real
street address per venue (from byFood.com's own listing, Google Maps, or
you), not another guess from me.

**Ask:** should I go find real addresses for these ~10 stacked pins across
both batches (Oniku Karyu + the Ginza six, Sandwich Club + the Shimokitazawa
three, Nishiazabu Kamikura, Yoshoku Yoshikami) and push a precision-fix PR?
Or leave them until a broader precision pass? Either is fine — just didn't
want to silently ship pins I know are wrong.
