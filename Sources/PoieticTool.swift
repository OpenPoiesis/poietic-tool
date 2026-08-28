//
//  PoieticTool.swift
//
//
//  Created by Stefan Urbanek on 27/06/2023.
//

@preconcurrency import ArgumentParser

// The Command
// ------------------------------------------------------------------------

@main
struct PoieticTool: ParsableCommand {
    
    // IMPORTANT: Keep this in sync with Core and with git tag
    static let Version: String = "0.8"
    
    static let configuration = CommandConfiguration(
        commandName: "poietic",
        abstract: "Poietic tool to edit and run poietic designs",
        version: Version,
        subcommands: [
            NewDesign.self,
            Info.self,
            List.self,
            Show.self,
            Validate.self,
            Edit.self,
            Import.self,
            Export.self,
            Run.self,
            WriteDOT.self,
            MetamodelCommand.self,
            BuiltinsCommand.self,
            CreateLibrary.self,
            ExportSVG.self,
        ]
    )
}

struct Options: ParsableArguments {
    @Option(name: [.customLong("design"), .customShort("d")], help: "Path to a design file. If not provided, then \(DesignEnvironmentVariable) environment variable or 'design.poietic' is used")
    var designLocation: String?
}
