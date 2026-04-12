// ============================================================
// EventData.swift
// AROPluginSDK - Event Data Accessor (ARO-0073)
// ============================================================

/// Type-safe access to the data payload delivered with an ARO domain event.
///
/// When a plugin subscribes to events via the `"events"` array in
/// `aro_plugin_info`, the runtime calls `aro_plugin_on_event` with:
/// - `event_type` — the event name (e.g., `"UserCreated"`)
/// - `data_json`  — a JSON object with the event payload
///
/// `EventData` wraps the deserialized payload and exposes the same
/// typed accessors as `ActionInput`.
///
/// ## Example
/// ```swift
/// @_cdecl("aro_plugin_on_event")
/// public func aroPluginOnEvent(
///     eventType: UnsafePointer<CChar>?,
///     dataJson:  UnsafePointer<CChar>?
/// ) {
///     let type = eventType.map { String(cString: $0) } ?? ""
///     let data = EventData(aroParseJSON(dataJson))
///
///     if type == "UserCreated" {
///         let userId = data.string("id") ?? "unknown"
///         print("New user: \(userId)")
///     }
/// }
/// ```
public struct EventData: @unchecked Sendable {

    /// The raw deserialized payload dictionary.
    public let data: [String: Any]

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
}
