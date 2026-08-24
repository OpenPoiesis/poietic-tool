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
            = CommandConfiguration(abstract: "Validate design or a single plane")
        @OptionGroup var options: Options

        @Option(name: [.customLong("plane")], help: "Plane to be validated. Default: current plane.")
        var planeReference: String?

        mutating func run() throws {
            let editor = try DesignSession(location: options.designLocation)
            let world = editor.world

            let plane = try editor.plane(planeReference)
            world.setPlane(plane)

            try world.run(schedule: PlanSchedule.self)
            
            guard let _: SimulationPlan = world.singleton() else {
                printIssues(world)
                throw ToolError.designIssues(world.issues)
            }

            print("Plane is valid.")
        }
    }
}

