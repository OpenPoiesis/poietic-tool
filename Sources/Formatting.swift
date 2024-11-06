//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 30/06/2023.
//


func formatLabelledList(_ items: [(String?, String?)],
                        separator: String = ": ",
                        minimumWidth: Int? = nil) -> [String] {
    let maxWidth = items.map { $0.0?.count ?? 0 }.max() ?? 0
    let width = max(maxWidth, minimumWidth ?? 0)
    
    var result: [String] = []
    
    for (label, value) in items {
        let item: String

        if let label {
            let padding = String(repeating: " ", count: width - label.count)
            if let value {
                item = "\(label)\(padding)\(separator)\(value)"
            }
            else {
                item = "\(label)"
            }
        }
        else {
            if let value {
                let padding = String(repeating: " ", count: width)
                item = "\(padding)\(value)"
            }
            else {
                item = ""
            }
        }
        
        result.append(item)
    }
    
    return result
}

