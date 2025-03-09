//
//  ValidateCommand.swift
//  poietic
//
//  Created by Stefan Urbanek on 09/03/2025.
//

@preconcurrency import ArgumentParser
import PoieticCore
import PoieticFlows

extension PoieticTool {
    struct Validate: ParsableCommand {
        static let configuration
            = CommandConfiguration(abstract: "Get information about the design")
        @OptionGroup var options: Options

        @Argument(help: "Frame ID to validate (current if not provided)")
        var frameID: String?

        mutating func run() throws {
            let env = try ToolEnvironment(location: options.designLocation)
            
            guard let frame = try env.frameIfPresent(frameID) else {
                throw CleanExit.message("No current frame")
            }
            
            let validFrame = try env.validate(frame)
            print("Frame validation passed.")
            let _ = try env.compile(validFrame)
            print("Frame compilation passed.")
        }
    }
}

