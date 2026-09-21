# HANDOFF 2026-09-21 — the overnight audit: coordinates, then titles

An unattended run on 50-minute scheduled wakes. Everything below is on
`claude/overnight-audit` ([#1034](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/1034)).

## 1. Coordinates — seven fixed out of 92 reported

A wrong coordinate is the defect CLAUDE.md calls invisible to every other check: the validator
passes, CI compiles, every URL 200s, and the tour simply never fires. `spine-match.py` reported
**92 disagreements with Wikidata**. All 92 are now accounted for.

**`scripts/triage-spine.py` (NEW)** — decides *who* is wrong, because **a gazetteer can be the
wrong one**. Three signals, in increasing order of authority:

| signal | what it is |
|---|---|
| city cluster | the MEDIAN coordinate of every other entry we carry in that city. Ours near it and theirs far ⇒ Wikidata matched something else |
| **stated municipality** | Wikidata says which municipality an entity is in. **This beats distance** |
| **stated extent** | Wikidata says what the thing *is*. A kilometre means nothing for a tram system |

The second and third signals **override an UNDECIDED distance verdict only** — letting them touch a
decided one would bury the only findings worth acting on, and there is a fixture proving an
`OURS-WRONG` row survives both.

```
 distance alone:  9 OURS-WRONG ·  16 elsewhere ·   0 extended · 125 undecided
 + the two facts: 9 OURS-WRONG ·  91 elsewhere ·  28 extended ·  22 undecided
```

**Seven coordinates moved, each corroborated by a document, never by a distance**
(rule 8d forbids the latter):

| entry | was out by | corroboration |
|---|---|---|
| Govind Dev Ji Temple | 11.9 km | Q5589834 sits inside Q2723395, the Jaipur City Palace |
| MahaNakhon | 6.9 km | Q1640197, 27 sitelinks, "skyscraper in Bangkok" |
| Robie House | 1.1 km | Wikidata states the address: **5757 South Woodlawn Avenue** |
| Intempo | 2.9 km | Wikidata states **avinguda de Colòmbia**, Benidorm's Poniente side |
| Bahrain World Trade Center | 1.3 km | **Wikipedia's** article coordinate matches Wikidata to the metre |
| InterContinental Shanghai Wonderland | 5.0 km | Wikipedia matches Wikidata to 61 m |
| Etihad Museum | 1.3 km | Wikipedia gives only 2 dp (~1 km slop) but lands on Wikidata's side |

The apply step **refuses unless the independent source is closer to Wikidata's point than to ours** —
corroboration has to be capable of exonerating us.

### 🔴 The reverse finding: Wikidata contradicting itself

**Pérez Art Museum Miami.** Q3026874 states the address as **1103 Biscayne Boulevard** — Museum
Park, which is *our* coordinate — while its own `P625` points at the museum's **pre-2013 downtown
site**. Acting on the distance alone would have moved a correct pin 1.6 km onto a building the
museum left thirteen years ago.

### Two still unproven, deliberately not moved

**Belgrade Tower** and **Yachthouse by Pininfarina** look wrong the same way, but Wikidata states
no address and Wikipedia carries no coordinate. The only thing supporting a move is recollection,
**and recollection is not a named source.**

133 verdicts in `checks/spine-verdicts.json`; the 125 entity descriptions are cached in
`checks/spine-admin.json.gz`, so this is reproducible without re-fetching.

## 2. Titles

`recover-pin-title.py` gained four guards, each with a selftest *and* a mutant: a trailing
`@handle`, a **European** address (number after the street, four-digit postcode — the US and
Japanese tells both missed `Getreidegasse 33, 5020 Salzburg`), a bare city or country offered as a
venue, and emoji / variation selectors. Then a fifth: a trailing clause and a leading handle.

**Handles can be resolved only where the caption spells the name out.** `@lindustriebk` is
*L'Industrie Pizzeria*; de-camel-casing would ship "Lindustriebk" — plausible, wrong, and
authoritative-looking. 🔴 **Of 74 handles exactly ONE is corroborated.** That is a poor yield and
the honest one; loosening the rule would manufacture the rest.

**66 selftests, 44/44 mutants caught, 3 recorded as equivalent with the reason.**

## 🔴 Things I got wrong tonight

**I shipped three titles with the `@handle` still attached** — `Pinacoteca di Brera Milan Italy
@pinacotecabrera`, `Hepworth Wakefield @hepworthwakefield`, `Villa Medici in Rome @villa_medici` —
**and described them to the owner in chat more cleanly than they were.** The reject list matched
exact strings and these were not among them. Corrected to the names the owner was actually shown.

**The accent-fold trap was paid for a THIRD time**, in a new place: `same_municipality` ran its
regex *before* stripping combining marks, so "Zürich" became "zu rich" and never matched "Zurich".
The repo already knew this lesson twice over.

**Eight masked guards.** Every one was a fixture realistic enough to trip several rules at once, so
deleting any one of them still read as caught. The worst: the handle resolver matched each handle
**against itself inside its own marker**, so every one corroborated and all 74 would have been
promoted.

## What is open

- **Belgrade Tower, Yachthouse by Pininfarina** — one document each and they can be fixed.
- **237 caption titles have no 📍 marker at all**; 73 are bare handles. Unresolved from the post text.
- Still in the NAME band and *not* clean: `Bleecker`, `Bowery` (truncated), `Colonnes de Buren
  Daniel Buren` (artist appended), `Kensington Gardens right by the @serpentineuk` (a phrase).
- The sweep's **301 CONTRADICTS** are untouched tonight. Thirteen were checked by eye earlier:
  twelve were the check being wrong.
