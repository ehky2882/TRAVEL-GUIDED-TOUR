import Foundation
import Supabase

/// Files a "Report a concern" into the Supabase `reports` table.
///
/// Anyone may report — anonymous or signed-in (the table's RLS is
/// `insert with check (true)`); only admins can read/triage. **The owner's
/// email is deliberately NOT in the app** — notification happens server-side
/// (the `notify-moderation` Edge Function emails on each new report), so the
/// recipient address never ships in the client binary.
struct ReportsService {
    var client: SupabaseClient = SupabaseClientProvider.shared

    /// Insert a report. `tourId` is set for tour reports (maker reports leave it
    /// nil and carry the maker id in `details`). `reporterId` is the signed-in
    /// user's id, or nil when anonymous.
    func submit(tourId: UUID?, reason: String, details: String?, reporterId: UUID?) async throws {
        struct ReportInsert: Encodable {
            let tour_id: String?
            let reporter_user_id: String?
            let reason: String
            let details: String?
        }
        let trimmed = details?.trimmingCharacters(in: .whitespacesAndNewlines)
        let row = ReportInsert(
            tour_id: tourId?.uuidString.lowercased(),
            reporter_user_id: reporterId?.uuidString.lowercased(),
            reason: reason,
            details: (trimmed?.isEmpty ?? true) ? nil : trimmed
        )
        try await client.from("reports").insert(row).execute()
    }
}
