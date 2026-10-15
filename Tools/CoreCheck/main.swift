import Foundation
import FillLightCore

// Plain assertions instead of XCTest so this runs with Command Line Tools only.
var failures = 0
func check(_ ok: Bool, _ message: String) {
    if !ok {
        failures += 1
        print("FAIL: \(message)")
    }
}

let daylight = LightMath.color(kelvin: 6500)
check(daylight.red > 0.97 && daylight.green > 0.97 && daylight.blue > 0.95, "6500K should be near white, got \(daylight)")

let warm = LightMath.color(kelvin: 2700)
check(warm.red == 1, "2700K red should be full, got \(warm.red)")
check(warm.blue < warm.green && warm.green < warm.red, "2700K should be orange-ish, got \(warm)")

var previousBlue = -1.0
for k in stride(from: 2700.0, through: 6500, by: 100) {
    let c = LightMath.color(kelvin: k)
    for v in [c.red, c.green, c.blue] {
        check((0...1).contains(v), "component out of range at \(k)K")
    }
    check(c.blue >= previousBlue, "blue should rise with temperature at \(k)K")
    previousBlue = c.blue
}

check(LightMath.ringThickness(brightness: 0, shortSide: 1000) == 30, "min thickness")
check(LightMath.ringThickness(brightness: 1, shortSide: 1000) == 250, "max thickness")
check(LightMath.ringThickness(brightness: 5, shortSide: 1000) == 250, "brightness is clamped")

check(LightColor(hex: "#FF8000") == LightColor(red: 1, green: 128.0 / 255, blue: 0), "hex parses")
check(LightColor(hex: "ff8000")?.hex == "#FF8000", "hex without # parses, output is uppercase with #")
check(LightColor(hex: "#12345") == nil, "short hex is rejected")
check(LightColor(hex: "#GG0000") == nil, "non-hex digits are rejected")
let roundTrip = LightColor(red: 0.2, green: 0.4, blue: 0.6)
check(LightColor(hex: roundTrip.hex)?.hex == roundTrip.hex, "hex round-trips")
check(LightColor(red: 2, green: -1, blue: 0.5).red == 1, "components are clamped")

if failures == 0 {
    print("core-check: all checks passed")
} else {
    print("core-check: \(failures) failure(s)")
    exit(1)
}
