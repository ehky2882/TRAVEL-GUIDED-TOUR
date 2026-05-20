import SwiftUI
import CoreLocation
#if os(iOS) || os(visionOS)
import UIKit
#endif

/// User's choice for the app's color scheme. Stored in
/// `UserDefaults` via `@AppStorage("colorSchemePreference")`.
/// Default is `.system` (follow the device's setting). The app
/// entry reads this and applies `.preferredColorScheme(...)` to
/// the root view.
enum ColorSchemePreference: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    /// The SwiftUI `ColorScheme` to force, or `nil` to follow the
    /// device's setting.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

struct SettingsView: View {
    @Environment(LocationManager.self) private var locationManager
    @Environment(DataService.self) private var dataService
    @AppStorage("colorSchemePreference") private var colorSchemePreference: ColorSchemePreference = .system

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

                Section("Appearance") {
                    Picker(selection: $colorSchemePreference) {
                        ForEach(ColorSchemePreference.allCases) { pref in
                            Text(pref.label).tag(pref)
                        }
                    } label: {
                        Label("Theme", systemImage: "circle.lefthalf.filled")
                    }
                    .pickerStyle(.menu)
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

                    #if os(iOS) || os(visionOS)
                    if locationManager.authorizationStatus == .denied
                        || locationManager.authorizationStatus == .restricted {
                        Button {
                            openSystemSettings()
                        } label: {
                            Label("Open in Settings", systemImage: "gear")
                        }
                        .accessibilityHint("Opens the iOS Settings app to grant Atlas location access.")
                    }
                    #endif
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

    #if os(iOS) || os(visionOS)
    private func openSystemSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(url) else {
            return
        }
        UIApplication.shared.open(url)
    }
    #endif

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
