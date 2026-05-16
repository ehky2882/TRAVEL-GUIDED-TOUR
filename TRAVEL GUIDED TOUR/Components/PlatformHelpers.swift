import SwiftUI

extension View {
    @ViewBuilder
    func inlineNavigationBarTitle() -> some View {
        #if os(iOS) || os(visionOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// Cross-platform shim for `textInputAutocapitalization` — the
    /// modifier exists on iOS / iPadOS / visionOS but not macOS, where
    /// auto-capitalization isn't a TextField concern.
    @ViewBuilder
    func atlasNoAutocapitalization() -> some View {
        #if os(iOS) || os(visionOS)
        self.textInputAutocapitalization(.never)
        #else
        self
        #endif
    }
}

extension ToolbarItemPlacement {
    static var atlasTrailing: ToolbarItemPlacement {
        #if os(iOS) || os(visionOS)
        .topBarTrailing
        #else
        .automatic
        #endif
    }
}
