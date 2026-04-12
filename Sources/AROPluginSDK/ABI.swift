// ============================================================
// ABI.swift
// AROPluginSDK - C ABI Helpers (ARO-0073)
// ============================================================

import Foundation

// MARK: - Memory Allocation

/// Allocate a C string using `malloc` that is safe to return across a dylib boundary.
///
/// The ARO runtime frees every string returned by a plugin via the plugin's own
/// `aro_plugin_free` function (which in turn calls `free()`).  Swift's built-in
/// `String` heap allocator is NOT compatible with `free()`, so plugins must use
/// `malloc`-based allocation for any pointer they hand back to the runtime.
///
/// This function is the Swift equivalent of the C idiom `strdup(str)` and
/// produces a pointer compatible with the expected `aro_plugin_free` implementation:
/// ```swift
/// @_cdecl("aro_plugin_free")
/// public func aroPluginFree(ptr: UnsafeMutablePointer<CChar>?) {
///     guard let ptr else { return }
///     free(ptr)
/// }
/// ```
///
/// ## Usage
/// ```swift
/// return aroStrdup("{\"message\": \"Hello!\"}")
/// ```
public func aroStrdup(_ string: String) -> UnsafeMutablePointer<CChar>? {
    string.withCString { cStr in
        // strlen + 1 to include the NUL terminator
        let length = strlen(cStr) + 1
        guard let buffer = malloc(length) else { return nil }
        memcpy(buffer, cStr, length)
        return buffer.assumingMemoryBound(to: CChar.self)
    }
}

// MARK: - JSON Parsing (public overload for clarity)

/// Parse a JSON C string pointer into a `[String: Any]` dictionary.
///
/// This is a convenience re-export of `aroParseJSON(_:)` from `JSONHelpers.swift`
/// so plugin authors need only `import AROPluginSDK` and can use `aroParseJSON`
/// and `aroStrdup` as a matched pair without knowing the internal module layout.
///
/// ```swift
/// @_cdecl("aro_plugin_execute")
/// public func aroPluginExecute(
///     action: UnsafePointer<CChar>?,
///     inputJson: UnsafePointer<CChar>?
/// ) -> UnsafeMutablePointer<CChar>? {
///     let input  = ActionInput(aroParseJSON(inputJson))
///     let output = ActionOutput.success(["result": "ok"])
///     return aroStrdup(output.toJSON())
/// }
/// ```
// Note: aroParseJSON is defined in JSONHelpers.swift and is already public.
// This comment documents the intended API surface — no redeclaration needed.
