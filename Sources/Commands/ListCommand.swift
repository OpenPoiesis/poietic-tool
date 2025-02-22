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

        enum ListType: String, CaseIterable, ExpressibleByArgument{
            case all = "all"
            case names = "names"
            case formulas = "formulas"
            case graphicalFunctions = "graphical-functions"
            var defaultValueDescription: String { "all" }
            
            static var allValueStrings: [String] {
                ListType.allCases.map { "\($0.rawValue)" }
            }
        }
        
        @Argument(help: "Kind of list or type of objects to show.")
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
            case .graphicalFunctions:
                listGraphicalFunctions(frame)
            }

            try env.close()
        }
    }
}

func listAll(_ frame: DesignFrame) {
    let sorted = frame.snapshots.sorted { left, right in
        left.id < right.id
    }
    let nodes = sorted.filter { $0.structure.type == .node }
    let edges = sorted.compactMap { EdgeSnapshot($0,in: frame) }
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
        for edge in edges {
            let name: String = edge.object.name ?? "(unnamed)"
            let line: String = [
                "\(edge.object.id)",
                "\(edge.origin)-->\(edge.target)",
                "\(edge.object.type.name)",
                "\(name)",
            ].joined(separator: " ")
            print("  \(line)")
        }
    }
}

func listNames(_ frame: DesignFrame) {
    let names: [String] = frame.snapshots.compactMap { $0.name }
        .sorted { $0.lexicographicallyPrecedes($1)}
    
    for name in names {
        print(name)
    }
}

func listFormulas(_ frame: DesignFrame) {
    var result: [String: String] = [:]
    
    for object in frame.snapshots {
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

func listGraphicalFunctions(_ frame: DesignFrame) {
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
