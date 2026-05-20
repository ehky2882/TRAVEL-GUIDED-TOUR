import MapKit

extension MKCoordinateRegion {
    /// Returns true when `coordinate` falls inside this region's
    /// bounding box, correctly handling regions that straddle the
    /// antimeridian (the ±180° longitude line). A naive bounding-box
    /// check fails there — e.g. a region centered at longitude 179
    /// with a 4° span has `minLon = 177`, `maxLon = 181`, but a tour
    /// at -179 (= 181 wrapped) would fail `<= 181` because Apple's
    /// longitude domain is [-180, 180]. Splitting into two ranges
    /// at the wrap fixes it (audit P1-7).
    ///
    /// Latitude doesn't wrap; clamping to [-90, 90] is enough.
    func contains(_ coordinate: CLLocationCoordinate2D) -> Bool {
        let minLat = max(-90, center.latitude - span.latitudeDelta / 2)
        let maxLat = min(90, center.latitude + span.latitudeDelta / 2)
        guard coordinate.latitude >= minLat,
              coordinate.latitude <= maxLat else {
            return false
        }

        let rawMinLon = center.longitude - span.longitudeDelta / 2
        let rawMaxLon = center.longitude + span.longitudeDelta / 2

        if rawMinLon < -180 {
            // Region wraps west across the antimeridian.
            let wrappedMin = rawMinLon + 360
            return coordinate.longitude >= wrappedMin
                || coordinate.longitude <= rawMaxLon
        } else if rawMaxLon > 180 {
            // Region wraps east across the antimeridian.
            let wrappedMax = rawMaxLon - 360
            return coordinate.longitude >= rawMinLon
                || coordinate.longitude <= wrappedMax
        } else {
            return coordinate.longitude >= rawMinLon
                && coordinate.longitude <= rawMaxLon
        }
    }
}
