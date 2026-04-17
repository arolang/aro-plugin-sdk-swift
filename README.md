# ARO Plugin SDK for Swift

Build ARO plugins in Swift with zero boilerplate. The SDK provides a declarative builder API, the `@AROExport` macro for automatic C ABI generation, and type-safe accessors for all input and output.

## Installation

Add the SDK to your plugin's `Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyPlugin",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "MyPlugin", type: .dynamic, targets: ["MyPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/arolang/aro-plugin-sdk-swift.git", branch: "main"),
    ],
    targets: [
        .target(name: "MyPlugin", dependencies: [
            .product(name: "AROPluginKit", package: "aro-plugin-sdk-swift"),
        ]),
    ]
)
```

## Quick Start

```swift
import AROPluginKit

@AROExport
private let plugin = AROPlugin(name: "my-plugin", version: "1.0.0", handle: "Greeting")
    .action("Greet", verbs: ["greet"], role: "own", prepositions: ["with"],
            description: "Greet someone by name") { input in
        let name = input.string("name") ?? input.with.string("name") ?? "World"
        return .success(["greeting": "Hello, \(name)!"])
    }
```

The `@AROExport` macro generates all required C ABI exports (`aro_plugin_info`, `aro_plugin_execute`, `aro_plugin_qualifier`, `aro_plugin_free`, etc.) automatically.

## Actions

Actions handle verbs in ARO statements like `Greet the <result> with <data>.`

```swift
.action("Greet", verbs: ["greet"], role: "own", prepositions: ["with"],
        description: "Greet someone") { input in
    let name = input.string("name") ?? "World"
    let formal = input.with.bool("formal") ?? false

    if formal {
        return .success(["greeting": "Good day, \(name)."])
    }
    return .success(["greeting": "Hello, \(name)!"])
}
```

**Roles**: `"request"` (external → internal), `"own"` (internal → internal), `"response"` (internal → external), `"export"` (publishes data)

## Qualifiers

Qualifiers transform values using the `<value: Handle.qualifier>` syntax in ARO.

```swift
.qualifier("reverse", inputTypes: ["List", "String"],
           description: "Reverse elements or characters") { params in
    if let arr = params.arrayValue { return .success(Array(arr.reversed())) }
    if let str = params.stringValue { return .success(String(str.reversed())) }
    return .failure("reverse requires a list or string")
}
```

Qualifiers with parameters (from the ARO `with { }` clause):

```swift
.qualifier("top", inputTypes: ["List"], acceptsParameters: true,
           description: "Return top N elements") { params in
    guard let arr = params.arrayValue else { return .failure("requires a list") }
    let n = params.with.int("count") ?? 3
    return .success(Array(arr.prefix(n)))
}
```

## Services

Services expose methods callable via `Call the <result> from the <service: method>.`

```swift
.service("counter", methods: ["increment", "get", "reset"],
         description: "Thread-safe counter") { method, input in
    switch method {
    case "increment":
        count += 1
        return .success(["count": count])
    case "get":
        return .success(["count": count])
    case "reset":
        count = 0
        return .success(["count": 0])
    default:
        return .failure(.notFound, "Unknown method: \(method)")
    }
}
```

## Lifecycle Hooks

```swift
.onInit {
    // Called once when the plugin is loaded — open connections, allocate resources
}
.onShutdown {
    // Called when the plugin is unloaded — close connections, flush buffers
}
```

## Event Emission

Actions can emit events that trigger other ARO feature sets:

```swift
.action("CreateUser", verbs: ["createuser"], role: "own", prepositions: ["with"]) { input in
    let user = createUser(input)
    return .success(["user": user])
           .emit("UserCreated", data: ["userId": user["id"]!])
}
```

## Input API

`ActionInput` provides type-safe access to the JSON envelope:

```swift
// Primary data (top-level keys take precedence over _with)
input.string("name")         // String?
input.int("count")           // Int?
input.double("price")        // Double?
input.bool("enabled")        // Bool?
input.array("items")         // [Any]?
input.dict("metadata")       // [String: Any]?

// With-clause parameters: with { format: "json", limit: 10 }
input.with.string("format")  // String?
input.with.int("limit")      // Int?
input.with.bool("verbose")   // Bool?
input.with.isEmpty            // Bool
input.with.keys               // [String]

// ARO statement descriptors
input.result.base             // "greeting"
input.result.specifiers       // ["formal"]
input.source.base             // "user-data"
input.preposition             // "with"

// Execution context
input.context.requestId       // String? (HTTP request ID)
input.context.featureSet      // String? (ARO feature set name)
input.context.businessActivity // String? (business activity label)
```

## Output API

`ActionOutput` builds the JSON response:

```swift
return .success(["key": "value"])                           // Simple success
return .success(["result": data]).emit("Event", data: [...]) // With event
return .failure(.invalidInput, "Missing required field")     // Error with code
return .failure(.notFound, "User not found", ["id": userId]) // Error with details
```

## Error Codes

| Code | Name | Description |
|------|------|-------------|
| 0 | `success` | No error |
| 1 | `invalidInput` | Missing or malformed input |
| 2 | `notFound` | Resource not found |
| 3 | `permissionDenied` | Access denied |
| 4 | `timeout` | Operation timed out |
| 5 | `connectionFailed` | Network/connection error |
| 6 | `executionFailed` | Runtime execution error |
| 7 | `invalidState` | Invalid plugin state |
| 8 | `resourceExhausted` | Out of resources |
| 9 | `unsupported` | Feature not supported |
| 10 | `rateLimited` | Rate limit exceeded |

## Testing

The SDK provides mock helpers for unit testing:

```swift
import AROPluginSDK

// Mock a simple action input
let input = mockInput(["name": "Alice", "age": 30])

// Mock with with-clause parameters
let input = mockInputWith(["format": "json", "limit": "10"])

// Full envelope with all fields
let input = mockEnvelope(
    action: "greet",
    data: "Alice",
    result: Descriptor(base: "greeting"),
    source: Descriptor(base: "user"),
    preposition: "with",
    withParams: ["formal": true],
    context: ContextInfo(requestId: "req-001", featureSet: "UserAPI")
)

// Mock qualifier input
let params = mockQualifier(value: [1, 2, 3], type: "List")
assert(params.arrayValue?.count == 3)
```

## Complete Example

A plugin with actions, qualifiers, a service, and lifecycle hooks:

```swift
import AROPluginKit

private var db: DatabaseConnection?

@AROExport
private let plugin = AROPlugin(name: "my-database", version: "1.0.0", handle: "DB")
    .action("Query", verbs: ["query"], role: "request", prepositions: ["from", "with"],
            description: "Execute a database query") { input in
        let sql = input.string("data") ?? input.with.string("sql") ?? ""
        guard let rows = try? db?.query(sql) else {
            return .failure(.executionFailed, "Query failed")
        }
        return .success(["rows": rows, "count": rows.count])
    }
    .qualifier("count", inputTypes: ["List"],
               description: "Count elements") { params in
        guard let arr = params.arrayValue else { return .failure("requires a list") }
        return .success(arr.count)
    }
    .service("db", methods: ["execute", "ping"],
             description: "Low-level database access") { method, input in
        switch method {
        case "execute":
            let sql = input.with.string("sql") ?? ""
            return .success(["affected": try db?.execute(sql) ?? 0])
        case "ping":
            return .success(["alive": db != nil])
        default:
            return .failure(.notFound, "Unknown method: \(method)")
        }
    }
    .onInit {
        db = try? DatabaseConnection(path: "data.db")
    }
    .onShutdown {
        db?.close()
        db = nil
    }
```

## License

MIT
