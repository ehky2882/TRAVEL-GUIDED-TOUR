# dozent.world

The public website: home page plus the three policy pages Apple, Stripe and the
card networks expect a platform to publish.

Deployed to Vercel from this directory (project Root Directory = `site`).
Plain static HTML — no build step, no framework, no dependencies.

    /                  what Dozent is, how it works, links to the policies
    /privacy/          Privacy Policy
    /terms/            Terms of Service
    /acceptable-use/   Acceptable Use Policy
    /atlas.css         the shared stylesheet all four pages link

## The stylesheet is a port of the app's design tokens

`atlas.css` mirrors `TRAVEL GUIDED TOUR/Theme/Atlas*.swift` value for value,
so the website and the app read as one product:

  * **Everything is caption** — SF Mono at 13px (`AtlasTypography.caption`),
    the way the app's Player and Search surfaces are flattened to one token.
    **One size, one weight, one colour, no exceptions**: hierarchy is carried
    entirely by case, tracking and spacing. The page title is tracked widest,
    section headers less, sub-headers least, prose sentence case.
  * The `body, body *` reset near the top is **load-bearing, not tidiness**.
    Browsers give headings a default `em` font-size and `bold` weight, and
    inheriting from `body` does not override them — an earlier revision
    dropped h2's explicit size and it silently rendered at 19.5px. Leave it.
  * **The wordmark is the one exemption** (owner, 2026-08-19). It is New York
    serif at 13px tracked out to 6px in brass — exactly how the app draws
    DOZENT on the Settings masthead. It is a logotype, not a label.
  * `--font-body` / `--size-body` still carry `AtlasTypography.body` for
    reference, but nothing on the site uses them.
  * **Brass is `#8b7535` in both light and dark mode.** The app's AccentColor
    asset carries no dark variant on purpose (owner, 2026-07-04: "it is the
    one that stays consistent"). Do not add one here.
  * Surfaces, text steps, dividers, the spacing scale and the 12px card
    radius all come from `AtlasColors` / `AtlasSpacing`.

Each token in the file names its Swift counterpart in a comment. **If a value
changes in Swift, change it here in the same session** — nothing enforces it.

## Not the asset CDN

The app's audio and images are served from the `gh-pages` branch at
`ehky2882.github.io/TRAVEL-GUIDED-TOUR/`, and **7,713 URLs in `Tours.json`
point there**. That host is deliberately left alone. Do not attach
`dozent.world` to GitHub Pages — it would redirect every one of those URLs.

## Keep in step with the app

`/privacy/` must agree with the App Privacy answers in App Store Connect, and
`/acceptable-use/` is cited in Dozent's Stripe platform review. Update the
"Last updated" date in a page when its substance changes.
