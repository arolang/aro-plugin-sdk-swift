// ============================================================
// JSONHelpers.swift
// AROPluginSDK - Internal JSON Serialisation Helpers
// ============================================================

import Foundation

// MARK: - Cross-dylib-safe bridging

/// Recursively convert Swift collections to their NS equivalents.
///
/// When a Swift plugin is loaded as a dynamic library via `dlopen()`, the
/// Foundation bridging machinery that normally coerces Swift `Dictionary` /
/// `Array` literals to `NSObject`-compatible types may not have run yet.
/// `JSONSerialization` can then silently drop keys or crash.
///
/// Using explicit `NSDictionary` / `NSArray` guarantees correct bridging
/// across the dylib boundary regardless of load order.
///
/// This function is `@_spi(AROPluginSDKInternal)` — it is technically public
/// so `ActionOutput` and `QualifierOutput` (same module) can call it, but
/// plugin authors should not rely on its signature.
@_spi(AROPluginSDKInternal)
public func bridgeToNSObject(_ value: Any) -> Any {
    switch value {
    case let dict as [String: Any]:
        let ns = NSMutableDictionary(capacity: dict.count)
        for (key, val) in dict {
            ns[key] = bridgeToNSObject(val)
        }
        return ns.copy()

    case let array as [Any]:
        let ns = NSMutableArray(capacity: array.count)
        for item in array {
            ns.add(bridgeToNSObject(item))
        }
        return ns.copy()

    case let s as String:   return s as NSString
    case let i as Int:      return NSNumber(value: i)
    case let d as Double:   return NSNumber(value: d)
    case let b as Bool:     return NSNumber(value: b)

    default:
        // Best-effort: return as-is and let JSONSerialization decide
        return value
    }
}

// MARK: - JSON String Parsing

/// Deserialise a JSON C string pointer into a `[String: Any]` dictionary.
///
/// Returns an empty dictionary when `ptr` is `nil`, empty, or not valid JSON.
/// This function never throws or crashes.
///
/// Used as the first line of every `aro_plugin_execute` / `aro_plugin_qualifier`
/// implementation:
/// ```swift
/// let input = ActionInput(aroParseJSON(inputJson))
/// ```
public func aroParseJSON(_ ptr: UnsafePointer<CChar>?) -> [String: Any] {
    guard
        let ptr,
        let json   = String(validatingCString: ptr),
        !json.isEmpty,
        let data   = json.data(using: .utf8),
        let object = try? JSONSerialization.jsonObject(with: data),
        let dict   = object as? [String: Any]
    else {
        return [:]
    }
    return dict
}

/// Overload that accepts the optional-pointer variant the C ABI often produces.
public func aroParseJSON(_ ptr: UnsafePointer<CChar>?) -> [String: Any]? {
    let result: [String: Any] = aroParseJSON(ptr)
    return result.isEmpty ? nil : result
}
