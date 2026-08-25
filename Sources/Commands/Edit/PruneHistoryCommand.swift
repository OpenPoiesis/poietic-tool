//
//  PruneHistoryCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 27/03/2025.
//

@preconcurrency import ArgumentParser
import PoieticCore

// TODO: Allow "smart" pruning options, such as only non-simulation related changes (position/style); requires plane diffing

extension PoieticTool {
    struct PruneHistory: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "prune-history",
                abstract: "Remove all planes in the undo/redo history and keep just the current plane. Other non-history related planes remain untouched."
            )

        @OptionGroup var globalOptions: Options

        // TODO: [REFACTORING] Add this
//        @Option(name: [.customLong("keep")], help: "Keep at most given number of planes in the undo history")
//        var keep: UInt = 0

        mutating func run() throws {
            let session = try DesignSession(location: globalOptions.designLocation)
            let design = session.design
            
            let count = design.undoList.count + design.redoList.count

            for plane in design.undoList {
                design.removePlane(plane)
            }
            for plane in design.redoList {
                design.removePlane(plane)
            }

            try session.save()
            
            if count > 0 {
                infoPrint("Removed \(count) planes.")
            }
            else {
                infoPrint("History is empty, nothing removed.")
            }
        }
    }

}
