import Foundation
import CoreLocation
import Observation
import Supabase

/// A tour owned by the signed-in maker, with its lifecycle status — the unit
/// shown on the own-profile "My tours" feed (drafts + in-review + published).
struct MakerTour: Identifiable, Hashable {
    let tour: Tour
    let status: TourStatus
    var id: UUID { tour.id }
}

/// Authoring service for the signed-in maker's own tours (V2 Step 4, increment
/// 2b). Loads the maker's tours across ALL statuses (the public catalog only
/// carries published ones) and creates new `draft` tours.
///
/// A "draft" single-stop tour is one `tours` row (status `draft`, empty
/// hero/audio, 0 duration) + one `stops` row (order 0, geofenced, the pin +
/// radius). Audio / photos / transcript / submit-for-review land in later
/// increments. RLS (`tours_owner_insert` requires `owns_maker(maker_id)` and a
/// non-published status; `stops_owner_write` requires `owns_tour`) already
/// applied — no owner setup.
@MainActor
@Observable
final class MakerTourService {
    /// The signed-in maker's own tours (all statuses), newest first.
    private(set) var myTours: [MakerTour] = []

    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseClientProvider.shared) {
        self.client = client
    }

    /// Clear when signed out or when the profile has no maker row yet.
    func clear() { myTours = [] }

    /// Load the maker's own tours (all statuses). Owner-scoped by RLS
    /// (`tours_owner_select`), filtered to this maker. A failure leaves the
    /// current list unchanged.
    func loadMyTours(makerId: UUID) async {
        do {
            let rows: [TourRow] = try await client
                .from("tours")
                .select()
                .eq("maker_id", value: makerId.uuidString.lowercased())
                .order("created_at", ascending: false)
                .execute()
                .value
            myTours = rows.map { $0.asMakerTour }
        } catch {
            // Keep whatever we have; the profile still renders.
        }
    }

    /// Create a new single-stop `draft` tour under `makerId`, returning its id.
    /// Inserts the `tours` row first (so the stop's `owns_tour` check passes),
    /// then the `stops` row. Optimistically prepends it to `myTours`.
    @discardableResult
    func createDraftTour(
        makerId: UUID,
        title: String,
        shortDescription: String,
        longDescription: String,
        category: TourCategory,
        tags: [String],
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Int
    ) async throws -> UUID {
        let tourId = UUID()
        let stopId = UUID()
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        let tourRow = NewTourRow(
            id: tourId.uuidString.lowercased(),
            title: cleanTitle,
            shortDescription: shortDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            longDescription: longDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            makerId: makerId.uuidString.lowercased(),
            heroImageURL: "",
            kind: TourKind.single.rawValue,
            totalDurationSeconds: 0,
            centroidLatitude: coordinate.latitude,
            centroidLongitude: coordinate.longitude,
            primaryCategory: category.rawValue,
            tags: tags,
            status: TourStatus.draft.rawValue
        )
        try await client.from("tours").insert(tourRow, returning: .minimal).execute()

        let stopRow = NewStopRow(
            id: stopId.uuidString.lowercased(),
            tourId: tourId.uuidString.lowercased(),
            order: 0,
            title: cleanTitle,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            audioURL: "",
            audioDurationSeconds: 0,
            triggerMode: "geofenced",
            triggerRadiusMeters: radiusMeters
        )
        try await client.from("stops").insert(stopRow, returning: .minimal).execute()

        // Optimistic insert so it shows immediately with a DRAFT badge.
        let tour = tourRow.asTour(stops: [])
        myTours.insert(MakerTour(tour: tour, status: .draft), at: 0)
        return tourId
    }
}

// MARK: - DTOs

/// Insert payload for a new draft `tours` row (snake_case columns).
private struct NewTourRow: Encodable {
    let id: String
    let title: String
    let shortDescription: String
    let longDescription: String
    let makerId: String
    let heroImageURL: String
    let kind: String
    let totalDurationSeconds: Int
    let centroidLatitude: Double
    let centroidLongitude: Double
    let primaryCategory: String
    let tags: [String]
    let status: String

