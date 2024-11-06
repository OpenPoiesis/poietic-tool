//
//  PoieticTool.swift
//
//
//  Created by Stefan Urbanek on 27/06/2023.
//

import PoieticCore

@preconcurrency import ArgumentParser

// The Command
// ------------------------------------------------------------------------

@main
struct PoieticTool: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "poietic",
        abstract: "Poietic tool to edit and run poietic designs",
        subcommands: [
            CreateDB.self,
            Info.self,
            List.self,
            Show.self,
            Edit.self,
//            Print.self,
            Import.self,
//            Export.self,
            Run.self,
            WriteDOT.self,
            MetamodelCommand.self,
            CreateLibrary.self,
        ]
    )
}

struct Options: ParsableArguments {
    @Option(name: [.customLong("design"), .customShort("d")], help: "Path to a design file. If not provided, then \(DesignEnvironmentVariable) environment variable or 'design.poietic' is used")
    var designLocation: String?
}
