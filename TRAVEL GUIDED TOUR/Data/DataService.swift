import Foundation
import Observation
import CoreLocation

@Observable
final class DataService {
    private(set) var tours: [Tour] = []
    private(set) var makers: [Maker] = []

    init() {
        loadTours()
    }

    private func loadTours() {
        guard let url = Bundle.main.url(forResource: "Tours", withExtension: "json"),
              let data = try? Data(contentsOf: url) else {
            return
        }
        let decoder = JSONDecoder()
        guard let bundle = try? decoder.decode(ToursData.self, from: data) else {
            return
        }
        tours = bundle.tours
        makers = bundle.makers
    }

    func tour(by id: UUID) -> Tour? {
        tours.first { $0.id == id }
    }

    func maker(by id: UUID) -> Maker? {
        makers.first { $0.id == id }
    }

    func maker(for tour: Tour) -> Maker? {
        maker(by: tour.makerId)
    }

    func tours(by maker: Maker) -> [Tour] {
        tours.filter { $0.makerId == maker.id }
    }

    func tours(in category: TourCategory) -> [Tour] {
        tours.filter { $0.primaryCategory == category }
    }

    func toursNearby(_ location: CLLocation, limit: Int = 10) -> [Tour] {
        tours
            .sorted { $0.distance(from: location) < $1.distance(from: location) }
            .prefix(limit)
            .map { $0 }
    }
}
