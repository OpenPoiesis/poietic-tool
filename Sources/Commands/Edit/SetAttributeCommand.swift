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
    struct SetAttributes: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "set",
                abstract: "Set value of one or more attributes of an object.",
                //  ^--------|---------|---------|---------|---------|---------|---------|---------$
                discussion: """
                    Sets attributes of an object specified by its name or ID. The attributes are
                    listed in form: attribute=value.
                    
                    Examples:
                    
                    poietic edit set fish formula=1000 color=azure
                    poietic edit set fish_birth_rate formula="coeficient * fish"
                    poietic edit set shark position="[100,150]"
                    """
            )

        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        @Argument(help: "ID of an object to be modified")
        var reference: String

        @Argument(help: "Attributes to set in form: attribute=value")
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

