//
//  RemovePlaneCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 28/03/2025.
//


@preconcurrency import ArgumentParser
import PoieticCore

// TODO: Add possibility of using multiple references

extension PoieticTool {
    struct RemovePlane: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Remove a plane"
            )

        @OptionGroup var globalOptions: Options

        @Argument(help: "IDs or names of planes to be removed")
        var references: [String]
        
        mutating func run() throws {
            let session = try DesignSession(location: globalOptions.designLocation)

            guard !references.isEmpty else {
                print("Nothing to be removed")
                return
            }

            var toRemove: [PlaneID] = []
            
            for ref in references {
                let plane = try session.plane(ref)
                toRemove.append(plane.id)
            }

            for id in toRemove {
                session.design.removePlane(id)
            }

            try session.save()
            print("Removed \(toRemove.count) planes.")
        }
    }
}
