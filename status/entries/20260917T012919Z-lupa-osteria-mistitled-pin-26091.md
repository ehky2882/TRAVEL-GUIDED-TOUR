# A pin named for the restaurant it only mentions is retitled Lupa Osteria Romana

_2026-09-17 01:29 UTC · branch `lupa-osteria-mistitled-pin-26091`_

Owner: *"fix the one about lupa osteria"*.

A `@jacksdiningroom` pin was titled **"Did you know the people behind
@allanticovinaionyc also h…"** — the raw caption. Its subject is **Lupa Osteria
Romana**; All'Antico is only *mentioned*, as the sister restaurant. Retitled to
`Lupa Osteria Romana`, on the pin and on its single stop.

**Verified rather than assumed:** Lupa Osteria Romana, 170 Thompson Street,
Greenwich Village — and the pin's coordinate `40.7275849, -74.0000977` lands on
Thompson Street. The pin was in the right place; only its name was wrong.

⚠️ **The caption is kept verbatim** in `longDescription`. It is the creator's own
words and the reason the pin exists; the title is ours to make readable, the
caption is not ours to edit.

⚠️ **The hero image filename is left alone** —
`did-you-know-the-people-behind-jacksdiningroom_hero.webp`. It is only an
address, the bytes are correct, and Image Pipeline rule 9 is explicit that a new
filename means a new upload while overwriting bytes at a live URL reaches no
phone that has already downloaded it. Renaming buys nothing and risks that.

⚠️ Retitling changes text the embedding model reads, so the `rebuild-related`
job will regenerate "More like this" on merge. That is automatic since
2026-09-15 and needs no action.

**How it was found:** while checking the six restaurant places (#975), the
venue-handle rule correctly refused to group this pin with the two real
All'Antico ones — it names `@lupaosteria` as its location and All'Antico only in
passing. The rule working is what exposed the mis-title.
