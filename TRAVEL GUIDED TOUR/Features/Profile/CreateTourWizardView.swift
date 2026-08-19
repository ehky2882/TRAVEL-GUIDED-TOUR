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
    @Environment(MakerProfileService.self) private var makerProfileService
    @Environment(MakerTourService.self) private var makerTourService
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss

    enum Step: Int, CaseIterable {
        case location, details, photos, audio, review

        var label: String {
            switch self {
            case .location: return "LOCATION"
            case .details:  return "DETAILS"
            case .photos:   return "PHOTOS"
            case .audio:    return "AUDIO"
            case .review:   return "REVIEW"
            }
        }
    }

    @State private var step: Step = .location
    @State private var draftId: UUID?

    // Step 1 — location
    @State private var radius: Double = 30
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var centerCoordinate: CLLocationCoordinate2D?

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
    @State private var showingPhotoManager = false
    @State private var showingCloseConfirm = false
    @State private var outcome: Outcome?
    @FocusState private var focused: Field?

    private enum Field { case title, short, long }
    private enum Outcome { case submitted, savedDraft }

    /// The catalogue's own range. Every single-stop tour sits at 30 m and every
    /// walk stop at 40; the old 200 m ceiling was range nobody had ever used,
    /// and a 200 m circle runs off all four edges of this map.
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
        NavigationStack {
            Group {
                if let outcome {
                    outcomeView(outcome)
                } else {
                    wizard
                }
            }
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("")
            .inlineNavigationBarTitle()
            .toolbar { toolbarContent }
        }
        .sheet(isPresented: $showingPhotoManager) {
            if let draft { PhotoManagerView(tour: draft.tour) }
        }
        .confirmationDialog("Discard this tour?", isPresented: $showingCloseConfirm,
                            titleVisibility: .visible) {
            Button("Discard", role: .destructive) { dismiss() }
            Button("Keep editing", role: .cancel) {}
        } message: {
            Text("Nothing has been saved yet. Save progress keeps it as a draft.")
        }
        .onAppear(perform: centerOnUser)
    }

    // MARK: - Chrome

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if outcome == nil {
            ToolbarItem(placement: .principal) {
                Text(step.label)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
            }
            ToolbarItem(placement: .cancellationAction) {
                if step == .location {
                    Button("Close") { closeTapped() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.primaryText)
                } else {
                    Button { goBack() } label: {
                        Image(systemName: "chevron.left")
                    }
                    .tint(AtlasColors.primaryText)
                    .accessibilityLabel("Back")
                }
            }
        }
    }

    private var wizard: some View {
        VStack(spacing: 0) {
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
    }

    /// Five segments, one per step, filled up to where you are.
    private var progressBar: some View {
        HStack(spacing: 5) {
            ForEach(Step.allCases, id: \.rawValue) { s in
                Capsule()
                    .fill(s.rawValue <= step.rawValue
                          ? AtlasColors.mapPin
                          : AtlasColors.tertiaryText.opacity(0.3))
                    .frame(height: 3)
            }
        }
        .padding(.horizontal, AtlasSpacing.lg)
        .padding(.bottom, AtlasSpacing.sm)
        .accessibilityElement()
        .accessibilityLabel("Step \(step.rawValue + 1) of \(Step.allCases.count)")
    }

    /// Save progress and the primary action, side by side, where neither can
    /// scroll out of reach. Sits above the mini-player + tab bar, which live in
    /// a separate, higher window.
    private var footer: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            if let blockingHint {
                Text(blockingHint)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
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
        .padding(.bottom, AtlasSpacing.sm)
        .background(AtlasColors.secondaryBackground)
        .overlay(alignment: .top) {
            Rectangle().fill(AtlasColors.divider).frame(height: 0.5)
        }
        .padding(.bottom, AtlasBottomModule.height())
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
            centerCoordinate = context.region.center
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
            let all = ([draft.tour.heroImageURL] + (draft.tour.additionalImageURLs ?? []))
                .filter { !$0.isEmpty }
            VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                fieldLabel("PHOTOS — UP TO \(PhotoManagerView.maxPhotos), THE FIRST IS THE COVER")

                if !all.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AtlasSpacing.sm) {
                            ForEach(Array(all.enumerated()), id: \.offset) { idx, url in
                                HeroImageView(imageName: url, height: 84,
                                              cornerRadius: 0, category: draft.tour.primaryCategory)
                                    .frame(width: 112)
                                    .overlay(alignment: .bottomLeading) {
                                        if idx == 0 {
                                            Text("COVER")
                                                .font(.system(size: 9, weight: .semibold))
                                                .foregroundStyle(AtlasColors.background)
                                                .padding(.horizontal, 5).padding(.vertical, 2)
                                                .background(AtlasColors.mapPin)
                                                .padding(AtlasSpacing.xs)
                                        }
                                    }
                            }
                        }
                    }
                }

                Button { showingPhotoManager = true } label: {
                    wideButton(all.isEmpty ? "Add photos" : "Manage photos",
                               systemImage: all.isEmpty ? "photo.badge.plus" : "square.grid.2x2",
                               primary: all.isEmpty)
                }
                .buttonStyle(.plain)

                Text(all.isEmpty
                     ? "Photos are framed to 1200×900. The first is the cover."
                     : "\(all.count) of \(PhotoManagerView.maxPhotos) · drag to reorder, the first is the cover.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
        } else {
            missingDraftNotice
        }
    }

    @ViewBuilder
    private var audioStep: some View {
        if let draft {
            VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                TourAudioSection(tour: draft.tour, showsHeader: false)

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
                fieldLabel("REVIEW")
                VStack(spacing: 0) {
                    summaryRow("TITLE", tour.title, isLast: false)
                    summaryRow("WHERE",
                               String(format: "%.4f, %.4f", tour.centroidLatitude, tour.centroidLongitude),
                               isLast: false)
                    summaryRow("GEOFENCE", "\(Int(radius)) m", isLast: false)
                    summaryRow("TAGS", tour.tags.isEmpty ? "None" : tour.tags.joined(separator: " · "),
                               isLast: false)
                    summaryRow("PHOTOS", photoCount == 0 ? "None" : "\(photoCount)", isLast: false)
                    summaryRow("AUDIO",
                               tour.totalDurationSeconds > 0
                                 ? AtlasFormatters.duration(seconds: tour.totalDurationSeconds)
                                 : "None",
                               isLast: true)
                }
                .background(AtlasColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))

                Text("We review every tour before it goes live. Most are looked at within a day.")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.tertiaryText)
            }
        } else {
            missingDraftNotice
        }
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
                .padding(.bottom, AtlasBottomModule.height())
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Gating

    /// The vocabulary requires at least one Place type and one Theme.
    private var hasRequiredTags: Bool {
        !selectedTags.isDisjoint(with: Set(Tag.tags(in: .placeType)))
            && !selectedTags.isDisjoint(with: Set(Tag.tags(in: .theme)))
    }
    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    /// Anything at all can be saved as a draft once there's a coordinate to
    /// hang it on — the title falls back to a placeholder.
    private var canPersist: Bool { centerCoordinate != nil }

    /// Whether the current step is finished enough to leave. Without this a
    /// maker can tap through five empty screens and arrive at a tour that
    /// cannot be submitted, which is worse than the form it replaced.
    private var canAdvance: Bool {
        switch step {
        case .location: return centerCoordinate != nil
        case .details:
            return !trimmedTitle.isEmpty
                && !shortDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && hasRequiredTags
        case .photos: return !(draft?.tour.heroImageURL.isEmpty ?? true)
        case .audio:  return (draft?.tour.totalDurationSeconds ?? 0) > 0
        case .review: return draft != nil
        }
    }

    /// Says what's missing rather than leaving a dimmed button unexplained.
    private var blockingHint: String? {
        guard !canAdvance else { return nil }
        switch step {
        case .location: return "Pan the map to put the pin where the tour begins."
        case .details:
            if trimmedTitle.isEmpty { return "A title is needed." }
            if shortDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "A short description is needed — it's the line on cards."
            }
            return "Pick at least one Place type and one Theme."
        case .photos: return "Add at least one photo. The first becomes the cover."
        case .audio:  return "Record or import the narration."
        case .review: return nil
        }
    }

    private var primaryLabel: String {
        step == .review ? "Submit for review" : "Next"
    }

    // MARK: - Actions

    private func closeTapped() {
        let typedSomething = !trimmedTitle.isEmpty
            || !shortDescription.isEmpty
            || !longDescription.isEmpty
            || !selectedTags.isEmpty
        if draftId == nil && typedSomething {
            showingCloseConfirm = true
        } else {
            dismiss()
        }
    }

    private func goBack() {
        focused = nil
        guard let previous = Step(rawValue: step.rawValue - 1) else { return }
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
        isPersisting = true
        Task {
            defer { isPersisting = false }
            do {
                try await persist()
                guard let next = Step(rawValue: step.rawValue + 1) else { return }
                withAnimation(.easeInOut(duration: 0.2)) { step = next }
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    private func saveProgress() {
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
        guard let draft else { return }
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
                radiusMeters: Int(radius)
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
                radiusMeters: Int(radius)
            )
        }

        if !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
           let id = draftId {
            try await makerTourService.setTranscript(tourId: id, text: transcript)
        }
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

    private func centerOnUser() {
        guard centerCoordinate == nil,
              let coord = locationManager.userLocation?.coordinate else { return }
        cameraPosition = .region(
            MKCoordinateRegion(center: coord, latitudinalMeters: 700, longitudinalMeters: 700)
        )
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

    private func wideButton(_ title: String, systemImage: String, primary: Bool) -> some View {
        HStack {
            Spacer()
            Label(title, systemImage: systemImage)
                .font(AtlasTypography.caption)
            Spacer()
        }
        .padding(.vertical, AtlasSpacing.md)
        .foregroundStyle(primary ? AtlasColors.background : AtlasColors.primaryText)
        .background(primary ? AtlasColors.mapPin : Color.clear)
        .overlay {
            if !primary {
                RoundedRectangle(cornerRadius: AtlasSpacing.sm)
                    .stroke(AtlasColors.secondaryText.opacity(0.4), lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
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
