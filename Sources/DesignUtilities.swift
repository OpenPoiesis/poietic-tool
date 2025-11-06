//
//  DesignUtilities.swift
//
//
//  Created by Stefan Urbanek on 12/03/2024.
//

// INCUBATOR for design manipulation utilities.
//
// Most of the functionality is this file might be a candidate for inclusion
// in the Flows library.
//
// This file contains functionality that might be more complex, not always
// trivial manipulation of the frame.
//
// Once happy with the function/structure, consider moving to Flows or even Core
// library.
//

import PoieticFlows
import PoieticCore

public struct ParameterInfo {
    /// Name of the parameter
    let parameterName: String?
    /// ID of the parameter node
    let parameterID: ObjectID
    /// Name of node using the parameter
    let targetName: String?
    /// ID of node using the parameter
    let targetID: ObjectID
    /// ID of the edge from the parameter to the target
    let edgeID: ObjectID
}

/// Automatically connect parameters in a frame.
///

func autoConnectParameters(runtime: RuntimeFrame, trans: TransientFrame)
throws -> (added: [ParameterInfo], removed: [ParameterInfo]) {
    var added: [ParameterInfo] = []
    var removed: [ParameterInfo] = []

    guard let component = runtime.frameComponent(SimulationNameLookupComponent.self) else {
        return (added: [], removed:[])
    }

    for (id, comp) in runtime.filter(ResolvedParametersComponent.self) {
        guard let object = trans[id] else { continue }
        let result = autoConnect(object,
                                 missing: comp.missing,
                                 unused: comp.unused,
                                 nameLookup: component.namedObjects,
                                 in: trans)
        added += result.added
        removed += result.removed
    }
    return (added: added, removed: removed)
}
func autoConnect(_ object: ObjectSnapshot,
                 missing: [String],
                 unused: [ObjectID],
                 nameLookup: [String:ObjectID],
                 in trans: TransientFrame)
-> (added: [ParameterInfo], removed: [ParameterInfo]) {
    var added: [ParameterInfo] = []
    var removed: [ParameterInfo] = []

    for edgeID in unused {
        guard let edge = trans.edge(edgeID) else {continue}
        trans.removeCascading(edge.key)
        
        let info = ParameterInfo(parameterName: edge.originObject.name,
                                 parameterID: edge.origin,
                                 targetName: edge.targetObject.name,
                                 targetID: edge.target,
                                 edgeID: edge.key)
        removed.append(info)
    }
    
    for name in missing {
        guard let parameterID = nameLookup[name],
              let parameter = trans[parameterID]
        else {
            continue // gracefully
        }
        let edge = trans.createEdge(.Parameter, origin: parameter.objectID, target: object.objectID)
        let info = ParameterInfo(parameterName: name,
                                 parameterID: parameterID,
                                 targetName: object.name,
                                 targetID: object.objectID,
                                 edgeID: edge.objectID)
        added.append(info)
    }

    return (added: added, removed: removed)
}
