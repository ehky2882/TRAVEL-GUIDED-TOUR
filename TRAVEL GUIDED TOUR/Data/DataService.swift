import Foundation
import Observation
import CoreLocation

@Observable
final class DataService {
    private(set) var cities: [City] = []
    private(set) var places: [Place] = []

    init() {
        loadSeedData()
    }

    private func loadSeedData() {
        guard let url = Bundle.main.url(forResource: "SeedData", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }
        let decoder = JSONDecoder()
        guard let seed = try? decoder.decode(SeedData.self, from: data) else {
            return
        }
        cities = seed.cities
        places = seed.places
    }

    func places(for city: City) -> [Place] {
        places.filter { $0.cityId == city.id }
    }

    func places(for city: City, category: PlaceCategory) -> [Place] {
        places.filter { $0.cityId == city.id && $0.category == category }
    }

    func featuredPlaces() -> [Place] {
        places.filter { $0.isFeatured }
    }

    func place(by id: UUID) -> Place? {
        places.first { $0.id == id }
    }

    func city(by id: UUID) -> City? {
        cities.first { $0.id == id }
    }

    func city(for place: Place) -> City? {
        cities.first { $0.id == place.cityId }
    }

    func nearbyPlaces(to place: Place, limit: Int = 3) -> [Place] {
        let placeLocation = CLLocation(latitude: place.latitude, longitude: place.longitude)
        return places
            .filter { $0.id != place.id && $0.cityId == place.cityId }
            .sorted { a, b in
                let distA = CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: placeLocation)
                let distB = CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: placeLocation)
                return distA < distB
            }
            .prefix(limit)
            .map { $0 }
    }

    func nearestCity(to location: CLLocation) -> City? {
        cities.min { a, b in
            let distA = CLLocation(latitude: a.latitude, longitude: a.longitude).distance(from: location)
            let distB = CLLocation(latitude: b.latitude, longitude: b.longitude).distance(from: location)
            return distA < distB
        }
    }
}
