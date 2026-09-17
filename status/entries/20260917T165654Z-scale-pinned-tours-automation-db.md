# Spine coordinate audit shipped — 1,667 entries confirmed, and the findings are mostly not errors

_2026-09-17 16:56 UTC · branch `scale-pinned-tours-automation-db`_

The place spine's first payoff shipped (#988): an audit asking whether a
coordinate is RIGHT, not merely plausible or well-formed.

4,566 entries swept, zero failures. CONFIRMS 1,667 · EXTENDED 114 ·
UNMATCHED 2,507 · DISAGREES 86.

🔴 Five of the top findings were opened by hand and NONE was a catalogue error —
two were Wikidata's own error, two a different place of the same name. The
errors that prompted the work were already fixed, so the false-positive classes
now dominate. The 86 are NOT a worklist, and the PR and the tool both say so.

The durable outputs are the 1,667 independent confirmations and per-creator
coverage: Atlas Studio LDN 86% against @japanbyfood 1%. Food content needs
parse-caption-address.py + GSI, never this method.

Key facts corrected — the THIRTY-SECOND staling, and the largest countries move
this line has recorded: 2,799 pins / 344 places / 619 cities / 69 countries
against a real 2,984 / 351 / 685 / 88.
