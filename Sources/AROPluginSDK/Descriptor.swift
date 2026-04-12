// ============================================================
// Descriptor.swift
// AROPluginSDK - Result and Source Descriptor (ARO-0073)
// ============================================================

/// A parsed descriptor for the result or source slot of an ARO statement.
///
/// In `Compute the <total: length> from the <items>`:
/// - result descriptor: base="total", specifiers=["length"]
/// - source descriptor: base="items",  specifiers=[]
///
/// The runtime serialises descriptors into every `input_json` envelope under
/// the `"result"` and `"source"` keys.
public struct Descriptor: Sendable, Equatable {

    /// The base name — the variable being bound (result) or the input slot (source).
    public let base: String

    /// Type or operation specifiers appended after the colon in `<base: spec1.spec2>`.
    public let specifiers: [String]

    /// The first specifier, or `nil` when none are present.
    public var primarySpecifier: String? { specifiers.first }

    /// Full qualified name as it appears in ARO source (`base: spec1.spec2`).
    public var fullName: String {
        specifiers.isEmpty ? base : "\(base): \(specifiers.joined(separator: "."))"
    }

    // MARK: - Initialisation

    public init(base: String, specifiers: [String] = []) {
        self.base = base
        self.specifiers = specifiers
    }

    /// Parse a descriptor from a dictionary produced by the ARO runtime.
    ///
    /// Expected format: `{ "base": "...", "specifiers": ["..."] }`
    public init?(from dict: [String: Any]) {
        guard let base = dict["base"] as? String else { return nil }
        self.base = base
        self.specifiers = dict["specifiers"] as? [String] ?? []
    }
}
