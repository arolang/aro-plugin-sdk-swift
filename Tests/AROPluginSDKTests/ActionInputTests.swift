// ============================================================
// ActionInputTests.swift
// AROPluginSDKTests - ActionInput Unit Tests
// ============================================================

import Testing
@testable import AROPluginSDK

// MARK: - ActionInput Tests

@Suite("ActionInput")
struct ActionInputTests {

    // MARK: Basic typed accessors

    @Test("string(_:) returns value when key exists")
    func stringAccessor() {
        let input = mockInput(["name": "Alice"])
        #expect(input.string("name") == "Alice")
    }

    @Test("string(_:) returns nil for missing key")
    func stringMissing() {
        let input = mockInput([:])
        #expect(input.string("name") == nil)
    }

    @Test("int(_:) coerces Double to Int")
    func intCoercesDouble() {
        let input = mockInput(["count": 3.0])
        #expect(input.int("count") == 3)
    }

    @Test("int(_:) coerces String to Int")
    func intCoercesString() {
        let input = mockInput(["count": "42"])
        #expect(input.int("count") == 42)
    }

    @Test("int(_:) returns nil for non-numeric string")
    func intInvalidString() {
        let input = mockInput(["count": "abc"])
        #expect(input.int("count") == nil)
    }

    @Test("double(_:) coerces Int to Double")
    func doubleCoercesInt() {
        let input = mockInput(["price": 10])
        #expect(input.double("price") == 10.0)
    }

    @Test("bool(_:) reads Bool directly")
    func boolDirect() {
        let input = mockInput(["active": true])
        #expect(input.bool("active") == true)
    }

    @Test("bool(_:) coerces 'true' string")
    func boolCoercesString() {
        let input = mockInput(["active": "true"])
        #expect(input.bool("active") == true)
    }

    @Test("array(_:) returns [Any]")
    func arrayAccessor() {
        let input = mockInput(["items": ["a", "b"] as [Any]])
        #expect((input.array("items") as? [String]) == ["a", "b"])
    }

    @Test("dict(_:) returns [String: Any]")
    func dictAccessor() {
        let input = mockInput(["meta": ["key": "val"] as [String: Any]])
        let dict = input.dict("meta")
        #expect(dict?["key"] as? String == "val")
    }

    @Test("subscript returns raw value")
    func subscriptAccess() {
        let input = mockInput(["x": 99])
        #expect(input["x"] as? Int == 99)
    }

    // MARK: Descriptors

    @Test("result descriptor parses base and specifiers")
    func resultDescriptor() {
        let input = mockInput([
            "result": ["base": "greeting", "specifiers": ["length"]] as [String: Any]
        ])
        #expect(input.result.base == "greeting")
        #expect(input.result.specifiers == ["length"])
    }

    @Test("result descriptor falls back gracefully")
    func resultDescriptorFallback() {
        let input = mockInput([:])
        #expect(input.result.base == "result")
        #expect(input.result.specifiers.isEmpty)
    }

    @Test("source descriptor parses correctly")
    func sourceDescriptor() {
        let input = mockInput([
            "source": ["base": "name", "specifiers": []] as [String: Any]
        ])
        #expect(input.source.base == "name")
        #expect(input.source.specifiers.isEmpty)
    }

    // MARK: Preposition

    @Test("preposition returns correct value")
    func prepositionValue() {
        let input = mockInput(["preposition": "from"])
        #expect(input.preposition == "from")
    }

    @Test("preposition returns empty string when absent")
    func prepositionMissing() {
        let input = mockInput([:])
        #expect(input.preposition == "")
    }

    // MARK: Context

    @Test("context parses all fields")
    func contextAllFields() {
        let input = mockInput([
            "_context": [
                "requestId":        "req-001",
                "featureSet":       "MyFeature",
                "businessActivity": "My App",
            ] as [String: Any]
        ])
        #expect(input.context.requestId == "req-001")
        #expect(input.context.featureSet == "MyFeature")
        #expect(input.context.businessActivity == "My App")
    }

