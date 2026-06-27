import Foundation
import Supabase

/// The shared supabase-swift client, configured from `SupabaseConfig`.
///
/// Used by `AuthService` (sign-in/out + session) and, later, the consumer-sync
/// and maker-authoring features. The **catalog read deliberately does NOT go
/// through this client** — it stays on its own lightweight `URLSession` fetcher
/// in `RemoteCatalogLoader` (the read needs no SDK). So this client exists
/// purely for the auth/session machinery that supabase-swift handles well
/// (secure token storage, automatic refresh, OAuth/Apple flows in later steps).
enum SupabaseClientProvider {
    static let shared = SupabaseClient(
        supabaseURL: SupabaseConfig.projectURL,
        supabaseKey: SupabaseConfig.anonKey
    )
}
