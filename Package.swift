// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "poietic",
    platforms: [.macOS("14"), .custom("linux", versionString: "1")],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/openpoiesis/PoieticCore", branch: "main"),
        .package(url: "https://github.com/openpoiesis/PoieticFlows", branch: "main"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "poietic",
            dependencies: [
                "PoieticCore",
                "PoieticFlows",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "RealModule", package: "swift-numerics"),
            ]
        ),
    ]
)
