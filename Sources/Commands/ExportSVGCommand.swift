//
//  ExportSVGCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 01/08/2025.
//

@preconcurrency import ArgumentParser
import Foundation
import PoieticCore
import PoieticFlows
import Diagramming

extension PoieticTool {
    struct ExportSVG: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Export design as a SVG diagram"
            )

        // TODO: Option for secondary label: formula, value
        // TODO: Option for simulation step (combine with `run` command)
        // TODO: Option for indicators (value, error)
        // TODO: Option for SVG style

        @OptionGroup var options: Options
        
        @Option(name: [.long, .customShort("o")], help: "Output file path")
        var output = "diagram.svg"

        @Option(name: [.customLong("pictogram-scale")], help: "Scale of pictograms")
        var pictogramScale: Double = 0.5

        @Option(name: [.customLong("pictogram-line-width")], help: "Scale of pictograms")
        var pictogramLineWidth: Double = 1.0

        @Option(name: [.customLong("zoom")], help: "Zoom level in %")
        var zoom: Double = 100.0
        
        @Option(name: [.customLong("plane")], help: "Plane name or ID. Default: current plane")
        var planeRef: String?

        @Option(name: [.customLong("pictograms")], help: "File with pictogram collection")
        var pictogramCollectionPath: String?

        mutating func run() throws {
            let session = try DesignSession(location: options.designLocation)
            try session.setPlane(planeRef)
            let world = session.world
            
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

            let pictograms: PictogramCollection
            if let path = pictogramCollectionPath {
                infoPrint("Loading pictograms from \(path)")
                pictograms = try loadPictograms(path: path)
            }
            else {
                pictograms = PictogramCollection()
            }
        
            // TODO: Move somewhere more appropriate
            let scaledPictos = pictograms.pictograms.map { $0.scaled(pictogramScale) }
            pictograms.pictograms = scaledPictos
            
            infoPrint("Exporting to: \(outputURL.path())")
            infoPrint("Creating diagram...")

            // 1. Configure the notation
            //
            let notation = Notation(
                pictograms: pictograms.pictograms,
                defaultPictogramName: "Unknown",
                connectorGlyphs: DefaultStockFlowConnectorGlyphs,
                defaultConnectorGlyphName: "default"
            )
            world.setSingleton(notation)

            // 2. Update the world
            //
            try world.run(schedule: DiagramSchedule.self)
            
            // 3. Create Diagram
            //
            var svgStyle = SVGDiagramStyle.Default
            svgStyle.classes[.pictogram]?.strokeWidth = pictogramLineWidth
            
            let diagram = PresentationBuilder.createDiagramFromAll(world: world)

            // 4. Create presentation and update layout
            let builder = PresentationBuilder(world: world)
            
            let presentation = builder.createPresentation(diagram: diagram, camera: Camera(zoom: zoom / 100.0))
            presentation.setComponent(LayoutEnvironment(provider: svgStyle))
            try PresentationUpdateSystem.update(world)

            // Export
            let renderer = SVGDiagramRenderer(world: world)
            try renderer.render(presentation, style: svgStyle, to: outputURL.path())
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
