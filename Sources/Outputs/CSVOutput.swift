//
//  CSVOutput.swift
//  poietic
//
//  Created by Stefan Urbanek on 31/08/2026.
//

import PoieticCore
import PoieticFlows

public enum VariableNameFormat: CaseIterable {
    case normalized
    case display
    // case objectID
}

func header(variables: [StateVariable],
            format: VariableNameFormat,
            in world: World) -> [String]
{
    var header: [String] = []
    for variable in variables {
        let item: String
        switch format {
        case .normalized: item = variable.name
        case .display:
            if let objectID = variable.objectID,
               let entity = world.entity(objectID),
               let normalized: NormalizedName = entity.component()
            {
                item = normalized.displayName
            }
            else if case let .builtin(builtin) = variable.content {
                item = builtin.name
            }
            else {
                item = variable.name
            }
        }
        header.append(item)
    }
    return header
}

func writeCSV(path: String,
              view: SimulationResultView,
              nameFormat: VariableNameFormat,
              world: World) throws
{
    let header = header(variables: view.variables, format: nameFormat, in: world)

    let writer: CSVWriter
    if path == "-" {
        writer = CSVWriter(.standardOutput)
    }
    else {
        writer = try CSVWriter(path: path)
    }
    try writer.write(row: header)
    
    for variantRow in view {
        let stringRow = try variantRow.values.map { try $0.stringValue() }
        try writer.write(row: stringRow)
    }
    try writer.close()
    
}
