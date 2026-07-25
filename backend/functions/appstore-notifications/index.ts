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
// Always returns 200 quickly (Apple retries non-200s aggressively); failures
// are logged for manual reconciliation (design doc: monthly reconciliation
// vs Apple's per-tier unit counts).

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
  const key = await importPKCS8(IAP_KEY, "ES256");
  return await new SignJWT({ bid: BUNDLE_ID })
    .setProtectedHeader({ alg: "ES256", kid: IAP_KEY_ID, typ: "JWT" })
    .setIssuer(ISSUER_ID)
    .setIssuedAt()
    .setExpirationTime("5m")
    .setAudience("appstoreconnect-v1")
    .sign(key);
}

/** Authoritative transaction record from Apple (production, then sandbox). */
async function fetchTransaction(
  transactionId: string,
): Promise<Record<string, unknown> | null> {
  const token = await appleApiToken();
  for (const host of [PRODUCTION_HOST, SANDBOX_HOST]) {
    const res = await fetch(
      `${host}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (res.status === 404 || res.status === 401) continue;
    if (!res.ok) {
      console.error("apple api error", host, res.status, await res.text());
      continue;
    }
    const body = await res.json();
    const payload = typeof body?.signedTransactionInfo === "string"
      ? unsafeDecodePayload(body.signedTransactionInfo)
      : null;
    if (payload?.transactionId) return payload;
  }
  return null;
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

  const txn = await fetchTransaction(transactionId);
  if (!txn || txn.bundleId !== BUNDLE_ID) {
    console.error("could not confirm transaction with Apple", transactionId);
    return new Response("ok", { status: 200 });
  }

  // Apple's record decides: revocationDate present → refunded; absent →
  // not refunded (covers REFUND_REVERSED restoring the sale).
  const patch = txn.revocationDate
    ? { refunded_at: new Date(Number(txn.revocationDate)).toISOString() }
    : { refunded_at: null };

  const res = await fetch(
    `${SUPABASE_URL}/rest/v1/purchases?apple_transaction_id=eq.${
      encodeURIComponent(transactionId)
    }`,
    { method: "PATCH", headers: svcHeaders, body: JSON.stringify(patch) },
  );
  if (!res.ok) {
    console.error("refund update failed", res.status, await res.text());
  }
  return new Response("ok", { status: 200 });
});
