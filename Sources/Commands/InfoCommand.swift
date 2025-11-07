//
//  InfoCommand.swift
//
//
//  Created by Stefan Urbanek on 30/06/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows
import Markdown

extension PoieticTool {
    struct Info: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Get information about the design")
        @OptionGroup var options: Options

        @Argument(help: "Frame ID (current if not provided)")
        var frameID: String?

        mutating func run() throws {
            let modeller = try ModellerTool(location: options.designLocation)
            let frame = try modeller.frameIfPresent(frameID)
            
            var items: [(String?, String?)] = [
                ("Design", modeller.url.relativeString)
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
                ("Total snapshots", "\(modeller.design.objectSnapshots.count)"),

                (nil, nil),
                ("Total frames", "\(modeller.design.frames.count)"),
                ("History frames", "\(modeller.design.versionHistory.count)"),
                ("Undoable frames", "\(modeller.design.undoList.count)"),
                ("Redoable frames", "\(modeller.design.redoList.count)"),
                ("Named frames", "\(modeller.design.namedFrames.count)"),
            ]
            
            if let frame {
                let unstructuredCount = frame.filter { $0.structure.type == .unstructured }.count
                items += [
                    (nil, nil),
                    ("Frame", "\(frame.id)"),
                    ("All snapshots", "\(frame.snapshots.count)"),
                    ("Nodes", "\(frame.nodeKeys)"),
                    ("Edges", "\(frame.edgeKeys)"),
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
