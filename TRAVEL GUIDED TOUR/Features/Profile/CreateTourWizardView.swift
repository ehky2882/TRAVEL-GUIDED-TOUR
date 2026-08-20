import SwiftUI
import MapKit
import CoreLocation

/// Making a tour, as five steps instead of one long form — Location, Details,
/// Photos, Audio, Review — with a progress bar, a Back/Save/Next footer, and a
/// confirmation screen at the end. Replaces the old `CreateTourView`, which
/// asked for everything at once and then handed you off to a second screen.
///
/// **This increment is the shell.** The chrome, the step order, the gating and
/// the draft-as-you-go saving are new; the content of each step is the app's
/// existing authoring UI moved across unchanged. Location's place autocomplete
/// and Details' accordion tags land next, and they slot into these steps
/// without disturbing the flow.
///
/// **The draft is created when you leave step 1**, titled "Untitled tour" until
/// step 2 supplies a real one. That is deliberate: photos and audio upload
/// against a tour id, so one has to exist by step 3 — and it means Save
/// progress works from the first screen rather than being dimmed on the first
/// thing a maker ever sees.
struct CreateTourWizardView: View {
    /// The tour to open, or nil to start a new one. Passing one makes this the
    /// *only* way a maker edits their work — there is no second editor screen.
    var existingTourId: UUID? = nil

    @Environment(MakerProfileService.self) private var makerProfileService
    @Environment(MakerTourService.self) private var makerTourService
    @Environment(LocationManager.self) private var locationManager
    /// Only used to put the mini-player and tab bar back on the way out — the
    /// primary restore lives in `MakerView`, which drives this from its own
    /// presentation state. This is the second of three backstops, and the one
    /// that cannot misfire: it runs when this view is genuinely gone.
    /// Optional so the wizard still renders anywhere the full app environment
    /// isn't present.
    @Environment(AppSharedState.self) private var appShared: AppSharedState?
    @Environment(BottomModuleWindowController.self)
    private var bottomModuleWindow: BottomModuleWindowController?
    @Environment(\.dismiss) private var dismiss

    @State private var step: TourWizardStep = .location
    @State private var draftId: UUID?
    /// True once an existing tour's values have been read in, so the load
    /// can't run twice and clobber an edit in progress.
    @State private var didLoadExisting = false
    @State private var isDeleting = false

    // Step 1 — location
    @State private var radius: Double = 30
    /// 🔴 NEVER `.automatic` OVER EMPTY CONTENT. `Map(position:)` bound to
    /// `.automatic` with nothing to frame makes MapKit resolve a camera, write
    /// back through the binding, re-render, and resolve again — a synchronous
    /// layout loop that the watchdog eventually kills.
    ///
    /// ⚠️ `.automatic` itself is fine and is used elsewhere: `TourSetMap` and
    /// the maker page's map both start there and have never hung, because both
    /// always have pins, so the automatic frame has an answer and settles. Do
    /// not "fix" those. The rule is about the empty case. This screen hits exactly that case on
    /// the edit path: `centerOnUser` is skipped for an existing tour, so
    /// nothing set a camera and `centerCoordinate` was still nil (no
    /// `MapCircle`), leaving an automatic camera over empty content until the
    /// fetched pin arrived. Creating a tour never hung because `centerOnUser`
    /// hands it a concrete region in `onAppear`. Start concrete; every real
    /// value overwrites this within a frame or two.
    // (`Self` is rejected in a stored-property initializer — name the type.)
    @State private var cameraPosition: MapCameraPosition =
        .region(CreateTourWizardView.fallbackRegion)
    @State private var centerCoordinate: CLLocationCoordinate2D?
    /// What the maker typed into "city & country", and what they picked.
    @State private var cityQuery = ""
    @State private var city: String?
    @State private var country: String?
    /// What they typed into "location name". Free text — a tour can be about
    /// a place MapKit has never heard of, so a suggestion is an offer, not a
    /// requirement.
    @State private var locationName = ""
    /// Whether each field's dropdown is showing. Deliberately not derived
    /// from focus — tapping a row resigns focus, which would pull the row out
    /// from under the tap before it registered.
    @State private var showingCitySuggestions = false
    @State private var showingPlaceSuggestions = false
    @State private var isResolvingPlace = false
    @State private var citySearch = PlaceSearchService.cities()
    @State private var placeSearch = PlaceSearchService.venues()

    // Step 2 — details
    @State private var title = ""
    @State private var shortDescription = ""
    @State private var longDescription = ""
    @State private var selectedTags: Set<String> = []
    @State private var architect: String?

    // Step 4 — audio
    @State private var transcript = ""

    // Flow
    @State private var isPersisting = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    /// Which confirmation is up, if any. Deliberately one modifier driven by
    /// an enum rather than two `confirmationDialog`s on the same view: stacking
    /// them makes them fight over a single presentation slot.
    @State private var confirming: Confirmation?
    @State private var outcome: Outcome?
    /// Where the narration upload has got to. Submit waits on it; walking to
    /// Review does not.
    @State private var audioUpload: AudioUploadState = .idle
    /// A signature of everything saved so far, so Close can tell whether
    /// there is anything to lose.
    @State private var savedSignature: String?
    /// 🔴 Whether the swipe-to-dismiss guard is on, held as state rather than
    /// computed at the root.
    ///
    /// `.interactiveDismissDisabled` sits on the outermost view, so whatever
    /// it reads becomes a dependency of the *whole* `NavigationStack` — and
    /// reading `hasUnsavedChanges` there made the live map coordinate one.
    /// Every camera callback then re-evaluated the root body, from inside
    /// `_sheetLayoutInfoLayout:`, which laid the map out again. That is the
    /// hang opening a saved tour. A `Bool` is `Equatable`, so an unchanged
    /// value costs nothing; the `onChange` below keeps it honest.
    @State private var dismissGuarded = false
    /// Shown briefly under the footer after Save progress.
    @State private var savedConfirmation = false
    @FocusState private var focused: Field?

