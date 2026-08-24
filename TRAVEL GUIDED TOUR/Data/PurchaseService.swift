import Foundation
import Observation
import StoreKit
import Supabase

/// Buying and unlocking paid tours (V2 Step 6, Phase 3).
///
/// **The shape of the problem.** The ten App Store products are *tiers*
/// (`tour.tier.299`), reused across every paid tour — Apple has no idea
/// tours exist. So Apple's receipt proves *someone paid $2.99*, never
/// *which tour*. The app therefore sends the signed transaction **plus the
/// tour id** to the `record-purchase` Edge Function, which re-fetches the
/// transaction from Apple under our own key, checks the tour's price tier
/// matches what was actually paid, and writes the `purchases` row. That row
/// — not anything on this device — is the entitlement.
///
/// **What this class is allowed to decide:** what to show, and what to
/// unlock locally. It cannot grant itself anything the server hasn't
/// written. `isUnlocked` reading `true` on a tampered device unlocks audio
/// on *that* device and nothing else: no purchase row, no maker credit, and
/// the next successful refresh overwrites it.
///
/// **Offline is a first-class case, not an edge case.** Atlas is for
/// walking around with no signal. Entitlements are cached to disk
/// (`EntitlementStore`) and hydrated synchronously at init, so a tour you
/// bought plays in a dead spot, and a failed refresh never re-locks it.
@MainActor
@Observable
final class PurchaseService {

    /// How much of a paid tour anyone can hear before buying, in seconds.
    ///
    /// Owner decision 2026-07-28. Single-stop tours cluster tightly around
    /// **135s** (p10 113s, p90 165s), so 30s is ~22% — the opening *plus*
    /// the first real idea, which is the least that lets someone judge the
    /// narrator. 15s was considered and rejected: an Atlas script is barely
    /// past scene-setting by then, so it samples the premise but not the
    /// voice, and the voice is what's being sold.
    ///
    /// **Tuning this is a one-line change** — nothing else encodes 30.
    static let previewSeconds: TimeInterval = 30

    enum PurchaseOutcome: Equatable {
        case purchased
        case userCancelled
        /// Apple has the payment in flight (Ask to Buy / SCA). Nothing is
        /// unlocked yet; the entitlement lands via `Transaction.updates`.
        case pending
        /// StoreKit reports the product already bought on this Apple ID but
        /// we had no row for it — treated as success once re-recorded.
        case alreadyOwned
    }

    enum PurchaseError: LocalizedError {
        case notSignedIn
        case productUnavailable
        case verificationFailed
        case recordingFailed

        var errorDescription: String? {
            switch self {
            case .notSignedIn:
                return "Sign in to buy this tour, so your purchase follows you to any device."
            case .productUnavailable:
                return "This tour isn't available for purchase right now. Try again shortly."
            case .verificationFailed:
                return "Apple couldn't verify that purchase. You have not been charged twice."
            case .recordingFailed:
                return "Payment went through, but unlocking failed. Reopen the app to finish — you won't be charged again."
            }
        }
    }

    /// Tour ids the signed-in user owns. Seeded from disk at init so the
    /// first frame after launch is already correct.
    private(set) var entitlements: Set<UUID> = []
    /// Loaded StoreKit products keyed by product id, for localized pricing.
    private(set) var products: [String: Product] = [:]
    /// Tour ids with a purchase in flight — drives per-button spinners.
    private(set) var inFlight: Set<UUID> = []

    private let client: SupabaseClient
    private let auth: AuthService
    private let store: EntitlementStore
    private let pending: PendingPurchaseQueue
    private var updatesTask: Task<Void, Never>?

    private var uid: String? { auth.user?.id.uuidString.lowercased() }

    init(
        auth: AuthService,
        client: SupabaseClient = SupabaseClientProvider.shared,
        store: EntitlementStore = EntitlementStore(),
        pending: PendingPurchaseQueue = PendingPurchaseQueue()
    ) {
        self.auth = auth
        self.client = client
        self.store = store
        self.pending = pending
        // Synchronous hydrate: AuthService restores its session in its own
        // init, so the uid is already known here and the first paint of any
        // paid tour is correct rather than briefly locked.
        self.entitlements = store.tourIds(uid: uid)
        listenForTransactionUpdates()
    }

