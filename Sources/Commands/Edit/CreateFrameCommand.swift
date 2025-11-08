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
        @OptionGroup var globalOptions: Options

        @Option(name: [.customLong("derive")], help: "Derive an existing frame")
        var derivingRef: String?

        @Option(help: "Create a named frame with given name")
        var name: String?

        @Option(name: [.customLong("id")], help: "Create a frame with given id")
        var requestedRef: String?

        @Flag(name: [.customLong("force")], help: "Replace existing frame")
        var force: Bool = false

        @Flag(name: [.customLong("append-history")], help: "Append frame to the undo history")
        var appendHistory: Bool = false

        mutating func run() throws {
            let modeller = try CommandLineModeller(location: globalOptions.designLocation)
            let design = modeller.design
            let requestedID: FrameID?
            let createdRef: String
            let derivingFrame = try modeller.frameIfPresent(derivingRef)

            if let ref = requestedRef, let frameID = FrameID(ref) {
                requestedID = frameID
                guard !design.containsFrame(frameID) else {
                    throw ToolError.frameExists(frameID.stringValue)
                }
            }
            else {
                requestedID = nil
            }
            
            if let name {
                guard design.frame(name: name) == nil || force else {
                    throw ToolError.frameExists(name)
                }
                let frame = createFrame(in: design, deriving: derivingFrame)
                try design.accept(frame, replacingName: name)
                createdRef = name
            }
            else if let requestedID {
                let frame = createFrame(in: design, deriving: derivingFrame, requestedID: requestedID)
                try design.accept(frame, appendHistory: appendHistory)
                createdRef = requestedID.stringValue
            }
            else {
                let frame = createFrame(in: design, deriving: derivingFrame)
                try design.accept(frame, appendHistory: appendHistory)
                createdRef = frame.id.stringValue
            }

            try modeller.save()

            print("Created frame \(createdRef)")
        }
    }
}

func createFrame(in design: Design, deriving: DesignFrame?, requestedID: FrameID? = nil) -> TransientFrame {
    if let deriving {
        return design.createFrame(deriving: deriving, id: requestedID)
    }
    else {
        return design.createFrame(id: requestedID)
    }
}
