import Foundation
import FillLightCore

/// User preferences, persisted in UserDefaults.
final class Settings {
    private let defaults = UserDefaults.standard
    var onChange: (() -> Void)?

    private enum Key {
        static let brightness = "brightness"
        static let kelvin = "kelvin"
        static let fadeNearPointer = "fadeNearPointer"
        static let allDisplays = "allDisplays"
    }

    init() {
        defaults.register(defaults: [
            Key.brightness: 0.5,
            Key.kelvin: LightMath.defaultKelvin,
            Key.fadeNearPointer: true,
            Key.allDisplays: false,
        ])
    }

    /// 0...1, maps to ring thickness.
    var brightness: Double {
        get { defaults.double(forKey: Key.brightness) }
        set { defaults.set(min(max(newValue, 0), 1), forKey: Key.brightness); onChange?() }
    }

    var kelvin: Double {
        get { defaults.double(forKey: Key.kelvin) }
        set {
            let r = LightMath.kelvinRange
            defaults.set(min(max(newValue, r.lowerBound), r.upperBound), forKey: Key.kelvin)
            onChange?()
        }
    }

    /// Clear a soft hole around the mouse pointer so menus and buttons under the ring stay usable.
    var fadeNearPointer: Bool {
        get { defaults.bool(forKey: Key.fadeNearPointer) }
        set { defaults.set(newValue, forKey: Key.fadeNearPointer); onChange?() }
    }

    /// Light every display instead of only the one with the camera.
    var allDisplays: Bool {
        get { defaults.bool(forKey: Key.allDisplays) }
        set { defaults.set(newValue, forKey: Key.allDisplays); onChange?() }
    }
}
