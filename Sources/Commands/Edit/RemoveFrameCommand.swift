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
                abstract: "Remove a frame"
            )

        @OptionGroup var globalOptions: Options

        @Argument(help: "IDs or names of frames to be removed")
        var references: [String]
        
        mutating func run() throws {
            let modeller = try CommandLineModeller(location: globalOptions.designLocation)

            guard modeller.design.frames.count > 0 else {
                throw ToolError.emptyDesign
            }
            guard !references.isEmpty else {
                print("Nothing to be removed")
                return
            }

            var toRemove: [FrameID] = []
            
            for ref in references {
                if let id = modeller.design.frame(name: ref)?.id {
                    toRemove.append(id)
                }
                else if let id = FrameID(ref),
                        modeller.design.containsFrame(id)
                {
                    toRemove.append(id)
                }
                else {
                    throw ToolError.unknownFrame(ref)
                }
            }

            for id in toRemove {
                modeller.design.removeFrame(id)
            }

            try modeller.save()
            print("Removed \(toRemove.count) frames.")
        }
    }
}
