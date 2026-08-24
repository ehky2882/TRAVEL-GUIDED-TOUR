import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// What a downloaded tour actually carries to disk. The rule these pin: a tour
/// saved for a journey with no signal must arrive with its photographs, which
/// it did not before 2026-08-23.
@MainActor
final class TourDownloadPlanTests: XCTestCase {

    // MARK: - Fixtures

    /// Local rather than `TestFixtures`, because these tests turn on exactly
    /// the fields that factory fixes: per-stop audio and image URLs.
    private func stop(order: Int, audio: String, image: String?) -> Stop {
        Stop(
            id: UUID(),
            order: order,
            title: "Stop \(order)",
            caption: nil,
            latitude: 40.7,
            longitude: -73.9,
            audioURL: audio,
            audioDurationSeconds: 60,
            triggerMode: .geofenced,
            triggerRadiusMeters: 30,
            imageURL: image,
            transcriptText: nil
        )
    }

    private func tour(hero: String, intro: String? = nil, stops: [Stop]) -> Tour {
        Tour(
            id: UUID(),
            title: "A tour",
            shortDescription: "short",
            longDescription: "long",
            makerId: UUID(),
            heroImageURL: hero,
            additionalImageURLs: ["https://example.com/gallery-1.webp"],
            videoURLs: nil,
            videoRole: nil,
            kind: .single,
            sourceURL: nil,
            sourceAuthor: nil,
            stops: stops,
            introAudioURL: intro,
            totalDurationSeconds: 60,
            walkingDistanceMeters: nil,
            centroidLatitude: 40.7,
            centroidLongitude: -73.9,
            city: "New York",
            country: "United States",
            primaryCategory: .history,
            tags: [],
            priceUSD: 0,
            priceTier: nil,
            createdAt: nil
        )
    }

    // MARK: - The plan

    func test_plan_carriesTheHeroAndEveryStopPhotograph() {
        let t = tour(
            hero: "https://example.com/hero.webp",
            stops: [
                stop(order: 0, audio: "https://example.com/a0.mp3", image: "https://example.com/s0.webp"),
                stop(order: 1, audio: "https://example.com/a1.mp3", image: "https://example.com/s1.webp"),
            ]
        )
        let urls = TourDownloader.downloadPlan(for: t).map(\.url.absoluteString)
        XCTAssertTrue(urls.contains("https://example.com/hero.webp"))
        XCTAssertTrue(urls.contains("https://example.com/s0.webp"))
        XCTAssertTrue(urls.contains("https://example.com/s1.webp"))
    }

    func test_plan_stillCarriesEveryPieceOfAudio() {
        let t = tour(
            hero: "https://example.com/hero.webp",
            intro: "https://example.com/intro.mp3",
            stops: [
                stop(order: 0, audio: "https://example.com/a0.mp3", image: nil),
                stop(order: 1, audio: "https://example.com/a1.mp3", image: nil),
            ]
        )
        let urls = TourDownloader.downloadPlan(for: t).map(\.url.absoluteString)
        XCTAssertEqual(
            urls.filter { $0.hasSuffix(".mp3") },
            ["https://example.com/intro.mp3",
             "https://example.com/a0.mp3",
             "https://example.com/a1.mp3"]
        )
    }

    /// Interrupted half way, a tour should still be listenable.
    func test_plan_queuesAllAudioBeforeAnyPhotograph() {
        let t = tour(
            hero: "https://example.com/hero.webp",
            intro: "https://example.com/intro.mp3",
            stops: [
                stop(order: 0, audio: "https://example.com/a0.mp3", image: "https://example.com/s0.webp"),
                stop(order: 1, audio: "https://example.com/a1.mp3", image: "https://example.com/s1.webp"),
            ]
        )
        let plan = TourDownloader.downloadPlan(for: t)
        let lastAudio = plan.lastIndex { $0.url.pathExtension == "mp3" }
        let firstImage = plan.firstIndex { $0.url.pathExtension == "webp" }
        XCTAssertNotNil(lastAudio)
        XCTAssertNotNil(firstImage)
        XCTAssertLessThan(lastAudio!, firstImage!)
    }

