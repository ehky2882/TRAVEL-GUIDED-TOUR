import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: AtlasSpacing.md) {
                        Text("Atlas")
                            .font(.system(size: 32, weight: .bold, design: .serif))
                            .foregroundStyle(AtlasColors.primaryText)
                        Text("Curated urban art, culture & design")
                            .font(AtlasTypography.callout)
                            .foregroundStyle(AtlasColors.secondaryText)
                        Text("Version 1.0")
                            .font(.system(size: 12))
                            .foregroundStyle(AtlasColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, AtlasSpacing.lg)
                }

                Section("Location") {
                    HStack {
                        Label("Location Access", systemImage: "location")
                        Spacer()
                        Text(locationStatusText)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }

                    if locationManager.authorizationStatus == .notDetermined {
                        Button {
                            locationManager.requestPermission()
                        } label: {
                            Label("Enable Location", systemImage: "location.circle")
                                .foregroundStyle(AtlasColors.accent)
                        }
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        URLCache.shared.removeAllCachedResponses()
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                }

                Section("About") {
                    HStack {
                        Label("Cities", systemImage: "map")
                        Spacer()
                        Text("3")
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                    HStack {
                        Label("Curated Places", systemImage: "mappin.and.ellipse")
                        Spacer()
                        Text("45")
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                    Label("No account required", systemImage: "person.slash")
                        .foregroundStyle(AtlasColors.secondaryText)
                    Label("All data stored on device", systemImage: "iphone")
                        .foregroundStyle(AtlasColors.secondaryText)
                }
                .font(AtlasTypography.callout)

                Section {
                    VStack(spacing: AtlasSpacing.xs) {
                        Text("If this app were a store, it would be")
                            .font(.system(size: 12))
                            .foregroundStyle(AtlasColors.tertiaryText)
                        Text("a gallery bookshop, not a gift shop.")
                            .font(.system(size: 12, weight: .medium, design: .serif))
                            .foregroundStyle(AtlasColors.secondaryText)
                            .italic()
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, AtlasSpacing.sm)
                }
            }
            .navigationTitle("Settings")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .atlasTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(AtlasColors.accent)
                }
            }
        }
    }

    private var locationStatusText: String {
        switch locationManager.authorizationStatus {
        case .authorizedAlways: return "Always"
        case .denied, .restricted: return "Denied"
        case .notDetermined: return "Not Asked"
        default:
            #if os(iOS) || os(visionOS)
            if locationManager.authorizationStatus == .authorizedWhenInUse {
                return "While Using"
            }
            #endif
            return "Unknown"
        }
    }
}
