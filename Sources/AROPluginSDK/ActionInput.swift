// ============================================================
// ActionInput.swift
// AROPluginSDK - Type-Safe Action Input (ARO-0073)
// ============================================================

import Foundation

/// Type-safe access to the JSON envelope passed to `aro_plugin_execute`.
///
/// The ARO runtime serialises every action invocation into a JSON envelope
/// and passes it to the plugin as the `input_json` argument.  `ActionInput`
/// wraps that deserialized dictionary and provides structured, strongly-typed
/// accessors so plugin authors do not need to work with `[String: Any]`
/// directly.
///
/// ## Envelope structure
/// ```json
/// {
///   "action":      "greet",
///   "data":        "ARO Developer",
///   "result":      { "base": "greeting", "specifiers": [] },
///   "source":      { "base": "name",     "specifiers": [] },
///   "preposition": "with",
///   "_with":       { "name": "ARO Developer" },
///   "_context":    {
///     "requestId":        "abc-123",
///     "featureSet":       "Application-Start",
///     "businessActivity": "My App"
///   }
/// }
/// ```
///
/// ## Usage
/// ```swift
/// @_cdecl("aro_plugin_execute")
/// public func aroPluginExecute(
///     action:    UnsafePointer<CChar>?,
///     inputJson: UnsafePointer<CChar>?
/// ) -> UnsafeMutablePointer<CChar>? {
///     let input = ActionInput(aroParseJSON(inputJson))
///
///     let name  = input.string("data") ?? "World"
///     let reqId = input.context.requestId ?? "(none)"
///     let disc  = input.with.double("discount") ?? 0.0
///
///     return ActionOutput.success(["message": "Hello, \(name)!"]).toCString()
/// }
/// ```
public struct ActionInput: Sendable {

    /// The raw deserialized envelope dictionary.
    public let data: [String: Any]

    // MARK: - Initialisation

    /// Wrap an already-deserialized envelope dictionary.
    public init(_ data: [String: Any]) {
        self.data = data
    }

    // MARK: - Top-Level Data Accessors

    /// Returns the value for `key` as a `String`, or `nil` if absent or wrong type.
    public func string(_ key: String) -> String? {
        data[key] as? String
    }

    /// Returns the value for `key` as an `Int`, or `nil` if absent or wrong type.
    public func int(_ key: String) -> Int? {
        switch data[key] {
        case let i as Int:    return i
        case let d as Double: return Int(d)
        case let s as String: return Int(s)
        default:              return nil
        }
    }

    /// Returns the value for `key` as a `Double`, or `nil` if absent or wrong type.
    public func double(_ key: String) -> Double? {
        switch data[key] {
        case let d as Double: return d
        case let i as Int:    return Double(i)
        case let s as String: return Double(s)
        default:              return nil
        }
    }

    /// Returns the value for `key` as a `Bool`, or `nil` if absent or wrong type.
    public func bool(_ key: String) -> Bool? {
        switch data[key] {
        case let b as Bool:   return b
        case let s as String: return Bool(s)
        default:              return nil
        }
    }

    /// Returns the value for `key` as an `[Any]` array, or `nil` if absent or wrong type.
    public func array(_ key: String) -> [Any]? {
        data[key] as? [Any]
    }

    /// Returns the value for `key` as a `[String: Any]` dictionary, or `nil` if absent or wrong type.
    public func dict(_ key: String) -> [String: Any]? {
        data[key] as? [String: Any]
    }

    /// Raw access to the underlying value for `key`.
    public subscript(key: String) -> Any? { data[key] }

    // MARK: - ARO-0073 Descriptors

    /// Descriptor for the ARO result slot — the variable being bound by this statement.
    public var result: Descriptor {
        guard let d = data["result"] as? [String: Any] else {
            return Descriptor(base: "result")
        }
        return Descriptor(from: d) ?? Descriptor(base: "result")
    }

    /// Descriptor for the primary source (object) slot.
    public var source: Descriptor {
        guard let d = data["source"] as? [String: Any] else {
            return Descriptor(base: "source")
        }
        return Descriptor(from: d) ?? Descriptor(base: "source")
    }

    // MARK: - ARO-0073 Preposition

    /// The preposition used in the ARO statement (e.g., `"with"`, `"from"`, `"for"`).
    public var preposition: String {
        data["preposition"] as? String ?? ""
    }

    // MARK: - ARO-0073 Execution Context

    /// Execution context provided by the runtime (request ID, feature set name, etc.).
    public var context: ContextInfo {
        guard let d = data["_context"] as? [String: Any] else {
            return .empty
        }
        return ContextInfo(from: d)
    }

    // MARK: - ARO-0073 With-Clause Parameters

    /// Named parameters from the ARO `with { … }` clause.
    public var with: Params {
        guard let d = data["_with"] as? [String: Any] else {
            return Params()
        }
        return Params(d)
    }
}
