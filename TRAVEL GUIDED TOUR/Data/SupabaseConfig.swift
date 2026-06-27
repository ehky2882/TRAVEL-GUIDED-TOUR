import Foundation

/// Connection details for the Supabase backend (project "Dozent").
///
/// V2 Step 2 cutover: the app now reads its catalog from the `get_catalog`
/// Postgres RPC instead of (only) the gh-pages `Tours.json`. gh-pages is kept
/// as an automatic fallback — see `RemoteCatalogLoader`.
///
/// The **anon (publishable) key is client-safe by design** — it carries no
/// privileges beyond what the table RLS policies grant the `anon` role
/// (public read of `published` rows). It is meant to ship in client apps.
/// The **service_role** key must NEVER appear here or anywhere in the app.
///
/// Values come from the Supabase Dashboard:
/// - Base URL: Settings → Data API → Project URL (`https://<ref>.supabase.co`)
/// - Anon key: Settings → API → `anon` / `publishable` key
enum SupabaseConfig {
    /// Project base URL.
    static let projectURL = URL(string: "https://apkcihljybvuyuzpbnqd.supabase.co")!

    /// Public anon/publishable key. Client-safe (RLS-gated). Not the secret key.
    static let anonKey = "sb_publishable_KRAiUnT3z6yjhvPmXO9CIQ_OKPdtdKf"

    /// The `get_catalog()` RPC endpoint that returns the full `{makers, tours}`
    /// document in the exact shape `ToursData` decodes.
    static var catalogRPCURL: URL {
        projectURL
            .appendingPathComponent("rest")
            .appendingPathComponent("v1")
            .appendingPathComponent("rpc")
            .appendingPathComponent("get_catalog")
    }

    /// Whether real credentials have been filled in. When false, the catalog
    /// loader skips the Supabase source entirely and reads gh-pages only, so a
    /// missing key degrades gracefully rather than breaking the app.
    static var isConfigured: Bool {
        !anonKey.isEmpty
            && anonKey != "PASTE_ANON_KEY_HERE"
            && projectURL.host?.hasSuffix("supabase.co") == true
            && projectURL.host != "YOUR_PROJECT_REF.supabase.co"
    }
}
