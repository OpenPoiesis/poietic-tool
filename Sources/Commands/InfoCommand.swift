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

        @Option(name: [.customLong("plane")], help: "Plane ID or name. Default is current.")
        var planeReference: String?

        mutating func run() throws {
            let session = try DesignSession(location: options.designLocation)
            let plane: DesignPlane?
            if session.design.isEmpty {
                plane = nil
            }
            else {
                plane = try session.setPlane(planeReference)
            }
            
            var items: [(String?, String?)] = [
                ("Design", session.url.relativeString)
            ]

            if let info = plane?.filter(type: BasicDomain.Types.DesignInfo).first {
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
                ("Total snapshots", "\(session.design.objectSnapshots.count)"),

                (nil, nil),
                ("Total planes", "\(session.design.planes.count)"),
                ("History planes", "\(session.design.versionHistory.count)"),
                ("Undoable planes", "\(session.design.undoList.count)"),
                ("Redoable planes", "\(session.design.redoList.count)"),
                ("Named planes", "\(session.design.namedPlanes.count)"),
            ]
            
            if let plane {
                let unstructuredCount = plane.filter { $0.topology.type == .unstructured }.count
                items += [
                    (nil, nil),
                    ("Plane", "\(plane.id)"),
                    ("All snapshots", "\(plane.snapshots.count)"),
                    ("Nodes", "\(plane.nodeKeys)"),
                    ("Edges", "\(plane.edgeKeys)"),
                    ("Unstructured", "\(unstructuredCount)"),
                ]

                if let obj = plane.first(trait: StockFlowDomain.Traits.StockFlowSimulationSettings) {
                    let params = SimulationTimeSettings(fromObject: obj)
                    items += [
                        (nil, nil),
                        ("Time Settings", nil),
                        ("Start time", "\(params.startTime)"),
                        ("Final time", "\(params.finalTime)"),
                        ("Time step", "\(params.timeStep)"),
                    ]
                }
            }
            else {
                items += [
                    (nil, nil),
                    ("Current plane", "no current plane"),
                ]
            }
            
            let formattedItems = formatLabelledList(items)
            
            for item in formattedItems {
                print(item)
            }
            
        }
    }
}
