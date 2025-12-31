//
//  Modeller+Tool.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore
import PoieticFlows
import Foundation
import Diagramming

/// Systems to create a simulation plan.
enum PlanSchedule: ScheduleLabel {}
/// Systems to perform simulation and create presentation of results.
enum SimulateSchedule: ScheduleLabel {}
enum DiagramSchedule: ScheduleLabel {}

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

// TODO: Rename to Laboratory
public class DesignEditor {
    public let url: URL
    public let design: Design
    public let world: World

    /// Create a new editor given the URL and optional design.
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
        self.design = useDesign
        if let frame = self.design.currentFrame {
            self.world = World(frame: frame)
        }
        else {
            self.world = World(design: self.design)
        }
        self.world.setSystems(schedule: PlanSchedule.self,
                              systems: SystemGroup(PoieticFlows.SimulationPlanningSystems))
        self.world.setSystems(schedule: SimulateSchedule.self,
                              systems: SystemGroup(PoieticFlows.SimulationPlanningSystems
                                                   + PoieticFlows.SimulationPresentationSystems))
        let diagramCompositionSystems: SystemGroup = SystemGroup(
            BlockCreationSystem.self,
            TraitConnectorCreationSystem.self,
            ConnectorGeometrySystem.self
        )
        self.world.setSystems(schedule: DiagramSchedule.self, systems: diagramCompositionSystems)
    }
    convenience init(location: String?, design: Design? = nil) throws (ToolError) {
        try self.init(url: try designURL(location), design: design)
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
    func frame(required reference: String? = nil) throws (ToolError) -> FrameID? {
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

    /// Try to accept a frame in the modeller design.
    ///
    /// Tries to accept the frame. If the frame contains constraint violations, then
    /// the violations are printed out in a more human-readable format.
    ///
    func accept(_ trans: TransientFrame, replacing: String? = nil, appendHistory: Bool = true) throws (ToolError) {
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
