# TRAVEL GUIDED TOUR Tests

XCTest unit tests for Atlas's data/logic layer. Speculative right now — the test target doesn't exist in the Xcode project yet. Step 1 of the M-tests milestone landed this folder and the CI workflow; step 2 wires it into Xcode.

## What's in here

| File | Tests |
|---|---|
| `TourCategoryTests.swift` | Every enum case has non-empty `displayName` and `iconName`; JSON encoding round-trip; bad raw values error. |
| `LibraryStoreTests.swift` | `toggleSaved`, `markDownloaded`, `clearDownload`, `updateProgress`, persistence across instances, sorted views. |
| `RecentSearchStoreTests.swift` | `record` dedup behavior, whitespace trimming, cap-20 enforcement, `remove` and `clearAll`. |
| `RecentlyViewedStoreTests.swift` | `record` move-to-front, cap-20, `recentlyViewed(in:limit:)` filters missing tours. |
| `HomeRailsViewModelTests.swift` | Each rail family (continueListening, recentlyViewed, nearYou, inView, category) — empty cases, inclusion rules, ordering, the inView pan-threshold. |
| `ToursDataDecodingTests.swift` | `ToursData` decodes valid JSON; rejects missing required fields; rejects bad enum values; trip through encode→decode preserves shape. |

Total: ~250 lines of test code across six files. Covers the highest-bug-risk pure-logic surfaces per the pre-QA audit. Skips View bodies, audio playback, geofencing — those require simulator or real device anyway.

## One-time setup in Xcode (after this PR lands)

The test target isn't in `TRAVEL GUIDED TOUR.xcodeproj` yet. To wire it up:

1. **Open the project in Xcode:**
   ```
   open "TRAVEL GUIDED TOUR.xcodeproj"
   ```

2. **Add a Unit Testing Bundle target:**
   - Menu: `File → New → Target…`
   - Pick: **iOS → Test → Unit Testing Bundle** → Next
   - Configure:
     - **Product Name:** `TRAVEL GUIDED TOURTests`
     - **Team:** your dev team (once Apple Developer Program enrollment lands)
     - **Organization Identifier:** matches the main app (`com.ehky`)
     - **Project:** `TRAVEL GUIDED TOUR`
     - **Target to be Tested:** `TRAVEL GUIDED TOUR`
   - Click **Finish**.

3. **Replace the template file with the real tests:**
   - Xcode just created `TRAVEL GUIDED TOURTests/TRAVEL_GUIDED_TOURTests.swift` (a single template file). Delete it from the Project Navigator (right-click → Delete → Move to Trash).
   - In Finder, locate this folder (`TRAVEL GUIDED TOURTests/`) — it has 6 `.swift` files plus this README.
   - Drag the 6 `.swift` files from Finder into the Project Navigator under the `TRAVEL GUIDED TOURTests` group.
   - In the dialog that appears: **check the "TRAVEL GUIDED TOURTests" target** under "Add to targets," leave the main app target unchecked, click Add.

4. **Run the tests once locally:**
   - Press `⌘U` (Cmd-U).
   - All tests should pass. If any fail, screenshot or paste the error and ping me.

5. **Commit the Xcode project changes:**
   ```bash
   git add "TRAVEL GUIDED TOUR.xcodeproj"
   git commit -m "Wire up TRAVEL GUIDED TOURTests target in Xcode project"
   git push
   ```
   CI should turn green within a minute or two.

That's it. From then on, every PR runs the test suite automatically via `.github/workflows/ci.yml`.

## When you add new code

If you add new logic to the data/model/store layer, add a test for it. Naming convention: `<TypeName>Tests.swift` with one `XCTestCase` subclass per file.

If you change an existing type's API:
- Run `⌘U` locally before pushing.
- If a test fails, decide whether the test or the code is wrong — both happen.

## When you change the data model

`scripts/validate-tours.swift` mirrors the Swift data model. If you change `Tour`, `Stop`, `Maker`, or `TourCategory`, update **both** the validator script and the relevant test files in the same commit. (Drift between mirror types and the real model is one of the easier ways to break things silently.)
