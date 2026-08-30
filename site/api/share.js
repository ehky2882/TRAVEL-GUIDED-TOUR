/**
 * Server-rendered share pages for /t/ (tour), /m/ (creator), /p/ (place) and
 * /l/ (list).
 *
 * ⚠️ WHY THIS IS A FUNCTION AND NOT A STATIC PAGE — do not "simplify" it back.
 * These URLs are what the app's share sheet produces, so the first thing that
 * fetches one is almost always a link-preview crawler (iMessage, Slack,
 * WhatsApp, Signal, Discord). **Those crawlers do not run JavaScript.** They
 * read the bytes of this response and nothing else. The previous static pages
 * carried one hardcoded `og:image` and patched `og:title`/`og:description`
 * from JS after load, so every shared link — whichever tour it pointed at —
 * previewed as the same generic card with a stale placeholder icon. The tags
 * have to be in the HTML before it leaves the server, which is what this does.
 *
 * It also renders the human-facing card server-side. That is a side benefit
 * worth keeping: the old page downloaded the whole ~7 MB `Tours.json` in the
 * browser to display one tour. Here a single row comes back from PostgREST.
 *
 * Reads use the **publishable (anon) key**, which is client-safe by design and
 * already ships inside the iOS app — RLS limits it to published rows, and a
 * private list correctly resolves to nothing. Never put the service_role key
 * here: this file is public.
 */

const SUPABASE_URL = 'https://apkcihljybvuyuzpbnqd.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_KRAiUnT3z6yjhvPmXO9CIQ_OKPdtdKf';

const SITE = 'https://dozent.world';
const APP_STORE_URL = 'https://apps.apple.com/app/id6771030927';
const CONTACT_EMAIL = 'hello@dozent.world';

/** The brand card, used whenever a subject has no picture of its own. */
const DEFAULT_IMAGE = `${SITE}/og-default.png`;
const DEFAULT_IMAGE_W = 1200;
const DEFAULT_IMAGE_H = 630;

/** Budget for the catalog read. A crawler that waits is a preview that fails. */
const FETCH_TIMEOUT_MS = 4500;

const KINDS = {
  t: { eyebrow: 'Audio tour', fallbackTitle: 'An audio tour on Dozent' },
  m: { eyebrow: 'Creator', fallbackTitle: 'A creator on Dozent' },
  p: { eyebrow: 'Place', fallbackTitle: 'A place on Dozent' },
  l: { eyebrow: 'List', fallbackTitle: 'A list on Dozent' },
};

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function esc(value) {
  return String(value == null ? '' : value).replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}

/**
 * ⚠️ KNOWN GAP, measured 2026-08-30 — heroes are linked at their real URL, and
 * two platform quirks follow from that. Neither is worth a transcoding proxy
 * today, but do not "fix" one without re-measuring the other:
 *
 *  1. **Wikimedia 403s crawler user-agents.** 48 of 1,794 heroes (the older NYC
 *     tours) sit on `upload.wikimedia.org`, which answers `facebookexternalhit`
 *     with 403 "Unauthorized request" while serving a browser 200. So those 48
 *     preview without a picture on Facebook and WhatsApp. Apple/iMessage, Slack,
 *     Twitter and Discord all fetch them fine — verified per user-agent.
 *  2. **1,746 heroes are WebP.** Fine on iMessage, Slack, Facebook, Twitter and
 *     Discord; historically unreliable on WhatsApp.
 *
 * The fix for both is one thing: serve og:image through an optimizer that
 * refetches server-side and emits JPEG (Vercel Image Optimization, or a
 * `sharp`-backed function). That was deliberately not done here because a
 * misconfigured or quota-limited optimizer breaks *every* preview, which is
 * far worse than the partial gap above.
 */

/**
 * Only https images are emitted. An og:image must be absolute and publicly
 * fetchable, and refusing anything else keeps a malformed catalog value from
 * reaching an href/src attribute.
 */
