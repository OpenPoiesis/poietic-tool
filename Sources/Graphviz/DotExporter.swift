//
//  File.swift
//
//
//  Created by Stefan Urbanek on 2021/10/21.
//

import SystemPackage
import PoieticCore

// NOTE: This is simple one-use exporter.
// TODO: Make this export to a string and make it export by appending content.

/// Object that exports nodes and edges into a [GraphViz](https://graphviz.org)
/// dot language file.
public class DotExporter {
    /// Path of the file to be exported to.
    let path: FilePath

    /// Name of the graph in the output file.
    let name: String
    
    /// Attribute of nodes that will be used as a node label in the output.
    /// If not set then the node ID will be used.
    ///
    let labelAttribute: String?
    
    /// Label used when an object has no label attribute
    let missingLabel: String?
    
    /// Style and formatting of the output.
    ///
    let style: DotStyle?

    /// Creates a GraphViz DOT file exporter.
    ///
    /// - Parameters:
    ///     - path: Path to the file where the output is written
    ///     - name: Name of the graph in the output
    ///     - labelAttribute: Attribute of exported nodes that will be used
    ///       as a label of nodes in the output. If not set then node ID will be
    ///       used.
    ///     - style: style of the graph
    ///     - missingLabel: text to be used when a label attribute is not present
    ///
    public init(path: FilePath,
                name: String,
                labelAttribute: String? = nil,
                missingLabel: String? = nil,
                style: DotStyle? = nil) {
        self.path = path
        self.name = name
        self.labelAttribute = labelAttribute
        self.missingLabel = missingLabel
        self.style = style
    }
    
    /// Export nodes and edges into the output.
    public func export(_ frame: StableFrame) throws  {
        var output: String = ""
        let formatter = DotFormatter(name: name, type: .directed)

        output = formatter.header()
        
        for nodeID in frame.nodeKeys {
            let node = frame[nodeID]
            let label: String
            
            if let attribute = labelAttribute {
                if let value = node[attribute] {
                    label = String(describing: value)
                }
                else if let missingLabel {
                    label = missingLabel
                }
                else {
                    label = nodeID.stringValue
                }
            }
            else {
                label = nodeID.stringValue
            }

            var attributes = format(graph: frame, node: node)
            attributes["label"] = label

            let id = "\(nodeID)"
            output += formatter.node(id, attributes: attributes)
        }

        for edge in frame.edges {
            let attributes = format(graph: frame, edge: edge.object)
            // TODO: Edge label
            // attributes["label"] = edge.type.name
            output += formatter.edge(from:"\(edge.origin)",
                                     to:"\(edge.target)",
                                     attributes: attributes)
        }

        output += formatter.footer()
        
        let file = try FileDescriptor.open(path, .writeOnly,
                                           options: [.truncate, .create],
                                           permissions: .ownerReadWrite)
        try file.closeAfter {
          _ = try file.writeAll(output.utf8)
        }
    }
    
    public func format(graph: StableFrame, node: ObjectSnapshot) -> [String:String] {
        var combined: [String:String] = [:]
        
        for style in style?.nodeStyles ?? [] {
            if style.predicate.match(node, in: graph) {
                combined.merge(style.attributes) { (_, new) in new}
            }
        }
       
        if let position = node.position {
            combined["pos"] = "\(position.x/100),\(position.y/100)!"
        }
        
        return combined
    }

    public func format(graph: StableFrame, edge: ObjectSnapshot) -> [String:String] {
        var combined: [String:String] = [:]
        
        for style in style?.edgeStyles ?? [] {
            if style.predicate.match(edge, in: graph) {
                combined.merge(style.attributes) { (_, new) in new}
            }
        }
        
        return combined
    }
}

