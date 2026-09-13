# A board item I migrated was three days stale — I copied its label, not its fact

_2026-09-13 18:19 UTC · branch `filtered-view-lesson`_

Owner: *"I thought I supplied ps1 hero already."* **They had.** Verified:

* [#799](https://github.com/ehky2882/TRAVEL-GUIDED-TOUR/pull/799) repointed it on
  **2026-09-10**, off a dead `upload.wikimedia.org` URL and onto the owner's own
  image on `gh-pages`.
* `moma-ps1_hero.webp` returns **200, 247,730 bytes**, `RIFF`/`WEBP` magic
  confirmed — a real image, not a 200 that serves an error page.

🔴 **How it survived: I migrated the item during the board restructure and copied
its `OPEN` label without re-checking the fact underneath it.** The file it came
from carried its own warning about exactly this — *"Four of them were still
labelled OPEN while GitHub had them merged… A label is not a state"* — and the
migration moved that warning across while committing the error it describes.

**The other two migrated items were then re-verified rather than waiting to be
told twice:**

* **The dead TikTok link — still genuinely dead** (*"Video currently
  unavailable"*, no real `og:` tags) and **no pin for it exists in the
  catalogue**, so nothing is broken by leaving it. Annotated as optional.
* The `@insightcities` coordinate check was created today by another session, so
  it needs no re-verification.

**The habit this is the third instance of today:** a recorded state is not a live
one. Counting through a filtered view, assuming `taken_down` kept buyers' access,
and now trusting a migrated label — all three were reading something written down
instead of checking the thing itself.