function safeImage(url) {
  if (typeof url !== 'string') return null;
  const trimmed = url.trim();
  return /^https:\/\/[^\s"'<>]+$/i.test(trimmed) ? trimmed : null;
}

/**
 * Several bureaus title their tours "English | 日本語" / "English | 中文".
 * The primary reads as the headline; the secondary sits beneath it and is
 * deliberately kept out of og:title, where it would just eat the line.
 */
function splitTitle(title) {
  const parts = String(title || '').split(' | ');
  return { primary: parts[0] || '', secondary: parts.slice(1).join(' | ') };
}

/** "2 min" / "1 hr 14 min" — matches how the app states a tour's length. */
function formatDuration(seconds) {
  const total = Number(seconds);
  if (!Number.isFinite(total) || total <= 0) return null;
  const mins = Math.max(1, Math.round(total / 60));
  if (mins < 60) return `${mins} min`;
  const hrs = Math.floor(mins / 60);
  const rem = mins % 60;
  return rem ? `${hrs} hr ${rem} min` : `${hrs} hr`;
}

/** Trimmed to something a preview card will actually show without eliding. */
function clamp(text, max = 200) {
  const s = String(text || '').replace(/\s+/g, ' ').trim();
  if (s.length <= max) return s;
  return `${s.slice(0, max - 1).replace(/[\s,;:.!-]+$/, '')}…`;
}

async function supabase(path, init = {}) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), FETCH_TIMEOUT_MS);
  try {
    const res = await fetch(`${SUPABASE_URL}${path}`, {
      ...init,
      signal: controller.signal,
      headers: {
        apikey: SUPABASE_ANON_KEY,
        Authorization: `Bearer ${SUPABASE_ANON_KEY}`,
        ...(init.headers || {}),
      },
    });
    if (!res.ok) return null;
    return await res.json();
  } catch {
    // A backend blip must degrade to the brand card, never to a 500 — a
    // crawler that gets an error caches the absence of a preview.
    return null;
  } finally {
    clearTimeout(timer);
  }
}

const first = (rows) => (Array.isArray(rows) && rows.length ? rows[0] : null);

// ---------------------------------------------------------------------------
// Loaders. Each returns the normalised shape the page template renders, or
// null when the subject does not exist / is not visible to anon.
// ---------------------------------------------------------------------------

async function loadTour(id) {
  const row = first(await supabase(
    `/rest/v1/tours?id=eq.${id}` +
    '&select=title,short_description,long_description,hero_image_url,city,country,' +
    'total_duration_seconds,kind,makers(display_name)'
  ));
  if (!row) return null;

  const { primary, secondary } = splitTitle(row.title);
  const meta = [];
  if (row.city) meta.push(row.city);
  if (row.makers && row.makers.display_name) meta.push(row.makers.display_name);
  const duration = formatDuration(row.total_duration_seconds);
  if (duration) meta.push(duration);

  return {
    heading: primary,
    subheading: secondary,
    // A link pin is somebody's post that Dozent pins to a map, not a tour we
    // narrate — labelling it "Audio tour" would misdescribe it.
    eyebrow: row.kind === 'multiStop' ? 'Walking tour'
      : row.kind === 'link' ? 'Pinned post'
      : 'Audio tour',
    meta,
    body: row.short_description || row.long_description,
    image: safeImage(row.hero_image_url),
  };
}

async function loadPlace(id) {
  const row = first(await supabase(
    `/rest/v1/places?id=eq.${id}&select=name,description,hero_image_url,city,address`
  ));
  if (!row) return null;

  const meta = [];
  if (row.address) meta.push(row.address);
  else if (row.city) meta.push(row.city);

  return {
    heading: row.name,
    subheading: row.address && row.city ? row.city : '',
    eyebrow: 'Place',
    meta,
    body: row.description,
    image: safeImage(row.hero_image_url),
  };
}

async function loadMaker(id) {
  const row = first(await supabase(
    `/rest/v1/makers?id=eq.${id}&select=display_name,bio,avatar_url,avatar_emoji`
  ));
  if (!row) return null;

  return {
    heading: row.display_name,
    subheading: '',
    eyebrow: 'Creator',
    meta: [],
    body: row.bio,
    image: safeImage(row.avatar_url),
    // An avatar is a small square. Asking a client for a wide hero card and
    // handing it a 512px circle looks worse than the compact card, so this
    // one stays `summary`.
    squareImage: true,
  };
}

async function loadList(id) {
  const doc = await supabase('/rest/v1/rpc/get_journey', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ p_journey: id }),
  });
  // RLS returns nothing for an Only-me list — indistinguishable from a list
  // that never existed, which is the correct outcome for a stranger's link.
  if (!doc || !doc.id) return null;

  const items = Array.isArray(doc.items) ? doc.items : [];
  let image = safeImage(doc.coverImageURL);

  // No cover set: borrow the first tour's hero rather than falling all the way
  // back to the brand card. One extra read, only in this case.
  if (!image && items.length) {
    const tourId = String(items[0].tourId || '');
    if (UUID_RE.test(tourId)) {
      const row = first(await supabase(
        `/rest/v1/tours?id=eq.${tourId}&select=hero_image_url`
      ));
      if (row) image = safeImage(row.hero_image_url);
    }
  }

  const count = items.length;
  return {
    heading: doc.title,
    subheading: '',
    eyebrow: 'List',
    meta: [count === 1 ? '1 tour' : `${count} tours`],
    body: doc.description,
    image,
  };
}

