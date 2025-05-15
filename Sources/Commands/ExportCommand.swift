//
//  Import.swift
//  
//
//  Created by Stefan Urbanek on 14/08/2023.
//

@preconcurrency import ArgumentParser
import Foundation
import PoieticCore
import PoieticFlows

// TODO: Merge with PrintCommand, use --format=id
extension PoieticTool {
    struct Export: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Export current frame or a collection of objects")
        
        @OptionGroup var globalOptions: Options

        @Option(name: [.customLong("frame")], help: "Frame to be exported. Default: current frame.")
        var frameReference: String?

        @Option(name: [.customLong("output"), .customShort("o")], help: "Output path. Default or '-' is standard output.")
        var outputPath: String = "-"

        @Argument(help: "List of references of objects to be exported. Default: all objects in a frame.")
        var references: [String] = []

        mutating func run() throws {
            let env = try ToolEnvironment(location: globalOptions.designLocation)
            guard env.design.frames.count > 0 else {
                throw ToolError.emptyDesign
            }
            let frameID: ObjectID
            if let frameReference {
                if let id = env.design.frame(name: frameReference)?.id {
                    frameID = id
                }
                else if let id = ObjectID(frameReference), env.design.containsFrame(id) {
                    frameID = id
                }
                else {
                    throw ToolError.unknownFrame(frameReference)

                }
            }
            else {
                guard let id = env.design.currentFrameID else {
                    throw ToolError.unknownFrame("<current frame>")
                }
                frameID = id
            }
            let frame = env.design.frame(frameID)!
            let extractor = RawDesignExtractor()
            let snapshots: [RawSnapshot]
            if references.isEmpty {
                snapshots = frame.snapshots.map {
                    extractor.extract($0)
                }
            }
            else {
                var validIDs: [ObjectID] = []
                for ref in references {
                    guard let snapshot = frame.object(stringReference: ref) else {
                        throw ToolError.unknownObject(ref)
                    }
                    validIDs.append(snapshot.id)
                }
                snapshots = extractor.extractPruning(snapshots: validIDs, frame: frame)
            }

            let rawDesign = extractor.extractStub(env.design)
            rawDesign.snapshots = snapshots
            
            let writer = JSONDesignWriter()
            if outputPath == "-" {
                let data = writer.write(rawDesign)
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
                    // TODO Add tool error
                    fatalError("Unable to write to \(url): \(error)")
                }
            }
        }
    }
}

