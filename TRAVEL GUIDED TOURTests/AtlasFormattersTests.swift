import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Covers the shared locale-aware formatters (audit P2-5, also closes
/// the P3-2 DRY gap). Exact unit words depend on `Locale.current` —
/// these tests verify shape and presence rather than exact strings,
/// since CI machines and the test target inherit whatever locale they
/// were configured with.
final class AtlasFormattersTests: XCTestCase {

    // MARK: - Duration

    func test_duration_subMinute_isNonEmpty() {
        let s = AtlasFormatters.duration(seconds: 30)
        XCTAssertFalse(s.isEmpty)
        XCTAssertTrue(s.contains("30"))
    }

    func test_duration_exactMinute_isNonEmpty() {
        let s = AtlasFormatters.duration(seconds: 300)
        XCTAssertFalse(s.isEmpty)
        XCTAssertTrue(s.contains("5"))
    }

    func test_duration_overOneHour_includesHourAndMinute() {
        let s = AtlasFormatters.duration(seconds: 3 * 3600 + 25 * 60)
        XCTAssertFalse(s.isEmpty)
        XCTAssertTrue(s.contains("3"))
        XCTAssertTrue(s.contains("25"))
    }

    func test_duration_zero_isNonEmpty() {
        let s = AtlasFormatters.duration(seconds: 0)
        XCTAssertFalse(s.isEmpty)
    }

    func test_duration_negative_isNonEmpty() {
        // Defensive: clamped to 0 internally, so we still get a valid string.
        let s = AtlasFormatters.duration(seconds: -10)
        XCTAssertFalse(s.isEmpty)
    }

    // MARK: - Distance

    func test_distance_isNonEmpty() {
        let near = AtlasFormatters.distance(meters: 250)
        let far = AtlasFormatters.distance(meters: 5_000)
        XCTAssertFalse(near.isEmpty)
        XCTAssertFalse(far.isEmpty)
        // Far should be a larger unit; both contain at least one digit.
        XCTAssertTrue(near.contains { $0.isNumber })
        XCTAssertTrue(far.contains { $0.isNumber })
    }

    func test_distanceAway_endsWithAway() {
        let s = AtlasFormatters.distanceAway(meters: 500)
        XCTAssertTrue(s.hasSuffix("away"))
    }
}
