// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Harmony",
    platforms: [
        .macOS(.v10_12),
        .iOS(.v10),
        .tvOS(.v10),
        .watchOS(.v3)
    ],
    products: [
        .library(
            name: "Harmony",
            targets: ["Harmony"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", .upToNextMinor(from: "0.13.3"))
    ],
    targets: [
        .target(
            name: "Harmony",
            dependencies: [
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "HarmonyTests",
            dependencies: ["Harmony"],
            path: "HarmonyTests"
        ),
    ]
)
