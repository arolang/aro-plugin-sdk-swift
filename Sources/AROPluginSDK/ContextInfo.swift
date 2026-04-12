// ============================================================
// ContextInfo.swift
// AROPluginSDK - Execution Context (ARO-0073)
// ============================================================

/// Runtime context passed to every plugin action via the `"_context"` key.
///
/// Use these values for tracing, logging, and diagnostics. The runtime
/// populates whichever fields are available; all properties are optional.
///
/// ## JSON format (in `input_json`)
/// ```json
/// {
///   "_context": {
///     "requestId":        "abc-123",
///     "featureSet":       "Application-Start",
///     "businessActivity": "My App"
///   }
/// }
/// ```
public struct ContextInfo: Sendable {

    /// Unique identifier for the current HTTP request, if any.
    public let requestId: String?

    /// Name of the ARO feature set currently executing.
    public let featureSet: String?

    /// Business activity label from the feature set header.
    public let businessActivity: String?

    // MARK: - Initialisation

    public init(
        requestId: String? = nil,
        featureSet: String? = nil,
        businessActivity: String? = nil
    ) {
        self.requestId = requestId
        self.featureSet = featureSet
        self.businessActivity = businessActivity
    }

    /// Parse from the `"_context"` dictionary in the runtime input envelope.
    public init(from dict: [String: Any]) {
        self.requestId = dict["requestId"] as? String
        self.featureSet = dict["featureSet"] as? String
        self.businessActivity = dict["businessActivity"] as? String
    }

    /// An empty context with no fields set.
    public static let empty = ContextInfo()
}
