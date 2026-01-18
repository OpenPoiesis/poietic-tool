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
            let editor = try DesignEditor(location: options.designLocation)
            let frame = try editor.frame(frameRef)
            let world = editor.world
            try world.run(schedule: PlanSchedule.self)
            
            guard let _: SimulationPlan = world.singleton() else {
                printIssues(world)
                throw ToolError.designIssues(world.issues)
            }

            print("Frame is valid.")
        }
    }
}

