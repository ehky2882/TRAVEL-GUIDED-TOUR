// Atlas — App Store Server Notifications endpoint (Supabase Edge Function)
//
// Apple POSTs V2 notifications here (refunds are the one we act on — a
// refunded sale must stop counting toward the maker's earnings and the
// buyer's entitlement). docs/paid-tours-design.md §attribution.
//
// Trust model: the notification body is only used to extract a transaction
// id and a hint of what happened. Before touching the database we fetch the
// authoritative transaction record from Apple's App Store Server API (same
// primitive as record-purchase) and act on ITS revocationDate. A forged POST
// therefore can't mark anything refunded — Apple's API wouldn't show a
// revocation.
//
// Setup (owner, dashboards — hand-held in the session notes):
//   1. Supabase → Edge Functions → deploy this as `appstore-notifications`
//      → turn **Verify JWT OFF** (Apple sends no Supabase JWT).
//   2. Same 4 secrets as record-purchase (APPSTORE_IAP_KEY, APPSTORE_IAP_KEY_ID,
//      APPSTORE_ISSUER_ID, APPSTORE_BUNDLE_ID) — set once, shared.
//   3. App Store Connect → app → App Information → App Store Server
//      Notifications → set BOTH the Production and Sandbox URLs to
//      https://<project>.supabase.co/functions/v1/appstore-notifications
//      (Version 2 notifications).
//
// Response policy: 200 for anything we've finished with (acted on it, or
// there was nothing to do) — Apple retries non-200s, and a needless retry
// storm helps nobody. The ONE exception is not being able to reach Apple to
// confirm the transaction: that returns 500 **on purpose**, because Apple's
// retry is the only second chance a refund gets, and silently dropping one
// leaves the sale counted and the maker overpaid. Everything else is logged
// for the monthly reconciliation against Apple's per-tier unit counts.

import { importPKCS8, SignJWT } from "npm:jose@5";

const IAP_KEY = Deno.env.get("APPSTORE_IAP_KEY") ?? "";
const IAP_KEY_ID = Deno.env.get("APPSTORE_IAP_KEY_ID") ?? "";
const ISSUER_ID = Deno.env.get("APPSTORE_ISSUER_ID") ?? "";
const BUNDLE_ID = Deno.env.get("APPSTORE_BUNDLE_ID") ?? "com.ehky.TRAVEL-GUIDED-TOUR";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const svcHeaders = {
  apikey: SERVICE_KEY,
  Authorization: `Bearer ${SERVICE_KEY}`,
  "Content-Type": "application/json",
};

const PRODUCTION_HOST = "https://api.storekit.itunes.apple.com";
const SANDBOX_HOST = "https://api.storekit-sandbox.itunes.apple.com";

function unsafeDecodePayload(jws: string): Record<string, unknown> | null {
  try {
    const part = jws.split(".")[1];
    const b64 = part.replaceAll("-", "+").replaceAll("_", "/");
    return JSON.parse(new TextDecoder().decode(
      Uint8Array.from(atob(b64), (c) => c.charCodeAt(0)),
    ));
  } catch {
    return null;
  }
}

async function appleApiToken(): Promise<string> {
  // Secrets pasted into the dashboard often carry literal "\n" — normalize,
  // and fail with a clear message rather than an opaque throw.
  const pem = IAP_KEY.includes("\\n") ? IAP_KEY.replaceAll("\\n", "\n") : IAP_KEY;
  let key;
  try {
    key = await importPKCS8(pem, "ES256");
  } catch (e) {
    throw new Error(
      `APPSTORE_IAP_KEY is not a usable PKCS#8 .p8 key: ${(e as Error).message}`,
    );
  }
  return await new SignJWT({ bid: BUNDLE_ID })
    .setProtectedHeader({ alg: "ES256", kid: IAP_KEY_ID, typ: "JWT" })
    .setIssuer(ISSUER_ID)
    .setIssuedAt()
    .setExpirationTime("5m")
    .setAudience("appstoreconnect-v1")
    .sign(key);
}

/** Same three-way outcome as record-purchase. `unavailable` matters here for
 *  a different reason: this endpoint's only retry mechanism is Apple's own,
 *  and Apple retries on non-200. Answering 200 when we couldn't reach Apple
 *  would make it give up — dropping a real refund permanently, which quietly
 *  overpays the maker for a sale that was reversed. */
