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
            let editor = try DesignEditor(location: globalOptions.designLocation)

            if !editor.design.canUndo {
                throw ToolError.noChangesToUndo
            }
            
            let frameID = editor.design.undoList.last!
            editor.design.undo(to: frameID)

            try editor.save()
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
            let editor = try DesignEditor(location: globalOptions.designLocation)

            if !editor.design.canRedo {
                throw ToolError.noChangesToRedo
            }
            
            let frameID = editor.design.redoList.first!
            editor.design.redo(to: frameID)

            try editor.save()
            print("Did redo.")
        }
    }
}
