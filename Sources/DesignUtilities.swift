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
func autoConnectParameters(_ frame: TransientFrame) throws -> (added: [ParameterInfo], removed: [ParameterInfo]) {
    let view = StockFlowView(frame)
    var added: [ParameterInfo] = []
    var removed: [ParameterInfo] = []
    
    let builtinNames: Set<String> = Set(Simulator.BuiltinVariables.map {
        $0.name
    })

    let context = RuntimeContext(frame: frame)
    var formulaCompiler = FormulaCompilerSystem()
    formulaCompiler.update(context)

    for target in view.simulationNodes {
        guard let component: ParsedFormulaComponent = context.component(for: target.id) else {
            continue
        }
        let allNodeVars: Set<String> = Set(component.parsedFormula.allVariables)
        let required = Array(allNodeVars.subtracting(builtinNames))
        let resolved = view.resolveParameters(target.id, required: required)
        
        for name in resolved.missing {
            guard let paramNode = frame.object(named: name) else {
                throw ToolError.unknownObject(name)
            }
            let edge = frame.createEdge(.Parameter, origin: paramNode.id, target: target.id)
            let info = ParameterInfo(parameterName: name,
                                     parameterID: paramNode.id,
                                     targetName: target.name,
                                     targetID: target.id,
                                     edgeID: edge.id)
            added.append(info)
        }

        for edge in resolved.unused {
            let node = frame.object(edge.origin)
            frame.removeCascading(edge.id)
            
            let info = ParameterInfo(parameterName: node.name,
                                     parameterID: node.id,
                                     targetName: target.name,
                                     targetID: target.id,
                                     edgeID: edge.id)
            removed.append(info)
        }
    }

    return (added: added, removed: removed)
}
