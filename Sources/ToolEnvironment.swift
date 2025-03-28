//
//  ToolEnvironment.swift
//  
//
//  Created by Stefan Urbanek on 31/05/2024.
//

@preconcurrency import ArgumentParser
import Foundation
import PoieticCore
import PoieticFlows

class ToolEnvironment {
    private(set) var design: Design
    let url: URL
    
    var isOpen: Bool = true
    
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
    
    convenience init(location: String?, design: Design? = nil) throws (ToolError) {
        try self.init(url: try Self.designURL(location), design: design)
    }
    
    /// Create a new tool environment given the URL and optional design.
    ///
    /// If the design is provided, then it is used and the URL is assigned as a storage URL
    /// of the design.
    ///
    /// If the design is not provided, then it is attempted to load from the URL.
    ///
    /// - Warning: If both the design and URL are provided, the provided design will potentially
    ///            overwrite the design currently present at the URL.
    ///
    init(url: URL, design: Design? = nil) throws (ToolError) {
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
            catch {
                throw ToolError.storeError(error)
            }
            
            self.design = design
        }
    }
    
    /// Get a frame by its name or an ID reference.
    ///
    /// Use this method to get a frame by user-provided reference.
    ///
    func frame(_ reference: String) -> DesignFrame? {
        if let frame = design.frame(name: reference) {
            return frame
        }
        else if let id = ObjectID(reference), let frame = design.frame(id) {
            return frame
        }
        else {
            return nil
        }
    }

    /// Get a frame by ID or a name. If reference is not provided, get
    /// the current frame.
    ///
    /// - Throws ``ToolError/unknownFrame(_:)`` when the frame is not found or
    ///   ``ToolError/emptyDesign`` if there are no frames in the design.
    ///
    func existingFrame(_ reference: String? = nil) throws (ToolError) -> DesignFrame {
        if let reference {
            if let frame = frame(reference) {
                return frame
            }
            else {
                throw .unknownFrame(reference)
            }
        }
        else {
            if let frame = design.currentFrame {
                return frame
            }
            else {
                throw .emptyDesign
            }
        }
    }

    /// Get a frame by given ID as a string or current frame.
    ///
    /// Use this method to get a frame by user-provided reference.
    ///
    /// - Throws ``ToolError/unknownFrame(_:)`` when the frame is not found.
    ///
    func frameIfPresent(_ reference: String? = nil) throws (ToolError) -> DesignFrame? {
        if let reference {
            if let id = ObjectID(reference), let frame = design.frame(id) {
                return frame
            }
            else {
                throw ToolError.unknownFrame(reference)
            }
        }
        else {
            if let frame = design.currentFrame {
                return frame
            }
            else {
                return nil
            }
        }
    }

    /// Try to accept a frame in a design.
    ///
    /// Tries to accept the frame. If the frame contains constraint violations, then
    /// the violations are printed out in a more human-readable format.
    ///
    func accept(_ frame: TransientFrame, replacing: String? = nil) throws (ToolError) {
        precondition(isOpen, "Trying to accept already closed design: \(url)")
        
        let stableFrame: DesignFrame

        if let name = replacing {
            do {
                stableFrame = try design.accept(frame, replacingName: name)
            }
            catch {
                throw ToolError.brokenStructuralIntegrity(error)
            }
        }
        else {
            do {
                stableFrame = try design.accept(frame)
            }
            catch {
                throw ToolError.brokenStructuralIntegrity(error)
            }
        }
        
        try validate(stableFrame)
    }
   
    /// Try to validate the frame.
    ///
    /// If the frame is successfully validated then its validated version is returned.
    ///
    /// If the frame validation failed, errors are printed and a ``ToolError`` is thrown.
    ///
    @discardableResult
    func validate(_ frame: DesignFrame) throws (ToolError) -> ValidatedFrame {
        do {
            return try design.validate(frame)
        }
        catch {
            let issues = error.asDesignIssueCollection()
            printObjectIssuesError(issues, in: frame)
            throw .validationFailed(issues)
        }
    }
    
    /// Try to compile the frame.
    ///
    /// If the frame is successfully compiled then the simulation plan returned.
    ///
    /// If the frame compilation failed, errors are printed and a ``ToolError`` is thrown.
    ///
    @discardableResult
    func compile(_ frame: ValidatedFrame) throws (ToolError) -> SimulationPlan {
        let compiler = Compiler(frame: frame)
        do {
            return try compiler.compile()
        }
        catch {
            switch error {
            case .issues(let issues):
                let designIssues = issues.asDesignIssueCollection()
                printObjectIssuesError(designIssues, in: frame)
                throw .compilationFailed(designIssues)
            case .internalError(let error):
                throw .internalError(error)
            }
        }
    }
    
    func close() throws (ToolError) {
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


func printObjectIssuesError(_ issues: DesignIssueCollection, in frame: some Frame) {
    print("DESIGN ISSUES:")
    for issue in issues.designIssues {
        print("ERROR: \(issue)")
    }
    for (id, objIssues) in issues.objectIssues {
        let detail = objectDetail(id, in: frame)
        print("Object \(detail):")
        for issue in objIssues {
            print("      \(issue)")
        }
    }

}

private func objectDetail(_ id: ObjectID, in frame: some Frame) -> String {
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
