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
