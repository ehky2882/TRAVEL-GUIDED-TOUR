import SwiftUI

struct CategoryFilterBar: View {
    let categories: [PlaceCategory]
    @Binding var selected: PlaceCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AtlasSpacing.sm) {
                TagChip(text: "All", isSelected: selected == nil)
                    .onTapGesture { selected = nil }

                ForEach(categories) { category in
                    TagChip(text: category.displayName, isSelected: selected == category)
                        .onTapGesture { selected = category }
                }
            }
            .padding(.horizontal, AtlasSpacing.lg)
        }
    }
}
