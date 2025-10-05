// swift-tools-version: 5.9

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "ContainerMacro",
    platforms: [.macOS(.v13)],
    products: [
        .library(
            name: "ContainerMacro",
            targets: ["ContainerMacro"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "ContainerMacroPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "ContainerMacro",
            dependencies: ["ContainerMacroPlugin"]
        ),
        .testTarget(
            name: "ContainerMacroTests",
            dependencies: [
                "ContainerMacroPlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
