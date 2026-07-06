import SwiftUI
import MapKit
import CoreLocation

/// Create a new single-stop tour (V2 Step 4, increment 2b). Metadata + a map
/// pin + geofence radius → a `draft` `tours` row (+ its `stops` row) under the
/// signed-in user's maker. Audio / photos / transcript / submit-for-review come
/// in later increments; a draft is saved and shows on the profile with a badge.
struct CreateTourView: View {
    @Environment(MakerProfileService.self) private var makerProfileService
    @Environment(MakerTourService.self) private var makerTourService
    @Environment(LocationManager.self) private var locationManager
    @Environment(\.dismiss) private var dismiss

    /// Called with the new draft's id after it's saved, so the presenter can
    /// open the tour editor (step 2 — audio / photos / transcript) instead of
    /// dropping the user back on the profile.
    var onCreated: ((UUID) -> Void)? = nil

    @State private var title = ""
    @State private var shortDescription = ""
    @State private var longDescription = ""
    @State private var selectedTags: Set<String> = []
    @State private var architect: String? = nil
    @State private var radius: Double = 30
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var centerCoordinate: CLLocationCoordinate2D?
    @State private var isSaving = false
    @State private var errorMessage: String?
    @FocusState private var focused: Field?

    private enum Field { case title, short, long }

    // Max lengths, with a live "N left" countdown by each field.
    private static let titleLimit = 60
    private static let shortLimit = 100
    private static let longLimit = 600

    private var trimmedTitle: String {
        title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    private var canSave: Bool {
        !isSaving
            && !trimmedTitle.isEmpty
            && !shortDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && centerCoordinate != nil
            && hasRequiredTags
    }

    /// The vocabulary requires ≥1 Place type and ≥1 Theme tag.
    private var hasRequiredTags: Bool {
        !selectedTags.isDisjoint(with: Set(Tag.tags(in: .placeType)))
            && !selectedTags.isDisjoint(with: Set(Tag.tags(in: .theme)))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AtlasSpacing.md) {
                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        fieldLabel("TITLE", remaining: Self.titleLimit - title.count)
                        TextField("e.g. The Old Custom House", text: $title)
                            .focused($focused, equals: .title)
                            .onChange(of: title) { _, new in
                                if new.count > Self.titleLimit { title = String(new.prefix(Self.titleLimit)) }
                            }
                            .fieldStyle()
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        fieldLabel("SHORT DESCRIPTION", remaining: Self.shortLimit - shortDescription.count)
                        TextField("One line shown on cards", text: $shortDescription)
                            .focused($focused, equals: .short)
                            .onChange(of: shortDescription) { _, new in
                                if new.count > Self.shortLimit { shortDescription = String(new.prefix(Self.shortLimit)) }
                            }
                            .fieldStyle()
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        fieldLabel("DESCRIPTION", remaining: Self.longLimit - longDescription.count)
                        TextField("What this tour is about", text: $longDescription, axis: .vertical)
                            .lineLimit(3...6)
                            .focused($focused, equals: .long)
                            .onChange(of: longDescription) { _, new in
                                if new.count > Self.longLimit { longDescription = String(new.prefix(Self.longLimit)) }
                            }
                            .fieldStyle()
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
                        fieldLabel("TAGS — HOW YOUR TOUR IS FOUND")
                        ControlledTagPicker(selectedTags: $selectedTags, architect: $architect)
                    }

                    VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                        fieldLabel("LOCATION — PAN TO PLACE THE PIN")
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

                    // Set the expectation that saving is step 1 of 2.
                    Text("Step 1 of 2. Next, you'll add audio, photos, and a transcript.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                        .padding(.top, AtlasSpacing.sm)

                    saveButton
                }
                .padding(AtlasSpacing.lg)
            }
            // Reserve space for the mini-player + tab bar (a separate, higher
            // window) so the save button clears it and stays tappable.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                Color.clear.frame(height: AtlasBottomModule.height())
            }
            .background(AtlasColors.secondaryBackground)
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("NEW TOUR")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.primaryText)
                }
            }
            .onAppear(perform: centerOnUser)
        }
    }

    // MARK: - Sections

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
            // Fixed center pin — the map center IS the chosen coordinate, so
            // panning the map moves the pin. Tip anchored at the true center.
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

    private var saveButton: some View {
        Button(action: save) {
            HStack {
                Spacer()
                if isSaving {
                    ProgressView().tint(AtlasColors.background)
                } else {
                    Text("Save draft & continue").font(AtlasTypography.caption)
                }
                Spacer()
            }
            .padding(.vertical, AtlasSpacing.md)
            .background(canSave ? AtlasColors.mapPin : AtlasColors.mapPin.opacity(0.4))
            .foregroundStyle(AtlasColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
        }
        .disabled(!canSave)
    }

    /// A field label, optionally with a right-aligned "N left" countdown that
    /// turns red as the limit approaches.
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

    private func centerOnUser() {
        guard let coord = locationManager.userLocation?.coordinate else { return }
        cameraPosition = .region(
            MKCoordinateRegion(
                center: coord,
                latitudinalMeters: 700,
                longitudinalMeters: 700
            )
        )
        centerCoordinate = coord
    }

    /// Final tag list, in canonical order, with the architect + its
    /// implied "Designed by a Master" appended when one is chosen.
    private var finalTags: [String] {
        var tags = Tag.ordered(selectedTags)
        if let architect {
            tags.append("Designed by a Master")
            tags.append(architect)
        }
        return tags
    }

    private func save() {
        guard let coordinate = centerCoordinate else { return }
        focused = nil
        errorMessage = nil
        isSaving = true
        Task {
            defer { isSaving = false }
            do {
                // Ensure the user has a maker row (creates one with a default
                // name if this is their very first authoring action).
                let makerId = try await makerProfileService.ensureMaker()
                let tags = finalTags
                let tourId = try await makerTourService.createDraftTour(
                    makerId: makerId,
                    title: title,
                    shortDescription: shortDescription,
                    longDescription: longDescription,
                    category: Tag.deriveCategory(from: tags),
                    tags: tags,
                    coordinate: coordinate,
                    radiusMeters: Int(radius)
                )
                // Hand the new draft to the presenter, which opens the editor
                // (step 2) as this sheet dismisses.
                onCreated?(tourId)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private extension View {
    /// Shared field chrome — matches SignInView / ProfileEditorView.
    func fieldStyle() -> some View {
        self
            .font(AtlasTypography.caption)
            .padding(AtlasSpacing.md)
            .background(AtlasColors.background)
            .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
    }
}
