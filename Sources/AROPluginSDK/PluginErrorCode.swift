// ============================================================
// PluginErrorCode.swift
// AROPluginSDK - Standard Error Codes (ARO-0073)
// ============================================================

// MARK: - Standard Plugin Error Codes

/// Standard numeric error codes for plugin responses (ARO-0073).
///
/// Return these codes in the `"error_code"` key of your plugin's JSON response.
/// The runtime maps them to descriptive error messages visible to the developer.
///
/// ## Usage
/// ```swift
/// return ActionOutput
///     .error(.notFound, "User with id \(id) was not found")
///     .toCString()
/// ```
///
/// ## Raw JSON equivalent
/// ```json
/// { "error_code": 2, "error": "User with id 42 was not found" }
/// ```
public enum PluginErrorCode: Int, Sendable, CaseIterable {

    /// Operation completed successfully (no error).
    case success = 0

    /// The input provided to the plugin was invalid or malformed.
    case invalidInput = 1

    /// The requested resource could not be found.
    case notFound = 2

    /// The caller does not have permission to perform the requested operation.
    case permissionDenied = 3

    /// The operation did not complete within the allowed time window.
    case timeout = 4

    /// A required network or service connection could not be established.
    case connectionFailed = 5

    /// The plugin failed while executing the requested operation.
    case executionFailed = 6

    /// The plugin or a resource it manages is in an invalid state.
    case invalidState = 7

    /// A required resource (memory, file handles, connections, etc.) is exhausted.
    case resourceExhausted = 8

    /// The requested action or feature is not supported by this plugin.
    case unsupported = 9

    /// The caller has exceeded an allowed request rate.
    case rateLimited = 10

    /// Human-readable description of the error code.
    public var description: String {
        switch self {
        case .success:           return "Success"
        case .invalidInput:      return "Invalid input"
        case .notFound:          return "Not found"
        case .permissionDenied:  return "Permission denied"
        case .timeout:           return "Timeout"
        case .connectionFailed:  return "Connection failed"
        case .executionFailed:   return "Execution failed"
        case .invalidState:      return "Invalid state"
        case .resourceExhausted: return "Resource exhausted"
        case .unsupported:       return "Unsupported"
        case .rateLimited:       return "Rate limited"
        }
    }
}

// MARK: - Plugin Error Category

/// Domain-specific category for a plugin error.
///
/// Categories group related error codes by area of concern, letting callers
/// apply broad retry or fallback strategies without matching individual codes.
public enum PluginErrorCategory: String, Sendable, CaseIterable {

    /// Input validation failure (maps to `invalidInput`).
    case validation

    /// I/O or file-system error (maps to `connectionFailed`, `resourceExhausted`, etc.).
    case io

    /// Authentication or authorisation failure (maps to `permissionDenied`).
    case authentication

    /// Request-rate limit exceeded (maps to `rateLimited`).
    case rateLimiting
}
