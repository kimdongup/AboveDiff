// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "fxfile",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "fxfile", targets: ["fxfile"]),
        .library(name: "fxfileCore", targets: ["fxfileCore"]),
        .library(name: "fxfileLocalization", targets: ["fxfileLocalization"]),
        .library(name: "fxfileState", targets: ["fxfileState"]),
        .library(name: "fxfileViews", targets: ["fxfileViews"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "fxfileCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        .target(
            name: "fxfileLocalization",
            dependencies: [],
            path: "Sources/Localization"
        ),
        .target(
            name: "fxfileState",
            dependencies: ["fxfileCore", "fxfileLocalization"],
            path: "Sources/State"
        ),
        .target(
            name: "fxfileViews",
            dependencies: ["fxfileCore", "fxfileLocalization", "fxfileState"],
            path: "Sources/Views"
        ),
        .executableTarget(
            name: "fxfile",
            dependencies: ["fxfileCore", "fxfileLocalization", "fxfileState", "fxfileViews"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "fxfileTests",
            dependencies: ["fxfileCore", "fxfileLocalization", "fxfileState"],
            path: "Tests/fxfileTests"
        )
    ]
)
