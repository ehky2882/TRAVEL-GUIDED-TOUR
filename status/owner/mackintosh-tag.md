# Add a 'Charles Rennie Mackintosh' architect tag (6 Glasgow tours)

_opened 2026-09-29 · clear with `git rm status/owner/mackintosh-tag.md`_

# Add a "Charles Rennie Mackintosh" architect tag to the vocabulary

_Glasgow launch (Atlas Studio GLA), 2026-09-29_

Six of the new Glasgow tours or stops are Mackintosh buildings, and the controlled tag
vocabulary has no tag for him, so they ship with only **Designed by a Master**.
The contributor asked that you add it. It is a Swift change (`Models/Tag.swift`,
the `.architect` list, plus the mirrored list in `scripts/validate-tours.swift`),
so it waits for your OK.

| tour | |
|---|---|
| Mackintosh Queen's Cross Church | his only built church |
| The Mackintosh Tearooms | the Willow Tea Rooms, 217 Sauchiehall St |
| Old Daily Record Building | Renfield Lane facade, 1901–04 |
| The Hill House | Helensburgh |
| House for an Art Lover | built 1996 to his 1901 design |
| University of Glasgow walk → The Mackintosh House stop | reconstructed interiors (the walk also carries George Gilbert Scott) |

Once the tag exists, a content-only follow-up PR adds it to those tours.
