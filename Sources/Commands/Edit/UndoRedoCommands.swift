//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore

extension PoieticTool {
    struct Undo: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Undo last change"
            )

        @OptionGroup var globalOptions: Options

        mutating func run() throws {
            let modeller = try CommandLineModeller(location: globalOptions.designLocation)

            if !modeller.design.canUndo {
                throw ToolError.noChangesToUndo
            }
            
            let frameID = modeller.design.undoList.last!
            modeller.design.undo(to: frameID)

            try modeller.save()
            print("Did undo")
        }
    }

}

extension PoieticTool {
    struct Redo: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Redo undone change"
            )

        @OptionGroup var globalOptions: Options

        mutating func run() throws {
            let modeller = try CommandLineModeller(location: globalOptions.designLocation)

            if !modeller.design.canRedo {
                throw ToolError.noChangesToRedo
            }
            
            let frameID = modeller.design.redoList.first!
            modeller.design.redo(to: frameID)

            try modeller.save()
            print("Did redo.")
        }
    }
}
