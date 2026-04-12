// ============================================================
// Testing.swift
// AROPluginSDK - Testing Helpers
// ============================================================

// MARK: - Mock Factories

/// Create an `ActionInput` pre-populated with `data` for unit testing.
///
/// Use this to test plugin logic without going through the C ABI:
/// ```swift
/// func testGreet() {
///     let input = mockInput(["data": "Alice", "_with": ["formal": "true"]])
///     XCTAssertEqual(input.string("data"), "Alice")
///     XCTAssertEqual(input.with.bool("formal"), true)
/// }
/// ```
public func mockInput(_ data: [String: Any] = [:]) -> ActionInput {
    ActionInput(data)
}

/// Create an `ActionInput` with named `with` parameters set.
///
/// Convenience wrapper for the common case where the test only needs to
/// exercise `input.with` accessors:
/// ```swift
/// let input = mockInputWith(["discount": 10.0, "currency": "USD"])
/// XCTAssertEqual(input.with.double("discount"), 10.0)
/// ```
public func mockInputWith(_ withParams: [String: Any]) -> ActionInput {
    ActionInput(["_with": withParams])
}

/// Create an `ActionInput` that simulates a full ARO-0073 envelope.
///
/// All fields are optional; omit those you don't need:
/// ```swift
/// let input = mockEnvelope(
///     action:      "greet",
///     data:        "Bob",
///     result:      Descriptor(base: "greeting"),
///     source:      Descriptor(base: "name"),
///     preposition: "with",
///     withParams:  ["formal": "false"],
///     context:     ContextInfo(requestId: "req-001", featureSet: "TestFeature")
/// )
/// ```
public func mockEnvelope(
    action:      String            = "test",
    data:        Any?              = nil,
    result:      Descriptor        = Descriptor(base: "result"),
    source:      Descriptor        = Descriptor(base: "source"),
    preposition: String            = "with",
    withParams:  [String: Any]     = [:],
    context:     ContextInfo       = .empty
) -> ActionInput {
    var envelope: [String: Any] = [
        "action":      action,
        "preposition": preposition,
        "result": [
            "base":       result.base,
            "specifiers": result.specifiers,
        ] as [String: Any],
        "source": [
            "base":       source.base,
            "specifiers": source.specifiers,
        ] as [String: Any],
    ]

    if let data { envelope["data"] = data }
    if !withParams.isEmpty { envelope["_with"] = withParams }

    var ctx: [String: Any] = [:]
    if let v = context.requestId        { ctx["requestId"] = v }
    if let v = context.featureSet       { ctx["featureSet"] = v }
    if let v = context.businessActivity { ctx["businessActivity"] = v }
    if !ctx.isEmpty { envelope["_context"] = ctx }

    return ActionInput(envelope)
}

/// Create a `QualifierParams` for testing qualifier logic.
///
/// ```swift
/// let params = mockQualifier(value: ["a", "b", "c"], type: "List")
/// let output = myPlugin.pickRandom(params)
/// XCTAssertNotNil(output)
/// ```
public func mockQualifier(
    value: Any,
    type: String = "Unknown",
    withParams: [String: Any] = [:]
) -> QualifierParams {
    var data: [String: Any] = ["value": value, "type": type]
    if !withParams.isEmpty { data["_with"] = withParams }
    return QualifierParams(data)
}
