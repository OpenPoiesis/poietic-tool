//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Allow setting attributes on creation

extension PoieticTool {
    struct Connect: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "connect",
                abstract: "Create a new connection (edge) between two nodes"
            )

        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        @Argument(help: "Type of the connection to be created")
        var typeName: String

        @Argument(help: "Reference to the connection's origin node")
        var origin: String

        @Argument(help: "Reference to the connection's target node")
        var target: String

        
        mutating func run() throws {
            let env = try ToolEnvironment(location: globalOptions.designLocation)
            let trans = try env.deriveOrCreate(options.deriveRef)

            guard let type = FlowsMetamodel.objectType(name: typeName) else {
                throw ToolError.unknownObjectType(typeName)
            }
            
            guard type.structuralType == .edge else {
                throw ToolError.structuralTypeMismatch(StructuralType.edge.rawValue,
                                                       type.structuralType.rawValue)
            }
            
            guard let originObject = trans.object(stringReference: self.origin) else {
                throw ToolError.unknownObject( self.origin)
            }
            
            guard originObject.structure == .node else {
                throw ToolError.nodeExpected(self.origin)

            }
            
            guard let targetObject = trans.object(stringReference: self.target) else {
                throw ToolError.unknownObject(self.target)
            }

            guard targetObject.structure == .node else {
                throw ToolError.nodeExpected(target)

            }

            let id = trans.create(type, structure: .edge(originObject.id, targetObject.id))
            
            try env.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try env.close()

            print("Created edge \(id)")
        }
    }

}


