//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore

// TODO: Add import from CSV for multiple attributes and objects
// TODO: Add import from JSON for multiple attributes and objects

extension PoieticTool {
    struct SetAttribute: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "set",
                abstract: "Set an attribute value"
            )

        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        @Argument(help: "ID of an object to be modified")
        var reference: String

        @Argument(help: "Attribute to be set")
        var attributeName: String

        @Argument(help: "New attribute value")
        var value: String

        
        mutating func run() throws {
            let env = try ToolEnvironment(location: globalOptions.designLocation)
            let original = try env.existingFrame(options.deriveRef)
            let frame = env.design.createFrame(deriving: original)

            guard let object = frame.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let mutableObject = frame.mutate(object.id)

            try setAttributeFromString(object: mutableObject,
                                       attribute: attributeName,
                                       string: value)
            
            try env.accept(frame, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try env.close()
            
            print("Property set in \(reference): \(attributeName) = \(value)")
        }
    }

}

