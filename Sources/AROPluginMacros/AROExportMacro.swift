import SwiftSyntax
import SwiftSyntaxMacros

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

enum AROExportError: Error, CustomStringConvertible {
    case missingArgument

    var description: String {
        "#AROExport requires a plugin variable, e.g. #AROExport(plugin)"
    }
}
