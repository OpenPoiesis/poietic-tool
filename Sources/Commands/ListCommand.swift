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
            = CommandConfiguration(abstract: "List design content objects")
        @OptionGroup var options: Options

        enum EntityType {
            case frames
            case objects
        }
        
        enum ListType: String, CaseIterable, ExpressibleByArgument{
            case all = "all"
            case namedFrames = "named-frames"
            case frames
            case history
            case names = "names"
            case formulas = "formulas"
            case pseudoEquations = "pseudo-equations"
            case graphicalFunctions = "graphical-functions"
            var defaultValueDescription: String { "all" }
            
            static var allValueStrings: [String] {
                ListType.allCases.map { "\($0.rawValue)" }
            }
            
            var entityType: EntityType {
                switch self {
                case .all: .objects

                case .namedFrames: .frames
                case .frames: .frames
                case .history: .frames
                    
                case .formulas: .objects
                case .graphicalFunctions: .objects
                case .names: .objects
                case .pseudoEquations: .objects
                }
            }
        }
        
        @Option(name: [.customLong("frame")], help: "List objects in frame (ID or name). If not provided, current is used.")
        var frameRef: String?

        @Option(name: [.customLong("type")], help: "Filter list objects by type (when applicable)")
        var typeName: String?

        @Argument(help: "Kind of list or type of objects to show.")
        var listType: ListType = .all

        mutating func run() throws {
            let editor = try DesignEditor(location: options.designLocation)
            switch listType.entityType {
            case .frames:
                try listFrames(editor.design)
            case .objects:
                let frame = try editor.frame(frameRef)
                try listObjects(editor.world, in: frame)
            }
        }
        func listFrames(_ design: Design) throws {
            switch listType {
            case .namedFrames:
                listNamedFrames(design)
            case .frames:
                listFrameIDs(design)
            case .history:
                listHistory(design)
            default:
                return
            }
        }
        func listObjects(_ world: World, in frame: DesignFrame) throws {
            let type: ObjectType?
            
            if let typeName  {
                if let maybeType = frame.design.metamodel.objectType(name: typeName) {
                    type = maybeType
                }
                else {
                    throw CleanExit.message("Unknown type name: \(typeName)")
                }
            }
            else {
                type = nil
            }
            
            let snapshots: [ObjectSnapshot]
            if let type {
                snapshots = frame.filter(type: type)
            }
            else {
                snapshots = frame.snapshots
            }

            switch listType {
            case .all:
                listAll(snapshots,in: frame)
            case .names:
                listNames(snapshots)
            case .formulas:
                listFormulas(snapshots)
            case .pseudoEquations:
                try listPseudoEquations(frame, world: world)
            case .graphicalFunctions:
                listGraphicalFunctions(frame)
            default:
                return
            }
        }
    }
}

func listAll(_ snapshots: [ObjectSnapshot], in frame: DesignFrame) {
    let sorted = snapshots.sorted { left, right in
        left.id < right.id
    }
    let nodes = sorted.filter { $0.structure.type == .node }
    let edges = sorted.compactMap { DesignObjectEdge($0,in: frame) }
    let unstructured = sorted.filter { $0.structure.type == .unstructured }

    if unstructured.count > 0 {
        print("UNSTRUCTURED OBJECTS")
        for object in unstructured {
            let name: String = object.name ?? "(unnamed)"
            let line: String = [
                "\(object.objectID)",
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
                "\(object.objectID)",
                "\(object.type.name)",
                "\(name)",
            ].joined(separator: " ")
            print("  \(line)")
        }
    }
    if edges.count > 0 {
        print("EDGES")
        for edge in edges {
            let name: String = edge.object.name ?? "(unnamed)"
            let line: String = [
                "\(edge.object.objectID)",
                "\(edge.origin)-->\(edge.target)",
                "\(edge.object.type.name)",
                "\(name)",
            ].joined(separator: " ")
            print("  \(line)")
        }
    }
}

func listNames(_ snapshots: [ObjectSnapshot]) {
    let names: [String] = snapshots.compactMap { $0.name }
        .sorted { $0.lexicographicallyPrecedes($1)}
    
    for name in names {
        print(name)
    }
}

func listFormulas(_ snapshots: [ObjectSnapshot]) {
    var result: [String: String] = [:]
    
    for object in snapshots {
        guard let name = object.name else {
            continue
        }
        guard let formula = object["formula"] else {
            continue
        }

        result[name] = (try? formula.stringValue()) ?? "(invalid formula representation)"
    }
    
    let sorted = result.keys.sorted {
        $0.localizedLowercase.lexicographicallyPrecedes($1.localizedLowercase)
    }
    
    for name in sorted {
        print("\(name) = \(result[name]!)")
    }
}

func listPseudoEquations(_ frame: DesignFrame, world: World) throws (ToolError) {
    // TODO: Add stocks
    do {
        try world.run(schedule: PlanSchedule.self)
    }
    catch {
        throw .internalSystemError(error)
    }

    for (entity, stock) in world.query(StockComponent.self) {
        let lhs = entity.displayName(default: "(unnamed)")
        var rhs = ""
        var hasInflows: Bool = false

        if !stock.inflowRates.isEmpty {
            let inflows = stock.inflowRates.compactMap { world.entity($0) }
                .map { $0.displayName(default: "(unnamed)") }
            rhs += inflows.joined(separator: " + ")
            hasInflows = true
        }

        if !stock.outflowRates.isEmpty {
            if hasInflows {
                rhs += " - "
            }
            let outflows = stock.outflowRates.compactMap { world.entity($0) }
                .map { $0.displayName(default: "(unnamed)") }
            rhs += outflows.joined(separator: " - ")
        }
        
        print("Δ \(lhs) = \(rhs)")
    }
}

func listGraphicalFunctions(_ frame: some Frame) {
    var result: [String: [Point]?] = [:]
    
    for object in frame.snapshots {
        guard let name = object.name else {
            continue
        }
        guard let rawPoints = object["graphical_function_points"] else {
            continue
        }
        result[name] = try? rawPoints.pointArray()
    }
    
    let sorted = result.keys.sorted {
        $0.localizedLowercase.lexicographicallyPrecedes($1.localizedLowercase)
    }
    
    for name in sorted {
        print("\(name):")
        if let points = result[name]! {
            for point in points {
                print("    \(point.x), \(point.y)")
            }
        }
        else {
            print("    (invalid point array representation)")
        }
    }
}

func listNamedFrames(_ design: Design) {
    let names = design.namedFrames.keys
    let sorted = names.sorted {
        $0.localizedLowercase.lexicographicallyPrecedes($1.localizedLowercase)
    }
    for name in sorted {
        let frame = design.frame(name: name)!
        print("\(name) \(frame.id)")
    }
}

func listFrameIDs(_ design: Design) {
    for frame in design.frames {
        print("\(frame.id)")
    }
}
func listHistory(_ design: Design) {
    print("UNDO")
    for id in design.undoList {
        print("\(id)")
    }
    print("REDO")
    for id in design.redoList {
        print("\(id)")
    }
}
