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

extension VariableNameFormat: ExpressibleByArgument {
    public init?(argument: String) {
        switch argument.lowercased() {
        case "normalized": self = .normalized
        case "display": self = .display
        default: return nil
        }
    }
    
    public var defaultValueDescription: String { "display" }

}

extension PoieticTool {
    struct Run: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Run the simulation and generate output")

        @OptionGroup var options: Options

        @Option(name: [.customLong("start-time")],
                help: "Initial time, overrides design-specified initial time")
        var startTime: Double?

        @Option(name: [.long],
                help: "Final simulation time, overrides design-specified end time")
        var finalTime: Double?

        @Option(name: [.long, .customShort("s")],
                help: "Maximum number of steps to run, before end-time is reached [DEPRECATED]")
        var steps: UInt?
        
        @Option(name: [.long, .customShort("t")],
                help: "Time step, overrides design-specified time step")
        var timeStep: Double?

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
                help: "Names of variables to observe in the output. If not specified: time plus all object variables")
        var outputNames: [String] = []
        
        @Flag(name: [.customLong("all-variables")],
              help: "Include internal and all built-in variables when no --variable is given")
        var includeAllVariables: Bool = false

        @Option(name: [.customLong("name-format")],
              help: "Format of output variable names")
        var nameFormat: VariableNameFormat = .display

        @Option(name: [.customLong("parameter"), .customShort("p")],
                       help: "Override a node value ('name=value') to a constant. For stocks and other accumulators: used only for initialisation.")
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
            
            var timeSettings: SimulationTimeSettings = world.singleton() ?? SimulationTimeSettings()
            var simSettings: SimulationSettings = world.singleton() ?? SimulationSettings()
            
            if let startTime { timeSettings.startTime = startTime }
            if let timeStep {
                guard timeStep > 0 else {
                    throw ToolError.invalidOption("time-step", "Time delta must be greater than 0")
                }
                timeSettings.timeStep = timeStep
            }
            if let finalTime {
                guard finalTime >= timeSettings.startTime else {
                    throw ToolError.invalidOption("end-time", "End time must be greater or equal than start time")
                }

                timeSettings.finalTime = finalTime
            }
            else if let steps {
                errorPrint("WARNING: Settings steps is deprecated, use --end-time")
                timeSettings.finalTime = timeSettings.startTime + timeSettings.timeStep * Double(steps)
            }

            simSettings.solverType = solverName
            
            // Collect names of nodes to be observed
            // -------------------------------------------------------------
            var outputVariables: [StateVariable] = []
            if outputNames.isEmpty {
                if includeAllVariables { outputVariables = plan.stateVariables }
                else                   { outputVariables = plan.defaultVariables }
            }
            else {
                let variables = plan.variables(named: outputNames, includeTime: true)
                guard variables.unknown.isEmpty else {
                    throw ToolError.unknownVariables(variables.unknown)
                }
                outputVariables = variables.known
            }

            // Collect parameters to be overridden
            // -------------------------------------------------------------
            var scenarioParams: [ObjectID: Variant] = [:]
            for item in overrideValues {
                guard let split = parseValueAssignment(item) else {
                    throw ToolError.invalidAttributeAssignment(item)
                }
                let (variableKey, stringValue) = split
                guard let doubleValue = Double(stringValue) else {
                    throw ToolError.typeMismatch("parameter override '\(variableKey)'", stringValue, "double")
                }
                let normalisedKey = NormalizedName.normalize(variableKey)
                guard let object = plan.simulationObject(withKey: normalisedKey) else {
                    throw ToolError.unknownObject(variableKey)
                }
                scenarioParams[object.objectID] = Variant(doubleValue)
            }
            let scenario = ScenarioParameters(values: scenarioParams)
            
            // Create and initialise the solver
            // -------------------------------------------------------------
            world.setSingleton(simSettings)
            world.setSingleton(timeSettings)
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
            
            // FIXME: Collect references instead of whole variables.
            switch outputFormat {
            case .csv:
                let view = SimulationResultView(result: result,
                                                selection: outputVariables.map {$0.reference} )
                try writeCSV(path: outputPath, view: view, nameFormat: nameFormat, world: world)
            case .gnuplot:
                let writer = GNUPlotBundleWriter()
                let coalescedPath = outputPath == "-" ? "." : outputPath
                try writer.write(result: result,
                                 toPath: coalescedPath,
                                 nameFormat: nameFormat,
                                 world: world)
//            case .json:
//                try writeJSON(path: outputPath,
//                              variables: outputVariables,
//                              states: simulator.output)
            }
        }
    }
}

