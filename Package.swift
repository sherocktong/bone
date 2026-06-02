// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "bone",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "bone", targets: ["bone"])
    ],
    targets: [
        .executableTarget(
            name: "bone",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
