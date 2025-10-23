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
        enum IdentityMode: String, CaseIterable, ExpressibleByArgument{
            case require = "require" // requireProvided
            case auto = "auto" // preserveOrCreate
            case create = "create" // createNew

            var defaultValueDescription: String { "require" }
            
            static var allValueStrings: [String] {
                IdentityMode.allCases.map { $0.rawValue }
            }
        }
        @Option(name: [.customLong("identity")], help: "Object identity mode")
        var identityMode: IdentityMode = .require
        
        @Argument(help: "Path to a poietic design to import from")
        var fileName: String
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: globalOptions.designLocation)
            let trans = try env.deriveOrCreate(options.deriveRef)

            let rawDesign = try readRawDesign(fromPath: fileName)
            let loader = DesignLoader(metamodel: StockFlowMetamodel, options: .useIDAsNameAttribute)
            let strategy: DesignLoader.IdentityStrategy

            switch identityMode {
            case .require: strategy = .requireProvided
            case .auto: strategy = .preserveOrCreate
            case .create: strategy = .preserveOrCreate
            }

            do {
                try loader.load(rawDesign, into: trans, identityStrategy: strategy)
            }
            catch {
                throw ToolError.designLoaderError(error, URL(fileURLWithPath: fileName))
            }

            try env.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try env.closeAndSave()
        }
    }
}

