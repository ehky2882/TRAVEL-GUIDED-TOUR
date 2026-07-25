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
// Response: 200 {ok:true, transactionId}
//           4xx {error}  — terminal; don't retry (bad input, wrong tier,
//                          already redeemed by someone else)
//           503 {error}  — transient (Apple unreachable); DO retry
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
  // A .p8 pasted into the Supabase secrets UI often arrives with literal
  // "\n" instead of real newlines; importPKCS8 would throw an opaque error
  // on every purchase. Normalize, and fail loudly if it's still unusable.
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

/** Outcome of asking Apple about a transaction.
 *  `unavailable` (Apple erroring/unreachable) must NOT be reported to the
 *  client as "not found" — a paying user would see a permanent-looking 4xx
 *  for a transient outage and could drop a real entitlement. */
type TransactionLookup =
  | { status: "found"; txn: AppleTransaction }
  | { status: "not_found" }
  | { status: "unavailable" };

/** Ask Apple for the authoritative record of a transaction. Tries production
 *  first, then sandbox (sandbox purchases 404 on the production host). */
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
    // Terminal for this host: 404 = genuinely not here; 400 = the id itself
    // is malformed (Apple's InvalidTransactionIdError). Neither improves on
    // retry, and the id is client-supplied — treating 400 as "transient"
    // would hand a caller an infinite 503 retry loop.
    if (res.status === 404 || res.status === 400) continue;
    // 401/403 = OUR credentials are wrong; 5xx/429 = Apple. Not a "missing
    // transaction" — flag it so the caller retries rather than being told
    // their purchase doesn't exist.
    if (!res.ok) {
      console.error("apple api error", host, res.status, await res.text());
      sawUpstreamFailure = true;
      continue;
    }
    const body = await res.json();
    // Apple returns { signedTransactionInfo: <JWS> }. It arrived from Apple
    // over TLS under our API credentials, so its payload is authoritative
    // without re-verifying the inner signature.
    const payload = typeof body?.signedTransactionInfo === "string"
      ? unsafeDecodePayload(body.signedTransactionInfo)
      : null;
    if (payload?.transactionId) {
      return { status: "found", txn: payload as unknown as AppleTransaction };
    }
    sawUpstreamFailure = true; // 200 with a shape we don't understand
  }
  return sawUpstreamFailure ? { status: "unavailable" } : { status: "not_found" };
}

/** Verify the caller's Supabase session server-side and return their uid.
 *  Deliberately does NOT just decode the JWT: that would be safe only while
 *  the dashboard's "Verify JWT" toggle is ON, and its sibling function ships
 *  with instructions to turn that toggle OFF. One misclick must not make
 *  user_id attacker-chosen, so we ask GoTrue who this token belongs to. */
async function verifiedUserId(bearer: string): Promise<string | null> {
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${bearer}` },
    });
    if (!res.ok) return null;
    const user = await res.json();
    return typeof user?.id === "string" ? user.id : null;
  } catch {
    return null;
  }
}

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") return json(405, { error: "POST only" });
  if (!IAP_KEY || !IAP_KEY_ID || !ISSUER_ID) {
    return json(500, { error: "App Store API secrets not configured" });
  }

  // Who is buying? Verified against GoTrue, not decoded from the token —
  // see verifiedUserId().
  const auth = req.headers.get("Authorization") ?? "";
  const userJWT = auth.replace(/^Bearer\s+/i, "");
  const userId = userJWT ? await verifiedUserId(userJWT) : null;
  if (!userId) return json(401, { error: "sign in required" });

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
  // tourId goes into a service-role query string below — insist on a UUID
  // so it can't smuggle extra PostgREST parameters.
  if (typeof tourId !== "string" || !UUID_RE.test(tourId)) {
    return json(400, { error: "tourId must be a uuid" });
  }
  if (typeof clientTxnId !== "string") {
    return json(400, { error: "signedTransaction required" });
  }

  // The authoritative record, straight from Apple.
  const lookup = await fetchTransaction(clientTxnId);
  if (lookup.status === "unavailable") {
    // Transient (or our credentials are wrong) — tell the client to retry
    // rather than implying the purchase isn't real.
    return json(503, { error: "could not reach Apple — retry shortly" });
  }
  if (lookup.status === "not_found") {
    return json(422, { error: "transaction not found with Apple" });
  }
  const txn = lookup.txn;
  if (txn.bundleId !== BUNDLE_ID) {
    return json(422, { error: "transaction is for a different app" });
  }
  const tierMatch = TIER_RE.exec(txn.productId ?? "");
  if (!tierMatch) return json(422, { error: "not a tour tier product" });
  if (txn.revocationDate) return json(422, { error: "transaction was refunded" });
  const tierCents = parseInt(tierMatch[1], 10);

  // The tour must exist and be PAID AT EXACTLY THIS TIER; derive maker_id
  // server-side (never from the client).
  //
  // This tier check is what binds the receipt to the tour. The tier products
  // are reusable across every paid tour, so without it a genuine $0.99
  // receipt could be re-sent with any tourId — unlocking a $19.99 tour while
  // crediting its maker 99¢. Apple can't catch that; only we can.
  //
  // status=published too: this is a service-role read, so without it a
  // draft or taken-down tour would be purchasable by anyone who knows its id.
  const tourRes = await fetch(
    `${SUPABASE_URL}/rest/v1/tours?id=eq.${encodeURIComponent(tourId)}` +
      `&status=eq.published&select=id,maker_id,price_tier&limit=1`,
    { headers: svcHeaders },
  );
  if (!tourRes.ok) {
    console.error("tour lookup failed", tourRes.status, await tourRes.text());
    return json(503, { error: "lookup failed — retry shortly" });
  }
  const tours = await tourRes.json();
  const tour = Array.isArray(tours) ? tours[0] : null;
  if (!tour) return json(422, { error: "unknown tour" });
  if (tour.price_tier === null || tour.price_tier === undefined) {
    return json(422, { error: "tour is free — nothing to purchase" });
  }
  if (tour.price_tier !== tierCents) {
    console.error(
      "tier mismatch", { tourId, tourTier: tour.price_tier, paidTier: tierCents },
    );
    return json(422, { error: "receipt does not match this tour's price" });
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
        maker_id: tour.maker_id,
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

  // ignore-duplicates means a conflicting row was left untouched, and
  // return=minimal can't tell us whose it is. Read it back: if the stored
  // row belongs to someone else (an Apple id can only be redeemed once), the
  // caller is NOT entitled and must not be told it succeeded.
  const check = await fetch(
    `${SUPABASE_URL}/rest/v1/purchases?apple_transaction_id=eq.${
      encodeURIComponent(txn.transactionId)
    }&select=user_id,tour_id&limit=1`,
    { headers: svcHeaders },
  );
  if (check.ok) {
    const rows = await check.json();
    const row = Array.isArray(rows) ? rows[0] : null;
    if (row && (row.user_id !== userId || row.tour_id !== tourId)) {
      console.error("transaction already recorded for a different buyer/tour", {
        transactionId: txn.transactionId,
      });
      return json(409, { error: "this transaction is already redeemed" });
    }
  }
  return json(200, { ok: true, transactionId: txn.transactionId });
});
