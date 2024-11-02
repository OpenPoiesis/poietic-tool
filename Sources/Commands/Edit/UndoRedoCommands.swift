//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Undo: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Undo last change"
            )

        @OptionGroup var options: Options

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)

            if !env.design.canUndo {
                throw ToolError.noChangesToUndo
            }
            
            let frameID = env.design.undoableFrames.last!
            env.design.undo(to: frameID)

            try env.close()
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

        @OptionGroup var options: Options

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)

            if !env.design.canRedo {
                throw ToolError.noChangesToRedo
            }
            
            let frameID = env.design.redoableFrames.first!
            env.design.redo(to: frameID)

            try env.close()
            print("Did redo.")
        }
    }

}
