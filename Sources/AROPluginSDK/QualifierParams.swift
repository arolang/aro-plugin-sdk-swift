// ============================================================
// QualifierParams.swift
// AROPluginSDK - Qualifier Parameter Access (ARO-0073)
// ============================================================

import Foundation

/// Type-safe wrapper for the JSON envelope passed to `aro_plugin_qualifier`.
///
/// The runtime serialises qualifier invocations into a JSON envelope:
/// ```json
/// {
///   "value": [...],
///   "type":  "List",
///   "_with": { "separator": "," }
/// }
/// ```
///
/// ## Usage
/// ```swift
/// @_cdecl("aro_plugin_qualifier")
/// public func aroPluginQualifier(
///     qualifier: UnsafePointer<CChar>?,
///     inputJson: UnsafePointer<CChar>?
/// ) -> UnsafeMutablePointer<CChar>? {
///     let params = QualifierParams(aroParseJSON(inputJson))
///     let sep = params.with.string("separator") ?? ","
///     // ... transform params.rawValue ...
/// }
/// ```
public struct QualifierParams: @unchecked Sendable {

    /// The raw deserialized envelope.
    public let data: [String: Any]

    // MARK: - Initialisation

    public init(_ data: [String: Any] = [:]) {
        self.data = data
    }

    // MARK: - Value Access

    /// The raw value to transform (may be a String, Int, Double, [Any], etc.).
    public var rawValue: Any? { data["value"] }

    /// The detected ARO type of the input value (`"List"`, `"String"`, `"Int"`, etc.).
    public var type: String { data["type"] as? String ?? "Unknown" }

    // MARK: - Convenience Typed Value Accessors

    /// The value as a `String`, or `nil` if absent or wrong type.
    public var stringValue: String? { data["value"] as? String }

    /// The value as an `Int`, or `nil` if absent or wrong type.
    public var intValue: Int? {
        switch data["value"] {
        case let i as Int:    return i
        case let d as Double: return Int(d)
        case let s as String: return Int(s)
        default:              return nil
        }
    }

    /// The value as a `Double`, or `nil` if absent or wrong type.
    public var doubleValue: Double? {
        switch data["value"] {
        case let d as Double: return d
        case let i as Int:    return Double(i)
        case let s as String: return Double(s)
        default:              return nil
        }
    }

    /// The value as an `[Any]` array, or `nil` if absent or wrong type.
    public var arrayValue: [Any]? { data["value"] as? [Any] }

    /// The value as a `[String: Any]` dictionary, or `nil` if absent or wrong type.
    public var dictValue: [String: Any]? { data["value"] as? [String: Any] }

    // MARK: - With-Clause Parameters

    /// Named parameters from the optional ARO `with { … }` clause.
    public var with: Params {
        guard let d = data["_with"] as? [String: Any] else {
            return Params()
        }
        return Params(d)
    }

    // MARK: - Building Responses

    /// Build a successful qualifier response wrapping the given value.
    ///
    /// ```swift
    /// return params.successResult(transformedList).toCString()
    /// ```
    public func successResult(_ value: Any) -> QualifierOutput {
        QualifierOutput(result: value)
    }

    /// Build an error qualifier response.
    public func errorResult(_ message: String) -> QualifierOutput {
        QualifierOutput(error: message)
    }
}

// MARK: - Qualifier Output

/// Response returned from `aro_plugin_qualifier`.
///
/// Use `toCString()` to produce the pointer expected by the C ABI.
public struct QualifierOutput: @unchecked Sendable {

    private let result: Any?
    private let error: String?

    public init(result: Any) {
        self.result = result
        self.error  = nil
    }

    public init(error: String) {
        self.result = nil
        self.error  = error
    }

    /// Serialise to a JSON string.
    public func toJSON() -> String {
        var dict: [String: Any]
        if let error {
            dict = ["error": error]
        } else if let result {
            // NSDictionary/NSArray for safe cross-dylib bridging
            let nsResult = bridgeToNSObject(result)
            dict = ["result": nsResult as Any]
        } else {
            dict = ["error": "No result"]
        }

        guard
            let nsDict = bridgeToNSObject(dict) as? NSDictionary,
            let data   = try? JSONSerialization.data(withJSONObject: nsDict),
            let json   = String(data: data, encoding: .utf8)
        else {
            return "{\"error\":\"Serialisation failed\"}"
        }
        return json
    }

    /// Allocate a C string suitable for returning from `aro_plugin_qualifier`.
    public func toCString() -> UnsafeMutablePointer<CChar>? {
        aroStrdup(toJSON())
    }
}
