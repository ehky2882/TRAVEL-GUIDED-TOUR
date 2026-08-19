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
    @Environment(AuthService.self) private var authService
    @AppStorage("colorSchemePreference") private var colorSchemePreference: ColorSchemePreference = .system
    @State private var showingSignIn = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    // Base gap is 4pt; the tagline adds 4pt on top so
                    // Dozent↔tagline = 8pt while tagline↔Version = 4pt.
                    VStack(spacing: AtlasSpacing.xs) {
                        // Wordmark, drawn EXACTLY as `SplashView` draws it:
                        // New York serif at 15pt, tracked 2, Title Case. It
                        // was uppercase and tracked 6, which is a logotype
                        // convention that only works on capitals — so the
                        // launch screen and this masthead read as two
                        // different marks (owner, 2026-08-19).
                        //
                        // It stays BRASS here rather than the splash's
                        // white: the splash has a brass circle above it
                        // carrying the accent, and this screen has nothing
                        // else on it that does. Same call the website makes
                        // for its page mastheads (site/atlas.css `.brand`).
                        //
                        // Keep this in step with SplashView and with
                        // `.brand` / `.splash-wordmark` in site/atlas.css.
                        Text("Dozent")
                            .font(AtlasTypography.wordmark)
                            .tracking(2)
                            .foregroundStyle(AtlasColors.mapPin)
                        Text("Audio tours, anchored to places.")
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.secondaryText)
                            .padding(.top, AtlasSpacing.xs)
                        if let versionLine {
                            Text(versionLine)
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.secondaryText)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    // Tight masthead: 4pt row inset + 4pt VStack padding
                    // = 8pt above Dozent and below the version line.
                    .listRowInsets(EdgeInsets(
                        top: AtlasSpacing.xs, leading: AtlasSpacing.md,
                        bottom: AtlasSpacing.xs, trailing: AtlasSpacing.md))
                    .padding(.vertical, AtlasSpacing.xs)
                }

                Section(header: sectionHeader("Account")) {
                    if authService.isSignedIn {
                        HStack {
                            Label(authService.email ?? "Signed in",
                                  systemImage: "person.crop.circle.fill")
                            Spacer()
                        }
                        Button(role: .destructive) {
                            Task { try? await authService.signOut() }
                        } label: {
                            Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                        Button {
                            showingSignIn = true
                        } label: {
                            HStack {
                                Label("Sign in", systemImage: "person.crop.circle")
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(AtlasTypography.caption)
                                    .foregroundStyle(AtlasColors.secondaryText)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    HStack {
                        Label("Messages", systemImage: "bubble.left.and.bubble.right")
                        Spacer()
                        Text("Coming soon")
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                }

                Section(header: sectionHeader("Appearance")) {
                    ThemeDropdown(selection: $colorSchemePreference)
                }

                Section(header: sectionHeader("Location")) {
                    #if os(iOS) || os(visionOS)
                    // The whole row is tappable and deep-links to Atlas's
                    // page in the system Settings app, where location
                    // access is changed. (The standalone "Open in
                    // Settings" button is now redundant and removed.)
                    Button {
                        openSystemSettings()
                    } label: {
                        HStack {
                            Label("Location Access", systemImage: "location")
                            Spacer()
                            Text(locationStatusText)
                                .foregroundStyle(AtlasColors.secondaryText)
                            Image(systemName: "chevron.right")
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.secondaryText)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint("Opens the Settings app to change Atlas's location access.")
                    #else
                    HStack {
                        Label("Location Access", systemImage: "location")
                        Spacer()
                        Text(locationStatusText)
                            .foregroundStyle(AtlasColors.secondaryText)
                    }
                    #endif

                    if locationManager.authorizationStatus == .notDetermined {
                        Button {
                            locationManager.requestPermission()
                        } label: {
                            Label("Enable Location", systemImage: "location.circle")
                        }
                    }
                }

                Section(header: sectionHeader("Data")) {
                    NavigationLink {
                        ManageDownloadsView()
                    } label: {
                        Label("Manage downloads", systemImage: "arrow.down.circle")
                    }

                    Button {
                        URLCache.shared.removeAllCachedResponses()
                        #if canImport(UIKit)
                        ImageCache.shared.clear()
                        #endif
                    } label: {
                        Label("Clear Cache", systemImage: "trash")
                    }
                }

                // Apple expects an app carrying user-generated content and
                // in-app purchases to surface its terms in-app, and Stripe's
                // platform review cites the acceptable use policy. The pages
                // are canonical on dozent.world so there is one copy to keep
                // current, rather than a bundled duplicate that silently
                // drifts out of date.
                Section(header: sectionHeader("Legal")) {
                    Link(destination: AtlasLegalLinks.privacy) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: AtlasLegalLinks.terms) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    Link(destination: AtlasLegalLinks.acceptableUse) {
                        Label("Acceptable Use", systemImage: "checkmark.shield")
                    }
                }

                Section(header: sectionHeader("About")) {
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
                    // Was "All data stored on device", which stopped being
                    // true when accounts and cross-device sync shipped: a
                    // signed-in user's library, purchases and creator content
                    // all live on the server. Location genuinely never leaves
                    // the device, so that is what this row claims now.
                    Label("Location never leaves this device", systemImage: "location.slash")
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
            // Spacing pass (tokens only):
            // - pull the masthead up under the nav bar (top gap)
            // - tighten the gap between sections
            // - reduce row height so the mono rows read denser
            .contentMargins(.top, 0, for: .scrollContent)
            .listSectionSpacing(AtlasSpacing.sm)
            .environment(\.defaultMinListRowHeight, AtlasSpacing.xl + AtlasSpacing.xs)
            // No accent gold on this surface: List auto-tints row icons +
            // button labels with the accent, so pin the tint to
            // primaryText instead.
            .tint(AtlasColors.primaryText)
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
            .sheet(isPresented: $showingSignIn) {
                SignInView()
            }
            // Declare the scheme on the sheet itself. The app root sets
            // `.preferredColorScheme`, but a `.sheet` doesn't reliably pick up
            // *changes* to a presenter's preference (SwiftUI quirk — the first
            // toggle applies, the toggle-back gets stuck). Since the theme
            // picker lives on this sheet, applying it here keyed on the same
            // `@AppStorage` value makes the sheet re-render to the right scheme
            // on every toggle.
            .preferredColorScheme(colorSchemePreference.colorScheme)
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

    /// The running app's version, read from the bundle rather than typed
    /// into the masthead — `Info.plist` fills both keys from the build
    /// settings (`CFBundleShortVersionString` = `$(MARKETING_VERSION)`,
    /// `CFBundleVersion` = `$(CURRENT_PROJECT_VERSION)`), so this can
    /// never disagree with the binary the way a literal did: the label
    /// still read "Version 1.0" at marketing version 1.1, build 75.
    ///
    /// The build number is shown because a marketing version alone
    /// cannot identify a TestFlight build, and "which build are you on?"
    /// is the first question asked whenever a tester reports something.
    ///
    /// Both keys are declared in `Info.plist`, so nil here means the
    /// bundle is malformed; the row is dropped rather than printed as a
    /// placeholder, since a wrong-looking version is worse than none.
    private var versionLine: String? {
        let info = Bundle.main.infoDictionary
        guard let marketing = info?["CFBundleShortVersionString"] as? String,
              !marketing.isEmpty else { return nil }
        guard let build = info?["CFBundleVersion"] as? String,
              !build.isEmpty else { return "Version \(marketing)" }
        return "Version \(marketing) (\(build))"
    }

    /// Section header styled to match the rest of the screen: caption
    /// mono, ALL CAPS, secondary tint — instead of the system grey
    /// Title-Case header.
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
            .textCase(.uppercase)
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
                    .foregroundStyle(AtlasColors.primaryText)
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
                            .foregroundStyle(AtlasColors.primaryText)
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
