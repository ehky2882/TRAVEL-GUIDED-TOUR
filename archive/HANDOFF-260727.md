# HANDOFF 2026-07-27 — Rome launched (session 75, web/PM, content)

**Shipped:** [PR #450](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/450) (squash `4598ed6`) —
**Rome live under Atlas Studio ROM**, 30 tours. Catalog **948 → 978 tours / 18 → 19 makers /
1174 → 1227 stops**. Verified live on Supabase (the primary source) at 978 tours / Rome 30.

Content-only; no app code, no backend change, no build needed.

---

## What landed

New maker **Atlas Studio ROM** 🇮🇹 — `d5939cce-c156-5316-984a-6259aadd8be2`
(uuid5 `atlas-maker:rom`), the 19th.

- **25 single-stop tours**, geofenced 30 m (the city-launch default).
- **5 multi-stop walks**, stop 0 `manual` intro + geofenced 40 m stops:

  | walk slug | title | stops | distance | category |
  |---|---|---|---|---|
  | `rome-ancientrome-walk` | Ancient Rome | intro+5 | 1.5 km | history |
  | `rome-baroqueheart-walk` | The Baroque Heart | intro+5 | 2.0 km | culturalHeritage |
  | `rome-ghettotrastevere-walk` | The Ghetto and Trastevere | intro+5 | 2.5 km | culturalHeritage |
  | `rome-vaticanborgo-walk` | The Vatican and the Borgo | intro+4 | 1.25 km | sacredSites |
  | `rome-aventinetestaccio-walk` | The Aventine and Testaccio | intro+4 | 2.5 km | culturalHeritage |

- 53 MP3s, **6,866 s** (~1h54m). Category mix: 12 history · 7 culturalHeritage ·
  5 architecture · 3 sacredSites · 3 natureAndParks.
- Images needed **zero** work — all 116 were already staged by slug on gh-pages since
  2026-07-15, and the counts matched the batch README exactly.

This is the second consecutive city wired straight out of the audio-pending queue
(after Madrid): scripts + images staged long in advance on
`claude/amsterdam-handoff-preserve-hlhyp8`, narration the only missing ingredient.

---

## ⚠️ The delivery was 60 MP3s, not 53 — 7 singles arrived that could NOT be wired

Master-list numbers **25–31**, narrated *after* the image-staging session closed (its README
says "gaps 25–45 were never uploaded as singles"):

| # | Tour | banked audio slug | hero image? | script? |
|---|---|---|---|---|
| 25 | Piazza del Quirinale | `piazza-quirinale` | ✗ | ✗ |
| 26 | Monti — Piazza della Madonna dei Monti | `monti` | ✗ | ✗ |
| 27 | Santa Maria Maggiore | `santa-maria-maggiore` | ✗ | ✗ |
| 28 | San Giovanni in Laterano & Scala Santa | `san-giovanni-laterano` | ✗ | ✗ |
| 29 | Trajan's Column & Imperial Forums | `trajans-column` | ✓ walk-only hero, no gallery | ✗ |
| 30 | Via Appia Antica — Porta San Sebastiano | `porta-san-sebastiano` | ✗ | ✗ |
| 31 | Testaccio & Monte Testaccio | `testaccio` | ✓ walk-only hero, no gallery | ✗ |

**The Dropbox drop carried only MP3s plus handoff/master-list `.md` files — zero `.txt`
scripts.** So these have audio and nothing else.

**Deliberately not wired.** A tour with no hero can't ship at all, and one with no script
would ship `transcriptText: null` plus a blind-authored caption. **Their audio IS banked on
gh-pages under its eventual slug**, so nothing is lost and no re-upload is needed later.

**Judgement call worth revisiting:** Trajan's Column + Testaccio *do* have a hero and could
have shipped as thin singles. I left them out because without scripts they'd be low quality,
and both already appear as walk stops. Owner can overrule — it's a quick follow-up.

**To finish all 7:** (a) find the display scripts — they exist, the narration was read from
something; (b) run the image pipeline for the 5 with no hero + galleries for all 7 (needs
owner picks); (c) assemble as singles, geofenced 30 m.

Tracked as a new PENDING row in `drafts/AUDIO-PENDING-SURVEY.md`.

---

## ⚠️ Two staging-README errors — expect them again in Montreal and Berlin

Both batches were staged by the same hand as Rome, so **check for these before wiring**:

1. **The READMEs specify `kind: "singleStop"`. The catalog's real value is `"single"`**
   (934 tours use it). `"singleStop"` would fail to decode.
2. **Their suggested tags are not in the controlled vocabulary** — `ancient-site`, `square`,
   `church`, `fountain`, `viewpoint`, `castle`, `monument` are all informal. Map onto real
   Place types (`Monument`, `Public Square`, `Religious Building`, `Park`, `Market`, …).
   **`Models/Tag.swift` is the vocabulary, not a batch README.**

Also: the README offers `_intro.mp3` *or* `_stop0` for walk intro audio. **The catalog
convention is `{walkslug}_stop0.mp3`** (verified against live Madrid).

---

## Verification performed

- **Swift validator (CI, authoritative): 0 errors, 0 warnings.** All three checks green
  (Validate Tours.json · Build iOS Simulator · Run unit tests).
- **Locally there is no `swift` toolchain in a Linux web session**, so validation ran through
  a Python mirror of `validate-tours.swift` (`scratchpad/validate_tours.py`). **That mirror
  was self-tested against 5 injected fault classes** — beat marker, unknown tag, duplicate
  stop id, hero-in-gallery, zero duration — and caught all 5, so its 0/0 wasn't a silent pass.
  Worth rebuilding the same way next time; CI stays authoritative.
- **All 169 Rome asset URLs live-checked 200** (53 audio + 116 images).
  ⚠️ *Gotcha:* `while read` skips a final line with no trailing newline — the first sweep
  silently checked 168 of 169. Check the count, not just the failure count.
- **uuid5 scheme reverse-verified** against live Madrid maker/tour/stop ids *before* use
  (`atlas-{maker,tour,stop}:rom:<slug>`, walk stops `…:<walkslug>-stop{N}`).
  0 duplicate tour or stop ids in the merged catalog.
- **Diff additions-only** — 1685 +, 1 − (closing brace shifting). `Tours.json` re-serialized
  with `json.dumps(d, ensure_ascii=False, indent=2)`, no trailing newline.
- `transcriptText` = each display (non-TTS) script minus the **44 `[beat]` markers**
  (validator hard-errors on `\[[A-Za-z]`). Madrid had 20, HCMC 33 — this trap recurs every
  batch. Captions: opening sentence, extended to a second when the opener is a bare
  instruction ("Start with the holes."); shortest shipped caption 60 chars, no fragments.
- All 53 stop coordinates sanity-checked inside greater Rome.

---

## Process notes

- **gh-pages `--no-checkout` worktree** (avoids downloading the whole binary tree in a web
  session). ⚠️ **Every file reads as an unstaged deletion in that worktree** — stage new files
  by explicit path (`xargs … git add --`) and **never `git add -A`**, or the commit wipes the
  branch. I verified `git diff --cached --name-status` showed 60 A and zero D before committing.
- A first attempt using `git sparse-checkout` staged mass deletions — abandoned and redone.
- **Dropbox folder link → `?dl=1`** downloads the whole folder as a zip (123 MB here).
- **CI job-state API lags.** A poll returned "zero jobs in flight" while the simulator build
  was still running, and a later run-level poll timed out at 30 min although all jobs had
  finished at 02:51. Poll the individual check runs, and don't trust one reading.
- **Branch deletion is blocked by this environment's git proxy** — `claude/rome-audio-stage-tours-m05vud`
  is merged and needs deleting in the GitHub UI.

---

## Queue after Rome

**Audio-pending: 65 tours / 103 MP3s** — Montreal 29 (25 single + 4 walks, → Atlas Studio YUL),
Berlin 36 (31 single + 5 walks, → Atlas Studio BER). Both image-complete, narration only.

Plus the 7 Rome extras above, which need **scripts + images**, not audio.
