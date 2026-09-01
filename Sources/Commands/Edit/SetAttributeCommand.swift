//
//  SetAttributeCommand.swift
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
            let session = try DesignSession(location: globalOptions.designLocation)
            let trans = try session.createTransaction(deriving: options.deriveRef)

            guard let object = trans.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let mutableObject = trans.mutate(object.objectID)

            try setAttributeFromString(object: mutableObject,
                                       attribute: attributeName,
                                       string: value)
            
            try session.save(replacing: options.replaceRef, appendHistory: options.appendHistory)

            infoPrint("Attribute set in \(reference): \(attributeName) = \(value)")
        }
    }

    // MARK: Set Multiple
    struct SetMultipleAttributes: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "set-multiple",
                abstract: "Set values of multiple attributes"
            )

        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        @Argument(help: "ID of an object to be modified")
        var reference: String

        @Argument(help: "Attributes to set in form 'attribute=value'")
        var assignments: [String]

        mutating func validate() throws {
            guard !assignments.isEmpty else {
                throw ValidationError("At least one 'attribute=value' assignment is required")
            }
        }

        mutating func run() throws {
            let session = try DesignSession(location: globalOptions.designLocation)
            let trans = try session.createTransaction(deriving: options.deriveRef)

            guard let object = trans.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let mutableObject = trans.mutate(object.objectID)

            var names: [String] = []
            for item in assignments {
                guard let split = parseValueAssignment(item) else {
                    throw ToolError.invalidAttributeAssignment(item)
                }
                let (name, stringValue) = split
                names.append(name)
                try setAttributeFromString(object: mutableObject,
                                           attribute: name,
                                           string: stringValue)

            }

            try session.save(replacing: options.replaceRef, appendHistory: options.appendHistory)

            let nameList = names.joined(separator: ",")
            infoPrint("Attributes set in \(reference): \(nameList)")
        }
    }

    // MARK: Unset Attributes
    struct UnsetAttributes: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "unset",
                abstract: "Remove values of multiple attributes"
            )

        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        @Argument(help: "ID of an object to be modified")
        var reference: String

        @Argument(help: "Attributes to be unset")
        var names: [String]

        mutating func run() throws {
            let session = try DesignSession(location: globalOptions.designLocation)
            let trans = try session.createTransaction(deriving: options.deriveRef)

            guard let object = trans.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let mutableObject = trans.mutate(object.objectID)

            for name in names {
                mutableObject.removeAttribute(forKey: name)
            }

            try session.save(replacing: options.replaceRef, appendHistory: options.appendHistory)

            let nameList = names.joined(separator: ",")
            infoPrint("Attributes removed in \(reference): \(nameList)")
        }
    }

}

