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
            let original = try env.existingFrame(options.deriveRef)
            let frame = env.design.createFrame(deriving: original)

            var objects: [MutableObject] = []
            if references.isEmpty {
                objects = frame.snapshots.map { frame.mutate($0.id) }
            }
            else {
                for ref in references {
                    guard let object = frame.object(stringReference: ref) else {
                        throw ToolError.unknownObject(ref)
                    }
                    objects.append(frame.mutate(object.id))
                }
            }
            let center = Point(100.0, 100.0)
            let radius: Double = 100.0
            var angle: Double = 0.0
            let step: Double = (2 * Double.pi) / Double(objects.count)
            
            for obj in objects {
                let obj = frame.mutate(obj.id)
                let position = Point(center.x + radius * Double.cos(angle),
                                     center.y + radius * Double.sin(angle))
                obj.position = position
                angle += step
            }
            
            try env.accept(frame, replacing: options.replaceRef, appendHistory: options.appendHistory)
            try env.close()
        }
    }
}
