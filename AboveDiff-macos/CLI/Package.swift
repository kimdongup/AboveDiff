// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AboveDiffCLI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "abovediff",
            targets: ["abovediff"]
        )
    ],
    dependencies: [
        .package(
            name: "AboveDiff",
            path: ".."
        )
    ],
    targets: [
        .executableTarget(
            name: "abovediff",
            dependencies: [
                .product(
                    name: "AboveDiffCore",
                    package: "AboveDiff"
                )
            ],
            path: "Sources/abovediff"
        )
    ]
)
