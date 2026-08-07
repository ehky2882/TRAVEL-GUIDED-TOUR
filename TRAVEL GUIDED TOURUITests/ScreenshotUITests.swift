import CoreLocation
import XCTest

/// Captures the App Store screenshots.
///
/// This is not a correctness test — nothing here asserts that the app is right.
/// Its only job is to walk through the app and call `snapshot(...)` at each
/// screen worth showing on the store. `fastlane screenshots` runs it once per
/// device size listed in `fastlane/Snapfile` and collects the PNGs.
///
/// ⚠️ DESIGN NOTE — WHY THIS FILE IS SO DEFENSIVE
/// A UI test navigates by finding elements on screen, so it breaks whenever the
/// UI moves. A screenshot run that crashes halfway is worse than useless, so
/// every step after the first is *optional*: if an element cannot be found, the
/// step is skipped with a logged note and the run continues. A UI change costs
/// one missing screenshot, not a red build and no screenshots at all.
///
/// If a screenshot goes missing, read the test log for the "SCREENSHOT SKIPPED"
/// line — it names the step that could not be reached.
///
/// The whole class is `@MainActor` because fastlane's `setupSnapshot` and
/// `snapshot` are main-actor isolated. Setup deliberately happens inside the
/// test method rather than in `setUpWithError()`: overriding an XCTestCase
/// method from a `@MainActor` class is an actor-isolation mismatch.
@MainActor
final class ScreenshotUITests: XCTestCase {

    private var app: XCUIApplication!

    /// How long to wait for a screen to appear before giving up on it.
    private let timeout: TimeInterval = 20

    /// Where the phone pretends to be: 34th & Fifth, outside the Empire State
    /// Building.
    ///
    /// ⚠️ THIS IS WHAT FRAMES THE MAP, and it replaced an earlier approach that
    /// looked reasonable and produced bad screenshots. Declining the location
    /// permission was reproducible — the app falls back to a fixed region — but
    /// that region centres on the Hudson, so the hero screenshot showed
    /// suburban New Jersey with Manhattan shoved into a corner. Simulating a
    /// real location is just as reproducible AND lands the map on the densest
    /// part of the catalogue.
    private let simulatedLocation = CLLocation(latitude: 40.7484, longitude: -73.9857)

    func testCaptureAppStoreScreenshots() throws {
        // A failed step should not abort the whole run — see the design note.
        continueAfterFailure = true

        app = XCUIApplication()
        setupSnapshot(app)

        // Must be set before the app asks, so the very first camera move is
        // already centred on Midtown.
        XCUIDevice.shared.location = XCUILocation(location: simulatedLocation)

        app.launch()
        allowLocationPermission()

        // 1. The map. This is the one screenshot that must always work, so it
        //    is taken first and is the only step that fails the test.
        XCTAssertTrue(
            waitForAppToSettle(),
            "The app never reached its main screen — screenshots cannot be captured."
        )
        // The map streams tiles and the mini-player's title scrolls; give both a
        // moment to come to rest so nothing is captured mid-animation.
        settle(seconds: 4)
        snapshot("01-Home-Map")

        // 2. The drawer of tours, raised over the map.
        if raiseDrawer() {
            snapshot("02-Browse-Tours")
        } else {
            skipped("the tour drawer")
        }

        // 3. A tour's own page: hero image, description, stops, nearby tours.
        if openFirstTour() {
            snapshot("03-Tour-Detail")

            // 4. The full-screen player.
            if startPlayback() {
                snapshot("04-Player")
            } else {
                skipped("the player")
            }
            closeAnyOpenLayer()
        } else {
            skipped("a tour page")
        }

        // 5. Saved tours.
        if selectTab("Library") {
            snapshot("05-Library")
        } else {
            skipped("the Library tab")
        }
    }

    // MARK: - Steps

    /// Waits for the splash screen to give way to the real UI.
    private func waitForAppToSettle() -> Bool {
        // The tab bar is the most reliable "we have arrived" signal: it is
        // present on every tab and outlives any transient loading state.
        if app.buttons["HOME"].firstMatch.waitForExistence(timeout: timeout) { return true }

        return app.maps.firstMatch.waitForExistence(timeout: timeout)
            || app.otherElements["Home"].waitForExistence(timeout: 5)
    }

