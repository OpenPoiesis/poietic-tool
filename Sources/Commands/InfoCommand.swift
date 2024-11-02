//
//  InfoCommand.swift
//
//
//  Created by Stefan Urbanek on 30/06/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Info: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Get information about the design")
        @OptionGroup var options: Options

        @Argument(help: "Frame ID (current if not provided)")
        var frameID: String?

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)

            let frame: StableFrame?
            
            if let frameID {
                if let id = ObjectID(frameID) {
                    if let stableFrame = env.design.frame(id) {
                        frame = stableFrame
                    }
                    else {
                        throw ToolError.unknownFrame(frameID)
                    }
                }
                else {
                    throw ToolError.unknownFrame(frameID)
                }
            }
            else {
                frame = env.design.currentFrame
            }
            
            let currentFrameID: String
            if let frame = env.design.currentFrame {
                currentFrameID = "\(frame.id)"
            }
            else {
                currentFrameID = "none"
            }
            
            var items: [(String?, String?)] = [
                ("Design", env.url.relativeString),
                (nil, nil),
                ("Current frame ID", "\(currentFrameID)"),
                ("Total snapshot count", "\(env.design.validatedSnapshots.count)"),

                (nil, nil),
                ("History", nil),
                ("History frames", "\(env.design.versionHistory.count)"),
                ("Undoable frames", "\(env.design.undoableFrames.count)"),
                ("Redoable frames", "\(env.design.redoableFrames.count)"),
            ]
            
            if let frame {
                items += [
                    (nil, nil),
                    ("Frame", "\(frame.id)"),
                    ("All snapshots", "\(frame.snapshots.count)"),
                    ("Nodes", "\(frame.graph.nodes.count)"),
                    ("Edges", "\(frame.graph.edges.count)"),
                ]
            }
            
            let formattedItems = formatLabelledList(items)
            
            for item in formattedItems {
                print(item)
            }
            
        }
    }
}

