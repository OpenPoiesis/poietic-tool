// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "poietic",
    platforms: [.macOS("15"), .custom("linux", versionString: "1")],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/swiftlang/swift-markdown.git", branch: "main"),
        .package(url: "https://github.com/openpoiesis/poietic-core", from: "0.9.0"),
        .package(url: "https://github.com/openpoiesis/poietic-flows", from: "0.9.0"),
        .package(url: "https://github.com/openpoiesis/poietic-diagram", from: "0.8.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "poietic",
            dependencies: [
                .product(name: "PoieticCore", package: "poietic-core"),
                .product(name: "PoieticFlows", package: "poietic-flows"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "RealModule", package: "swift-numerics"),
                .product(name: "Markdown", package: "swift-markdown"),
                .product(name: "Diagramming", package: "poietic-diagram"),
            ]
        ),
    ]
)
