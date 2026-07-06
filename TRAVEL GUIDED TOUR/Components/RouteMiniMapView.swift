import SwiftUI
#if canImport(UIKit)
import UIKit
import MapKit

/// A small static route thumbnail overlaid in the bottom-right corner of
/// a **multi-stop** tour card's hero (the AllTrails route-map cue). It
/// renders an `MKMapSnapshotter` image of the map region fit to the
/// tour's stops, with the stops connected in order by a gold polyline
/// and a dot at each stop.
///
/// - **Multi-stop only.** Single-stop tours render nothing, so the
///   presence of the thumbnail itself signals "this is a walk".
/// - **Decorative.** No tap target of its own — a tap anywhere on the
///   card opens the tour as usual.
/// - **Cached by tour id** (`RouteSnapshotCache`) so scrolling the rails
///   never re-snapshots. Nothing is drawn until the image is ready; it
///   then fades in.
struct RouteMiniMapView: View {
    let tour: Tour
    /// Thumbnail side length in points. Kept small so it reads as a
    /// subtle "this is a walk" cue, not a second hero (owner direction).
    var side: CGFloat = 64

    @Environment(\.displayScale) private var displayScale
    @State private var image: UIImage?

    var body: some View {
        Group {
            if tour.kind == .multiStop, let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: side, height: side)
                    // Corner radius = the 36pt badge circle's radius (18pt),
                    // so the thumbnail's rounding matches the download /
                    // bookmark chips (owner test).
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(.white, lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 2.5, x: 0, y: 1)
                    .transition(.opacity)
            }
        }
        .animation(.easeIn(duration: 0.25), value: image != nil)
        // One snapshot request per tour id; the cache makes repeat
        // appearances (rail recycling, Home staying alive) instant.
        .task(id: tour.id) {
            guard tour.kind == .multiStop else { return }
            if let cached = RouteSnapshotCache.shared.cached(tour.id) {
                image = cached
                return
            }
            let scale = displayScale > 0 ? displayScale : 2
            image = await RouteSnapshotCache.shared.snapshot(
                for: tour,
                size: CGSize(width: side, height: side),
                scale: scale
            )
        }
    }
}

/// In-memory cache of rendered route thumbnails keyed by tour id, plus
/// in-flight de-duplication so the same tour appearing on two shelves at
/// once only snapshots once. `NSCache` evicts under memory pressure, so
/// this never needs manual trimming.
@MainActor
final class RouteSnapshotCache {
    static let shared = RouteSnapshotCache()

    private let cache: NSCache<NSUUID, UIImage> = {
        let c = NSCache<NSUUID, UIImage>()
        // ~10 multi-stop tours today; a generous cap that still bounds RAM.
        c.countLimit = 64
        return c
    }()

    /// Renders already in flight, so concurrent requests for the same
    /// tour await one render instead of racing two snapshotters.
    private var inFlight: [UUID: Task<UIImage?, Never>] = [:]

    /// Synchronous cache peek — lets a view render frame-zero on a hit.
    func cached(_ id: UUID) -> UIImage? { cache.object(forKey: id as NSUUID) }

    func snapshot(for tour: Tour, size: CGSize, scale: CGFloat) async -> UIImage? {
        if let hit = cache.object(forKey: tour.id as NSUUID) { return hit }
        if let existing = inFlight[tour.id] { return await existing.value }

        let coords = tour.stops
            .sorted { $0.order < $1.order }
            .map(\.coordinate)
        guard coords.count >= 2 else { return nil }

        let task = Task<UIImage?, Never> {
            await Self.render(coords: coords, size: size, scale: scale)
        }
        inFlight[tour.id] = task
        let image = await task.value
        inFlight[tour.id] = nil
        if let image { cache.setObject(image, forKey: tour.id as NSUUID) }
        return image
    }

    // MARK: - Rendering (off the main actor)

    nonisolated private static func render(
        coords: [CLLocationCoordinate2D],
        size: CGSize,
        scale: CGFloat
    ) async -> UIImage? {
        // Fit the region to all stops, then pad ~35% so the route never
        // hugs the thumbnail edges.
        var rect = MKMapRect.null
        for c in coords {
            let p = MKMapPoint(c)
            rect = rect.union(MKMapRect(x: p.x, y: p.y, width: 0, height: 0))
        }
        guard !rect.isNull else { return nil }
        let padX = max(rect.size.width * 0.35, 1)
        let padY = max(rect.size.height * 0.35, 1)
        let padded = rect.insetBy(dx: -padX, dy: -padY)

        let options = MKMapSnapshotter.Options()
        options.mapRect = padded
        options.size = size
        options.scale = scale
        // A MUTED standard map with no POIs, no traffic — labels/details
        // recede so the gold route is the prominent element (owner
        // direction: keep the thumbnail about the route, not the map).
        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        config.pointOfInterestFilter = .excludingAll
        config.showsTraffic = false
        options.preferredConfiguration = config
        options.showsBuildings = false
        // Keep the thumbnail a light map regardless of app appearance so
        // its white border + gold route read consistently.
        options.traitCollection = UITraitCollection(userInterfaceStyle: .light)

        let snapshotter = MKMapSnapshotter(options: options)
        let snapshot: MKMapSnapshotter.Snapshot? = await withCheckedContinuation { cont in
            snapshotter.start(with: DispatchQueue.global(qos: .utility)) { snap, _ in
                cont.resume(returning: snap)
            }
        }
        guard let snapshot else { return nil }

        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true
        // Brand accent gold `#8B7535`. Built locally (not via
        // `AtlasColors`) because Core Graphics needs a concrete `UIColor`,
        // and kept off the @MainActor class so this render stays
        // nonisolated. A one-line swap to green if the owner prefers.
        let routeColor = UIColor(red: 0x8B / 255, green: 0x75 / 255, blue: 0x35 / 255, alpha: 1)

        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { ctx in
            snapshot.image.draw(at: .zero)
            let cg = ctx.cgContext
            let points = coords.map { snapshot.point(for: $0) }

            // Route polyline: stops connected in order.
            cg.setStrokeColor(routeColor.cgColor)
            cg.setLineWidth(4)
            cg.setLineJoin(.round)
            cg.setLineCap(.round)
            cg.beginPath()
            cg.move(to: points[0])
            for p in points.dropFirst() { cg.addLine(to: p) }
            cg.strokePath()

            // A dot at each stop: white ring + gold centre.
            for p in points {
                let outer: CGFloat = 3.6
                cg.setFillColor(UIColor.white.cgColor)
                cg.fillEllipse(in: CGRect(
                    x: p.x - outer, y: p.y - outer, width: outer * 2, height: outer * 2
                ))
                let inner: CGFloat = 2.2
                cg.setFillColor(routeColor.cgColor)
                cg.fillEllipse(in: CGRect(
                    x: p.x - inner, y: p.y - inner, width: inner * 2, height: inner * 2
                ))
            }
        }
    }
}
#else
/// macOS / non-UIKit fallback: the route thumbnail relies on
/// `UIGraphicsImageRenderer`, so it renders nothing off-iOS. The type
/// still exists so the shared card views compile on every platform.
struct RouteMiniMapView: View {
    let tour: Tour
    var side: CGFloat = 64
    var body: some View { EmptyView() }
}
#endif
