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

        @Argument(help: "Plane ID or name to validate (current if not provided)")
        var planeRef: String?

        mutating func run() throws {
            let editor = try DesignSession(location: options.designLocation)
            let plane = try editor.plane(planeRef)
            let world = editor.world
            try world.run(schedule: PlanSchedule.self)
            
            guard let _: SimulationPlan = world.singleton() else {
                printIssues(world)
                throw ToolError.designIssues(world.issues)
            }

            print("Plane is valid.")
        }
    }
}

