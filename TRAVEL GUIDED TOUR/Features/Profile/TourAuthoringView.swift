import SwiftUI
import PhotosUI
#if canImport(UIKit)
import UIKit
#endif

/// The authoring editor for one of the maker's own tours. Reached by tapping an
/// owned tour on the profile feed: details, audio, photos, transcript, submit.
///
/// New tours are made in `CreateTourWizardView`, which walks the same ground as
/// a five-step flow. The two share their step content — `TourAudioSection`,
/// `PhotoManagerView`, `TourDetailsEditorView` — deliberately, so a limit or a
/// failure path can only live in one file. A later increment folds this screen
/// into the wizard entirely, as its index for an existing tour.
struct TourAuthoringView: View {
    let tourId: UUID

    @Environment(MakerTourService.self) private var makerTourService
    @Environment(AtlasNavigationState.self) private var navState
    @Environment(\.dismiss) private var dismiss

    @State private var transcriptText = ""
    @State private var isSavingTranscript = false
    @State private var isSubmitting = false
    @State private var showingDeleteConfirm = false
    @State private var isDeleting = false
    @State private var showingDetailsEditor = false
    @State private var showingPhotoManager = false
    @State private var errorMessage: String?

    /// Live lookup so the view refreshes after an upload reloads `myTours`.
    private var makerTour: MakerTour? {
        makerTourService.myTours.first { $0.id == tourId }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AtlasSpacing.lg) {
                if let makerTour {
                    header(makerTour)
                    detailsSection(makerTour)
                    TourAudioSection(tour: makerTour.tour)
                    photosSection(makerTour.tour)
                    transcriptSection
                    submitSection(makerTour)
                    deleteSection(makerTour.tour)
                } else {
                    Text("This tour is no longer available.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.secondaryText)
                }
            }
            .padding(AtlasSpacing.lg)
        }
        .background(AtlasColors.secondaryBackground)
        .navigationTitle("")
        .inlineNavigationBarTitle()
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("EDIT TOUR")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Color.clear.frame(height: AtlasBottomModule.height())
        }
        .onAppear { navState.push() }
        .onDisappear { navState.pop() }
        .sheet(isPresented: $showingDetailsEditor) {
            if let makerTour {
                TourDetailsEditorView(tour: makerTour.tour, status: makerTour.status)
            }
        }
        .sheet(isPresented: $showingPhotoManager) {
            if let makerTour {
                PhotoManagerView(tour: makerTour.tour)
            }
        }
        .task(id: tourId) {
            transcriptText = await makerTourService.stopTranscript(tourId: tourId)
        }
        .confirmationDialog(
            "Delete this tour?",
            isPresented: $showingDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete tour", role: .destructive) {
                if let tour = makerTour?.tour { delete(tour) }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This can't be undone.")
        }
    }

    private func deleteSection(_ tour: Tour) -> some View {
        Button(role: .destructive) {
            showingDeleteConfirm = true
        } label: {
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
        .padding(.top, AtlasSpacing.md)
    }

    private func delete(_ tour: Tour) {
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

    /// The tour's metadata, as tappable rows that open the details editor.
    ///
    /// Before this existed, everything shown here was set once on the create
    /// form and then frozen — a typo in a title could only be fixed by deleting
    /// the tour, taking its audio and photos with it.
    private func detailsSection(_ makerTour: MakerTour) -> some View {
        let tour = makerTour.tour
        let tagSummary = tour.tags.isEmpty ? "None" : tour.tags.joined(separator: " · ")
        return VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            HStack {
                Text("DETAILS")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                Spacer()
                Text("Edit")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.mapPin)
            }

            Button { showingDetailsEditor = true } label: {
                VStack(spacing: 0) {
                    detailRow("TITLE", tour.title, isLast: false)
                    detailRow("SHORT DESCRIPTION",
                              tour.shortDescription.isEmpty ? "Not set" : tour.shortDescription,
                              isLast: false)
                    detailRow("TAGS", tagSummary, isLast: false, mono: true)
                    detailRow("LOCATION",
                              String(format: "%.4f, %.4f", tour.centroidLatitude, tour.centroidLongitude),
                              isLast: true, mono: true)
                }
                .background(AtlasColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit tour details")
            .accessibilityHint("Opens the editor for title, description, tags and location")
        }
    }

    private func detailRow(_ key: String, _ value: String, isLast: Bool, mono: Bool = false) -> some View {
        HStack(alignment: .center, spacing: AtlasSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(key)
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundStyle(AtlasColors.tertiaryText)
                Text(value)
                    .font(mono ? AtlasTypography.caption : AtlasTypography.body)
                    .foregroundStyle(AtlasColors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 13))
                .foregroundStyle(AtlasColors.tertiaryText)
        }
        .padding(.horizontal, AtlasSpacing.md)
        .padding(.vertical, 13)
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(AtlasColors.divider)
                    .frame(height: 0.5)
                    .padding(.leading, AtlasSpacing.md)
            }
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text("TRANSCRIPT")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            TextField("The words spoken in the audio", text: $transcriptText, axis: .vertical)
                .lineLimit(4...12)
                .font(AtlasTypography.caption)
                .padding(AtlasSpacing.md)
                .background(AtlasColors.background)
                .clipShape(RoundedRectangle(cornerRadius: AtlasSpacing.sm))

            Button { saveTranscript() } label: {
                audioButton(isSavingTranscript ? "Saving…" : "Save transcript",
                            systemImage: "checkmark", primary: false)
            }
            .disabled(isSavingTranscript)
        }
    }

    private func submitSection(_ makerTour: MakerTour) -> some View {
        let hasAudio = makerTour.tour.totalDurationSeconds > 0
        let hasHero = !makerTour.tour.heroImageURL.isEmpty
        let isDraft = makerTour.status == .draft
        let canSubmit = hasAudio && hasHero && isDraft && !isSubmitting
        return VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text("SUBMIT")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            if isDraft {
                Button { submit(makerTour.tour) } label: {
                    audioButton(isSubmitting ? "Submitting…" : "Submit for review",
                                systemImage: "paperplane.fill", primary: true)
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)

                if !(hasAudio && hasHero) {
                    Text("Add audio and at least one photo before submitting.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.tertiaryText)
                }
            } else {
                HStack(spacing: AtlasSpacing.sm) {
                    Image(systemName: "clock.badge.checkmark")
                        .foregroundStyle(AtlasColors.mapPin)
                    Text("Submitted — \(makerTour.status.label). We'll review it and publish it.")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
            }
        }
    }

    private func photosSection(_ tour: Tour) -> some View {
        let all = ([tour.heroImageURL] + (tour.additionalImageURLs ?? []))
            .filter { !$0.isEmpty }
        return VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text("PHOTOS")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.secondaryText)

            if !all.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AtlasSpacing.sm) {
                        ForEach(Array(all.enumerated()), id: \.offset) { idx, url in
                            HeroImageView(imageName: url, height: 84,
                                          cornerRadius: 0, category: tour.primaryCategory)
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
                audioButton(all.isEmpty ? "Add photos" : "Manage photos",
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
    }

    /// Styled audio-action button — a filled primary (record) or a bordered
    /// secondary (import).
    private func audioButton(_ title: String, systemImage: String, primary: Bool) -> some View {
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

    // MARK: - Sections

    private func header(_ makerTour: MakerTour) -> some View {
        VStack(alignment: .leading, spacing: AtlasSpacing.sm) {
            Text(makerTour.tour.title)
                .font(AtlasTypography.body)
                .textCase(.uppercase)
                .foregroundStyle(AtlasColors.primaryText)
            Text(makerTour.status.label.uppercased())
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(AtlasColors.background)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(makerTour.status.badgeColor)
                .clipShape(Capsule())
        }
    }

    /// Real byte progress, not a spinner. Narration is the largest thing this
    /// app uploads, and an indeterminate spinner can't distinguish "nearly
    /// there" from "stalled".

    /// A failed upload keeps the file and offers to try again, rather than
    /// dropping a recording the maker may not be able to make twice.


    private func saveTranscript() {
        errorMessage = nil
        isSavingTranscript = true
        Task {
            defer { isSavingTranscript = false }
            do {
                try await makerTourService.setTranscript(tourId: tourId, text: transcriptText)
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    private func submit(_ tour: Tour) {
        errorMessage = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await makerTourService.submitForReview(tour: tour, transcript: transcriptText)
            } catch {
                errorMessage = AuthoringErrorText.message(for: error)
            }
        }
    }

    // MARK: - Import

    // MARK: - Audio import

    /// Retry a failed upload from the original source.

    /// The upload itself, split out so `uploadAudio` and `retryUpload` share one
    /// path rather than drifting.

}

/// An audio upload that failed after the file was already in hand.
