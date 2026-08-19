# dozent.world

The public website: home page plus the three policy pages Apple, Stripe and the
card networks expect a platform to publish.

Deployed to Vercel from this directory (project Root Directory = `site`).
Plain static HTML — no build step, no framework, no dependencies.

    /                  the splash — logo, wordmark, "Coming Soon"
    /about/            what Dozent is, how it works, links to the policies
    /privacy/          Privacy Policy
    /terms/            Terms of Service
    /acceptable-use/   Acceptable Use Policy
    /atlas.css         the shared stylesheet all five pages link

## The front door is the app's load screen

`/` is a port of `TRAVEL GUIDED TOUR/SplashView.swift`, not a design of its
own: a 44px brass circle pulsing between opacity 1.0 and 0.2 on a 0.8s
ease-in-out that autoreverses, 16px of space, then "Dozent" in New York
serif at 15px, white, tracked 2. **If the app's splash changes, change this
too** — the whole point is that they are the same screen. The wordmark is
15px rather than the site's 13px caption for that reason, and the pulse is
suppressed under `prefers-reduced-motion`.

Everything that used to be on the front page now lives at `/about/`.

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
  * **Dark only, for now** (owner, 2026-08-19). The tokens hold the dark
    half of each app pair and the page does not answer
    `prefers-color-scheme` at all — a visitor on a light system still gets
    black. To restore adaptive behaviour, put the light values back on
    `:root` and move the dark ones into a `prefers-color-scheme` block;
    every rule reads tokens only, so nothing else changes.
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
