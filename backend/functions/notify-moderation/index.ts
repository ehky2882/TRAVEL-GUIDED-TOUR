// Atlas — moderation email notifier + one-click approve (Supabase Edge Function)
//
// Two roles in one function:
//   • POST (Database Webhook): a tour entered review, or a report was filed →
//     email the moderator a rich, reviewable summary (title, maker name,
//     description, transcript, a Listen link, the photos) with one-click
//     Approve & publish / Take down buttons.
//   • GET  (button click from that email): ?action=publish|takedown&tour=<id>&token=<T>
//     → verify the token and update the tour, then show a small confirmation page.
//
// Setup (owner, Supabase dashboard):
//   1. Edge Functions → notify-moderation → paste this file → Deploy.
//   2. Edge Functions → notify-moderation → **turn Verify JWT OFF** (a browser
//      click from the email carries no JWT; the GET is protected by the token).
//   3. Secrets (Edge Functions → Secrets):
//        RESEND_API_KEY, MODERATION_EMAIL, FROM_EMAIL  (as before)
//        MODERATION_TOKEN = <a long random string>     (guards the approve links)
//   4. The two Database Webhooks (tours UPDATE, reports INSERT) are unchanged.
//
// Publishing uses a direct service-role table update (not publish_tour()), because
// the SECURITY DEFINER is_admin() gate returns false under the service role
// (auth.uid() is null). The function itself is the trusted admin here, gated by
// MODERATION_TOKEN — so a bad actor can't publish without the secret.

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
}

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const TO = Deno.env.get("MODERATION_EMAIL") ?? "";
const FROM = Deno.env.get("FROM_EMAIL") ?? "Atlas <moderation@atlas.app>";
const MODERATION_TOKEN = Deno.env.get("MODERATION_TOKEN") ?? "";

// Auto-injected into every Supabase Edge Function.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const FUNCTION_URL = `${SUPABASE_URL}/functions/v1/notify-moderation`;

const svcHeaders = {
  apikey: SERVICE_KEY,
  Authorization: `Bearer ${SERVICE_KEY}`,
  "Content-Type": "application/json",
};

function esc(s: unknown): string {
  return String(s ?? "")
    .replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function fmtDuration(seconds: unknown): string {
  const s = Number(seconds) || 0;
  if (s <= 0) return "—";
  return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
}

/// Fetch one row's selected columns via the service role (bypasses RLS).
async function fetchOne(
  table: string, query: string,
): Promise<Record<string, unknown> | null> {
  if (!SUPABASE_URL || !SERVICE_KEY) return null;
  try {
    const res = await fetch(`${SUPABASE_URL}/rest/v1/${table}?${query}&limit=1`, {
      headers: svcHeaders,
    });
    if (!res.ok) return null;
    const rows = await res.json();
    return Array.isArray(rows) && rows[0] ? rows[0] : null;
  } catch {
    return null;
  }
}

async function sendEmail(subject: string, html: string): Promise<void> {
  if (!RESEND_API_KEY || !TO) {
    console.error("missing RESEND_API_KEY or MODERATION_EMAIL");
    return;
  }
  const res = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${RESEND_API_KEY}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ from: FROM, to: TO, subject, html }),
  });
  if (!res.ok) console.error("resend error", res.status, await res.text());
}

/// Rich, reviewable HTML for a submitted tour.
async function submissionEmail(t: Record<string, unknown>): Promise<string> {
  const maker = await fetchOne("makers", `id=eq.${t.maker_id}&select=display_name`);
  const stop = await fetchOne(
    "stops",
    `tour_id=eq.${t.id}&select=audio_url,audio_duration_seconds,transcript_text`,
  );
  const makerName = maker?.display_name ? esc(maker.display_name) : `id ${esc(t.maker_id)}`;
  const audioURL = typeof stop?.audio_url === "string" ? stop.audio_url : "";
  const transcript = typeof stop?.transcript_text === "string" ? stop.transcript_text : "";

  // Photos: hero + gallery, rendered inline.
  const gallery = Array.isArray(t.additional_image_urls) ? t.additional_image_urls : [];
  const photoURLs = [t.hero_image_url, ...gallery].filter(
    (u): u is string => typeof u === "string" && u.length > 0,
  );
  const photosHTML = photoURLs.length
    ? photoURLs.map((u) =>
      `<img src="${esc(u)}" alt="" style="max-width:100%;border-radius:8px;margin:6px 0;">`
    ).join("")
    : "<p style='color:#888'>No photos attached.</p>";

  const listenHTML = audioURL
    ? `<p><a href="${esc(audioURL)}" style="font-size:16px">▶ Listen to the audio</a>
         &nbsp;<span style="color:#888">(${fmtDuration(stop?.audio_duration_seconds)})</span></p>`
    : "<p style='color:#888'>No audio attached.</p>";

  const transcriptHTML = transcript
    ? `<h3>Transcript</h3><div style="white-space:pre-wrap;background:#f6f6f6;padding:12px;border-radius:8px">${esc(transcript)}</div>`
    : "<p style='color:#888'>No transcript.</p>";

  // One-click actions (only when a token is configured).
  const actionsHTML = MODERATION_TOKEN
    ? `<p style="margin:20px 0">
         <a href="${FUNCTION_URL}?action=publish&tour=${esc(t.id)}&token=${esc(MODERATION_TOKEN)}"
            style="background:#1a7f37;color:#fff;padding:12px 20px;border-radius:8px;text-decoration:none;font-weight:bold">✓ Approve &amp; publish</a>
         &nbsp;&nbsp;
         <a href="${FUNCTION_URL}?action=takedown&tour=${esc(t.id)}&token=${esc(MODERATION_TOKEN)}"
            style="background:#b42318;color:#fff;padding:12px 20px;border-radius:8px;text-decoration:none;font-weight:bold">Take down</a>
       </p>`
    : "";

  return `
    <div style="font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:640px">
      <h2 style="margin-bottom:4px">${esc(t.title)}</h2>
      <p style="color:#555;margin-top:0">
        by <strong>${makerName}</strong> · ${esc(t.city ?? "—")} · ${esc(t.primary_category)} · ${fmtDuration(t.total_duration_seconds)}
      </p>
      ${t.short_description ? `<p><em>${esc(t.short_description)}</em></p>` : ""}
      ${t.long_description ? `<p>${esc(t.long_description)}</p>` : ""}
      ${listenHTML}
      ${transcriptHTML}
      <h3>Photos</h3>
      ${photosHTML}
      ${actionsHTML}
      <hr style="border:none;border-top:1px solid #eee;margin:20px 0">
      <p style="color:#999;font-size:12px">
        Tour id <code>${esc(t.id)}</code>.
        Manual SQL if needed: <code>select publish_tour('${esc(t.id)}');</code> ·
        <code>select takedown_tour('${esc(t.id)}');</code>
      </p>
    </div>`;
}

