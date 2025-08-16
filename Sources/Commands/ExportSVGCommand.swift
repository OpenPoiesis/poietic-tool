//
//  ExportSVGCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 01/08/2025.
//

@preconcurrency import ArgumentParser
import SystemPackage
import Foundation
import PoieticCore
import PoieticFlows
import Diagramming

extension PoieticTool {
    struct ExportSVG: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "experimental-export-svg",
                abstract: "Export design as a SVG diagram"
            )

        @OptionGroup var options: Options
        
        @Option(name: [.long, .customShort("o")],
                help: "Output file path")
        var output = "diagram.svg"

        @Option(name: [.customLong("pictogram-scale")],
                help: "Scale of pictograms")
        var pictogramScale: Double = 0.5

        @Option(name: [.customLong("pictogram-line-width")],
                help: "Scale of pictograms")
        var pictogramLineWidth: Double = 1.0

        @Option(name: [.customLong("frame")], help: "Frame ID or name")
        var frameRef: String?
        
        @Option(name: [.customLong("pictograms")], help: "File with pictogram collection")
        var pictogramCollectionPath: String?

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let frame = try env.existingFrame(frameRef)

            guard let testURL = URL(string: output) else {
                fatalError("Invalid resource reference: \(output)")
            }
            let outputURL: URL

            if testURL.scheme == nil {
                outputURL = URL(fileURLWithPath: output)
            }
            else {
                outputURL = testURL
            }

            print("### EXPERIMENTAL ###")
            let collection: PictogramCollection
            if let path = pictogramCollectionPath {
                print("Loading pictograms from \(path)")
                collection = try loadPictograms(path: path)
            }
            else {
                collection = PictogramCollection()
            }
            
            // TODO: Move somewhere appropriate
            let scaledPictos = collection.pictograms.map { $0.scaled(pictogramScale) }
            collection.pictograms = scaledPictos
            
            print("Exporting to: \(outputURL.path())")
            print("Creating diagram...")
            let ctrl = DiagramController(pictograms: collection)
            ctrl.update(frame: frame)
            
            let style = SVGDiagramStyle(
                pictogramLineWidth: pictogramLineWidth
            )
            
            let exporter = SVGDiagramExporter(style: style)
            try exporter.export(diagram: ctrl.diagram, to: outputURL.path())
        }
    }
}

func loadPictograms(path: String) throws -> PictogramCollection {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    let decoder = JSONDecoder()
    let collection = try decoder.decode(PictogramCollection.self, from: data)
    return collection
}
