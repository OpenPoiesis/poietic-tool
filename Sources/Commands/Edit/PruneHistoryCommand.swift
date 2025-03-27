//
//  PruneHistoryCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 27/03/2025.
//

@preconcurrency import ArgumentParser
import PoieticCore

// TODO: Allow pruning options, such as only non-simulation related changes (position/style)

extension PoieticTool {
    struct PruneHistory: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "prune-history",
                abstract: "Remove all frames in the undo/redo history and keep just the current frame. Other non-history related frames remain untouched."
            )

        @OptionGroup var options: Options

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)

            let count = env.design.undoableFrames.count + env.design.redoableFrames.count

            for frame in env.design.undoableFrames {
                env.design.removeFrame(frame)
            }
            for frame in env.design.redoableFrames {
                env.design.removeFrame(frame)
            }

            try env.close()
            
            if count > 0 {
                print("Removed \(count) frames.")
            }
            else {
                print("History is empty, nothing removed.")
            }
        }
    }

}
