//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore

// TODO: Add possibility of using multiple references

extension PoieticTool {
    struct Remove: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Remove an object – a node or a connection"
            )

        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        @Argument(help: "ID of an object to be removed")
        var reference: String

        
        mutating func run() throws {
            let editor = try DesignEditor(location: globalOptions.designLocation)
            let trans = try editor.deriveOrCreate(options.deriveRef)

            guard let object = trans.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let removed = trans.removeCascading(object.objectID)

            try editor.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try editor.save()

            print("Removed object: \(object.objectID)")
            if !removed.isEmpty {
                let list = removed.map { $0.stringValue }.joined(separator: ", ")
                print("Removed cascading: \(list)")
            }
        }
    }
}