    private enum Field { case city, place, title, short, long }
    private enum Outcome { case submitted, savedDraft }
    private enum Confirmation: Identifiable {
        case leaving, deleting
        var id: Self { self }
    }

    /// The catalogue's own range. Every single-stop tour sits at 30 m and every
    /// walk stop at 40; the old 200 m ceiling was range nobody had ever used,
    /// and a 200 m circle runs off all four edges of this map.
    /// Somewhere neutral to point the camera before anything real is known —
    /// mid-Atlantic, wide enough to read as "no location yet" rather than a
    /// wrong one. Only ever on screen for a frame or two.
    private static let fallbackRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 30, longitude: -20),
        span: MKCoordinateSpan(latitudeDelta: 90, longitudeDelta: 90)
    )

    /// 🔴 THE ONE SWITCH. While the wizard is up the mini-player and tab bar
    /// are withdrawn, which gives every step back the 126pt they occupy.
    ///
    /// The rule this serves: **no step of the wizard may scroll** (owner,
    /// 2026-08-20) — anything that doesn't fit becomes another step instead. A
    /// quarter of the screen held for controls that do nothing while you are
    /// making a tour is the cheapest height there is to reclaim, and reclaiming
    /// it is worth roughly two extra steps we then don't have to add.
    ///
    /// **Set this to `false` and the bars come back, with no other edit.** The
    /// footer's clearance below reads it, the confirmation screen reads it, and
    /// `MakerView` reads it when deciding whether to withdraw the module at
    /// all. Nothing else in the app knows about it.
    static let hidesBottomModule = true

    /// How much room the footer must leave for the mini-player and tab bar —
    /// their full height, or nothing when they're withdrawn.
    private static var reservedBottomInset: CGFloat {
        hidesBottomModule ? 0 : AtlasBottomModule.height()
    }

    private static let radiusRange: ClosedRange<Double> = 15...100
    private static let titleLimit = 60
    private static let shortLimit = 100
    private static let longLimit = 600

    /// The draft as the service currently holds it, so photos and audio see
    /// their own writes land.
    private var draft: MakerTour? {
        guard let draftId else { return nil }
        return makerTourService.myTours.first { $0.id == draftId }
    }

    var body: some View {
        // 🔴 NO NavigationStack AND NO .toolbar — deliberately, and the reason
        // must survive any future tidy-up. Opening a saved tour hung the app
        // (0x8BADF00D) with the main thread looping in SwiftUI's toolbar
        // bridge: `_sheetLayoutInfoLayout:` → `_UIHostingView.layoutSubviews`
        // → `preferencesDidChange` → `UIKitToolbarStrategy.updateLocations()`.
        // Every toolbar update moves the navigation bar's metrics, and inside
        // a sheet's own layout pass that re-runs the layout that triggered it.
        // Making the items structurally constant was tried and did NOT fix it
        // (build 87) — content changes relay through the same bridge. The
        // wizard never navigates (no NavigationLink, no navigationDestination
        // anywhere in its files), so the stack existed only to host the
        // toolbar. The header below is plain layout: no bridge, no metrics,
        // nothing for sheet layout to feed back into.
        Group {
            if let outcome {
                outcomeView(outcome)
            } else {
                wizard
            }
        }
        .background(AtlasColors.secondaryBackground)
        // Unsaved work can't be swiped away; Close is where the question lives.
        //
        // 🔴 This modifier reconfigures `UISheetPresentationController`, so the
        // value it reads must be cheap AND rarely-changing. Two earlier
        // versions hung the app here: the first reached into the presentation
        // controller from a representable to *prompt* on the swipe, setting
        // `isModalInPresentation` from inside sheet layout; the second passed
        // `hasUnsavedChanges`, which reads the live map coordinate, so every
        // camera callback re-ran the root body inside `_sheetLayoutInfoLayout:`
        // and laid the map out again. Pass plain state, computed elsewhere.
        .interactiveDismissDisabled(dismissGuarded)
        .confirmationDialog(confirmTitle, isPresented: confirmBinding,
                            titleVisibility: .visible) {
            switch confirming {
            case .leaving:
                Button("Save draft & close") { saveAndClose() }
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            case .deleting:
                Button("Delete tour", role: .destructive) { deleteTour() }
                Button("Cancel", role: .cancel) {}
            case .none:
                EmptyView()
            }
        } message: {
            Text(confirmMessage)
        }
        .onAppear(perform: centerOnUser)
        .onDisappear {
            guard Self.hidesBottomModule else { return }
            appShared?.hidesBottomModule = false
            bottomModuleWindow?.setHidden(false)
        }
        .task(id: existingTourId) { await loadExistingTour() }
    }

    /// Read an existing tour into the form. Runs once: a second pass would
    /// overwrite whatever the maker had already changed.
    private func loadExistingTour() async {
        guard let existingTourId, !didLoadExisting,
              let existing = makerTourService.myTours.first(where: { $0.id == existingTourId })
        else { return }
        didLoadExisting = true

        // 🔴 Nothing may be written to view state until the sheet's
        // presentation transition is over, and everything is then written in
        // ONE batch. Every crash log of the saved-tour hang — builds 77, 81,
        // 84, 87 — is the same picture with a different function on top: the
        // main thread flushing SwiftUI graph transactions from inside
        // `_transitionWillBegin:`'s alongside animations, where each of our
        // state writes forces a re-render whose platform-view update walks
        // MKMapView's whole subview tree for trait changes. Enough writes in
        // that window and the 5 s watchdog fires. Creating a tour writes
        // nothing there, which is why it never hung. So: fetch first (the
        // network runs while the sheet is still sliding), wait out the
        // remainder of the transition, then apply the lot as a single
        // transaction. The four separate batches this used to be — fields,
        // stop, transcript, signature — were four full map re-walks.
        let settleDeadline = ContinuousClock.now.advanced(by: .milliseconds(650))
        let stop = await makerTourService.stopLocation(tourId: existingTourId)
        let fetchedTranscript = await makerTourService.stopTranscript(tourId: existingTourId)
        try? await Task.sleep(until: settleDeadline, clock: .continuous)

        draftId = existingTourId

        let tour = existing.tour
        title = tour.title
        shortDescription = tour.shortDescription
        longDescription = tour.longDescription
        city = tour.city
        cityQuery = tour.city ?? ""

        // Split the stored tags back into what the picker edits. The architect
        // is stored as a plain tag beside its implied "Designed by a Master";
        // both are re-derived on save, so both come out here — otherwise saving
        // twice would accumulate duplicates.
        let architectTag = tour.tags.first { Tag.facet(for: $0) == .architect }
        var editable = Set(tour.tags)
        editable.remove("Designed by a Master")
        if let architectTag { editable.remove(architectTag) }
        selectedTags = editable
        architect = architectTag

        // `MakerTour` carries no stops — the profile feed doesn't need them —
        // so the pin and radius have to be fetched. Reading them off the tour
        // would silently reset every edited tour's geofence to the default.
        if let stop {
            // Clamped into the slider's range. Tours made before today were
            // created with a 20–200 m slider, so a stored radius can sit
            // outside 15–100 — and a Slider handed a value beyond its bounds
            // is not something to find out about on a device.
            radius = min(max(Double(stop.radiusMeters), Self.radiusRange.lowerBound),
                         Self.radiusRange.upperBound)
            centerCoordinate = stop.coordinate
            cameraPosition = .region(MKCoordinateRegion(
                center: stop.coordinate, latitudinalMeters: 700, longitudinalMeters: 700))
        }
        transcript = fetchedTranscript
        savedSignature = currentSignature
    }

    private func deleteTour() {
        guard let tour = draft?.tour else { return }
        errorMessage = nil
        isDeleting = true
        Task {
            defer { isDeleting = false }
            do {
                try await makerTourService.deleteTour(tour)
                dismiss()
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    // MARK: - Chrome

    /// The bar the toolbar used to be: where you are centred, the way out on
    /// the leading edge. Plain views in a plain HStack — see `body` for why
    /// this must never become a `.toolbar` again.
    ///
    /// Built from `AtlasChromeButton`, so it is the same control `TourDetailView`
    /// closes with — that page is the canon for page chrome (owner,
    /// 2026-08-20). The leading button used to be the word "Close", which was
    /// the only spelled-out one in the app.
    private var header: some View {
        ZStack {
            Text(stepTitle)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .lineLimit(1)
                // Clear of the leading button and its mirror on the trailing
                // side, so a long step name is truncated rather than run under
                // the glyph.
                .padding(.horizontal, AtlasChromeButton.diameter + AtlasSpacing.sm)
            HStack {
                Button {
                    if step == .location { closeTapped() } else { goBack() }
                } label: {
                    AtlasChromeButton(step == .location ? "xmark" : "chevron.left")
                }
                .buttonStyle(.plain)
                .accessibilityLabel(step == .location ? "Close" : "Back")
                Spacer()
            }
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, AtlasSpacing.sm)
        .frame(height: AtlasChromeButton.rowHeight)
    }

    /// "STEP 2 OF 5 — DETAILS". Counted off `allCases`, so adding or removing
    /// a step can't leave the header claiming a total nobody has.
    private var stepTitle: String {
        "STEP \(step.rawValue + 1) OF \(TourWizardStep.allCases.count) — \(step.label)"
    }

    private var wizard: some View {
        VStack(spacing: 0) {
            header
            progressBar
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                    stepContent
                    if let errorMessage {
                        Text(errorMessage)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.mapPin)
                    }
                }
                .padding(AtlasSpacing.lg)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        // Deliberately here and not at the root — see `dismissGuarded`.
        .onChange(of: currentSignature, initial: true) { _, _ in
            dismissGuarded = outcome == nil && wouldLoseWork
        }
        .onChange(of: savedSignature, initial: true) { _, _ in
            dismissGuarded = outcome == nil && wouldLoseWork
        }
        .onChange(of: draftId) { _, _ in
            dismissGuarded = outcome == nil && wouldLoseWork
        }
        // The keyboard rises *over* the footer rather than shoving it up the
        // screen — otherwise Save progress and Next end up floating in the
        // middle of the map. Same treatment the mini-player and the home
        // drawer already get (PR #132).
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    /// Five segments, one per step — and on an existing tour they're the way
    /// you move around. Tapping one jumps straight there, so fixing a typo is
    /// a tap rather than a walk through four screens you didn't come for.
    /// A new tour can only go back this way; going forward still has to earn
    /// it, step by step.
    private var progressBar: some View {
        HStack(spacing: 5) {
            ForEach(TourWizardStep.allCases, id: \.rawValue) { s in
                Button { jump(to: s) } label: {
                    Rectangle()
                        .fill(s.rawValue <= step.rawValue
                              ? AtlasColors.mapPin
                              : AtlasColors.divider)
                        .frame(height: 0.5)
                        .padding(.vertical, 10)     // a hairline is not a tap target
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(!canJump(to: s))
                .accessibilityLabel(s.label.capitalized)
            }
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.bottom, 2)
    }

    /// Any step on a tour that already exists; otherwise only backwards.
    private func canJump(to target: TourWizardStep) -> Bool {
        target != step && (existingTourId != nil || target.rawValue < step.rawValue)
    }

    /// Jumping saves what's on screen first, so moving around can't lose an
    /// edit the way tapping through would.
    private func jump(to target: TourWizardStep) {
        guard canJump(to: target) else { return }
        focused = nil
        errorMessage = nil
        Task {
            if hasUnsavedChanges, canPersist {
                do { try await persist() }
                catch { errorMessage = AuthoringErrorText.message(for: error) ; return }
            }
            withAnimation(.easeInOut(duration: 0.2)) { step = target }
        }
    }

    /// Save progress and the primary action, side by side, where neither can
    /// scroll out of reach. Sits above the mini-player + tab bar, which live in
    /// a separate, higher window.
    private var footer: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            // ⚠️ The hint line reserves two lines whether or not it has
            // anything to say. The footer is a `.safeAreaInset`, so its height
            // is a layout input for everything above it — and this line
            // appears and disappears exactly when a saved tour finishes
            // loading, which is *during* the sheet's presentation transition.
            // A constant height means that can't feed back into the sheet.
            // Same reason the toolbar above is structurally fixed.
            Group {
                if savedConfirmation {
                    Label("Draft saved", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(AtlasColors.mapPin)
                } else if let blockingHint {
                    Text(blockingHint)
                        .foregroundStyle(AtlasColors.tertiaryText)
                } else {
                    Text(" ")
                }
            }
            .font(AtlasTypography.caption)
            .lineLimit(2, reservesSpace: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: AtlasSpacing.sm) {
                Button { saveProgress() } label: {
                    pill("Save progress", filled: false)
                }
                .buttonStyle(.plain)
                .disabled(!canPersist || isPersisting || isSubmitting)
                .opacity(canPersist ? 1 : 0.4)

                Spacer(minLength: 0)

                Button { primaryTapped() } label: {
                    pill(primaryLabel, filled: true, busy: isPersisting || isSubmitting)
                }
                .buttonStyle(.plain)
                .disabled(!canAdvance || isPersisting || isSubmitting)
                .opacity(canAdvance ? 1 : 0.4)
            }
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.top, AtlasSpacing.sm)
        // The mini-player and tab bar live in a higher window, so the footer
        // has to clear them itself — and the clearance must be *inside* the
        // painted background, or the page scrolls visibly through it. Zero
        // while they're withdrawn; see `hidesBottomModule`.
        .padding(.bottom, AtlasSpacing.sm + Self.reservedBottomInset)
        // The fill runs into the home-indicator strip while the content stays
        // above it. Without the bars underneath, that strip is bare screen —
        // and the step would be seen scrolling through it.
        .background { AtlasColors.secondaryBackground.ignoresSafeArea(edges: .bottom) }
        .overlay(alignment: .top) {
            Rectangle().fill(AtlasColors.divider).frame(height: 0.5)
        }
    }

    private func pill(_ text: String, filled: Bool, busy: Bool = false) -> some View {
        HStack(spacing: 6) {
            if busy { ProgressView().tint(filled ? AtlasColors.background : AtlasColors.primaryText) }
            Text(text).font(AtlasTypography.caption)
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.vertical, 12)
        .foregroundStyle(filled ? AtlasColors.background : AtlasColors.primaryText)
        .background(filled ? AtlasColors.mapPin : AtlasColors.background)
        .clipShape(Capsule())
        .overlay {
            if !filled {
                Capsule().stroke(AtlasColors.tertiaryText.opacity(0.5), lineWidth: 1)
            }
        }
    }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .location: locationStep
        case .details:  detailsStep
        case .photos:   photosStep
        case .audio:    audioStep
        case .review:   reviewStep
        }
    }

    private var locationStep: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("CITY & COUNTRY")
                TextField("e.g. Porto, Portugal", text: $cityQuery)
                    .focused($focused, equals: .city)
                    .autocorrectionDisabled()
                    .onChange(of: cityQuery) { _, new in
                        // Only a person typing opens the dropdown. Loading a
                        // saved tour fills this field, and `pickCity` rewrites
                        // it as "Porto, Portugal" — neither is a search, and
                        // both used to re-open the list and set a completer
                        // streaming results into a view mid-layout.
                        guard focused == .city else { return }
                        citySearch.search(new)
                        showingCitySuggestions = true
                        // Typing again after a pick means they're changing
                        // their mind, so the old choice shouldn't linger.
                        if new != cityLabel { city = nil; country = nil }
                    }
                    .onSubmit { showingCitySuggestions = false }
                    .wizardFieldStyle()

                if showingCitySuggestions, !citySearch.suggestions.isEmpty {
                    suggestionList(citySearch.suggestions) { pickCity($0) }
                }
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("LOCATION NAME")
                HStack(spacing: AtlasSpacing.sm) {
                    TextField("e.g. The Old Custom House", text: $locationName)
                        .focused($focused, equals: .place)
                        .onChange(of: locationName) { _, new in
                            guard focused == .place else { return }
                            placeSearch.search(new)
                            showingPlaceSuggestions = true
                        }
                        .onSubmit { showingPlaceSuggestions = false }
                    if isResolvingPlace { ProgressView() }
                }
                .wizardFieldStyle()

                if showingPlaceSuggestions, !placeSearch.suggestions.isEmpty {
                    suggestionList(placeSearch.suggestions) { pickPlace($0) }
                }
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("PAN TO PLACE THE PIN")
                mapSection
            }
            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("TRIGGER RADIUS — \(Int(radius)) m")
                Slider(value: $radius, in: Self.radiusRange, step: 5)
                    .tint(AtlasColors.mapPin)
                HStack {
                    Text("\(Int(Self.radiusRange.lowerBound)) m")
                    Spacer()
                    Text("\(Int(Self.radiusRange.upperBound)) m")
                }
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
            }
            Text("The tour fires when a listener walks inside this circle.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
        }
    }

    /// The dropdown under either place field. Deliberately not a `List` —
    /// it sits inside the step's own scroll view, and a nested scrolling
    /// list there fights the page for the drag.
    private func suggestionList(_ suggestions: [PlaceSuggestion],
                                onPick: @escaping (PlaceSuggestion) -> Void) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                Button { onPick(suggestion) } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.title)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.primaryText)
                        if !suggestion.subtitle.isEmpty {
                            Text(suggestion.subtitle)
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.tertiaryText)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, AtlasSpacing.md)
                    .padding(.vertical, 11)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .overlay(alignment: .bottom) {
                    if index < suggestions.count - 1 {
                        Rectangle().fill(AtlasColors.divider).frame(height: 0.5)
                            .padding(.leading, AtlasSpacing.md)
                    }
                }
            }
        }
        .background(AtlasColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
    }

    /// Picking a city fills the field, frames the map on it, and biases the
    /// location-name lookup — so "the old custom house" means the one there,
    /// not the nearest one to wherever the maker happens to be sitting.
    private func pickCity(_ suggestion: PlaceSuggestion) {
        focused = nil
        showingCitySuggestions = false
        citySearch.clear()
        Task {
            guard let place = await citySearch.resolveDetails(suggestion) else { return }
            city = place.locality ?? suggestion.title
            country = place.country
            cityQuery = cityLabel
            placeSearch.regionBias = place.region
            // A new city invalidates the old pin — it would otherwise sit
            // hundreds of miles away, quietly, on a map framed elsewhere.
            locationName = ""
            placeSearch.clear()
            showingPlaceSuggestions = false
            cameraPosition = .region(place.region)
            centerCoordinate = place.coordinate
        }
    }

    /// Picking a named place drops the pin on it. The field stays editable
    /// afterwards: the suggestion is a shortcut, not a commitment.
    private func pickPlace(_ suggestion: PlaceSuggestion) {
        focused = nil
        showingPlaceSuggestions = false
        locationName = suggestion.title
        placeSearch.clear()
        isResolvingPlace = true
        Task {
            defer { isResolvingPlace = false }
            guard let place = await placeSearch.resolveDetails(suggestion) else { return }
            centerCoordinate = place.coordinate
            // Frame tightly — the maker is checking the pin is on the right
            // building, not browsing the neighbourhood.
            cameraPosition = .region(MKCoordinateRegion(
                center: place.coordinate,
                latitudinalMeters: 400,
                longitudinalMeters: 400
            ))
            if city == nil, let locality = place.locality {
                city = locality
                country = place.country
                cityQuery = cityLabel
            }
        }
    }

    /// What the Review step calls the place: the name if one was given, the
    /// city if not, and an honest "Not named" rather than a blank row.
    private var whereSummary: String {
        let parts = [locationName.isEmpty ? nil : locationName,
                     cityLabel.isEmpty ? nil : cityLabel].compactMap { $0 }
        return parts.isEmpty ? "Not named" : parts.joined(separator: ", ")
    }

    /// "Porto, Portugal" — what the field shows once a city is chosen.
    private var cityLabel: String {
        [city, country].compactMap { $0 }.joined(separator: ", ")
    }

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            if let c = centerCoordinate {
                MapCircle(center: c, radius: radius)
                    .foregroundStyle(AtlasColors.mapPin.opacity(0.18))
                    .stroke(AtlasColors.mapPin, lineWidth: 2)
            }
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
        .overlay {
            // Fixed centre pin — the map centre IS the chosen coordinate, so
            // panning the map moves the pin. Tip anchored at the true centre.
            Image(systemName: "mappin")
                .font(.title)
                .foregroundStyle(AtlasColors.mapPin)
                .offset(y: -11)
                .allowsHitTesting(false)
        }
        .onMapCameraChange(frequency: .continuous) { context in
            // 🔴 The guard is load-bearing, not an optimisation.
            // `CLLocationCoordinate2D` is not `Equatable`, so SwiftUI cannot
            // tell an unchanged write from a real one — *every* callback
            // dirties this view. MapKit reports a camera change on each layout
            // pass, so an unguarded write means: layout → callback → dirty →
            // layout, forever, inside `_sheetLayoutInfoLayout:`. That is the
            // watchdog kill (0x8BADF00D) opening a saved tour. Assign only
            // when the pin has genuinely moved.
            let c = context.region.center
            if let existing = centerCoordinate, existing.isEssentially(c) { return }
            centerCoordinate = c
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("TITLE", remaining: Self.titleLimit - title.count)
                TextField("e.g. The Old Custom House", text: $title)
                    .focused($focused, equals: .title)
                    .onChange(of: title) { _, new in
                        if new.count > Self.titleLimit { title = String(new.prefix(Self.titleLimit)) }
                    }
                    .wizardFieldStyle()
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("SHORT DESCRIPTION", remaining: Self.shortLimit - shortDescription.count)
                TextField("One line shown on cards", text: $shortDescription)
                    .focused($focused, equals: .short)
                    .onChange(of: shortDescription) { _, new in
                        if new.count > Self.shortLimit { shortDescription = String(new.prefix(Self.shortLimit)) }
                    }
                    .wizardFieldStyle()
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("DESCRIPTION", remaining: Self.longLimit - longDescription.count)
                TextField("What this tour is about", text: $longDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .focused($focused, equals: .long)
                    .onChange(of: longDescription) { _, new in
                        if new.count > Self.longLimit { longDescription = String(new.prefix(Self.longLimit)) }
                    }
                    .wizardFieldStyle()
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                fieldLabel("TAGS — HOW YOUR TOUR IS FOUND")
                ControlledTagPicker(selectedTags: $selectedTags, architect: $architect)
            }
        }
    }

    @ViewBuilder
    private var photosStep: some View {
        if let draft {
            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                fieldLabel("PHOTOS — UP TO \(PhotoGridEditor.maxPhotos), THE FIRST IS THE COVER")
                // Adding, framing, reordering and removing all happen here.
                // There is no second screen for it — the step is the page.
                PhotoGridEditor(tour: draft.tour)
                    .id(draft.tour.id)
            }
        } else {
            missingDraftNotice
        }
    }

    @ViewBuilder
    private var audioStep: some View {
        if let draft {
            VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                TourAudioSection(tour: draft.tour,
                                 onUploadStateChange: { audioUpload = $0 })

                VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                    fieldLabel("TRANSCRIPT — OPTIONAL")
                    TextField("The words spoken in the audio", text: $transcript, axis: .vertical)
                        .lineLimit(4...12)
                        .wizardFieldStyle()
                    Text("Used for accessibility and search. It is saved when you submit.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
            }
        } else {
            missingDraftNotice
        }
    }

    @ViewBuilder
    private var reviewStep: some View {
        if let draft {
            let tour = draft.tour
            let photoCount = ([tour.heroImageURL] + (tour.additionalImageURLs ?? []))
                .filter { !$0.isEmpty }.count
            VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                fieldLabel("PREVIEW — HOW IT'LL LOOK IN THE APP")
                previewCard(tour)
                VStack(spacing: 0) {
                    summaryRow("TITLE", tour.title, isLast: false)
                    summaryRow("WHERE", whereSummary, isLast: false)
                    summaryRow("PIN",
                               String(format: "%.4f, %.4f", tour.centroidLatitude, tour.centroidLongitude),
                               isLast: false)
                    summaryRow("GEOFENCE", "\(Int(radius)) m", isLast: false)
                    summaryRow("TAGS", tour.tags.isEmpty ? "None" : tour.tags.joined(separator: " · "),
                               isLast: false)
                    summaryRow("PHOTOS", photoCount == 0 ? "None" : "\(photoCount)", isLast: false)
                    summaryRow("AUDIO", audioSummary(tour), isLast: existingTourId == nil)
                    if existingTourId != nil {
                        summaryRow("STATUS", draft.status.label, isLast: true)
                    }
                }
                .background(AtlasColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))

                Text(reviewFootnote)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)

                if existingTourId != nil {
                    Button(role: .destructive) { confirming = .deleting } label: {
                        HStack {
                            Spacer()
                            if isDeleting {
                                ProgressView()
                            } else {
                                Label("Delete tour", systemImage: "trash")
                                    .font(AtlasTypography.caption)
                                    .foregroundStyle(AtlasColors.accent)
                            }
                            Spacer()
                        }
                        .padding(.vertical, AtlasSpacing.md)
                        .overlay(
                            RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                                .stroke(AtlasColors.accent.opacity(0.5), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(isDeleting)
                    .padding(.top, AtlasSpacing.sm)
                }
            }
        } else {
            missingDraftNotice
        }
    }

    /// A still of the player, so the maker sees what a listener sees before
    /// committing. Deliberately inert — it is a picture of the app, not a
    /// second place to play the audio.
    private func previewCard(_ tour: Tour) -> some View {
        let images = ([tour.heroImageURL] + (tour.additionalImageURLs ?? []))
            .filter { !$0.isEmpty }
        let blurb = longDescription.isEmpty ? shortDescription : longDescription
        return VStack(spacing: 0) {
            ZStack(alignment: .bottom) {
                if let hero = images.first {
                    HeroImageView(imageName: hero, height: 200,
                                  cornerRadius: 0, category: tour.primaryCategory)
                } else {
                    Rectangle()
                        .fill(AtlasColors.secondaryBackground)
                        .frame(height: 200)
                        .overlay(
                            Text("No cover photo yet")
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.tertiaryText)
                        )
                }
                if images.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(0..<images.count, id: \.self) { index in
                            Circle()
                                .fill(Color.white.opacity(index == 0 ? 1 : 0.5))
                                .frame(width: 5, height: 5)
                        }
                    }
                    .padding(.bottom, AtlasSpacing.sm)
                }
            }

            VStack(spacing: AtlasSpacing.xs) {
                Text("NOW PLAYING")
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(AtlasColors.tertiaryText)
                Text(persistedTitle)
                    .font(AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(blurb.isEmpty ? "Add a description to see it here." : blurb)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.bottom, AtlasSpacing.xs)

                Capsule()
                    .fill(AtlasColors.tertiaryText.opacity(0.3))
                    .frame(height: 3)
                    .overlay(alignment: .leading) {
                        GeometryReader { geo in
                            Capsule()
                                .fill(AtlasColors.mapPin)
                                .frame(width: geo.size.width * 0.06, height: 3)
                        }
                        .frame(height: 3)
                    }
                HStack {
                    Text("0:00")
                    Spacer()
                    Text(tour.totalDurationSeconds > 0
                         ? AtlasFormatters.duration(seconds: tour.totalDurationSeconds)
                         : "—")
                }
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.tertiaryText)
                .padding(.bottom, AtlasSpacing.xs)

                HStack {
                    Text("1x")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .overlay(Capsule().stroke(AtlasColors.tertiaryText.opacity(0.5), lineWidth: 1))
                    Spacer()
                    Image(systemName: "gobackward.10")
                    Spacer()
                    Image(systemName: "play.fill")
                        .font(.system(size: 15))
                        .foregroundStyle(AtlasColors.background)
                        .frame(width: 44, height: 44)
                        .background(AtlasColors.mapPin, in: Circle())
                    Spacer()
                    Image(systemName: "goforward.10")
                    Spacer()
                    Image(systemName: "forward.end.fill")
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
                .font(.system(size: 16))
                .foregroundStyle(AtlasColors.primaryText)
            }
            .padding(AtlasSpacing.md)
        }
        .background(AtlasColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
        .allowsHitTesting(false)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Preview of how this tour will look in the player")
    }

    private var missingDraftNotice: some View {
        Text("Go back to Location and place the pin first.")
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
    }

    private func summaryRow(_ key: String, _ value: String, isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: AtlasSpacing.md) {
            Text(key)
                .font(.system(size: 11, weight: .regular, design: .monospaced))
                .foregroundStyle(AtlasColors.tertiaryText)
            Spacer(minLength: 0)
            Text(value)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
        }
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.vertical, 12)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle().fill(AtlasColors.divider).frame(height: 0.5)
                    .padding(.leading, AtlasSpacing.md)
            }
        }
    }

    // MARK: - Outcome

    private func outcomeView(_ outcome: Outcome) -> some View {
        VStack(spacing: AtlasSpacing.md) {
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(AtlasColors.mapPin)
                .frame(width: 64, height: 64)
                .overlay(Circle().stroke(AtlasColors.mapPin, lineWidth: 2))

            Text(outcome == .submitted ? "SUBMITTED FOR REVIEW" : "SAVED AS DRAFT")
                .font(AtlasTypography.body)
                .foregroundStyle(AtlasColors.primaryText)

            Text(outcome == .submitted
                 ? "Most tours are reviewed within a day. It'll show as In review on your profile until then."
                 : "It's in your tours — pick up right where you left off.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AtlasSpacing.lg)

            Spacer()

            Button { dismiss() } label: { pill("Done", filled: true) }
                .buttonStyle(.plain)
                .padding(.bottom, Self.reservedBottomInset)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Gating

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    /// Anything at all can be saved as a draft once there's a coordinate to
    /// hang it on — the title falls back to a placeholder.
    private var canPersist: Bool { centerCoordinate != nil }

    /// The view's state flattened for `TourWizardRules`, which owns every
    /// "can I leave this step?" decision so the rule and the reason it gives
    /// can never disagree.
    private var wizardState: TourWizardState {
        TourWizardState(
            hasCoordinate: centerCoordinate != nil,
            title: title,
            shortDescription: shortDescription,
            tags: selectedTags,
            hasCoverPhoto: !(draft?.tour.heroImageURL.isEmpty ?? true),
            audioDurationSeconds: draft?.tour.totalDurationSeconds ?? 0,
            audioUpload: audioUpload,
            draftExists: draft != nil,
            isAlreadyInReview: draft?.status == .inReview
        )
    }

    private var canAdvance: Bool {
        TourWizardRules.canAdvance(from: step, state: wizardState)
    }

    /// Says what's missing rather than leaving a dimmed button unexplained.
    private var blockingHint: String? {
        TourWizardRules.blockingReason(for: step, state: wizardState)
    }

    private var primaryLabel: String {
        guard step == .review else { return "Next" }
        switch draft?.status {
        case .inReview: return "In review"
        // Editing something already live is allowed — a maker shouldn't need
        // an admin to fix a typo — but it re-enters moderation rather than
        // changing under a listener mid-tour.
        case .published: return "Submit changes for review"
        default:        return "Submit for review"
        }
    }

    private var reviewFootnote: String {
        switch draft?.status {
        case .inReview:
            return "Already with us. We'll let you know either way."
        case .published:
            return "This tour is live. Saving changes sends it back for review before they appear."
        default:
            return "We review every tour before it goes live. Most are looked at within a day."
        }
    }

    /// The Audio row on Review, which carries the upload through rather than
    /// leaving the maker to guess whether it finished.
    private func audioSummary(_ tour: Tour) -> String {
        switch audioUpload {
        case .uploading(let fraction): return "Uploading — \(Int(fraction * 100))%"
        case .failed:                  return "Upload failed"
        case .idle:
            return tour.totalDurationSeconds > 0
                ? AtlasFormatters.duration(seconds: tour.totalDurationSeconds)
                : "None"
        }
    }

    /// Everything currently entered, as one comparable string. Close reads it
    /// to know whether there is unsaved work worth asking about.
    private var currentSignature: String {
        [
            persistedTitle, shortDescription, longDescription,
            selectedTags.sorted().joined(separator: "|"),   // plain sort: this is change detection, not display
            architect ?? "", city ?? "", transcript,
            String(format: "%.6f,%.6f,%d",
                   centerCoordinate?.latitude ?? 0,
                   centerCoordinate?.longitude ?? 0,
                   Int(radius)),
        ].joined(separator: "\u{1}")
    }

    private var hasUnsavedChanges: Bool { savedSignature != currentSignature }

    // MARK: - Actions

    /// Nothing entered yet, or everything already saved, closes straight
    /// away. Anything else asks — and offers to keep it, which is the whole
    /// point of a five-step flow that can be abandoned four steps in.
    private var confirmBinding: Binding<Bool> {
        Binding(get: { confirming != nil },
                set: { if !$0 { confirming = nil } })
    }
    private var confirmTitle: String {
        confirming == .deleting ? "Delete this tour?" : "Keep this tour?"
    }
    private var confirmMessage: String {
        confirming == .deleting
            ? "This can't be undone. Its audio and photos go with it."
            : "A draft stays in your tours, so you can pick it up where you left off."
    }

    /// Whether closing now would lose something. **The swipe guard and the
    /// Close button both read this** — they used to test different things, so
    /// a brand-new tour with nothing typed refused the swipe while Close shut
    /// it without a word. A blocked gesture with no explanation reads as the
    /// app being broken.
    private var wouldLoseWork: Bool {
        let typedSomething = !trimmedTitle.isEmpty
            || !shortDescription.isEmpty
            || !longDescription.isEmpty
            || !selectedTags.isEmpty
            || !locationName.isEmpty
        return (draftId != nil || typedSomething) && hasUnsavedChanges && canPersist
    }

    private func closeTapped() {
        if wouldLoseWork {
            confirming = .leaving
        } else {
            dismiss()
        }
    }

    private func goBack() {
        focused = nil
        guard let previous = step.previous else { return }
        withAnimation(.easeInOut(duration: 0.2)) { step = previous }
    }

    private func primaryTapped() {
        focused = nil
        errorMessage = nil
        if step == .review {
            submit()
        } else {
            advance()
        }
    }

    private func advance() {
        // The place they just named is nearly always what the tour is called.
        // Offered, not imposed: only when the title is still empty.
        if step == .location, trimmedTitle.isEmpty, !locationName.isEmpty {
            title = String(locationName.prefix(Self.titleLimit))
        }
        isPersisting = true
        Task {
            defer { isPersisting = false }
            do {
                try await persist()
                guard let next = step.next else { return }
                withAnimation(.easeInOut(duration: 0.2)) { step = next }
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    /// Save and stay put. Tapping Save progress mid-flow means "don't lose
    /// this", not "I'm done" — leaving is Close's job, and Close now offers to
    /// save on the way out.
    private func saveProgress() {
        focused = nil
        errorMessage = nil
        isPersisting = true
        Task {
            defer { isPersisting = false }
            do {
                try await persist()
                withAnimation(.easeInOut(duration: 0.2)) { savedConfirmation = true }
                try? await Task.sleep(for: .seconds(2.5))
                withAnimation(.easeInOut(duration: 0.2)) { savedConfirmation = false }
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    /// Close's "save it first" branch — the same write, then the confirmation
    /// screen so the maker sees where the draft went.
    private func saveAndClose() {
        focused = nil
        errorMessage = nil
        isPersisting = true
        Task {
            defer { isPersisting = false }
            do {
                try await persist()
                outcome = .savedDraft
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    private func submit() {
        guard let draft, draft.status != .inReview else { return }
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await persist()
                try await makerTourService.submitForReview(tour: draft.tour, transcript: transcript)
                outcome = .submitted
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    /// Write what's been entered so far — creating the draft on the first call
    /// and updating it thereafter. Every Next and every Save progress runs
    /// through here, so there is one write path rather than one per step.
    private func persist() async throws {
        guard let coordinate = centerCoordinate else { return }
        let tags = finalTags
        let category = Tag.deriveCategory(from: tags)

        if let existing = draft {
            try await makerTourService.updateDetails(
                tour: existing.tour,
                status: existing.status,
                title: persistedTitle,
                shortDescription: shortDescription,
                longDescription: longDescription,
                category: category,
                tags: tags,
                coordinate: coordinate,
                radiusMeters: Int(radius),
                city: city
            )
        } else {
            let makerId = try await makerProfileService.ensureMaker()
            draftId = try await makerTourService.createDraftTour(
                makerId: makerId,
                title: persistedTitle,
                shortDescription: shortDescription,
                longDescription: longDescription,
                category: category,
                tags: tags,
                coordinate: coordinate,
                radiusMeters: Int(radius),
                city: city
            )
        }

        if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let id = draftId {
            try await makerTourService.setTranscript(tourId: id, text: transcript)
        }

        savedSignature = currentSignature
    }

    /// The database won't take a tour without a title, and step 1 doesn't have
    /// one yet — so an early save gets a placeholder that step 2 replaces.
    private var persistedTitle: String {
        trimmedTitle.isEmpty ? "Untitled tour" : trimmedTitle
    }

    /// Final tag list, in canonical order, with the architect and its implied
    /// "Designed by a Master" appended when one is chosen.
    private var finalTags: [String] {
        var tags = Tag.ordered(selectedTags)
        if let architect {
            tags.append("Designed by a Master")
            tags.append(architect)
        }
        return tags
    }

    /// Frames the map on the user before anything else is known.
    ///
    /// ⚠️ On an existing tour this moves the CAMERA ONLY. The pin belongs to
    /// the saved tour and arrives from `loadExistingTour`; dropping the user's
    /// coordinate into `centerCoordinate` here would invent an edit — it feeds
    /// `canPersist` and the change signature, so the tour would open already
    /// claiming unsaved work, on a pin nobody placed.
    private func centerOnUser() {
        guard let coord = locationManager.userLocation?.coordinate else { return }
        guard centerCoordinate == nil else { return }
        cameraPosition = .region(
            MKCoordinateRegion(center: coord, latitudinalMeters: 700, longitudinalMeters: 700)
        )
        guard existingTourId == nil else { return }
        centerCoordinate = coord
    }

    // MARK: - Small pieces

    /// A field label, optionally with a right-aligned "N left" countdown that
    /// turns gold as the limit approaches.
    private func fieldLabel(_ text: String, remaining: Int? = nil) -> some View {
        HStack {
            Text(text)
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
            if let remaining {
                Spacer()
                Text("\(max(0, remaining)) left")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(remaining <= 8 ? AtlasColors.mapPin : AtlasColors.tertiaryText)
            }
        }
    }

}

private extension View {
    /// Shared field chrome — matches the details editor and profile editor.
    func wizardFieldStyle() -> some View {
        self
            .font(AtlasTypography.caption)
            .padding(AtlasSpacing.md)
            .background(AtlasColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }
}