    /// Raises the bottom sheet so the tour list fills more of the screen.
    ///
    /// Drags from the sheet's grab handle rather than from an arbitrary point:
    /// starting the drag inside the scrolling list just scrolls the list, which
    /// is how an earlier version produced a near-duplicate of screenshot 01
    /// with a half-cut card row across the top.
    private func raiseDrawer() -> Bool {
        guard app.maps.firstMatch.exists else { return false }

        // The handle sits at the top edge of the sheet, a little under halfway
        // down the screen.
        let handle = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.42))
        let target = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12))
        handle.press(forDuration: 0.25, thenDragTo: target, withVelocity: .slow,
                     thenHoldForDuration: 0.2)

        settle(seconds: 3)
        return true
    }

    /// Opens the first tour card in the drawer.
    ///
    /// Card buttons are found by shape rather than by label: the drawer also
    /// contains the search field and the category chips, which are buttons too.
    /// A tour card is large and sits in the lower half of the screen, so that is
    /// what we look for. Matching on a tour's title would tie these screenshots
    /// to whatever happens to be nearest, which changes with the catalogue.
    private func openFirstTour() -> Bool {
        let screen = app.frame

        let card = app.buttons.allElementsBoundByIndex.first { button in
            guard button.exists, button.isHittable else { return false }
            let frame = button.frame
            return frame.height > 120
                && frame.width > 120
                && frame.minY > screen.height * 0.35
        }

        guard let card else { return false }
        card.tap()
        settle(seconds: 3)
        return true
    }

    /// Presses the button that begins a tour.
    private func startPlayback() -> Bool {
        for label in ["Start Tour", "START TOUR", "Start", "Play"] {
            let button = app.buttons[label].firstMatch
            if button.waitForExistence(timeout: 3) && button.isHittable {
                button.tap()
                settle(seconds: 3)
                return true
            }
        }
        return false
    }

    /// Closes the tour or player layer so the next step starts from a tab root.
    private func closeAnyOpenLayer() {
        for label in ["Close", "close", "Done", "X"] {
            let button = app.buttons[label].firstMatch
            if button.exists && button.isHittable {
                button.tap()
                settle(seconds: 2)
                return
            }
        }
    }

    /// Switches to a bottom tab. Tab labels render in capitals.
    private func selectTab(_ name: String) -> Bool {
        for label in [name.uppercased(), name] {
            let tab = app.buttons[label].firstMatch
            if tab.exists && tab.isHittable {
                tab.tap()
                settle(seconds: 2)
                return true
            }
        }
        return false
    }

    // MARK: - Helpers

    /// Grants the location permission if the system asks.
    ///
    /// We ALLOW it, paired with the simulated location above, so the map opens
    /// on Midtown Manhattan. See the note on `simulatedLocation` for why
    /// declining — the obvious way to get a reproducible screenshot — produced
    /// a worse one.
    private func allowLocationPermission() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let preferred = [
            "Allow While Using App",
            "Allow Once",
            "Allow",
            "OK",
            "Continue"
        ]

        // Dialogs can appear a beat after launch, and there may be more than one.
        for _ in 0..<3 {
            let alert = springboard.alerts.firstMatch
            guard alert.waitForExistence(timeout: 4) else { return }

            let tapped = preferred.contains { title in
                let button = alert.buttons[title]
                guard button.exists else { return false }
                button.tap()
                return true
            }
            if !tapped { return }
        }
    }

    /// Lets animations, map tiles and the scrolling mini-player title come to
    /// rest. Screenshots caught mid-animation look like bugs, which is a fast
    /// way to fail App Store review.
    private func settle(seconds: TimeInterval = 2) {
        _ = app.wait(for: .runningForeground, timeout: 5)
        Thread.sleep(forTimeInterval: seconds)
    }

    private func skipped(_ what: String) {
        // Shows up in the test log and in fastlane's output.
        print("SCREENSHOT SKIPPED: could not reach \(what). " +
              "The UI has probably moved — update ScreenshotUITests.swift.")
    }
}
