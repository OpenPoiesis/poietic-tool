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
            = CommandConfiguration(abstract: "Import a plane into the design")
        
        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        // TODO: Specify which plane to import from a multi-plane file
        // TODO: Fail on multi-plane file without current plane
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
            let editor = try DesignEditor(location: globalOptions.designLocation)
            let trans = try editor.deriveOrCreate(options.deriveRef)

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

            try editor.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try editor.save()
        }
    }
}

