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

            let frame: DesignFrame?
            
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
            
            var items: [(String?, String?)] = [
                ("Design", env.url.relativeString)
            ]

            if let info = frame?.filter(type: ObjectType.DesignInfo).first {
                if let text = try info["title"]?.stringValue() {
                    items.append(("Title", text))
                }
                if let text = try info["author"]?.stringValue() {
                    items.append(("Author", text))
                }
                if let text = try info["license"]?.stringValue() {
                    items.append(("License", text))
                }
            }
            
            items += [
                (nil, nil),
                ("Total snapshots", "\(env.design.snapshots.count)"),

                (nil, nil),
                ("Total frames", "\(env.design.frames.count)"),
                ("History frames", "\(env.design.versionHistory.count)"),
                ("Undoable frames", "\(env.design.undoableFrames.count)"),
                ("Redoable frames", "\(env.design.redoableFrames.count)"),
                ("Named frames", "\(env.design.namedFrames.count)"),
            ]
            
            if let frame {
                let unstructuredCount = frame.filter { $0.structure.type == .unstructured }.count
                items += [
                    (nil, nil),
                    ("Frame", "\(frame.id)"),
                    ("All snapshots", "\(frame.snapshots.count)"),
                    ("Nodes", "\(frame.nodes.count)"),
                    ("Edges", "\(frame.edges.count)"),
                    ("Unstructured", "\(unstructuredCount)"),
                ]

                if let obj = frame.first(trait: .Simulation) {
                    let params = SimulationParameters(fromObject: obj)
                    items += [
                        (nil, nil),
                        ("Simulation Parameters", nil),
                        ("Initial time", "\(params.initialTime)"),
                        ("End time", "\(params.endTime)"),
                        ("Time delta", "\(params.timeDelta)"),
                    ]
                }
            }
            else {
                items += [
                    (nil, nil),
                    ("Current frame", "no current frame"),
                ]
            }
            
            let formattedItems = formatLabelledList(items)
            
            for item in formattedItems {
                print(item)
            }
            
        }
    }
}
