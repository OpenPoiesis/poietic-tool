//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 30/06/2023.
//

@preconcurrency import ArgumentParser
import PoieticCore
import Markdown

// TODO: Add output to JSON
// TODO: Add output to CSV

extension PoieticTool {
    struct MetamodelCommand: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "metamodel",
                abstract: "Show information about the metamodel and object types"
            )

        @OptionGroup var options: Options

        enum OutputFormat: String, CaseIterable, ExpressibleByArgument{
            case text = "text"
            case markdown = "markdown"
            case html = "html"
            var defaultValueDescription: String { "text" }
            
            static var allValueStrings: [String] {
                OutputFormat.allCases.map { "\($0)" }
            }
        }
        @Option(name: [.long, .customShort("f")], help: "Output format")
        var outputFormat: OutputFormat = .text
        
        @Argument(help: "Object type to show")
        var objectType: String?

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let metamodel = env.design.metamodel
            
            if let typeName = objectType {
                guard let type = metamodel.objectType(name: typeName) else {
                    throw ToolError.unknownObjectType(typeName)
                }
                
                printType(type, format: outputFormat)
            }
            else {
                printAll(metamodel, format: outputFormat)
            }
            try env.closeAndSave()
        }
        
        func printType(_ type: ObjectType,
                       format: OutputFormat) {
            switch format {
            case .text: printTypeAsText(type)
            case .markdown: printTypeAsMarkdown(type)
            case .html: printTypeAsHTML(type)
            }
        }
        func printAll(_ metamodel: Metamodel,
                      format: OutputFormat) {
            switch format {
            case .text: printAllAsText(metamodel)
            case .markdown: printAllAsMarkdown(metamodel)
            case .html: printAllAsHTML(metamodel)
            }
        }
    }

}

// Output: Text
// -------------------------------------------------------------------------
func printAllAsText(_ metamodel: Metamodel) {
    print("TYPES AND COMPONENTS\n")

    for type in metamodel.types {
        printTypeAsText(type)
        print("")
    }
    
    print("\nCONSTRAINTS\n")
    
    for constr in metamodel.constraints {
        print("\(constr.name): \(constr.abstract ?? "(no description)")")
    }
    
    print("")

}

func printTypeAsText(_ type: ObjectType) {
    print("\(type.name) (\(type.structuralType))")

    if type.traits.isEmpty {
        print("    (no components)")
    }
    else {
        for attr in type.attributes {
            if let abstract = attr.abstract {
                print("    \(attr.name) (\(attr.type))")
                print("        - \(abstract)")
            }
            else {
                print("    \(attr.name) (\(attr.type))")
            }
        }
    }
}

// Output: Markdown
// -------------------------------------------------------------------------
func printAllAsMarkdown(_ metamodel: Metamodel) {
    let text = metamodel.asMarkdown().format()
    print(text)
}

func printTypeAsMarkdown(_ type: ObjectType) {
    let text = type.asMarkdown().format()
    print(text)
}

// Output: HTML
// -------------------------------------------------------------------------
func printAllAsHTML(_ metamodel: Metamodel) {
    let doc = metamodel.asMarkdown()
    let text = HTMLFormatter.format(doc)
    print(text)
}

func printTypeAsHTML(_ type: ObjectType) {
    let doc = type.asMarkdown()
    let text = HTMLFormatter.format(doc)
    print(text)
}
