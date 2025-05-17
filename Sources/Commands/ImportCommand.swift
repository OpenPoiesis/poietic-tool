//
//  Import.swift
//  
//
//  Created by Stefan Urbanek on 14/08/2023.
//

@preconcurrency import ArgumentParser
import Foundation
import PoieticCore
import PoieticFlows

// TODO: Merge with PrintCommand, use --format=id
extension PoieticTool {
    struct Import: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Import a frame into the design")
        
        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        // TODO: Specify which frame to import from a multi-frame file
        // TODO: Fail on multi-frame file without current frame
        
        @Argument(help: "Path to a poietic design to import from")
        var fileName: String
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: globalOptions.designLocation)
            let trans = try env.deriveOrCreate(options.deriveRef)

            let rawDesign = try readRawDesign(fromPath: fileName)
            let loader = DesignLoader(metamodel: StockFlowMetamodel, options: .useIDAsNameAttribute)
            do {
                // FIXME: [WIP] add which frame to load
                try loader.load(rawDesign.snapshots, into: trans)
            }
            catch {
                throw ToolError.designLoaderError(error, URL(fileURLWithPath: fileName))
            }

            try env.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try env.closeAndSave()
        }
    }
}