    @Test("context returns empty when absent")
    func contextMissing() {
        let input = mockInput([:])
        #expect(input.context.requestId == nil)
        #expect(input.context.featureSet == nil)
        #expect(input.context.businessActivity == nil)
    }

    // MARK: With params

    @Test("with params provide typed access")
    func withParams() {
        let input = mockInput([
            "_with": ["discount": 0.1, "currency": "USD"] as [String: Any]
        ])
        #expect(input.with.double("discount") == 0.1)
        #expect(input.with.string("currency") == "USD")
    }

    @Test("with params is empty when absent")
    func withParamsMissing() {
        let input = mockInput([:])
        #expect(input.with.isEmpty)
    }
}

// MARK: - mockEnvelope Tests

@Suite("mockEnvelope")
struct MockEnvelopeTests {

    @Test("produces correct result descriptor")
    func resultDescriptor() {
        let input = mockEnvelope(result: Descriptor(base: "output", specifiers: ["uppercase"]))
        #expect(input.result.base == "output")
        #expect(input.result.specifiers == ["uppercase"])
    }

    @Test("includes data when provided")
    func dataField() {
        let input = mockEnvelope(data: "hello")
        #expect(input.string("data") == "hello")
    }

    @Test("omits context when empty")
    func noContext() {
        let input = mockEnvelope()
        #expect(input.data["_context"] == nil)
    }

    @Test("includes context when provided")
    func withContext() {
        let ctx = ContextInfo(requestId: "abc", featureSet: "Feat", businessActivity: "Act")
        let input = mockEnvelope(context: ctx)
        #expect(input.context.requestId == "abc")
        #expect(input.context.featureSet == "Feat")
        #expect(input.context.businessActivity == "Act")
    }
}

// MARK: - ActionOutput Tests

@Suite("ActionOutput")
struct ActionOutputTests {

    @Test("success serialises payload")
    func successJSON() {
        let output = ActionOutput.success(["message": "Hello"])
        let json = output.toJSON()
        #expect(json.contains("Hello"))
        #expect(!json.contains("error_code"))
    }

    @Test("error serialises error_code")
    func errorJSON() {
        let output = ActionOutput.error(.notFound, "Not found")
        let json = output.toJSON()
        #expect(json.contains("\"error_code\""))
        #expect(json.contains("2"))
    }

    @Test("emit appends _events array")
    func emitEvent() {
        let output = ActionOutput
            .success(["id": 1])
            .emit("UserCreated", data: ["id": 1])
        let json = output.toJSON()
        #expect(json.contains("_events"))
        #expect(json.contains("UserCreated"))
    }

    @Test("multiple emits chain correctly")
    func multipleEmits() {
        let output = ActionOutput
            .success([:])
            .emit("EventA", data: [:])
            .emit("EventB", data: [:])
        let json = output.toJSON()
        #expect(json.contains("EventA"))
        #expect(json.contains("EventB"))
    }

    @Test("toCString returns non-nil pointer")
    func toCString() {
        let output = ActionOutput.success(["ok": true])
        let ptr = output.toCString()
        #expect(ptr != nil)
        if let ptr { free(ptr) }
    }
}

// MARK: - Descriptor Tests

@Suite("Descriptor")
struct DescriptorTests {

    @Test("fullName with no specifiers is just base")
    func fullNameNoSpecifiers() {
        let d = Descriptor(base: "total")
        #expect(d.fullName == "total")
    }

    @Test("fullName includes specifiers")
    func fullNameWithSpecifiers() {
        let d = Descriptor(base: "total", specifiers: ["length"])
        #expect(d.fullName == "total: length")
    }

    @Test("primarySpecifier returns first element")
    func primarySpecifier() {
        let d = Descriptor(base: "x", specifiers: ["first", "second"])
        #expect(d.primarySpecifier == "first")
    }

    @Test("primarySpecifier is nil when empty")
    func primarySpecifierEmpty() {
        let d = Descriptor(base: "x")
        #expect(d.primarySpecifier == nil)
    }

    @Test("init(from:) parses valid dict")
    func initFromDict() {
        let d = Descriptor(from: ["base": "user", "specifiers": ["id"]])
        #expect(d?.base == "user")
        #expect(d?.specifiers == ["id"])
    }

