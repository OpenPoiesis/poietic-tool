//
//  DesignSession.swift
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

class DesignSession {
    let url: URL
    let design: Design
    let world: World
    
    // TODO: [REFACTORING] Allow specifying reference on init()
    // TODO: [REFACTORING] Keep one transaction (fatal error on multiple attempts), and then accept on save()

    /// Create a new session given the URL and optional design.
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
        if let plane = self.design.currentPlane {
            self.world = World(plane: plane)
        }
        else {
            self.world = World(design: self.design)
        }
        // TODO: [IMPORTANT][REFACTORING] Validate schedules
        self.world.addSchedule(Schedule(
            label: PlanSchedule.self,
            systems: PoieticFlows.SimulationPlanningSystems
        ))
        self.world.addSchedule(Schedule(
            label: SimulateSchedule.self,
            systems: PoieticFlows.SimulationRunningSystems
                     + [PoieticFlows.ChartResolutionSystem.self]
        ))
        
        self.world.addSchedule(Schedule(
            label: DiagramSchedule.self,
            systems:
                TraitsToDiagramObjectsSystem.self,
        ))
    }
    
    convenience init(location: String?, design: Design? = nil) throws (ToolError) {
        try self.init(url: try designURL(location), design: design)
    }
    
    /// Get a plane by reference or default plane.
    ///
    /// If the plane reference is specified: function tries to find a plane with given ID or name.
    /// If no plane with given reference exists, then it throws ``ToolError/unknownPlane(_:)``.
    ///
    /// If no plane reference is specified: try to use current plane. If no current plane
    /// is found, then return the only plane in design. If multiple planes exist in the design,
    /// then the function throws ``ToolError/planeRequired``
    ///
    /// Use this method to get a plane by user-provided reference.
    ///
    func plane(_ reference: String? = nil) throws (ToolError) -> DesignPlane {
        if let reference {
            if let id = PlaneID(reference), let plane = design.plane(id) {
                return plane
            }
            else if let plane = design.plane(name: reference){
                return plane
            }
            else {
                throw .unknownPlane(reference)
            }
        }
        else {
            if let plane = design.currentPlane {
                return plane
            }
            else if design.planes.count == 1, let plane = design.planes.first {
                return plane
            }
            else {
                throw .planeRequired
            }
        }
    }

//    func defaultPlane() -> DesignPlane? {
//        if let plane = design.currentPlane {
//            return plane
//        }
//        else if design.planes.count == 1, let plane = design.planes.first {
//            return plane
//        }
//        else {
//            return nil
//        }
//    }
    
    /// Derive a plane from existing plane, if the reference is valid. Create a new plane if
    /// there is no current plane.
    ///
    /// - Throws ``ToolError/unknownPlane(_:)`` when the plane is not found or
    ///   ``ToolError/emptyDesign`` if there are no planes in the design.
    ///
    func deriveOrCreate(_ reference: String? = nil) throws (ToolError) -> TransientPlane {
        // TODO: [REFACTORING] Is this good logic? Verify!
        let trans: TransientPlane
        
        do {
            let original = try plane(reference)
            trans = design.createPlane(deriving: original)
        }
        catch .planeRequired {
            guard design.planes.count == 0 else {
                throw .planeRequired
            }
            trans = design.createPlane()
        }
        
        return trans
    }

    /// Try to accept a plane in the modeller design.
    ///
    /// Tries to accept the plane. If the plane contains constraint violations, then
    /// the violations are printed out in a more human-readable format.
    ///
    func accept(_ trans: TransientPlane, replacing: String? = nil, appendHistory: Bool = true) throws (ToolError) {
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