const LOADERS = { t: loadTour, m: loadMaker, p: loadPlace, l: loadList };

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

function renderPage({ kind, subject, canonical }) {
  const config = KINDS[kind];
  const heading = (subject && subject.heading) || config.fallbackTitle;
  const image = (subject && subject.image) || DEFAULT_IMAGE;
  const isDefaultImage = image === DEFAULT_IMAGE;
  const isSquare = Boolean(subject && subject.squareImage);

  const ogTitle = subject ? `${heading} — Dozent` : 'Dozent — Audio Tours';
  const ogDescription = clamp(
    (subject && subject.body) ||
    'GPS-anchored audio tours that play themselves as you walk.'
  );

  const meta = (subject && subject.meta ? subject.meta : []).filter(Boolean);
  const metaHTML = meta.map(esc).join('<span class="sep">·</span>');

  // Width/height are only asserted for the brand card, whose size we know.
  // Catalog heroes vary (1200x900 pipeline crops, Wikimedia thumbs of assorted
  // heights), and a wrong dimension renders worse than none at all.
  const dimensions = isDefaultImage
    ? `\n  <meta property="og:image:width" content="${DEFAULT_IMAGE_W}" />` +
      `\n  <meta property="og:image:height" content="${DEFAULT_IMAGE_H}" />`
    : '';

  const heroHTML = subject && subject.image
    ? `<img class="hero" src="${esc(subject.image)}" alt="${esc(heading)}" />`
    : '<div class="hero"></div>';

  const notFoundHTML = `
      <div class="center-state">
        <h1>Not found</h1>
        <p>This link may be out of date. Dozent has more than 1,500 audio tours across dozens of cities.</p>
      </div>`;

  const cardHTML = `
      <div class="card">
        ${heroHTML}
        <div class="body">
          <span class="eyebrow">${esc(subject ? subject.eyebrow : config.eyebrow)}</span>
          <h1>${esc(heading)}</h1>
          ${subject && subject.subheading ? `<p class="subtitle">${esc(subject.subheading)}</p>` : ''}
          ${metaHTML ? `<p class="meta">${metaHTML}</p>` : ''}
          ${subject && subject.body ? `<p class="desc">${esc(clamp(subject.body, 400))}</p>` : ''}
        </div>
      </div>`;

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <title>${esc(ogTitle)}</title>
  <meta name="description" content="${esc(ogDescription)}" />
  <link rel="canonical" href="${esc(canonical)}" />

  <!-- Rendered server-side on purpose: link-preview crawlers do not run JS. -->
  <meta property="og:site_name" content="Dozent" />
  <meta property="og:type" content="website" />
  <meta property="og:url" content="${esc(canonical)}" />
  <meta property="og:title" content="${esc(ogTitle)}" />
  <meta property="og:description" content="${esc(ogDescription)}" />
  <meta property="og:image" content="${esc(image)}" />
  <meta property="og:image:alt" content="${esc(heading)}" />${dimensions}
  <meta name="twitter:card" content="${isSquare || isDefaultImage ? 'summary' : 'summary_large_image'}" />
  <meta name="twitter:title" content="${esc(ogTitle)}" />
  <meta name="twitter:description" content="${esc(ogDescription)}" />
  <meta name="twitter:image" content="${esc(image)}" />

  <link rel="icon" type="image/png" href="${SITE}/og-default.png" />
  <link rel="apple-touch-icon" href="${SITE}/og-default.png" />
  <style>
    :root {
      --bg: #17130F;
      --surface: #211B15;
      --surface-2: #2C241C;
      --text: #F5EFE7;
      --muted: #B7AC9E;
      --accent: #8B7535;
      --accent-soft: rgba(139, 117, 53, 0.16);
      --border: rgba(245, 239, 231, 0.10);
    }
    * { box-sizing: border-box; -webkit-tap-highlight-color: transparent; }
    html, body { margin: 0; padding: 0; }
    body {
      background: var(--bg);
      color: var(--text);
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.5;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    .wrap { width: 100%; max-width: 560px; padding: 20px 20px 48px; }
    .brand {
      display: flex; align-items: center; gap: 10px;
      font-weight: 700; letter-spacing: 0.14em; text-transform: uppercase;
      font-size: 14px; color: var(--text); margin: 8px 0 22px;
      text-decoration: none;
    }
    .brand .dot { width: 12px; height: 12px; border-radius: 50%; background: var(--accent); }
    .card {
      background: var(--surface); border: 1px solid var(--border);
      border-radius: 18px; overflow: hidden;
      box-shadow: 0 18px 40px rgba(0,0,0,0.35);
    }
    .hero { width: 100%; aspect-ratio: 4 / 3; background: var(--surface-2); object-fit: cover; display: block; }
    .body { padding: 20px; }
    .eyebrow {
      display: inline-block; font-size: 11px; font-weight: 700; letter-spacing: 0.12em;
      text-transform: uppercase; color: var(--accent);
      background: var(--accent-soft); padding: 5px 10px; border-radius: 999px; margin-bottom: 12px;
    }
    h1 { font-size: 24px; line-height: 1.22; margin: 0 0 4px; font-weight: 700; }
    .subtitle { font-size: 17px; color: var(--muted); margin: 0 0 12px; font-weight: 500; }
    .meta { font-size: 14px; color: var(--muted); margin: 0 0 16px; }
    .meta .sep { opacity: 0.5; padding: 0 6px; }
    .desc { font-size: 15px; color: var(--text); opacity: 0.92; margin: 0; }
    .cta { margin-top: 22px; text-align: center; }
    .cta .lead { font-size: 15px; color: var(--muted); margin: 0 0 14px; }
    .store {
      display: inline-block; text-decoration: none; font-weight: 600; font-size: 16px;
      color: #17130F; background: var(--accent); padding: 14px 26px; border-radius: 999px;
    }
    .store:active { opacity: 0.85; }
    .foot { text-align: center; font-size: 12px; color: var(--muted); margin-top: 26px; opacity: 0.8; }
    .foot a { color: var(--muted); }
    .center-state { text-align: center; padding: 60px 10px; }
    .center-state h1 { font-size: 22px; }
    .center-state p { color: var(--muted); }
  </style>
</head>
<body>
  <div class="wrap">
    <a class="brand" href="${SITE}/"><span class="dot"></span> Dozent</a>
    ${subject ? cardHTML : notFoundHTML}
    <div class="cta">
      <p class="lead">${subject
        ? 'Find this on the map in Dozent, alongside audio tours that play themselves as you walk.'
        : 'GPS-anchored audio tours that play themselves as you walk.'}</p>
      <a class="store" href="${APP_STORE_URL}">Download on the App Store</a>
    </div>
    <div class="foot">
      Dozent — GPS-anchored audio tours. <a href="mailto:${CONTACT_EMAIL}">${CONTACT_EMAIL}</a>
    </div>
  </div>
</body>
</html>`;
}

// ---------------------------------------------------------------------------

module.exports = async (req, res) => {
  const query = req.query || {};
  const kind = String(query.kind || 't').toLowerCase();
  const config = KINDS[kind];

  if (!config) {
    res.statusCode = 404;
    res.setHeader('Content-Type', 'text/html; charset=utf-8');
    res.end(renderPage({ kind: 't', subject: null, canonical: `${SITE}/` }));
    return;
  }

  const rawId = String(query.id || '').trim();
  const canonical = rawId
    ? `${SITE}/${kind}/?id=${encodeURIComponent(rawId.toLowerCase())}`
    : `${SITE}/${kind}/`;

  let subject = null;
  if (UUID_RE.test(rawId)) {
    try {
      subject = await LOADERS[kind](rawId.toLowerCase());
    } catch {
      subject = null;
    }
  }

  // Always 200. A crawler handed a 404 caches "no preview", and these links
  // are shared by people — a stale id should still show the brand card and a
  // way to get the app, not a dead end.
  res.statusCode = 200;
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  // Cache at the edge so a widely-shared link does not hit Postgres per crawl,
  // while still picking up a corrected hero within the hour.
  res.setHeader(
    'Cache-Control',
    subject
      ? 'public, max-age=0, s-maxage=600, stale-while-revalidate=86400'
      : 'public, max-age=0, s-maxage=60'
  );
  res.end(renderPage({ kind, subject, canonical }));
};
