# dozent.world

The public website: home page plus the three policy pages Apple, Stripe and the
card networks expect a platform to publish.

Deployed to Vercel from this directory (project Root Directory = `site`).
Plain static HTML — no build step, no framework, no dependencies.

    /                  what Dozent is, how it works, links to the policies
    /privacy/          Privacy Policy
    /terms/            Terms of Service
    /acceptable-use/   Acceptable Use Policy

    /t/?id=<uuid>      a shared tour        ─┐
    /m/?id=<uuid>      a shared creator      │  where every Share button
    /l/?id=<uuid>      a shared list         │  in the app points
    /p/?id=<uuid>      a shared place        │
    /g/?code=<code>    join a group listen  ─┘

## Why the share links live here

iOS opens a link in the app instead of Safari only if the site serves
`.well-known/apple-app-site-association` **at its domain root**, and the app
claims that domain (`applinks:dozent.world`, in the entitlements file).

The gh-pages host could never do this: it puts the project under
`ehky2882.github.io/TRAVEL-GUIDED-TOUR/`, and that root belongs to the account
rather than to this repo, so the file can't be served where iOS looks. Every
share link therefore opened in Safari. Moving the links to a domain we own
outright fixes it.

`vercel.json` forces `Content-Type: application/json` on that file — Apple
rejects it otherwise, and it deliberately has no extension.

**The gh-pages copies of these five pages stay published.** Links shared from
builds before this change point there, and they must keep working. That is a
permanent legacy surface, not a duplicate to tidy away.

## Not the asset CDN

The app's audio and images are served from the `gh-pages` branch at
`ehky2882.github.io/TRAVEL-GUIDED-TOUR/`, and **7,713 URLs in `Tours.json`
point there**. That host is deliberately left alone. Do not attach
`dozent.world` to GitHub Pages — it would redirect every one of those URLs.

## Keep in step with the app

`/privacy/` must agree with the App Privacy answers in App Store Connect, and
`/acceptable-use/` is cited in Dozent's Stripe platform review. Update the
"Last updated" date in a page when its substance changes.
