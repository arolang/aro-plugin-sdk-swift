// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "AROPluginSDK",
    platforms: [.macOS(.v12)],
    products: [
        // The main product — types + auto-generated @_cdecl exports + #AROExport macro.
        // Plugin authors use: `import AROPluginKit`
        .library(name: "AROPluginKit", targets: ["AROPluginKit"]),
        // Core types only (no @_cdecl exports, no macros).
        // Use when your plugin has its own @_cdecl exports.
        .library(name: "AROPluginSDK", targets: ["AROPluginSDK"]),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"602.0.0"),
    ],
    targets: [
        .target(name: "AROPluginSDK"),
        .macro(
            name: "AROPluginMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ]
        ),
        .target(
            name: "AROPluginKit",
            dependencies: [
                "AROPluginSDK",
                "AROPluginMacros",
            ]
        ),
        .testTarget(
            name: "AROPluginSDKTests",
            dependencies: [
                "AROPluginSDK",
                "AROPluginMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
