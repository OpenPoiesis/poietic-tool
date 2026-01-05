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
            let editor = try DesignEditor(location: options.designLocation)
            let frame = try editor.frameIfPresent(frameID)
            
            var items: [(String?, String?)] = [
                ("Design", editor.url.relativeString)
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
                ("Total snapshots", "\(editor.design.objectSnapshots.count)"),

                (nil, nil),
                ("Total frames", "\(editor.design.frames.count)"),
                ("History frames", "\(editor.design.versionHistory.count)"),
                ("Undoable frames", "\(editor.design.undoList.count)"),
                ("Redoable frames", "\(editor.design.redoList.count)"),
                ("Named frames", "\(editor.design.namedFrames.count)"),
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
                    let params = SimulationSettings(fromObject: obj)
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
