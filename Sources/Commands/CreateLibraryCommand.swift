//
//  CreateLibraryCommand.swift
//
//
//  Created by Stefan Urbanek on 25/03/2024.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows
import Foundation


extension PoieticTool {
    struct CreateLibrary: ParsableCommand {
        static let configuration
            = CommandConfiguration(
                commandName: "create-library",
                abstract: "Create a library description for multiple models",
                discussion: """
The command creates a library description from a given list of design files (not a Poietic plane file).

Command extracts DesignInfo from the designs. If multiple instances of DesignInfo are present, then one is chosen arbitrarily.
""")

        @Option(name: [.long, .customShort("o")], help: "Output library file")
        var outputFile: String = "poietic-library.json"

        @Argument(help: "Paths to designs to be referenced by the library")
        var designs: [String]

        mutating func run() throws {
            let outputURL = URL(fileURLWithPath: outputFile)

            var items: [DesignLibraryItem] = []
            for location in designs {
                let item = try createLibraryItem(fromDesignAt: location)
                items.append(item)
            }

            let library = DesignLibraryInfo(items: items)
            
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            let data: Data

            // This should not fail, we do not have to guard and re-throw this.
            // If it fails, we have deeper problems...
            data = try encoder.encode(library)
            
            do {
                try data.write(to: outputURL)
            }
            catch {
                throw ToolError.unableToWrite(outputURL, error)
            }

            print("Created library: \(outputFile)")
        }
        
    }
}

func createLibraryItem(fromDesignAt location: String) throws -> DesignLibraryItem {
    // TODO: Add BibliographicalReferences
    guard let url = URL(string: location) else {
        throw ToolError.malformedLocation(location)
    }
    
    let actualURL = if url.scheme == nil {
        URL(fileURLWithPath: location, isDirectory: false).absoluteURL
    }
    else {
        url
    }

    let editor = try DesignSession(url: actualURL)

    guard let plane = editor.design.currentPlane else {
        throw ToolError.emptyDesign
    }

    let info = plane.filter(type: ObjectType.DesignInfo).first?.attributes ?? [:]
    
    let name: String
    if let infoName = try? info["name"]?.stringValue() {
        name = infoName
    }
    else {
        name = actualURL.lastPathComponent
    }

    return DesignLibraryItem(
        url: actualURL,
        name: name,
        title: (try? info["title"]?.stringValue()) ?? name
    )
}
