import Foundation

struct ToursData: Codable {
    let makers: [Maker]
    let tours: [Tour]
    /// Sites that more than one tour describes. **Optional on purpose** — an
    /// older catalog (the on-disk cache written by a previous build, or the
    /// gh-pages mirror before it republishes) carries no `places` key, and must
    /// still decode rather than dropping the whole catalog on the floor.
    let places: [Place]?

    /// Written out rather than synthesized so `places` can default to nil for
    /// callers that predate the place layer. A `let` carrying an initial value
    /// would be skipped by the synthesized decoder entirely — the property
    /// would silently never decode — so the default belongs here, not on the
    /// declaration.
    init(makers: [Maker], tours: [Tour], places: [Place]? = nil) {
        self.makers = makers
        self.tours = tours
        self.places = places
    }
}
