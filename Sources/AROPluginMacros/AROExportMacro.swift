import SwiftSyntax
import SwiftSyntaxMacros

/// Freestanding form: `#AROExport(plugin)`
public struct AROExportMacro: DeclarationMacro {
    public static func expansion(
        of node: some FreestandingMacroExpansionSyntax,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let argument = node.arguments.first?.expression else {
            throw AROExportError.missingArgument
        }

        return [
            """
            @_cdecl("aro_plugin_register")
            public func _aroPluginRegister() {
                _ = \(argument)
            }
            """
        ]
    }
}

/// Attached form: `@AROExport private let plugin = ...`
public struct AROExportPeerMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        // Extract the variable name from the let/var declaration
        guard let varDecl = declaration.as(VariableDeclSyntax.self),
              let binding = varDecl.bindings.first,
              let pattern = binding.pattern.as(IdentifierPatternSyntax.self) else {
            throw AROExportError.notALetDeclaration
        }

        let varName = pattern.identifier.text

        return [
            """
            @_cdecl("aro_plugin_register")
            public func _aroPluginRegister() {
                _ = \(raw: varName)
            }
            """
        ]
    }
}

enum AROExportError: Error, CustomStringConvertible {
    case missingArgument
    case notALetDeclaration

    var description: String {
        switch self {
        case .missingArgument:
            return "#AROExport requires a plugin variable, e.g. #AROExport(plugin)"
        case .notALetDeclaration:
            return "@AROExport must be attached to a let declaration, e.g. @AROExport let plugin = ..."
        }
    }
}
