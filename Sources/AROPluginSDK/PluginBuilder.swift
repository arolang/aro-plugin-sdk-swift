// ============================================================
// PluginBuilder.swift
// AROPluginSDK - Declarative Plugin Registration (ARO-0073)
// ============================================================
//
// Eliminates @_cdecl boilerplate and hand-written JSON.
// Plugin authors declare their plugin using a builder API:
//
//     let plugin = AROPlugin(name: "my-plugin", version: "1.0.0", handle: "MyPlugin")
//         .qualifier("reverse", inputTypes: ["List", "String"], description: "Reverse elements") { params in
//             if let arr = params.arrayValue { return .success(Array(arr.reversed())) }
//             if let str = params.stringValue { return .success(String(str.reversed())) }
//             return .failure("reverse requires a list or string")
//         }
//         .action("Greet", role: "own", prepositions: ["with"]) { input in
//             let name = input.string("name") ?? "World"
//             return .success(["greeting": "Hello, \(name)!"])
//         }
//
// Then call plugin.export() from a single @_cdecl entry point, or use the
// global AROPluginSDK.register(plugin) to auto-export.
// ============================================================

import Foundation

// MARK: - Qualifier Result

/// Result type for qualifier handlers
public enum QualifierResult {
    case success(Any)
    case failure(String)
}

// MARK: - Plugin Builder

/// Declarative plugin builder that auto-generates aro_plugin_info JSON
/// and dispatches aro_plugin_execute / aro_plugin_qualifier calls.
public final class AROPlugin: @unchecked Sendable {
    public let name: String
    public let version: String
    public let handle: String

    private var actionEntries: [ActionEntry] = []
    private var qualifierEntries: [QualifierEntry] = []
    private var serviceEntries: [ServiceEntry] = []
    private var initHandler: (() -> Void)?
    private var shutdownHandler: (() -> Void)?

    public init(name: String, version: String, handle: String) {
        self.name = name
        self.version = version
        self.handle = handle
    }

    // MARK: - Action Registration

    public struct ActionEntry: @unchecked Sendable {
        let name: String
        let verbs: [String]
        let role: String
        let prepositions: [String]
        let description: String
        let handler: (ActionInput) -> ActionOutput
    }

    @discardableResult
    public func action(
        _ name: String,
        verbs: [String]? = nil,
        role: String = "own",
        prepositions: [String] = ["from"],
        description: String = "",
        handler: @escaping (ActionInput) -> ActionOutput
    ) -> AROPlugin {
        actionEntries.append(ActionEntry(
            name: name,
            verbs: verbs ?? [name.lowercased()],
            role: role,
            prepositions: prepositions,
            description: description,
            handler: handler
        ))
        return self
    }

    // MARK: - Qualifier Registration

    public struct QualifierEntry: @unchecked Sendable {
        let name: String
        let inputTypes: [String]
        let description: String
        let acceptsParameters: Bool
        let handler: (QualifierParams) -> QualifierResult
    }

    @discardableResult
    public func qualifier(
        _ name: String,
        inputTypes: [String] = ["List"],
        description: String = "",
        acceptsParameters: Bool = false,
        handler: @escaping (QualifierParams) -> QualifierResult
    ) -> AROPlugin {
        qualifierEntries.append(QualifierEntry(
            name: name,
            inputTypes: inputTypes,
            description: description,
            acceptsParameters: acceptsParameters,
            handler: handler
        ))
        return self
    }

    // MARK: - Service Registration

    public struct ServiceEntry: @unchecked Sendable {
        let name: String
        let methods: [String]
        let description: String
        let handler: (String, ActionInput) -> ActionOutput
    }

    @discardableResult
    public func service(
        _ name: String,
        methods: [String],
        description: String = "",
        handler: @escaping (String, ActionInput) -> ActionOutput
    ) -> AROPlugin {
        serviceEntries.append(ServiceEntry(
            name: name,
            methods: methods,
            description: description,
            handler: handler
        ))
        return self
    }

