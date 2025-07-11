//
//  ShowCommand.swift
//
//
//  Created by Stefan Urbanek on 29/06/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import Foundation

/// Width of the attribute label column for right-aligned display.
///
let AttributeColumnWidth = 20

extension PoieticTool {
    struct Show: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Describe an object")
        @OptionGroup var options: Options

        enum OutputFormat: String, CaseIterable, ExpressibleByArgument{
            case text = "text"
            case json = "json"
            var defaultValueDescription: String { "text" }
            
            static var allValueStrings: [String] {
                OutputFormat.allCases.map { "\($0)" }
            }
        }
        @Option(name: [.long, .customShort("f")], help: "Output format")
        var outputFormat: OutputFormat = .text

        @Option(name: [.customLong("frame")], help: "Frame to get object from")
        var frameRef: String?
        
        @Argument(help: "ID of an object to be described")
        var reference: String
        
        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let frame = try env.existingFrame(frameRef)
            
            guard let object = frame.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }
            
            switch outputFormat {
            case .text: printObjectAsText(object)
            case .json: printObjectAsJSON(object)
            }
            try env.close()
        }
    }
}

func printObjectAsText(_ object: ObjectSnapshot) {
    var items: [(String?, String?)] = [
        ("Type", "\(object.type.name)"),
        ("Object ID", "\(object.objectID)"),
        ("Snapshot ID", "\(object.snapshotID)"),
        ("Structure", "\(object.structure.type)"),
    ]
    
    let traits = object.type.traits.map { $0.name }.joined(separator: ", ")
    items.append(("Traits:", traits))
    
    var seenAttributes: [String] = []
    
    items.append((nil, nil))
    items.append(("Attributes", nil))

    for trait in object.type.traits {
        if trait.attributes.isEmpty {
            continue
        }
        

        for attr in trait.attributes {
            let rawValue = object[attr.name]
            let displayValue: String
            if let rawValue {
                displayValue = String(describing: rawValue)
            }
            else {
                displayValue = "(no value)"
            }

            items.append((attr.name, displayValue))
            seenAttributes.append(attr.name)
        }
    }
    
    var orphanedItems: [(String?, String?)]  = []

    for item in object.attributes {
        let (name, value) = item
        if seenAttributes.contains(name) {
            continue
        }
        let displayValue = String(describing: value)

        orphanedItems.append((name, displayValue))
    }
    
    if !orphanedItems.isEmpty {
        items.append((nil, nil))
        items.append(("Extra attributes", ""))
        items += orphanedItems
    }
    
    if items.isEmpty {
        print("Object has no attributes.")
    }
    else {
        let formattedItems = formatLabelledList(items,
                                                minimumWidth: AttributeColumnWidth)
        
        for item in formattedItems {
            print(item)
        }
    }

}

func printObjectAsJSON(_ object: ObjectSnapshot) {
    let raw = RawSnapshot(object)
    let encoder = JSONEncoder()
    let data = try! encoder.encode(raw)
    let output = String(data: data, encoding: .utf8)!
    print(output)
}
