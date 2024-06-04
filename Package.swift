// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

/// The package definition.
let package = Package(
    name: "VHDLKripkeStructureGenerator",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other
        // packages.
        .library(
            name: "VHDLKripkeStructureGenerator",
            targets: ["VHDLKripkeStructureGenerator"]
        ),
        .library(
            name: "VHDLKripkeStructureGeneratorProtocols", targets: ["VHDLKripkeStructureGeneratorProtocols"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.3.0"),
        .package(url: "https://github.com/mipalgu/VHDLMachines.git", from: "4.0.0"),
        .package(url: "https://github.com/mipalgu/VHDLParsing.git", from: "2.5.0"),
        .package(url: "https://github.com/CPSLabGU/SwiftUtils.git", from: "0.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package
        // depends on.
        .target(
            name: "VHDLKripkeStructureGenerator",
            dependencies: [
                .product(name: "VHDLMachines", package: "VHDLMachines"),
                .product(name: "VHDLParsing", package: "VHDLParsing"),
                .target(name: "VHDLKripkeStructureGeneratorProtocols"),
                .target(name: "Utilities"),
                .target(name: "KripkeStructureParser"),
                .product(name: "SwiftUtils", package: "SwiftUtils")
            ]
        ),
        .target(name: "VHDLKripkeStructureGeneratorProtocols", dependencies: ["VHDLParsing", "VHDLMachines"]),
        .target(
            name: "Utilities",
            dependencies: [
                .product(name: "VHDLMachines", package: "VHDLMachines"),
                .product(name: "VHDLParsing", package: "VHDLParsing"),
            ]
        ),
        .target(
            name: "KripkeStructureParser",
            dependencies: [
                .product(name: "VHDLMachines", package: "VHDLMachines"),
                .product(name: "VHDLParsing", package: "VHDLParsing"),
                .product(name: "StringHelpers", package: "VHDLParsing"),
                .target(name: "Utilities"),
                .product(name: "SwiftUtils", package: "SwiftUtils")
            ]
        ),
        .testTarget(
            name: "TestUtils",
            dependencies: [
                .product(name: "VHDLMachines", package: "VHDLMachines"),
                .product(name: "VHDLParsing", package: "VHDLParsing"),
                .product(name: "SwiftUtils", package: "SwiftUtils")
            ]
        ),
        .testTarget(
            name: "VHDLKripkeStructureGeneratorTests",
            dependencies: [
                .target(name: "VHDLKripkeStructureGenerator"),
                .product(name: "VHDLMachines", package: "VHDLMachines"),
                .product(name: "VHDLParsing", package: "VHDLParsing"),
                .target(name: "Utilities"),
                .target(name: "KripkeStructureParser"),
                .product(name: "SwiftUtils", package: "SwiftUtils"),
                .target(name: "TestUtils")
            ]
        ),
        .testTarget(
            name: "UtilitiesTests",
            dependencies: [
                .target(name: "Utilities"),
                .product(name: "VHDLMachines", package: "VHDLMachines"),
                .product(name: "VHDLParsing", package: "VHDLParsing"),
                .target(name: "TestUtils")
            ]
        ),
        .testTarget(
            name: "KripkeStructureParserTests",
            dependencies: [
                .target(name: "KripkeStructureParser"),
                .product(name: "VHDLMachines", package: "VHDLMachines"),
                .product(name: "VHDLParsing", package: "VHDLParsing"),
                .target(name: "Utilities"),
                .target(name: "TestUtils")
            ]
        )
    ]
)
