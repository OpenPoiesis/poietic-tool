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
        
        @Option(name: [.customLong("frame")], help: "Frame ID or name")
        var frameRef: String?
        
        @Option(name: [.customLong("pictograms")], help: "File with pictogram collection")
        var pictogramCollectionPath: String?

        mutating func run() throws {
            let editor = try DesignEditor(location: options.designLocation)
            let world = editor.world
            
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

            let pictograms: PictogramCollection
            if let path = pictogramCollectionPath {
                print("Loading pictograms from \(path)")
                pictograms = try loadPictograms(path: path)
            }
            else {
                pictograms = PictogramCollection()
            }
        
            // TODO: Move somewhere more appropriate
            let scaledPictos = pictograms.pictograms.map { $0.scaled(pictogramScale) }
            pictograms.pictograms = scaledPictos
            
            print("Exporting to: \(outputURL.path())")
            print("Creating diagram...")

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
            
            let diagram = DiagramSceneComposer.createDiagramFromAll(world: world)

            // 4. Create scene and update layout
            let composer = DiagramSceneComposer(world: world)
            
            let scene = composer.createScene(diagram: diagram, viewport: ViewportState(zoom: zoom / 100.0))
            scene.setComponent(SceneLayoutProvider(provider: svgStyle))
            let system = SceneCompositionSystem(world)
            try system.update(world)

            // Export
            let renderer = SVGDiagramSceneRenderer(world: world)
            try renderer.render(scene, style: svgStyle, to: outputURL.path())
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
