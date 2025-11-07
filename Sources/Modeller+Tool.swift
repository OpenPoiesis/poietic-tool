//
//  Modeller+Tool.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore
import PoieticFlows
import Foundation

enum SystemConfiguration {
    case inspection
    case planning
    case simulation
    
    var systemGroup: SystemGroup {
        switch self {
        case .inspection: return SystemGroup(PoieticFlows.ModelInspectionSystemGroup)
        case .planning: return SystemGroup(PoieticFlows.SimulationPlanningSystemGroup)
        case .simulation: return SystemGroup(PoieticFlows.SimulationPresentationSystemGroup)
        }
        
    }
}

/// Get the design URL. The database location can be specified by options,
/// environment variable or as a default name, in respective order
func designURL(_ location: String?) throws (ToolError) -> URL {
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


class ModellerTool: Modeller {
    let url: URL
    
    /// Create a new modeller given the URL and optional design.
    ///
    /// If the design is provided, then it is used and the URL is assigned as a storage URL
    /// of the design.
    ///
    /// If the design is not provided, then it is attempted to load from the URL.
    ///
    /// - Warning: If both the design and URL are provided, the provided design will potentially
    ///            overwrite the design currently present at the URL.
    ///
    init(url: URL, design: Design? = nil, configuration: SystemConfiguration = .inspection) throws (ToolError) {
        self.url = url
        let useDesign: Design
        if let design {
            useDesign = design
        }
        else {
            let store = DesignStore(url: url)
            do {
                // TODO: remove the metamodel here
                useDesign = try store.load(metamodel: StockFlowMetamodel)
            }
            catch {
                throw ToolError.storeError(error)
            }
        }
        super.init(design: useDesign, systems: configuration.systemGroup)
    }
    convenience init(location: String?, design: Design? = nil, configuration: SystemConfiguration = .inspection) throws (ToolError) {
        try self.init(url: try designURL(location), design: design, configuration: configuration)
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
    

    /// Get frame ID from a frame reference, which can be either frame ID or frame name.
    ///
    /// - Returns: Frame ID of resolved reference or `nil` if no such frame exists.
    public func frame(required reference: String? = nil) throws (ToolError) -> FrameID? {
        if let reference {
            if let frameID = FrameID(reference), design.containsFrame(frameID) {
                return frameID
            }
            else {
                throw .unknownFrame(reference)
            }
        }
        else {
            return design.currentFrameID
        }
    }
    
    /// Get a frame by given ID as a string or current frame.
    ///
    /// - If ID is provided: tries to find it, otherwise throws an error.
    /// - If ID is not provided:
    ///     - If current frame is set: use current frame.
    ///     - There is only one frame: use the only frame.
    ///     - Otherwise return nil
    ///
    /// Use this method to get a frame by user-provided reference.
    ///
    /// - Throws ``ToolError/unknownFrame(_:)`` when the frame is not found.
    ///
    func frameIfPresent(_ requiredReference: String? = nil) throws (ToolError) -> DesignFrame? {
        if let requiredReference {
            if let id = FrameID(requiredReference), let frame = design.frame(id) {
                return frame
            }
            else {
                throw ToolError.unknownFrame(requiredReference)
            }
        }
        else {
            if let frame = design.currentFrame {
                return frame
            }
            else if design.frames.count == 1 {
                return design.frames.first!
            }
            else {
                return nil
            }
        }
    }
    
    /// Get a runtime frame by named reference, if it exists.
    ///
    /// - Throws: ``ToolError/unknownFrame`` if the frame does not exist.
    ///
    public func createRuntime(frameReference: String? = nil) throws (ToolError) -> RuntimeFrame {
        let frame = try frame(frameReference)
        return RuntimeFrame(frame)
    }
    
    /// Save the design.
    func save() throws (ToolError) {
        let store = DesignStore(url: url)
        do {
            try store.save(design: design)
        }
        catch {
            throw ToolError.unableToSaveDesign(error)
        }
    }
}
