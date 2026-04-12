// ============================================================
// ActionOutput.swift
// AROPluginSDK - Output Builder (ARO-0073)
// ============================================================

import Foundation

/// Builds the JSON response returned from `aro_plugin_execute`.
///
/// Use the enum cases to create success or error responses, optionally
/// append events, and call `toCString()` to produce the
/// `UnsafeMutablePointer<CChar>` expected by the C ABI.
///
/// ## Success
/// ```swift
/// return ActionOutput.success(["message": "Hello, \(name)!"]).toCString()
/// ```
///
/// ## Error
/// ```swift
/// return ActionOutput.failure(.notFound, "User not found").toCString()
/// ```
///
/// ## Emitting events
/// ```swift
/// return ActionOutput
///     .success(["user": userDict])
///     .emit("UserCreated", data: ["user": userDict])
///     .toCString()
/// ```
///
/// > Note: `[String: Any]` is not `Sendable` in Swift 6 strict mode.
/// > `ActionOutput` values are constructed and consumed on a single thread
/// > within the synchronous C ABI call, so `@unchecked Sendable` is safe.
public enum ActionOutput: @unchecked Sendable {

    /// A successful response carrying an arbitrary payload dictionary.
    case success([String: Any])

    /// An error response with a standard code, an optional human-readable
    /// message, and optional additional details.
    case failure(PluginErrorCode, String? = nil, [String: Any]? = nil)

    // MARK: - Event Emission

    /// Append a domain event to emit after this action completes.
    ///
    /// The runtime reads the `"_events"` array and publishes each entry to
    /// the `EventBus` before binding the result variable.
    ///
    /// Multiple calls chain together:
    /// ```swift
    /// return ActionOutput.success(result)
    ///     .emit("UserCreated", data: ["id": userId])
    ///     .emit("AuditLog",    data: ["action": "create"])
    ///     .toCString()
    /// ```
    public func emit(_ eventType: String, data: [String: Any] = [:]) -> ActionOutput {
        var payload = payloadDict()

        // Append to existing events array (or start a new one)
        var events = payload["_events"] as? [[String: Any]] ?? []
        events.append(["type": eventType, "data": data])
        payload["_events"] = events

        // Preserve error information when chaining on an error output
        switch self {
        case .success:
            return .success(payload)
        case .failure(let code, let message, _):
            return .failure(code, message, payload)
        }
    }

    // MARK: - Serialisation

    /// Serialise to a JSON string.
    ///
    /// Returns `"{}"` on serialisation failure (should never happen with
    /// well-formed plugin payloads).
    public func toJSON() -> String {
        let dict = payloadDict()

        // NSDictionary is used intentionally to guarantee correct bridging
        // across the dylib boundary (see HelloPlugin.swift for full rationale).
        guard
            let nsDict = bridgeToNSObject(dict) as? NSDictionary,
            let data   = try? JSONSerialization.data(withJSONObject: nsDict),
            let json   = String(data: data, encoding: .utf8)
        else {
            return "{}"
        }
        return json
    }

    /// Allocate a C string (using `malloc`) suitable for returning from a
    /// `@_cdecl` function. The caller (the ARO runtime) is responsible for
    /// freeing it via `aro_plugin_free`.
    ///
    /// Equivalent to `aroStrdup(toJSON())`.
    public func toCString() -> UnsafeMutablePointer<CChar>? {
        aroStrdup(toJSON())
    }

    // MARK: - Internal Helpers

    /// Build the raw `[String: Any]` dictionary for this output.
    func payloadDict() -> [String: Any] {
        switch self {
        case .success(let payload):
            return payload

        case .failure(let code, let message, let details):
            var dict: [String: Any] = ["error_code": code.rawValue]
            dict["error"] = message ?? code.description
            if let details { dict["details"] = details }
            return dict
        }
    }
}
