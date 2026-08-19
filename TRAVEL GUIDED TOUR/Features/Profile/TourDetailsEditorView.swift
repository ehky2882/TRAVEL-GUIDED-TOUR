import SwiftUI
import MapKit
import CoreLocation

/// Edit a tour's metadata after it exists — title, both descriptions, tags, the
/// map pin and the geofence radius.
///
/// **Why this screen exists.** Everything here was previously set once on the
/// create form and then frozen for the life of the tour: a typo in a title could
/// only be fixed by deleting the tour, which destroyed its audio and photos with
/// it. That was the single biggest hole in the authoring flow.
///
/// Deliberately mirrors `CreateTourWizardView`'s field order, limits and map
/// interaction, so the two read as the same form in two moments rather than two
/// different forms. **If you change a limit or a field here, change it there
/// too** — they are separate views because the surrounding chrome differs
/// (sheet-with-Save vs step-1-of-2), not because the content should diverge.
struct TourDetailsEditorView: View {
    let tour: Tour
    let status: TourStatus

    @Environment(MakerTourService.self) private var makerTourService
    @Environment(\.dismiss) private var dismiss

    @State private var title: String
    @State private var shortDescription: String
    @State private var longDescription: String
    @State private var selectedTags: Set<String>
    @State private var architect: String?
    @State private var radius: Double
    @State private var cameraPosition: MapCameraPosition
    @State private var centerCoordinate: CLLocationCoordinate2D
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showingDiscardConfirm = false
    @FocusState private var focused: Field?

    private enum Field { case title, short, long }

    // Same limits as CreateTourWizardView — keep the two in step.
    private static let titleLimit = 60
    private static let shortLimit = 100
    private static let longLimit = 600

    /// The originals, so "did anything change?" is a comparison rather than a
    /// flag that every field has to remember to set.
    private let originalTitle: String
    private let originalShort: String
    private let originalLong: String
    private let originalTags: Set<String>
    private let originalArchitect: String?
    /// Pin and radius are `@State` rather than `let` because they are corrected
    /// asynchronously once the real stop row loads (see the `.task` below) — the
    /// baseline has to move with them, or the form would open reading "changed"
    /// the instant it finished loading and offer to save an edit nobody made.
    @State private var originalRadius: Double
    @State private var originalCoordinate: CLLocationCoordinate2D

    init(tour: Tour, status: TourStatus) {
        self.tour = tour
        self.status = status

        let stop = tour.stops.first
        let coordinate = CLLocationCoordinate2D(
            latitude: stop?.latitude ?? tour.centroidLatitude,
            longitude: stop?.longitude ?? tour.centroidLongitude
        )
        let radiusValue = Double(stop?.triggerRadiusMeters ?? 30)

        // Split the stored tag list back into what the picker edits. The
        // architect is stored as a plain tag alongside its implied "Designed by
        // a Master"; both are re-derived on save, so both are stripped here —
        // otherwise saving twice would accumulate duplicates.
        let stored = Set(tour.tags)
        let architectTag = tour.tags.first { Tag.facet(for: $0) == .architect }
        var editable = stored
        editable.remove("Designed by a Master")
        if let architectTag { editable.remove(architectTag) }

        _title = State(initialValue: tour.title)
        _shortDescription = State(initialValue: tour.shortDescription)
        _longDescription = State(initialValue: tour.longDescription)
        _selectedTags = State(initialValue: editable)
        _architect = State(initialValue: architectTag)
        _radius = State(initialValue: radiusValue)
        _centerCoordinate = State(initialValue: coordinate)
        _cameraPosition = State(initialValue: .region(
            MKCoordinateRegion(center: coordinate,
                               latitudinalMeters: 700,
                               longitudinalMeters: 700)
        ))

        originalTitle = tour.title
        originalShort = tour.shortDescription
        originalLong = tour.longDescription
        originalTags = editable
        originalArchitect = architectTag
        _originalRadius = State(initialValue: radiusValue)
        _originalCoordinate = State(initialValue: coordinate)
    }

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The vocabulary requires ≥1 Place type and ≥1 Theme — same rule the create
    /// form and `validate-tours.swift` enforce.
    private var hasRequiredTags: Bool {
        !selectedTags.isDisjoint(with: Set(Tag.tags(in: .placeType)))
            && !selectedTags.isDisjoint(with: Set(Tag.tags(in: .theme)))
    }

    private var hasChanges: Bool {
        title != originalTitle
            || shortDescription != originalShort
            || longDescription != originalLong
            || selectedTags != originalTags
            || architect != originalArchitect
            || radius != originalRadius
            || abs(centerCoordinate.latitude - originalCoordinate.latitude) > 0.0000001
            || abs(centerCoordinate.longitude - originalCoordinate.longitude) > 0.0000001
    }

