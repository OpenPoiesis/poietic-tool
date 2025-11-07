//
//  ValidateCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 09/03/2025.
//

@preconcurrency import ArgumentParser

extension PoieticTool {
    struct Validate: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Get information about the design")
        @OptionGroup var options: Options

        @Argument(help: "Frame ID or name to validate (current if not provided)")
        var frameRef: String?

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            let frame = try env.frame(frameRef)

            print("Frame validation passed.")
            let _ = try env.compile(frame)
            print("Frame compilation passed.")
        }
    }
}

