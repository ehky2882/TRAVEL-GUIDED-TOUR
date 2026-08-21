import SwiftUI

/// The app's map pin vocabulary, shared by every map surface.
///
/// These lived `private` inside `HomeMapSection` until 2026-07-27, and
/// the cost of that was already on the books: `TourDetailView`'s inline
/// map had reimplemented `StopPin` and `UserLocationDot` by hand, with a
/// comment saying it had to because the originals were unreachable — and
/// the copies had drifted (a 14pt dot there against Home's 16pt). The
/// maker page's map would have been the third copy.
///
/// Anything drawing a pin on a map should use these. If a surface needs
/// a different size or treatment, add a parameter here rather than a
/// local copy.

// MARK: - Stop pin

/// Small filled circle, accent-tinted. Selected state thickens the
/// ring and bumps the radius so the active pin pops above its
/// neighbors without changing pin density elsewhere.
struct StopPin: View {
    let isSelected: Bool

    init(isSelected: Bool = false) {
        self.isSelected = isSelected
    }

    var body: some View {
        Circle()
            .fill(AtlasColors.mapPin)
            .frame(width: diameter, height: diameter)
            .overlay(
                Circle().stroke(Color.white, lineWidth: isSelected ? 3 : 1.5)
            )
            .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 1)
    }

    private var diameter: CGFloat { isSelected ? 20 : 16 }
}

// MARK: - Cluster pin

/// Cluster badge: a larger circle with a count, in the accent color
/// so it reads as the same family as the individual pins.
struct ClusterPin: View {
    let count: Int

    var body: some View {
        ZStack {
            Circle()
                .fill(AtlasColors.mapPin.opacity(0.25))
                .frame(width: outerDiameter, height: outerDiameter)
            Circle()
                .fill(AtlasColors.mapPin)
                .frame(width: innerDiameter, height: innerDiameter)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
            Text("\(count)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
                .foregroundStyle(.white)
        }
        .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 1)
    }

    private var innerDiameter: CGFloat {
        switch count {
        case ..<10: return 26
        case ..<100: return 30
        default: return 34
        }
    }

    private var outerDiameter: CGFloat { innerDiameter + 10 }
}

// MARK: - Place pin

/// A site several tours describe — the Met steps, Dorchester Square.
///
/// 🔴 **The silhouette is the whole point.** A cluster pin and a place pin both
/// carry a number in brass, but they mean opposite things: a cluster means
/// *zoom in, these will separate*, a place means *tap me, this is one spot*.
/// The design handoff flagged shipping two identical marks for opposite
/// actions as unresolved. So a cluster stays a **circle** and a place is a
/// **capsule** — different shape, same palette, and it still reads in greyscale
/// or to someone who can't distinguish the hue.
///
/// ✅ **Owner-confirmed 2026-08-18** ("i like your capsule"), reviewed on
/// device in TestFlight 1.1 (68) against a real cluster pin. This closes the
/// "place pin vs. cluster pin" question the design handoff left open — it is a
/// decision now, not a placeholder, so don't quietly revert it to a circle for
/// consistency with the cluster. The differing silhouette IS the point, and it
/// costs no second colour (the app has exactly one accent by design).
struct PlacePin: View {
    let count: Int
    var isSelected: Bool = false

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: "mappin")
                .font(.system(size: 10, weight: .semibold))
            Text("\(count)")
                .font(.system(size: 12, weight: .regular, design: .monospaced))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 8)
        .frame(height: height)
        .background(
            Capsule().fill(AtlasColors.mapPin)
        )
        .overlay(
            Capsule().stroke(Color.white, lineWidth: isSelected ? 3 : 1.5)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 1.5, y: 1)
    }

    private var height: CGFloat { isSelected ? 30 : 26 }
}

// MARK: - User location

/// iOS-Maps-style user-location indicator: a soft accuracy halo, an
/// optional directional wedge showing which way the device is
/// facing, and the blue dot itself. All colors are explicit (not
/// `.tint`-derived) so the dot stays Apple-Maps blue rather than
/// inheriting the gold app accent.
struct UserLocationDot: View {
    /// Screen-space rotation for the heading wedge, in degrees
    /// (0 = pointing up). `nil` hides the wedge.
    let headingDegrees: Double?

    init(headingDegrees: Double? = nil) {
        self.headingDegrees = headingDegrees
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.15))
                .frame(width: 46, height: 46)

            if let headingDegrees {
                HeadingWedge()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.55), Color.blue.opacity(0)],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .frame(width: 34, height: 26)
                    .offset(y: -16)
                    .rotationEffect(.degrees(headingDegrees))
            }

            Circle()
                .fill(Color.blue)
                .frame(width: 16, height: 16)
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
                .shadow(color: Color.black.opacity(0.25), radius: 1.5)
        }
        .frame(width: 46, height: 46)
    }
}

/// A fan/cone — apex at bottom-center (over the dot), spreading
/// toward the top. Rotated by the device heading so it points the
/// way the user is facing.
struct HeadingWedge: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.55)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Launch bloom

extension View {
    /// The launch hand-off's pin arrival: scale + fade, driven by a plain
    /// value so it can be applied to a **map annotation**.
    ///
    /// 🔴 Deliberately not a `.transition`. MapKit rebuilds annotation views
    /// whenever the region changes, so an insertion animation replays every
    /// time the map settles — and the home map emits settle frames for seconds
    /// after any camera move. A view reading a number simply picks up wherever
    /// that number currently is.
    ///
    /// `progress` defaults to 1 at every call site outside the launch, so the
    /// maker map, tour detail's inline map and the place layer are untouched.
    func atlasPinBloom(_ progress: Double) -> some View {
        let p = min(max(progress, 0), 1)
        // Overshoot slightly on the way in so the pin lands rather than simply
        // appearing — the same easing character as the mark's own arrival.
        let overshoot = sin(p * .pi) * 0.12
        return self
            .scaleEffect(p == 1 ? 1 : 0.3 + 0.7 * p + overshoot)
            .opacity(p)
    }
}
