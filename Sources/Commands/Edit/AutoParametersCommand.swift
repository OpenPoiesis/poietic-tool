//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore

extension PoieticTool {
    struct AutoParameters: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "auto-parameters",
                abstract: "Automatically connect parameter nodes: connect required, disconnect unused"
            )

        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        @Flag(name: [.customLong("verbose"), .customShort("v")],
                help: "Print created and removed edges")
        var verbose: Bool = false

        mutating func run() throws {
            let env = try ToolEnvironment(location: globalOptions.designLocation)
            let trans = try env.deriveOrCreate(options.deriveRef)

            let result = try autoConnectParameters(trans)
            
            if verbose {
                for info in result.added {
                    print("Connected parameter \(info.parameterName ?? "(unnamed)") (\(info.parameterID)) to \(info.targetName ?? "(unnamed)") (\(info.targetID)), edge: \(info.edgeID)")
                }
                for info in result.removed {
                    print("Disconnected parameter \(info.parameterName ?? "(unnamed)") (\(info.parameterID)) from \(info.targetName ?? "(unnamed)") (\(info.targetID)), edge: \(info.edgeID)")
                }
            }

            try env.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try env.close()
            
            if result.added.count + result.removed.count > 0 {
                print("Added \(result.added.count) edges and removed \(result.removed.count) edges.")
            }
            else {
                print("All parameter connections seem to be ok.")
            }
        }
    }

}
