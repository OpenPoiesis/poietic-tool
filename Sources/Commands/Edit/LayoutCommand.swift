//
//  LayoutCommand.swift
//  
//
//  Created by Stefan Urbanek on 19/10/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import RealModule

enum LayoutType: String, CaseIterable, ExpressibleByArgument{
    case circle
    // case horizontal + option: distribute equally vs keep other coordinate
    // case vertical + option: distribute equally vs. keep other coordinate
    
//    case forceDirected
    
    var defaultValueDescription: String { "circle" }
    
    static var allValueStrings: [String] {
        LayoutType.allCases.map { "\($0)" }
    }
}


extension PoieticTool {
    struct Layout: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                abstract: "Lay out objects"
            )

        @OptionGroup var globalOptions: Options
        @OptionGroup var options: EditOptions

        @Option
        var layout: LayoutType = .circle

        @Argument(help: "IDs of objects to be laid out. If not specified, then lay out all with position attribute or with DiagramBlock trait.")
        var references: [String] = []
        
        mutating func run() throws {
            let session = try DesignSession(location: globalOptions.designLocation)
            let trans = try session.createTransaction(deriving: options.deriveRef)

            var objects: [TransientObject] = []
            if references.isEmpty {
                for object in trans.snapshots {
                    if object.attributes["position"] != nil
                        || object.type.hasTrait(DiagramDomain.Traits.DiagramBlock)
                    {
                        objects.append(trans.mutate(object.objectID))
                    }
                }
            }
            else {
                for ref in references {
                    guard let object = trans.object(stringReference: ref) else {
                        throw ToolError.unknownObject(ref)
                    }
                    objects.append(trans.mutate(object.objectID))
                }
            }
            
            guard objects.count > 0 else { return }
            
            let center = Point(200.0, 200.0)
            let radius: Double = 200.0
            var angle: Double = 0.0
            
            let step: Double = (2 * Double.pi) / Double(objects.count)
            
            for obj in objects {
                let position = Point(center.x + radius * Double.cos(angle),
                                     center.y + radius * Double.sin(angle))
                obj.position = position
                angle += step
            }
            
            try session.save(replacing: options.replaceRef, appendHistory: options.appendHistory)
        }
    }
}
