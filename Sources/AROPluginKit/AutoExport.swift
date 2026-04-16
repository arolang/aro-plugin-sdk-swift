// ============================================================
// AutoExport.swift
// AROPluginKit - Auto-generated @_cdecl entry points
// ============================================================
//
// This target provides the @_cdecl exports that the ARO runtime
// loads via dlsym, plus the #AROExport macro for plugin registration.
//
// Plugin authors use:
//
//     import AROPluginKit
//
//     let plugin = AROPlugin(name: "my-plugin", version: "1.0.0", handle: "My")
//         .action("Greet", verbs: ["greet"]) { input in ... }
//
//     #AROExport(plugin)
//

import Foundation
@_exported import AROPluginSDK

@_cdecl("aro_plugin_info")
public func _aro_sdk_plugin_info() -> UnsafeMutablePointer<CChar>? {
    guard let plugin = AROPluginExport.shared else {
        return aroStrdup("{\"name\":\"unknown\",\"version\":\"0.0.0\",\"actions\":[],\"qualifiers\":[]}")
    }
    return aroStrdup(plugin.infoJSON())
}

@_cdecl("aro_plugin_execute")
public func _aro_sdk_plugin_execute(
    action: UnsafePointer<CChar>?,
    inputJson: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {
    guard let plugin = AROPluginExport.shared else {
        return aroStrdup("{\"error\":\"Plugin not registered\"}")
    }
    let actionStr = action.map { String(cString: $0) } ?? ""
    let input = ActionInput(aroParseJSON(inputJson))
    let output = plugin.execute(action: actionStr, input: input)
    return output.toCString()
}

@_cdecl("aro_plugin_qualifier")
public func _aro_sdk_plugin_qualifier(
    qualifier: UnsafePointer<CChar>?,
    inputJson: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {
    guard let plugin = AROPluginExport.shared else {
        return aroStrdup("{\"error\":\"Plugin not registered\"}")
    }
    let qualName = qualifier.map { String(cString: $0) } ?? ""
    let params = QualifierParams(aroParseJSON(inputJson))
    let result = plugin.executeQualifier(name: qualName, params: params)
    switch result {
    case .success(let value):
        return params.successResult(value).toCString()
    case .failure(let message):
        return params.errorResult(message).toCString()
    }
}

@_cdecl("aro_plugin_init")
public func _aro_sdk_plugin_init() {
    AROPluginExport.shared?.callInit()
}

@_cdecl("aro_plugin_shutdown")
public func _aro_sdk_plugin_shutdown() {
    AROPluginExport.shared?.callShutdown()
}

@_cdecl("aro_plugin_free")
public func _aro_sdk_plugin_free(ptr: UnsafeMutablePointer<CChar>?) {
    guard let ptr else { return }
    free(ptr)
}
