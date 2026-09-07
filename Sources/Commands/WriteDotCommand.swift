//
//  WriteDotCommand.swift
//  
//
//  Created by Stefan Urbanek on 27/06/2023.
//

import Foundation
@preconcurrency import ArgumentParser

import PoieticFlows
import PoieticCore

let DefaultDOTStyle = DotStyle(
    nodes: [
        DotNodeStyle(predicate: .any,
                     attributes: [
                        "labelloc": "b",
                     ]),
        DotNodeStyle(predicate: .isType(StockFlowDomain.Types.FlowRate),
                     attributes: [
                        "shape": "ellipse",
                        "style": "bold",

                     ]),
        DotNodeStyle(predicate: .isType(StockFlowDomain.Types.Stock),
                     attributes: [
                        "style": "bold",
                        "shape": "box",
                     ]),
        DotNodeStyle(predicate: .isType(StockFlowDomain.Types.Auxiliary),
                     attributes: [
                        "shape": "ellipse",
                        "style": "dotted",
                     ]),
    ],
    edges: [
        DotEdgeStyle(predicate: .isType(StockFlowDomain.Types.Flow),
                     attributes: [
                        "color": "blue:white:blue",
                        "arrowhead": "empty",
                        "arrowsize": "2",
                     ]),
        DotEdgeStyle(predicate: .isType(StockFlowDomain.Types.Parameter),
                     attributes: [
                        "arrowhead": "open",
                        "color": "red",
                     ]),
    ]
)


extension PoieticTool {
    struct WriteDOT: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Write a Graphviz DOT file.")

        @OptionGroup var globalOptions: Options
        
        @Option(name: [.long, .customShort("n")],
                help: "Name of the graph in the output file")
        var name = "output"

        @Option(name: [.long, .customShort("o")],
                help: "Path to a DOT file where the output will be written.")
        var output = "output.dot"

        @Option(name: [.long, .customShort("l")],
                help: "Node attribute that will be used as node label")
        var labelAttribute = "id"
        
        @Option(name: [.long, .customShort("m")],
                help: "Label used if the node has no label attribute")
        var missingLabel = "(none)"
        
        @Option(name: [.customLong("plane")], help: "Plane ID or name")
        var planeRef: String?
        
        mutating func run() throws {
            let session = try DesignSession(location: globalOptions.designLocation)
            let plane = try session.plane(planeRef)

            guard let testURL = URL(string: output) else {
                throw ToolError.malformedLocation(output)
            }
            let outputURL: URL

            if testURL.scheme == nil {
                outputURL = URL(fileURLWithPath: output)
            }
            else {
                outputURL = testURL
            }

            let exporter = DotExporter(path: outputURL.path,
                                       name: name,
                                       labelAttribute: labelAttribute,
                                       missingLabel: missingLabel,
                                       style: DefaultDOTStyle)

            try exporter.export(plane)
        }
    }
}