type TransactionLookup =
  | { status: "found"; txn: Record<string, unknown> }
  | { status: "not_found" }
  | { status: "unavailable" };

/** Authoritative transaction record from Apple (production, then sandbox). */
async function fetchTransaction(
  transactionId: string,
): Promise<TransactionLookup> {
  const token = await appleApiToken();
  let sawUpstreamFailure = false;

  for (const host of [PRODUCTION_HOST, SANDBOX_HOST]) {
    let res: Response;
    try {
      res = await fetch(
        `${host}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
        { headers: { Authorization: `Bearer ${token}` } },
      );
    } catch (e) {
      console.error("apple api unreachable", host, (e as Error).message);
      sawUpstreamFailure = true;
      continue;
    }
    // Terminal for this host: not here (404), or the id is malformed (400).
    if (res.status === 404 || res.status === 400) continue;
    if (!res.ok) {
      // 401/403 = our credentials; 5xx/429 = Apple. Either way, retryable.
      console.error("apple api error", host, res.status, await res.text());
      sawUpstreamFailure = true;
      continue;
    }
    const body = await res.json();
    const payload = typeof body?.signedTransactionInfo === "string"
      ? unsafeDecodePayload(body.signedTransactionInfo)
      : null;
    if (payload?.transactionId) return { status: "found", txn: payload };
    sawUpstreamFailure = true; // 200 with a shape we don't understand
  }
  return sawUpstreamFailure ? { status: "unavailable" } : { status: "not_found" };
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") return new Response("ok", { status: 200 });

  let signedPayload = "";
  try {
    const body = await req.json();
    if (typeof body?.signedPayload === "string") signedPayload = body.signedPayload;
  } catch { /* fall through */ }
  if (!signedPayload) return new Response("ok", { status: 200 });

  // Unverified peek — id extraction only; facts come from Apple's API below.
  const note = unsafeDecodePayload(signedPayload);
  const notificationType = String(note?.notificationType ?? "");
  const data = note?.data as Record<string, unknown> | undefined;
  const txnInfo = typeof data?.signedTransactionInfo === "string"
    ? unsafeDecodePayload(data.signedTransactionInfo)
    : null;
  const transactionId = typeof txnInfo?.transactionId === "string"
    ? txnInfo.transactionId
    : null;

  console.log("notification", notificationType, "txn", transactionId ?? "—");

  // Only refund-shaped notifications require action on non-consumables.
  const actionable = ["REFUND", "REVOKE", "REFUND_REVERSED"].includes(
    notificationType,
  );
  if (!actionable || !transactionId) return new Response("ok", { status: 200 });

  const lookup = await fetchTransaction(transactionId);
  if (lookup.status === "unavailable") {
    // 500 on purpose: Apple retries non-200s, and that retry is the ONLY
    // second chance this refund gets. Swallowing it with a 200 would leave
    // the sale counted and the maker overpaid.
    console.error("apple unreachable — asking Apple to retry", transactionId);
    return new Response("upstream unavailable", { status: 500 });
  }
  if (lookup.status === "not_found" || lookup.txn.bundleId !== BUNDLE_ID) {
    console.error("could not confirm transaction with Apple", transactionId);
    return new Response("ok", { status: 200 });
  }
  const txn = lookup.txn;

  // Apple's record decides: revocationDate present → refunded; absent →
  // not refunded (covers REFUND_REVERSED restoring the sale).
  const patch = txn.revocationDate
    ? { refunded_at: new Date(Number(txn.revocationDate)).toISOString() }
    : { refunded_at: null };

  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/purchases?apple_transaction_id=eq.${
      encodeURIComponent(transactionId)
    }`,
    {
      method: "PATCH",
      // count=exact so a zero-row match is visible: PostgREST returns 204
      // either way, and a refund we never recorded would otherwise vanish
      // silently (Apple can notify before the app records the purchase).
      headers: { ...svcHeaders, Prefer: "count=exact" },
      body: JSON.stringify(patch),
    },
  );
  if (!res.ok) {
    console.error("refund update failed", res.status, await res.text());
    return new Response("ok", { status: 200 });
  }
  // Content-Range looks like "0-0/1"; the part after "/" is the row count.
  const matched = Number(
    (res.headers.get("content-range") ?? "").split("/")[1] ?? "0",
  );
  if (!matched) {
    console.error(
      "REFUND for an unrecorded purchase — reconcile by hand",
      { transactionId, notificationType },
    );
  }
  return new Response("ok", { status: 200 });
});
