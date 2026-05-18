import SwiftUI
import CoreLocation

struct SettingsView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(DataService.self) private var dataService

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: AtlasSpacing.md) {
                        Text("Atlas")
                            .font(AtlasTypography.headline)
                        Text("Audio tours, anchored to places.")
                            .font(AtlasTypography.body)
                            .foregroundStyle(AtlasColors.secondaryText)
                        Text("Version 1.0")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.tertiaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .padding(.vertical, AtlasSpacing.lg)
                }

                Section("Account") {
                    HStack {
                        Label("Sign in", systemImage: "person.crop.circle")
                        Spacer()
                        Text("Coming soon")
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                    HStack {
                        Label("Messages", systemImage: "bubble.left.and.bubble.right")
                        Spacer()
                        Text("Coming soon")
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                }

                Section("Location") {
                    HStack {
                        Label("Location Access", systemImage: "location")
                        Spacer()
                        Text(locationStatusText)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }

                    if locationManager.authorizationStatus == .notDetermined {
                        Button {
                            locationManager.requestPermission()
                        } label: {
                            Label("Enable Location", systemImage: "location.circle")
                        }
                    }
                }

                Section("Data") {
                    NavigationLink {
                        ManageDownloadsView()
                    } label: {
                        Label("Manage downloads", systemImage: "arrow.down.circle")
                    }

                    Button {
                        URLCache.shared.removeAllCachedResponses()
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                }

                Section("About") {
                    HStack {
                        Label("Tours", systemImage: "headphones")
                        Spacer()
                        Text("\(dataService.tours.count)")
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                    HStack {
                        Label("Makers", systemImage: "person.2")
                        Spacer()
                        Text("\(dataService.makers.count)")
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                    Label("All data stored on device", systemImage: "iphone")
                }
            }
            .navigationTitle("Settings")
            .inlineNavigationBarTitle()
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
