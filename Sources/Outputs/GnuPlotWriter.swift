//
//  GnuPlotWriter.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore
import PoieticFlows
import Foundation

func writeToCSV(path: String,
                result: SimulationResult,
                plan: SimulationPlan,
                ids: [PoieticCore.ObjectID])
throws {
    var variableIndices: [Int] = []
    variableIndices.append(plan.builtins.step)
    variableIndices.append(plan.builtins.time)
    
    if ids.isEmpty {
        variableIndices += Array(plan.stateVariables.indices)
    }
    else {
        variableIndices += ids.compactMap { plan.variableIndex(of: $0) }
    }

    let writer: CSVWriter = try CSVWriter(path: path)
    let header: [String] = variableIndices.map { plan.stateVariables[$0].name }

    try writer.write(row: header)
    
    for state in result.states {
        var row: [String] = []
        for index in variableIndices {
            let value: PoieticCore.Variant = state[index]
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
/// - `data.csv` – all the simulation states
/// - `chart_NAME.gnuplot` – one file for every chart where the NAME is the
///    chart object name.
///
/// If the path is '-' then the current directory will be used.
///
class GNUPlotBundleWriter {
    let dataFileName: String

    init(dataFileName: String = "data.csv") {
        self.dataFileName = dataFileName
    }
    
    public func write(result: SimulationResult, toPath path: String, frame: RuntimeFrame) throws {
        guard let plan = frame.frameComponent(SimulationPlan.self) else {
            return
        }
        let fm = FileManager()
        try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
        
        let objectIDs = plan.simulationObjects.compactMap(\.objectID)
        
        try writeToCSV(
            path: path + "/" + dataFileName,
            result: result,
            plan: plan,
            ids: objectIDs)

        for (chartID, chart) in frame.filter(ChartComponent.self) {
            let chartName = chart.name ?? "unnamed_\(chartID)"
            let gnuplotCommand = chartCommand(chart: chart, plan: plan)
            let gnuplotCommandPath = path + "/" + "chart_\(chartName).gnuplot"

            guard let data = gnuplotCommand.data(using: .utf8) else {
                continue
            }
            try data.write(to: URL(filePath: gnuplotCommandPath))
        }
    }
    func chartCommand(chart: ChartComponent, plan: SimulationPlan) -> String {
        
        let chartName = chart.name ?? "unnamed_\(chart.chartObject.objectID)"
        let imageFile = "chart_\(chartName).png"
        let plots = plotCommands(chart: chart, plan: plan).joined(separator: ", ")

        let command =
        """
        set datafile separator ',';
        set key autotitle columnhead;
        set terminal png;
        set output '\(imageFile)';
        plot \(plots);
        """

        return command
    }
    func plotCommands(chart: ChartComponent, plan: SimulationPlan) -> [String] {
        var commands: [String] = []
        let timeIndex = plan.builtins.time
        for series in chart.series {
            guard let seriesIndex = plan.variableIndex(of: series.objectID) else {
                continue // We continue gracefully, not user's fault
            }
            let label = series.name ?? "unnamed"
            let item = "'\(dataFileName)' using \(timeIndex + 1):\(seriesIndex + 1) with lines title '\(label)'"
            commands.append(item)
        }
        return commands

    }
}
