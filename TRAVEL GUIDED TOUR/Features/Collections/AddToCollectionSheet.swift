import SwiftUI

struct AddToCollectionSheet: View {
    let placeId: UUID
    @Environment(CollectionStore.self) private var collectionStore
    @Environment(\.dismiss) private var dismiss
    @State private var showNewCollection = false
    @State private var newCollectionName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(collectionStore.collections) { collection in
                    Button {
                        collectionStore.addPlace(placeId, to: collection.id)
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: AtlasSpacing.xs) {
                                Text(collection.name)
                                    .font(AtlasTypography.headline)
                                    .foregroundStyle(AtlasColors.primaryText)
                                Text("\(collection.placeIds.count) places")
                                    .font(AtlasTypography.caption)
                                    .foregroundStyle(AtlasColors.tertiaryText)
                            }
                            Spacer()
                            if collection.placeIds.contains(placeId) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(AtlasColors.accent)
                            }
                        }
                    }
                }

                Button {
                    showNewCollection = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(AtlasColors.accent)
                        Text("New Collection")
                            .font(AtlasTypography.headline)
                            .foregroundStyle(AtlasColors.accent)
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Add to Collection")
            .inlineNavigationBarTitle()
            .toolbar {
                ToolbarItem(placement: .atlasTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .alert("New Collection", isPresented: $showNewCollection) {
                TextField("Collection name", text: $newCollectionName)
                Button("Cancel", role: .cancel) { newCollectionName = "" }
                Button("Create") {
                    if !newCollectionName.trimmingCharacters(in: .whitespaces).isEmpty {
                        collectionStore.createCollection(name: newCollectionName)
                        collectionStore.addPlace(placeId, to: collectionStore.collections.last!.id)
                        newCollectionName = ""
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
}
