import SwiftUI

/// Placeholder shown by the profile's "+" (add a tour) affordance.
///
/// Increment 1 of maker authoring (V2 Step 4) establishes the profile
/// shell — the Me tab as a maker-style profile with the `+` in the feed.
/// The real single-stop authoring flow (record / import audio → drop a
/// map pin + radius → add photos → metadata → transcript → submit for
/// review) lands in the following increments. See
/// `docs/maker-dashboard-design.md`.
struct CreateTourPlaceholderView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: AtlasSpacing.lg) {
                Spacer()

                Image(systemName: "waveform.badge.plus")
                    .font(.system(size: 56))
                    .foregroundStyle(AtlasColors.mapPin)

                Text("CREATE A TOUR")
                    .font(AtlasTypography.body)
                    .textCase(.uppercase)
                    .foregroundStyle(AtlasColors.primaryText)

                Text("Record or import audio, drop a pin on the map, add photos, and submit for review. Coming next.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AtlasSpacing.xl)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("NEW TOUR")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.primaryText)
                }
            }
        }
    }
}
