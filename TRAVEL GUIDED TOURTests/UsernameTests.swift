import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Usernames (`docs/usernames-design.md`, `backend/usernames.sql`).
///
/// The database enforces every rule; these tests pin the parts the app owns:
/// what it sends, what it shows, and — most importantly — what it must never
/// send on an ordinary profile save.
final class UsernameTests: XCTestCase {

    // MARK: - Normalising what was typed

    func test_normalise_trimsDropsAtAndLowercases() {
        XCTAssertEqual(Username.normalise("  @KathyNg "), "kathyng")
        XCTAssertEqual(Username.normalise("@@atlas.nyc"), "atlas.nyc")
        XCTAssertEqual(Username.normalise("plain"), "plain")
    }

    // MARK: - Format rules, in the server's own words

    func test_formatProblem_acceptsGoodUsernames() {
        for ok in ["kathyng", "kathy.ng", "kathy_ng", "k9x", "user.3f9a2c",
                   String(repeating: "a", count: 24)] {
            XCTAssertNil(Username.formatProblem(ok), ok)
        }
    }

    func test_formatProblem_matchesTheServersWording() {
        XCTAssertEqual(Username.formatProblem(""), "is empty")
        XCTAssertEqual(Username.formatProblem("ab"), "must be 3 to 24 characters")
        XCTAssertEqual(Username.formatProblem(String(repeating: "a", count: 25)),
                       "must be 3 to 24 characters")
        XCTAssertEqual(Username.formatProblem("kathy-ng"), "may use only letters, numbers, . and _")
        XCTAssertEqual(Username.formatProblem(".kathy"), "must start and end with a letter or number")
        XCTAssertEqual(Username.formatProblem("kathy_"), "must start and end with a letter or number")
        XCTAssertEqual(Username.formatProblem("kathy..ng"), "may not have two dots in a row")
        XCTAssertEqual(Username.formatProblem("12345"), "must contain a letter")
    }

    // MARK: - handle_available()'s reply

    func test_availability_parsesEveryServerAnswer() {
        XCTAssertEqual(Username.Availability(server: "available"), .available)
        XCTAssertEqual(Username.Availability(server: "yours"), .yours)
        XCTAssertEqual(Username.Availability(server: "taken"), .taken)
        XCTAssertEqual(Username.Availability(server: "reserved"), .reserved)
        XCTAssertEqual(Username.Availability(server: "invalid: must contain a letter"),
                       .invalid("must contain a letter"))
    }

    /// An answer this build has never seen must not read as a refusal.
    func test_availability_unfamiliarAnswerIsUnknown_notARefusal() {
        XCTAssertEqual(Username.Availability(server: "something-new"), .unknown)
    }

    func test_friendlyMessage_raceAndTriggerAndOther() {
        XCTAssertEqual(Username.friendlyMessage(code: "23505", message: "duplicate key"),
                       "That username was just taken. Try another.")
        XCTAssertEqual(Username.friendlyMessage(code: "23514",
                                                message: "A username can be changed once every 30 days."),
                       "A username can be changed once every 30 days.")
        XCTAssertEqual(Username.friendlyMessage(code: nil, message: "boom"),
                       "Couldn't change your username. Please try again.")
    }

    // MARK: - Maker

    func test_maker_decodesWithAndWithoutTheNewKeys() throws {
        let with = #"{"id":"11111111-1111-1111-1111-111111111111","displayName":"Kathy Ng","bio":"","platform":"dozent","handle":"kathyng"}"#
        let without = #"{"id":"11111111-1111-1111-1111-111111111111","displayName":"Kathy Ng","bio":""}"#
        let a = try JSONDecoder().decode(Maker.self, from: Data(with.utf8))
        let b = try JSONDecoder().decode(Maker.self, from: Data(without.utf8))
        XCTAssertEqual(a.handle, "kathyng")
        XCTAssertEqual(a.platform, "dozent")
        XCTAssertNil(b.handle, "the bundled seed and older mirrors must keep decoding")
        XCTAssertNil(b.atHandle)
    }

    func test_profileHandleLine_isForDozentOnly_notRepeatedForPinnedCreators() {
        let account = Maker(id: UUID(), displayName: "Kathy Ng", avatarURL: nil, avatarEmoji: nil,
                            bio: "", websiteURL: nil, platform: "dozent", handle: "kathyng")
        let pinned = Maker(id: UUID(), displayName: "Instagram @urbanistariel", avatarURL: nil,
                           avatarEmoji: nil, bio: "", websiteURL: nil,
                           platform: "instagram", handle: "urbanistariel")
        XCTAssertEqual(account.profileHandleLine, "@kathyng")
        XCTAssertNil(pinned.profileHandleLine, "its display name already says @urbanistariel")
        XCTAssertEqual(pinned.atHandle, "@urbanistariel")
    }

    /// The former `New Creator` accounts are named after their username; the
    /// line under the name would otherwise repeat it.
    func test_profileHandleLine_hiddenWhenTheNameIsTheUsername() {
        let renamed = Maker(id: UUID(), displayName: "@user.f15619", avatarURL: nil, avatarEmoji: nil,
                            bio: "", websiteURL: nil, platform: "dozent", handle: "user.f15619")
        XCTAssertNil(renamed.profileHandleLine)
    }

    // MARK: - MakerRow: the profile upsert must never carry the username

    func test_makerRowEncode_neverSendsHandlePlatformOrHandleAuto() throws {
        let row = MakerRow(id: UUID(), userId: "abc", displayName: "Kathy Ng", avatarUrl: nil,
                           avatarEmoji: nil, bio: "", websiteUrl: nil,
                           platform: "dozent", handle: "kathyng", handleAuto: true)
        let json = try JSONSerialization.jsonObject(with: JSONEncoder().encode(row)) as? [String: Any]
        let keys = Set(json?.keys.map { $0 } ?? [])
        XCTAssertFalse(keys.contains("handle"),
                       "PostgREST updates exactly what it is sent — sending handle lets a profile save change it")
        XCTAssertFalse(keys.contains("platform"))
        XCTAssertFalse(keys.contains("handle_auto"))
        XCTAssertTrue(keys.contains("display_name"), "sanity: the rest of the row is still sent")
    }

    func test_makerRowDecode_readsTheUsernameColumns_andAsMakerCarriesThem() throws {
        let json = #"{"id":"11111111-1111-1111-1111-111111111111","user_id":"22222222-2222-2222-2222-222222222222","display_name":"New Creator","bio":"","platform":"dozent","handle":"user.3f9a2c","handle_auto":true}"#
        let row = try JSONDecoder().decode(MakerRow.self, from: Data(json.utf8))
        XCTAssertEqual(row.handleAuto, true)
        XCTAssertEqual(row.asMaker.handle, "user.3f9a2c")
        XCTAssertEqual(row.asMaker.platform, "dozent")
    }
}
