# AROPluginSDK (Swift)

Swift helper library for building ARO plugins. Eliminates boilerplate by providing
type-safe wrappers for the ARO-0073 C ABI.

## Installation

Add the package to your plugin's `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arolang/aro-plugin-sdk-swift", from: "1.0.0"),
],
targets: [
    .target(name: "MyPlugin", dependencies: ["AROPluginSDK"]),
]
```

## Usage

```swift
import AROPluginSDK
import Foundation

@_cdecl("aro_plugin_execute")
public func aroPluginExecute(
    action:    UnsafePointer<CChar>?,
    inputJson: UnsafePointer<CChar>?
) -> UnsafeMutablePointer<CChar>? {

    let input  = ActionInput(aroParseJSON(inputJson))
    let name   = input.string("data") ?? "World"
    let formal = input.with.bool("formal") ?? false
    let reqId  = input.context.requestId ?? "(none)"

    let greeting = formal ? "Good day, \(name)." : "Hello, \(name)!"

    return ActionOutput
        .success(["message": greeting, "requestId": reqId])
        .emit("GreetingIssued", data: ["name": name])
        .toCString()
}

@_cdecl("aro_plugin_free")
public func aroPluginFree(ptr: UnsafeMutablePointer<CChar>?) {
    guard let ptr else { return }
    free(ptr)
}
```

## Key Types

| Type | Purpose |
|------|---------|
| `ActionInput` | Typed access to the JSON envelope passed to `aro_plugin_execute` |
| `ActionOutput` | Builder for the JSON response, with event emission support |
| `Descriptor` | Parsed result/source descriptor (`base` + `specifiers`) |
| `ContextInfo` | Execution context (request ID, feature set, business activity) |
| `Params` | Named parameters from the ARO `with { … }` clause |
| `EventData` | Typed access to event payloads in `aro_plugin_on_event` |
| `QualifierParams` | Envelope wrapper for `aro_plugin_qualifier` |
| `QualifierOutput` | Response builder for qualifier transformations |
| `PluginErrorCode` | Standard error codes 0–10 (ARO-0073) |
| `PluginErrorCategory` | Broad error category groupings |

## ABI Helpers

```swift
// Parse JSON from a C string pointer (returns empty dict on failure, never throws)
let dict = aroParseJSON(inputJson)

// Allocate a malloc-based C string safe to return across dylib boundaries
return aroStrdup("{\"ok\": true}")
```

## Testing

Use the mock helpers in test targets:

```swift
import AROPluginSDK

let input = mockEnvelope(
    action:      "greet",
    data:        "Alice",
    preposition: "with",
    withParams:  ["formal": "true"],
    context:     ContextInfo(requestId: "req-001")
)

let qualifier = mockQualifier(value: ["a", "b", "c"], type: "List")
```
