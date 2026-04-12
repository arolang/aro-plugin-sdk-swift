// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AROPluginSDK",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "AROPluginSDK", targets: ["AROPluginSDK"]),
    ],
    targets: [
        .target(name: "AROPluginSDK"),
        .testTarget(name: "AROPluginSDKTests", dependencies: ["AROPluginSDK"]),
    ]
)
