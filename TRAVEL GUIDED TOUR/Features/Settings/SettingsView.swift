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
                        Text("DOZENT")
                            .font(AtlasTypography.caption)
                        Text("Audio tours, anchored to places.")
                            .font(AtlasTypography.caption)
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
                    ThemeDropdown(selection: $colorSchemePreference)
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
            // Merge the page with the bottom island: hide the List's
            // default grouped backdrop, paint our island color, and
            // clear the row (section "card") backgrounds so the whole
            // surface reads as one continuous color.
            .scrollContentBackground(.hidden)
            .background(AtlasColors.secondaryBackground)
            .listRowBackground(Color.clear)
            // Owner-requested: every text element on Settings renders in
            // the caption token (13pt SF Mono). Applied at the List so it
            // cascades into all row labels + values; the masthead's
            // explicit fonts were switched to caption above so they don't
            // override the cascade.
            .font(AtlasTypography.caption)
            .navigationTitle("Settings")
            .inlineNavigationBarTitle()
            // Render the nav-bar title ourselves so it carries the
            // caption token (13pt SF Mono) in ALL CAPS. The principal
            // toolbar item replaces the system inline title visually;
            // `.navigationTitle("Settings")` is kept above so the
            // back-button label on pushed screens still reads "Settings".
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("SETTINGS")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
            }
            // Reserve room at the bottom for the mini-player + tab bar
            // stack so the last settings row is always reachable above
            // the module rather than hidden behind it.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AtlasBottomModule.height())
            }
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

/// Theme chooser styled to look like the native menu picker — a
/// compact one-line row ("Theme … Dark ⌄") — but built ourselves so
/// the popped-up options carry the caption token (13pt SF Mono). The
/// real `.menu` picker can't take a custom font; this presents the
/// three choices in a `.popover` (forced to compact-popover
/// adaptation so it floats anchored to the row on iPhone instead of
/// adapting to a sheet). Tokens only — no hardcoded colors / fonts.
private struct ThemeDropdown: View {
    @Binding var selection: ColorSchemePreference
    @State private var isExpanded = false

    var body: some View {
        Button {
            isExpanded = true
        } label: {
            HStack(spacing: AtlasSpacing.sm) {
                Label("Theme", systemImage: "circle.lefthalf.filled")
                Spacer()
                Text(selection.label)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.accent)
                Image(systemName: "chevron.down")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.18), value: isExpanded)
        .popover(isPresented: $isExpanded) {
            ThemeDropdownMenu(selection: $selection, isExpanded: $isExpanded)
                .presentationCompactAdaptation(.popover)
        }
    }
}

/// The floating card of options shown by `ThemeDropdown`. Each option
/// is a caption-mono row with an accent checkmark on the current
/// selection; picking one updates the binding and closes the popover.
private struct ThemeDropdownMenu: View {
    @Binding var selection: ColorSchemePreference
    @Binding var isExpanded: Bool

    var body: some View {
        VStack(spacing: 0) {
            ForEach(ColorSchemePreference.allCases) { pref in
                Button {
                    selection = pref
                    isExpanded = false
                } label: {
                    HStack(spacing: AtlasSpacing.lg) {
                        Text(pref.label)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.primaryText)
                        Spacer(minLength: 0)
                        Image(systemName: "checkmark")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.accent)
                            .opacity(pref == selection ? 1 : 0)
                    }
                    .padding(.horizontal, AtlasSpacing.md)
                    .padding(.vertical, AtlasSpacing.sm)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(pref == selection ? [.isButton, .isSelected] : .isButton)

                if pref != ColorSchemePreference.allCases.last {
                    Divider()
                }
            }
        }
        .padding(.vertical, AtlasSpacing.xs)
        .frame(minWidth: 168)
    }
}
