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
/// step is skipped with a logged note and the run continues. The result is that
/// a UI change costs you one missing screenshot, not a red build and no
/// screenshots at all.
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

    func testCaptureAppStoreScreenshots() throws {
        // A failed step should not abort the whole run — see the design note.
        continueAfterFailure = true

        app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        dismissSystemAlerts()

        // 1. The map. This is the one screenshot that must always work, so it
        //    is taken first and is the only step that fails the test.
        XCTAssertTrue(
            waitForAppToSettle(),
            "The app never reached its main screen — screenshots cannot be captured."
        )
        snapshot("01-Home-Map")

        // 2. The drawer of nearby tours, pulled up over the map.
        if raiseDrawer() {
            snapshot("02-Browse-Tours")
        } else {
            skipped("the tour drawer")
        }

        // 3. A tour's own page: hero image, description, stops.
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

        // Fall back to the map itself, in case the tab labels are restyled.
        return app.maps.firstMatch.waitForExistence(timeout: timeout)
            || app.otherElements["Home"].waitForExistence(timeout: 5)
    }

    /// Drags the bottom sheet up so the tour list fills the screen.
    private func raiseDrawer() -> Bool {
        guard app.maps.firstMatch.exists else { return false }

        // Drag from low on the screen towards the top — the drawer's grab area
        // sits at the bottom, above the mini player.
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.82))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.25))
        start.press(forDuration: 0.1, thenDragTo: end)

        return settle()
    }

    /// Opens the first tour it can find in the drawer.
    private func openFirstTour() -> Bool {
        // Tour cards are buttons; the first few elements are chrome (search,
        // category chips), so prefer a cell-like element when one exists.
        let candidates: [XCUIElement] = [
            app.buttons.matching(identifier: "TourCard").firstMatch,
            app.cells.firstMatch,
            app.scrollViews.buttons.element(boundBy: 0)
        ]

        for candidate in candidates where candidate.exists && candidate.isHittable {
            candidate.tap()
            return settle()
        }
        return false
    }

    /// Presses the button that begins a tour.
    private func startPlayback() -> Bool {
        for label in ["Start Tour", "START TOUR", "Start"] {
            let button = app.buttons[label].firstMatch
            if button.waitForExistence(timeout: 3) && button.isHittable {
                button.tap()
                return settle()
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
                _ = settle()
                return
            }
        }
        // Nothing to close, or it dismisses by a swipe we do not need here.
    }

    /// Switches to a bottom tab. Tab labels render in capitals.
    private func selectTab(_ name: String) -> Bool {
        for label in [name.uppercased(), name] {
            let tab = app.buttons[label].firstMatch
            if tab.exists && tab.isHittable {
                tab.tap()
                return settle()
            }
        }
        return false
    }

    // MARK: - Helpers

    /// Dismisses the location permission dialog if the system shows one.
    ///
    /// We deliberately DECLINE location. It sounds backwards, but it is what
    /// makes screenshots reproducible: with no location fix the map falls back
    /// to a fixed New York region, which is both the densest part of the
    /// catalogue and identical on every run and every machine. Allowing
    /// location would frame the map on wherever the simulator happens to think
    /// it is that day.
    private func dismissSystemAlerts() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let preferred = ["Don't Allow", "Dont Allow", "Allow Once", "OK", "Continue"]

        // Permission dialogs can appear a beat after launch, and there may be
        // more than one (location, then notifications).
        for _ in 0..<3 {
            let alert = springboard.alerts.firstMatch
            guard alert.waitForExistence(timeout: 3) else { return }

            let tapped = preferred.contains { title in
                let button = alert.buttons[title]
                guard button.exists else { return false }
                button.tap()
                return true
            }
            if !tapped { return }
        }
    }

    /// Lets an animation or transition finish. Screenshots taken mid-animation
    /// look like bugs, which is a fast way to fail App Store review.
    @discardableResult
    private func settle() -> Bool {
        _ = app.wait(for: .runningForeground, timeout: 5)
        Thread.sleep(forTimeInterval: 1.5)
        return true
    }

    private func skipped(_ what: String) {
        // Shows up in the test log and in fastlane's output.
        print("SCREENSHOT SKIPPED: could not reach \(what). " +
              "The UI has probably moved — update ScreenshotUITests.swift.")
    }
}
