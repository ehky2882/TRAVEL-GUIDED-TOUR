// Atlas — moderation email notifier (Supabase Edge Function)
//
// Emails the Atlas team when a tour is submitted for review or a report is filed.
// This is the V2-launch minimal moderation surface (owner decision 2026-06-21):
// notify by email, act manually via select publish_tour(...) / takedown_tour(...).
//
// Setup (owner, when standing up Supabase):
//   1. Deploy:  supabase functions deploy notify-moderation
//   2. Secrets: supabase secrets set RESEND_API_KEY=... MODERATION_EMAIL=you@example.com \
//                                    FROM_EMAIL="Atlas <moderation@yourdomain>"
//   3. Two Database Webhooks (Dashboard → Database → Webhooks), both POST here:
//        a) table public.tours,   events: UPDATE   (fires on status changes)
//        b) table public.reports, events: INSERT
//   (Resend is the example email provider; swap the sendEmail body for SendGrid/
//    Postmark/SMTP if preferred — only that one function changes.)

interface WebhookPayload {
  type: "INSERT" | "UPDATE" | "DELETE";
  table: string;
  record: Record<string, unknown> | null;
  old_record: Record<string, unknown> | null;
}

const RESEND_API_KEY = Deno.env.get("RESEND_API_KEY") ?? "";
const TO = Deno.env.get("MODERATION_EMAIL") ?? "";
const FROM = Deno.env.get("FROM_EMAIL") ?? "Atlas <moderation@atlas.app>";

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

Deno.serve(async (req: Request): Promise<Response> => {
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
      `Atlas: tour submitted for review — ${t.title}`,
      `<p><strong>${t.title}</strong> was submitted for review.</p>
       <p>Maker: <code>${t.maker_id}</code><br>
          City: ${t.city ?? "—"}<br>
          Category: ${t.primary_category}</p>
       <p>Tour id: <code>${t.id}</code></p>
       <p>After reviewing in Supabase:<br>
          publish &nbsp;<code>select publish_tour('${t.id}');</code><br>
          take down <code>select takedown_tour('${t.id}');</code></p>`,
    );
  }

  // New report filed against a tour.
  if (p.table === "reports" && p.type === "INSERT" && p.record) {
    const r = p.record;
    await sendEmail(
      `Atlas: tour reported — ${r.reason}`,
      `<p>A tour was reported.</p>
       <p>Reason: ${r.reason}<br>
          Details: ${r.details ?? "—"}<br>
          Tour id: <code>${r.tour_id}</code></p>
       <p>Triage in the <code>reports</code> table (status: open → reviewed / actioned / dismissed).</p>`,
    );
  }

  return new Response("ok", { status: 200 });
});
