import Foundation

/// An sRGB color with components in 0...1.
public struct LightColor: Equatable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
    }

    /// Parses "#RRGGBB" or "RRGGBB". Used to save custom colors in UserDefaults.
    public init?(hex: String) {
        var digits = hex.trimmingCharacters(in: .whitespaces)
        if digits.hasPrefix("#") { digits.removeFirst() }
        guard digits.count == 6, let value = UInt32(digits, radix: 16) else { return nil }
        self.init(red: Double((value >> 16) & 0xFF) / 255,
                  green: Double((value >> 8) & 0xFF) / 255,
                  blue: Double(value & 0xFF) / 255)
    }

    public var hex: String {
        func byte(_ v: Double) -> Int { Int((v * 255).rounded()) }
        return String(format: "#%02X%02X%02X", byte(red), byte(green), byte(blue))
    }
}

public enum LightMath {
    /// The warmth slider runs from candle-ish warm to daylight.
    public static let kelvinRange: ClosedRange<Double> = 2700...6500
    public static let defaultKelvin: Double = 5000
    /// A soft pink, the first color shown when someone opens the custom color picker.
    public static let defaultCustomColor = LightColor(hex: "#FFB3C7")!

    /// Approximate color of a black-body light source at `kelvin`.
    /// Tanner Helland's curve fit; good enough for a screen light.
    public static func color(kelvin: Double) -> LightColor {
        let t = min(max(kelvin, 1000), 40000) / 100

        let red: Double = t <= 66
            ? 255
            : 329.698727446 * pow(t - 60, -0.1332047592)
        let green: Double = t <= 66
            ? 99.4708025861 * log(t) - 161.1195681661
            : 288.1221695283 * pow(t - 60, -0.0755148492)
        let blue: Double
        if t >= 66 {
            blue = 255
        } else if t <= 19 {
            blue = 0
        } else {
            blue = 138.5177312231 * log(t - 10) - 305.0447927307
        }

        func unit(_ v: Double) -> Double { min(max(v, 0), 255) / 255 }
        return LightColor(red: unit(red), green: unit(green), blue: unit(blue))
    }

    /// Ring thickness in points for a brightness in 0...1.
    /// Wider ring = more light, like Apple's Edge Light.
    public static func ringThickness(brightness: Double, shortSide: Double) -> Double {
        let b = min(max(brightness, 0), 1)
        return shortSide * (0.03 + 0.22 * b)
    }
}
