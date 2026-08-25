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

/// Main object managing a command-line session.
///
/// Usage:
///
/// - Session starts with ``init(url:design:)``.
/// - ``setPlane(reference:)`` resolves and sets the world's plane.
/// - A session without a transaction needs no explicit ending.
/// - The session owns **one** transaction created by ``createTransaction(deriving:)`` or ``createTransaction()``.
/// - Session is concluded with ``save(replacing:appendHistory:)``, which accept pending transaction
///   (if any) + persist the design. On failed accept, print design errors and throw.
///
/// ## Examples
///
/// Typical command that uses a plane contains the following option:
///
/// ```
/// @Option(name: [.customLong("plane")],
///         help: "Plane to get object from. Default is current plane")
/// var planeReference: String?
/// ```
///
/// Read-only commands get the plane and use the plane directly or world with the plane:
///
/// ```swift
/// let session = try DesignSession(location: options.designLocation)
/// let plane = try session.setPlane(planeReference)
///
/// // Use plane ...
///
/// // Run systems, query entities and components, ...
/// session.world.run(systems: ...)
/// ```
///
/// Commands that edit planes:
///
/// ```swift
/// let session = try DesignSession(location: options.designLocation)
/// // Begin editing session by creating a transaction
/// let trans = try session.createTransaction(planeReference)
///
/// // Make changes ...
/// let object = trans.mutate(...)
/// object["name"] = "New Name"
///
/// // Accept transaction and persist the design
/// session.save()
/// ```
///
class DesignSession {
    let url: URL
    let design: Design
    let world: World
    
    /// Plane we are working with.
    ///
    var plane: DesignPlane? { world.plane }
    
    /// Current transaction
    ///
    /// - SeeAlso: ``save(replacing:appendHistory:)``, ``createTransaction(deriving:)``, ``createTransaction()``
    ///
    var transaction: TransientPlane? = nil
    
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
                VisualMetadataSystem.self,
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
    
    /// Set a design plane by reference and populate the world.
    ///
    /// See ``plane(_:)`` for more information about reference rules.
    ///
    @discardableResult
    func setPlane(_ reference: String? = nil) throws (ToolError) -> DesignPlane {
        let plane = try plane(reference)
        self.world.setPlane(plane)
        return plane
    }
    
    /// Create a new transaction deriving a plane with given reference.
    ///
    /// If the reference is `nil` then current plane is tried, if there is no current plane
    /// then the only plane in design is used. If the design has multiple planes, the function
    /// throws.
    ///
    /// - Note: This function differs from the ``createTransaction()`` in the way that on
    ///   `nil` references it is checking for defaults. This function _requires_ an existing
    ///   plane.
    ///
    /// - Throws ``ToolError/unknownPlane(_:)`` when the plane is not found or
    ///   ``ToolError/planeRequired`` if there are no planes in the design or more than one plane
    ///   without current plane set.
    ///
    /// - SeeAlso: ``createTransaction()``
    ///
    func createTransaction(deriving reference: String?) throws (ToolError) -> TransientPlane {
        let original = try plane(reference)
        return _createTransaction(deriving: original)
    }

    /// Create transaction without deriving any existing plane.
    ///
    /// Function does not require any planes to exist in the design.
    ///
    func createTransaction() -> TransientPlane {
        return _createTransaction(deriving: nil)
    }

    private func _createTransaction(deriving original: DesignPlane?) -> TransientPlane {
        precondition(transaction == nil) // This is our programming problem, not throwing.
        let trans = design.createPlane(deriving: original)
        self.transaction = trans
        return trans
    }

    /// Accept pending transaction and save the design.
    func save(replacing: String? = nil, appendHistory: Bool = true) throws (ToolError) {
        if let transaction {
            try _accept(transaction, replacing: replacing, appendHistory: appendHistory)
            self.transaction = nil
        }
        
        let store = DesignStore(url: url)
        do {
            try store.save(design: design)
        }
        catch {
            throw ToolError.unableToSaveDesign(error)
        }
    }
    
    /// Try to accept a plane in the modeller design.
    ///
    /// Tries to accept the plane. If the plane contains constraint violations, then
    /// the violations are printed out in a more human-readable format.
    ///
    private func _accept(_ transaction: TransientPlane, replacing: String? = nil, appendHistory: Bool = true) throws (ToolError) {
        do {
            if let name = replacing {
                try design.accept(transaction, replacingName: name)
            }
            else {
                try design.accept(transaction, appendHistory: appendHistory)
            }
        }
        catch {
            switch error {
            case let .brokenStructuralIntegrity(subError):
                throw ToolError.brokenStructuralIntegrity(subError)
            case .constraintViolation(_),
                    .edgeRuleViolation(_, _),
                    .objectTypeError(_, _):
                let checker = ConstraintChecker(transaction.design.metamodel)
                let result = checker.diagnose(transaction)
                printValidationResult(result, in: transaction)
                throw ToolError.validationFailed(result)
            }
        }
    }

}
