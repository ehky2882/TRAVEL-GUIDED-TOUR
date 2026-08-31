import XCTest
@testable import TRAVEL_GUIDED_TOUR

/// Paid tours (V2 Step 6, Phase 3) — the pure, testable parts: the tier →
/// App Store product-id mapping, the free/paid split, and the offline
/// entitlement cache.
///
/// The StoreKit purchase flow itself isn't unit-tested here: it needs a real
/// payment sheet and Apple's sandbox, which is exactly what the owner's
/// on-device pass covers.
final class PaidTourTests: XCTestCase {

    // MARK: - Free vs paid

    func test_tourWithNoPriceTier_isFree() {
        let tour = TestFixtures.makeTour()
        XCTAssertFalse(tour.isPaid)
        XCTAssertNil(tour.storeProductId)
        XCTAssertNil(tour.fallbackPriceText)
    }

    /// The entire catalog today decodes with no `priceTier`, so "absent means
    /// free" is the property that keeps 1000+ existing tours playable.
    func test_zeroOrNegativeTier_isTreatedAsFree() {
        XCTAssertFalse(TestFixtures.makeTour(priceTier: 0).isPaid)
        XCTAssertFalse(TestFixtures.makeTour(priceTier: -100).isPaid)
    }

    func test_positiveTier_isPaid() {
        XCTAssertTrue(TestFixtures.makeTour(priceTier: 299).isPaid)
    }

    // MARK: - Product id mapping

    /// These strings must match the fourteen products created by hand in App Store
    /// Connect. A mismatch means the payment sheet never opens, so pin every
    /// tier rather than spot-checking.
    func test_productId_matchesAppStoreConnectProducts() {
        let expected: [Int: String] = [
            99: "tour.tier.099",
            199: "tour.tier.199",
            299: "tour.tier.299",
            399: "tour.tier.399",
            499: "tour.tier.499",
            599: "tour.tier.599",
            699: "tour.tier.699",
            799: "tour.tier.799",
            899: "tour.tier.899",
            999: "tour.tier.999",
            1299: "tour.tier.1299",
            1499: "tour.tier.1499",
            1799: "tour.tier.1799",
            1999: "tour.tier.1999",
        ]
        for (tier, productId) in expected {
            XCTAssertEqual(
                TestFixtures.makeTour(priceTier: tier).storeProductId,
                productId,
                "tier \(tier) mapped to the wrong App Store product"
            )
        }
    }

    /// The sub-$1 tier is the one that needs zero-padding; a plain
    /// "tour.tier.99" would 404 against App Store Connect.
    func test_subDollarTier_isZeroPadded() {
        XCTAssertEqual(TestFixtures.makeTour(priceTier: 99).storeProductId, "tour.tier.099")
    }

    func test_fallbackPriceText_formatsCentsAsDollars() {
        XCTAssertEqual(TestFixtures.makeTour(priceTier: 99).fallbackPriceText, "$0.99")
        XCTAssertEqual(TestFixtures.makeTour(priceTier: 299).fallbackPriceText, "$2.99")
        XCTAssertEqual(TestFixtures.makeTour(priceTier: 1999).fallbackPriceText, "$19.99")
    }

    // MARK: - Entitlement cache

    private func makeStore() -> (EntitlementStore, UserDefaults) {
        let suite = "PaidTourTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        return (EntitlementStore(defaults: defaults), defaults)
    }

    func test_entitlements_roundTripPerUser() {
        let (store, _) = makeStore()
        let tour = UUID()
        store.store([tour], uid: "user-a")
        XCTAssertEqual(store.tourIds(uid: "user-a"), [tour])
    }

    /// Two accounts on one device must never see each other's purchases.
    func test_entitlements_areIsolatedBetweenAccounts() {
        let (store, _) = makeStore()
        let ownedByA = UUID()
        store.store([ownedByA], uid: "user-a")
        XCTAssertTrue(store.tourIds(uid: "user-b").isEmpty)
    }

    func test_entitlements_signedOutReadsEmpty() {
        let (store, _) = makeStore()
        store.store([UUID()], uid: "user-a")
        XCTAssertTrue(store.tourIds(uid: nil).isEmpty)
    }

    /// A refund that empties the set has to actually clear the cache —
    /// otherwise a refunded tour stays playable forever.
    func test_entitlements_storingEmptySetClearsPreviousUnlocks() {
        let (store, _) = makeStore()
        store.store([UUID(), UUID()], uid: "user-a")
        store.store([], uid: "user-a")
        XCTAssertTrue(store.tourIds(uid: "user-a").isEmpty)
    }

    func test_entitlements_insertAddsWithoutDroppingExisting() {
        let (store, _) = makeStore()
        let first = UUID(), second = UUID()
        store.store([first], uid: "user-a")
        store.insert(second, uid: "user-a")
        XCTAssertEqual(store.tourIds(uid: "user-a"), [first, second])
    }

