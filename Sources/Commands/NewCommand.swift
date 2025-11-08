//
//  File.swift
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
                help: "Poietic frame to import into the first frame")
        var importPaths: [String] = []

        mutating func run() throws {
            let design = Design(metamodel: StockFlowMetamodel)
            let modeller = try ModellerTool(location: globalOptions.designLocation,
                                            design: design)

            if !importPaths.isEmpty {
                let loader = DesignLoader(metamodel: design.metamodel, options: .useIDAsNameAttribute)
                let frame = design.createFrame()

                for path in importPaths {
                    let rawDesign = try readRawDesign(fromPath: path)
                    print("Importing from: \(path)")
                    do {
                        // FIXME: [WIP] add which frame to load
                        try loader.load(rawDesign, into: frame)
                    }
                    catch {
                        throw ToolError.designLoaderError(error, URL(fileURLWithPath: path))
                    }
                }
                
                try modeller.accept(frame)
            }
            
            try modeller.save()
            if modeller.url.scheme == nil || modeller.url.scheme == "file" {
                print("Design created: \(modeller.url.path)")
            }
            else {
                print("Design created: \(modeller.url)")
            }
        }
    }
}

