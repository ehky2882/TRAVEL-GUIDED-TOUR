import Foundation
import CoreLocation
import Observation
import Supabase

/// A tour owned by the signed-in maker, with its lifecycle status — the unit
/// shown on the own-profile "My tours" feed (drafts + in-review + published).
struct MakerTour: Codable, Identifiable, Hashable {
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

    private let auth: AuthService
    private let client: SupabaseClient
    /// Last-known tour list, persisted per user so the Me-tab feed renders on the
    /// first frame after launch instead of an empty list. See `ProfileSnapshotStore`.
    private let snapshot: ProfileSnapshotStore<[MakerTour]>
    /// Byte-progress uploader, used for audio only. Photos stay on the SDK —
    /// they're small, and "3 of 5" is the honest unit for a batch anyway.
    private let uploader = StorageUploader()
    private var loadedUid: String?
    private var didHydrate = false

    init(auth: AuthService,
         client: SupabaseClient = SupabaseClientProvider.shared,
         snapshot: ProfileSnapshotStore<[MakerTour]> = ProfileSnapshotStore("myTours")) {
        self.auth = auth
        self.client = client
        self.snapshot = snapshot
        // Hydrate synchronously from the cached snapshot so the feed isn't empty
        // on the first Me-tab paint after launch.
        hydrateIfUserChanged()
    }

    /// Swap `myTours` to the current user's cached snapshot when the active user
    /// changed (or on first hydrate); a no-op when unchanged, so it never
    /// clobbers a freshly-loaded list. Call from the Profile tab's `.task`.
    func hydrateIfUserChanged() {
        let uid = auth.user?.id.uuidString.lowercased()
        guard !didHydrate || uid != loadedUid else { return }
        didHydrate = true
        loadedUid = uid
        myTours = snapshot.load(uid: uid) ?? []
    }

    /// Clear when signed out or when the profile has no maker row yet. Only
    /// clears the in-memory list — the persisted snapshot is per-user, so it
    /// stays valid for this account without risking a network-blip wipe.
    func clear() { myTours = [] }

    /// Upload audio for a draft tour's single stop and patch its `audio_url` +
    /// duration (and the tour's total duration). Stored at
    /// `tour-audio/{maker_id}/{tour_id}/{filename}` — the leading maker-id
    /// segment satisfies the storage RLS (`owns_maker`). Reloads `myTours` so
    /// the feed reflects the new duration.
    /// - Parameter onProgress: fractional upload progress, 0...1. Narration is
    ///   the largest thing this app uploads, so this path goes through
    ///   `StorageUploader` rather than the SDK — see that type for why the SDK
    ///   can't report progress.
    func attachAudio(
        to tour: Tour,
        data: Data,
        filename: String,
        contentType: String,
        durationSeconds: Int,
        onProgress: @escaping @Sendable (Double) -> Void = { _ in }
    ) async throws {
        let makerId = tour.makerId.uuidString.lowercased()
        let tourId = tour.id.uuidString.lowercased()
        let path = "\(makerId)/\(tourId)/\(filename)"

        let token = try await client.auth.session.accessToken
        let publicURL = try await uploader.upload(
            data: data,
            bucket: "tour-audio",
            path: path,
            contentType: contentType,
            accessToken: token,
            onProgress: onProgress
        )

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
            let uid = auth.user?.id.uuidString.lowercased()
            loadedUid = uid
            snapshot.save(myTours, uid: uid)
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

    /// Edit a tour's metadata after it was created — title, both descriptions,
    /// tags, and the stop's pin + geofence radius.
    ///
    /// **Why this exists at all:** before it, everything on the create form was
    /// frozen for the life of the tour. A typo in a title could only be fixed by
    /// deleting the tour, which also destroyed its audio and photos. This is the
    /// single biggest gap in the authoring flow.
    ///
    /// **A published tour returns to review** (owner decision, 2026-08-17).
    /// Editing live text is allowed — a maker shouldn't need to ask an admin to
    /// fix a typo — but it re-enters moderation rather than changing under a
    /// listener mid-tour. A draft or an already-in-review tour keeps its status.
    /// Note the tour is patched first and the stop second, mirroring
    /// `createDraftTour`'s order so the stop's `owns_tour` RLS check always sees
    /// a row it can match.
    func updateDetails(
        tour: Tour,
        status: TourStatus,
        title: String,
        shortDescription: String,
        longDescription: String,
        category: TourCategory,
        tags: [String],
        coordinate: CLLocationCoordinate2D,
        radiusMeters: Int
    ) async throws {
        let tourId = tour.id.uuidString.lowercased()
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)

        try await client.from("tours")
            .update(TourDetailsPatch(
                title: cleanTitle,
                shortDescription: shortDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                longDescription: longDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                primaryCategory: category.rawValue,
                tags: tags,
                centroidLatitude: coordinate.latitude,
                centroidLongitude: coordinate.longitude,
                // Published edits re-enter moderation; drafts and in-review
                // tours keep the status they already had.
                status: status == .published ? TourStatus.inReview.rawValue : status.rawValue
            ))
            .eq("id", value: tourId)
            .execute()

        // Single-stop tours only for now: filter by tour_id alone. The stop
        // column is literally named "order", which collides with PostgREST's
        // reserved sort parameter — see `attachAudio`.
        try await client.from("stops")
            .update(StopLocationPatch(
                title: cleanTitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                triggerRadiusMeters: radiusMeters
            ))
            .eq("tour_id", value: tourId)
            .execute()

        await loadMyTours(makerId: tour.makerId)
    }