    func test_entitlements_clearRemovesOnlyThatUser() {
        let (store, _) = makeStore()
        let a = UUID(), b = UUID()
        store.store([a], uid: "user-a")
        store.store([b], uid: "user-b")
        store.clear(uid: "user-a")
        XCTAssertTrue(store.tourIds(uid: "user-a").isEmpty)
        XCTAssertEqual(store.tourIds(uid: "user-b"), [b])
    }

    // MARK: - Pending purchase queue

    private func makeQueue() -> PendingPurchaseQueue {
        let suite = "PaidTourTests.queue.\(UUID().uuidString)"
        return PendingPurchaseQueue(defaults: UserDefaults(suiteName: suite)!)
    }

    /// The queue is the only place the transaction↔tour link survives a dead
    /// spot — Apple's receipt never names a tour — so a paid-but-unrecorded
    /// purchase must persist and replay exactly once.
    func test_pendingQueue_enqueueAndRemove() {
        let queue = makeQueue()
        let tour = UUID()
        queue.enqueue(transactionId: "txn-1", tourId: tour, signedTransaction: "jws-1", uid: "user-a")
        XCTAssertEqual(queue.all(uid: "user-a").count, 1)
        XCTAssertEqual(queue.entry(forTransactionId: "txn-1", uid: "user-a")?.tourId, tour)
        XCTAssertEqual(queue.entry(forTransactionId: "txn-1", uid: "user-a")?.signedTransaction, "jws-1")

        queue.remove(transactionId: "txn-1", uid: "user-a")
        XCTAssertTrue(queue.all(uid: "user-a").isEmpty)
    }

    /// Re-enqueuing the same transaction (a retry) must not duplicate it,
    /// or a replay would POST the same sale repeatedly.
    func test_pendingQueue_isIdempotentPerTransaction() {
        let queue = makeQueue()
        let tour = UUID()
        queue.enqueue(transactionId: "txn-1", tourId: tour, signedTransaction: "jws-1", uid: "user-a")
        queue.enqueue(transactionId: "txn-1", tourId: tour, signedTransaction: "jws-1", uid: "user-a")
        XCTAssertEqual(queue.all(uid: "user-a").count, 1)
    }

    func test_pendingQueue_holdsMultipleDistinctPurchases() {
        let queue = makeQueue()
        queue.enqueue(transactionId: "txn-1", tourId: UUID(), signedTransaction: "a", uid: "user-a")
        queue.enqueue(transactionId: "txn-2", tourId: UUID(), signedTransaction: "b", uid: "user-a")
        XCTAssertEqual(queue.all(uid: "user-a").count, 2)
        queue.remove(transactionId: "txn-1", uid: "user-a")
        XCTAssertEqual(queue.all(uid: "user-a").map(\.transactionId), ["txn-2"])
    }

    /// A queued purchase belongs to the account that made it, and to no
    /// other. `handleSignedIn()` drains this queue, and `record-purchase`
    /// attributes the sale to whichever token made the call — so a shared
    /// key would let A's unrecorded payment be recorded against B, and
    /// grant B the tour. This is the same isolation `EntitlementStore`
    /// already promises for the unlock cache.
    func test_pendingQueue_isScopedPerUser() {
        let queue = makeQueue()
        let tourA = UUID()
        queue.enqueue(transactionId: "txn-a", tourId: tourA, signedTransaction: "jws-a", uid: "user-a")

        XCTAssertTrue(queue.all(uid: "user-b").isEmpty,
                      "account B must not see account A's pending purchase")
        XCTAssertNil(queue.entry(forTransactionId: "txn-a", uid: "user-b"))
        XCTAssertEqual(queue.all(uid: "user-a").count, 1,
                       "A's own entry must survive B reading the queue")
    }

    /// B removing a transaction id it doesn't own must not delete A's entry.
    func test_pendingQueue_removeIsScopedPerUser() {
        let queue = makeQueue()
        queue.enqueue(transactionId: "txn-a", tourId: UUID(), signedTransaction: "jws-a", uid: "user-a")
        queue.remove(transactionId: "txn-a", uid: "user-b")
        XCTAssertEqual(queue.all(uid: "user-a").count, 1)
    }

    /// Signed out there is no account to attribute a purchase to, so the
    /// queue must refuse to store one rather than park it under a blank key
    /// where the next account to sign in would drain it.
    func test_pendingQueue_ignoresMissingUid() {
        let queue = makeQueue()
        queue.enqueue(transactionId: "txn-1", tourId: UUID(), signedTransaction: "jws", uid: nil)
        XCTAssertTrue(queue.all(uid: nil).isEmpty)
        XCTAssertTrue(queue.all(uid: "").isEmpty)
    }

    // MARK: - Preview length

    /// Owner decision 2026-07-28. Single-stop tours median ~135s, so 30s is
    /// about a fifth — enough to judge the narrator, not enough to substitute
    /// for the tour.
    func test_previewLength_is30Seconds() {
        XCTAssertEqual(PurchaseService.previewSeconds, 30)
    }
}
