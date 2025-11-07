//
//  Modeller.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

// TODO: Move the Modeller to PoieticCore once happy; we are prototyping it here.

import PoieticCore

/// Manages a design and modelling workflow.
///
public class Modeller {
    /// Design that is being the focus of the modelling workflow.
    ///
    public private(set) var design: Design
    
    /// Systems deriving information from the design on design changes.
    ///
    public let systems: SystemGroup
    
    /// Convenience shortcut for design metamodel.
    public var metamodel: Metamodel { design.metamodel }

    /// Convenience shortcut for design current frame.
    public var currentFrame: DesignFrame? { design.currentFrame }

    /// Runtime frame for current frame.
    public private(set) var runtimeFrame: RuntimeFrame?
    
    /// Create a new modeller for a given design using given runtime systems.
    ///
    init(design: Design, systems: SystemGroup) {
        self.design = design
        self.systems = systems
    }
    
    // MARK: - Authoring
    
    /// Creates a transaction for editing a frame.
    ///
    /// If ``frameID`` is provided, then the frame with given ID is edited. If the frame ID is not
    /// provided, then current frame is edited if it exists. If there is no current frame, then new
    /// empty frame is created.
    ///
    /// - Precondition: If ``frameID`` is given, it must exist in the design. It is up to the caller
    ///   to validate before calling this method.
    /// - SeeAlso: ``accept(_:)``, ``discard(_:)``.
    ///
    public func beginEditing(from frameID: FrameID? = nil) -> TransientFrame {
        if let frameID {
            guard let frame = design.frame(frameID) else {
                fatalError("Frame \(frameID) not found")
            }
            return design.createFrame(deriving: frame)
        } else if let current = currentFrame {
            return design.createFrame(deriving: current)
        } else {
            return design.createFrame()
        }
    }
    
    /// Accept changes to the frame.
    ///
    /// Tries to accept the changes in the transient frame. The caller is responsible for making
    /// sure that there are no structural integrity errors or frame constraint errors. It should
    /// not be user's fault to make this method fail.
    ///
    /// The method invalidates current runtime frame.
    ///
    /// - SeeAlso: ``beginEditing(from:)``, ``discard(_:)``.
    ///
    public func accept(_ frame: TransientFrame) throws (FrameValidationError) {
        try design.accept(frame)
        invalidateRuntime()
    }
    
    /// Discard editing changes.
    ///
    /// - SeeAlso: ``beginEditing(from:)``, ``accept(_:)``.
    ///
    public func discard(_ frame: TransientFrame) {
        design.discard(frame)
    }
    
    // MARK: - Runtime
    
    /// Updates runtime frame by running systems on current frame, if current frame is set.
    ///
    /// If no error was thrown, the runtime frame will be updated with components and object issues.
    ///
    /// - Throws: ``InternalSystemError`` when the systems fail. It is considered a programming
    ///   error when this happens.
    ///
    /// - SeeAlso: ``runtimeFrame``.
    ///
    func updateCurrentRuntime() throws (InternalSystemError) {
        guard let currentFrame = design.currentFrame else {
            runtimeFrame = nil
            return
        }
        // TODO: Reuse previous runtime once we decide to reuse runtimes.
        // TODO: Store runtime once we decide to cache them here.
        let runtime = RuntimeFrame(currentFrame)
        try systems.update(runtime)
        runtimeFrame = runtime
    }

    /// Update runtime of given frame.
    ///
    func updateRuntime(_ frameID: FrameID) throws (InternalSystemError) -> RuntimeFrame {
        guard let frame = design.frame(frameID) else { preconditionFailure("Frame does not exist") }
        // TODO: Reuse previous runtime once we decide to reuse runtimes.
        // TODO: Store runtime once we decide to cache them here.
        let runtime = RuntimeFrame(frame)
        try systems.update(runtime)
        return runtime
    }

    private func invalidateRuntime() {
        runtimeFrame = nil
    }
}