    // No `deinit` cancel: `updatesTask` is main-actor isolated and a deinit
    // is not, so touching it there doesn't compile under strict concurrency.
    // It isn't needed either — the loop captures `self` weakly and returns
    // the moment the service goes away, and in practice this is built once
    // at App init and lives for the process.

    // MARK: - Reading

    /// Whether this tour's audio may play in full. Free tours are always
    /// unlocked — the entire catalog today.
    /// Seconds of preview to allow for this tour, or `nil` for unlimited.
    ///
    /// 🔴 One definition, because a lock enforced in one place is not enforced
    /// until EVERY place enforces it. `TourDetailView`'s play button used to
    /// own this rule privately; the fullscreen video viewer needs the same
    /// answer, and a second copy computed slightly differently is how the
    /// session-91 overflow-menu paywall hole happened. Anything that can
    /// START a tour must call this first.
    func previewLimit(for tour: Tour) -> TimeInterval? {
        guard tour.isPaid, !isUnlocked(tour) else { return nil }
        return Self.previewSeconds
    }

    func isUnlocked(_ tour: Tour) -> Bool {
        guard tour.isPaid else { return true }
        return entitlements.contains(tour.id)
    }

    /// The price to show, localized by App Store storefront when StoreKit
    /// has loaded (so a UK buyer sees £, not a converted-looking $). Falls
    /// back to the USD tier only until products arrive.
    func displayPrice(for tour: Tour) -> String? {
        guard tour.isPaid else { return nil }
        if let id = tour.storeProductId, let product = products[id] {
            return product.displayPrice
        }
        return tour.fallbackPriceText
    }

    func isPurchasing(_ tour: Tour) -> Bool { inFlight.contains(tour.id) }

    // MARK: - Products

    /// Load the StoreKit products for whichever tiers the catalog actually
    /// uses. Cheap and idempotent; safe to call on catalog refresh.
    func loadProducts(for tours: [Tour]) async {
        let ids = Set(tours.compactMap(\.storeProductId))
        guard !ids.isEmpty else { return }
        do {
            let loaded = try await Product.products(for: ids)
            for product in loaded { products[product.id] = product }
        } catch {
            // Non-fatal: badges fall back to the USD tier text and the Buy
            // button reports `.productUnavailable` if actually tapped.
            print("PurchaseService: product load failed — \(error)")
        }
    }

    // MARK: - Buying

    /// Run Apple's payment sheet for this tour, then record the sale.
    ///
    /// Sign-in is required *before* paying, deliberately: the entitlement is
    /// keyed to the Supabase account, so buying anonymously would strand the
    /// purchase on one device with no way to restore it.
    @discardableResult
    func purchase(_ tour: Tour) async throws -> PurchaseOutcome {
        guard auth.isSignedIn else { throw PurchaseError.notSignedIn }
        guard let productId = tour.storeProductId else { throw PurchaseError.productUnavailable }

        if products[productId] == nil { await loadProducts(for: [tour]) }
        guard let product = products[productId] else { throw PurchaseError.productUnavailable }

        inFlight.insert(tour.id)
        defer { inFlight.remove(tour.id) }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            throw PurchaseError.productUnavailable
        }

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            // Remember the tour↔receipt link BEFORE finishing, so a crash or
            // dead spot between here and the network call can still be
            // replayed. StoreKit alone can never tell us which tour this was
            // for — only this record can. The JWS is stored with it because
            // that is what `record-purchase` needs to re-verify with Apple.
            let jws = verification.jwsRepresentation
            pending.enqueue(
                transactionId: String(transaction.id),
                tourId: tour.id,
                signedTransaction: jws,
                uid: uid
            )

            do {
                try await record(
                    transactionId: String(transaction.id),
                    tourId: tour.id,
                    signedTransaction: jws
                )
            } catch {
                // Paid but unrecorded. Unlock nothing — the server is the
                // authority — and deliberately DO NOT finish the transaction.
                // Finishing tells Apple the content was delivered, after
                // which it stops re-delivering through `Transaction.updates`;
                // leaving it unfinished means every launch hands it back to
                // us until the recording succeeds, which is a second recovery
                // path alongside the queued entry.
                //
                // Residual limit, stated honestly rather than papered over:
                // if this device's queue is also lost (app deleted before the
                // replay lands), the sale still cannot be attributed to a
                // tour, because nothing on Apple's side names one. That needs
                // a server-side reconciliation, not a client change.
                throw PurchaseError.recordingFailed
            }
            await transaction.finish()
            grantLocally(tour.id)
            return .purchased

