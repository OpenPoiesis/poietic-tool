//
//  RuntimeFrame+extensions.swift
//  poietic
//
//  Created by Stefan Urbanek on 07/11/2025.
//

import PoieticCore
import PoieticFlows

extension RuntimeEntity {
    /// Get default display name of an object. Try to get simulation object name, then try to fall
    /// back to object name property, then use the default value.
    ///
    /// - Precondition: Object must exist in the plane.
    ///
    public func displayName(default defaultName: String = "(unnamed)") -> String {
        if let component: SimulationName = self.component() {
            return component.name
        }
        else  {
            return self.designObject?.name ?? defaultName
        }
    }
}
