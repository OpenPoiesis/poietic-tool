//
//  ValidateCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 09/03/2025.
//

@preconcurrency import ArgumentParser
import PoieticFlows

extension PoieticTool {
    struct Validate: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Get information about the design")
        @OptionGroup var options: Options

        @Argument(help: "Frame ID or name to validate (current if not provided)")
        var frameRef: String?

        mutating func run() throws {
            let modeller = try CommandLineModeller(location: options.designLocation, configuration: .simulation)
            let frame = try modeller.frame(frameRef)
            let runtime = try modeller.updateRuntime(frame.id)
            
            guard let _ = runtime.frameComponent(SimulationPlan.self) else {
                printIssues(runtime)
                throw ToolError.designIssues(runtime.issues)
            }

            print("Frame is valid.")
        }
    }
}

