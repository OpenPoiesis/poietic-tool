//
//  RemoveFrameCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 28/03/2025.
//


@preconcurrency import ArgumentParser
import PoieticCore

// TODO: Add possibility of using multiple references

extension PoieticTool {
    struct RemoveFrame: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Remove a plane"
            )

        @OptionGroup var globalOptions: Options

        @Argument(help: "IDs or names of planes to be removed")
        var references: [String]
        
        mutating func run() throws {
            let editor = try DesignEditor(location: globalOptions.designLocation)

            guard editor.design.planes.count > 0 else {
                throw ToolError.emptyDesign
            }
            guard !references.isEmpty else {
                print("Nothing to be removed")
                return
            }

            var toRemove: [PlaneID] = []
            
            for ref in references {
                if let id = editor.design.plane(name: ref)?.id {
                    toRemove.append(id)
                }
                else if let id = PlaneID(ref),
                        editor.design.containsPlane(id)
                {
                    toRemove.append(id)
                }
                else {
                    throw ToolError.unknownFrame(ref)
                }
            }

            for id in toRemove {
                editor.design.removePlane(id)
            }

            try editor.save()
            print("Removed \(toRemove.count) planes.")
        }
    }
}
