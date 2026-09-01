//
//  ConnectCommand.swift
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

        @Argument(help: "Attributes to be set in form 'attribute=value'")
        var attributeAssignments: [String] = []

        mutating func run() throws {
            let session = try DesignSession(location: globalOptions.designLocation)
            let trans = try session.createTransaction(deriving: options.deriveRef)

            guard let type = StockFlowMetamodel.objectType(name: typeName) else {
                throw ToolError.unknownObjectType(typeName)
            }
            
            guard type.topologyType == .edge else {
                throw ToolError.topologyTypeMismatch(TopologyType.edge.rawValue,
                                                       type.topologyType.rawValue)
            }
            
            guard let originObject = trans.object(stringReference: self.origin) else {
                throw ToolError.unknownObject( self.origin)
            }
            
            guard originObject.topology == .node else {
                throw ToolError.nodeExpected(self.origin)

            }
            
            guard let targetObject = trans.object(stringReference: self.target) else {
                throw ToolError.unknownObject(self.target)
            }

            guard targetObject.topology == .node else {
                throw ToolError.nodeExpected(target)

            }

            let edge = trans.create(type, topology: .edge(originObject.objectID, targetObject.objectID))
            
            for item in attributeAssignments {
                guard let split = parseValueAssignment(item) else {
                    throw ToolError.invalidAttributeAssignment(item)
                }
                let (name, stringValue) = split
                try setAttributeFromString(object: edge,
                                           attribute: name,
                                           string: stringValue)

            }
            
            try session.save(replacing: options.replaceRef, appendHistory: options.appendHistory)

            infoPrint("Created edge \(edge.objectID) in plane \(trans.id)")
        }
    }

}


