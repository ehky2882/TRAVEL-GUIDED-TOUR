import CoreLocation
import XCTest

/// Captures the App Store screenshots.
///
/// This is not a correctness test — nothing here asserts that the app is
/// right. Its only job is to walk through the app and call `snapshot(...)` at
/// each screen worth showing on the store. `fastlane screenshots` runs it once
/// per device size listed in `fastlane/Snapfile` and collects the PNGs.
///
/// ⚠️ DESIGN NOTE — WHY THIS FILE IS SO DEFENSIVE
/// A UI test navigates by finding elements on screen, so it breaks whenever the
/// UI moves. A screenshot run that crashes halfway is worse than useless, so
/// every step after the first is *optional*: if an element cannot be found, the
/// step is skipped with a logged note and the run continues. A UI change costs
/// one missing screenshot, not a red build and no screenshots at all.
///
/// If a screenshot goes missing, the run goes red at the **"Verify the expected
/// screenshots" step in `.github/workflows/screenshots.yml`**, which names each
/// absent shot. Do not rely on this file's own "SCREENSHOT SKIPPED" notes to
/// reach CI — fastlane's log formatter swallows `print` and `NSLog`, which is
/// exactly how a three-image run shipped as a success (2026-08-16, run
/// 31979282815). The notes survive in the `.xcresult`; the filename check is
/// the signal.
///
/// ⚠️ NEVER CALL `isHittable` HERE. It *throws* on a SwiftUI element whose
/// activation point can't be resolved ("Activation point invalid and no
/// suggested hit points based on element frame"), which aborts the whole test
/// mid-run — that is what killed screenshots 03/04. Tap through
/// `tapCentre(of:)`, which drives a coordinate and never runs that check.
///
/// The whole class is `@MainActor` because fastlane's `setupSnapshot` and
/// `snapshot` are main-actor isolated. Setup deliberately happens inside the
/// test method rather than in `setUpWithError()`: overriding an XCTestCase
/// method from a `@MainActor` class is an actor-isolation mismatch.
@MainActor
final class ScreenshotUITests: XCTestCase {

    private var app: XCUIApplication!

    /// How long to wait for a screen to appear before giving up on it.
    private let timeout: TimeInterval = 25

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

    /// The tour used for the detail screenshot. It is the nearest
    /// tour to `simulatedLocation`, so it also leads the "Near you" rail.
    private let featuredTourTitle = "Empire State Building"