        case .userCancelled:
            return .userCancelled

        case .pending:
            return .pending

        @unknown default:
            return .pending
        }
    }

    /// Restore purchases made on another device (or reinstall). The
    /// `purchases` table already is the restore mechanism, so this is just a
    /// refresh plus a StoreKit sync for good measure.
    func restore() async {
        try? await AppStore.sync()
        await replayPendingRecords()
        await refreshEntitlements()
    }

    // MARK: - Entitlements

    /// Re-read the authoritative entitlement set for the signed-in user.
    /// On failure the in-memory set is left alone — a flaky connection must
    /// never re-lock a tour someone paid for.
    func refreshEntitlements() async {
        guard let uid else {
            entitlements = []
            return
        }
        struct Row: Decodable { let tour_id: UUID }
        do {
            // The `user_id` filter is belt-and-braces: RLS already scopes
            // `purchases` to the caller's own rows, and that policy is what
            // actually protects this. Asking for our own rows explicitly
            // costs nothing and means a future policy change can't quietly
            // turn this into "every purchase in the table", which would
            // unlock the whole paid catalog for everyone.
            let rows: [Row] = try await client
                .from("purchases")
                .select("tour_id")
                .eq("user_id", value: uid)
                .is("refunded_at", value: nil)
                .execute()
                .value
            let ids = Set(rows.map(\.tour_id))
            entitlements = ids
            store.store(ids, uid: uid)
        } catch {
            print("PurchaseService: entitlement refresh failed — \(error)")
        }
    }

    /// Called on sign-out: drop this account's unlocks from memory so the
    /// next user doesn't inherit them. The on-disk cache stays keyed by the
    /// old uid, so signing back in is instant.
    func handleSignedOut() {
        entitlements = []
    }

    /// Called after a sign-in (or account switch) — hydrate from that user's
    /// cache immediately, then confirm against the server.
    func handleSignedIn() async {
        entitlements = store.tourIds(uid: uid)
        await replayPendingRecords()
        await refreshEntitlements()
    }

    // MARK: - Recording

    /// POST the receipt to `record-purchase`. Field names must match that
    /// function's contract exactly (`tourId` + `signedTransaction`) — it
    /// re-fetches the transaction from Apple and refuses anything whose tier
    /// doesn't match the tour's price, so a mismatch here fails closed.
    private func record(transactionId: String, tourId: UUID, signedTransaction: String) async throws {
        struct Body: Encodable {
            let tourId: String
            let signedTransaction: String
        }
        _ = try await client.functions.invoke(
            "record-purchase",
            options: FunctionInvokeOptions(
                body: Body(
                    tourId: tourId.uuidString.lowercased(),
                    signedTransaction: signedTransaction
                )
            )
        ) { data, _ in data }
        pending.remove(transactionId: transactionId, uid: uid)
    }

    /// Drain purchases that were paid for but never recorded (dead spot,
    /// crash, app killed mid-flight). Safe to run repeatedly: the server
    /// de-duplicates on Apple's transaction id, so a re-send is a no-op.
    func replayPendingRecords() async {
        guard auth.isSignedIn else { return }
        for entry in pending.all(uid: uid) {
            do {
                try await record(
                    transactionId: entry.transactionId,
                    tourId: entry.tourId,
                    signedTransaction: entry.signedTransaction
                )
                grantLocally(entry.tourId)
            } catch {
                // Leave it queued; try again next launch.
                print("PurchaseService: replay failed for \(entry.transactionId) — \(error)")
            }
        }
    }

    // MARK: - Internals

    private func grantLocally(_ tourId: UUID) {
        entitlements.insert(tourId)
        store.insert(tourId, uid: uid)
    }

    private func checkVerified(_ result: VerificationResult<StoreKit.Transaction>) throws -> StoreKit.Transaction {
        switch result {
        case .verified(let safe): return safe
        case .unverified: throw PurchaseError.verificationFailed
        }
    }

    /// StoreKit can hand us transactions we didn't start — an Ask to Buy
    /// approval that lands later, or a purchase made on another device.
    /// We finish them so Apple stops re-delivering, and record any whose
    /// tour we can identify from the pending queue. A transaction with no
    /// queued intent (e.g. Family Sharing) can't be attributed to a tour at
    /// all — nothing on Apple's side names one — so it is finished and left
    /// for the server-side entitlement refresh to reconcile.
    private func listenForTransactionUpdates() {
        updatesTask = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                guard let self else { return }
                guard case .verified(let transaction) = update else { continue }
                let id = String(transaction.id)
                guard let entry = self.pending.entry(forTransactionId: id, uid: self.uid) else {
                    // No queued intent, so this transaction can't be tied to a
                    // tour by anything on this device — Family Sharing, or a
                    // purchase whose queue entry belongs to a different
                    // account. Finish it so Apple stops re-delivering, and
                    // leave the server-side entitlement refresh to reconcile.
                    await transaction.finish()
                    continue
                }
                do {
                    try await self.record(
                        transactionId: id,
                        tourId: entry.tourId,
                        signedTransaction: entry.signedTransaction
                    )
                } catch {
                    // Unrecorded: grant nothing and leave it unfinished so
                    // Apple re-delivers on a later launch. Granting here would
                    // unlock a tour the server has no row for — no purchase,
                    // no maker credit — which is exactly what `purchase()`
                    // and `replayPendingRecords()` both refuse to do.
                    print("PurchaseService: update-path record failed for \(id) — \(error)")
                    continue
                }
                await transaction.finish()
                self.grantLocally(entry.tourId)
            }
        }
    }
}

