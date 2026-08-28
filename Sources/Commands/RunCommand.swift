//
//  RunCommand.swift
//  
//
//  Created by Stefan Urbanek on 17/07/2022.
//

@preconcurrency import ArgumentParser
import Foundation

import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Run: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Run the simulation and generate output")

        @OptionGroup var options: Options

        @Option(name: [.customLong("start-time")],
                help: "Initial time, overrides design-specified initial time")
        var startTime: Double?

        @Option(name: [.long, .customShort("s")],
                help: "Maximum number of steps to run, before end-time is reached")
        var steps: UInt?
        
        @Option(name: [.long, .customShort("t")],
                help: "Time delta, overrides design-specified time delta")
        var timeDelta: Double?
        
        @Option(name: [.customLong("solver")],
                help: "Solver to use: euler, rk4 (default: euler)")
        var solverName: String = "euler"

        enum OutputFormat: String, CaseIterable, ExpressibleByArgument{
            case csv = "csv"
            case gnuplot = "gnuplot"
            // case json = "json"

            var defaultValueDescription: String { "csv" }
            
            static var allValueStrings: [String] {
                OutputFormat.allCases.map { "\($0)" }
            }
        }
        @Option(name: [.long, .customShort("f")], help: "Output format")
        var outputFormat: OutputFormat = .csv

        @Option(name: [.customLong("variable"), .customShort("V")],
                help: "Variables to observe in the output; can be object IDs or object names. If not specified: time plus all object variables")
        var outputNames: [String] = []
        
        @Flag(name: [.customLong("all-variables")],
              help: "Include internal and all built-in variables when no --variable is given")
        var includeAllVariables: Bool = false

        @Option(name: [.customLong("parameter"), .customShort("p")],
                       help: "Set (override) a numeric value of a parameter node in a form 'object_name=value'")
        var overrideValues: [String] = []

        @Option(name: [.customLong("plane")], help: "Plane name or ID to run. Default: current plane")
        var planeRef: String?

        /// Path to the output directory.
        /// The generated files are:
        /// out/
        ///     simulation.csv
        ///     chart-NAME.csv
        ///     data-NAME.csv
        ///
        /// output format:
        ///     - simple: full state only, as CSV
        ///     - json: full state with all outputs as structured JSON
        ///     - dir: directory with all outputs as CSVs (no stdout)
        ///
        @Option(name: [.customLong("output"), .customShort("o")], help: "Output path. Default or '-' is standard output.")
        var outputPath: String = "-"
        
        mutating func run() throws {
            let session = try DesignSession(location: options.designLocation)
            try session.setPlane(planeRef)
            let world = session.world
            
            try world.run(schedule: PlanSchedule.self)
            
            guard let plan: SimulationPlan = world.singleton() else {
                printIssues(world)
                throw ToolError.designIssues(world.issues)
            }
            
            var settings: SimulationSettings = world.singleton() ?? SimulationSettings()
            
            if let startTime { settings.initialTime = startTime }
            if let timeDelta { settings.timeDelta = timeDelta }
            if let steps     { settings.steps = steps }

            settings.solverType = solverName
            
            // Collect names of nodes to be observed
            // -------------------------------------------------------------
            var outputVariables: [StateVariable] = []
            if outputNames.isEmpty {
                if includeAllVariables {
                    outputVariables = plan.stateVariables
                }
                else {
                    outputVariables = plan.stateVariables.filter {
                        $0.kind == .object || ($0.kind == .builtin && $0.name == "time")
                    }
                }
            }
            else {
                var unknownNames: [String] = []
                for name in outputNames {
                    guard let variable = plan.variable(named: name) else {
                        unknownNames.append(name)
                        continue
                    }
                    outputVariables.append(variable)
                }
                guard unknownNames.isEmpty else {
                    throw ToolError.unknownVariables(unknownNames)
                }
            }

            // Collect parameters to be overridden during initialisation.
            // -------------------------------------------------------------
            var scenarioParams: [ObjectID: Variant] = [:]
            for item in overrideValues {
                guard let split = parseValueAssignment(item) else {
                    throw ToolError.invalidAttributeAssignment(item)
                }
                let (key, stringValue) = split
                guard let doubleValue = Double(stringValue) else {
                    throw ToolError.typeMismatch("parameter override '\(key)'", stringValue, "double")
                }
                guard let object = plan.simulationObject(named: key) else {
                    throw ToolError.unknownObject(key)
                }
                if object.role != .stock {
                    // FIXME: [IMPORTANT] This must be fixed in Flows
                    errorPrint("Warning: '\(key)' is not a stock; -p currently applies only to the initial value and is overwritten by its formula from step 1.")
                }
                scenarioParams[object.objectID] = Variant(doubleValue)
            }
            let scenario = ScenarioParameters(initialValues: scenarioParams)
            
            // Create and initialise the solver
            // -------------------------------------------------------------
            world.setSingleton(settings)
            world.setSingleton(scenario)
            
            // Run the simulation
            // -------------------------------------------------------------
            do {
                try world.run(schedule: SimulateSchedule.self)
            }
            catch {
                throw ToolError.simulationFailed(error.message)
            }
            
            guard let result: SimulationResult = world.singleton() else {
                // This should not happen, if the simulation system does not throw, then we get result.
                // TODO: Once we have simulation errors set on objects, use them. We do not have them yet.
                throw ToolError.internalError("Unknown error (no result produced)")
            }
            
            switch outputFormat {
            case .csv:
                try writeCSV(path: outputPath,
                             variables: outputVariables,
                             states: result.states)
            case .gnuplot:
                let writer = GNUPlotBundleWriter()
                let coalescedPath = outputPath == "-" ? "." : outputPath
                try writer.write(result: result, toPath: coalescedPath, world: world)
//            case .json:
//                try writeJSON(path: outputPath,
//                              variables: outputVariables,
//                              states: simulator.output)
            }
        }
    }
}

func writeCSV(path: String,
              variables: [StateVariable],
              states: [SimulationState]) throws {
    let header: [String] = variables.map { $0.name }

    // TODO: Step
    let writer: CSVWriter
    if path == "-" {
        writer = CSVWriter(.standardOutput)
    }
    else {
        writer = try CSVWriter(path: path)
    }
    try writer.write(row: header)
    for state in states {
        var row: [String] = []
        for variable in variables {
            let value: Variant = state[variable.index]
            row.append(try value.stringValue())
        }
        try writer.write(row: row)
    }
    try writer.close()
    
}

