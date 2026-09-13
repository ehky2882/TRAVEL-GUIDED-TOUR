// Atlas — delete the caller's OWN account (Supabase Edge Function)
//
// Settings → Account → Delete account. Apple App Review Guideline 5.1.1(v)
// requires that an app offering account creation lets people start deleting
// the account from inside the app; the privacy policy (site/privacy/) already
// promises what that means:
//
//   "Delete your account and we remove your profile, synced library and
//    creator content; records we must keep for legal or financial reasons are
//    retained in minimal form."
//
// 🔴 WHO CAN TRIGGER THIS: ONLY THE ACCOUNT HOLDER.
// The standing decision is that we never delete anyone's account; this is a
// person deleting their own. So the user id is NEVER read from the request.
// It comes from the caller's session, verified against GoTrue (not merely
// decoded), and every step below acts on that id alone. There is no admin
// mode and no parameter that names a user. Keep it that way.
//
// Request (from the signed-in app):
//   POST  Authorization: Bearer <user JWT>   (Verify JWT stays ON)
//   { "appleAuthorizationCode"?: "<fresh code from Sign in with Apple>" }
// Response: 200 {ok:true, removedTours, keptTours}
//           401 {error}  — not signed in / session expired
//           5xx {error}  — did not finish; SAFE TO RETRY (every step is
//                          idempotent and the login is deleted last)
//
// Steps, in this order on purpose — the login goes LAST, so a failure at any
// earlier step leaves the person signed in and able to retry:
//   1. public.delete_my_account_content(), called WITH THE USER'S OWN TOKEN,
//      so it runs as them and acts on auth.uid(). Deletes their unsold tours,
//      anonymises their creator page. (backend/account_deletion.sql)
//   2. Their uploaded files: everything under {maker_id}/ in tour-audio and
//      tour-images, except the folders of tours somebody bought.
//   3. Sign in with Apple: revoke Dozent's tokens (Apple requires it), when a
//      code was sent and the secrets below are set. Best effort.
//   4. Delete the auth user. The schema's cascades remove profile, library,
//      saved places, lists, follows; purchases survive with user_id nulled.
//   5. Creator page: delete the row if nothing restricts it; otherwise release
//      the username (the row is already anonymised).
//   6. Rebuild the catalogue snapshot so the tours and name stop being served.
//
// Setup (owner, dashboards):
//   1. SQL Editor: run backend/account_deletion.sql.
//   2. Edge Functions → deploy this as `delete-account` (Verify JWT ON).
//   3. Optional but Apple-required for Sign in with Apple accounts — Secrets:
//        APPLE_SIWA_KEY      = full contents of a "Sign in with Apple" .p8 key
//        APPLE_SIWA_KEY_ID   = that key's ID (10 chars)
//        APPLE_TEAM_ID       = CPC7M72JTP
//      Without them deletion still works; the Apple revocation is skipped and
//      logged.

import { importPKCS8, SignJWT } from "npm:jose@5";

// Auto-injected into every Supabase Edge Function.
const SUPABASE_URL = Deno.env.get("SUPABASE_URL") ?? "";
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
const ANON_KEY = Deno.env.get("SUPABASE_ANON_KEY") ?? "";

const SIWA_KEY = Deno.env.get("APPLE_SIWA_KEY") ?? "";
const SIWA_KEY_ID = Deno.env.get("APPLE_SIWA_KEY_ID") ?? "";
const TEAM_ID = Deno.env.get("APPLE_TEAM_ID") ?? "CPC7M72JTP";
// A native app's Sign in with Apple client id is its bundle id.
const SIWA_CLIENT_ID = Deno.env.get("APPLE_SIWA_CLIENT_ID") ?? "com.ehky.TRAVEL-GUIDED-TOUR";

const BUCKETS = ["tour-audio", "tour-images"];

const svcHeaders = {
  apikey: SERVICE_KEY,
  Authorization: `Bearer ${SERVICE_KEY}`,
  "Content-Type": "application/json",
};

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function json(status: number, body: unknown): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

/** The caller's user id, asked of GoTrue rather than decoded from the token —
 *  same reasoning as record-purchase: one misclick on the dashboard's Verify
 *  JWT toggle must never make the id attacker-chosen. */
