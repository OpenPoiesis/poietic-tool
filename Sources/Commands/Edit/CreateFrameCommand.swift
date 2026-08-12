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
                commandName: "create-plane",
                abstract: "Create a new plane",
                usage: """
Create a new plane and make it the current plane, previous plane is added to the history:

    poietic edit create-plane

Create a named plane, not added to the history. Plane with given name must not exist.

    poietic edit create-plane --name settings

Create a named plane, replacing existing named plane:

    poietic edit create-plane --force --name settings

Note: Plane with requested IDs can not be --forced to be replaced. Remove the plane first.

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

        @Option(name: [.customLong("derive")], help: "Derive an existing plane")
        var derivingRef: String?

        @Option(help: "Create a named plane with given name")
        var name: String?

        @Option(name: [.customLong("id")], help: "Create a plane with given id")
        var requestedRef: String?

        @Flag(name: [.customLong("force")], help: "Replace existing plane")
        var force: Bool = false

        @Flag(name: [.customLong("append-history")], help: "Append plane to the undo history")
        var appendHistory: Bool = false

        mutating func run() throws {
            let editor = try DesignEditor(location: globalOptions.designLocation)
            let design = editor.design
            let requestedID: PlaneID?
            let createdRef: String
            let derivingFrame = try editor.frameIfPresent(derivingRef)

            if let ref = requestedRef, let frameID = PlaneID(ref) {
                requestedID = frameID
                guard !design.containsPlane(frameID) else {
                    throw ToolError.frameExists(frameID.stringValue)
                }
            }
            else {
                requestedID = nil
            }
            
            if let name {
                guard design.plane(name: name) == nil || force else {
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

            try editor.save()

            print("Created plane \(createdRef)")
        }
    }
}

func createFrame(in design: Design, deriving: DesignPlane?, requestedID: PlaneID? = nil) -> TransientPlane {
    if let deriving {
        return design.createPlane(deriving: deriving, id: requestedID)
    }
    else {
        return design.createPlane(id: requestedID)
    }
}
