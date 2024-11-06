//
//  ToolEnvironment.swift
//  
//
//  Created by Stefan Urbanek on 31/05/2024.
//

import Foundation
import PoieticCore
import PoieticFlows

class ToolEnvironment {
    public private(set) var design: Design
    public let url: URL
    
    public var isOpen: Bool = true
    
    /// Get the design URL. The database location can be specified by options,
    /// environment variable or as a default name, in respective order.
    static func designURL(_ location: String?) throws (ToolError) -> URL {
        let actualLocation: String
        let env = ProcessInfo.processInfo.environment
        
        if let location {
            actualLocation = location
        }
        else if let location = env[DesignEnvironmentVariable] {
            actualLocation = location
        }
        else {
            actualLocation = DefaultDesignLocation
        }
        
        if let url = URL(string: actualLocation) {
            if url.scheme == nil {
                return URL(fileURLWithPath: actualLocation, isDirectory: false)
            }
            else {
                return url
            }
        }
        else {
            throw ToolError.malformedLocation(actualLocation)
        }
    }
    
    public convenience init(location: String?, design: Design? = nil) throws (ToolError) {
        try self.init(url: try Self.designURL(location), design: design)
    }

    public init(url: URL, design: Design? = nil) throws (ToolError) {
        self.url = url
        if let design {
            self.design = design
        }
        else {
            let store = MakeshiftDesignStore(url: url)
            let design: Design
            do {
                // TODO: remove the metamodel here
                design = try store.load(metamodel: FlowsMetamodel)
            }
            catch let error as FrameConstraintError {
                printValidationError(error)
                throw ToolError.constraintViolationError(error)
                
            }
            catch let error as PersistentStoreError {
                throw ToolError.storeError(error)
            }
            catch {
                throw ToolError.unknownError(error)
            }
            
            self.design = design
        }
    }

    /// Try to accept a frame in a design.
    ///
    /// Tries to accept the frame. If the frame contains constraint violations, then
    /// the violations are printed out in a more human-readable format.
    ///
    public func accept(_ frame: TransientFrame) throws (ToolError) {
        precondition(isOpen, "Trying to accept already closed design: \(url)")

        do {
            try design.accept(frame)
        }
        catch {
            printValidationError(error)

            throw ToolError.constraintViolationError(error)
        }
    }
    
    public func close() throws (ToolError) {
        precondition(isOpen, "Trying to close already closed design: \(url)")
        
        let store = MakeshiftDesignStore(url: url)
        do {
            try store.save(design: design)
        }
        catch {
            throw ToolError.unableToSaveDesign(error)
        }
        isOpen = false
    }
}

private func printValidationError(_ error: FrameConstraintError) {
    // FIXME: Print to stderr
    for violation in error.violations {
        let objects = violation.objects.map { String($0) }.joined(separator: ",")
        print("Constraint error: \(violation.constraint.name) object IDs: \(objects)")
        if let abstract = violation.constraint.abstract {
            print("    - \(abstract)")
        }
    }
    for item in error.objectErrors {
        let (id, typeErrors) = item
        for typeError in typeErrors {
            print("Type error:\(id): \(typeError)")
        }
    }
}