async function verifiedUserId(bearer: string): Promise<string | null> {
  try {
    const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
      headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${bearer}` },
    });
    if (!res.ok) return null;
    const user = await res.json();
    return typeof user?.id === "string" && UUID_RE.test(user.id) ? user.id : null;
  } catch {
    return null;
  }
}

// ---------------------------------------------------------------------------
// Step 2 — uploaded files
// ---------------------------------------------------------------------------

interface StorageEntry {
  name: string;
  id: string | null; // null = a folder
}

/** Every file path under `prefix/`, recursively. Throws on any failure: a
 *  partial listing must not be mistaken for "nothing left". */
async function listFiles(bucket: string, prefix: string, depth = 0): Promise<string[]> {
  if (depth > 4) return [];
  const out: string[] = [];
  const pageSize = 1000;
  for (let offset = 0; ; offset += pageSize) {
    const res = await fetch(`${SUPABASE_URL}/storage/v1/object/list/${bucket}`, {
      method: "POST",
      headers: svcHeaders,
      body: JSON.stringify({ prefix: `${prefix}/`, limit: pageSize, offset }),
    });
    if (!res.ok) {
      throw new Error(`list ${bucket}/${prefix}: ${res.status} ${await res.text()}`);
    }
    const entries = (await res.json()) as StorageEntry[];
    for (const e of entries) {
      const path = `${prefix}/${e.name}`;
      if (e.id === null) out.push(...await listFiles(bucket, path, depth + 1));
      else out.push(path);
    }
    if (entries.length < pageSize) break;
  }
  return out;
}

/** Remove a creator's files, keeping the folder of every tour that was bought. */
async function purgeMakerFiles(makerId: string, keptTourIds: Set<string>): Promise<number> {
  let removed = 0;
  for (const bucket of BUCKETS) {
    const files = (await listFiles(bucket, makerId)).filter((path) => {
      // {maker}/{tour}/{file} — keep it if {tour} is a tour somebody bought.
      const second = path.split("/")[1]?.toLowerCase();
      return !(second && keptTourIds.has(second));
    });
    for (let i = 0; i < files.length; i += 500) {
      const chunk = files.slice(i, i + 500);
      const res = await fetch(`${SUPABASE_URL}/storage/v1/object/${bucket}`, {
        method: "DELETE",
        headers: svcHeaders,
        body: JSON.stringify({ prefixes: chunk }),
      });
      if (!res.ok) {
        throw new Error(`remove from ${bucket}: ${res.status} ${await res.text()}`);
      }
      removed += chunk.length;
    }
  }
  return removed;
}

// ---------------------------------------------------------------------------
// Step 3 — Sign in with Apple token revocation
// https://developer.apple.com/documentation/sign_in_with_apple/revoke_tokens
// ---------------------------------------------------------------------------

async function appleClientSecret(): Promise<string> {
  // Same newline normalisation as record-purchase: a .p8 pasted into the
  // secrets UI often arrives with literal "\n".
  const pem = SIWA_KEY.includes("\\n") ? SIWA_KEY.replaceAll("\\n", "\n") : SIWA_KEY;
  const key = await importPKCS8(pem, "ES256");
  return await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: SIWA_KEY_ID })
    .setIssuer(TEAM_ID)
    .setSubject(SIWA_CLIENT_ID)
    .setAudience("https://appleid.apple.com")
    .setIssuedAt()
    .setExpirationTime("5m")
    .sign(key);
}

async function revokeApple(code: string): Promise<string> {
  if (!SIWA_KEY || !SIWA_KEY_ID) return "skipped: APPLE_SIWA_KEY / APPLE_SIWA_KEY_ID not set";
  try {
    const secret = await appleClientSecret();
    const tokenRes = await fetch("https://appleid.apple.com/auth/token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: SIWA_CLIENT_ID,
        client_secret: secret,
        code,
        grant_type: "authorization_code",
      }),
    });
    if (!tokenRes.ok) return `failed: token exchange ${tokenRes.status} ${await tokenRes.text()}`;
    const tokens = await tokenRes.json();
    const token = tokens?.refresh_token ?? tokens?.access_token;
    if (typeof token !== "string") return "failed: Apple returned no token";
    const revokeRes = await fetch("https://appleid.apple.com/auth/revoke", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        client_id: SIWA_CLIENT_ID,
        client_secret: secret,
        token,
        token_type_hint: tokens?.refresh_token ? "refresh_token" : "access_token",
      }),
    });
    return revokeRes.ok ? "revoked" : `failed: revoke ${revokeRes.status} ${await revokeRes.text()}`;
  } catch (e) {
    return `failed: ${(e as Error).message}`;
  }
}

// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") return json(405, { error: "POST only" });

  // Who is deleting? Only ever the verified caller.
  const auth = req.headers.get("Authorization") ?? "";
  const userJWT = auth.replace(/^Bearer\s+/i, "");
  const userId = userJWT ? await verifiedUserId(userJWT) : null;
  if (!userId) return json(401, { error: "Please sign in again, then try deleting your account." });

  // The body may carry ONE thing: a Sign in with Apple authorization code.
  // Nothing in it can name a user.
  let appleCode: string | null = null;
  try {
    const body = await req.json();
    if (typeof body?.appleAuthorizationCode === "string" && body.appleAuthorizationCode.length < 4096) {
      appleCode = body.appleAuthorizationCode;
    }
  } catch {
    // An empty body is fine.
  }

  // 1. Database content, AS THE USER (auth.uid() inside the function).
  const rpc = await fetch(`${SUPABASE_URL}/rest/v1/rpc/delete_my_account_content`, {
    method: "POST",
    headers: {
      apikey: ANON_KEY || SERVICE_KEY,
      Authorization: `Bearer ${userJWT}`,
      "Content-Type": "application/json",
    },
    body: "{}",
  });
  if (!rpc.ok) {
    console.error("delete_my_account_content failed", userId, rpc.status, await rpc.text());
    return json(500, { error: "We couldn't delete your account just now. Please try again." });
  }
  const summary = await rpc.json() as {
    makerIds?: string[];
    removedTourIds?: string[];
    keptTourIds?: string[];
  };
  const makerIds = (summary.makerIds ?? []).filter((id) => UUID_RE.test(id));
  const keptTourIds = new Set((summary.keptTourIds ?? []).map((id) => id.toLowerCase()));

  // 2. Files. Abort before touching the login if this fails, so a retry
  //    finds everything it needs (the maker rows still point at this user).
  let filesRemoved = 0;
  try {
    for (const makerId of makerIds) {
      filesRemoved += await purgeMakerFiles(makerId.toLowerCase(), keptTourIds);
    }
  } catch (e) {
    console.error("file purge failed", userId, (e as Error).message);
    return json(503, { error: "We couldn't finish removing your uploads. Please try again." });
  }

  // 3. Apple.
  const apple = appleCode ? await revokeApple(appleCode) : "no code sent";

  // 4. The login itself.
  const del = await fetch(`${SUPABASE_URL}/auth/v1/admin/users/${userId}`, {
    method: "DELETE",
    headers: svcHeaders,
  });
  if (!del.ok && del.status !== 404) {
    console.error("auth delete failed", userId, del.status, await del.text());
    return json(500, { error: "We couldn't finish deleting your account. Please try again." });
  }

  // 5. Creator pages. Deleted outright unless a bought tour (or a purchase or
  //    payout record) restricts it — then it stays as the anonymised "Former
  //    creator", and its username is released. `user_id=is.null` confirms the
  //    login is really gone before anything here runs.
  for (const makerId of makerIds) {
    const gone = await fetch(
      `${SUPABASE_URL}/rest/v1/makers?id=eq.${makerId}&user_id=is.null`,
      { method: "DELETE", headers: { ...svcHeaders, Prefer: "return=minimal" } },
    );
    if (gone.ok) continue;
    const handle = `former.${makerId.replaceAll("-", "").slice(0, 12)}`;
    const patch = await fetch(
      `${SUPABASE_URL}/rest/v1/makers?id=eq.${makerId}&user_id=is.null`,
      {
        method: "PATCH",
        headers: { ...svcHeaders, Prefer: "return=minimal" },
        body: JSON.stringify({ handle }),
      },
    );
    if (!patch.ok) {
      // Not fatal: the row carries no personal name, photo, bio or links.
      console.error("maker handle release failed", makerId, patch.status, await patch.text());
    }
  }

  // 6. Stop serving what was removed. Not fatal — the next content merge
  //    rebuilds the snapshot anyway — but log it.
  if (makerIds.length > 0) {
    const refresh = await fetch(`${SUPABASE_URL}/rest/v1/rpc/refresh_catalog_snapshot`, {
      method: "POST",
      headers: svcHeaders,
      body: "{}",
    });
    if (!refresh.ok) {
      console.error("catalog snapshot refresh failed", refresh.status, await refresh.text());
    }
  }

  console.log("account deleted", {
    removedTours: summary.removedTourIds?.length ?? 0,
    keptTours: keptTourIds.size,
    filesRemoved,
    apple,
  });
  return json(200, {
    ok: true,
    removedTours: summary.removedTourIds?.length ?? 0,
    keptTours: keptTourIds.size,
  });
});
