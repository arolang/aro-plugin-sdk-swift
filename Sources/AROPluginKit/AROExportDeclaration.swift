/// Attached macro that generates the `@_cdecl("aro_plugin_register")` entry point.
///
/// Usage (preferred):
///
///     @AROExport
///     private let plugin = AROPlugin(name: "my-plugin", version: "1.0.0", handle: "My")
///         .action("Greet", verbs: ["greet"]) { input in ... }
///
@attached(peer, names: named(_aroPluginRegister))
public macro AROExport() = #externalMacro(module: "AROPluginMacros", type: "AROExportPeerMacro")

/// Freestanding macro form for cases where an attached macro is not desired.
///
/// Usage:
///
///     let plugin = AROPlugin(name: "my-plugin", version: "1.0.0", handle: "My")
///         .action("Greet", verbs: ["greet"]) { input in ... }
///
///     #AROExport(plugin)
///
@freestanding(declaration, names: named(_aroPluginRegister))
public macro AROExport(_ plugin: Any) = #externalMacro(module: "AROPluginMacros", type: "AROExportMacro")
