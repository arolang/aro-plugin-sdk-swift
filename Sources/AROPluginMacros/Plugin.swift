import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AROPluginMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AROExportMacro.self,
        AROExportPeerMacro.self,
    ]
}