/// Purchases that Apple has taken payment for but Supabase hasn't recorded.
///
/// Exists because Apple's receipt never names a tour: if the recording call
/// fails, the *only* place the transaction↔tour link survives is here. Lose
/// this and a paid tour can't be attributed — so it's written to disk before
/// the network is touched, and cleared only once the server confirms.
///
/// **Scoped per signed-in user id, for the same reason `EntitlementStore`
/// is.** A single shared key would let one account's unrecorded purchase be
/// replayed under another's session: `handleSignedIn()` drains this queue,
/// and `record-purchase` attributes the sale to whoever's token made the
/// call. On a shared phone that credits A's payment to B — and grants B the
/// tour. Keying by uid means a queued purchase can only ever be replayed by
/// the account that made it.
struct PendingPurchaseQueue {
    struct Entry: Codable, Equatable {
        let transactionId: String
        let tourId: UUID
        /// Apple's signed receipt. Kept because `record-purchase` re-verifies
        /// it with Apple, so a replay needs the original token, not just its
        /// id. It is a receipt, not a credential — it grants nothing on its
        /// own and the server still checks the tier against the tour.
        let signedTransaction: String
    }

    private let defaults: UserDefaults
    private let keyPrefix = "atlas.pendingPurchases."

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private func key(uid: String) -> String { keyPrefix + uid }

    func all(uid: String?) -> [Entry] {
        guard let uid, !uid.isEmpty,
              let data = defaults.data(forKey: key(uid: uid)),
              let entries = try? JSONDecoder().decode([Entry].self, from: data)
        else { return [] }
        return entries
    }

    func enqueue(transactionId: String, tourId: UUID, signedTransaction: String, uid: String?) {
        guard let uid, !uid.isEmpty else { return }
        var entries = all(uid: uid)
        guard !entries.contains(where: { $0.transactionId == transactionId }) else { return }
        entries.append(
            Entry(
                transactionId: transactionId,
                tourId: tourId,
                signedTransaction: signedTransaction
            )
        )
        persist(entries, uid: uid)
    }

    func entry(forTransactionId id: String, uid: String?) -> Entry? {
        all(uid: uid).first { $0.transactionId == id }
    }

    func remove(transactionId: String, uid: String?) {
        guard let uid, !uid.isEmpty else { return }
        persist(all(uid: uid).filter { $0.transactionId != transactionId }, uid: uid)
    }

    private func persist(_ entries: [Entry], uid: String) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        defaults.set(data, forKey: key(uid: uid))
    }
}
