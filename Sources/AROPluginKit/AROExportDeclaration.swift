/// Generates the `@_cdecl("aro_plugin_register")` entry point that the
/// ARO runtime calls to trigger plugin initialization on all platforms.
///
/// Place this at file scope after your plugin declaration:
///
///     let plugin = AROPlugin(name: "my-plugin", version: "1.0.0", handle: "My")
///         .action("Greet", verbs: ["greet"]) { input in ... }
///
///     #AROExport(plugin)
///
@freestanding(declaration, names: named(_aroPluginRegister))
public macro AROExport(_ plugin: Any) = #externalMacro(module: "AROPluginMacros", type: "AROExportMacro")
