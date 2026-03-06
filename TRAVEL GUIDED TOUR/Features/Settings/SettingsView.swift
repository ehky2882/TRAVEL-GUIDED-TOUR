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
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Text("Curated urban art, culture & design")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Text("Version 1.0")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, AtlasSpacing.lg)
                }

                Section {
                    HStack {
                        Label("Location Access", systemImage: "location")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Spacer()
                        Text(locationStatusText)
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }

                    if locationManager.authorizationStatus == .notDetermined {
                        Button {
                            locationManager.requestPermission()
                        } label: {
                            Label("Enable Location", systemImage: "location.circle")
                                .font(AtlasTypography.standard)
                                .foregroundStyle(.black)
                        }
                    }
                } header: {
                    Text("Location")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                }

                Section {
                    Button {
                        URLCache.shared.removeAllCachedResponses()
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }
                } header: {
                    Text("Data")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                }

                Section {
                    HStack {
                        Label("Cities", systemImage: "map")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Spacer()
                        Text("3")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }
                    HStack {
                        Label("Curated Places", systemImage: "mappin.and.ellipse")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Spacer()
                        Text("45")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }
                    Label("No account required", systemImage: "person.slash")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                    Label("All data stored on device", systemImage: "iphone")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                } header: {
                    Text("About")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                }

                Section {
                    VStack(spacing: AtlasSpacing.xs) {
                        Text("If this app were a store, it would be")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Text("a gallery bookshop, not a gift shop.")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
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
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
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
