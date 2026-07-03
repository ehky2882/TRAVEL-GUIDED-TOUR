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

    /// Upload audio for a draft tour's single stop and patch its `audio_url` +
    /// duration (and the tour's total duration). Stored at
    /// `tour-audio/{maker_id}/{tour_id}/{filename}` — the leading maker-id
    /// segment satisfies the storage RLS (`owns_maker`). Reloads `myTours` so
    /// the feed reflects the new duration.
    func attachAudio(
        to tour: Tour,
        data: Data,
        filename: String,
        contentType: String,
        durationSeconds: Int
    ) async throws {
        let makerId = tour.makerId.uuidString.lowercased()
        let tourId = tour.id.uuidString.lowercased()
        let path = "\(makerId)/\(tourId)/\(filename)"

        _ = try await client.storage
            .from("tour-audio")
            .upload(path, data: data, options: FileOptions(contentType: contentType, upsert: true))
        let publicURL = try client.storage.from("tour-audio").getPublicURL(path: path).absoluteString

        // Patch the stop (single-stop draft → order 0) and the tour duration.
        // Filter by tour_id only. The stop column is literally named "order",
        // which collides with PostgREST's reserved `order` (sort) query
        // parameter — `.eq("order", …)` sends `order=eq.0` and PostgREST tries
        // to parse it as a sort spec ("failed to parse order (eq.0)"). A
        // Phase-1 draft has exactly one stop, so tour_id alone is unambiguous.
        try await client.from("stops")
            .update(StopAudioPatch(audioURL: publicURL, audioDurationSeconds: durationSeconds))
            .eq("tour_id", value: tourId)
            .execute()
        try await client.from("tours")
            .update(TourDurationPatch(totalDurationSeconds: durationSeconds))
            .eq("id", value: tourId)
            .execute()

        await loadMyTours(makerId: tour.makerId)
    }

    /// Upload photos (already cropped to 1200×900 JPEG) for a draft tour and
    /// patch `hero_image_url` + `additional_image_urls`. The first photo becomes
    /// the cover when the tour has none yet; the rest append to the gallery.
    /// Stored at `tour-images/{maker_id}/{tour_id}/{filename}`.
    func attachPhotos(to tour: Tour, images: [Data]) async throws {
        guard !images.isEmpty else { return }
        let makerId = tour.makerId.uuidString.lowercased()
        let tourId = tour.id.uuidString.lowercased()

        var uploaded: [String] = []
        for data in images {
            let path = "\(makerId)/\(tourId)/photo-\(UUID().uuidString).jpg"
            _ = try await client.storage
                .from("tour-images")
                .upload(path, data: data, options: FileOptions(contentType: "image/jpeg", upsert: true))
            uploaded.append(try client.storage.from("tour-images").getPublicURL(path: path).absoluteString)
        }

        let existingHero = tour.heroImageURL.isEmpty ? nil : tour.heroImageURL
        var hero = existingHero
        var additional = tour.additionalImageURLs ?? []
        if existingHero == nil {
            hero = uploaded.first
            additional += Array(uploaded.dropFirst())
        } else {
            additional += uploaded
        }

        try await client.from("tours")
            .update(TourImagesPatch(heroImageURL: hero ?? "", additionalImageURLs: additional))
            .eq("id", value: tourId)
            .execute()

        await loadMyTours(makerId: tour.makerId)
    }

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

    /// Current transcript text for a tour's single stop ("" if none).
    func stopTranscript(tourId: UUID) async -> String {
        do {
            // Single-stop draft → filter by tour_id only. (The "order" column
            // collides with PostgREST's reserved sort param — see attachAudio.)
            let rows: [StopTranscriptRow] = try await client
                .from("stops")
                .select("transcript_text")
                .eq("tour_id", value: tourId.uuidString.lowercased())
                .limit(1)
                .execute()
                .value
            return rows.first?.transcriptText ?? ""
        } catch {
            return ""
        }
    }

    /// Save the transcript onto the tour's single stop.
    func setTranscript(tourId: UUID, text: String) async throws {
        // Single-stop draft → filter by tour_id only. (The "order" column
        // collides with PostgREST's reserved sort param — see attachAudio.)
        try await client
            .from("stops")
            .update(StopTranscriptPatch(transcriptText: text))
            .eq("tour_id", value: tourId.uuidString.lowercased())
            .execute()
    }

    /// Submit a draft for moderation: flip `status` draft → in_review. Saves the
    /// transcript first so a just-typed transcript isn't lost. Reloads `myTours`
    /// so the badge updates. (A DB webhook on tours UPDATE emails the admin.)
    func submitForReview(tour: Tour, transcript: String) async throws {
        try await setTranscript(tourId: tour.id, text: transcript)
        try await client
            .from("tours")
            .update(TourStatusPatch(status: TourStatus.inReview.rawValue))
            .eq("id", value: tour.id.uuidString.lowercased())
            .execute()
        await loadMyTours(makerId: tour.makerId)
    }

    /// Delete one of the maker's tours (its stops cascade via the FK). RLS
    /// `tours_owner_delete` scopes this to the owner. Removes it from `myTours`.
    /// (Uploaded audio/photos in Storage are left as orphans for now — a later
    /// cleanup can prune `tour-audio`/`tour-images` under the tour's folder.)
    func deleteTour(_ tour: Tour) async throws {
        try await client
            .from("tours")
            .delete()
            .eq("id", value: tour.id.uuidString.lowercased())
            .execute()
        myTours.removeAll { $0.id == tour.id }
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

/// Update payload: set a stop's audio.
private struct StopAudioPatch: Encodable {
    let audioURL: String
    let audioDurationSeconds: Int
    enum CodingKeys: String, CodingKey {
        case audioURL = "audio_url"
        case audioDurationSeconds = "audio_duration_seconds"
    }
}

/// Update payload: set a tour's total duration.
private struct TourDurationPatch: Encodable {
    let totalDurationSeconds: Int
    enum CodingKeys: String, CodingKey {
        case totalDurationSeconds = "total_duration_seconds"
    }
}

/// Update payload: set a tour's hero + gallery image URLs.
private struct TourImagesPatch: Encodable {
    let heroImageURL: String
    let additionalImageURLs: [String]
    enum CodingKeys: String, CodingKey {
        case heroImageURL = "hero_image_url"
        case additionalImageURLs = "additional_image_urls"
    }
}

/// Read/update payloads for a stop's transcript + a tour's status.
private struct StopTranscriptRow: Decodable {
    let transcriptText: String?
    enum CodingKeys: String, CodingKey { case transcriptText = "transcript_text" }
}
private struct StopTranscriptPatch: Encodable {
    let transcriptText: String
    enum CodingKeys: String, CodingKey { case transcriptText = "transcript_text" }
}
private struct TourStatusPatch: Encodable {
    let status: String
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