    /// Replace a tour's photo set wholesale, in the given order: the first entry
    /// becomes the cover, the rest the gallery.
    ///
    /// Deliberately a *replace*, not an append — reordering
    /// and removal both need to express "this exact list, in this exact order",
    /// and an append-only API cannot say that. Any file dropped from the list is
    /// also deleted from Storage rather than orphaned, since nothing else will
    /// ever reference it. Storage deletion is best-effort: a failure there must
    /// not block the reorder the user asked for, and the worst case is a stray
    /// object nothing points at.
    func setPhotos(for tour: Tour, orderedURLs: [String]) async throws {
        let previous = Set(([tour.heroImageURL] + (tour.additionalImageURLs ?? []))
            .filter { !$0.isEmpty })
        let kept = Set(orderedURLs)
        let removed = previous.subtracting(kept)

        try await client.from("tours")
            .update(TourImagesPatch(
                heroImageURL: orderedURLs.first ?? "",
                additionalImageURLs: Array(orderedURLs.dropFirst())
            ))
            .eq("id", value: tour.id.uuidString.lowercased())
            .execute()

        for url in removed {
            guard let path = Self.storagePath(from: url, bucket: "tour-images") else { continue }
            _ = try? await client.storage.from("tour-images").remove(paths: [path])
        }

        await loadMyTours(makerId: tour.makerId)
    }

    /// Upload images (already cropped to 1200×900 JPEG) and return their public
    /// URLs, without touching the tour row. Split from `setPhotos` so the caller
    /// can upload, then commit one ordered list — which is what makes "add three
    /// photos and drag one to the front" a single write instead of three.
    func uploadPhotos(for tour: Tour, images: [Data]) async throws -> [String] {
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
        return uploaded
    }

