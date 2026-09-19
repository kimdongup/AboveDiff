// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AboveDiff",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AboveDiff", targets: ["AboveDiff"]),
        .library(name: "AboveDiffCore", targets: ["AboveDiffCore"]),
        .library(name: "AboveDiffLocalization", targets: ["AboveDiffLocalization"]),
        .library(name: "AboveDiffState", targets: ["AboveDiffState"]),
        .library(name: "AboveDiffViews", targets: ["AboveDiffViews"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AboveDiffCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        .target(
            name: "AboveDiffLocalization",
            dependencies: [],
            path: "Sources/Localization"
        ),
        .target(
            name: "AboveDiffState",
            dependencies: ["AboveDiffCore", "AboveDiffLocalization"],
            path: "Sources/State"
        ),
        .target(
            name: "AboveDiffViews",
            dependencies: ["AboveDiffCore", "AboveDiffLocalization", "AboveDiffState"],
            path: "Sources/Views"
        ),
        .executableTarget(
            name: "AboveDiff",
            dependencies: ["AboveDiffCore", "AboveDiffLocalization", "AboveDiffState", "AboveDiffViews"],
            path: "Sources/App"
        ),
        .testTarget(
            name: "AboveDiffTests",
            dependencies: ["AboveDiffCore", "AboveDiffLocalization", "AboveDiffState"],
            path: "Tests/AboveDiffTests"
        )
    ]
)
