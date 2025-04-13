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
            let env = try ToolEnvironment(location: globalOptions.designLocation)
            let trans = try env.deriveOrCreate(options.deriveRef)

            guard let object = trans.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let removed = trans.removeCascading(object.id)

            try env.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try env.close()

            print("Removed object: \(object.id)")
            if !removed.isEmpty {
                let list = removed.map { $0.stringValue }.joined(separator: ", ")
                print("Removed cascading: \(list)")
            }
//            print("Current frame ID: \(design.currentFrame.id)")
        }
    }
}
