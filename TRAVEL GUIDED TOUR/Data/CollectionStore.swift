import Foundation
import Observation

@Observable
final class CollectionStore {
    private static let storageKey = "atlas_collections"
    private(set) var collections: [PlaceCollection] = []

    init() {
        loadCollections()
        if collections.isEmpty {
            collections = [PlaceCollection(name: "Saved")]
            saveCollections()
        }
    }

    var savedCollection: PlaceCollection {
        collections.first { $0.name == "Saved" } ?? collections[0]
    }

    func isPlaceSaved(_ placeId: UUID) -> Bool {
        collections.contains { $0.placeIds.contains(placeId) }
    }

    func toggleSaved(placeId: UUID) {
        if let index = collections.firstIndex(where: { $0.name == "Saved" }) {
            if collections[index].placeIds.contains(placeId) {
                collections[index].placeIds.removeAll { $0 == placeId }
            } else {
                collections[index].placeIds.append(placeId)
            }
            saveCollections()
        }
    }

    func addPlace(_ placeId: UUID, to collectionId: UUID) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            if !collections[index].placeIds.contains(placeId) {
                collections[index].placeIds.append(placeId)
                saveCollections()
            }
        }
    }

    func removePlace(_ placeId: UUID, from collectionId: UUID) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            collections[index].placeIds.removeAll { $0 == placeId }
            saveCollections()
        }
    }

    func createCollection(name: String) {
        let collection = PlaceCollection(name: name)
        collections.append(collection)
        saveCollections()
    }

    func deleteCollection(_ collectionId: UUID) {
        collections.removeAll { $0.id == collectionId && $0.name != "Saved" }
        saveCollections()
    }

    private func saveCollections() {
        if let data = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }

    private func loadCollections() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let decoded = try? JSONDecoder().decode([PlaceCollection].self, from: data) else {
            return
        }
        collections = decoded
    }
}
