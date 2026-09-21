# #1037 MERGED: one defect in three places — spine-match.py, the verdict layer, and the vision sweep all read a cached answer without checking the digest that versions it. The coordinate audit had been reporting all nine of the previous night's fixes as still broken. refresh-spine now keeps the cache current on every content merge (continue-on-error). Coordinate findings 85 -> 41 genuinely unexamined.

_2026-09-21 07:15 UTC · branch `scale-pinned-tours-automation-db`_