/// Small confirmation page returned after an approve/takedown click.
function page(title: string, body: string): Response {
  return new Response(
    `<!doctype html><meta name="viewport" content="width=device-width,initial-scale=1">
     <div style="font-family:-apple-system,Segoe UI,Roboto,sans-serif;max-width:520px;margin:60px auto;text-align:center">
       <h1 style="font-size:22px">${title}</h1><p style="color:#555">${body}</p></div>`,
    { status: 200, headers: { "Content-Type": "text/html; charset=utf-8" } },
  );
}

/// Handle a one-click approve / takedown link.
async function handleAction(url: URL): Promise<Response> {
  const action = url.searchParams.get("action");
  const tour = url.searchParams.get("tour");
  const token = url.searchParams.get("token");

  if (!MODERATION_TOKEN || token !== MODERATION_TOKEN) {
    return page("Not authorized", "This link is missing or has the wrong token.");
  }
  if (!tour || (action !== "publish" && action !== "takedown")) {
    return page("Bad request", "Missing tour id or unknown action.");
  }

  const now = new Date().toISOString();
  const patch = action === "publish"
    ? { status: "published", published_at: now, updated_at: now }
    : { status: "taken_down", updated_at: now };

  const res = await fetch(`${SUPABASE_URL}/rest/v1/tours?id=eq.${tour}`, {
    method: "PATCH",
    headers: { ...svcHeaders, Prefer: "return=representation" },
    body: JSON.stringify(patch),
  });
  if (!res.ok) {
    return page("Something went wrong", `The update failed (${res.status}). Try the SQL fallback.`);
  }
  const rows = await res.json();
  const title = Array.isArray(rows) && rows[0]?.title ? esc(rows[0].title) : "the tour";
  return action === "publish"
    ? page("✓ Published", `“${title}” is now live in the catalog.`)
    : page("Taken down", `“${title}” has been taken down.`);
}

Deno.serve(async (req: Request): Promise<Response> => {
  // GET → an approve/takedown button was clicked in the email.
  if (req.method === "GET") {
    return await handleAction(new URL(req.url));
  }

  // POST → a Database Webhook fired.
  let p: WebhookPayload;
  try {
    p = await req.json();
  } catch {
    return new Response("bad payload", { status: 400 });
  }

  // Tour entered review (new submission or re-review after an edit).
  if (
    p.table === "tours" &&
    p.record?.status === "in_review" &&
    p.old_record?.status !== "in_review"
  ) {
    const t = p.record;
    await sendEmail(
      `Atlas: review “${esc(t.title)}”`,
      await submissionEmail(t),
    );
  }

  // New report filed against a tour.
  if (p.table === "reports" && p.type === "INSERT" && p.record) {
    const r = p.record;
    const row = await fetchOne("tours", `id=eq.${r.tour_id}&select=title`);
    const title = row?.title ? String(row.title) : null;
    await sendEmail(
      title ? `Atlas: “${title}” reported — ${r.reason}` : `Atlas: tour reported — ${r.reason}`,
      `<p><strong>${esc(title ?? "A tour")}</strong> was reported.</p>
       <p>Reason: ${esc(r.reason)}<br>
          Details: ${esc(r.details ?? "—")}<br>
          Tour id: <code>${esc(r.tour_id ?? "—")}</code></p>
       <p>Triage in the <code>reports</code> table (status: open → reviewed / actioned / dismissed).</p>`,
    );
  }

  return new Response("ok", { status: 200 });
});