    /// A single-stop tour sets `stop0.imageURL` to its own hero, and a walk's
    /// intro stop reuses the landmark's photograph. Two files of identical
    /// bytes would also make the progress total lie.
    func test_plan_doesNotQueueTheSamePhotographTwice() {
        let shared = "https://example.com/hero.webp"
        let t = tour(
            hero: shared,
            stops: [stop(order: 0, audio: "https://example.com/a0.mp3", image: shared)]
        )
        let plan = TourDownloader.downloadPlan(for: t)
        XCTAssertEqual(plan.filter { $0.url.absoluteString == shared }.count, 1)
        XCTAssertEqual(Set(plan.map(\.name)).count, plan.count, "names must be unique on disk")
    }

    /// Gallery extras are browsing material, not walking material.
    func test_plan_leavesTheGalleryExtrasBehind() {
        let t = tour(
            hero: "https://example.com/hero.webp",
            stops: [stop(order: 0, audio: "https://example.com/a0.mp3", image: nil)]
        )
        let urls = TourDownloader.downloadPlan(for: t).map(\.url.absoluteString)
        XCTAssertFalse(urls.contains("https://example.com/gallery-1.webp"))
    }

    func test_plan_skipsUnusableURLs() {
        let t = tour(
            hero: "",
            stops: [stop(order: 0, audio: "https://example.com/a0.mp3", image: "")]
        )
        let plan = TourDownloader.downloadPlan(for: t)
        XCTAssertEqual(plan.count, 1, "only the one real audio file")
    }

    // MARK: - Finding the file again

    func test_photographsAreNamedApartFromTheAudioFiles() {
        let t = tour(
            hero: "https://example.com/hero.webp",
            intro: "https://example.com/intro.mp3",
            stops: [stop(order: 0, audio: "https://example.com/a0.mp3", image: nil)]
        )
        let plan = TourDownloader.downloadPlan(for: t)
        let imageNames = plan.filter { $0.url.pathExtension == "webp" }.map(\.name)
        XCTAssertEqual(imageNames.count, 1)
        XCTAssertTrue(imageNames[0].hasPrefix("img-"))
        XCTAssertFalse(plan.contains { $0.url.pathExtension == "mp3" && $0.name.hasPrefix("img-") })
    }

    func test_baseNameIsStableForTheSameURL() {
        let url = URL(string: "https://example.com/hero.webp")!
        XCTAssertEqual(
            DownloadedImageIndex.baseName(for: url),
            DownloadedImageIndex.baseName(for: url)
        )
    }

    func test_baseNameDiffersBetweenDifferentURLs() {
        XCTAssertNotEqual(
            DownloadedImageIndex.baseName(for: URL(string: "https://example.com/a.webp")!),
            DownloadedImageIndex.baseName(for: URL(string: "https://example.com/b.webp")!)
        )
    }

    func test_indexFindsARegisteredPhotographByItsURLAlone() throws {
        let folder = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let remote = URL(string: "https://example.com/hero.webp")!
        let file = folder.appendingPathComponent(
            "\(DownloadedImageIndex.baseName(for: remote)).webp"
        )
        try Data("not really a webp".utf8).write(to: file)
        // An audio file in the same folder must not be picked up as a photo.
        try Data().write(to: folder.appendingPathComponent("intro.mp3"))

        let index = DownloadedImageIndex()
        XCTAssertNil(index.file(for: remote), "nothing is known before registering")
        index.register(folder: folder)
        XCTAssertEqual(index.file(for: remote)?.lastPathComponent, file.lastPathComponent)
        XCTAssertNil(index.file(for: URL(string: "https://example.com/other.webp")!))

        index.forget(folder: folder)
        XCTAssertNil(index.file(for: remote), "a deleted download leaves no path behind")
    }
}
