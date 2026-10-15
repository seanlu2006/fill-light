import UIKit

/// Drives the display brightness while the light is showing and gives the
/// user's own brightness back when the app goes to the background.
@MainActor
final class ScreenBrightness {
    private var original: CGFloat?

    private var screen: UIScreen? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .screen
            ?? UIApplication.shared.connectedScenes.compactMap { ($0 as? UIWindowScene)?.screen }.first
    }

    func apply(_ value: Double) {
        guard let screen else { return }
        if original == nil { original = screen.brightness }
        screen.brightness = CGFloat(min(max(value, 0), 1))
    }

    func restore() {
        guard let original, let screen else { return }
        screen.brightness = original
        self.original = nil
    }
}
