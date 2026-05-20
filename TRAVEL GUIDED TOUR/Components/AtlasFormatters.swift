import Foundation

/// Locale-aware duration + distance formatters used throughout the
/// app. Replaces five copies of hand-rolled `formattedDuration` and
/// the hardcoded `"m"` / `"km"` / `"min"` literals that were
/// double-broken for non-English / non-metric users (audit P2-5,
/// also closes the P3-2 DRY gap).
enum AtlasFormatters {

    // MARK: - Duration

    /// Renders an audio duration as `"5 min"`, `"45 sec"`, or
    /// `"1 hr 5 min"` — adapting unit words to the device's locale.
    /// Uses `.abbreviated` style so the strings stay short on rail
    /// cards and metadata rows. Drops the zero component for cleaner
    /// reading (`"5 min"` instead of `"5 min 0 sec"`).
    static func duration(seconds: Int) -> String {
        let total = TimeInterval(max(0, seconds))
        if total < 60 {
            // Sub-minute → second-only formatter so we don't emit "0 min 30 sec".
            return secondFormatter.string(from: total) ?? "\(seconds)s"
        }
        return durationFormatter.string(from: total) ?? "\(seconds / 60) min"
    }

    private static let durationFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.hour, .minute]
        f.unitsStyle = .abbreviated
        f.zeroFormattingBehavior = .dropAll
        f.maximumUnitCount = 2
        return f
    }()

    private static let secondFormatter: DateComponentsFormatter = {
        let f = DateComponentsFormatter()
        f.allowedUnits = [.second]
        f.unitsStyle = .abbreviated
        return f
    }()

    // MARK: - Distance

    /// Renders a distance in meters using the device's preferred unit
    /// system. Metric locales see `"850 m"` / `"1.2 km"`; imperial
    /// locales see `"930 yd"` / `"0.75 mi"`. `.naturalScale` picks the
    /// most-appropriate unit within the system.
    static func distance(meters: Double) -> String {
        let measurement = Measurement<UnitLength>(value: meters, unit: .meters)
        return distanceFormatter.string(from: measurement)
    }

    /// Distance phrased as "{distance} away" for the home rail subtitle
    /// and tour list cards. The "away" word stays English-only until
    /// the broader app strings are wrapped in NSLocalizedString —
    /// scoping P2-5 to numeric formatters.
    static func distanceAway(meters: Double) -> String {
        "\(distance(meters: meters)) away"
    }

    private static let distanceFormatter: MeasurementFormatter = {
        let f = MeasurementFormatter()
        f.unitOptions = .naturalScale
        f.unitStyle = .medium
        f.numberFormatter.maximumFractionDigits = 1
        f.numberFormatter.minimumFractionDigits = 0
        return f
    }()
}
