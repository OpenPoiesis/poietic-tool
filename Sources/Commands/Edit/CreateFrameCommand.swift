//
//  CreateFrameCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 28/03/2025.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Add import

extension PoieticTool {
    struct CreateFrame: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "create-frame",
                abstract: "Create a new frame",
                usage: """
Create a new frame and make it the current frame, previous frame is added to the history:

    poietic edit create-frame

Create a named frame, not added to the history. Frame with given name must not exist.

    poietic edit create-frame --name settings

Create a named frame, replacing existing named frame:

    poietic edit create-frame --force --name settings

Note: Frame with requested IDs can not be --forced to be replaced. Remove the frame first.

"""
            )

        // TODO: Make sure only valid combinations are allowed
        // Valid combinations:
        //  - id + deriving + append-history
        //  - name + force
        // Invalid:
        //  - id + force
        //  - name + append-history
        //
        @OptionGroup var options: Options

        @Option(help: "Create a named frame with given name")
        var name: String?

        @Option(name: [.customLong("id")], help: "Create a frame with given id")
        var requestedRef: String?

        @Option(name: [.customLong("derive")], help: "Derive an existing frame")
        var derivingRef: String?

        @Flag(name: [.customLong("force")], help: "Replace existing frame")
        var force: Bool = false

        @Flag(name: [.customLong("append-history")], help: "Append frame to the undo history")
        var appendHistory: Bool = false

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let requestedID: ObjectID?
            let createdRef: String
            let derivingFrame: StableFrame?
            
            if let derivingRef {
                if let frame = env.frame(derivingRef) {
                    derivingFrame = frame
                }
                else {
                    throw ToolError.unknownFrame(derivingRef)
                }
            }
            else {
                derivingFrame = nil
            }
            
            if let ref = requestedRef, let id = ObjectID(ref) {
                requestedID = id
            }
            else {
                requestedID = nil
            }
            
            if let name {
                if env.design.frame(name: name) != nil && !force {
                    throw ToolError.frameExists(name)
                }
                let frame = env.design.createFrame(deriving: derivingFrame)
                try env.design.accept(frame, replacingName: name)
                createdRef = name
            }
            else if let requestedID {
                if env.design.containsFrame(requestedID) {
                    // TODO: Allow force?
                    throw ToolError.frameExists(requestedID.stringValue)
                }
                let frame = env.design.createFrame(deriving: derivingFrame, id: requestedID)
                try env.design.accept(frame, appendHistory: appendHistory)
                createdRef = requestedID.stringValue
            }
            else {
                let frame = env.design.createFrame(deriving: derivingFrame)
                try env.design.accept(frame, appendHistory: appendHistory)
                createdRef = frame.id.stringValue
            }

            try env.closeAndSave()

            print("Created frame \(createdRef)")
        }
    }
}
