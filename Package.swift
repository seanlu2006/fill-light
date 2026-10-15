// swift-tools-version:5.9
import PackageDescription

// Builds the macOS menu bar app with plain `swift build` (no Xcode needed).
// The iOS/iPadOS app lives in iOS/ and is built with Xcode.
let package = Package(
    name: "FillLight",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "FillLight", targets: ["FillLight"]),
    ],
    targets: [
        // Shared between macOS and iOS (the iOS project compiles this folder directly).
        .target(name: "FillLightCore", path: "Shared"),
        .executableTarget(name: "FillLight", dependencies: ["FillLightCore"], path: "Mac"),
        // `swift run core-check` — sanity checks for the shared math.
        .executableTarget(name: "core-check", dependencies: ["FillLightCore"], path: "Tools/CoreCheck"),
    ]
)
