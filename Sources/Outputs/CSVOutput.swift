//
//  CSVOutput.swift
//  poietic
//
//  Created by Stefan Urbanek on 31/08/2026.
//

import PoieticCore
import PoieticFlows

func writeCSV(path: String, view: SimulationResultView, nameFormat: VariableNameFormat, world: World) throws {
    
    let header = view.header(format: nameFormat, in: world)

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