    private var canSave: Bool {
        !isSaving
            && hasChanges
            && !trimmedTitle.isEmpty
            && !shortDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && hasRequiredTags
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                    if status == .published {
                        publishedNotice
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        fieldLabel("TITLE", remaining: Self.titleLimit - title.count)
                        TextField("e.g. The Old Custom House", text: $title)
                            .focused($focused, equals: .title)
                            .onChange(of: title) { _, new in
                                if new.count > Self.titleLimit { title = String(new.prefix(Self.titleLimit)) }
                            }
                            .detailsFieldStyle()
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        fieldLabel("SHORT DESCRIPTION", remaining: Self.shortLimit - shortDescription.count)
                        TextField("One line shown on cards", text: $shortDescription)
                            .focused($focused, equals: .short)
                            .onChange(of: shortDescription) { _, new in
                                if new.count > Self.shortLimit { shortDescription = String(new.prefix(Self.shortLimit)) }
                            }
                            .detailsFieldStyle()
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        fieldLabel("DESCRIPTION", remaining: Self.longLimit - longDescription.count)
                        TextField("What this tour is about", text: $longDescription, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($focused, equals: .long)
                            .onChange(of: longDescription) { _, new in
                                if new.count > Self.longLimit { longDescription = String(new.prefix(Self.longLimit)) }
                            }
                            .detailsFieldStyle()
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                        fieldLabel("TAGS — HOW YOUR TOUR IS FOUND")
                        ControlledTagPicker(selectedTags: $selectedTags, architect: $architect)
                        if !hasRequiredTags {
                            Text("Pick at least one Place type and one Theme.")
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.mapPin)
                        }
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        fieldLabel("LOCATION — PAN TO MOVE THE PIN")
                        mapSection
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        fieldLabel("TRIGGER RADIUS — \(Int(radius)) m")
                        Slider(value: $radius, in: 20...200, step: 5)
                            .tint(AtlasColors.mapPin)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(AtlasTypography.caption)
                            .foregroundStyle(AtlasColors.mapPin)
                    }
                }
                .padding(AtlasSpacing.lg)
            }
            // The mini-player + tab bar live in a higher window and paint over
            // this sheet, so reserve their height or the last field is unusable.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AtlasBottomModule.height())
            }
            .background(AtlasColors.secondaryBackground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("DETAILS")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { attemptDismiss() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving…" : "Save") { save() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.mapPin)
                        .disabled(!canSave)
                }
            }
            // Load the stop's real pin + radius. The feed's `Tour` is built with
            // `stops: []`, so the init could only fall back to the centroid and
            // a 30 m default — saving that back would silently reset the
            // geofence of every tour anyone edited. Both the live values and
            // their baseline move together, so this does not read as an edit.
            .task(id: tour.id) {
                guard let stop = await makerTourService.stopLocation(tourId: tour.id) else { return }
                // Don't clobber the user if they've already started dragging.
                guard !hasChanges else { return }
                radius = Double(stop.radiusMeters)
                originalRadius = Double(stop.radiusMeters)
                centerCoordinate = stop.coordinate
                originalCoordinate = stop.coordinate
                cameraPosition = .region(
                    MKCoordinateRegion(center: stop.coordinate,
                                       latitudinalMeters: 700,
                                       longitudinalMeters: 700)
                )
            }
            // Block the swipe-to-dismiss gesture too, or the confirmation is
            // trivially bypassable and edits vanish silently.
            .interactiveDismissDisabled(hasChanges)
            .confirmationDialog("Discard changes?",
                                isPresented: $showingDiscardConfirm,
                                titleVisibility: .visible) {
                Button("Discard", role: .destructive) { dismiss() }
                Button("Keep editing", role: .cancel) {}
            }
        }
    }

    // MARK: - Sections

    /// Editing a live tour is allowed, but it re-enters moderation — say so
    /// before the maker taps Save, not after.
    private var publishedNotice: some View {
        HStack(alignment: .top, spacing: AtlasSpacing.sm) {
            Image(systemName: "info.circle")
                .foregroundStyle(AtlasColors.mapPin)
            Text("This tour is live. Saving changes sends it back for review before the new version appears.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)
        }
        .padding(AtlasSpacing.md)
        .background(AtlasColors.background)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }

    private var mapSection: some View {
        Map(position: $cameraPosition) {
            MapCircle(center: centerCoordinate, radius: radius)
                .foregroundStyle(AtlasColors.mapPin.opacity(0.18))
                .stroke(AtlasColors.mapPin, lineWidth: 2)
        }
        .frame(height: 280)
        .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
        .overlay {
            // Fixed centre pin — the map centre IS the coordinate, so panning
            // the map moves the pin. Tip anchored at the true centre.
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

    // MARK: - Actions

    private func attemptDismiss() {
        if hasChanges { showingDiscardConfirm = true } else { dismiss() }
    }

    /// Final tag list, in canonical order, with the architect and its implied
    /// "Designed by a Master" re-appended — matching `CreateTourWizardView.finalTags`.
    private var finalTags: [String] {
        var tags = Tag.ordered(selectedTags)
        if let architect {
            tags.append("Designed by a Master")
            tags.append(architect)
        }
        return tags
    }

    private func save() {
        focused = nil
        errorMessage = nil
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                let tags = finalTags
                try await makerTourService.updateDetails(
                    tour: tour,
                    status: status,
                    title: title,
                    shortDescription: shortDescription,
                    longDescription: longDescription,
                    category: Tag.deriveCategory(from: tags),
                    tags: tags,
                    coordinate: centerCoordinate,
                    radiusMeters: Int(radius)
                )
                dismiss()
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }
}

private extension View {
    /// Shared field chrome — matches `CreateTourWizardView` / `ProfileEditorView`.
    /// Named distinctly from the wizard's file-private `wizardFieldStyle()` so
    /// the two can't be confused for one shared helper when someone changes one.
    func detailsFieldStyle() -> some View {
        self
            .font(AtlasTypography.caption)
            .padding(AtlasSpacing.md)
            .background(AtlasColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }
}
