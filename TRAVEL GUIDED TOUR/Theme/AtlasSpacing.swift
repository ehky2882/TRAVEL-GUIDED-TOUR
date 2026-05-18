import Foundation

enum AtlasSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let heroHeight: CGFloat = 320
    static let cardCornerRadius: CGFloat = 12
    static let chipCornerRadius: CGFloat = 20
    /// Approximation of the modern iPhone screen corner radius. Used
    /// for the home-page floating-island shape so the drawer + tab
    /// bar look like they "follow" the device's bottom curve.
    static let phoneScreenRadius: CGFloat = 48
}
