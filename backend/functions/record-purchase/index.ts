// Atlas — record a paid-tour purchase (Supabase Edge Function)
//
// The write path for the `purchases` table (docs/paid-tours-design.md §attribution).
// After StoreKit's payment sheet succeeds, the app POSTs the signed transaction
// plus the tour id here. We do NOT trust the client's JWS: we extract the
// transaction id from it, then ask Apple's App Store Server API for the
// authoritative transaction record (over TLS, under our signed API JWT) and
// record THAT. One inserted row = the buyer's entitlement + the maker's
// ledger entry. The UNIQUE apple_transaction_id makes replays idempotent, so
// the app can safely re-send from StoreKit transaction history after a dead
// spot.
//
// Request (from the signed-in app):
//   POST  Authorization: Bearer <user JWT>   (Verify JWT stays ON)
//   { "tourId": "<uuid>", "signedTransaction": "<StoreKit jwsRepresentation>" }
// Response: 200 {ok:true, transactionId} | 4xx {error}
//
// Setup (owner, dashboards — hand-held in the session notes):
//   1. App Store Connect → Users and Access → Integrations → In-App Purchase →
//      generate an API key → download the .p8 ONCE.
//   2. Supabase → Edge Functions → deploy this as `record-purchase`
//      (Verify JWT ON — the default).
//   3. Secrets (Edge Functions → Secrets):
//        APPSTORE_IAP_KEY        = full contents of the .p8 file
//        APPSTORE_IAP_KEY_ID     = the key's ID (10 chars)
//        APPSTORE_ISSUER_ID      = Issuer ID shown on the keys page
//        APPSTORE_BUNDLE_ID      = com.ehky.TRAVEL-GUIDED-TOUR

import { importPKCS8, SignJWT } from "npm:jose@5";

const IAP_KEY = Deno.env.get("APPSTORE_IAP_KEY") ?? "";
const IAP_KEY_ID = Deno.env.get("APPSTORE_IAP_KEY_ID") ?? "";
const ISSUER_ID = Deno.env.get("APPSTORE_ISSUER_ID") ?? "";
const BUNDLE_ID = Deno.env.get("APPSTORE_BUNDLE_ID") ?? "com.ehky.TRAVEL-GUIDED-TOUR";

// Auto-injected into every Supabase Edge Function.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";

const svcHeaders = {
  apikey: SERVICE_KEY,
  Authorization: `Bearer ${SERVICE_KEY}`,
  "Content-Type": "application/json",
};

const PRODUCTION_HOST = "https://api.storekit.itunes.apple.com";
const SANDBOX_HOST = "https://api.storekit-sandbox.itunes.apple.com";

/** The 10 tier product ids (Phase 1) → price in cents. */
const TIER_RE = /^tour\.tier\.(\d{3,4})$/;

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** Decode a JWS/JWT payload WITHOUT verifying. Only ever used to extract an
 *  id that is then confirmed against Apple's API — never as a source of
 *  recorded facts. */
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

/** Mint the App Store Server API JWT (ES256, ≤5 min). */
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

interface AppleTransaction {
  transactionId: string;
  originalTransactionId?: string;
  bundleId?: string;
  productId?: string;
  type?: string;
  purchaseDate?: number; // ms since epoch
  revocationDate?: number;
  environment?: string; // "Production" | "Sandbox"
}

/** Ask Apple for the authoritative record of a transaction. Tries production
 *  first, then sandbox (sandbox purchases 404 on the production host). */
async function fetchTransaction(
  transactionId: string,
): Promise<AppleTransaction | null> {
  const token = await appleApiToken();
  for (const host of [PRODUCTION_HOST, SANDBOX_HOST]) {
    const res = await fetch(
      `${host}/inApps/v1/transactions/${encodeURIComponent(transactionId)}`,
      { headers: { Authorization: `Bearer ${token}` } },
    );
    if (res.status === 404 || res.status === 401) continue; // try next host
    if (!res.ok) {
      console.error("apple api error", host, res.status, await res.text());
      continue;
    }
    const body = await res.json();
    // Apple returns { signedTransactionInfo: <JWS> }. It arrived from Apple
    // over TLS under our API credentials, so its payload is authoritative
    // without re-verifying the inner signature.
    const payload = typeof body?.signedTransactionInfo === "string"
      ? unsafeDecodePayload(body.signedTransactionInfo)
      : null;
    if (payload?.transactionId) return payload as unknown as AppleTransaction;
  }
  return null;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") return json(405, { error: "POST only" });
  if (!IAP_KEY || !IAP_KEY_ID || !ISSUER_ID) {
    return json(500, { error: "App Store API secrets not configured" });
  }

  // Who is buying? Verify JWT is ON, so the gateway already validated the
  // user token — decoding `sub` from it is safe.
  const auth = req.headers.get("Authorization") ?? "";
  const userJWT = auth.replace(/^Bearer\s+/i, "");
  const userId = unsafeDecodePayload(userJWT)?.sub;
  if (typeof userId !== "string" || !userId) {
    return json(401, { error: "sign in required" });
  }

  let body: { tourId?: string; signedTransaction?: string };
  try {
    body = await req.json();
  } catch {
    return json(400, { error: "bad JSON" });
  }
  const tourId = body.tourId;
  const clientTxnId = body.signedTransaction
    ? unsafeDecodePayload(body.signedTransaction)?.transactionId
    : null;
  if (!tourId || typeof clientTxnId !== "string") {
    return json(400, { error: "tourId and signedTransaction required" });
  }

  // The authoritative record, straight from Apple.
  const txn = await fetchTransaction(clientTxnId);
  if (!txn) return json(422, { error: "transaction not found with Apple" });
  if (txn.bundleId !== BUNDLE_ID) {
    return json(422, { error: "transaction is for a different app" });
  }
  const tierMatch = TIER_RE.exec(txn.productId ?? "");
  if (!tierMatch) return json(422, { error: "not a tour tier product" });
  if (txn.revocationDate) return json(422, { error: "transaction was refunded" });
  const tierCents = parseInt(tierMatch[1], 10);

  // The tour must exist; derive maker_id server-side (never from the client).
  const tourRes = await fetch(
    `${SUPABASE_URL}/rest/v1/tours?id=eq.${tourId}&select=id,maker_id&limit=1`,
    { headers: svcHeaders },
  );
  const tours = tourRes.ok ? await tourRes.json() : [];
  if (!Array.isArray(tours) || !tours[0]) {
    return json(422, { error: "unknown tour" });
  }

  // Idempotent insert: a replayed transaction id is a no-op, not an error.
  const insertRes = await fetch(
    `${SUPABASE_URL}/rest/v1/purchases?on_conflict=apple_transaction_id`,
    {
      method: "POST",
      headers: {
        ...svcHeaders,
        Prefer: "resolution=ignore-duplicates,return=minimal",
      },
      body: JSON.stringify({
        user_id: userId,
        tour_id: tourId,
        maker_id: tours[0].maker_id,
        price_tier: tierCents,
        apple_transaction_id: txn.transactionId,
        apple_original_transaction_id: txn.originalTransactionId ?? null,
        apple_environment: txn.environment === "Sandbox" ? "Sandbox" : "Production",
        purchased_at: txn.purchaseDate
          ? new Date(txn.purchaseDate).toISOString()
          : new Date().toISOString(),
      }),
    },
  );
  if (!insertRes.ok) {
    console.error("insert failed", insertRes.status, await insertRes.text());
    return json(500, { error: "recording failed — retry later" });
  }
  return json(200, { ok: true, transactionId: txn.transactionId });
});
