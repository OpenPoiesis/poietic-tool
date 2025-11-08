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

class OLD_ToolEnvironment {
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
            let store = DesignStore(url: url)
            let design: Design
            do {
                // TODO: remove the metamodel here
                design = try store.load(metamodel: StockFlowMetamodel)
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
    func frame(_ reference: String? = nil) throws (ToolError) -> DesignFrame {
        guard let frame = try frameIfPresent(reference) else {
            throw .noCurrentFrame
        }
        return frame
    }

    /// Get a frame by given ID as a string or current frame.
    ///
    /// Use this method to get a frame by user-provided reference.
    ///
    /// - Throws ``ToolError/unknownFrame(_:)`` when the frame is not found.
    ///
    func frameIfPresent(_ reference: String? = nil) throws (ToolError) -> DesignFrame? {
        if let reference {
            if let id = FrameID(reference), let frame = design.frame(id) {
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

    func runtimeFrame(_ reference: String? = nil) throws (ToolError) -> RuntimeFrame {
        let frame = try frame(reference)
        return RuntimeFrame(frame)
    }

    /// Derive a frame from existing frame, if the reference is valid or create a new frame if
    /// there is no current frame.
    ///
    /// - Throws ``ToolError/unknownFrame(_:)`` when the frame is not found or
    ///   ``ToolError/emptyDesign`` if there are no frames in the design.
    ///
    func deriveOrCreate(_ reference: String? = nil) throws (ToolError) -> TransientFrame {
        if let reference {
            if let original = try frameIfPresent(reference) {
                return design.createFrame(deriving: original)
            }
            else {
                throw .unknownFrame(reference)
            }
        }
        else if let original = design.currentFrame {
            return design.createFrame(deriving: original)
        }
        else {
            return design.createFrame()
        }
    }


    /// Try to accept a frame in a design.
    ///
    /// Tries to accept the frame. If the frame contains constraint violations, then
    /// the violations are printed out in a more human-readable format.
    ///
    func accept(_ trans: TransientFrame, replacing: String? = nil, appendHistory: Bool = true) throws (ToolError) {
        precondition(isOpen, "Trying to accept already closed design: \(url)")
        
        do {
            if let name = replacing {
                try design.accept(trans, replacingName: name)
            }
            else {
                try design.accept(trans, appendHistory: appendHistory)
            }
        }
        catch {
            switch error {
            case let .brokenStructuralIntegrity(subError):
                throw ToolError.brokenStructuralIntegrity(subError)
            case .constraintViolation(_),
                    .edgeRuleViolation(_, _),
                    .objectTypeError(_, _):
                let checker = ConstraintChecker(trans.design.metamodel)
                let result = checker.diagnose(trans)
                printValidationResult(result, in: trans)
                throw ToolError.validationFailed(result)
            }
        }
    }

//    /// Try to compile the frame.
//    ///
//    /// If the frame is successfully compiled then the simulation plan returned.
//    ///
//    /// If the frame compilation failed, errors are printed and a ``ToolError`` is thrown.
//    ///
//    @discardableResult
//    func compile(_ frame: DesignFrame) throws (ToolError) -> SimulationPlan {
//        let compiler = Compiler(frame: frame)
//        do {
//            return try compiler.compile()
//        }
//        catch {
//            switch error {
//            case .issues(let issues):
//                printObjectIssuesError(issues, in: frame)
//                throw .compilationFailed(issues)
//            case .internalError(let error):
//                throw .internalError(error)
//            }
//        }
//    }
//    
//    @discardableResult
//    func createSimulationPlan(_ runtime: RuntimeFrame) throws (ToolError) -> SimulationPlan {
//        let systems = SystemGroup()
//        systems.register(SimulationPlanningSystemGroup)
//
//        do {
//            try systems.update(runtime)
//        }
//        catch {
//            throw .internalSystemError(error)
//        }
//        
//        if runtime.hasIssues {
//            printObjectIssuesError(runtime.issues, in: runtime)
//        
//        }
//        guard let plan = runtime.frameComponent(SimulationPlan.self) else {
//            // TODO: What to do now? we should not have no issues and no plan
//            fatalError("Plan was not created")
//        }
//        return plan
//    }

    /// Close with saving the modified design.
    func closeAndSave() throws (ToolError) {
        precondition(isOpen, "Trying to close already closed design: \(url)")
        
        let store = DesignStore(url: url)
        do {
            try store.save(design: design)
        }
        catch {
            throw ToolError.unableToSaveDesign(error)
        }
        isOpen = false
    }
    
    /// Close without saving the design.
    ///
    func close() throws (ToolError) {
        precondition(isOpen, "Trying to close already closed design: \(url)")
        isOpen = false
    }

}


