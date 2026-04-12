// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AROPluginSDK",
    platforms: [.macOS(.v12)],
    products: [
        // The main product — types + auto-generated @_cdecl exports.
        // Plugin authors use: `import AROPluginKit`
        .library(name: "AROPluginKit", targets: ["AROPluginKit"]),
        // Core types only (no @_cdecl exports).
        // Use when your plugin has its own @_cdecl exports.
        .library(name: "AROPluginSDK", targets: ["AROPluginSDK"]),
    ],
    targets: [
        .target(name: "AROPluginSDK"),
        .target(name: "AROPluginKit", dependencies: ["AROPluginSDK"]),
        .testTarget(name: "AROPluginSDKTests", dependencies: ["AROPluginSDK"]),
    ]
)
