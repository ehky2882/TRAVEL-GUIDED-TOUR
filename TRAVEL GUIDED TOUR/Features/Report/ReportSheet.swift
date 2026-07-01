import SwiftUI

/// The reasons a user can pick when reporting a tour or maker. Stored as the
/// `reason` text on the `reports` row.
enum ReportReason: String, CaseIterable, Identifiable {
    case inaccurate = "Inaccurate information"
    case offensive = "Offensive or inappropriate"
    case brokenMedia = "Broken audio or images"
    case spam = "Spam or misleading"
    case other = "Something else"

    var id: String { rawValue }
}

/// "Report a concern" sheet — presented from the ••• menu on a tour or a maker.
/// Pick a reason, optionally add detail, submit → writes a row to the Supabase
/// `reports` table (no email address ships in the app). Shows a thank-you state
/// on success.
struct ReportSheet: View {
    /// What's being reported. Tours are captured by `tour_id`; makers have no
    /// column on `reports`, so their id is carried into `details`.
    enum Target {
        case tour(Tour)
        case maker(Maker)

        var displayName: String {
            switch self {
            case .tour(let tour): return tour.title
            case .maker(let maker): return maker.displayName
            }
        }
        var kindLabel: String {
            switch self {
            case .tour: return "tour"
            case .maker: return "creator"
            }
        }
        var tourId: UUID? {
            if case .tour(let tour) = self { return tour.id }
            return nil
        }
        /// Prefix folded into `details` so the owner can trace the target.
        var contextPrefix: String {
            switch self {
            case .tour: return ""
            case .maker(let maker): return "[Creator report] \(maker.displayName) (id: \(maker.id.uuidString))\n\n"
            }
        }
    }

    let target: Target

    @Environment(AuthService.self) private var authService
    @Environment(\.dismiss) private var dismiss

    @State private var reason: ReportReason = .inaccurate
    @State private var details = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var submitted = false

    private let service = ReportsService()

    var body: some View {
        NavigationStack {
            Group {
                if submitted {
                    thankYouState
                } else {
                    form
                }
            }
            .background(AtlasColors.secondaryBackground)
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("REPORT A CONCERN")
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(submitted ? "Done" : "Cancel") { dismiss() }
                        .font(AtlasTypography.caption)
                        .tint(AtlasColors.primaryText)
                }
            }
        }
    }

    private var form: some View {
        List {
            Section {
                Text("Reporting \(target.kindLabel): \(target.displayName)")
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.secondaryText)
                    .listRowBackground(Color.clear)
            }

            Section(header: sectionHeader("What's the issue?")) {
                ForEach(ReportReason.allCases) { option in
                    Button {
                        reason = option
                    } label: {
                        HStack {
                            Text(option.rawValue)
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.primaryText)
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(AtlasTypography.caption)
                                .foregroundStyle(AtlasColors.mapPin)
                                .opacity(option == reason ? 1 : 0)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Section(header: sectionHeader("Anything to add? (optional)")) {
                TextField("Details", text: $details, axis: .vertical)
                    .font(AtlasTypography.caption)
                    .lineLimit(3...6)
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .font(AtlasTypography.caption)
                        .foregroundStyle(AtlasColors.mapPin)
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                Button(action: submit) {
                    HStack {
                        Spacer()
                        if isSubmitting {
                            ProgressView().tint(AtlasColors.background)
                        } else {
                            Text("Submit report").font(AtlasTypography.caption)
                        }
                        Spacer()
                    }
                    .padding(.vertical, AtlasSpacing.sm)
                }
                .listRowBackground(AtlasColors.mapPin)
                .foregroundStyle(AtlasColors.background)
                .disabled(isSubmitting)
            }
        }
        .scrollContentBackground(.hidden)
        .tint(AtlasColors.primaryText)
    }

    private var thankYouState: some View {
        VStack(spacing: AtlasSpacing.md) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 40))
                .foregroundStyle(AtlasColors.mapPin)
            Text("Thanks — we'll take a look.")
                .font(AtlasTypography.caption)
                .foregroundStyle(AtlasColors.primaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AtlasSpacing.lg)
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(AtlasTypography.caption)
            .foregroundStyle(AtlasColors.secondaryText)
            .textCase(.uppercase)
    }

    private func submit() {
        errorMessage = nil
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                try await service.submit(
                    tourId: target.tourId,
                    reason: reason.rawValue,
                    details: target.contextPrefix + details,
                    reporterId: authService.userId
                )
                withAnimation { submitted = true }
            } catch {
                errorMessage = "Couldn't send the report. Please try again."
            }
        }
    }
}
