// ============================================================
// Params.swift
// AROPluginSDK - With-Clause Parameters (ARO-0073)
// ============================================================

/// Type-safe access to named parameters from the ARO `with { … }` clause.
///
/// The runtime serialises the `with` block into the `"_with"` key of every
/// `input_json` envelope. `Params` wraps that dictionary and provides
/// strongly-typed accessors.
///
/// ## Example
/// ARO statement: `Compute the <total> from the <cart> with { discount: "10" }.`
///
/// Plugin code:
/// ```swift
/// let discount = input.with.double("discount") ?? 0.0
/// ```
public struct Params: @unchecked Sendable {

    private let data: [String: Any]

    // MARK: - Initialisation

    public init(_ data: [String: Any] = [:]) {
        self.data = data
    }

    // MARK: - Typed Accessors

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

    /// `true` when no parameters were supplied.
    public var isEmpty: Bool { data.isEmpty }

    /// All parameter keys present in this instance.
    public var keys: [String] { Array(data.keys) }
}
