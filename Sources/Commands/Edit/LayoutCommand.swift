//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 19/10/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import RealModule

enum LayoutType: String, CaseIterable, ExpressibleByArgument{
    case circle
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

        @Argument(help: "IDs of objects to be laid out. If not specified, then lay out all.")
        var references: [String] = []
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: globalOptions.designLocation)
            let trans = try env.deriveOrCreate(options.deriveRef)

            var objects: [TransientObject] = []
            if references.isEmpty {
                objects = trans.objectIDs.map { trans.mutate($0) }
            }
            else {
                for ref in references {
                    guard let object = trans.object(stringReference: ref) else {
                        throw ToolError.unknownObject(ref)
                    }
                    objects.append(trans.mutate(object.objectID))
                }
            }
            let center = Point(100.0, 100.0)
            let radius: Double = 100.0
            var angle: Double = 0.0
            let step: Double = (2 * Double.pi) / Double(objects.count)
            
            for obj in objects {
                let obj = trans.mutate(obj.objectID)
                let position = Point(center.x + radius * Double.cos(angle),
                                     center.y + radius * Double.sin(angle))
                obj.position = position
                angle += step
            }
            
            try env.accept(trans, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try env.closeAndSave()
        }
    }
}
