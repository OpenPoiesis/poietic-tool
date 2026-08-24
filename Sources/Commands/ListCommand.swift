//
//  ListCommand.swift
//
//
//  Created by Stefan Urbanek on 11/01/2022.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct List: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "List design content objects")
        @OptionGroup var options: Options

        enum EntityType {
            case planes
            case objects
        }
        
        enum ListType: String, CaseIterable, ExpressibleByArgument{
            case all = "all"
            case namedPlanes = "named-planes"
            case planes
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

                case .namedPlanes: .planes
                case .planes: .planes
                case .history: .planes
                    
                case .formulas: .objects
                case .graphicalFunctions: .objects
                case .names: .objects
                case .pseudoEquations: .objects
                }
            }
        }
        
        @Option(name: [.customLong("plane")], help: "List objects in plane (ID or name). If not provided, current is used.")
        var planeRef: String?

        @Option(name: [.customLong("type")], help: "Filter list objects by type (when applicable)")
        var typeName: String?

        @Argument(help: "Kind of list or type of objects to show.")
        var listType: ListType = .all

        mutating func run() throws {
            let editor = try DesignSession(location: options.designLocation)
            switch listType.entityType {
            case .planes:
                try listPlanes(editor.design)
            case .objects:
                let plane = try editor.setPlane(planeRef)
                try listObjects(editor.world, in: plane)
            }
        }
        func listPlanes(_ design: Design) throws {
            switch listType {
            case .namedPlanes:
                listNamedPlanes(design)
            case .planes:
                listPlaneIDs(design)
            case .history:
                listHistory(design)
            default:
                return
            }
        }
        func listObjects(_ world: World, in plane: DesignPlane) throws {
            let type: ObjectType?
            
            if let typeName  {
                if let maybeType = plane.design.metamodel.objectType(name: typeName) {
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
                snapshots = plane.filter(type: type)
            }
            else {
                snapshots = plane.snapshots
            }

            switch listType {
            case .all:
                listAll(snapshots,in: plane)
            case .names:
                listNames(snapshots)
            case .formulas:
                listFormulas(snapshots)
            case .pseudoEquations:
                try listPseudoEquations(plane, world: world)
            case .graphicalFunctions:
                listGraphicalFunctions(plane)
            default:
                return
            }
        }
    }
}

func listAll(_ snapshots: [ObjectSnapshot], in plane: DesignPlane) {
    let sorted = snapshots.sorted { left, right in
        left.snapshotID.rawValue < right.snapshotID.rawValue
    }
    let nodes = sorted.filter { $0.topology.type == .node }
    let edges = sorted.compactMap { DesignObjectEdge($0,in: plane) }
    let unstructured = sorted.filter { $0.topology.type == .unstructured }

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

func listPseudoEquations(_ plane: DesignPlane, world: World) throws (ToolError) {
    // TODO: Add stocks
    do {
        try world.run(schedule: PlanSchedule.self)
    }
    catch {
        throw .internalSystemError(error)
    }

    for (entity, stock) in world.query(Stock.self) {
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

func listGraphicalFunctions(_ plane: some Plane) {
    var result: [String: [Point]?] = [:]
    
    for object in plane.snapshots {
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

func listNamedPlanes(_ design: Design) {
    let names = design.namedPlanes.keys
    let sorted = names.sorted {
        $0.localizedLowercase.lexicographicallyPrecedes($1.localizedLowercase)
    }
    for name in sorted {
        let plane = design.plane(name: name)!
        print("\(name) \(plane.id)")
    }
}

func listPlaneIDs(_ design: Design) {
    for plane in design.planes {
        print("\(plane.id)")
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