    func testCaptureAppStoreScreenshots() throws {
        // A failed step should not abort the whole run — see the design note.
        continueAfterFailure = true

        app = XCUIApplication()
        setupSnapshot(app)

        // Screenshot-only app switches. Both are inert without these
        // arguments — see `UITestSupport` in the app target.
        //   * the marquee never stops scrolling, so without this every shot
        //     catches the mini-player title mid-word;
        //   * an empty Library advertises an app with no content.
        app.launchArguments += ["-UITestDisableMarquee", "-UITestSeedLibrary"]

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
        // The permission alert can leave a stray tap behind (see
        // `allowLocationPermission`), and a tap anywhere in the drawer opens a
        // tour — so prove we are on a clean Home root before shot 1 rather
        // than assuming it.
        returnToHomeRoot()
        // Pin the drawer to its half-open default — the launch detent is not
        // reliable by this point (see `halfOpenDrawer`).
        halfOpenDrawer()
        // The map streams tiles and remote hero images load over the network;
        // give both time to land so nothing is captured half-drawn.
        settle(seconds: 8)
        XCTAssertTrue(
            app.maps.firstMatch.exists,
            "Shot 01 is supposed to be the map, and the map is not on screen."
        )
        XCTAssertFalse(
            isShowingTourLayer,
            "A tour layer is covering the map — shot 01 would not be the map."
        )
        snapshot("01-Home-Map")

        // 2. The same map with the drawer dropped to its peek detent, so the
        //    map runs nearly full-bleed and the spread of pins is the whole
        //    picture. Sits next to shot 01 on purpose: the pair reads as one
        //    gesture — drag the sheet down for the map, up for the tours.
        if collapseDrawer() {
            settle(seconds: 5)
            snapshot("02-Map-Fullscreen")
        } else {
            skipped("the map with the drawer collapsed")
        }

        // 3. The drawer raised over the map: curated tag shelves and the
        //    filter chips, showing the catalogue's breadth.
        if raiseDrawer() {
            settle(seconds: 5)
            snapshot("03-Browse-Tours")
        } else {
            skipped("the tour drawer")
        }

        // 4. A tour's own page: hero image, title, play pill, description.
        if openTour(matching: featuredTourTitle) {
            settle(seconds: 6)
            snapshot("04-Tour-Detail")

            // Start playback but DON'T capture the full player — the owner
            // dropped that shot in favour of the full-bleed map above. Playing
            // is still worth doing: it puts a real tour in the mini-player for
            // the remaining screenshots, so the app looks in use rather than
            // idle. Nothing is captured here, so a failure costs no image.
            _ = startPlayback()
        } else {
            skipped("a tour page")
        }

        // 5. A multi-stop walk — its route map and stop count.
        //    This is what separates Atlas from a single-audio-clip app.
        returnToHomeRoot()
        if openFirstWalk() {
            settle(seconds: 6)
            // Swap the hero carousel for the walk's route map. Without this the
            // walk screenshot is compositionally identical to shot 04 — same
            // hero, same title block, same play pill — and two near-duplicate
            // images in a six-shot set is a waste of a slot. The route map is
            // the thing only a multi-stop walk has.
            showWalkRoute()
            settle(seconds: 6)
            snapshot("05-Walk")
        } else {
            skipped("a multi-stop walk")
        }

        // 6. Saved tours — a populated Library, not an empty state.
        returnToHomeRoot()
        if selectTab("Library") && openLikedList() {
            settle(seconds: 5)
            snapshot("06-Library")
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

    /// True while a tour (or maker) detail layer is presented over the tab
    /// root. Those layers carry the only "Close" button in the app.
    private var isShowingTourLayer: Bool {
        app.buttons["Close"].firstMatch.exists
    }

    /// Gets back to a bare Home tab: dismiss any presented tour/maker layer,
    /// then select Home.
    ///
    /// ⚠️ This is the fix for the wrong screenshot 01. A stray tap left over
    /// from the location alert opened the Empire State tour *before* the first
    /// snapshot, so shots 01 and 02 were the same tour page and the map — the
    /// single strongest selling image — was never captured.
    private func returnToHomeRoot() {
        for _ in 0..<3 where isShowingTourLayer {
            tapCentre(of: app.buttons["Close"].firstMatch)
            settle(seconds: 2)
        }
        if app.buttons["HOME"].firstMatch.exists {
            tapCentre(of: app.buttons["HOME"].firstMatch)
            settle(seconds: 2)
        }
    }

    /// Raises the bottom sheet to its fully-open detent so the tag shelves
    /// fill the screen.
    ///
    /// Drags the sheet's grab handle *as an element* rather than from a guessed
    /// normalised point. The old version started at a fixed `dy: 0.42`, which
    /// lands on the map above the half-open drawer — so it panned the map (or,
    /// with a tour page open, scrolled that page) and then returned `true`
    /// regardless, reporting success for a step that never happened.
    ///
    /// The handle publishes its detent as an accessibility value, so success is
    /// something we can actually assert instead of assume.
    /// ⚠️ FLICK IT — DO NOT DRAG IT SLOWLY. A `.slow` (250 pt/s) drag over the
    /// ~740 pt to the top takes three seconds, and the sheet does not follow
    /// it; the gesture ends up panning the MAP instead, which is far worse than
    /// a no-op. A panned map re-renders the rails, and because they are lazy
    /// stacks the tours that were on screen stop existing as elements — so the
    /// tour and walk steps then fail too. One bad gesture cost three
    /// screenshots. A flick at the default velocity raises it first time
    /// (verified in the simulator).
    private func raiseDrawer() -> Bool {
        setDrawer(to: "Fully open", draggingHandleTo: 0.20)
    }

    /// Puts the drawer at its half-open default, where both the map and the
    /// first rail of tours read.
    ///
    /// ⚠️ DO NOT ASSUME THE LAUNCH DETENT. The drawer opens half-open, but the
    /// map's startup recenter counts as a camera move and
    /// `HomeView.onCameraMoving` collapses the drawer to peek — so whether
    /// shot 01 has rails in it depends on which finishes first. Two
    /// consecutive local runs produced different framings. A store screenshot
    /// must not be a coin toss.
    @discardableResult
    private func halfOpenDrawer() -> Bool {
        setDrawer(to: "Half open", draggingHandleTo: 0.50)
    }

    /// Drops the drawer to its peek detent, leaving the map nearly full-bleed.
    private func collapseDrawer() -> Bool {
        setDrawer(to: "Collapsed", draggingHandleTo: 0.92)
    }

    /// Drags the sheet's grab handle until it reports the wanted detent.
    ///
    /// ⚠️ TWO THINGS ABOUT THIS GESTURE ARE LOAD-BEARING, both learned by
    /// watching it fail:
    ///
    /// 1. **Drag TO the target position, don't overshoot.** A drag that ends up
    ///    in the map region above the sheet gets treated as a map pan, and a
    ///    panned map fires `onCameraMoving`, which *collapses* the drawer —
    ///    so an over-enthusiastic upward drag reliably closes it. Worse, the
    ///    pan re-renders the rails, and because they are lazy stacks the tours
    ///    that were on screen stop existing as elements, breaking every later
    ///    step. One bad gesture cost three screenshots in run 31979282815's
    ///    successor.
    /// 2. **Use `press(forDuration:thenDragTo:)`, not the `withVelocity:`
    ///    overload.** The velocity variant moved the sheet by one detent at
    ///    most and often not at all.
    ///
    /// The handle publishes its detent as an accessibility value, so the result
    /// is asserted rather than assumed — the old code returned `true`
    /// unconditionally and reported success for a step that never happened.
    @discardableResult
    private func setDrawer(to wanted: String, draggingHandleTo targetY: CGFloat) -> Bool {
        let handle = app.buttons["Tour list"].firstMatch
        guard handle.waitForExistence(timeout: 10) else { return false }

        for _ in 0..<3 {
            if handle.value as? String == wanted { return true }
            let start = handle.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: targetY))
            start.press(forDuration: 0.05, thenDragTo: end)
            settle(seconds: 3)
        }
        return handle.value as? String == wanted
    }

