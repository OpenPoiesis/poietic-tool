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
            let session = try DesignSession(location: globalOptions.designLocation)

            if !session.design.canUndo {
                throw ToolError.noChangesToUndo
            }
            
            let frameID = session.design.undoList.last!
            session.design.undo(to: frameID)

            try session.save()
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
            let session = try DesignSession(location: globalOptions.designLocation)

            if !session.design.canRedo {
                throw ToolError.noChangesToRedo
            }
            
            let frameID = session.design.redoList.first!
            session.design.redo(to: frameID)

            try session.save()
            print("Did redo.")
        }
    }
}
