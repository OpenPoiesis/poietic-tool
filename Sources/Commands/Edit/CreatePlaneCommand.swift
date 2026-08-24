//
//  CreatePlaneCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 28/03/2025.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Add import

extension PoieticTool {
    struct CreatePlane: ParsableCommand {
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

        // TODO: [REFACTORING] Should we call this --plane to be aligned with others? It has other meaning here though.
        @Option(name: [.customLong("derive")], help: "Derive an existing plane")
        var derivingRef: String?

        @Option(help: "Create a named plane with given name")
        var name: String?

        @Option(name: [.customLong("id")], help: "Create a plane with given id")
        var requestedRef: String?

        @Flag(name: [.customLong("force")], help: "Replace existing named plane")
        var force: Bool = false

        @Flag(name: [.customLong("append-history")], help: "Append plane to the undo history")
        var appendHistory: Bool = false

        mutating func run() throws {
            let session = try DesignSession(location: globalOptions.designLocation)
            let design = session.design
            let requestedID: PlaneID?
            let createdRef: String

            let original: DesignPlane?
            if let derivingRef {
                original = try session.plane(derivingRef)
            }
            else {
                original = nil
            }

            if let ref = requestedRef, let planeID = PlaneID(ref) {
                guard !session.design.containsPlane(planeID)
                else {
                    throw ToolError.planeExists(planeID.stringValue)
                }
                requestedID = planeID
            }
            else {
                requestedID = nil
            }
            
            if let name {
                guard design.plane(name: name) == nil || force else {
                    throw ToolError.planeExists(name)
                }
                let plane = design.createPlane(deriving: original)
                try design.accept(plane, replacingName: name)
                createdRef = name
            }
            else if let requestedID {
                let plane = design.createPlane(deriving: original, id: requestedID)
                try design.accept(plane, appendHistory: appendHistory)
                createdRef = requestedID.stringValue
            }
            else {
                let plane = design.createPlane(deriving: original)
                try design.accept(plane, appendHistory: appendHistory)
                createdRef = plane.id.stringValue
            }

            try session.save()

            print("Created plane \(createdRef)")
        }
    }
}