    enum CodingKeys: String, CodingKey {
        case id, title, kind, tags, status
        case shortDescription = "short_description"
        case longDescription = "long_description"
        case makerId = "maker_id"
        case heroImageURL = "hero_image_url"
        case totalDurationSeconds = "total_duration_seconds"
        case centroidLatitude = "centroid_latitude"
        case centroidLongitude = "centroid_longitude"
        case primaryCategory = "primary_category"
    }

    /// Build the in-memory `Tour` for the optimistic feed insert.
    func asTour(stops: [Stop]) -> Tour {
        Tour(
            id: UUID(uuidString: id) ?? UUID(),
            title: title,
            shortDescription: shortDescription,
            longDescription: longDescription,
            makerId: UUID(uuidString: makerId) ?? UUID(),
            heroImageURL: heroImageURL,
            additionalImageURLs: nil,
            kind: TourKind(rawValue: kind) ?? .single,
            stops: stops,
            introAudioURL: nil,
            totalDurationSeconds: totalDurationSeconds,
            walkingDistanceMeters: nil,
            centroidLatitude: centroidLatitude,
            centroidLongitude: centroidLongitude,
            city: nil,
            primaryCategory: TourCategory(rawValue: primaryCategory) ?? category,
            tags: tags,
            priceUSD: 0,
            createdAt: nil
        )
    }

    private var category: TourCategory { .hiddenGems }
}

/// Insert payload for a new `stops` row (snake_case columns).
private struct NewStopRow: Encodable {
    let id: String
    let tourId: String
    let order: Int
    let title: String
    let latitude: Double
    let longitude: Double
    let audioURL: String
    let audioDurationSeconds: Int
    let triggerMode: String
    let triggerRadiusMeters: Int

    enum CodingKeys: String, CodingKey {
        case id, order, title, latitude, longitude
        case tourId = "tour_id"
        case audioURL = "audio_url"
        case audioDurationSeconds = "audio_duration_seconds"
        case triggerMode = "trigger_mode"
        case triggerRadiusMeters = "trigger_radius_meters"
    }
}

/// Read payload for a `tours` table row (a direct select returns snake_case,
/// unlike the camelCase `get_catalog` RPC). Only the fields the feed needs.
private struct TourRow: Decodable {
    let id: UUID
    let title: String
    let shortDescription: String
    let longDescription: String
    let makerId: UUID
    let heroImageURL: String
    let additionalImageURLs: [String]?
    let kind: String
    let totalDurationSeconds: Int
    let centroidLatitude: Double
    let centroidLongitude: Double
    let city: String?
    let primaryCategory: String
    let tags: [String]
    let status: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, kind, tags, status, city
        case shortDescription = "short_description"
        case longDescription = "long_description"
        case makerId = "maker_id"
        case heroImageURL = "hero_image_url"
        case additionalImageURLs = "additional_image_urls"
        case totalDurationSeconds = "total_duration_seconds"
        case centroidLatitude = "centroid_latitude"
        case centroidLongitude = "centroid_longitude"
        case primaryCategory = "primary_category"
        case createdAt = "created_at"
    }

    var asMakerTour: MakerTour {
        let tour = Tour(
            id: id,
            title: title,
            shortDescription: shortDescription,
            longDescription: longDescription,
            makerId: makerId,
            heroImageURL: heroImageURL,
            additionalImageURLs: additionalImageURLs,
            kind: TourKind(rawValue: kind) ?? .single,
            stops: [],
            introAudioURL: nil,
            totalDurationSeconds: totalDurationSeconds,
            walkingDistanceMeters: nil,
            centroidLatitude: centroidLatitude,
            centroidLongitude: centroidLongitude,
            city: city,
            primaryCategory: TourCategory(rawValue: primaryCategory) ?? .hiddenGems,
            tags: tags,
            priceUSD: 0,
            createdAt: createdAt.map { String($0.prefix(10)) }
        )
        return MakerTour(tour: tour, status: TourStatus(rawValue: status) ?? .draft)
    }
}