    @Test("init(from:) returns nil for missing base")
    func initFromDictMissingBase() {
        let d = Descriptor(from: ["specifiers": ["id"]])
        #expect(d == nil)
    }
}

// MARK: - PluginErrorCode Tests

@Suite("PluginErrorCode")
struct PluginErrorCodeTests {

    @Test("all raw values are 0 through 10")
    func rawValues() {
        #expect(PluginErrorCode.success.rawValue == 0)
        #expect(PluginErrorCode.invalidInput.rawValue == 1)
        #expect(PluginErrorCode.notFound.rawValue == 2)
        #expect(PluginErrorCode.permissionDenied.rawValue == 3)
        #expect(PluginErrorCode.timeout.rawValue == 4)
        #expect(PluginErrorCode.connectionFailed.rawValue == 5)
        #expect(PluginErrorCode.executionFailed.rawValue == 6)
        #expect(PluginErrorCode.invalidState.rawValue == 7)
        #expect(PluginErrorCode.resourceExhausted.rawValue == 8)
        #expect(PluginErrorCode.unsupported.rawValue == 9)
        #expect(PluginErrorCode.rateLimited.rawValue == 10)
    }

    @Test("roundtrips through rawValue")
    func roundtrip() {
        for code in PluginErrorCode.allCases {
            #expect(PluginErrorCode(rawValue: code.rawValue) == code)
        }
    }

    @Test("description is non-empty for all cases")
    func descriptions() {
        for code in PluginErrorCode.allCases {
            #expect(!code.description.isEmpty)
        }
    }
}

// MARK: - QualifierParams Tests

@Suite("QualifierParams")
struct QualifierParamsTests {

    @Test("rawValue returns the value field")
    func rawValue() {
        let params = mockQualifier(value: ["a", "b"], type: "List")
        let arr = params.arrayValue
        #expect(arr?.count == 2)
    }

    @Test("type returns detected type")
    func typeField() {
        let params = mockQualifier(value: "hello", type: "String")
        #expect(params.type == "String")
    }

    @Test("with params work on qualifier")
    func withParams() {
        let params = mockQualifier(value: 42, type: "Int", withParams: ["multiplier": 2])
        #expect(params.with.int("multiplier") == 2)
    }

    @Test("successResult builds QualifierOutput")
    func successResult() {
        let params = mockQualifier(value: "x", type: "String")
        let output = params.successResult("transformed")
        let json = output.toJSON()
        #expect(json.contains("result"))
        #expect(json.contains("transformed"))
    }

    @Test("errorResult builds QualifierOutput with error")
    func errorResult() {
        let params = mockQualifier(value: "x", type: "String")
        let output = params.errorResult("Unsupported type")
        let json = output.toJSON()
        #expect(json.contains("error"))
        #expect(json.contains("Unsupported type"))
    }
}

// MARK: - aroStrdup Tests

@Suite("ABI")
struct ABITests {

    @Test("aroStrdup returns non-nil pointer for non-empty string")
    func strdupNonEmpty() {
        let ptr = aroStrdup("hello")
        #expect(ptr != nil)
        if let ptr {
            #expect(String(cString: ptr) == "hello")
            free(ptr)
        }
    }

    @Test("aroStrdup handles empty string")
    func strdupEmpty() {
        let ptr = aroStrdup("")
        #expect(ptr != nil)
        if let ptr {
            #expect(String(cString: ptr) == "")
            free(ptr)
        }
    }

    @Test("aroParseJSON parses valid JSON")
    func parseJSON() {
        let json = "{\"key\":\"value\"}"
        let dict: [String: Any] = json.withCString { aroParseJSON($0) }
        #expect(dict["key"] as? String == "value")
    }

    @Test("aroParseJSON returns empty dict for nil pointer")
    func parseJSONNil() {
        let dict: [String: Any] = aroParseJSON(nil)
        #expect(dict.isEmpty)
    }

    @Test("aroParseJSON returns empty dict for invalid JSON")
    func parseJSONInvalid() {
        let dict: [String: Any] = "not json".withCString { aroParseJSON($0) }
        #expect(dict.isEmpty)
    }
}