    /// Recover the storage object path from a public URL, so a removed photo can
    /// actually be deleted rather than left behind. Public URLs look like
    /// `…/storage/v1/object/public/<bucket>/<maker>/<tour>/<file>`; everything
    /// after the bucket segment is the path. Returns nil rather than guessing if
    /// the URL isn't in that shape — a wrong path would delete nothing, but a
    /// *plausible* wrong path could delete the wrong object.
    nonisolated static func storagePath(from urlString: String, bucket: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }
        let parts = url.pathComponents.filter { $0 != "/" }
        guard let bucketIndex = parts.lastIndex(of: bucket),
              bucketIndex + 1 < parts.count
        else { return nil }
        return parts[(bucketIndex + 1)...].joined(separator: "/")
    }

    /// The tour's single stop as stored — pin and geofence radius.
    ///
    /// **Needed because `MakerTour` carries no stops.** `TourRow.asMakerTour`
    /// builds its `Tour` with `stops: []` (the feed only needs title, status and
    /// images), so a details editor reading `tour.stops.first` sees nil and
    /// would silently fall back to a default radius — quietly resetting every
    /// tour's geofence to 30 m the first time anyone edited its title. Read the
    /// real values instead.
    func stopLocation(tourId: UUID) async -> (coordinate: CLLocationCoordinate2D, radiusMeters: Int)? {
        do {
            // Single-stop tours: filter by tour_id alone — the "order" column
            // collides with PostgREST's reserved sort param (see attachAudio).
            let rows: [StopLocationRow] = try await client
                .from("stops")
                .select("latitude,longitude,trigger_radius_meters")
                .eq("tour_id", value: tourId.uuidString.lowercased())
                .limit(1)
                .execute()
                .value
            guard let row = rows.first else { return nil }
            return (CLLocationCoordinate2D(latitude: row.latitude, longitude: row.longitude),
                    row.triggerRadiusMeters)
        } catch {
            return nil
        }
    }

    /// The URL of the audio attached to a tour's single stop, if any.
    ///
    /// Needed for the same reason as `stopLocation`: `MakerTour` carries no
    /// stops, so the editor knows a tour *has* audio (from its duration) without
    /// knowing where that audio is — which is why it could never offer to play
    /// it back.
    func stopAudioURL(tourId: UUID) async -> URL? {
        do {
            let rows: [StopAudioRow] = try await client
                .from("stops")
                .select("audio_url")
                .eq("tour_id", value: tourId.uuidString.lowercased())
                .limit(1)
                .execute()
                .value
            guard let raw = rows.first?.audioURL, !raw.isEmpty else { return nil }
            return URL(string: raw)
        } catch {
            return nil
        }
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
            videoURLs: nil,
            kind: TourKind(rawValue: kind) ?? .single,
            stops: stops,
            introAudioURL: nil,
            totalDurationSeconds: totalDurationSeconds,
            walkingDistanceMeters: nil,
            centroidLatitude: centroidLatitude,
            centroidLongitude: centroidLongitude,
            city: nil,
            // Maker-authored tours carry no city, so no country either.
            country: nil,
            primaryCategory: TourCategory(rawValue: primaryCategory) ?? category,
            tags: tags,
            priceUSD: 0,
            priceTier: nil,
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

/// Update payload: a tour's editable metadata (see `updateDetails`).
private struct TourDetailsPatch: Encodable {
    let title: String
    let shortDescription: String
    let longDescription: String
    let primaryCategory: String
    let tags: [String]
    let centroidLatitude: Double
    let centroidLongitude: Double
    let status: String

    enum CodingKeys: String, CodingKey {
        case title, tags, status
        case shortDescription = "short_description"
        case longDescription = "long_description"
        case primaryCategory = "primary_category"
        case centroidLatitude = "centroid_latitude"
        case centroidLongitude = "centroid_longitude"
    }
}

/// Read payload: a stop's audio URL (see `stopAudioURL`).
private struct StopAudioRow: Decodable {
    let audioURL: String?
    enum CodingKeys: String, CodingKey { case audioURL = "audio_url" }
}

/// Read payload: a stop's pin + geofence radius (see `stopLocation`).
private struct StopLocationRow: Decodable {
    let latitude: Double
    let longitude: Double
    let triggerRadiusMeters: Int
    enum CodingKeys: String, CodingKey {
        case latitude, longitude
        case triggerRadiusMeters = "trigger_radius_meters"
    }
}

/// Update payload: a stop's title + pin + geofence radius.
private struct StopLocationPatch: Encodable {
    let title: String
    let latitude: Double
    let longitude: Double
    let triggerRadiusMeters: Int

    enum CodingKeys: String, CodingKey {
        case title, latitude, longitude
        case triggerRadiusMeters = "trigger_radius_meters"
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
            videoURLs: nil,
            kind: TourKind(rawValue: kind) ?? .single,
            stops: [],
            introAudioURL: nil,
            totalDurationSeconds: totalDurationSeconds,
            walkingDistanceMeters: nil,
            centroidLatitude: centroidLatitude,
            centroidLongitude: centroidLongitude,
            city: city,
            // The authoring tables hold no country column; a maker picks a
            // point on a map, not a country. Catalog tours get theirs from
            // Tours.json / get_catalog instead.
            country: nil,
            primaryCategory: TourCategory(rawValue: primaryCategory) ?? .hiddenGems,
            tags: tags,
            priceUSD: 0,
            priceTier: nil,
            createdAt: createdAt.map { String($0.prefix(10)) }
        )
        return MakerTour(tour: tour, status: TourStatus(rawValue: status) ?? .draft)
    }
}
