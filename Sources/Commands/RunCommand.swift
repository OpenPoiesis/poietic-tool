//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 17/07/2022.
//

@preconcurrency import ArgumentParser
import SystemPackage
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

        @Option(name: [.customLong("end-time")],
                help: "Final time, overrides design-specified end time")
        var endTime: Double?

        @Option(name: [.long, .customShort("s")],
                help: "Maximum number of steps to run, before end-time is reached")
        var steps: Int?
        
        @Option(name: [.long, .customShort("t")],
                help: "Time delta, overrides design-specified time delta")
        var timeDelta: Double?
        
        @Option(name: [.customLong("solver")],
                help: "Type of the solver to be used for computation")
        var solverName: String = "euler"

        enum OutputFormat: String, CaseIterable, ExpressibleByArgument{
            case csv = "csv"
//            case json = "json"
            case gnuplot = "gnuplot"
            var defaultValueDescription: String { "csv" }
            
            static var allValueStrings: [String] {
                OutputFormat.allCases.map { "\($0)" }
            }
        }
        @Option(name: [.long, .customShort("f")], help: "Output format")
        var outputFormat: OutputFormat = .csv

        // TODO: Deprecate
        @Option(name: [.customLong("variable"), .customShort("V")],
                help: "Values to observe in the output; can be object IDs or object names.")
        var outputNames: [String] = []

        // TODO: Deprecate
        @Option(name: [.customLong("constant"), .customShort("c")],
                       help: "Set (override) a value of a constant node in a form 'attribute=value'")
        var overrideValues: [String] = []

        @Option(name: [.customLong("frame")], help: "Frame to run")
        var frameRef: String?

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
            let env = try ToolEnvironment(location: options.designLocation)
            let stableFrame = try env.existingFrame(frameRef)

            let validFrame = try env.validate(stableFrame)
            
            guard let solverType = StockFlowSimulation.SolverType(rawValue: solverName) else {
                throw ToolError.unknownSolver(solverName)
            }

            let plan = try env.compile(validFrame)
            
            var parameters = plan.simulationParameters ?? SimulationParameters()
            
            if let timeDelta {
                parameters.timeDelta = timeDelta
            }
            
            if let endTime {
                parameters.endTime = endTime
            }
            
            if let startTime {
                parameters.initialTime = startTime
            }
            
            let simulation = StockFlowSimulation(plan, solver: solverType)
            let simulator = Simulator(simulation: simulation, parameters: parameters)

            // Collect names of nodes to be observed
            // -------------------------------------------------------------
            var outputVariables: [StateVariable] = []
            if outputNames.isEmpty {
                outputVariables = plan.stateVariables
            }
            else {
                var unknownNames: [String] = []
                for name in outputNames {
                    guard let variable = plan.stateVariables.first(where: { $0.name == name }) else {
                        unknownNames.append(name)
                        continue
                    }
                    outputVariables.append(variable)
                }
                guard unknownNames.isEmpty else {
                    throw ToolError.unknownVariables(unknownNames)
                }
            }

            // TODO: Add JSON for controls
            // Collect constants to be overridden during initialization.
            // -------------------------------------------------------------
            var overrideConstants: [ObjectID: Double] = [:]
            for item in overrideValues {
                guard let split = parseValueAssignment(item) else {
                    throw ToolError.invalidAttributeAssignment(item)
                }
                let (key, stringValue) = split
                guard let doubleValue = Double(stringValue) else {
                    throw ToolError.typeMismatch("constant override '\(key)'", stringValue, "double")
                }
                guard let variable = plan.variable(named: key) else {
                    throw ToolError.unknownObject(key)
                }
                overrideConstants[variable.objectID] = doubleValue
            }
            
            // Create and initialize the solver
            // -------------------------------------------------------------
            try simulator.initializeState(override: overrideConstants)
            
            // Run the simulation
            // -------------------------------------------------------------
            try simulator.run(steps)

            switch outputFormat {
            case .csv:
                try writeCSV(path: outputPath,
                             variables: outputVariables,
                             states: simulator.result.states)
            case .gnuplot:
                try writeGnuplotBundle(path: outputPath,
                                       compiledModel: plan,
                                       output: simulator.result.states)
//            case .json:
//                try writeJSON(path: outputPath,
//                              variables: outputVariables,
//                              states: simulator.output)
            }

            try env.close()
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
        writer = try CSVWriter(.standardOutput)
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

/// Write a Gnuplot directory bundle.
///
/// The function will create a directory at `path` if it does not exist and then
/// creates the following files:
///
/// - `output.csv` – all the simulation states
/// - `chart_NAME.gnuplot` – one file for every chart where the NAME is the
///    chart object name.
///
/// If the path is '-' then the current directory will be used.
///
func writeGnuplotBundle(path: String,
                        compiledModel: SimulationPlan,
                        output: [SimulationState]) throws {
    let path = if path == "-" { "." } else { path }
    let variables = compiledModel.stateVariables
    let fm = FileManager()
    try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
    let dataFileName = "output.csv"
    // Write all the output
    try writeCSV(path: path + "/" + dataFileName,
                 variables: compiledModel.stateVariables,
                 states: output)
    
    let timeIndex = variables.firstIndex { $0.name == "time" }!

    // Write chart output
    for chart in compiledModel.charts {
        
        let chartName = chart.node.name!
        // TODO: Plot all the series
        if chart.series.count > 1 {
            print("NOTE: Printing only the first series, multiple series is not yet supported")
        }
        guard let series = chart.series.first else {
            print("WARNING: Chart '\(chart.node.name ?? "(unnamed)")' has no series.")
            continue
        }
        let seriesIndex = variables.firstIndex { $0.name == series.name }!
        let imageFile = "chart_\(chartName).png"
        
        let gnuplotCommand =
        """
        set datafile separator ',';
        set key autotitle columnhead;
        set terminal png;
        set output '\(imageFile)';
        plot '\(dataFileName)' using \(timeIndex + 1):\(seriesIndex + 1) with lines;
        """

        let gnuplotCommandPath = path + "/" + "chart_\(chartName).gnuplot"
        let file = try FileDescriptor.open(gnuplotCommandPath,
                                           .writeOnly,
                                           options: [.truncate, .create],
                                           permissions: .ownerReadWrite)
        try file.writeAll(gnuplotCommand.utf8)
        try file.close()
    }
}
