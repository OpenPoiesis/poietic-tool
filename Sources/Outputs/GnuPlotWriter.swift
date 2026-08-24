//
//  GnuPlotWriter.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore
import PoieticFlows
import Foundation

func writeToCSV(path: String, result: SimulationResult, plan: SimulationPlan) throws {
    let writer: CSVWriter = try CSVWriter(path: path)
    let header: [String] = plan.stateVariables.map { $0.name }

    try writer.write(row: header)
    
    for state in result.states {
        var row: [String] = []
        for index in plan.stateVariables.indices {
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
class GNUPlotBundleWriter {
    let dataFileName: String

    init(dataFileName: String = "data.csv") {
        self.dataFileName = dataFileName
    }
    
    public func write(result: SimulationResult, toPath path: String, world: World) throws {
        guard let plan: SimulationPlan = world.singleton() else {
            return
        }
        let fm = FileManager()
        try fm.createDirectory(atPath: path, withIntermediateDirectories: true)
        
        try writeToCSV(path: path + "/" + dataFileName, result: result, plan: plan)

        for (entity, chart) in world.query(Chart.self) {
            let name = chart.label ?? "unnamed_\(entity.runtimeID)"
            let gnuplotCommand = chartCommand(entity: entity, chart: chart, name: name, plan: plan)
            let gnuplotCommandPath = path + "/" + "chart_\(name).gnuplot"

            guard let data = gnuplotCommand.data(using: .utf8) else {
                continue
            }
            try data.write(to: URL(filePath: gnuplotCommandPath))
        }
    }
    func chartCommand(entity: RuntimeEntity, chart: Chart, name: String, plan: SimulationPlan) -> String {
        
        let imageFile = "chart_\(name).png"
        let plots = plotCommands(entity: entity, chart: chart, plan: plan).joined(separator: ", ")

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
    func plotCommands(entity: RuntimeEntity, chart: Chart, plan: SimulationPlan) -> [String] {
        var commands: [String] = []
        let timeIndex = plan.builtins.time
        for seriesEnt in entity.outgoing(ChildOf.self) {
            guard let _: ChartSeries = seriesEnt.component(),
                  let target = seriesEnt.firstOutgoing(RepresentationOf.self),
                  let targetObjectID = target.objectID,
                  let seriesIndex = plan.variableIndex(targetObjectID)
            else { continue }

            let label: String
            if let simName: SimulationName = target.component() {
                label = simName.name
            }
            else {
                label = "unnamed"
            }
                
            let item = "'\(dataFileName)' using \(timeIndex + 1):\(seriesIndex + 1) with lines title '\(label)'"
            commands.append(item)
        }
        return commands

    }
}

