# dozent.world

The public website: home page plus the three policy pages Apple, Stripe and the
card networks expect a platform to publish.

Deployed to Vercel from this directory (project Root Directory = `site`).
Plain static HTML — no build step, no framework, no dependencies.

    /                  what Dozent is, how it works, links to the policies
    /privacy/          Privacy Policy
    /terms/            Terms of Service
    /acceptable-use/   Acceptable Use Policy

## Not the asset CDN

The app's audio and images are served from the `gh-pages` branch at
`ehky2882.github.io/TRAVEL-GUIDED-TOUR/`, and **7,713 URLs in `Tours.json`
point there**. That host is deliberately left alone. Do not attach
`dozent.world` to GitHub Pages — it would redirect every one of those URLs.

## Keep in step with the app

`/privacy/` must agree with the App Privacy answers in App Store Connect, and
`/acceptable-use/` is cited in Dozent's Stripe platform review. Update the
"Last updated" date in a page when its substance changes.
