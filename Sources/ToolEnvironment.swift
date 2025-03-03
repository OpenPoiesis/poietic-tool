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
            catch let error as FrameValidationError {
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
            printValidationError(error, frame: frame)
            
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

private func printValidationError(_ error: FrameValidationError, frame: TransientFrame? = nil) {
    // FIXME: Print to stderr
    for violation in error.violations {
        let objects = violation.objects.map { $0.stringValue }.joined(separator: ",")
        print("Constraint error: \(violation.constraint.name) object IDs: \(objects)")
        if let abstract = violation.constraint.abstract {
            print("    - \(abstract)")
        }
    }
    if error.objectErrors.count > 0 {
        print("Object Errors:")
    }
    for item in error.objectErrors {
        let (id, typeErrors) = item
        
        let detail: String
        if let frame {
            detail = objectDetail(id, in: frame)
        }
        else {
            detail = "\(id)"
        }
        
        print("\(detail)")
        for typeError in typeErrors {
            print("    \(typeError)")
        }
    }
}
private func objectDetail(_ id: ObjectID, in frame: TransientFrame) -> String {
    guard frame.contains(id) else {
        return "\(id)"
    }
    
    var text: String = "\(id)"
    // id
    let object = frame[id]
    
    if let name = object.name {
        text += ":\(name)"
    }
    text += ":\(object.type.name)"
    
    if case let .edge(origin, target) = object.structure {
        let originObject = frame[origin]
        let targetObject = frame[target]
        
        text += " Edge \(origin)"
        
        if let name = originObject.name {
            text += ":\(name):\(originObject.type.name)"
        }
        else {
            text += ":\(originObject.type.name)"
        }

        text += " -> \(target)"
        if let name = targetObject.name {
            text += ":\(name):\(targetObject.type.name)"
        }
        else {
            text += ":\(targetObject.type.name)"
        }
        return text
    }
    
    return text
}
