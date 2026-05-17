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
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Text("Audio tours, anchored to places.")
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
                        Label("Sign in", systemImage: "person.crop.circle")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Spacer()
                        Text("Coming soon")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                    HStack {
                        Label("Messages", systemImage: "bubble.left.and.bubble.right")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Spacer()
                        Text("Coming soon")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                } header: {
                    Text("Account")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
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
                    NavigationLink {
                        ManageDownloadsView()
                    } label: {
                        Label("Manage downloads", systemImage: "arrow.down.circle")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }

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
                        Label("Tours", systemImage: "headphones")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Spacer()
                        Text("\(dataService.tours.count)")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }
                    HStack {
                        Label("Makers", systemImage: "person.2")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                        Spacer()
                        Text("\(dataService.makers.count)")
                            .font(AtlasTypography.standard)
                            .foregroundStyle(.black)
                    }
                    Label("All data stored on device", systemImage: "iphone")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
                } header: {
                    Text("About")
                        .font(AtlasTypography.standard)
                        .foregroundStyle(.black)
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
