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

        @OptionGroup var options: Options

        @Argument(help: "ID of an object to be removed")
        var reference: String

        
        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            guard let currentFrame = env.design.currentFrame else {
                throw ToolError.emptyDesign
            }
            
            let frame = env.design.createFrame(deriving: currentFrame)

            guard let object = frame.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }

            let removed = frame.removeCascading(object.id)

            try env.accept(frame)
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
