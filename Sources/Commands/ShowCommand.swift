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

        @Option(name: [.customLong("plane")], help: "Plane to get object from. Default is current plane")
        var planeRef: String?
        
        @Flag(name: [.customLong("debug")], help: "Show detailed debug information")
        var debug: Bool = false

        @Argument(help: "ID or a name of an object to be described")
        var reference: String
        
        mutating func run() throws {
            let session = try DesignSession(location: options.designLocation)
            let plane = try session.plane(planeRef)
            
            guard let object = plane.object(stringReference: reference) else {
                throw ToolError.unknownObject(reference)
            }
            
            printObjectAsText(object, debug: debug)
        }
    }
}

func printObjectAsText(_ object: ObjectSnapshot, debug: Bool) {
    var items: [(String?, String?)] = [
        ("Type", "\(object.type.name)"),
        ("Object ID", "\(object.objectID)"),
        ("Snapshot ID", "\(object.snapshotID)"),
        ("Topology", "\(object.topology.type)"),
    ]
    
    let traits = object.type.traits.map { $0.name }.joined(separator: ", ")
    items.append(("Traits", traits))
    
    var seenAttributes: [String] = []
    
    items.append((nil, nil))
    if object.type.hasTrait(.Name),
       let name: String = object["name"]
    {
        let normalized = NormalizedName(name: name)
        items.append(("Normalized Name", normalized.key))
        items.append(("Display Name", normalized.displayName))

    }
    items.append((nil, nil))
    items.append(("Attributes", nil))

    for trait in object.type.traits {
        if trait.attributes.isEmpty {
            continue
        }
        

        for attr in trait.attributes {
            let rawValue = object[attr.name]
            var displayValue: String
            if let rawValue {
                displayValue = String(describing: rawValue)
            }
            else {
                displayValue = "(no value)"
            }
            if let rawValue, debug {
                displayValue += " (\(rawValue.valueType))"
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
        
        var displayValue = String(describing: value)
        if debug {
            displayValue += " (\(value.valueType))"
        }

        orphanedItems.append((name, displayValue))
    }
    
    if !orphanedItems.isEmpty {
        items.append((nil, nil))
        items.append(("Extra attributes", ""))
        items += orphanedItems
    }
    
    if items.isEmpty {
        infoPrint("Object has no attributes.")
    }
    else {
        let formattedItems = formatLabelledList(items,
                                                minimumWidth: AttributeColumnWidth)
        
        for item in formattedItems {
            print(item)
        }
    }
}
