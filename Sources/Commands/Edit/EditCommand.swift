//
//  InspectCommand.swift
//
//
//  Created by Stefan Urbanek on 29/06/2023.
//

@preconcurrency import ArgumentParser

struct EditOptions: ParsableArguments {
    @Option(name: [.customLong("derive")], help: "Frame ID or name to derive from. If not provided, current is used")
    var deriveRef: String?

    @Option(name: [.customLong("replace")], help: "Frame name to replace")
    var replaceRef: String?

    @Flag(name: [.customLong("append-history")], inversion:.prefixedNo, help: "If true, then the frame will be added to history (if not named)")
    var appendHistory: Bool = true
}

extension PoieticTool {
    struct Edit: ParsableCommand {
        static let configuration
        = CommandConfiguration(
            abstract: "Edit an object or a selection of objects",
            subcommands: [
                SetAttribute.self,
                Undo.self,
                Redo.self,
                Add.self,
                NewConnection.self,
                Remove.self,
                AutoParameters.self,
                Layout.self,
                Align.self,
                PruneHistory.self,
                CreateFrame.self,
                RemoveFrame.self,
            ]
        )
    }
}

