//
//  BuiltinsCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 28/08/2026.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows


extension PoieticTool {
    struct BuiltinsCommand: ParsableCommand {
        static let configuration
        = CommandConfiguration(
            commandName: "builtins",
            abstract: "List built-in functions, operators and variables"
        )
        
        mutating func run() throws {
            print("OPERATORS (highest precedence first)")
            print("  -   (unary) negation")
            print("  ^   Power")
            print("  *   Multiplication")
            print("  /   Division")
            print("  %   Modulo")
            print("  +   Addition")
            print("  -   Subtraction")
            print("  <   Less than")
            print("  <=  Less than or equal")
            print("  >   Greater than")
            print("  >=  Greater than or equal")
            print("  ==  Equal")
            print("  !=  Not equal")

            print("\nBUILT-IN FUNCTIONS")
                
            let functions = BuiltinFunction.allCases.sorted { lhs, rhs in
                lhs.name < rhs.name
            }
            
            let items: [(String?, String?)] = functions.map {
                ($0.descriptionWithSignature, $0.abstract)
            }
            let formattedItems = formatLabelledList(items, separator: "  ")
            
            for item in formattedItems {
                print("  " + item)
            }

            print("\nBUILT-IN VARIABLES")

            let varItems: [(String?, String?)] = BuiltinVariable.allCases.map {
                ($0.info.name, $0.info.abstract)
            }
            let formattedVars = formatLabelledList(varItems, separator: "  ")
            
            for item in formattedVars {
                print("  " + item)
            }
        }
    }
}
