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
                abstract: "Remove all planes in the undo/redo history and keep just the current plane. Other non-history related frames remain untouched."
            )

        @OptionGroup var globalOptions: Options

        mutating func run() throws {
            let editor = try DesignEditor(location: globalOptions.designLocation)
            let design = editor.design
            
            let count = design.undoList.count + design.redoList.count

            for frame in design.undoList {
                design.removePlane(frame)
            }
            for frame in design.redoList {
                design.removePlane(frame)
            }

            try editor.save()
            
            if count > 0 {
                print("Removed \(count) planes.")
            }
            else {
                print("History is empty, nothing removed.")
            }
        }
    }

}