    // MARK: - Lifecycle

    @discardableResult
    public func onInit(_ handler: @escaping () -> Void) -> AROPlugin {
        initHandler = handler
        return self
    }

    @discardableResult
    public func onShutdown(_ handler: @escaping () -> Void) -> AROPlugin {
        shutdownHandler = handler
        return self
    }

    // MARK: - Info JSON Generation

    /// Generate the aro_plugin_info JSON string
    public func infoJSON() -> String {
        var parts: [String] = []
        parts.append("\"name\":\"\(name)\"")
        parts.append("\"version\":\"\(version)\"")
        parts.append("\"handle\":\"\(handle)\"")

        // Actions
        let actionsJSON = actionEntries.map { entry in
            let verbs = entry.verbs.map { "\"\($0)\"" }.joined(separator: ",")
            let preps = entry.prepositions.map { "\"\($0)\"" }.joined(separator: ",")
            return "{\"name\":\"\(entry.name)\",\"verbs\":[\(verbs)],\"role\":\"\(entry.role)\",\"prepositions\":[\(preps)],\"description\":\"\(entry.description)\"}"
        }.joined(separator: ",")
        parts.append("\"actions\":[\(actionsJSON)]")

        // Qualifiers
        let qualJSON = qualifierEntries.map { entry in
            let types = entry.inputTypes.map { "\"\($0)\"" }.joined(separator: ",")
            return "{\"name\":\"\(entry.name)\",\"inputTypes\":[\(types)],\"description\":\"\(entry.description)\",\"accepts_parameters\":\(entry.acceptsParameters)}"
        }.joined(separator: ",")
        parts.append("\"qualifiers\":[\(qualJSON)]")

        // Services
        let svcJSON = serviceEntries.map { entry in
            let methods = entry.methods.map { "\"\($0)\"" }.joined(separator: ",")
            return "{\"name\":\"\(entry.name)\",\"methods\":[\(methods)],\"description\":\"\(entry.description)\"}"
        }.joined(separator: ",")
        parts.append("\"services\":[\(svcJSON)]")

        return "{\(parts.joined(separator: ","))}"
    }

    // MARK: - Dispatch

    /// Dispatch an action or service call
    public func execute(action: String, input: ActionInput) -> ActionOutput {
        // Check for service routing
        if action.hasPrefix("service:") {
            let method = String(action.dropFirst(8))
            for svc in serviceEntries {
                if svc.methods.contains(method) {
                    return svc.handler(method, input)
                }
            }
            return .failure(.unsupported, "Unknown service method: \(method)")
        }

        // Match action by name or verb
        let normalized = action.lowercased()
        for entry in actionEntries {
            if entry.name.lowercased() == normalized
                || entry.verbs.contains(where: { $0.lowercased() == normalized }) {
                return entry.handler(input)
            }
        }
        return .failure(.unsupported, "Unknown action: \(action)")
    }

    /// Dispatch a qualifier call
    public func executeQualifier(name: String, params: QualifierParams) -> QualifierResult {
        for entry in qualifierEntries {
            if entry.name == name {
                return entry.handler(params)
            }
        }
        return .failure("Unknown qualifier: \(name)")
    }

    /// Call init handler
    public func callInit() { initHandler?() }

    /// Call shutdown handler
    public func callShutdown() { shutdownHandler?() }
}

// MARK: - Global Plugin Registration

/// Global plugin instance for auto-export
/// Set via AROPluginExport.register() — the @_cdecl functions delegate here
public enum AROPluginExport {
    nonisolated(unsafe) static var shared: AROPlugin?

    /// Register a plugin for auto-export.
    /// After calling this, the SDK's @_cdecl entry points will delegate to this plugin.
    public static func register(_ plugin: AROPlugin) {
        shared = plugin
    }
}

// MARK: - Auto-generated @_cdecl entry points
//
// These are the C ABI exports that the ARO runtime loads via dlsym.
// They delegate to AROPluginExport.shared.

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
