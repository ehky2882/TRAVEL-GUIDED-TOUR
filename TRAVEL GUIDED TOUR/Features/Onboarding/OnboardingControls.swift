//
//  OnboardingControls.swift
//  TRAVEL GUIDED TOUR
//
//  The three shapes a question takes, and the answers they offer.
//
//  🔴 The form follows the content, never decoration (owner, 2026-09-22):
//  six or fewer options, each worth a line of explanation → stacked rows;
//  many options, each a word or two → a chip cloud. Under that rule screen 12
//  is not an exception, it is simply the only question with twenty-four
//  answers.
//

import SwiftUI

// MARK: - Stacked rows

/// One multi-select row: icon, label, tick.
struct OnboardingOptionRow: View {
    let label: String
    let symbol: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(AtlasColors.brass)
                    .frame(width: 26)
                Text(label)
                    .font(AtlasTypography.caption)
                    .fontWeight(isOn ? .bold : .regular)
                    .foregroundStyle(AtlasColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    Circle()
                        .strokeBorder(isOn ? AtlasColors.brass
                                           : AtlasColors.primaryText.opacity(0.24),
                                      lineWidth: 1.5)
                        .background(Circle().fill(isOn ? AtlasColors.brass : .clear))
                        .frame(width: 20, height: 20)
                    if isOn {
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .heavy))
                            .foregroundStyle(Color.white)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(minHeight: 46)
            .background(
                RoundedRectangle(cornerRadius: 13)
                    .fill(isOn ? AtlasColors.brass.opacity(0.10) : AtlasColors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(isOn ? AtlasColors.brass : AtlasColors.primaryText.opacity(0.14),
                            lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected, .isButton] : .isButton)
    }
}

/// One answer on a stacked question. A struct rather than a tuple because
/// `ForEach(_:id:)` and `map(\.label)` need a key path, and Swift has none
/// for a tuple's labels.
struct OnboardingOption: Identifiable {
    let label: String
    let symbol: String
    var id: String { label }
}

/// A stacked question: title, "pick as many as you like", then the rows.
struct OnboardingRowQuestion: View {
    let title: Text
    let options: [OnboardingOption]
    @Binding var selection: Set<String>

    var body: some View {
        VStack(spacing: 0) {
            OnboardingLine(title)
            OnboardingLine("Pick as many as you like")
                .padding(.top, OnboardingType.Gap.tight)
            VStack(spacing: 7) {
                ForEach(options) { option in
                    OnboardingOptionRow(
                        label: option.label,
                        symbol: option.symbol,
                        isOn: selection.contains(option.label)
                    ) {
                        toggle(option.label)
                    }
                }
            }
            .padding(.top, OnboardingType.Gap.step)
        }
    }

    private func toggle(_ label: String) {
        if selection.contains(label) { selection.remove(label) } else { selection.insert(label) }
    }
}

// MARK: - Chips

/// One interest chip. Brass when chosen — there is no second colour.
struct OnboardingChip: View {
    let label: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(AtlasTypography.caption)
                .fontWeight(isOn ? .bold : .regular)
                .foregroundStyle(isOn ? Color.white : AtlasColors.primaryText)
                .padding(.horizontal, 12)
                .frame(height: 31)
                .background(Capsule().fill(isOn ? AtlasColors.brass : AtlasColors.secondaryBackground))
                .overlay(
                    Capsule().stroke(isOn ? AtlasColors.brass
                                          : AtlasColors.primaryText.opacity(0.16),
                                     lineWidth: 1.5)
                )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected, .isButton] : .isButton)
    }
}

/// A wrapping cloud of chips. `Layout` rather than a `LazyVGrid` because the
/// chips are different widths and a grid would align them into columns.
struct ChipFlowLayout: Layout {
    var spacing: CGFloat = 7

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, in: width)
        let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: width == .infinity ? rows.map(\.width).max() ?? 0 : width,
                      height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews: subviews, in: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y),
                                      anchor: .topLeading,
                                      proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var indices: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(subviews: Subviews, in width: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + spacing + size.width
            if needed > width, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width = needed
                current.height = max(current.height, size.height)
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

// MARK: - Two big cards

/// The browsing-or-creating pair on screen 18.
struct OnboardingCardChoice: View {
    let title: String
    let subtitle: String
    let symbol: String
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 11) {
                    Image(systemName: symbol)
                        .font(.system(size: 18))
                        .foregroundStyle(AtlasColors.brass)
                    Text(title)
                        .font(AtlasTypography.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AtlasColors.primaryText)
                }
                Text(subtitle)
                    .font(AtlasTypography.caption)
                    .foregroundStyle(AtlasColors.primaryText)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(17)
            .background(
                RoundedRectangle(cornerRadius: 15)
                    .fill(isOn ? AtlasColors.brass.opacity(0.10) : AtlasColors.secondaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isOn ? AtlasColors.brass : AtlasColors.primaryText.opacity(0.14),
                            lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isOn ? [.isSelected, .isButton] : .isButton)
    }
}
