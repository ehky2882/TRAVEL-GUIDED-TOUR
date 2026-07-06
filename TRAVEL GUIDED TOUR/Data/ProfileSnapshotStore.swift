import Foundation

/// Persists a single `Codable` value to UserDefaults, **scoped to the signed-in
/// user**, so a service can hydrate its in-memory state on the first frame after
/// launch (stale-while-revalidate) instead of showing a placeholder / empty feed
/// until the network returns.
///
/// The Me tab (`ProfileView` → `MakerView`) is rebuilt on every tab switch and,
/// on a cold launch, its backing services (`MakerProfileService.myMaker`,
/// `MakerTourService.myTours`) start empty and only load from Supabase when the
/// tab is first opened — so the first Me tap after launch flashes placeholder
/// name/avatar + an empty tour list before the real data arrives. Hydrating
/// those services from a cached snapshot at init removes that lag; the network
/// load then refreshes them in place.
///
/// Keyed by user id: a snapshot only ever loads for the account that wrote it,
/// so one user never sees another's cached profile.
final class ProfileSnapshotStore<Value: Codable> {
    private let defaults: UserDefaults
    private let name: String

    init(_ name: String, defaults: UserDefaults = .standard) {
        self.name = name
        self.defaults = defaults
    }

    /// The cached value for `uid`, or `nil` if none / signed out / decode fails.
    func load(uid: String?) -> Value? {
        guard let uid, let data = defaults.data(forKey: key(uid)) else { return nil }
        return try? JSONDecoder().decode(Value.self, from: data)
    }

    func save(_ value: Value, uid: String?) {
        guard let uid, let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key(uid))
    }

    func clear(uid: String?) {
        guard let uid else { return }
        defaults.removeObject(forKey: key(uid))
    }

    private func key(_ uid: String) -> String { "profileSnapshot.\(name).\(uid)" }
}