    /// The drawer hides its rails entirely at the collapsed detent (they fade
    /// to zero opacity and stop hit-testing, so they aren't in the
    /// accessibility tree at all). Anything that looks for a tour card has to
    /// make sure the drawer is open first.
    @discardableResult
    private func ensureDrawerOpen() -> Bool {
        let handle = app.buttons["Tour list"].firstMatch
        guard handle.exists else { return false }
        if handle.value as? String != "Collapsed" { return true }
        return raiseDrawer()
    }

    /// Opens the tour whose card label contains `title`.
    ///
    /// Matching on the title is safe here *because* the simulated location is
    /// fixed: the featured tour is the nearest one, so it leads the "Near you"
    /// rail on every run. Matching by shape ("a big button low on the screen"),
    /// which the previous version did, picked up filter chips instead.
    private func openTour(matching title: String) -> Bool {
        ensureDrawerOpen()
        let card = app.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] %@", title))
            .firstMatch
        if card.waitForExistence(timeout: 10) {
            tapCentre(of: card)
            if waitForTourPage() { return true }
        }
        return openTourViaSearch(title)
    }

    /// Fallback route to a specific tour: the search field. Slower than tapping
    /// a rail card, but it does not depend on where the map happens to be
    /// pointing or on which cards a lazy stack has realised.
    private func openTourViaSearch(_ title: String) -> Bool {
        let field = app.buttons["Search tours, makers, categories"].firstMatch
        guard field.waitForExistence(timeout: 5) else { return false }
        tapCentre(of: field)
        settle(seconds: 2)

        let input = app.textFields.firstMatch
        guard input.waitForExistence(timeout: 5) else { return false }
        tapCentre(of: input)
        input.typeText(title)
        settle(seconds: 3)

        let result = app.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] %@", title))
            .firstMatch
        guard result.waitForExistence(timeout: 8) else { return false }
        tapCentre(of: result)
        return waitForTourPage()
    }

    /// Opens the first multi-stop walk via the drawer's "Walks" filter chip.
    /// Walk cards carry a stop count in their meta line, which is what
    /// distinguishes them from single-stop cards.
    private func openFirstWalk() -> Bool {
        ensureDrawerOpen()
        let chip = app.buttons["Walks"].firstMatch
        guard chip.waitForExistence(timeout: 10) else { return false }
        tapCentre(of: chip)
        settle(seconds: 4)

        let card = app.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] %@", " stops"))
            .firstMatch
        guard card.waitForExistence(timeout: 10) else { return false }
        tapCentre(of: card)
        return waitForTourPage()
    }

    /// A tour page is up once its primary action button exists.
    private func waitForTourPage() -> Bool {
        let started = Date()
        while Date().timeIntervalSince(started) < 15 {
            if app.buttons["Start Tour"].firstMatch.exists { return true }
            if app.buttons["Pause"].firstMatch.exists { return true }
            if isShowingTourLayer { return true }
            settle(seconds: 1)
        }
        return false
    }

    /// Presses the button that begins a tour. Playback is non-modal — it hands
    /// off to the mini-player rather than opening the player itself.
    private func startPlayback() -> Bool {
        let play = app.buttons["Start Tour"].firstMatch
        guard play.waitForExistence(timeout: 5) else { return false }
        tapCentre(of: play)
        // Let the audio actually stream and the progress bar move; a player
        // screenshot at 0:00 doesn't read as playing.
        settle(seconds: 12)
        return true
    }



    /// Opens the Liked list, which is where seeded saves land — the Library
    /// root is a list of lists, so the tours themselves live one level in.
    private func openLikedList() -> Bool {
        // The pushed screen carries `navigationTitle("Liked")`, so this is a
        // real check that we arrived rather than an assumption that the tap
        // landed — the difference between shipping the saved tours and
        // shipping a near-empty list-of-lists.
        let likedScreen = app.navigationBars["Liked"]
        let predicate = NSPredicate(format: "label CONTAINS[c] 'Liked'")

        let row = app.buttons.matching(predicate).firstMatch
        guard row.waitForExistence(timeout: 10) else { return false }
        for target in [row, app.staticTexts.matching(predicate).firstMatch] {
            guard target.exists else { continue }
            tapCentre(of: target)
            settle(seconds: 3)
            if likedScreen.exists { return true }
        }
        return likedScreen.exists
    }

    /// Switches to a bottom tab. Tab labels render in capitals.
    private func selectTab(_ name: String) -> Bool {
        for label in [name.uppercased(), name] {
            let tab = app.buttons[label].firstMatch
            if tab.exists {
                tapCentre(of: tab)
                settle(seconds: 3)
                return true
            }
        }
        return false
    }

    /// Switches a tour page's media area from the photo carousel to its map.
    /// Best-effort: if the strip has been renamed the walk simply keeps its
    /// hero photo, which is still a usable screenshot.
    private func showWalkRoute() {
        for label in ["Map", "MAP"] {
            let tab = app.buttons[label].firstMatch
            if tab.exists {
                tapCentre(of: tab)
                return
            }
        }
    }

    // MARK: - Helpers

    /// Grants the location permission if the system asks.
    ///
    /// We ALLOW it, paired with the simulated location above, so the map opens
    /// on Midtown Manhattan. See the note on `simulatedLocation` for why
    /// declining — the obvious way to get a reproducible screenshot — produced
    /// a worse one.
    ///
    /// 🔴 TAP EXACTLY ONCE, THEN WAIT FOR THE ALERT TO GO. The previous version
    /// looped three times, and on the second pass the springboard alert was
    /// mid-dismissal: `exists` still answered `true`, so XCTest tapped the
    /// button's *cached* coordinates — by then the alert had gone and the tap
    /// landed on the app underneath, right on the "Near you" rail's first card.
    /// That opened the Empire State tour before screenshot 01 and cost the
    /// whole 2026-08-16 run (verified by reproducing it locally, then fixing
    /// it here).
    private func allowLocationPermission() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch
        guard alert.waitForExistence(timeout: 10) else { return }

        for title in ["Allow While Using App", "Allow Once", "Allow", "OK", "Continue"] {
            let button = alert.buttons[title]
            guard button.exists else { continue }
            button.tap()
            break
        }

        // Do not touch anything until the alert has actually left the screen.
        _ = alert.waitForNonExistence(timeout: 10)
        settle(seconds: 2)
    }

    /// Taps an element by driving its centre coordinate.
    ///
    /// `XCUIElement.tap()` runs a hittability check first, and that check
    /// *throws* on SwiftUI elements whose activation point can't be resolved
    /// ("Activation point invalid…"), aborting the run. A coordinate tap skips
    /// the check entirely, which is what we want in a screenshot walk-through.
    private func tapCentre(of element: XCUIElement) {
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Lets animations, map tiles and remote images come to rest. Screenshots
    /// caught mid-animation look like bugs, which is a fast way to fail App
    /// Store review.
    private func settle(seconds: TimeInterval = 2) {
        _ = app.wait(for: .runningForeground, timeout: 5)
        Thread.sleep(forTimeInterval: seconds)
    }

    /// Records a step that could not be reached.
    ///
    /// ⚠️ NEITHER `print` NOR `NSLog` SURVIVES FASTLANE'S LOG FORMATTER. That
    /// is why the 2026-08-16 run reported plain success while producing three
    /// screenshots out of five: the notes were written and then swallowed.
    /// They are kept here because they do land in the `.xcresult`, but the
    /// signal that actually reaches CI is the **"Verify the expected
    /// screenshots" step in `.github/workflows/screenshots.yml`**, which
    /// checks the produced filenames against the expected set and fails the
    /// job naming each missing shot.
    ///
    /// Deliberately NOT an `XCTIssue`: failing the test risks `capture_screenshots`
    /// abandoning the run before it copies the PNGs out of the simulator cache,
    /// so a single missing shot would cost every other image. The workflow
    /// check runs *after* the artifact upload and cannot lose anything.
    private func skipped(_ what: String) {
        let message = "SCREENSHOT SKIPPED: could not reach \(what). " +
            "The UI has probably moved — update ScreenshotUITests.swift."
        print(message)
        NSLog("%@", message)
        XCTContext.runActivity(named: message) { _ in }
    }
}
