//
//  ExportCommand.swift
//  
//
//  Created by Stefan Urbanek on 14/08/2023.
//

@preconcurrency import ArgumentParser
import Foundation
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Export: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Export current plane or a collection of objects")

        @OptionGroup var globalOptions: Options

        @Option(name: [.customLong("plane")], help: "Plane to be exported. Default: current plane.")
        var planeReference: String?

        @Option(name: [.customLong("output"), .customShort("o")], help: "Output path. Default or '-' is standard output.")
        var outputPath: String = "-"

        @Argument(help: "List of references of objects to be exported. Default: all objects in a plane.")
        var references: [String] = []

        mutating func run() throws {
            let editor = try DesignSession(location: globalOptions.designLocation)
            let plane = try editor.plane(planeReference)

            let extractor = DesignExtractor()
            let snapshots: [RawSnapshot]
            if references.isEmpty {
                snapshots = plane.snapshots.map {
                    extractor.extract($0)
                }
            }
            else {
                var validIDs: [ObjectID] = []
                for ref in references {
                    guard let snapshot = plane.object(stringReference: ref) else {
                        throw ToolError.unknownObject(ref)
                    }
                    validIDs.append(snapshot.objectID)
                }
                snapshots = extractor.extractPruning(objects: validIDs, plane: plane)
            }

            let rawDesign = extractor.extractStub(editor.design)
            rawDesign.snapshots = snapshots
            
            let writer = JSONDesignWriter()
            if outputPath == "-" {
                let data: Data = writer.write(rawDesign)
                if let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            }
            else {
                let url = URL(filePath: outputPath)
                do {
                    try writer.write(rawDesign, toURL: url)
                }
                catch {
                    throw ToolError.unableToWrite(url, error)
                }
            }
        }
    }
}

