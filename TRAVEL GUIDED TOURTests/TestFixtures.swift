import Foundation
@testable import TRAVEL_GUIDED_TOUR

/// Shared factory methods for building `Tour` / `Stop` / `Maker`
/// instances in tests. Centralized so updates to the data model
/// only require a single edit point in the test suite.
enum TestFixtures {

    static let defaultMakerId = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!

    static func makeMaker(
        id: UUID = defaultMakerId,
        displayName: String = "Test Maker"
    ) -> Maker {
        Maker(
            id: id,
            displayName: displayName,
            avatarURL: nil,
            avatarEmoji: nil,
            bio: "Test bio",
            websiteURL: nil
        )
    }

    static func makeStop(
        id: UUID = UUID(),
        order: Int = 0,
        title: String = "Test Stop",
        latitude: Double = 40.7484,
        longitude: Double = -73.9857,
        audioDurationSeconds: Int = 120,
        triggerMode: StopTriggerMode = .manual
    ) -> Stop {
        Stop(
            id: id,
            order: order,
            title: title,
            caption: nil,
            latitude: latitude,
            longitude: longitude,
            audioURL: "https://example.test/audio.mp3",
            audioDurationSeconds: audioDurationSeconds,
            triggerMode: triggerMode,
            triggerRadiusMeters: 30,
            imageURL: nil,
            transcriptText: nil
        )
    }

    static func makeTour(
        id: UUID = UUID(),
        title: String = "Test Tour",
        makerId: UUID = defaultMakerId,
        kind: TourKind = .single,
        category: TourCategory = .architecture,
        tags: [String] = [],
        latitude: Double = 40.7484,
        longitude: Double = -73.9857,
        stopCount: Int = 1,
        createdAt: String? = nil,
        priceTier: Int? = nil,
        /// Explicit per-stop coordinates. Overrides `stopCount` +
        /// `latitude`/`longitude`. Needed for multi-stop tours whose
        /// stops are genuinely spread out — where the centroid is a
        /// different point from any stop.
        stopCoordinates: [(latitude: Double, longitude: Double)]? = nil,
        /// Centroid override. Defaults to `latitude`/`longitude`, which
        /// is right for a single-stop tour but not for a walk.
        centroidLatitude: Double? = nil,
        centroidLongitude: Double? = nil
    ) -> Tour {
        let stops: [Stop]
        if let stopCoordinates {
            stops = stopCoordinates.enumerated().map { index, coordinate in
                makeStop(
                    order: index,
                    title: "Stop \(index)",
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            }
        } else {
            stops = (0..<stopCount).map { i in
                makeStop(
                    order: i,
                    title: "Stop \(i)",
                    latitude: latitude,
                    longitude: longitude
                )
            }
        }
        let totalDuration = stops.reduce(0) { $0 + $1.audioDurationSeconds }

        return Tour(
            id: id,
            title: title,
            shortDescription: "Test short description",
            longDescription: "Test long description",
            makerId: makerId,
            heroImageURL: "https://example.test/hero.jpg",
            additionalImageURLs: nil,
            videoURLs: nil,
            kind: kind,
            stops: stops,
            introAudioURL: nil,
            totalDurationSeconds: totalDuration,
            walkingDistanceMeters: kind == .multiStop ? 500 : nil,
            centroidLatitude: centroidLatitude ?? latitude,
            centroidLongitude: centroidLongitude ?? longitude,
            city: "Test City",
            primaryCategory: category,
            tags: tags,
            priceUSD: 0,
            priceTier: priceTier,
            createdAt: createdAt
        )
    }
}
