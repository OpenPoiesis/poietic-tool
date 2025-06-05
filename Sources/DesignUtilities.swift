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

// FIXME: Sync with poietic-godot and actually make cleaner, shared in PoieticFlows
func resolveParameters(objects: [ObjectSnapshot], view: StockFlowView) -> [ObjectID:ResolvedParameters] {
    var result: [ObjectID:ResolvedParameters] = [:]
    let builtinNames = Set(BuiltinVariable.allCases.map { $0.name })
    
    for object in objects {
        guard let formulaText = try? object["formula"]?.stringValue() else {
            continue
        }
        let parser = ExpressionParser(string: formulaText)
        guard let formula = try? parser.parse() else {
            continue
        }
        let variables: Set<String> = Set(formula.allVariables)
        let required = Array(variables.subtracting(builtinNames))
        let resolved = view.resolveParameters(object.objectID, required: required)
        result[object.objectID] = resolved
    }
    return result
}

/// Automatically connect parameters in a frame.
///
func autoConnectParameters(_ resolvedMap: [ObjectID:ResolvedParameters], in frame: TransientFrame) throws -> (added: [ParameterInfo], removed: [ParameterInfo]) {
    var added: [ParameterInfo] = []
    var removed: [ParameterInfo] = []
    

    for (id, resolved) in resolvedMap {
        let object = frame[id]
        for name in resolved.missing {
            guard let paramNode = frame.object(named: name) else {
                throw ToolError.unknownObject(name)
            }
            let edge = frame.createEdge(.Parameter, origin: paramNode.objectID, target: object.objectID)
            let info = ParameterInfo(parameterName: name,
                                     parameterID: paramNode.objectID,
                                     targetName: object.name,
                                     targetID: object.objectID,
                                     edgeID: edge.objectID)
            added.append(info)
        }

        for edge in resolved.unused {
            let node = frame.object(edge.origin)
            frame.removeCascading(edge.key)
            
            let info = ParameterInfo(parameterName: node.name,
                                     parameterID: node.objectID,
                                     targetName: object.name,
                                     targetID: object.objectID,
                                     edgeID: edge.key)
            removed.append(info)
        }
    }

    return (added: added, removed: removed)
}
