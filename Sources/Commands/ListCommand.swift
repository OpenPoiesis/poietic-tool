//
//  ListCommand.swift
//
//
//  Created by Stefan Urbanek on 11/01/2022.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

// TODO: Merge with PrintCommand, use --format=id
extension PoieticTool {
    struct List: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "List design content objects.")
        @OptionGroup var options: Options

        enum ListType: String, CaseIterable, ExpressibleByArgument{
            case all = "all"
            case names = "names"
            case formulas = "formulas"
            case charts = "charts"
            var defaultValueDescription: String { "all" }
            
            static var allValueStrings: [String] {
                ListType.allCases.map { "\($0)" }
            }
        }
        
        @Argument(help: "What kind of list to show.")
        var listType: ListType = .all

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)

            guard let frame = env.design.currentFrame else {
                try env.close()
                throw CleanExit.message("The design is empty or has no current frame")
            }
            
            switch listType {
            case .all:
                listAll(frame)
            case .names:
                listNames(frame)
            case .formulas:
                listFormulas(frame)
            case .charts:
                listCharts(frame)
            }

            try env.close()
        }
        
        func listAll(_ frame: Frame) {
            let sorted = frame.snapshots.sorted { left, right in
                left.id < right.id
            }
            let nodes = sorted.compactMap { Node($0) }
            let edges = sorted.compactMap { Edge($0) }
            let unstructured = sorted.filter { $0.structure.type == .unstructured }

            if unstructured.count > 0 {
                print("UNSTRUCTURED OBJECTS")
                for object in unstructured {
                    let name: String = object.name ?? "(unnamed)"
                    let line: String = [
                        "\(object.id)",
                        "\(object.type.name)",
                        "\(name)",
                    ].joined(separator: " ")
                    print("  \(line)")
                }
            }
            if nodes.count > 0 {
                print("NODES")
                for object in nodes {
                    let name: String = object.name ?? "(unnamed)"
                    let line: String = [
                        "\(object.id)",
                        "\(object.type.name)",
                        "\(name)",
                    ].joined(separator: " ")
                    print("  \(line)")
                }
            }
            if edges.count > 0 {
                print("EDGES")
                for object in edges {
                    let name: String = object.name ?? "(unnamed)"
                    let line: String = [
                        "\(object.id)",
                        "\(object.origin)-->\(object.target)",
                        "\(object.type.name)",
                        "\(name)",
                    ].joined(separator: " ")
                    print("  \(line)")
                }
            }
        }
        
        func listNames(_ frame: Frame) {
            let names: [String] = frame.snapshots.compactMap { $0.name }
                .sorted { $0.lexicographicallyPrecedes($1)}
            
            for name in names {
                print(name)
            }
        }
        
        func listFormulas(_ frame: Frame) {
            var result: [String: String] = [:]
            
            for object in frame.snapshots {
                guard let name = object.name else {
                    continue
                }
                // TODO: Present error more nicely
                if let formula = object["formula"] {
                    result[name] = (try? formula.stringValue()) ?? "(type error)"
                }
                else if let points = object["graphical_function_points"] {
                    result[name] = (try? points.stringValue()) ?? "(type error)"
                }
            }
            
            let sorted = result.keys.sorted {
                $0.localizedLowercase.lexicographicallyPrecedes($1.localizedLowercase)
            }
            
            for name in sorted {
                print("\(name) = \(result[name]!)")
            }
        }
        
        func listCharts(_ frame: Frame) {
            let view = StockFlowView(frame)
            
            let charts = view.charts
            
            let sorted = charts.sorted {
                ($0.node.name!).lexicographicallyPrecedes($1.node.name!)
            }
            
            for chart in sorted {
                let seriesStr = chart.series.map { $0.name! }
                    .joined(separator: " ")
                print("\(chart.node.name!): \(seriesStr)")
            }
        }

    }
}
