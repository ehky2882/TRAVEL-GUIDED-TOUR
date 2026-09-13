import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// In-app account deletion (Apple Guideline 5.1.1(v)). The server half lives in
/// `backend/functions/delete-account` and `backend/account_deletion.sql`; these
/// pin the parts of the contract the app owns.
final class AccountDeletionTests: XCTestCase {

    // MARK: - Only the account holder

    /// 🔴 The standing decision is that nobody deletes someone else's account.
    /// The server takes the id from the caller's verified session, and the
    /// request must never grow a field that could name a different user. If
    /// this fails, a key was added — keep it out, or prove it cannot name one.
    func testRequestCarriesNoUserIdentifier() throws {
        let withCode = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(AccountDeletionRequest(appleAuthorizationCode: "abc"))
        ) as? [String: Any]
        XCTAssertEqual(Set(withCode?.keys ?? [:].keys), ["appleAuthorizationCode"])

        let withoutCode = try JSONSerialization.jsonObject(
            with: JSONEncoder().encode(AccountDeletionRequest(appleAuthorizationCode: nil))
        ) as? [String: Any]
        XCTAssertEqual(withoutCode?.isEmpty, true, "a nil Apple code should send an empty body")
    }

    // MARK: - Error messages

    func testExpiredSessionTellsPersonToSignInAgain() {
        let error = AccountDeletionError(status: 401, body: Data(#"{"error":"whatever"}"#.utf8))
        XCTAssertEqual(error.errorDescription,
                       "Your sign-in has expired. Sign out, sign back in, and try again.")
    }

    func testServerMessageIsShownWithContactFallback() {
        let error = AccountDeletionError(
            status: 503,
            body: Data(#"{"error":"We couldn't finish removing your uploads. Please try again."}"#.utf8)
        )
        XCTAssertEqual(error.serverMessage, "We couldn't finish removing your uploads. Please try again.")
        XCTAssertTrue(error.errorDescription?.hasSuffix("write to hello@dozent.world.") ?? false)
    }

    func testUnreadableBodyFallsBackToGenericRetryMessage() {
        let error = AccountDeletionError(status: 500, body: Data("<html>gateway</html>".utf8))
        XCTAssertNil(error.serverMessage)
        XCTAssertTrue(error.errorDescription?.hasPrefix("We couldn't finish deleting your account.") ?? false)
    }

    // MARK: - Local data

    func testForgetRemovesOnlyThatAccountsKeys() throws {
        let suite = "AccountDeletionTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        let gone = "8C0F4B6A-1D2E-4F3A-9B8C-7D6E5F4A3B2C"
        let other = "11111111-2222-3333-4444-555555555555"

        defaults.set(["t"], forKey: "atlas.entitlements.\(gone)")
        defaults.set(Data(), forKey: "atlas.pendingPurchases.\(gone.lowercased())")
        defaults.set(Data(), forKey: "profileSnapshot.myMaker.\(gone)")
        defaults.set(["t"], forKey: "atlas.entitlements.\(other)")
        defaults.set("dark", forKey: "colorSchemePreference")

        LocalAccountData.forget(uid: gone, defaults: defaults)

        XCTAssertNil(defaults.object(forKey: "atlas.entitlements.\(gone)"))
        XCTAssertNil(defaults.object(forKey: "atlas.pendingPurchases.\(gone.lowercased())"))
        XCTAssertNil(defaults.object(forKey: "profileSnapshot.myMaker.\(gone)"))
        XCTAssertNotNil(defaults.object(forKey: "atlas.entitlements.\(other)"),
                        "another account's cache on the same device must survive")
        XCTAssertEqual(defaults.string(forKey: "colorSchemePreference"), "dark")
    }
}
