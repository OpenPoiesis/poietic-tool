//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 04/07/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

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
            let modeller = try CommandLineModeller(location: globalOptions.designLocation)
            let original = try modeller.createRuntime(frameReference: options.deriveRef)
            let trans = try modeller.deriveOrCreate(options.deriveRef)

            let systems = SystemGroup(
                ComputationOrderSystem.self,
                NameResolutionSystem.self,
                ExpressionParserSystem.self,
                ParameterResolutionSystem.self,
            )

            try systems.update(original)
            let result = try autoConnectParameters(runtime: original, trans: trans)
            if verbose {
                for info in result.added {
                    print("Connected parameter \(info.parameterName ?? "(unnamed)") (\(info.parameterID)) to \(info.targetName ?? "(unnamed)") (\(info.targetID)), edge: \(info.edgeID)")
                }
                for info in result.removed {
                    print("Disconnected parameter \(info.parameterName ?? "(unnamed)") (\(info.parameterID)) from \(info.targetName ?? "(unnamed)") (\(info.targetID)), edge: \(info.edgeID)")
                }
            }

            if result.added.count + result.removed.count > 0 {
                try modeller.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
                try modeller.save()
                print("Added \(result.added.count) edges and removed \(result.removed.count) edges.")
            }
            else {
                print("All parameter connections seem to be ok.")
            }
        }
    }

}
