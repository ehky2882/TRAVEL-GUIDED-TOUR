import SwiftUI
import MapKit
import CoreLocation
import Combine

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
    /// 🔴 ONE SEARCH FIELD, NOT TWO (owner, 2026-08-20). This used to be
    /// "CITY & COUNTRY" above "LOCATION NAME", which was redundant: the job
    /// here is to get the map onto the right spot, and a maker who types
    /// "Casa da Música" has said everything the city field was asking for.
    /// Two labelled fields cost 154pt to say what 46pt says.
    ///
    /// `venues()` is what makes one field enough — its completer returns
    /// addresses *and* points of interest, so "Porto" and "Casa da Música"
    /// both resolve, and `resolveDetails` hands back the locality and country
    /// either way. Nothing is asked for twice.
    @State private var locationQuery = ""
    @State private var placeSearch = PlaceSearchService.venues()
    /// Filled from whatever was resolved, never typed. `city` is persisted on
    /// the tour; `resolvedPlaceName` only names the place on the Review step
    /// and offers itself as the tour's title.
    @State private var city: String?
    @State private var country: String?
    @State private var resolvedPlaceName: String?
    /// Whether the dropdown is showing. Deliberately not derived from focus —
    /// tapping a row resigns focus, which would pull the row out from under
    /// the tap before it registered.
    @State private var showingPlaceSuggestions = false
    @State private var isResolvingPlace = false

    // Step 2 — details
    @State private var title = ""
    @State private var shortDescription = ""
    @State private var longDescription = ""
    @State private var selectedTags: Set<String> = []
    @State private var architect: String?

    // Steps 5 and 6 — audio, then the transcript made from it
    @State private var transcript = ""
    /// Writes the narration down on device. Lives here rather than in
    /// `TourAudioSection` because the audio step starts it and the transcript
    /// step reads it — it outlives both, and a recording that takes a minute to
    /// transcribe must not be cancelled by walking to the next screen.
    @State private var transcriber = AudioTranscriber()
    /// The scroll viewport's height, so a step that needs to fill it can be
    /// sized rather than hope. See the ScrollView's `onGeometryChange`.
    @State private var stepAreaHeight: CGFloat = 0
    /// The transcript step's label row, measured so the box below it can take
    /// exactly what's left instead of guessing at a font's line height.
    @State private var transcriptLabelHeight: CGFloat = 0
    /// Whether the maker has typed in the transcript box themselves.
    ///
    /// 🔴 The one thing standing between a maker and losing a sentence they
    /// wrote. Transcription of a real tour outlasts the walk from step 5 to
    /// step 6, so results routinely arrive *while* the box is on screen and
    /// possibly being edited. Once this is true nothing automatic writes to
    /// `transcript` again.
    @State private var transcriptEdited = false
    /// The recording as it sits on this device, kept so the maker can ask for
    /// the transcript to be made again. Nil for a tour opened for editing —
    /// its audio is on the server and was never here.
    @State private var lastLocalAudioURL: URL?
    /// Remembered across tours: a maker who narrates ten tours in Spanish
    /// should say so once, not ten times.
    @AppStorage("transcriptionLocale") private var transcriptionLocaleID = ""
    /// The languages the recogniser handles, read once when the step appears.
    @State private var supportedLocales: [Locale] = []

    // Flow
    @State private var isPersisting = false
    @State private var isSubmitting = false
    /// Whether the write in flight is Save draft rather than Next. Both run
    /// through `persist()` and both set `isPersisting`, so without this the
    /// spinner appears on Next when you tapped Save — pointing at the wrong
    /// button while it works.
    @State private var isSavingInPlace = false
    /// How tall the keyboard is, tracked by hand.
    ///
    /// The wizard sets `.ignoresSafeArea(.keyboard)` so the footer never rides
    /// up the screen — which also means nothing inside it can learn the
    /// keyboard's height from the safe area any more. So it listens instead.
    @State private var keyboardHeight: CGFloat = 0
    /// The footer's real height, measured. Needed to work out how much of the
    /// keyboard actually covers the *step* rather than the footer.
    @State private var footerHeight: CGFloat = 0
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

    private enum Field { case place, title, short, long, transcript }
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
    /// How many characters of 13pt SF Mono fit on one line of a wizard field.
    ///
    /// 345pt of step width less `AtlasSpacing.md` of field padding each side
    /// leaves 313pt, and SF Mono advances 0.6em — so 7.8pt a character, and
    /// forty of them. Used to size each box to the most it will ever hold.
    private static let charsPerFieldLine = 40

    /// A box tall enough for everything its limit allows.
    ///
    /// Owner, 2026-08-20: *"size them to what the maximum text allowed would
    /// be."* So the box is the limit, drawn — you can see how much room you
    /// have before you start rather than watching a counter run down, and the
    /// layout never moves as you type because it was already that tall.
    ///
    /// ⚠️ Also what makes the boxes VISIBLE. They were always pure black
    /// (`AtlasColors.background`) on a `#1C1C1E` page — an 11% difference,
    /// which at one line tall reads as no box at all. That is what the owner
    /// saw. A large black area against that ground reads immediately.
    /// A field's text with any line breaks taken out and its limit applied.
    ///
    /// Newlines become spaces rather than vanishing, so "The Old\nCustom
    /// House" reads as it was meant to instead of running together. Trimmed
    /// only at the limit — not at the ends — because trimming as you type
    /// would eat the space you just pressed.
    static func oneLine(_ raw: String, limit: Int) -> String {
        let flattened = raw.replacingOccurrences(of: "\n", with: " ")
        return flattened.count > limit ? String(flattened.prefix(limit)) : flattened
    }

    private static func fieldLines(for limit: Int) -> Int {
        max(1, Int((Double(limit) / Double(charsPerFieldLine)).rounded(.up)))
    }

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
        // A saved tour keeps its city but not the search phrase that found it,
        // so the field opens showing the city — enough to recognise, and
        // re-searching replaces it.
        locationQuery = tour.city ?? ""

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
                // X on every step, never a back chevron. Going back is the
                // footer's job now, so the header means exactly one thing —
                // get me out of here — which is also what it means on
                // `TourDetailView`, the canon for page chrome.
                Button { closeTapped() } label: {
                    AtlasChromeButton("xmark")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
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
            // 🔴 A STEP IS A SCREENFUL, AND ITS ONE ELASTIC ELEMENT TAKES
            // WHAT'S LEFT. No step may scroll (owner, 2026-08-20) — but a
            // fixed height is a different height on every phone, which is the
            // same trap that cropped the hero photograph 8% on one device and
            // 23% on another. So nothing here is sized in absolute points if
            // it can be sized by what remains.
            //
            // How it works: `minHeight: geo.size.height` makes the content at
            // least a screenful, which gives the VStack a definite height to
            // divide up — so a child asking for `maxHeight: .infinity` (the
            // map, today) genuinely expands instead of collapsing to its ideal
            // size, which is what happens to a flexible child in a plain
            // ScrollView.
            //
            // ⚠️ The ScrollView stays, deliberately, as a safety valve. It has
            // nothing to scroll when the step fits, so the rule holds; but a
            // device or text size nobody anticipated gets a scroll rather than
            // content silently clipped off the bottom. Given the choice
            // between breaking the rule and hiding the Next button, break the
            // rule.
            GeometryReader { geo in
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
                    // 🔴 THE ELASTIC ELEMENT GIVES UP ITS OWN HEIGHT TO THE
                    // KEYBOARD, rather than hiding behind it (owner decision,
                    // 2026-08-20).
                    //
                    // Step 1 could ignore the keyboard entirely: its only text
                    // field was the search bar at the top, so a keyboard over
                    // the bottom half covered nothing anyone was looking at.
                    // Step 2 is the first step whose tall field is at the
                    // BOTTOM — and with the layout frozen, tapping into the
                    // description put the caret behind the keyboard. Not a
                    // scrolling problem: you could not see what you were
                    // typing.
                    //
                    // Shrinking the region the step is laid out in makes the
                    // elastic child absorb the loss, exactly as it absorbs the
                    // difference between one phone and another. Description
                    // goes 344 → about 140pt with the keyboard up, still four
                    // times its minimum, and nothing scrolls.
                    .frame(minHeight: max(0, geo.size.height - keyboardOverlap),
                           alignment: .top)
                    // 🔴 TAP ANYWHERE THAT ISN'T A CONTROL TO PUT THE KEYBOARD
                    // AWAY. Owner, 2026-08-20: *"when in the input fields and
                    // the keyboard is up, it's rather difficult to click out of
                    // the keyboard."*
                    //
                    // It was difficult because the only way out was
                    // `scrollDismissesKeyboard`, which needs something to
                    // scroll — and the whole point of this rebuild is that a
                    // step fits, so on most steps there is nothing to scroll
                    // and the gesture did nothing at all. Sizing the fields to
                    // their character limits made it worse again by leaving
                    // almost no bare screen to tap.
                    //
                    // ⚠️ A `.toolbar` "Done" above the keyboard is the usual
                    // iOS answer and is NOT AVAILABLE HERE — see `body`. The
                    // toolbar bridge is what hung this screen
                    // (`UIKitToolbarStrategy.updateLocations()` inside
                    // `_sheetLayoutInfoLayout:`), which is why the wizard has
                    // no NavigationStack and no toolbar of any kind. Do not
                    // reintroduce one for this.
                    //
                    // Attached AFTER the frame so the shape covers the whole
                    // screenful, including the empty space below the content —
                    // and as a plain `onTapGesture` rather than a simultaneous
                    // one, so the fields, buttons, slider and map still take
                    // their own taps first. A simultaneous gesture would fire
                    // on the tap that focuses a field and dismiss the keyboard
                    // it had just raised.
                    .contentShape(Rectangle())
                    .onTapGesture { focused = nil }
                }
                .scrollDismissesKeyboard(.interactively)
                // 🔴 MEASURED, BECAUSE `maxHeight: .infinity` DOES NOT WORK
                // HERE. A flexible child gets no room from a ScrollView whose
                // content frame sets only a `minHeight` — the frame stretches
                // to a screenful and top-aligns while the child stays at its
                // floor. That was the map on step 1 and the transcript box on
                // step 6, both showing a screenful of dead space beneath a
                // control at its minimum. Step 1 was fixed by giving the map a
                // real shape; a text box has no natural shape, so it takes
                // this number instead.
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { stepAreaHeight = $0 }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            // Measured rather than assumed: `keyboardOverlap` needs to know how
            // much of the keyboard the footer is already standing in front of.
            // Constant in practice — the hint line reserves two lines whether
            // or not it has anything to say — so this settles once.
            footer.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { footerHeight = $0 }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillShowNotification)) { note in
            let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
            withAnimation(.easeOut(duration: 0.22)) { keyboardHeight = frame?.height ?? 0 }
        }
        .onReceive(NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillHideNotification)) { _ in
            withAnimation(.easeOut(duration: 0.22)) { keyboardHeight = 0 }
        }
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
        // The recogniser writes as it goes, so this fires repeatedly while a
        // recording is being transcribed. `applyTranscript` is what decides
        // whether the words are welcome.
        .onChange(of: transcriber.text) { _, words in
            applyTranscript(words)
        }
        // Typing in the box, once, ends automatic writing for good. Compared
        // against the transcriber's own text so that the writes it makes
        // through `applyTranscript` don't count as the maker typing.
        .onChange(of: transcript) { _, typed in
            if typed != transcriber.text { transcriptEdited = true }
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
                } else if let stepGuidance {
                    Text(stepGuidance)
                        .foregroundStyle(AtlasColors.tertiaryText)
                } else {
                    Text(" ")
                }
            }
            .font(AtlasTypography.caption)
            .lineLimit(2, reservesSpace: true)
            .frame(maxWidth: .infinity, alignment: .leading)

            // A step may pin its own controls here, directly above the nav row
            // — today only the transcript step does. ⚠️ This makes the footer
            // a different height on that one step, which is fine because
            // `footerHeight` is *measured*; nothing may start assuming it.
            stepAccessory

            // Back · Save · Next — three equal columns, three glyphs
            // (owner, 2026-08-20). Nothing in this row is ever drawn as
            // words; the strings passed in are what VoiceOver reads.
            HStack(spacing: AtlasSpacing.sm) {
                footerButton("Back", icon: "chevron.left",
                             enabled: step.previous != nil && !isBusy,
                             action: goBack)

                footerButton("Save draft", icon: "folder",
                             enabled: canPersist && !isBusy,
                             busy: isSavingInPlace,
                             action: saveProgress)

                footerButton(primaryLabel, icon: primaryIcon,
                             filled: true,
                             enabled: canAdvance && !isBusy,
                             busy: isSubmitting || (isPersisting && !isSavingInPlace),
                             action: primaryTapped)
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

    /// One of the footer's three columns.
    ///
    /// 🔴 EVERY BUTTON IN THIS ROW IS A GLYPH, ALWAYS (owner, 2026-08-20).
    /// Not words-until-they-don't-fit: three icons, every step, so the row
    /// never changes character between one step and the next.
    ///
    /// That is why there is no `ViewThatFits` here any more, and no measuring.
    /// An earlier version chose words when words fitted — which, measured,
    /// they always did on every current iPhone, so the row read as one word
    /// flanked by two arrows and the fallback glyph was unreachable. A rule
    /// with no exceptions needs no machinery to decide.
    ///
    /// The three are also always the same width: `maxWidth: .infinity` splits
    /// the row in thirds and the capsule is painted across the whole of its
    /// third, so no button can be bigger than its neighbours.
    ///
    /// ⚠️ `text` is still required, and is the accessibility label. A row of
    /// three unlabelled glyphs is unusable with VoiceOver, so the words have
    /// to survive even though nothing draws them.
    private func footerButton(_ text: String,
                              icon: String,
                              filled: Bool = false,
                              enabled: Bool,
                              busy: Bool = false,
                              action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if busy {
                    // The spinner replaces the glyph rather than joining it —
                    // two marks in one capsule reads as a mistake.
                    ProgressView()
                        .controlSize(.small)
                        .tint(filled ? AtlasColors.background : AtlasColors.primaryText)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .regular))
                }
            }
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .foregroundStyle(filled ? AtlasColors.background : AtlasColors.primaryText)
            .background(filled ? AtlasColors.mapPin : AtlasColors.background)
            .clipShape(Capsule())
            .overlay {
                if !filled {
                    Capsule().stroke(AtlasColors.tertiaryText.opacity(0.5), lineWidth: 1)
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        // Dimmed rather than hidden — a disabled Back on step 1 shows that
        // going back is a thing this row does, before there is anywhere to go.
        .opacity(enabled ? 1 : 0.4)
        .accessibilityLabel(text)
    }

    /// A natural-width capsule. The confirmation screen's Done is the only one
    /// left — the footer's three size themselves against each other instead.
    private func pill(_ text: String, filled: Bool) -> some View {
        Text(text)
            .font(AtlasTypography.caption)
            .padding(.horizontal, AtlasSpacing.lg)
            .padding(.vertical, 12)
            .foregroundStyle(filled ? AtlasColors.background : AtlasColors.primaryText)
            .background(filled ? AtlasColors.mapPin : AtlasColors.background)
            .clipShape(Capsule())
    }

    /// How far the keyboard reaches into the step's own area.
    ///
    /// The keyboard covers the bottom of the *screen*; the footer is already
    /// standing in that space, unmoved, because the wizard ignores the
    /// keyboard's safe area. Only what is left over eats into the step.
    private var keyboardOverlap: CGFloat {
        max(0, keyboardHeight - footerHeight)
    }

    /// Any write in flight. Every footer button waits on it — two of them
    /// would otherwise start a second write over the first.
    private var isBusy: Bool { isPersisting || isSubmitting || isDeleting }

    // MARK: - Steps

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .location: locationStep
        case .details:  detailsStep
        case .tags:     tagsStep
        case .photos:   photosStep
        case .audio:    audioStep
        case .transcript: transcriptStep
        case .review:   reviewStep
        }
    }

    private var locationStep: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.md) {
            // No label. The placeholder says what the field is for — the same
            // arrangement as the home search bar, which is what the owner
            // asked this to match.
            //
            // The dropdown is an OVERLAY, not the next thing in the stack.
            // Stacked, three suggestions push the map 150pt down and off the
            // bottom of the screen, which is how the old two-field version
            // broke the no-scrolling rule the moment anyone typed. Drawn over
            // the map instead, it costs no layout at all.
            locationSearchField
                .zIndex(1)
                .overlay(alignment: .topLeading) {
                    if showingPlaceSuggestions, !placeSearch.suggestions.isEmpty {
                        suggestionList(placeSearch.suggestions) { pickPlace($0) }
                            .offset(y: AtlasSpacing.searchBarHeight + AtlasSpacing.xs)
                    }
                }

            // 🔴 SQUARE, NOT ELASTIC — and it was never actually elastic.
            // This asked for `maxHeight: .infinity` inside a ScrollView whose
            // content frame sets only a `minHeight`, and a flexible child
            // gets no room from a container sized by its own content: the
            // frame stretches to the screenful and top-aligns, while the map
            // sits at its 200pt floor with the rest as dead space. That is
            // exactly what the owner's screenshot showed.
            //
            // Sizing it like every other map in the app fixes the symptom and
            // removes the dependency at once. Its instruction still rides ON
            // it rather than above it, which is 21pt the map keeps.
            mapSection
                .atlasHeroSizing(nil)

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("TRIGGER RADIUS — \(Int(radius)) m")
                // No "15 m"/"100 m" end caps. The label already carries the
                // live value, and a slider's ends are self-evident the moment
                // you drag it — 21pt for something nobody reads twice.
                Slider(value: $radius, in: Self.radiusRange, step: 5)
                    .tint(AtlasColors.mapPin)
            }
            // The line explaining the circle now lives in the footer's hint
            // slot, which reserves two lines whether or not it has anything to
            // say — see `stepGuidance`. Free real estate; the map gets it.
        }
    }

    /// The home search bar's shape — capsule, magnifying glass, placeholder
    /// inside — made editable.
    ///
    /// ⚠️ One deliberate difference from `SearchBar`: the fill is
    /// `AtlasColors.background`, not `secondaryBackground`. On Home that bar
    /// floats over the map, so the chrome colour reads against it; here the
    /// page ground *is* `secondaryBackground`, and a bar in the same colour
    /// would be invisible. Same shape, the fill the wizard's other fields use.
    private var locationSearchField: some View {
        HStack(spacing: AtlasSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            TextField("Search location", text: $locationQuery)
                .font(AtlasTypography.caption)
                .focused($focused, equals: .place)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onChange(of: locationQuery) { _, new in
                    // Only a person typing opens the dropdown. Loading a saved
                    // tour fills this field, and `pickPlace` rewrites it —
                    // neither is a search, and both used to re-open the list
                    // and set a completer streaming results mid-layout.
                    guard focused == .place else { return }
                    placeSearch.search(new)
                    showingPlaceSuggestions = true
                    // Typing again after a pick means they are changing their
                    // mind, so the old resolution shouldn't linger on Review.
                    if new != resolvedPlaceName { resolvedPlaceName = nil }
                }
                .onSubmit { showingPlaceSuggestions = false }

            if isResolvingPlace {
                ProgressView()
            } else if !locationQuery.isEmpty {
                Button {
                    locationQuery = ""
                    resolvedPlaceName = nil
                    placeSearch.clear()
                    showingPlaceSuggestions = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear the search")
            }
        }
        .padding(.horizontal, AtlasSpacing.md)
        .frame(height: AtlasSpacing.searchBarHeight)
        .background(AtlasColors.background, in: Capsule())
    }

    /// The dropdown under the place field. Deliberately not a `List` —
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

    /// Picking a suggestion drops the pin on it and fills in everything the
    /// two fields used to ask for separately.
    ///
    /// It handles a city and a building with the same code because
    /// `resolveDetails` answers the same shape for both: a coordinate to pin,
    /// a region to frame, and the locality and country underneath it. Search
    /// "Porto" and you get the city framed with `city` filled; search "Casa da
    /// Música" and you get the building framed with `city` filled from the
    /// address it sits at. The maker never types Porto twice.
    ///
    /// The field stays editable afterwards — a suggestion is a shortcut, not a
    /// commitment, and a tour can be about somewhere the map has never heard
    /// of.
    private func pickPlace(_ suggestion: PlaceSuggestion) {
        focused = nil
        showingPlaceSuggestions = false
        locationQuery = suggestion.title
        resolvedPlaceName = suggestion.title
        placeSearch.clear()
        isResolvingPlace = true
        Task {
            defer { isResolvingPlace = false }
            guard let place = await placeSearch.resolveDetails(suggestion) else { return }
            centerCoordinate = place.coordinate
            cameraPosition = .region(Self.framing(place))
            // Later searches rank near what was just found, so a maker working
            // through one city doesn't get the other side of the world.
            placeSearch.regionBias = place.region
            city = place.locality
            country = place.country
        }
    }

    /// How tightly to frame a resolved place.
    ///
    /// A specific place gets 400m — the maker is checking the pin is on the
    /// right door, not browsing. A city or a district keeps the region MapKit
    /// derived for it, because framing Porto at 400m drops them on one
    /// arbitrary street with no way of telling which.
    ///
    /// ⚠️ The two are told apart by **how big the resolved region is**, not by
    /// what the placemark calls itself. `locality` is the obvious-looking
    /// discriminator and it does not work: a resolved city reports its own
    /// name as the locality exactly as a building in that city does. The
    /// region does distinguish them — `PlaceSearchService.region(for:)` sizes
    /// it from the placemark's own radius, so a POI lands on its 1km floor
    /// while a city comes back several km across.
    private static func framing(_ place: ResolvedPlace) -> MKCoordinateRegion {
        let metresAcross = place.region.span.latitudeDelta * 111_000
        guard metresAcross <= 2_000 else { return place.region }
        return MKCoordinateRegion(center: place.coordinate,
                                  latitudinalMeters: 400,
                                  longitudinalMeters: 400)
    }

    /// What the place would call the tour, if the maker hasn't named it.
    /// Offered on the way out of step 1, never imposed.
    ///
    /// A typed-but-unpicked phrase counts — someone who typed the building's
    /// name and then panned to it by hand meant it just as much. A search for
    /// the *city* does not: "Porto" is where a tour is, not what it is called,
    /// and a catalogue of tours named after their cities helps nobody.
    private var suggestedTitle: String {
        let named = resolvedPlaceName
            ?? locationQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return named == city ? "" : named
    }

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            if let c = centerCoordinate {
                MapCircle(center: c, radius: radius)
                    .foregroundStyle(AtlasColors.mapPin.opacity(0.18))
                    .stroke(AtlasColors.mapPin, lineWidth: 2)
            }
        }
        // 🔴 THE SAME FOOTPRINT AS THE MAP ON A TOUR PAGE — square, and square
        // corners. Owner, 2026-08-20, from a device screenshot: *"Map is too
        // small. Make it the same size as what would appear on a tour detail,
        // places, etc page. Square. No rounded corners."*
        //
        // `.atlasHeroSizing(nil)` is literally the modifier `TourDetailView`
        // and `PlaceView` size their maps with, so this cannot drift from
        // them: it takes `AtlasSpacing.heroAspectRatio`, which is 1.0. No
        // `clipShape` for the same reason — those maps have square corners,
        // matching the hero image they swap with.
        //
        // ⚠️ This makes the map FIXED rather than elastic, and that is the
        // point rather than a side effect. See the call site.
        .overlay {
            // Fixed centre pin — the map centre IS the chosen coordinate, so
            // panning the map moves the pin. Tip anchored at the true centre.
            Image(systemName: "mappin")
                .font(.title)
                .foregroundStyle(AtlasColors.mapPin)
                .offset(y: -11)
                .allowsHitTesting(false)
        }
        .overlay(alignment: .topLeading) {
            // The instruction, on the map instead of above it. A solid fill
            // rather than a material: map tiles are busy and light or dark
            // depending on where in the world the maker is, and the app moved
            // its chrome off materials for the same reason (PR #76).
            Text("PAN TO PLACE THE PIN")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
                .padding(.horizontal, AtlasSpacing.sm)
                .padding(.vertical, 5)
                .background(AtlasColors.background.opacity(0.9), in: Capsule())
                .padding(AtlasSpacing.sm)
                // Never eat a pan that starts on the label.
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
                TextField("e.g. The Old Custom House", text: $title, axis: .vertical)
                    .lineLimit(Self.fieldLines(for: Self.titleLimit), reservesSpace: true)
                    .focused($focused, equals: .title)
                    // 🔴 NO LINE BREAKS IN A TITLE. Sizing this box to its
                    // 60-character limit meant making it `axis: .vertical`,
                    // and a vertical TextField treats Return as a newline
                    // rather than as "done" — so a title could carry one, and
                    // then carry it into the catalogue, the share card and the
                    // lock screen. Same for the one-liner below, which is
                    // called a one-liner for a reason. Stripped on the way in,
                    // beside the limit that is already enforced here.
                    .onChange(of: title) { _, new in
                        title = Self.oneLine(new, limit: Self.titleLimit)
                    }
                    .wizardFieldStyle()
            }

            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("SHORT DESCRIPTION", remaining: Self.shortLimit - shortDescription.count)
                TextField("One line shown on cards", text: $shortDescription, axis: .vertical)
                    .lineLimit(Self.fieldLines(for: Self.shortLimit), reservesSpace: true)
                    .focused($focused, equals: .short)
                    .onChange(of: shortDescription) { _, new in
                        shortDescription = Self.oneLine(new, limit: Self.shortLimit)
                    }
                    .wizardFieldStyle()
            }

            // ⚠️ THE LABELS STAY, and that is a deliberate departure from step
            // 1, where the label went and the placeholder did its job. That
            // worked because step 1 had ONE field with an obvious purpose.
            // Three stacked text boxes are a different problem: a placeholder
            // disappears the moment you type, so on coming back to the step —
            // or editing the tour months later — there would be nothing to say
            // which box is the one-liner and which is the description. The
            // labels also carry the character countdowns, which have nowhere
            // else sensible to live.

            // This step's elastic element. The description is the thing a
            // maker writes most in, so it takes whatever the screen has left:
            // about 344pt on a 6.3" phone, which holds the entire 600-character
            // limit without scrolling, and less on a smaller one.
            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                fieldLabel("DESCRIPTION", remaining: Self.longLimit - longDescription.count)
                TextField("What this tour is about", text: $longDescription, axis: .vertical)
                    .focused($focused, equals: .long)
                    // Three lines at rest, two while the keyboard is up. On a
                    // 6.3" phone there is room for eighteen either way, but an
                    // SE with the keyboard showing has about 91pt for this
                    // group — and a three-line floor is 83pt of that plus a
                    // label, which is the one combination that would still
                    // have scrolled.
                    // Sized to the 600-character limit rather than flexible.
                    // ⚠️ This also retires a `maxHeight: .infinity` that was
                    // never doing anything — a flexible child gets no room
                    // from a ScrollView frame that sets only a minHeight.
                    .lineLimit(Self.fieldLines(for: Self.longLimit), reservesSpace: true)
                    .onChange(of: longDescription) { _, new in
                        if new.count > Self.longLimit { longDescription = String(new.prefix(Self.longLimit)) }
                    }
                    // Top-aligned inside the tall box: text that starts in the
                    // middle of a 344pt field reads as a bug.
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .wizardFieldStyle()
                    // ⚠️ Without this the box is a 344pt target of which only
                    // the first line is tappable — a `TextField` sizes to its
                    // text, so the empty space below it belongs to nothing.
                    // Tapping anywhere in the painted box starts writing.
                    .contentShape(Rectangle())
                    .onTapGesture { focused = .long }
            }
        }
    }

    /// Tags, on their own step since 2026-08-20 — see `TourWizardStep`.
    ///
    /// The picker fills the step because its open group is the elastic element,
    /// the same shape as the map on Location and the description on Details.
    /// Every group now opens with the page still fitting: the tallest, Theme,
    /// needs 226pt and gets 242.
    private var tagsStep: some View {
        ControlledTagPicker(selectedTags: $selectedTags, architect: $architect)
            .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private var photosStep: some View {
        if let draft {
            // No label. The header two lines above it already says PHOTOS, and
            // the rest of what that label said — how many fit, which one is the
            // cover — is now the COVER badge and the footer's count.
            //
            // Adding, framing, reordering and removing all happen here. There
            // is no second screen for it — the step is the page.
            PhotoGridEditor(tour: draft.tour)
                .id(draft.tour.id)
        } else {
            missingDraftNotice
        }
    }

    /// Recording, and nothing else (owner, 2026-08-20: *"i want everything to
    /// happen on one page. drop the transcription window."*).
    ///
    /// The transcript box used to sit under the recorder, which put each in the
    /// other's way: you cannot type while recording, and a live level meter is
    /// poor company for a text field. It also made this the one step with no
    /// elastic element — every height fixed — so reviewing a take came to 512pt
    /// against an SE's 417 and ran off the bottom. With the box gone the
    /// recorder simply takes the step.
    @ViewBuilder
    private var audioStep: some View {
        if let draft {
            TourAudioSection(tour: draft.tour,
                             onUploadStateChange: { audioUpload = $0 },
                             onAudioReady: { localURL in
                                 // Transcribe the file we still have on disk,
                                 // not the copy that just went up: it is right
                                 // here, and the uploaded one would have to be
                                 // fetched back to be read.
                                 startTranscription(of: localURL)
                             })
                // Centred, not top-aligned. With the transcript box gone this
                // step holds one button most of the time, and 75pt of controls
                // pinned to the top of 529pt of nothing reads as a screen that
                // failed to load. Centring also keeps the record button in the
                // same place whether or not audio is already attached.
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        } else {
            missingDraftNotice
        }
    }

    /// The words, already written down — a step you correct rather than fill.
    ///
    /// ⚠️ **An arriving transcript never overwrites typing.** `applyTranscript`
    /// is the only writer and it refuses when the box has been edited, because
    /// a maker who starts typing while the recogniser is still working would
    /// otherwise watch their sentence be replaced by a machine's. Late results
    /// are the normal case, not the edge one: transcription of a three-minute
    /// recording outlives the walk from step 5 to step 6.
    @ViewBuilder
    private var transcriptStep: some View {
        if draft != nil {
            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                HStack(spacing: AtlasSpacing.sm) {
                    fieldLabel("TRANSCRIPT — OPTIONAL")
                    if transcriber.isWorking {
                        ProgressView().controlSize(.small)
                    }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: {
                    transcriptLabelHeight = $0
                }

                // 🔴 A BOX, AND IT SCROLLS. Owner, 2026-08-20: *"the
                // transcription field (like the input fields) need to be
                // contrasted. that is probably scrollable since the audio may
                // be long, which is ok."*
                //
                // A `TextField(axis: .vertical)` grows to its text and cannot
                // scroll, so the painted background was drawn tight around two
                // lines and the `maxHeight: .infinity` that was meant to
                // stretch it did nothing — a small black rectangle on a nearly
                // black page, under a screenful of nothing. `TextEditor` has
                // its own scroller, so the box can be a fixed shape and a
                // twenty-minute narration still fits inside it.
                //
                // ⚠️ It needs `scrollContentBackground(.hidden)` or UIKit's own
                // fill paints over `wizardFieldStyle`'s, and the inner
                // `maxHeight: .infinity` is what makes the editor fill the
                // outer `.frame(height:)` — that one proposes a definite
                // height, which is exactly what the ScrollView never did.
                TextEditor(text: $transcript)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scrollContentBackground(.hidden)
                    .focused($focused, equals: .transcript)
                    .overlay(alignment: .topLeading) {
                        if transcript.isEmpty {
                            // `TextEditor` has no placeholder of its own.
                            Text("The words spoken in the audio")
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.tertiaryText)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }
                    }
                    .wizardFieldStyle()
                    .frame(height: transcriptBoxHeight)

                // The language menu and Transcribe again used to sit here.
                // They are in the footer now, pinned above Back · Save · Next
                // (owner, 2026-08-20) — so they keep their place while the box
                // grows, and the box gets the height they were using.
                //
                // The recogniser's note went with them, into the footer's hint
                // slot: it already reserves two lines on every step, and two
                // separate places for the step to speak was one too many.
            }
        } else {
            missingDraftNotice
        }
    }

    /// What's left of the step once the label has taken its line.
    ///
    /// The 120pt floor is the safety net for a phone or text size where the
    /// arithmetic leaves nothing — better a short box that scrolls than a box
    /// with no height at all.
    private var transcriptBoxHeight: CGFloat {
        let usable = stepAreaHeight - keyboardOverlap - AtlasSpacing.lg * 2
        return max(120, usable - transcriptLabelHeight - AtlasSpacing.xs)
    }

    /// The transcript step's own controls, pinned in the footer rather than
    /// left to float at the bottom of a box that changes height.
    ///
    /// 🔴 Owner, 2026-08-20: *"the language and transcribe again buttons should
    /// then reside fixed on the bottom above the back/save/next buttons."*
    /// Which is right for a step whose one element now scrolls: a control that
    /// rides on scrolling content is a control that can leave the screen.
    @ViewBuilder
    private var stepAccessory: some View {
        if step == .transcript, draft != nil {
            HStack(spacing: AtlasSpacing.sm) {
                languageMenu
                AtlasPillButton(title: "Transcribe again",
                                systemImage: "arrow.clockwise",
                                enabled: lastLocalAudioURL != nil && !transcriber.isWorking) {
                    retranscribe()
                }
            }
        }
    }

    /// The language the recogniser is listening for, said out loud, with the
    /// list behind it.
    ///
    /// 🔴 STATING IT IS THE POINT; THE MENU IS SECONDARY. The device's language
    /// is only a guess at the narration's, and tour makers are exactly the
    /// people for whom the two differ — an English-set phone narrating in
    /// Spanish is ordinary. Running the wrong model doesn't fail, it returns
    /// fluent nonsense, so a maker who is never told which language was used
    /// has no way to know anything went wrong. A button alone wouldn't fix
    /// that: someone unaware of the problem never presses it. The name on
    /// screen is what makes the mismatch visible.
    ///
    /// Changing it re-transcribes on the spot, because a language you picked
    /// and then had to ask for again would be a setting pretending to be an
    /// action.
    @ViewBuilder
    private var languageMenu: some View {
        Menu {
            // The device's own language leads, so the common case is one tap
            // back rather than a hunt through forty entries.
            Button("Match my phone") { chooseLanguage("") }
            Divider()
            ForEach(supportedLocales, id: \.identifier) { locale in
                Button(AudioTranscriber.displayName(of: locale)) {
                    chooseLanguage(locale.identifier)
                }
            }
        } label: {
            AtlasPillLabel(title: spokenLanguageName,
                           systemImage: "globe",
                           trailingImage: "chevron.down")
        }
        .disabled(transcriber.isWorking || supportedLocales.isEmpty)
        .opacity(transcriber.isWorking || supportedLocales.isEmpty ? 0.35 : 1)
        .task {
            guard supportedLocales.isEmpty else { return }
            supportedLocales = await AudioTranscriber.supportedLocales()
        }
    }

    /// What to call the language on screen.
    ///
    /// Falls back to the phone's own name for its language when nothing has
    /// been chosen — never to a blank or to "Default", either of which would
    /// leave the maker unable to tell what was actually used.
    private var spokenLanguageName: String {
        // Short form: the button has half a row, and the region is the part
        // worth losing — see `shortDisplayName`.
        if !transcriptionLocaleID.isEmpty {
            return AudioTranscriber.shortDisplayName(of: Locale(identifier: transcriptionLocaleID))
        }
        return AudioTranscriber.shortDisplayName(of: Locale.current)
    }

    /// What the step says about where the automatic transcript got to.
    ///
    /// A failure is written as an ordinary note in `secondaryText`, not in the
    /// alarm colour: nothing has gone wrong for the maker — the box works, it
    /// is simply empty, and the transcript was never required.
    private var transcriptNote: String? {
        switch transcriber.phase {
        case .preparingModel:
            return "Getting the language ready — first time only."
        case .transcribing:
            return "Writing down what you recorded…"
        case .failed(let why):
            return why
        case .done, .idle:
            return nil
        }
    }

    /// The last look before it goes to a moderator — **the tour's own page**.
    ///
    /// 🔴 Owner, 2026-08-20: *"why don't you just make the review a preview of
    /// the tour detail page? this one can be scrollable."* Right on both
    /// counts, and it replaced two worse answers of mine in a row.
    ///
    /// First a **360pt hand-built mock of the player** — a fake scrubber, a
    /// fake play button — which had the flaw every mock has: it goes on saying
    /// "this is how it will look" long after that has stopped being true. Then
    /// a **checklist of the six steps**, which was honest and compact but
    /// answered a different question: whether the form was filled in, not what
    /// the thing looks like. `TourDetailView` in `.preview` mode answers the
    /// real one, and cannot drift from the page it is previewing, because it
    /// *is* that page.
    ///
    /// ⚠️ **This is the one step that scrolls, by explicit exception.** The
    /// rule everywhere else is that a step fits — the whole wizard was rebuilt
    /// around it. A tour page is as long as its description and its photos,
    /// which is exactly what a maker has come here to look at; capping it would
    /// mean previewing a truncation of their tour. The exception is granted for
    /// this step and stays granted for this step.
    ///
    /// ⚠️ What the preview leaves out and why is documented on
    /// `TourDetailView.Presentation` — chrome, the action row, stops, place and
    /// nearby, and every side effect. The last matters most: the live page's
    /// `onAppear` records the tour as recently viewed, which would put an
    /// unpublished draft in the maker's own Home rail.
    @ViewBuilder
    private var reviewStep: some View {
        if let draft {
            VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                // Full-bleed against the step's own padding: the page has its
                // own gutters and would otherwise sit inside two.
                // ⚠️ Live, not inert. Swiping the photographs and switching
                // to the map are the two things a maker has come here to do,
                // and both are safe — the sections the preview keeps read
                // nothing but `locationManager` and `openURL`. The only
                // control that would have taken them out of the wizard, GET
                // DIRECTIONS, is dropped in preview mode.
                //
                // Full-bleed against the step's own padding: the page brings
                // its own gutters and would otherwise sit inside two.
                TourDetailView(tour: previewTour(from: draft.tour), mode: .preview)
                    .padding(.horizontal, -AtlasSpacing.lg)

                Text(reviewFootnote)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)

                if existingTourId != nil {
                    AtlasPillButton(title: isDeleting ? "Deleting…" : "Delete tour",
                                    systemImage: "trash",
                                    destructive: true,
                                    enabled: !isDeleting) {
                        confirming = .deleting
                    }
                }
            }
        } else {
            missingDraftNotice
        }
    }

    /// The draft with its stop put back, for the preview only.
    ///
    /// 🔴 **`MakerTour` CARRIES NO STOPS, AND ON THIS SCREEN THAT IS VISIBLE.**
    /// Owner, 2026-08-20: *"doesn't seem like in this preview map view that the
    /// pin location is recorded."* It is recorded — `TourRow.asMakerTour`
    /// builds its `Tour` with `stops: []` because the profile feed needs a
    /// title, a status and an image and nothing more. Everywhere else that
    /// emptiness is invisible; a page that draws a pin per stop and prints a
    /// stop count shows it plainly, as an empty map and "0 stops" on a tour
    /// that has both.
    ///
    /// So the preview is handed the stop the wizard is holding anyway. That is
    /// also the more honest preview: `centerCoordinate` and `radius` are what
    /// Save is about to write, so the map shows where the tour WILL fire rather
    /// than where the server last heard it was.
    ///
    /// ⚠️ Preview only. This is a display copy — nothing persists from it, and
    /// the synthesized stop id is a fresh UUID each time it is built, which is
    /// fine for a map annotation and would be wrong for anything that wrote.
    /// This is the same gap `stopLocation(tourId:)` and `stopAudioURL(tourId:)`
    /// exist to close; a third caller needing real stops should fetch, not
    /// invent.
    private func previewTour(from tour: Tour) -> Tour {
        guard tour.stops.isEmpty, let coordinate = centerCoordinate else { return tour }
        let stop = Stop(
            id: UUID(),
            order: 0,
            title: trimmedTitle.isEmpty ? tour.title : trimmedTitle,
            caption: nil,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            audioURL: "",
            audioDurationSeconds: tour.totalDurationSeconds,
            triggerMode: .geofenced,
            triggerRadiusMeters: Int(radius),
            imageURL: tour.heroImageURL.isEmpty ? nil : tour.heroImageURL,
            transcriptText: transcript.isEmpty ? nil : transcript
        )
        return Tour(
            id: tour.id,
            title: tour.title,
            shortDescription: tour.shortDescription,
            longDescription: tour.longDescription,
            makerId: tour.makerId,
            heroImageURL: tour.heroImageURL,
            additionalImageURLs: tour.additionalImageURLs,
            videoURLs: tour.videoURLs,
            kind: tour.kind,
            stops: [stop],
            introAudioURL: tour.introAudioURL,
            totalDurationSeconds: tour.totalDurationSeconds,
            walkingDistanceMeters: tour.walkingDistanceMeters,
            centroidLatitude: coordinate.latitude,
            centroidLongitude: coordinate.longitude,
            city: tour.city,
            country: tour.country,
            primaryCategory: tour.primaryCategory,
            tags: tour.tags,
            priceUSD: tour.priceUSD,
            priceTier: tour.priceTier,
            createdAt: tour.createdAt
        )
    }

    /// Every step from Details on writes against a tour id, so until the
    /// Location step has created the draft there is nothing for them to act on.
    private var missingDraftNotice: some View {
        Text("Go back to Location and place the pin first.")
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
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

    /// What the step would like the maker to know, once nothing is blocking.
    ///
    /// This is why the hint line reserves two lines whether or not it has
    /// anything to say: the reservation was already being paid for — it keeps
    /// the footer's height constant, which the sheet's layout depends on — so
    /// explanatory copy that used to sit in the step itself now costs nothing.
    /// Step 1's line about the geofence circle was 41pt of the map's space.
    ///
    /// Deliberately ranked *below* `blockingHint`: when something is stopping
    /// you, that is the more urgent thing to read.
    private var stepGuidance: String? {
        // ⚠️ ONE LINE EACH, AND THAT IS A HARD LIMIT, NOT A STYLE NOTE.
        // The slot reserves exactly two lines — it has to be a constant height,
        // or the footer's height becomes a moving layout input for everything
        // above it — and a *blocking* reason can legitimately need both
        // ("Pan the map to put the pin where the tour begins." is two).
        // Guidance therefore gets one: about 44 characters at 13pt SF Mono in
        // 345pt. Past that it doesn't wrap, it truncates mid-sentence.
        switch step {
        case .location:
            // "Plays", not "fires" — a maker is not writing a trigger.
            return "Plays when someone steps inside the circle."
        case .details:
            // The owner's rule from 2026-08-19, and not something a screen of
            // empty fields tells you on its own.
            return "Only a title is required."
        case .tags:
            // Was three lines inside the picker, which cost it 55pt. Says what
            // tags buy rather than demanding them: nothing here is required.
            return "Tags are how people find your tour."
        case .photos:
            // The count line that used to sit under the grid. Silent while
            // there are none, because `blockingHint` is saying something more
            // useful then.
            guard let tour = draft?.tour else { return nil }
            let count = ([tour.heroImageURL] + (tour.additionalImageURLs ?? []))
                .filter { !$0.isEmpty }.count
            guard count > 0 else { return nil }
            // ⚠️ "hold", not "drag" — and the word is the fix, not a wording
            // preference. `.draggable` is a UIKit drag interaction: the tile
            // lifts after about half a second of pressing, and until it lifts
            // a drag is just a scroll. Owner, 2026-08-20: *"don't think the
            // drag to reorder quite works. or at least it's difficult to make
            // it work."* It worked; nothing said how to start it.
            return "\(count) of \(PhotoGridEditor.maxPhotos) · hold a photo to move it."
        case .transcript:
            // The recogniser's own note comes first when it has one — it is
            // the more urgent thing to read, and this is the only slot on the
            // step that says anything now that the box takes the rest.
            // Otherwise: what the step is for, since a box that filled itself
            // invites the question.
            return transcriptNote ?? "Read it through — fix anything it misheard."
        case .audio, .review:
            return nil
        }
    }

    /// What VoiceOver says for the primary button. **Never drawn** — the row
    /// is glyphs — so it is free to be as long as it needs to be, and it says
    /// the whole thing rather than the shortest thing that fits a capsule.
    ///
    /// Editing something already live is allowed — a maker shouldn't need an
    /// admin to fix a typo — but it re-enters moderation rather than changing
    /// under a listener mid-tour, and the label says so.
    private var primaryLabel: String {
        guard step == .review else { return "Next" }
        switch draft?.status {
        case .inReview:  return "In review"
        case .published: return "Submit changes for review"
        default:         return "Submit for review"
        }
    }

    /// The primary's glyph. A chevron on the way through the wizard, matching
    /// Back; something else on Review, where the button stops meaning "next"
    /// and starts meaning "hand this over".
    ///
    /// ⚠️ Review's glyph is doing more work than the others, because it is the
    /// only irreversible-feeling tap in the flow — it puts the tour in front
    /// of a moderator. A paper plane is the clearest "sent" the symbol set
    /// has, and `reviewFootnote` sits directly above the row saying in words
    /// what the row no longer can.
    private var primaryIcon: String {
        guard step == .review else { return "chevron.right" }
        return draft?.status == .inReview ? "clock" : "paperplane.fill"
    }

    /// ⚠️ **This and the footer's disabled-button reason must not say the same
    /// thing.** Owner, 2026-08-20, circling both at once: *"what does 'already
    /// with us, we'll let you know either way' mean? maybe consider
    /// rephrasing."* Fair on both counts — it appeared twice on one screen, and
    /// "either way" was standing in for two outcomes it never named.
    ///
    /// They have different jobs and now sound like it: this describes the
    /// tour's state, the footer says why the button won't act. Neither promises
    /// a message, because nothing sends the maker one — `notify-moderation`
    /// emails the owner. What a maker can actually observe is the status on
    /// their profile, so that is what this points at.
    private var reviewFootnote: String {
        switch draft?.status {
        case .inReview:
            return "In review. The status on your profile changes once we've looked at it — usually within a day."
        case .published:
            return "This tour is live. Saving changes sends it back for review before they appear."
        default:
            return "We review every tour before it goes live. Most are looked at within a day."
        }
    }

    /// The Audio row on Review, which carries the upload through rather than
    /// leaving the maker to guess whether it finished.

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
            || !locationQuery.isEmpty
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
        if step == .location, trimmedTitle.isEmpty, !suggestedTitle.isEmpty {
            title = String(suggestedTitle.prefix(Self.titleLimit))
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
        isSavingInPlace = true
        Task {
            defer { isPersisting = false; isSavingInPlace = false }
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

    // MARK: - Transcription

    /// Start writing down a recording the maker just made or imported.
    ///
    /// Only ever called with a file that is still on this device. A tour opened
    /// for editing months later has its audio on the server and no local copy,
    /// so it keeps whatever transcript it was saved with — re-fetching a few
    /// megabytes to redo work already done would be the wrong trade.
    private func startTranscription(of localURL: URL) {
        lastLocalAudioURL = localURL
        transcriber.preferredLocaleID = transcriptionLocaleID
        // ⚠️ Words already in the box win, even against newer audio. Replacing
        // the narration does make an existing transcript wrong — but it may be
        // a transcript the maker wrote or corrected by hand, and no automatic
        // process gets to throw that away. `retranscribe()` is how they ask.
        guard !transcriptEdited else { return }
        transcriber.transcribe(fileURL: localURL)
    }

    /// Make the transcript again from the recording, discarding what's in the
    /// box. The one path that overwrites a maker's own words, and it exists
    /// precisely so that the automatic path never has to.
    /// Pick the language the narration is in, and act on it immediately.
    ///
    /// Empty means follow the phone. Choosing the language that is already in
    /// use does nothing — re-running the same model over the same audio to get
    /// the same words back would only look like an action that failed.
    private func chooseLanguage(_ identifier: String) {
        guard identifier != transcriptionLocaleID else { return }
        transcriptionLocaleID = identifier
        transcriber.preferredLocaleID = identifier
        guard lastLocalAudioURL != nil else { return }
        retranscribe()
    }

    private func retranscribe() {
        guard let url = lastLocalAudioURL else { return }
        transcript = ""
        transcriptEdited = false
        transcriber.transcribe(fileURL: url)
    }

    /// Put recognised words in the box, unless the maker has been typing.
    ///
    /// 🔴 The refusal is the point. Transcription outlives the walk from the
    /// audio step to this one, so results arrive while the box is on screen —
    /// and a maker who started typing would watch their sentence replaced.
    /// Automatic text yields to a person, always, and never the other way.
    private func applyTranscript(_ words: String) {
        guard !transcriptEdited, !words.isEmpty else { return }
        transcript = words
    }

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
        // Rank search results near the maker before they've picked anything.
        // Without a bias the completer answers from the whole world, so a
        // maker in Porto searching "cathedral" is offered Cologne.
        placeSearch.regionBias = MKCoordinateRegion(
            center: coord, latitudinalMeters: 30_000, longitudinalMeters: 30_000)
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
    /// ⚠️ **The border is the contrast, and it is the second attempt.** The
    /// fill is `AtlasColors.background` — pure black — on a page of `#1C1C1E`,
    /// an 11% difference that reads as no box at all. Sizing the boxes to their
    /// character limits was the first lever and wasn't enough: owner,
    /// 2026-08-20, *"the transcription field (like the input fields) need to be
    /// contrasted."* A hairline was named at the time as the next lever, so
    /// this is it, applied to every field at once rather than to the one that
    /// was complained about.
    func wizardFieldStyle() -> some View {
        self
            .font(AtlasTypography.caption)
            .padding(AtlasSpacing.md)
            .background(AtlasColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
            .overlay {
                RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                    .stroke(AtlasColors.divider, lineWidth: 1)
            }
    }
}
