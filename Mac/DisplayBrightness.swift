import CoreGraphics
import Darwin

/// Built-in display brightness, through Apple's private DisplayServices framework.
///
/// macOS has no public API for this. Many open-source utilities use these two
/// functions, but a future macOS could remove them, so everything here fails soft:
/// if the framework or a symbol is missing, `isAvailable` is false and the menu hides the option.
enum DisplayBrightness {
    private typealias GetFunction = @convention(c) (CGDirectDisplayID, UnsafeMutablePointer<Float>) -> Int32
    private typealias SetFunction = @convention(c) (CGDirectDisplayID, Float) -> Int32

    private static let framework = dlopen("/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices", RTLD_LAZY)
    private static let getBrightness = framework
        .flatMap { dlsym($0, "DisplayServicesGetBrightness") }
        .map { unsafeBitCast($0, to: GetFunction.self) }
    private static let setBrightness = framework
        .flatMap { dlsym($0, "DisplayServicesSetBrightness") }
        .map { unsafeBitCast($0, to: SetFunction.self) }

    static var isAvailable: Bool { getBrightness != nil && setBrightness != nil }

    /// 0...1, or nil if the display doesn't support it (external monitors usually don't).
    static func get(_ display: CGDirectDisplayID) -> Float? {
        guard let getBrightness else { return nil }
        var value: Float = 0
        return getBrightness(display, &value) == 0 ? value : nil
    }

    @discardableResult
    static func set(_ display: CGDirectDisplayID, to value: Float) -> Bool {
        guard let setBrightness else { return false }
        return setBrightness(display, min(max(value, 0), 1)) == 0
    }
}
