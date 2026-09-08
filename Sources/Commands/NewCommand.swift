//
//  NewCommand.swift
//  
//
//  Created by Stefan Urbanek on 11/01/2022.
//

@preconcurrency import ArgumentParser
import PoieticFlows
import PoieticCore
import Foundation

extension PoieticTool {
    struct NewDesign: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "new",
            abstract: "Create an empty design."
        )
        
        @OptionGroup var globalOptions: Options

        @Option(name: [.customLong("import"), .customShort("i")],
                help: "Import from existing poietic designs. Current plane or the only plane is used.")
        var importPaths: [String] = []
        
        @Flag(name: [.customLong("force")],
              help: "Force rewrite existing design file")
        var force: Bool = false
        
        mutating func run() throws {
            let design = Design(metamodel: StockFlowDomain.StockFlowMetamodel)
            let session = try DesignSession(location: globalOptions.designLocation, design: design)

            let manager = FileManager()
            let path = session.url.path()
            guard force || !manager.fileExists(atPath: path) else {
                throw ToolError.fileAlreadyExists(path)
            }

            if !importPaths.isEmpty {
                let loader = DesignLoader(metamodel: design.metamodel, options: .useIDAsNameAttribute)
                let plane = session.createTransaction()

                for path in importPaths {
                    let rawDesign = try readRawDesign(fromPath: path)
                    infoPrint("Importing from: \(path)")
                    do {
                        try loader.load(rawDesign, into: plane)
                    }
                    catch {
                        throw ToolError.designLoaderError(error, URL(fileURLWithPath: path))
                    }
                }
            }
            
            try session.save()
            if session.url.scheme == nil || session.url.scheme == "file" {
                infoPrint("Design created: \(session.url.path)")
            }
            else {
                infoPrint("Design created: \(session.url)")
            }
        }
    }
}

