// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "NVContainer",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "NVContainer",
            targets: ["NVContainer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "NVContainerMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "NVContainer",
            dependencies: ["NVContainerMacros"]
        ),
        .testTarget(
            name: "NVContainerTests",
            dependencies: [
                "NVContainerMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
