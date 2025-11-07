//
//  Output.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore

func printIssues(_ runtime: RuntimeFrame) {
    printIssues(runtime.issues, frame: runtime)
}
func printIssues(_ issues: [ObjectID:[Issue]], frame: some Frame) {
    // FIXME: Use stderr
    print("DESIGN ISSUES:")
    for (objectID, objectIssues) in issues {
        printObjectIssues(objectID, issues: objectIssues, frame: frame)
    }
}

func printObjectIssues(_ objectID: ObjectID, issues: [Issue], frame: some Frame) {
    /*
     [1234] Stock (ProductionRate):
     error: Cycle detected in flow network
     warning: Unused stock - no incoming flows
     error: Initial value must be positive
     
     [2545] Flow (DrainRate) [1234 → 1235]:
     error: Negative flow rate not allowed
     warning: Flow rate exceeds capacity limits
     */
    guard let object = frame[objectID] else { return }
    let identity = "[\(objectID)] \(object.type.name)"
    let name: String = object.name.map { " (\($0))" } ?? ""
    let structure: String
    
    switch object.structure {
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
func printDesignIssues(_ issues: [Issue], frame: some Frame) {
    print("[design]")
    
    for issue in issues {
        let severity = issue.severity.description
        let message = issue.message
        let line = severity + ": " + message
        print("    " + line)
    }
}

func printValidationResult(_ result: FrameValidationResult, in frame: some Frame) {
    printDesignIssues(result.violationsAsIssues(), frame: frame)
    printIssues(result.objectIssues(), frame: frame)
}
