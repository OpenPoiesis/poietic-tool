//
//  Output.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore
import Foundation

/// Print a string to `stderr`.
func errorPrint(_ string: String) {
    if let data = (string + "\n").data(using: .utf8) {
        FileHandle.standardError.write(data)
        FileHandle.standardError.synchronizeFile()
    }
}

/// Print a status information message.
func infoPrint(_ string: String) {
    // Just forward it to stderr.
    errorPrint(string)
}

func printIssues(_ world: World) {
    guard let plane = world.plane else { return }
    printIssues(world.issues, plane: plane)
}
func printIssues(_ issues: [ObjectID:[Issue]], plane: some Plane) {
    errorPrint("DESIGN ISSUES:")
    for (objectID, objectIssues) in issues {
        printObjectIssues(objectID, issues: objectIssues, plane: plane)
    }
}

func printObjectIssues(_ objectID: ObjectID, issues: [Issue], plane: some Plane) {
    /*
     [1234] Stock (ProductionRate):
     error: Cycle detected in flow network
     warning: Unused stock - no incoming flows
     error: Initial value must be positive
     
     [2545] Flow (DrainRate) [1234 → 1235]:
     error: Negative flow rate not allowed
     warning: Flow rate exceeds capacity limits
     */
    guard let object = plane[objectID] else { return }
    let identity = "[\(objectID)] \(object.type.name)"
    let name: String = object.name.map { " (\($0))" } ?? ""
    let topology: String
    
    switch object.topology {
    case .unstructured, .node:
        topology = ""
    case .edge(let origin, let target):
        topology = "[\(origin) → \(target)]"
    case .orderedSet(let owner, _):
        topology = "[\(owner),...]"
    }
    
    errorPrint(identity + name + topology + ":")
    let indent = "    "
    
    for issue in issues {
        let severity = issue.severity.description
        let message = issue.message
        let line = severity + ": " + message
        errorPrint(indent + line)
    }
}
func printDesignIssues(_ issues: [Issue], plane: some Plane) {
    errorPrint("[design]")
    
    for issue in issues {
        let severity = issue.severity.description
        let message = issue.message
        let line = severity + ": " + message
        errorPrint("    " + line)
    }
}

func printValidationResult(_ result: PlaneValidationResult, in plane: some Plane) {
    printDesignIssues(result.violationsAsIssues(), plane: plane)
    printIssues(result.objectIssues(), plane: plane)
}
