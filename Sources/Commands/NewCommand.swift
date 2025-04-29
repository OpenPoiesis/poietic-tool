//
//  File.swift
//  
//
//  Created by Stefan Urbanek on 11/01/2022.
//

@preconcurrency import ArgumentParser
import PoieticFlows
import PoieticCore

extension PoieticTool {
    struct NewDesign: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "new",
            abstract: "Create an empty design."
        )
        
        @OptionGroup var options: Options

        @Option(name: [.customLong("import"), .customShort("i")],
                help: "Poietic frame to import into the first frame")
        var importPaths: [String] = []

        mutating func run() throws {
            let design = Design(metamodel: StockFlowMetamodel)
            let env = try ToolEnvironment(location: options.designLocation, design: design)

            if !importPaths.isEmpty {
                let loader = ForeignFrameLoader()
                let frame = design.createFrame()

                for path in importPaths {
                    let foreignFrame = try readFrame(fromPath: path)
                    print("Importing from: \(path)")
                    do {
                        try loader.load(foreignFrame, into: frame)
                    }
                    catch {
                        throw ToolError.frameLoadingError(error)
                    }
                }
                
                try env.accept(frame)
            }
            
            try env.close()
            if env.url.scheme == nil || env.url.scheme == "file" {
                print("Design created: \(env.url.path)")
            }
            else {
                print("Design created: \(env.url)")
            }
        }
    }
}

