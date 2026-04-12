// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AROPluginSDK",
    platforms: [.macOS(.v12)],
    products: [
        // Core types only (ActionInput, ActionOutput, AROPlugin builder, etc.)
        // Use this when your plugin has its own @_cdecl exports
        .library(name: "AROPluginSDK", targets: ["AROPluginSDK"]),
        // Core types + auto-generated @_cdecl exports
        // Use this for zero-boilerplate plugins that use AROPlugin builder
        .library(name: "AROPluginSDKExport", targets: ["AROPluginSDKExport"]),
    ],
    targets: [
        .target(name: "AROPluginSDK"),
        .target(name: "AROPluginSDKExport", dependencies: ["AROPluginSDK"]),
        .testTarget(name: "AROPluginSDKTests", dependencies: ["AROPluginSDK"]),
    ]
)
