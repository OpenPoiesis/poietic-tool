//
//  Output.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore

func printIssues(_ world: World) {
    guard let plane = world.plane else { return }
    printIssues(world.issues, plane: plane)
}
func printIssues(_ issues: [ObjectID:[Issue]], plane: some Plane) {
    // FIXME: Use stderr
    print("DESIGN ISSUES:")
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
    let structure: String
    
    switch object.topology {
    case .unstructured, .node:          structure = ""
    case .edge(let origin, let target): structure = "[\(origin) → \(target)]"
    case .orderedSet(let owner, _):         structure = "[↕︎\(owner)]"
    }
    
    print(identity + name + structure + ":")
    let indent = "    "
    
    for issue in issues {
        let severity = issue.severity.description
        let message = issue.message
        let line = severity + ": " + message
        print(indent + line)
    }
}
func printDesignIssues(_ issues: [Issue], plane: some Plane) {
    print("[design]")
    
    for issue in issues {
        let severity = issue.severity.description
        let message = issue.message
        let line = severity + ": " + message
        print("    " + line)
    }
}

func printValidationResult(_ result: PlaneValidationResult, in plane: some Plane) {
    printDesignIssues(result.violationsAsIssues(), plane: plane)
    printIssues(result.objectIssues(), plane: plane)
}
